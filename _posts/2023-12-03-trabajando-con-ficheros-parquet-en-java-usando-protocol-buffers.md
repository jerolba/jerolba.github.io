---
layout: post
title: "Trabajando con ficheros Parquet en Java usando Protocol Buffers"
description: "Explicación y código ejemplo de cómo serializar y deserializar ficheros Parquet en Java usando Protocol Buffers"
modified: 2023-12-03
tags:
excerpt_separator: <!--more-->
---

Este post continúa la [serie de ](/trabajando-con-ficheros-parquet-en-Java/)[artículos](/trabajando-con-ficheros-parquet-en-java-usando-avro/) acerca del trabajo con ficheros Parquet en Java. Esta vez explicaré cómo hacerlo a través de la librería de Protocol Buffers (PB).

Si encontrar ejemplos y documentación sobre cómo usar Parquet con Avro es complicado, con **Protocol Buffers es más complicado todavía**.

<!--more-->

Tanto Protocol Buffers como Parquet permiten estructuras de datos complejas y hay un mapeo sencillo entre ellos.

Me basaré en el mismo ejemplo que usé en artículos anteriores hablando de serialización. El código será muy parecido al del [artículo sobre Protocol Buffers](/serializacion-java-json-protocol-buffers-y-flatbuffers/).

En el ejemplo trabajaremos con una colección de objetos Organización, que a su vez tienen una lista de Atributos:

```java
record Org(String name, String category, String country, Type type, List<Attr> attributes) {
}

record Attr(String id, byte quantity, byte amount, boolean active, double percent, short size) {
}

enum Type {
  FOO, BAR, BAZ
}
```

Al igual que cuando escribimos ficheros en formato PB, en Parquet con PB debemos usar clases generadas a partir del [IDL](/serializacion-java-json-protocol-buffers-y-flatbuffers/#protocol-buffers-1). Esta capacidad es propia de PB, no de Parquet, pero es *heredada* por `parquet-protobuf`, la librería que implementa esta integración.

Internamente la librería transforma el esquema de PB al esquema de Parquet, por lo que la mayoría de las herramientas y librerías que sepan trabajar con las clases de PB podrán trabajar indirectamente con Parquet con pocos cambios.

Lo único que cambia respecto a cuando serializamos a PB es la clase con la que vamos a escribir o leer los ficheros. El resto de lógica para construir las clases generadas por PB o leer sus datos es idéntica.

## Serialización

Necesitaremos instanciar un *writer* de Parquet que soporte la escritura de los objetos creados por PB:

```java
Path path = new Path("/tmp/my_output_file.parquet");
OutputFile outputFile = HadoopOutputFile.fromPath(path, new Configuration());
ParquetWriter<Organization> writer = ProtoParquetWriter.<Organization>builder(outputFile)
      .withMessage(Organization.class)
      .withWriteMode(Mode.OVERWRITE)
      .config(ProtoWriteSupport.PB_SPECS_COMPLIANT_WRITE, "true")
      .build();
```

Parquet define una clase llamada `ParquetWriter<T>` y la librería `parquet-protobuf` la extiende implementando en `ProtoParquetWriter<T>` la lógica de **convertir objetos de PB a llamadas al API de Parquet**. El objeto que serializaremos será `Organization`, que ha sido generado usando la utilidad de PB e implementa el API de PB.

La clase `Path` no es la existente en `java.nio.file`, sino una abstracción propia de Hadoop para referenciar rutas de ficheros. Mientras que la clase `OutputFile` es la abstracción de ficheros de Parquet con capacidad de escribir en ellos.

Por tanto:
* `Path`, `OutputFile`, `HadoopOutputFile` y `ParquetWriter` son clases definidas por el API de Parquet
* `ProtoParquetWriter` es una clase definida por el API de `parquet-protobuf`, librería que encapsula Parquet con Protocol Buffers
* `Organization` y `Attribute` son clases generadas por la utilidad de PB, no relacionada con Parquet

La forma de construir una instancia de `ParquetWriter` es mediante un Builder, donde se le pueden configurar bastantes parámetros propios de Parquet o de la librería que estemos usando (PB). Por ejemplo:
 * `withMessage`: clase generada con Protocol Buffers que queremos persistir (y que define internamente el schema)
 * `withCompressionCodec`: método de compresión a usar: SNAPPY, GZIP, LZ4, etc. Por defecto no configura ninguno.
 * `withWriteMode`: por defecto es CREATE, por lo que si el fichero ya existiera no lo sobreescribiría y lanza una excepción. Para evitarlo debes usar OVERWRITE
 * `withValidation`: si queremos que valide los tipos de datos que se pasan respecto al esquema definido

Se puede pasar configuración más genérica con el método `config(String property, String value)`. En este caso configuramos que internamente debe usar una [estructura de tres niveles](https://github.com/apache/parquet-format/blob/master/LogicalTypes.md#lists) para representar listas anidadas.

Una vez instanciada la clase `ParquetWriter`, la mayor complejidad reside en transformar tus POJOs a las clases `Organization` generadas a partir del IDL de PB:

```java
Path path = new Path("/tmp/my_output_file.parquet");
OutputFile outputFile = HadoopOutputFile.fromPath(path, new Configuration());
try (ParquetWriter<Organization> writer = ProtoParquetWriter.<Organization>builder(outputFile)
      .withMessage(Organization.class)
      .withWriteMode(Mode.OVERWRITE)
      .config(ProtoWriteSupport.PB_SPECS_COMPLIANT_WRITE, "true")
      .build()) {
    for (Org org : organizations) {
        var organizationBuilder = Organization.newBuilder()
            .setName(org.name())
            .setCategory(org.category())
            .setCountry(org.country())
            .setType(OrganizationType.forNumber(org.type().ordinal()));
        for (Attr attr : org.attributes()) {
            var attribute = Attribute.newBuilder()
                .setId(attr.id())
                .setQuantity(attr.quantity())
                .setAmount(attr.amount())
                .setActive(attr.active())
                .setPercent(attr.percent())
                .setSize(attr.size())
                .build();
            organizationBuilder.addAttributes(attribute);
        }
        writer.write(organizationBuilder.build());
    }
}
```

En vez de convertir toda la colección de organizaciones y luego escribirla, podemos convertir y persistir cada `Organization` una por una.

El código lo puedes encontrar en [GitHub](https://github.com/jerolba/parquet-for-java-posts/blob/master/src/main/java/com/jerolba/parquet/protocol/ToParquetUsingProtocolBuffers.java#L29).

## Deserialización

La deserialización es muy sencilla si aceptamos trabajar luego con las clases generadas por Protocol Buffers.

Para leer el fichero necesitaremos instanciar un *reader* de Parquet:

```java
Path path = new Path(filePath);
InputFile inputFile = HadoopInputFile.fromPath(path, new Configuration());
ParquetReader<Organization.Builder> reader =
    ProtoParquetReader.<Organization.Builder>builder(inputFile).build()
```

Parquet define una clase llamada `ParquetReader<T>` y la librería `parquet-protobuf` la extiende implementado en `ProtoParquetReader` la lógica de **convertir las estructuras de datos internas de Parquet** a las clases generadas por Protocol Buffers.

`InputFile` es la abstracción de ficheros de Parquet con capacidad de leer de ellos.

Por tanto:
* `Path`, `InputFile`, `HadoopInputFile` y `ParquetReader` son clases definidas por el API de Parquet
* `ProtoParquetReader` implementa  `ParquetReader` y está definida en `parquet-protobuf`, librería que encapsula Parquet con PB
* `Organization` (y `Attribute`) son clases generadas por la utilidad de PB, no relacionada con Parquet

La instanciación de la clase `ParquetReader` también se hace con un Builder, aunque las opciones a configurar son mucho menores, ya que toda su configuración viene dada por el propio fichero que vamos a leer. El reader no necesita saber si el fichero usa codificación de diccionario o si está comprimido, por lo que no es necesario configurarlo, ya lo descubre él leyendo el fichero.

Es importante destacar que el tipo de dato que devolverá el reader será un `Builder` de `Organization`, en vez de la propia `Organization`, y deberemos nosotros llamar al método `build()`:

```java
Path path = new Path(filePath);
InputFile inputFile = HadoopInputFile.fromPath(path, new Configuration());
try (ParquetReader<Organization.Builder> reader = ProtoParquetReader.<Organization.Builder>builder(inputFile).build()) {
    List<Organization> organizations = new ArrayList<>();
    Organization.Builder next = null;
    while ((next = reader.read()) != null) {
        organizations.add(next.build());
    }
    return organizations;
}
```

Si el IDL empleado para generar el código contuviera un subconjunto de las columnas existentes en el fichero, al leerlo estaríamos ignorando todas las columnas no presentes en el IDL. Nos ahorraremos lecturas de disco y deserialización/decodificación de datos.

El código lo puedes encontrar en [GitHub](https://github.com/jerolba/parquet-for-java-posts/blob/master/src/main/java/com/jerolba/parquet/protocol/FromParquetUsingProtocolBuffers.java#L21).

---

## Rendimiento

¿Qué rendimiento da Parquet con Protocol Buffers a la hora de serializar y deserializar un gran volumen de datos? ¿En qué medida influyen las distintas opciones de compresión? ¿elegimos compresión con Snappy o no comprimir? ¿y entre activar el diccionario o no?

Aprovechando los análisis que hice [anteriormente](/serializacion-java-avro/#análisis-e-impresiones) sobre distintos formatos de serialización podemos hacernos una idea de sus virtudes y carencias. Los *benchmarks* los he hecho con el mismo ordenador, por lo que son comparables para hacernos una idea.

### Tamaño del fichero

|   | Sin comprimir | Snappy |
|---|---:|---:|
| Dictionay False | 1 034 MB | 508 MB |
| Dictionay True  |   289 MB | 281 MB |


Dadas la diferencia de tamaños, podemos ver que en mi ejemplo sintético el uso de diccionarios comprime bastante la información, casi mejor que el propio algoritmo de Snappy. La activación de la compresión o no vendrá dada por la penalización en rendimiento que suponga.

### Tiempo de serialización

| | Sin comprimir | Snappy |
|:---|---:|---:|
| Dictionay False | 16 039 ms | 16 606 ms |
| Dictionay True  | 16 806 ms | 17 071 ms |

El tiempo es muy similar en todos los casos, y podemos decir que las distintas técnicas de compresión no afectan sensiblemente al tiempo empleado.

[Comparado con otros formatos de serialización](/serializacion-java-avro/#análisis-e-impresiones), tarda entre un 50% (Jackson) y un 300% (Protocol Buffers/Avro) más, pero a cambio consigue ficheros de entre un 60% (Protocol Buffers/Avro) o 90% (Jackson) menores.

### Tiempo de deserialización

|   | Sin comprimir | Snappy |
|---|---:|---:|
| Dictionay False | 12 419 ms | 13 173 ms |
| Dictionay True  | 11 379 ms | 11 096 ms |

En este caso, el uso del diccionario tiene un impacto relevante en el tiempo, al ahorrarse decodificar información que está repetida. Definitivamente no hay una razón para desactivar la funcionalidad.

Si comparamos con otros formatos, es un 100% más lento que Protocol Buffers puro y es un 30% más lento que Avro puro, pero es casi 2 veces más rápido que Jackson.

Para poner en perspectiva el rendimiento, en mi portátil lee 45 000 `Organization`s por segundo, que a su vez contienen casi 2,6 millones de instancias de tipo `Attribute`.

## Conclusión

Si ya conocías Protocol Buffers, la mayoría del código y particularidades relativas a PB te sonarán. Si no lo conoces, aumenta la barrera de entrada, al tener que familiarizarte sobre dos tecnologías distintas, pero similares, y no tener claro qué parte corresponde a cada una.

El mayor cambio respecto a Protocol Buffers puro es la forma de construir los objetos writer y reader, donde tendremos que lidiar con toda la configuración y particularidades propias de Parquet.

Aunque se pueda, Protocol Buffers no está pensado para serializar gran cantidad de datos, por lo que no es comparable con Parquet usando Protocol Buffers. Si tuviera que elegir entre usar Parquet con PB o Parquet con Avro, probablemente eligiría la versión de Avro, ya que Avro se usa a menudo en el mundo de la ingeniería de datos y podrías sacarle más partido a la experiencia.

Los datos que he usado en el ejemplo son aleatorios y los resultados pueden variar según las características de tus datos. Haz pruebas con tus datos para sacar conclusiones.

En entornos de escribir una vez y leer múltiples veces, el tiempo empleado en serializar no debería ser determinante. Son más importantes, el tamaño de los ficheros, su tiempo de transferencia, o la velocidad de procesamiento (más si puedes filtrar las columnas haciendo proyecciones).

A pesar de emplear diferentes técnicas de compresión y codificación, la velocidad de procesamiento de ficheros es bastante alta. Junto a su capacidad de trabajar con un esquema tipado, hace que Parquet sea un formato de intercambio de datos a tener en cuenta en proyectos con alto volumen de datos.