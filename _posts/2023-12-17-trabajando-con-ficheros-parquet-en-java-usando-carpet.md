---
layout: post
title: "Trabajando con ficheros Parquet en Java usando Carpet"
description: "Carpet es una librería Java que serializa y deserializa ficheros Parquet a Records de Java 17, abstrayéndote de los detalles de Parquet y Hadoop, y minimizando el número de dependencias."
modified: 2023-12-17
tags:
image:
  path: images/ParquetAvroGenerated.jpg
  feature: ParquetAvroGenerated.jpg
  credit: Jerolba + Ideogram
  creditlink: https://ideogram.ai/g/tJqPpL-PTnSSkeRVmf-AWw/3
excerpt_separator: <!--more-->
---
TL;DR - He creado una librería para trabajar con ficheros Parquet en Java llamada Carpet.

Tras un tiempo trabajando con ficheros Parquet en Java mediante la librería de Parquet Avro, y estudiando cómo funcionaba, llegué a la conclusión de que a pesar de **ser muy útil** en múltiples casos de uso y tener un gran potencial, **la documentación y ecosistema necesario para ser adoptado en el mundo Java era muy pobre**.

Mucha gente está usando soluciones subóptimas (ficheros csv o json), está aplicando soluciones más complejas (Spark), o lenguajes no familiares para ellos (Python) por desconocer cómo trabajar con ficheros Parquet de forma sencilla. Por eso decidí **escribir esta [serie de artículos](/trabajando-con-ficheros-parquet-en-Java/) y [dar una charla](https://www.youtube.com/watch?v=SPGBvb-DcKE) sobre el tema**.

Una vez que lo entiendes y tienes los ejemplos, todo es más fácil. Pero, **¿podría ser aún más fácil?** ¿Podríamos evitarnos el lío de usar librerías *extrañas* que serializan otros formatos? **Sí, debería ser más fácil aún.**

Por eso me decidí a **implementar una librería Open Source** que simplifique al extremo trabajar con Parquet desde Java, algo que lo recubra: **Carpet**.

Carpet es una librería Java que serializa y deserializa ficheros Parquet a Records de Java 17, abstrayéndote (si quieres) de las particularidades de Parquet y Hadoop, y minimizando el número de dependencias necesarias, ya que trabaja directamente con el código de Parquet. Está disponible en [Maven Central](https://central.sonatype.com/artifact/com.jerolba/carpet-record) y tenéis su código fuente en [GitHub](https://github.com/jerolba/parquet-carpet).

<!--more-->
## Hello world

**Carpet funciona por reflexión**: inspecciona tu modelo de clases y no es necesario definir un IDL, implementar interfaces o usar anotaciones. **Carpet está basado en los records de Java**, la primitiva creada por la JDK para hacer [Data Oriented Programing](https://www.infoq.com/articles/data-oriented-programming-java/).

Siguiendo con los mismos ejemplos de anteriores artículos, tendremos una colección de objetos Organización, que a su vez tienen una lista de Atributos:

```java
record Org(String name, String category, String country, Type type, List<Attr> attributes) { }

record Attr(String id, byte quantity, byte amount, boolean active, double percent, short size) { }

enum Type { FOO, BAR, BAZ }
```

Con Carpet no es necesario crear clases especiales ni hacer transformaciones. **Carpet trabaja directamente con tu modelo**, si éste encaja en el schema Parquet que necesitas.

### Serialización

Con Carpet no necesitas usar los writers de Parquet, ni las clases de Hadoop:

```java
try (OutputStream outputStream = new FileOutputStream(filePath)) {
    try (CarpetWriter writer = new CarpetWriter<>(outputStream, Org.class)) {
        writer.write(organizations);
    }
}
```

El código lo puedes encontrar en [GitHub](https://github.com/jerolba/parquet-for-java-posts/blob/master/src/main/java/com/jerolba/parquet/carpet/ToParquetUsingCarpetWriter.java#L14).

Si tus records coinciden con el esquema requerido en Parquet, no es necesaria la conversión de clases. Si no necesitas una configuración especial de Parquet, no hay que crear builders, y usamos directamente un `OutputStream` de Java.

**Por reflexión crea el esquema de Parquet**, usando como nombres y tipos de columnas los nombres y tipos de los campos de tus records.

Carpet soporta estructuras de datos complejas, siempre que todos los objetos sean records, colecciones (List, Set, etc) y mapas.



### Deserialización

La deserialización es igual o más sencilla:

```java
List<Org> organizations = new CarpetReader<>(new File(filePath), Org.class).toList();
```

También puedes iterar el fichero con un stream:

```java
List<Org> organizations = new CarpetReader<>(new File(filePath), Org.class).stream()
    .filter(this::somePredicate)
    .toList();
```

El código lo puedes encontrar en [GitHub](https://github.com/jerolba/parquet-for-java-posts/blob/master/src/main/java/com/jerolba/parquet/carpet/FromParquetUsingCarpetReader.java#L13).

Como Carpet usa reflexión, por convención esperará que los tipos y nombres de los campos se correspondan con los de las columnas del fichero Parquet.

Ninguna de las clases de Parquet o Hadoop son importadas en tu código.

### Deserialización usando una proyección

Carpet lee sólo las columnas que están definidas en los records, e ignora cualquier otra columna que exista en el fichero. **Definir una proyección con un subconjunto de sus atributos es tan sencillo como definir un record en Java**:

```java

record OrgProjection(String name, String category, String country, Type type) { }

var organizations = new CarpetReader<>(new File(filePath), OrgProjection.class).toList();

```

En este caso el tiempo de lectura pasa a ser de centenares de milisegundos.

El código lo puedes encontrar en [GitHub](https://github.com/jerolba/parquet-for-java-posts/blob/master/src/main/java/com/jerolba/parquet/carpet/FromParquetUsingCarpetReaderProjection.java#L14).

---

## The Parquet way

Si por algún motivo necesitas personalizar algún parámetro de la generación de ficheros o usarlo con Hadoop, Carpet provee de una implementación de los builders de `ParquetWriter` y `ParquetReader`. De esta forma todas las configuraciones de Parquet quedan expuestas.

### Serialización

Necesitaremos instanciar un *writer* de Parquet:

```java
OutputFile outputFile = new FileSystemOutputFile(new File(filePath));
try (ParquetWriter.<Org> writer = CarpetParquetWriter.<Org>builder(outputFile, Org.class)
        .withCompressionCodec(CompressionCodecName.GZIP)
        .withWriteMode(Mode.OVERWRITE)
        .build()) {
    for (Org org : organizations) {
        writer.write(org);
    }
}
```

El código lo puedes encontrar en [GitHub](https://github.com/jerolba/parquet-for-java-posts/blob/master/src/main/java/com/jerolba/parquet/carpet/ToParquetUsingCarpetParquetWriter.java#L19).

Carpet implementa un builder de `ParquetWriter<T>` con toda la lógica de **convertir records de Java a llamadas al API de Parquet**.

Para evitar usar las clases de Hadoop (e importar todas sus dependencias), **Carpet implementa las interfaces de `InputFile` y `OutputFile` usando ficheros normales**.

Por tanto:
* `OutputFile` y `ParquetWriter` son clases definidas por el API de Parquet
* `CarpetParquetWriter` y `FileSystemOutputFile` son clases implementadas por Carpet
* `Org` y `Attr` son records de Java de tu dominio, no relacionada con Parquet ni Carpet

Carpet genera implícitamente el schema de Parquet a partir de los campos de tus records.


### Deserialización

Necesitaremos instanciar un *reader* de Parquet mediante el builder de `CarpetParquetReader`:

```java
InputFile inputFile = new FileSystemInputFile(new File(filePath));
try (ParquetReader<Org> reader = CarpetParquetReader.builder(inputFile, Org.class).build()) {
    List<Org> organizations = new ArrayList<>();
    Org next = null;
    while ((next = reader.read()) != null) {
        organizations.add(next);
    }
    return organizations;
}
```

El código lo puedes encontrar en [GitHub](https://github.com/jerolba/parquet-for-java-posts/blob/master/src/main/java/com/jerolba/parquet/carpet/FromParquetUsingParquetCarpetReader.java#L18).

Parquet define una clase llamada `ParquetReader<T>` y Carpet la crea implementado en `CarpetParquetReader` la lógica de **convertir las estructuras de datos internas de Parquet** a tus records de Java.

En este caso:
* `InputFile`  y `ParquetReader` son clases definidas por el API de Parquet
* `CarpetParquetReader` y `FileSystemOutputFile` son clases implementadas por Carpet
* `Org` (y `Attr`) son records de Java de tu dominio, no relacionada con Parquet

La instanciación de la clase `ParquetReader` también se hace con un Builder por mantener el patrón que sigue Parquet.

Carpet valida que el schema del fichero Parquet sea compatible con los records Java. Si no fuera así lanza una excepción.

---

## Rendimiento

A igualdad de esquema y datos, el tamaño de los ficheros comparado con `parquet-avro` y `parquet-protobuf` es el mismo. Pero, ¿Cuál es el sobrecoste de usar reflexión?

| Librería | Serialización | Deserialización |
|:---|---:|---:|
| Parquet Avro             | 15 381 ms |  7 665 ms |
| Parquet Protocol Buffers | 16 174 ms | 11 025 ms |
| Carpet                   | 12 769 ms |  8 881 ms |

Escribiendo, Carpet es un 20% más rápido que usando Avro y Protocol Buffers. El *overhead* de la reflexión es menor que el trabajo de crear los objetos de Avro o Protocol Buffers.

Leyendo, Carpet es un poco más lento que la versión más rápida de Parquet Avro. El uso de reflexión no penaliza mucho el rendimiento, y a cambio acabamos con tipos de datos no propios de la librería.

## Conclusión

Parquet es un formato muy potente, pero infrautilizado en el ecosistema Java. En parte debido al desconocimiento y la dificultad de trabajar con él, y en parte porque al ser un formato binario, no es muy cómodo trabajar con él.

Aunque no hagas Big Data, Parquet también te puede ser útil en casos de uso donde tienes bastantes datos. Muchas veces por no saber tratarlos bien se adoptan soluciones y arquitecturas complejas o ineficientes.

El formato, al tener un schema, permite **garantizar que los tipos definidos se cumplan o que un dato no pueda ser null**. ¿Cuántas veces has tenido problemas intentando parsear un CSV?

Carpet ofrece un API muy sencilla, haciendo que sea muy fácil escribir y procesar ficheros Parquet en el 99% de los casos de uso. Para mi, ahora **resulta más cómodo trabajar con Parquet que con ficheros CSVs**.

Carpet es una librería Open Source bajo licencia Apache 2.0. Puedes encontrar su [código fuente en GitHub](https://github.com/jerolba/parquet-carpet) y está disponible en [Maven Central](https://central.sonatype.com/artifact/com.jerolba/carpet-record).

En el [README.md](https://github.com/jerolba/parquet-carpet?tab=readme-ov-file#table-of-contents) del proyecto tenéis una explicación detallada de las distintas funcionalidades, personalizaciones que podéis hacer, y formas de usar su API. **Os invito a usar Carpet y a que me déis *feedback*, o me contéis vuestros casos de uso trabajando con Parquet.**
