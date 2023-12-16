---
layout: post
title: "Trabajando con ficheros Parquet en Java usando Avro"
description: "Explicación y código ejemplo de cómo serializar y deserializar ficheros Parquet en Java usando Avro"
modified: 2023-11-22
tags:
image:
  path: images/parquet-avro.jpg
  feature: parquet-avro.jpg
  credit: Jerolba + Ideogram
  creditlink: https://ideogram.ai/g/tJqPpL-PTnSSkeRVmf-AWw/3
excerpt_separator: <!--more-->
---

En el artículo anterior hice una introducción sobre el uso de ficheros Parquet en Java, pero no puse ningún ejemplo. En este artículo explicaré cómo hacerlo a través de la librería Avro.

Parquet con Avro **es una de las formas más populares de trabajar con archivos Parquet en Java** debido a su sencillez, flexibilidad, y porque es la librería que más ejemplos tiene.

<!--more-->

Tanto Avro como Parquet permiten estructuras de datos complejas y hay un mapeo entre los tipos de uno sobre los del otro.

Me basaré en el mismo ejemplo que usé en artículos anteriores hablando de serialización. El código será muy parecido al del artículo sobre Avro. Para los detalles específicos de Avro os remito [al artículo](/serializacion-java-avro/).

En el ejemplo trabajaremos con una colección de objetos Organización (`Org`), que a su vez tienen una lista de Atributos (`Attr`):

```java
record Org(String name, String category, String country, Type type, List<Attr> attributes) {
}

record Attr(String id, byte quantity, byte amount, boolean active, double percent, short size) {
}

enum Type {
  FOO, BAR, BAZ
}
```

Al igual que cuando persistimos ficheros en formato Avro, esta versión de Parquet con Avro permite escribir ficheros usando clases generadas a partir del [IDL](/serializacion-java-avro/#idl-y-generación-de-código) o la estructura de datos `GenericRecord`. Esta capacidad es propia de Avro, no de Parquet, pero es *heredada* por `parquet-avro`, la librería que implementa esta integración.

Internamente la librería transforma el esquema de Avro al esquema de Parquet, por lo que la mayoría de las herramientas y librerías que sepan trabajar con las clases de Avro podrán trabajar indirectamente con Parquet con pocos cambios.

## Usando generación de código

Lo único que cambia respecto a cuando [serializamos a formato Avro](/serializacion-java-avro/) es la clase con la que vamos a escribir o leer los ficheros, el resto de lógica para [construir las clases generadas](/serializacion-java-avro/#idl-y-generación-de-código) por Avro o leer sus datos es idéntica.

### Serialización

Necesitaremos instanciar un *writer* de Parquet que soporte la escritura de los objetos creados por Avro:

```java
Path path = new Path("/tmp/my_output_file.parquet");
OutputFile outputFile = HadoopOutputFile.fromPath(path, new Configuration());
ParquetWriter<Organization> writer = AvroParquetWriter.<Organization>builder(outputFile)
    .withSchema(new Organization().getSchema())
    .withWriteMode(Mode.OVERWRITE)
    .config(AvroWriteSupport.WRITE_OLD_LIST_STRUCTURE, "false")
    .build();
```

Parquet define una clase llamada `ParquetWriter<T>` y la librería `parquet-avro` la extiende implementando en `AvroParquetWriter<T>` la lógica de **convertir objetos de Avro a llamadas al API de Parquet**. El objeto que serializaremos será `Organization`, que ha sido generado usando la utilidad de Avro e implementa el API de Avro.

La clase `Path` no es la existente en `java.nio.file`, sino una abstracción propia de Hadoop para referenciar rutas de ficheros. Mientras que la clase `OutputFile` es la abstracción de ficheros de Parquet con capacidad de escribir en ellos.

Por tanto:
* `Path`, `OutputFile`, `HadoopOutputFile` y `ParquetWriter` son clases definidas por el API de Parquet
* `AvroParquetWriter` es una clase definida por el API de `parquet-avro`, librería que encapsula Parquet con Avro
* `Organization` y `Attribute` son clases generadas por la utilidad de Avro, no relacionada con Parquet

La forma de construir una instancia de `ParquetWriter` es mediante un Builder, donde se le pueden configurar bastantes parámetros propios de Parquet o de la librería que estemos usando (Avro). Por ejemplo:
 * `withSchema`: esquema de la clase Organization en Avro, que internamente convertirá a schema de Parquet
 * `withCompressionCodec`: método de compresión a usar: SNAPPY, GZIP, LZ4, etc. Por defecto no configura ninguno.
 * `withWriteMode`: por defecto es CREATE, por lo que si el fichero ya existiera no lo sobreescribiría y lanza una excepción. Para evitarlo debes usar OVERWRITE
 * `withValidation`: si queremos que valide los tipos de datos que se pasan respecto al esquema definido
 * `withBloomFilterEnabled`: si queremos habilitar la creación de [bloom filters](https://en.wikipedia.org/wiki/Bloom_filter)

Una configuración más genérica (no definida en el API) de ambas librerías se puede pasar con el método `config(String property, String value)`. En este caso configuramos que internamente debe usar una [estructura de tres niveles](https://github.com/apache/parquet-format/blob/master/LogicalTypes.md#lists) para representar listas anidadas.

Una vez instanciada la clase `ParquetWriter`, la mayor complejidad reside en transformar tus POJOs a las clases `Organization` generadas a partir del IDL de Avro. El código completo sería este:

```java
Path path = new Path("/tmp/my_output_file.parquet");
OutputFile outputFile = HadoopOutputFile.fromPath(path, new Configuration());
try (ParquetWriter<Organization> writer = AvroParquetWriter.<Organization>builder(outputFile)
    .withSchema(new Organization().getSchema())
    .withWriteMode(Mode.OVERWRITE)
    .config(AvroWriteSupport.WRITE_OLD_LIST_STRUCTURE, "false")
    .build()) {
  for (var org : organizations) {
    List<Attribute> attrs = org.attributes().stream()
      .map(a -> Attribute.newBuilder()
        .setId(a.id())
        .setQuantity(a.quantity())
        .setAmount(a.amount())
        .setSize(a.size())
        .setPercent(a.percent())
        .setActive(a.active())
        .build())
      .toList();
    Organization organization = Organization.newBuilder()
      .setName(org.name())
      .setCategory(org.category())
      .setCountry(org.country())
      .setOrganizationType(OrganizationType.valueOf(org.type().name()))
      .setAttributes(attrs)
      .build();
    writer.write(organization);
  }
}
```

En vez de convertir toda la colección de organizaciones y luego escribirla, podemos convertir y persistir cada `Organization` una por una.

El código lo puedes encontrar en [GitHub](https://github.com/jerolba/parquet-for-java-posts/blob/master/src/main/java/com/jerolba/parquet/avro/ToParquetUsingAvroWithGeneratedClasses.java#L26).

#### Deserialización

La deserialización es muy sencilla si aceptamos trabajar luego con las clases generadas por Avro.

Para leer el fichero necesitaremos instanciar un *reader* de Parquet:

```java
Path path = new Path(filePath);
InputFile inputFile = HadoopInputFile.fromPath(path, new Configuration());
ParquetReader<Organization> reader = AvroParquetReader.<Organization>builder(inputFile).build();
```

Parquet define una clase llamada `ParquetReader<T>` y la librería `parquet-avro` la extiende implementado en `AvroParquetReader` la lógica de **convertir las estructuras de datos internas de Parquet** a las clases generadas por Avro.

En este caso `InputFile` es la abstracción de ficheros de Parquet con capacidad de leer de ellos.

Por tanto:
* `Path`, `InputFile`, `HadoopInputFile` y `ParquetReader` son clases definidas por el API de Parquet
* `AvroParquetReader` implementa  `ParquetReader` y está definida en `parquet-avro`, librería que encapsula Parquet con Avro
* `Organization` (y `Attribute`) son clases generadas por la utilidad de Avro, no relacionada con Parquet

La instanciación de la clase `ParquetReader` también se hace con un Builder, aunque las opciones a configurar son mucho menores, ya que toda su configuración viene dada por el propio fichero que vamos a leer. El reader no necesita saber si el fichero usa codificación de diccionario o si está comprimido, por lo que no es necesario configurarlo, ya lo descubre él leyendo el fichero.

```java
Path path = new Path(filePath);
InputFile inputFile = HadoopInputFile.fromPath(path, new Configuration());
try (ParquetReader<Organization> reader = AvroParquetReader.<Organization>builder(inputFile).build()) {
    List<Organization> organizations = new ArrayList<>();
    Organization next = null;
    while ((next = reader.read()) != null) {
        organizations.add(next);
    }
    return organizations;
}
```

Si el IDL empleado para generar el código contuviera un subconjunto de los atributos persistidos en el fichero, al leerlo estaríamos ignorando todas las columnas no presentes en el IDL. Nos ahorraremos lecturas de disco y deserialización/decodificación de datos.

El código lo puedes encontrar en [GitHub](https://github.com/jerolba/parquet-for-java-posts/blob/master/src/main/java/com/jerolba/parquet/avro/FromParquetUsingAvroWithGeneratedClasses.java#L18).

---

### Usando GenericRecord

Aquí no será necesario generar ningún código y trabajaremos con la clase `GenericRecord` proporcionada por Avro, pero el código será un poco más verboso.

#### Serialización

Como no tenemos ficheros generados que contengan el esquema embebido, necesitamos definir programáticamente el schema de Avro que vamos a usar. El código es el mismo que el del artículo sobre Avro:

```java
Schema attrSchema = SchemaBuilder.record("Attribute")
  .fields()
  .requiredString("id")
  .requiredInt("quantity")
  .requiredInt("amount")
  .requiredInt("size")
  .requiredDouble("percent")
  .requiredBoolean("active")
  .endRecord();
var enumSymbols = Stream.of(Type.values()).map(Type::name).toArray(String[]::new);
Schema orgsSchema = SchemaBuilder.record("Organizations")
  .fields()
  .requiredString("name")
  .requiredString("category")
  .requiredString("country")
  .name("organizationType").type().enumeration("organizationType")
  .symbols(enumSymbols).noDefault()
  .name("attributes").type().array().items(attrSchema).noDefault()
  .endRecord();
var typeField = orgsSchema.getField("organizationType").schema();
EnumMap<Type, EnumSymbol> enums = new EnumMap<>(Type.class);
enums.put(Type.BAR, new EnumSymbol(typeField, Type.BAR));
enums.put(Type.BAZ, new EnumSymbol(typeField, Type.BAZ));
enums.put(Type.FOO, new EnumSymbol(typeField, Type.FOO));
```

En vez de usar un `AvroParquetWriter` del tipo `Organization`, creamos uno del tipo `GenericRecord` y construimos instancias del mismo como si fuera un `Map`:

```java
Path path = new Path(filePath);
OutputFile outputFile = HadoopOutputFile.fromPath(path, new Configuration());
try (ParquetWriter<GenericRecord> writer = AvroParquetWriter.<GenericRecord>builder(outputFile)
    .withSchema(orgsSchema)
    .withWriteMode(Mode.OVERWRITE)
    .config(AvroWriteSupport.WRITE_OLD_LIST_STRUCTURE, "false")
    .build()) {
  for (var org : organizations) {
    List<GenericRecord> attrs = new ArrayList<>();
    for (var attr : org.attributes()) {
      GenericRecord attrRecord = new GenericData.Record(attrSchema);
      attrRecord.put("id", attr.id());
      attrRecord.put("quantity", attr.quantity());
      attrRecord.put("amount", attr.amount());
      attrRecord.put("size", attr.size());
      attrRecord.put("percent", attr.percent());
      attrRecord.put("active", attr.active());
      attrs.add(attrRecord);
    }
    GenericRecord orgRecord = new GenericData.Record(orgsSchema);
    orgRecord.put("name", org.name());
    orgRecord.put("category", org.category());
    orgRecord.put("country", org.country());
    orgRecord.put("organizationType", enums.get(org.type()));
    orgRecord.put("attributes", attrs);
    writer.write(orgRecord);
  }
}
```

El código lo puedes encontrar en [GitHub](https://github.com/jerolba/parquet-for-java-posts/blob/master/src/main/java/com/jerolba/parquet/avro/ToParquetUsingAvroWithGenericRecord.java#L33).

#### Deserialización

Como en la versión original de Avro, la mayor parte del trabajo consiste en convertir el `GenricRecord` en nuestra estructura de datos. Al comportarse como un `Map`, tendremos que *castear* los tipos de los valores:

```java
Path path = new Path(filePath);
InputFile inputFile = HadoopInputFile.fromPath(path, new Configuration());
try (ParquetReader<GenericRecord> reader = AvroParquetReader.<GenericRecord>builder(inputFile).build()) {
  List<Org> organizations = new ArrayList<>();
  GenericRecord record = null;
  while ((record = reader.read()) != null) {
    List<GenericRecord> attrsRecords = (List<GenericRecord>) record.get("attributes");
    var attrs = attrsRecords.stream().map(attr -> new Attr(attr.get("id").toString(),
        ((Integer) attr.get("quantity")).byteValue(),
        ((Integer) attr.get("amount")).byteValue(),
        (boolean) attr.get("active"),
        (double) attr.get("percent"),
        ((Integer) attr.get("size")).shortValue())).toList();
    Utf8 name = (Utf8) record.get("name");
    Utf8 category = (Utf8) record.get("category");
    Utf8 country = (Utf8) record.get("country");
    Type type = Type.valueOf(record.get("organizationType").toString());
    organizations.add(new Org(name.toString(), category.toString(), country.toString(), type, attrs));
  }
  return organizations;
}
```

Al estar utilizando la interface de Avro, mantiene su lógica de que los Strings se codifican dentro de la clase `Utf8` y será necesario extraer sus valores.

El código lo puedes encontrar en [GitHub](https://github.com/jerolba/parquet-for-java-posts/blob/master/src/main/java/com/jerolba/parquet/avro/FromParquetUsingAvroWithGenericRecord.java#L23).

Por defecto cuando lee el fichero deserializa todos los campos del objeto, ya que desconoce el esquema de lo que necesitas leer, y lo procesa todo. **Si quisieras una proyección de los campos deberás pasárselo en forma de schema de Avro** en la creación del `ParquetReader`:

```java
Schema projection = SchemaBuilder.record("Organizations")
  .fields()
  .requiredString("name")
  .requiredString("category")
  .requiredString("country")
  .endRecord();
Configuration configuration = new Configuration();
configuration.set(AvroReadSupport.AVRO_REQUESTED_PROJECTION, orgsSchema.toString());
try (ParquetReader<GenericRecord> reader = AvroParquetReader.<GenericRecord>builder(inputFile)
  .withConf(configuration)
  .build()) {
....
```

El resto del proceso sería igual, pero con menos campos. Puedes ver el todo el código fuente del ejemplo [aquí](https://github.com/jerolba/parquet-for-java-posts/blob/master/src/main/java/com/jerolba/parquet/avro/FromParquetUsingAvroWithGenericRecordProjection.java#L24).

---

## Rendimiento

¿Qué rendimiento da Parquet Avro a la hora de serializar y deserializar un gran volumen de datos? ¿En qué medida influyen las distintas opciones de compresión? ¿elegimos compresión con Snappy o no comprimir? ¿y entre activar el diccionario o no?

Aprovechando los análisis que hice [anteriormente](/serializacion-java-avro/#análisis-e-impresiones) sobre distintos formatos de serialización podemos hacernos una idea de sus virtudes y carencias. Los *benchmarks* los he hecho con el mismo ordenador, por lo que son comparables para hacernos una idea.

### Tamaño del fichero

Tanto usando generación de código como GenericRecord, el resultado es el mismo, ya que son distintas maneras de definir el mismo esquema y persistir los mismos datos:

|   | Sin comprimir | Snappy |
|---|---:|---:|
| Dictionay False | 1 034 MB | 508 MB |
| Dictionay True  |   289 MB | 281 MB |

Dadas la diferencia de tamaños, podemos ver que en mi ejemplo sintético el uso de diccionarios comprime bastante la información, mejor que el propio algoritmo de Snappy. La activación de la compresión o no vendrá dada por la penalización en rendimiento que suponga.

### Tiempo de serialización

**Usando generación de código:**

|    | Sin comprimir | Snappy |
|:---|---:|---:|
| Dictionay False | 14 386 ms | 14 920 ms |
| Dictionay True  | 15 110 ms | 15 381 ms |

**Usando GenericRecord:**

|   | Sin comprimir | Snappy |
|---|---:|---:|
| Dictionay False | 15 287 ms | 15 809 ms |
| Dictionay True  | 16 119 ms | 16 432 ms |

El tiempo es muy similar en todos los casos, y podemos decir que las distintas técnicas de compresión no afectan sensiblemente al tiempo empleado.

No hay diferencias de tiempos reseñables entre código generado y el uso de `GenericRecord`, por lo que el *performance* no debería ser un factor determinante a la hora de elegir una solución.

[Comparado con otros formatos de serialización](/serializacion-java-avro/#análisis-e-impresiones), tarda entre un 40% (Jackson) y un 300% (Protocol Buffers/Avro) más de tiempo, pero a cambio consigue ficheros entre un 70% (Protocol Buffers/Avro) o 90% (Jackson) menores.

### Tiempo de deserialización

**Usando generación de código:**

|   | Sin comprimir | Snappy |
|---|---:|---:|
| Dictionay False | 10 722 ms | 10 736 ms |
| Dictionay True  |  7 707 ms |  7 665 ms |

**Usando GenericRecord:**

|   | Sin comprimir | Snappy |
|---|---:|---:|
| Dictionay False | 12 089 ms | 11 931 ms |
| Dictionay True  |  8 374 ms |  8 451 ms |

En este caso el uso del diccionario tiene un impacto relevante en el tiempo, al ahorrarse decodificar información que está repetida. Definitivamente no hay una razón para desactivar la funcionalidad.

Si comparamos con otros formatos, es el doble de lento que Protocol Buffers y está a la par con Avro, pero más de dos veces más rápido que Jackson.

Para poner en perspectiva el rendimiento, en mi portátil lee 50 000 `Organization`s por segundo, que a su vez contienen casi 3 millones de instancias de tipo `Attribute`.

### Tiempo de deserialización usando una proyección

¿Cómo es el rendimiento si usamos una proyección y sólo leemos tres campos del objeto Organización e ignoramos su colección de atributos?

|   | Sin comprimir | Snappy |
|---|---:|---:|
| Dictionay False | 289 ms | 304 ms |
| Dictionay True  | 195 ms | 203 ms |

Confirmamos la promesa de que si accedemos a un subconjunto de columnas, leeremos y decodificaremos mucha menos información. En este caso **emplea un 2.5% del tiempo**, o lo que es lo mismo, **es 40 veces más rápido** procesando el mismo fichero.

Aquí es donde Parquet muestra toda su potencia, al permitir leer y decodificar un subconjunto de datos en poco tiempo, aprovechando cómo están distribuidos los mismos en el fichero.

## Conclusión

Si ya estás usando Avro o ya lo conoces, la mayoría del código y particularidades relativas a Avro te sonarán. Si no lo conoces, aumenta la barrera de entrada, al tener que aprender sobre dos tecnologías distintas, y no tener claro qué corresponde a cada una.

El mayor cambio respecto a usar sólo Avro es la forma de construir los objetos writer y reader, donde tendremos que lidiar con toda la configuración y particularidades propias de Parquet.

Si tuviera que elegir entre usar sólo Avro o Parquet con Avro, yo elegiría la segunda opción, ya que produce ficheros más compactos y tenemos la oportunidad de sacar provecho del formato columnar.

Los datos que he usado en el ejemplo son sintéticos y los resultados pueden variar según las características de tus datos. Te recomiendo hacer pruebas, pero a menos que todos tus valores sean muy aleatorios, las tasas de compresión serán altas.

En entornos de escribir una vez y leer múltiples veces, el tiempo empleado en serializar no debería ser determinante. Son más importantes, por ejemplo, el consumo de tu almacenamiento, el tiempo de transferencia de los ficheros, o la velocidad de procesamiento (más si puedes filtrar las columnas a las que accedes).

A pesar de usar diferentes técnicas de compresión y codificación, el tiempo de procesamiento de ficheros es bastante rápido. Junto a su capacidad de trabajar con un esquema tipado, lo convierte en un formato de intercambio de datos a tener en cuenta en proyectos con alto volumen de datos.