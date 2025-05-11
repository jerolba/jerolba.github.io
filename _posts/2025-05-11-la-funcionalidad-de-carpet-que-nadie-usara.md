---
layout: post
title: "La funcionalidad de Carpet que nadie usará"
description: "En la última versión de Carpet he añadido una funcionalidad que creo que nunca nadie va a usar, pero que es la base para poder hacer Carpet más útil."
modified: 2025-05-11
tags:
excerpt_separator: <!--more-->
---

Esta semana he publicado una nueva versión de [Carpet](https://github.com/jerolba/parquet-carpet), la librería de Java para trabajar con ficheros Parquet. En esta versión he añadido una funcionalidad que  creo que nunca nadie va a usar: **la capacidad de leer y escribir columnas de tipo BSON**.

<!--more-->

Parquet soporta [tipos embebidos](https://github.com/apache/parquet-format/blob/master/LogicalTypes.md#embedded-types), que permiten definir tipos de datos complejos dentro de una columna. Cada uno de estos tipos tiene su propia representación interna como un array de bytes.

Históricamente, el formato Parquet ha definido los tipos `JSON` y `BSON`:
*  **JSON**, con `binary nombre (JSON)` en el esquema, representa la información como la serialización a una cadena de texto (String) en UTF-8 de un objeto JSON. La diferencia con escribir el mismo contenido en una columna de tipo `STRING` es que permite definir explícitamente que su contenido es un objeto JSON, y no un simple texto.
* **BSON**, con `binary nombre (BSON)` en el esquema, representa la información como un array de bytes siguiendo [la especificación de BSON](https://bsonspec.org/spec.html). Al tiparlo, también se hace explícito que el contenido es un objeto BSON, y no un array de bytes cualquiera.

En mi escasa experiencia con Parquet, no he visto ejemplos donde se usen estos tipos embebidos, y nadie me había pedido que los soportara en Carpet.

Entonces, ¿por qué he decidido implementar la funcionalidad que les dé soporte? La respuesta es sencilla: **porque quería ver si era capaz de hacerlo**, y poner a prueba si el código es lo suficientemente flexible como para soportarlo sin romper ni condicionar nada de Carpet.

El otro motivo es que recientemente se han definido [nuevos tipos embebidos](https://github.com/apache/parquet-format/blob/master/LogicalTypes.md#variant) en la especificación de Parquet: VARIANT, GEOMETRY y GEOGRAPHY. Todavía no hay implementaciones funcionales de estos nuevos tipos en Parquet, pero ya están definidos y se está trabajando en su implementación en al menos dos lenguajes. No está de más ir preparando el terreno para cuando estén disponibles.

## El problema de la implementación

El principal problema a la hora de implementar estos tipos es elegir sobre qué tipos Java trabajar.

¿Qué clase en Java puede representar un JSON? ¿Una clase ad-hoc propia de Carpet? ¿La clase `JSONObject` de la librería `org.json`? ¿La clase `JsonNode` de la librería Jackson? ¿Cualquier objeto que yo serialice a JSON? ¿Con qué librería? En cualquiera de los casos me estaría acoplando a una implementación y añadiendo dependencias no necesarias en el 99,99% de los casos y forzando al usuario a usar una librería concreta.

Lo mismo ocurre con BSON. Podría usar la librería [bson de MongoDB]( https://central.sonatype.com/artifact/org.mongodb/bson), pero me estaría acoplando a una implementación concreta, y que nadie necesita.

Así que he decidido usar el tipo `String` de Java para representar el contenido de un JSON, y la clase [Binary](https://github.com/apache/parquet-java/blob/5f079b98e63c814535e8709ab5c6fb672c2aedc5/parquet-column/src/main/java/org/apache/parquet/io/api/Binary.java) de Parquet para representar el BSON. De esta forma, Carpet no se acopla a ninguna implementación concreta, y el usuario puede decidir qué librería usar para trabajar con el contenido.

El inconveniente es que los usuarios de esta funcionalidad (que dudo que existan) tendrán que declarar sus atributos como `String` o `Binary`, en lugar de usar sus propias clases de negocio, y tendrán que serializar y deserializar el contenido ellos mismos antes de usar Carpet:

```java
record ProductEvent(
    long id,
    String name,
    String jsonData,
    Binary bsonData,
    Instant timestamp) {
}
```

## Anotación de los tipos Java

No puedo usar `String` para representar un JSON y `Binary` para representar un BSON sin más, porque el tipo `String` de Java ya se mapea automáticamente al tipo `STRING` de Parquet, y `Binary` debería poder representar múltiples tipos lógicos de Parquet (el propio `STRING`, un `BSON` o los futuros `VARIANT`, `GEOMETRY` y `GEOGRAPHY`).

Así que he decidido anotar el atributo del record Java para indicar a qué tipo de dato Parquet se va a serializar.

Al anotar un atributo de tipo `String` con `@ParquetJson` o un atributo de tipo `Binary` con `@ParquetBson`, le indico a Carpet que el contenido de esos atributos representa un JSON o un BSON, respectivamente, y no una simple cadena de texto o un array de bytes genérico.

Este record al escribirse en un fichero Parquet:

```java
record ProductEvent(
    long id,
    String name,
    @ParquetJson String jsonData,
    @ParquetBson Binary bsonData,
    Instant timestamp) {
}
```

generará el siguiente esquema Parquet:

```
message ProductEvent {
    required int64 id;
    optional binary name (STRING);
    optional binary jsonData (JSON);
    optional binary bsonData (BSON);
    required int64 timestamp (TIMESTAMP(MILLIS,true));
}
```

Una vez abierta la puerta a las anotaciones para cambiar los tipos de los atributos en el esquema de Parquet, he decidido dar la opción de poder cambiar también los tipos `String` y `Enum` de Java, y no limitarlo solo a los tipos embebidos.

He añadido también las anotaciones `@ParquetString` y `@ParquetEnum` para poder cambiar el tipo lógico Parquet de un atributo Java de tipo `String`, `Enum` o `Binary` si, por ejemplo, un contrato con un tercero así lo requiere, permitiendo al mismo tiempo usar los tipos de datos más convenientes en el código Java.

Este record al escribirse en un fichero Parquet:

```java
record ProductEvent(
    long id,
    String name,
    @ParquetString Binary productCode,
    @ParquetString MyEnum category,
    @ParquetEnum String type){
}
```

generará el siguiente esquema Parquet:

```
message ProductEvent {
    required int64 id;
    optional binary name (STRING);
    optional binary productCode (STRING);
    optional binary category (STRING);
    optional binary type (ENUM);
}
```

Si quieres saber más sobre las nuevas funcionalidades, puedes consultar la [documentación de Carpet sobre las anotaciones a tipos Java](https://carpet.jerolba.com/advanced/java-type-annotations/).

## Conclusión

Aunque dudo que alguien vaya a usar la funcionalidad de JSON y BSON en Carpet, esta implementación me ha servido para poner a prueba la flexibilidad del código de Carpet y prepararlo para los nuevos tipos embebidos que se están definiendo en la especificación de Parquet.

Además, he añadido la funcionalidad para soportar el tipo `Binary` de Parquet de forma más explícita y la capacidad de cambiar el tipo lógico de los atributos en el esquema Parquet, algo que no tenía previsto inicialmente, pero que considero interesante para ciertos casos de uso.

Aprovechando la necesidad de documentar esta nueva funcionalidad, he decidido crear un site para la documentación de Carpet, trasladando allí todo el contenido que antes se encontraba en el README principal del repositorio de GitHub.

La documentación está generada con [MkDocs](https://www.mkdocs.org/) y alojada en [GitHub Pages](https://pages.github.com/). Puedes ver la documentación completa en [carpet.jerolba.com](https://carpet.jerolba.com/).



