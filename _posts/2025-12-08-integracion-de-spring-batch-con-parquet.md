---
layout: post
title: "Integración de Spring Batch con Parquet"
description: "Cómo integrar Apache Parquet con Spring Batch para crear procesos batch eficientes que generen o consuman ficheros en Parquet, optimizando el almacenamiento y la interoperabilidad con ecosistemas de datos modernos."
modified: 2025-12-08
tags:
excerpt_separator: <!--more-->
---

Spring Batch es una de las pocas herramientas existentes en el ecosistema Java *Enterprise* para construir procesos batch o pipelines de datos. Sin embargo, sus componentes (ItemReader/ItemWriter) están orientados principalmente a bases de datos relacionales, CSV, XML o JSON.

En un mundo donde los Data Lakes y los formatos columnares son cada vez más importantes, integrar Parquet con Spring Batch abre nuevas posibilidades para construir pipelines de datos desde el mundo Java, sin tener que depender de soluciones complejas o *stacks* tecnológicos diferentes que tanta alergia dan en el mundo *Enterprise*.

Ni el proyecto principal de [Spring Batch](https://spring.io/projects/spring-batch) ni el de [extensiones](https://github.com/spring-projects/spring-batch-extensions) ofrecen soporte nativo para leer o escribir ficheros Parquet, y no hay ninguna documentación sobre el tema. Por ello, en este artículo veremos cómo, **gracias a [Carpet](https://github.com/jerolba/parquet-carpet)**, podemos integrar muy fácilmente Parquet con Spring Batch.

<!--more-->

## Introducción

Spring Batch lleva más de 15 años siendo la solución de referencia para implementar procesos batch en Java. Su arquitectura basada en Jobs, Steps, ItemReaders e ItemWriters proporciona un modelo para procesar grandes volúmenes de datos de forma fiable, con capacidades de *restart*, transaccionalidad y gestión de errores.

Sin embargo, **el ecosistema de datos ha evolucionado significativamente** en los últimos años. Los Data Lakes basados en almacenamiento de objetos (S3, Azure Blob Storage, Google Cloud Storage) se han convertido en una pieza clave en los sistemas de persistencia de datos. Y dentro de estos Data Lakes, [Apache Parquet](https://parquet.apache.org/) se ha consolidado como el formato columnar por excelencia.

A pesar de esta evolución, Spring Batch no proporciona soporte directo para leer o escribir ficheros Parquet, y no existen apenas artículos o documentación que cubran este caso de uso. Los `ItemReader` e `ItemWriter` que vienen con el framework cubren:

- **Bases de datos relacionales**: `JdbcCursorItemReader`, `JdbcBatchItemWriter`, `JpaItemWriter`.
- **Ficheros planos**: `FlatFileItemReader`, `FlatFileItemWriter` (CSV, fixed-width).
- **XML**: `StaxEventItemReader`, `StaxEventItemWriter`.
- **JSON**: `JsonItemReader`, `JsonFileItemWriter`.

En muchas organizaciones, los equipos de Data Engineering trabajan con Spark, Pandas o herramientas analíticas que **consumen y generan Parquet de forma nativa**. Mientras tanto, los procesos batch tradicionales en Java continúan exportando CSV o insertando directamente en bases de datos, ignorando todas las ventajas que provee Parquet.

La integración de Spring Batch con Parquet permite:

- **Exportar datos desde sistemas transaccionales** hacia data lakes en un formato optimizado, bien conocido y estandarizado
- **Consumir datos** generados por otras herramientas (Spark, Python) desde procesos Java
- **Transformar y enriquecer** ficheros Parquet manteniendo el formato
- **Aprovechar las ventajas de Parquet**: compresión, *predicate pushdown*, proyecciones y esquema embebido

En este artículo explicaré cómo construir un `ItemReader` y un `ItemWriter` sencillos para trabajar con Parquet. No pretendo construir aquí una librería de producción completa, sino **mostrar lo fácil que es hacerlo con Carpet**. El código que crearé será muy simple, pero funcional y servirá como base para adaptarlo a tus necesidades específicas.

Como prerrequisito, asumo que tienes conocimientos básicos de Spring Batch (Jobs, Steps, ItemReaders/ItemWriters).

## ¿Por qué usar Parquet en Spring Batch?

Antes de meternos en la implementación, es importante entender **qué ventajas aporta Parquet** en el contexto de procesos batch y cuándo tiene sentido esta integración.

### Compresión y eficiencia de almacenamiento y procesamiento

Una de las ventajas más claras de Parquet es su **capacidad de compresión**. Al ser un formato columnar, los datos del mismo tipo se almacenan contiguos, lo que permite aplicar técnicas de compresión muy eficientes.

El formato columnar, y estructurar los datos en RowGroups con estadísticas e índices, permite a Parquet filtrar las filas que no cumplen ciertas condiciones sin necesidad de leer todo el fichero (*predicate pushdown*) y dejar de leer las columnas que no son necesarias. Gracias a la **proyección de columnas**, si solo necesitas leer 3 columnas de un fichero que tiene 50, Parquet solo leerá de disco y procesará los datos de esas 3 columnas.

### Interoperabilidad con ecosistemas de datos modernos

Probablemente la razón más importante para usar Parquet en Spring Batch es la **interoperabilidad**. Si tu organización tiene una arquitectura de datos moderna, es muy probable que otros equipos ya estén usando Parquet:

* **Herramientas de Data Engineering:**: Apache Spark, Apache Flink, Pandas/PyArrow, DuckDB
* **Plataformas de datos:**: Databricks, Snowflake, Google BigQuery, Amazon Redshift o Athena
* **Table formats modernos:**: Delta Lake, Apache Iceberg o DuckLake

Si tu proceso batch en Spring Batch genera un CSV, el equipo de Data Engineering probablemente tenga que convertirlo a Parquet en un paso adicional antes de poder trabajar con él eficientemente. Esto añade latencia, complejidad y puntos de fallo.

Generar directamente Parquet desde Spring Batch elimina esa fricción y permite que tus datos estén directamente disponibles para otros equipos, o que simplemente **tu equipo de Backend especializado en Java pueda implementar esos procesos que antes estaban reservados al equipo de Data Engineering**.

### Esquema embebido y evolución

A diferencia de CSV o formatos planos, Parquet **embebe el esquema** dentro del propio fichero. Esto significa que cualquier herramienta que lea el fichero puede:

- **Descubrir automáticamente** qué columnas contiene y de qué tipo son
- **Validar** que los datos cumplen con el esquema esperado
- **Evolucionar el esquema** de forma controlada (añadir columnas, deprecar otras)

Con Parquet, el esquema está **embebido** en cada fichero. Si añades una columna nueva en tu proceso batch, los consumidores antiguos simplemente la ignorarán. Si renombras una columna, es un cambio explícito visible en el esquema.

Al ser un formato binario y con esquema, el tipo de los datos es explícito y está validado. No hay ambigüedad a la hora de interpretar los datos de una columna. Inspirado en el [Paper de Dremel de Google](https://research.google/pubs/dremel-interactive-analysis-of-web-scale-datasets-2/), Parquet además soporta **estructuras de datos complejas con colecciones, mapas y registros anidados**.

De esta forma, Parquet no está limitado por un formato tabular como CSV, sino que permite tener **registros con la misma riqueza que un JSON, pero con un esquema explícito y tipado, y con una alta compresión**.

## Implementación de ParquetItemReader

Partiremos del ejemplo que provee Spring Batch en sus guías, [Creating a Batch Service](https://spring.io/guides/gs/batch-processing), donde se procesa un fichero CSV, se transforma y se persiste en una base de datos.

En el ejemplo se utiliza la implementación de `ItemReader` que parsea CSVs. Para procesar el equivalente en Parquet implementaremos la misma interfaz extendiendo de las clase abstracta `AbstractItemCountingItemStreamItemReader`, que resuelve gran parte de la lógica interna común de Spring Batch. La versión mínima solo pide implementar los métodos de abrir, leer y cerrar un fichero: `doOpen`, `doRead` y `doClose`.

Nuestra implementación será un *adapter* sobre las clases de `CarpetReader` que proporcionan esa lógica. En esta versión simple delegaremos en el usuario de la clase `ParquetItemReader` la instanciación de `CarpetReader`:

```java
public class ParquetItemReader<T> extends AbstractItemCountingItemStreamItemReader<T> {

    private final CarpetReader<T> carpetReader;
    private CloseableIterator<T> iterator;

    public ParquetItemReader(CarpetReader<T> carpetReader) {
        this.carpetReader = carpetReader;
    }

    @Override
    protected void doOpen() throws Exception {
        this.iterator = carpetReader.iterator();
    }

    @Override
    protected T doRead() throws Exception {
        return iterator.hasNext() ? iterator.next() : null;
    }

    @Override
    protected void doClose() throws Exception {
        this.iterator.close();
    }

}
```

En la configuración de Spring, su uso se reduciría a:

```java
@Bean
public ParquetItemReader<Person> parquetReader() throws IOException {
    InputFile inputFile = new FileSystemInputFile(new File("/tmp/sample-data.parquet"));
    CarpetReader<Person> reader = new CarpetReader<>(inputFile, Person.class);
    return new ParquetItemReader<>(reader);
}
```

## Implementación de ParquetItemWriter

El ejemplo del tutorial escribe el resultado de la transformación en una base de datos. Para completar el artículo, yo además escribiré el resultado en otro fichero Parquet como excusa para crear el `ParquetItemWriter`.

En este caso implementaremos un `ItemWriter` extendiendo de `AbstractItemStreamItemWriter`, que nos gestiona la parte común. La implementación es igualmente sencilla, delegando en `CarpetWriter` la lógica de escritura.

```java
public class ParquetItemWriter<T> extends AbstractItemStreamItemWriter<T> {

    private final CarpetWriter<T> carpetWriter;

    public ParquetItemWriter(CarpetWriter<T> carpetWriter) {
        this.carpetWriter = carpetWriter;
    }

    @Override
    public void write(Chunk<? extends T> chunk) throws Exception {
        for (T item : chunk.getItems()) {
            carpetWriter.write(item);
        }
    }

    @Override
    public void close() {
        try {
            carpetWriter.close();
        } catch (IOException e) {
            throw new ItemStreamException("Error closing CarpetWriter", e);
        }
    }

}
```

Al igual que en el `ItemReader`, delegamos la creación de `CarpetWriter` al usuario de la clase:

```java
@Bean
public ParquetItemWriter<Person> parquetWriter() throws IOException {
    OutputFile outputFile = new FileSystemOutputFile(new File("/tmp/processed-data.parquet"));
    CarpetWriter<Person> carpetWriter = new CarpetWriter<>(outputFile, Person.class);
    return new ParquetItemWriter<>(carpetWriter);
}
```

## Dependencia

Para usar Carpet en tu proyecto Maven, añade la siguiente dependencia en tu `pom.xml`:

```xml
<dependency>
    <groupId>com.jerolba</groupId>
    <artifactId>carpet-record</artifactId>
    <version>0.5.0</version>
</dependency>
```

La librería importa transitivamente las dependencias mínimas necesarias de Apache Parquet, que es la que implementa el formato.

## Conclusión

Integrar Apache Parquet con Spring Batch permite aprovechar las ventajas de un formato columnar optimizado para el almacenamiento y procesamiento de grandes cantidades de datos dentro de procesos batch tradicionales en Java, dejando de ser terreno exclusivo de herramientas como Spark o Pandas.

Aunque Spring Batch no ofrece soporte nativo para Parquet, con [Carpet](https://github.com/jerolba/parquet-carpet) es muy sencillo construir los `ItemReader` e `ItemWriter` que faciliten esta integración. Esto abre la puerta a construir desde Java pipelines de datos más eficientes, interoperables y alineados con las arquitecturas de datos modernas basadas en Data Lakes y formatos columnares.

Puedes encontrar el código de ejemplo en [este repositorio de GitHub](https://github.com/jerolba/gs-batch-processing-parquet).

En función del *feedback* recibido, consideraré crear una librería más completa que implemente estas clases de forma genérica y configurable para su uso en producción.