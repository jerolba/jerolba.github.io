---
layout: post
title: "Serialización en Java con Avro"
description: "¿Cuánto cuesta serializar y deserializar muchos datos en Java usando Avro?"
modified: 2022-11-20
tags: 
image:
  path: images/Autogiro_Cierva_C.19.jpg
  feature: Autogiro_Cierva_C.19.jpg
  credit: Agustin Ruzafa
  creditlink: https://es.wikipedia.org/wiki/Cierva_C.19#/media/Archivo:Autogiro_Cierva_C.19.jpg
excerpt_separator: <!--more-->
---

**TL;DR:** El artículo analiza el rendimiento de la serialización y deserialización de un gran volumen de datos con Avro, comparando los resultados con el [anterior artículo](/serializacion-java-json-protocol-buffers-y-flatbuffers/) sobre JSON, Protocol Buffers y FlatBuffers. 

<!--more-->

---
[Apache Avro](https://avro.apache.org/docs/current/) fue desarrollado como un componente del proyecto Hadoop de Apache, y lanzado en 2009 bajo licencia Apache 2.0.

Avro no debe confundirse con Parquet. Normalmente buscando documentación sobre Parquet acabas leyendo cosas sobre Avro, confundiéndolos. **Aunque la librería de Avro es útil para generar ficheros Parquet y ambos son muy usados en el mundo del Big Data, los formatos no tienen ninguna relación**.

Como en Protocol Buffers y Flat Buffers puedes predefinir un esquema (en JSON) y generar contenido binario no legible por humanos. También tiene soporte para [múltiples lenguajes](https://avro.apache.org/docs/1.11.1/#comparison-with-other-systems).

No es sólo usado para persistir grandes paquetes de datos. Por ejemplo, Avro es muy usado en [Kafka](https://www.confluent.io/blog/avro-kafka-data/) para serializar la información de sus mensajes.

Como el formato o esquema se puede incluir en los datos serializados, la generación de código es opcional, lo que facilita la construcción de sistemas que procesen sus ficheros de forma genérica. **Proporciona la flexibilidad de JSON, pero con un formato más compacto y eficiente**.

Exploraré las dos aproximaciones: con generación de código a partir del esquema y generado programáticamente.

* [IDL y generación de código](#idl-y-generación-de-código)
* [Usando generación de código](#usando-generación-de-código)
* [Usando GenericRecord](#usando-genericrecord)
* [Usando GenericRecord optimizado](#usando-genericrecord-optimizado)

---  

### IDL y generación de código

El fichero con el esquema equivalente al ejemplo del anterior artículo sería [este](https://github.com/jerolba/xbuffers-article/blob/master/src/main/resources/organizations.avsc):

```json
{
  "type": "record",
  "name": "Organization",
  "namespace": "com.jerolba.xbuffers.avro",
  "fields": [
    {
      "name": "name",
      "type": "string"
    }, {
      "name": "category",
      "type": "string"
    }, {
      "name": "organizationType",
      "type": {
        "type": "enum",
        "name": "OrganizationType",
        "symbols": ["FOO", "BAR", "BAZ"]
      }
    }, {
      "name": "country",
      "type": "string"
    }, {
      "name": "attributes",
      "type": {
        "type": "array",
        "items": {
          "type": "record",
          "name": "Attribute",
          "fields": [
            {
              "name": "id",
              "type": "string"
            }, {
              "name": "quantity",
              "type": "int"
            }, {
              "name": "amount",
              "type": "int"
            }, {
              "name": "size",
              "type": "int"
            }, {
              "name": "percent",
              "type": "double"
            }, {
              "name": "active",
              "type": "boolean"
            }
          ]
        }
      }
    }
  ]
}
```

Para generar todas las clases Java necesitas descargar [avro-tools](https://downloads.apache.org/avro/stable/java/avro-tools-1.11.1.jar), y ejecutarlo con parámetros que referencien dónde está localizado el fichero IDL y el directorio de destino de los fichero generados:

```bash
 java -jar avro-tools-1.11.1.jar compile schema ./src/main/resources/organizations.avsc ./src/main/java/
```

O directamente usar Docker con una imagen preparada para ejecutar el comando:

```bash
docker run --rm -v $(pwd)/src:/avro/src kpnnv/avro-tools:1.11.1 compile schema /avro/src/main/resources/organizations.avsc /avro/src/main/java/
```


---

### Usando generación de código

#### Serlialización

Como Protocol Buffers, Avro no serializa directamente tus POJOs, y necesitas copiar la información a los objetos generados por el compilador de esquemas.

Pero en este caso, como estamos persistiendo una colección de objetos, no necesitamos tenerlos todos en memoria porque podemos serializar los objetos convertidos uno por uno según los creamos.

El código necesario para serializar la información partiendo de los POJOs sería como [este](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/ToAvroWithGeneratedClasses.java#L37):

```java
var datumWriter = new SpecificDatumWriter<>(Organization.class);
var dataFileWriter = new DataFileWriter<>(datumWriter);
try (var os = new FileOutputStream("/tmp/organizations.avro")) {
  dataFileWriter.create(new Organization().getSchema(), os);
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
    dataFileWriter.append(organization);
  }
  dataFileWriter.close();
}
```
En vez de convertir toda la colección y luego persistirla, podemos convertir y persistir cada `Organization` uno por uno.

- Tiempo de serialización: 5 409 ms
- Tamaño del fichero: 846 MB
- Tamaño del fichero comprimido: 530 MB
- Memoria necesaria: como serializamos directamente a `OutputStream`, no consume nada a parte de los buffers de IO internos necesarios (y los objetos originales)
- Tamaño librerías (avro-1.11.1.jar + dependencias): 3 552 326 bytes
- Tamaño clases generadas: 37 283 bytes

#### Deserialización

Debido a la representación interna de los datos, Avro necesita moverse por el fichero parseando los datos, y necesitas proporcionar un InputStream *seekeable* o directamente un `File`. Por ejemplo, no puedes usar directamente un `InputStream` de una respuesta HTTP.

Con [pocas líneas](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/FromAvroWithGeneratedClasses.java#L31) puedes leer y procesar todo el grafo de objetos:

```java
var file = new File("/tmp/organizations.avro");
var datumReader = new SpecificDatumReader<>(Organization.class);
List<Organization> organizations = new ArrayList<>();
try (var dataFileReader = new DataFileReader<>(file, datumReader)) {
  while (dataFileReader.hasNext()) {
    organizations.add(dataFileReader.next());
  }
}
```

Los objetos son instancias de las clases generadas a partir del esquema, no los records originales. Pero como iteramos un *reader*, podemos transformar cada instancia a nuestra representación si fuera necesario, sin tener las dos representaciones repetidas en memoria.

- Tiempo de deserialización: 8 197 ms
- Memoria necesaria: reconstruir en memoria todas las estructuras de objetos definidos por el esquema consume 2 520 MB

---

### Usando GenericRecord

En Avro puedes tener el esquema [embebido en el fichero binario](https://avro.apache.org/docs/1.11.1/specification/_print/#object-container-files), y te permite leer un registro serializado sin necesitar conocer o acordar el esquema por adelantado. Esto nos habilita el poder deserializar y conocer el contenido de un fichero cualquiera, ni requerir de la generación de código.

Podemos definir el esquema en tiempo de ejecución y decidir, dadas tus necesidades, los campos y estructura de la información serializada.

#### Serialización

En vez de copiar los datos a las clases generadas, puede hacerlo a través de un `GenericRecord` de Avro, que se comporta como un Map. Primero necesitas definir el esquema de Avro mediante código (o cargarlo de un fichero JSON estático):

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
    .name("organizationType").type().enumeration("organizationType").symbols(enumSymbols).noDefault()
    .name("attributes").type().array().items(attrSchema).noDefault()
    .endRecord();
//Auxiliar Map to encode Enums
var typeField = orgsSchema.getField("organizationType").schema();
EnumMap<Type, EnumSymbol> enums = new EnumMap<>(Type.class);
enums.put(Type.BAR, new EnumSymbol(typeField, Type.BAR));
enums.put(Type.BAZ, new EnumSymbol(typeField, Type.BAZ));
enums.put(Type.FOO, new EnumSymbol(typeField, Type.FOO));
```

Y el código necesario para serializar la colección podría ser como [este](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/ToAvroWithGenericRecord.java#L68):


```java
var datumWriter = new GenericDatumWriter<>(orgsSchema);
var dataFileWriter = new DataFileWriter<>(datumWriter);
try (var os = new FileOutputStream("/tmp/organizations.avro")) {
  dataFileWriter.create(orgsSchema, os);
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
    dataFileWriter.append(orgRecord);
  }
  dataFileWriter.close();
}
```

Como estamos usando el mismo esquema, y sólo estamos cambiando cómo serializamos los datos, el fichero y memoria usada es la misma.

El tiempo de serialización crece a los **5 903 ms**, un 10% más que usando código generado. La implementación de GenericRecord introduce una ligera sobrecarga. 

#### Deserialización

Usando un tipo distinto de `Reader`, el resultado de la deserialización es otra vez un objeto `GenericRecord` no tipado. En este caso, necesitamos convertir cada instancia a la estructura de datos original, [mapeando cada tipo](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/FromAvroWithGenericRecord.java#L35):

```java
List<Org> organizations = new ArrayList<>();
var datumReader = new GenericDatumReader<>();
try (var dataFileReader = new DataFileReader<>(file, datumReader)) {
  while (dataFileReader.hasNext()) {
    GenericRecord record = dataFileReader.next();
    var attrsRecords = (List<GenericRecord>) record.get("attributes");
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
    organizations.add(new Org(name.toString(), category.toString(), 
                              country.toString(), type, attrs));
  }
}
```

El código **es verboso y está lleno de *casteos*.** Avro no soporta los tipos `byte` y `short`, y son convertidos a `int`, por lo que necesitamos *downcastear* sus valores. Como optimización de la codificación, los Strings son creados con una representación interna llamada [Utf8](https://avro.apache.org/docs/1.4.1/api/java/org/apache/avro/util/Utf8.html).

El tiempo de deserialización crece a **8 471 ms**, un 5% más comparado con la versión de código estático.

---

### Usando GenericRecord optimizado

Si inspeccionas la implementación de la clase `GenericRecord`, puedes ver que `get(String key)` y `put(String key, Object value)` [acceden por esa key a un mapa para obtener el índice en un array](https://github.com/apache/avro/blob/master/lang/java/avro/src/main/java/org/apache/avro/Schema.java#L928). Como cada atributo estará siempre en la misma posición leyendo el fichero, podemos acceder sólo una vez y reusar su valor con una variable, mejorando el tiempo de ejecución.

### Serialización

Debido a que necesitamos guardar el índice de cada campo en el esquema, el código queda aún más verboso. Después de crear el esquema, el [código sería](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/ToAvroWithGenericRecordByPosition.java#L68):

```java
int idPos = attrSchema.getField("id").pos();
int quantityPos = attrSchema.getField("quantity").pos();
int amountPos = attrSchema.getField("amount").pos();
int activePos = attrSchema.getField("active").pos();
int percentPos = attrSchema.getField("percent").pos();
int sizePos = attrSchema.getField("size").pos();
int namePos = orgsSchema.getField("name").pos();
int categoryPos = orgsSchema.getField("category").pos();
int countryPos = orgsSchema.getField("country").pos();
int organizationTypePos = orgsSchema.getField("organizationType").pos();
int attributesPos = orgsSchema.getField("attributes").pos();

try (var os = new FileOutputStream("/tmp/organizations.avro")) {
  var datumWriter = new GenericDatumWriter<>(orgsSchema);
  var dataFileWriter = new DataFileWriter<>(datumWriter);
  dataFileWriter.create(orgsSchema, os);
  for (var org : organizations) {
    List<GenericRecord> attrs = new ArrayList<>();
    for (var attr : org.attributes()) {
      GenericRecord attrRecord = new GenericData.Record(attrSchema);
      attrRecord.put(idPos, attr.id());
      attrRecord.put(quantityPos, attr.quantity());
      attrRecord.put(amountPos, attr.amount());
      attrRecord.put(sizePos, attr.size());
      attrRecord.put(percentPos, attr.percent());
      attrRecord.put(activePos, attr.active());
      attrs.add(attrRecord);
    }
    GenericRecord orgRecord = new GenericData.Record(orgsSchema);
    orgRecord.put(namePos, org.name());
    orgRecord.put(categoryPos, org.category());
    orgRecord.put(countryPos, org.country());
    orgRecord.put(organizationTypePos, enums.get(org.type()));
    orgRecord.put(attributesPos, attrs);
    dataFileWriter.append(orgRecord);
  }
  dataFileWriter.close();
}
```

El tiempo de serialización es de **5 381 ms**, muy cercano al tiempo empleado en la versión con código generado.

### Deserialización

El [código](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/FromAvroWithGenericRecordByPosition.java#L36) es muy similar, sólo añadimos las variables para saber la posición de cada campo:

```java
List<Org> organizations = new ArrayList<>();
var datumReader = new GenericDatumReader<>();
try (var dataFileReader = new DataFileReader<>(file, datumReader)) {
  Schema attributes = dataFileReader.getSchema().getField("attributes").schema().getElementType();
  int idPos = attributes.getField("id").pos();
  int quantityPos = attributes.getField("quantity").pos();
  int amountPos = attributes.getField("amount").pos();
  int activePos = attributes.getField("active").pos();
  int percentPos = attributes.getField("percent").pos();
  int sizePos = attributes.getField("size").pos();
  Schema orgs = dataFileReader.getSchema();
  int namePos = orgs.getField("name").pos();
  int categoryPos = orgs.getField("category").pos();
  int countryPos = orgs.getField("country").pos();
  int organizationTypePos = orgs.getField("organizationType").pos();
  while (dataFileReader.hasNext()) {
    GenericRecord record = dataFileReader.next();
    List<GenericRecord> attrsRecords = (List<GenericRecord>) record.get("attributes");
    var attrs = attrsRecords.stream().map(attr -> new Attr(attr.get(idPos).toString(),
      ((Integer) attr.get(quantityPos)).byteValue(),
      ((Integer) attr.get(amountPos)).byteValue(),
      (boolean) attr.get(activePos),
      (double) attr.get(percentPos),
      ((Integer) attr.get(sizePos)).shortValue())).toList();
    Utf8 name = (Utf8) record.get(namePos);
    Utf8 category = (Utf8) record.get(categoryPos);
    Utf8 country = (Utf8) record.get(countryPos);
    Type type = Type.valueOf(record.get(organizationTypePos).toString());
    organizations.add(new Org(name.toString(), category.toString(), 
                              country.toString(), type, attrs));
  }
}
```

El tiempo de deserialización cae a los **7 353 ms**, un 10% más rápido que la versión con código generado. ¿Por qué? No tengo conocimiento suficiente de sus interioridades como para atreverme a dar una respuesta, pero me ha sorprendido el resultado.

#### Resumen de Avro 

|   |Código generado|Generic Record|Generic Record<br/>optimizado |
|---|---:|---:|---:|
| Tiempo serialización    | 5 409 ms | 5 903 ms | 5 381 ms 
| Tiempo deserialización  | 8 197 ms | 8 471 ms | 7 353 ms

Usando GenericRecord podemos obtener alguna flexibilidad en el proceso sin perder rendimiento, pero hace el código mucho más verboso y propenso a errores debido al mapeo manual de campos. 

Las dependencias incluidas son las mismas en todos los casos, y como mucho sólo podríamos ahorrarnos el paso de la generación de código.

--- 

## Análisis e impresiones

|   | JSON | Protocol<br/>Buffers | FlatBuffers | Avro |
|---|---:|---:|---:|---:|
| Tiempo serialización    | 11 718 ms | 5 823 ms |       3 803 ms | 5 409 ms
| Tamaño fichero          |  2 457 MB | 1 044 MB |         600 MB |   846 MB
| Tamaño fichero GZ       |    525 MB |   448 MB |         414 MB |   530 MB
| Memoria serializando    |       N/A |  1,29 GB |    0.6 GB-1 GB |      N/A 
| Tiempo deserialización  | 20 410 ms | 4 535 ms |   202-1 876 ms | 8 197 ms
| Memoria deserialización |  2 193 MB | 2 710 MB |     0 - 600 MB | 2 520 MB
| Tamaño librería JAR     |  1 910 KB | 1 636 KB |          64 KB | 3 469 KB
| Tamaño clases generadas |       N/A |    40 KB |           9 KB |    36 KB

* Si no consideramos las optimizaciones aplicadas en FlatBuffers, el fichero de Avro ocupa menos.
* En el ejemplo, aunque todos los campos son obligatorios, puedes hacerlos fácilmente *nulables* (consumiendo un poco más de espacio).
* Para mi, su principal ventaja es que no requiere tener todos los datos en memoria para serializar la información. Por ejemplo, puedes leerla de una base de datos o un fichero, transformarlo o enriquecerlo según tu lógica, y a la vez que lo persistes en algún tipo de `OutputStream` (creado desde un fichero o una conexión HTTP).
* La posibilidad de definir un esquema programáticamente nos da la opción de modificar el formato de salida dependiendo de la lógica de negocio o crear nuestras herramientas de serialización.
* Avro está a medio camino entre JSON y los formatos binarios como Protocol Buffers y Flatbuffers:
  - Avro soporta un esquema flexible
  - No es necesario conocer o acordar el esquema de antemano para poder leer un fichero Avro
  - En JSON no puedes obtener el esquema del propio fichero (sin parsearlo por completo antes)
  - Avro es más compacto que JSON (pero no legible por humanos)
  - El tiempo de serialización y deserialización es más rápido que con JSON
  - Puedes fácilmente serializar o deserializar todos los objetos en un bucle/stream sin necesitar tenerlo todo en memoria
