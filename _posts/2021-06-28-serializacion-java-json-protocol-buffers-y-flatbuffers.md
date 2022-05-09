---
layout: post
title: "Serialización en Java con JSON, Protocol Buffers y FlatBuffers"
description: "¿Cuánto cuesta serializar y deserializar muchos datos en Java usando JSON, Protocol Buffers y FlatBuffers?"
modified: 2021-06-28
tags: 
image:
  path: images/data-serialization.jpg
  feature: data-serialization.jpg
  credit: Tim Johnson
  creditlink: https://unsplash.com/photos/20FJ6prKm28
excerpt_separator: <!--more-->
---

**TL;DR:** El artículo analiza el rendimiento de la serialización/deserialización con JSON, Protocol Buffers y FlatBuffers con muchos datos. Usando ciertas propiedades no evidentes de FlatBuffers, resulta ser el mejor formato en ciertos casos de uso.

<!--more-->

---

En [Clarity AI](https://clarity.ai/), generamos *batches* de datos que nuestra aplicación tiene que cargar y procesar para mostrar a nuestros clientes la información del impacto social de muchas empresas. Por volumen de información no es Big Data, pero es lo suficiente como para suponer un problema el tener que leerla y cargarla de una forma eficiente en procesos con usuarios *online*.

La información la puedes guardar en base de datos o en forma de ficheros, serializada en algún formato estándar y con un esquema consensuado con tu equipo de *Data Engineering*. Dependiendo de cómo sea tu información y requisitos, puede ser desde algo tan sencillo como CSV, XML o JSON, hasta los formatos surgidos del Big Data como [Parquet](https://parquet.apache.org/documentation/latest/), [Avro](https://avro.apache.org/docs/current/), [ORC](https://orc.apache.org/) o [Arrow](https://arrow.apache.org/). En este artículo me centraré en estudiar y analizar dos formatos de serialización binaria: Protocol Buffers y FlatBuffers.

Para que cualquiera pueda sacar sus conclusiones en función de sus requisitos, analizaré distintos aspectos técnicos: tiempo de generación, tamaño del fichero resultante, tamaño del fichero al comprimirlo (gzip), memoria necesaria para generar el fichero, tamaño de las librerías empleadas, tiempo de deserialización o la memoria necesaria para parsear y acceder a los datos.

En mi caso como mi patrón de acceso es escribir una vez, leer muchas (**W**rite **O**nce, **R**ead **M**any), en mi selección final primarán los factores de lectura sobre los de escritura.

## Los formatos

Analizaré Protocol Buffers y FlatBuffers, e incluiré JSON como referencia para poder comparar con algo que todo el mundo conoce.

Además de los mencionados anteriormente, existen otros sistemas de serialización como [MessagePack](https://msgpack.org/), [Thrift](https://thrift.apache.org/)  o [Cap’n Proto](https://capnproto.org/), pero me centraré sólo en esos dos.

### JSON

Es el formato de intercambio de datos por excelencia, y estándar de facto en la comunicación de servicios web. Aunque se definió como formato a principios de los 2000, no fue hasta 2013 que la [Ecma](https://www.ecma-international.org/) publicó una primera versión, que se convirtió en estándar internacional en 2017.

Con una sintaxis sencilla, no necesita predefinir el esquema de la información para poder parsearla. Como es un formato basado en texto plano, es legible por humanos y existen infinidad de librerías para procesarlo en todos los lenguajes.

### Protocol Buffers

[Protocol Buffers](https://developers.google.com/protocol-buffers) es el mecanismo que desarrolló Google internamente para serializar datos de forma eficiente tanto en recursos de CPU como de espacio, sobre todo si lo **comparas con lo que se hacía en su día con XML**. En 2008 lo liberaron bajo licencia BSD.

Se basa en predefinir qué formato tendrán los datos mediante un IDL (Interface Definition Language) y a partir de él, generar el código fuente que será capaz tanto de escribir como de leer ficheros con datos. El productor y el consumidor tienen que compartir de alguna manera el formato definido en el IDL. 

El formato es lo suficientemente flexible como para soportar el añadir nuevos campos y deprecar campos existentes sin romper la compatibilidad.

**La información generada tras la serialización es un array de bytes, ilegible por humanos.**

El soporte de diferentes lenguajes de programación viene dado por la existencia de un generador de código para cada lenguaje. Si un lenguaje no está oficialmente soportado siempre podrás [encontrar una implementación](https://github.com/protocolbuffers/protobuf/blob/master/docs/third_party.md) que haya hecho alguien de la comunidad.

Google lo ha estandarizado y convertido en su mecanismo para la comunicación entre servidores [gRPC](https://grpc.io/), en vez del habitual REST con JSON.

En la [documentación de Protocol Buffers](https://developers.google.com/protocol-buffers/docs/techniques#large-data) desaconsejan usarlo con mensajes muy grandes para comunicaciones, pero en mi caso, como quiero generar un fichero con todo el contenido serializado, voy a saltarme la recomendación.

### FlatBuffers

[FlatBuffers](https://google.github.io/flatbuffers/) fue creado también dentro de Google en 2014 bajo licencia Apache 2.0. Se desarrolló para cubrir necesidades específicas dentro del mundo de los videojuegos y aplicaciones móviles, donde los recursos son más limitados.

Al igual que Protocol Buffers, se basa en predefinir el formato de los datos con una sintaxis similar, y genera un binario ilegible por humanos. También tiene soporte para [múltiples lenguajes](https://google.github.io/flatbuffers/flatbuffers_support.html), y permite añadir y deprecar campos sin romper la compatibilidad.

La principal diferencia de FlatBuffers es que usa deserialización con *“zero-copy”*: no necesita crear objetos o reservar nuevas áreas de memoria para parsear la información, ya que trata siempre con la información en binario dentro de un área de memoria o de disco. **Los objetos que representan la información deserializada no contienen la información, si no que saben como resolver el valor cuando sus métodos *get* son llamados**.

En el caso concreto de Java esto no es estrictamente correcto, ya que para los Strings tiene que instanciar el `char[]` necesario para su estructura interna. Pero sólo es necesario si llamas al getter del atributo de tipo String. **Sólo se deserializa la información que es accedida**.


---

## Serialización

Dado [este modelo de datos](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/SampleDataFactory.java#L13) de organizaciones y sus atributos, usando los nuevo records de Java:

```java
record Org(String name, String category, String country, Type type,
           List<Attr> attributes) { }

record Attr(String id, byte quantity, byte amount, boolean active, 
            double percent, short size) { }

enum Type { FOO, BAR, BAZ }
```

Simularé un escenario pesado, donde haré que cada Organización tenga de forma aleatoria entre 40 y 70 Atributos distintos, y en total tendremos unas 400K organizaciones. Los valores de los atributos son también aleatorios.

### JSON

Usando un librería como [Jackson](https://github.com/FasterXML/jackson) y sin anotaciones especiales el código es [muy simple](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/ToJson.java#L22):

```java
var organizations = dataFactory.getOrganizations(400_000);

ObjectMapper mapper = new ObjectMapper();
try (var os = new FileOutputStream("/tmp/organizations.json")) {
  mapper.writeValue(organizations, os);
}
```

Métricas:
- Tiempo de serialización: 11 718 ms
- Tamaño del fichero: 2 457 MB
- Tamaño del fichero comprimido: 525 MB
- Memoria necesaria: al serializar directamente al `OutputStream`, no consume nada a parte de los buffers de IO internos necesarios.
- Tamaño librerías (jackson-xxx.jar): 1 956 679 bytes

### Protocol Buffers

El fichero con el esquema podría ser [este](https://github.com/jerolba/xbuffers-article/blob/master/src/main/resources/organizations.proto):

```bash
syntax = "proto3";

package com.jerolba.xbuffers.protocol;

option java_multiple_files = true;
option java_package = "com.jerolba.xbuffers.protocol";
option java_outer_classname = "OrganizationsCollection";

message Organization {
  string name = 1;
  string category = 2;
  OrganizationType type = 3;
  string country = 4;
  repeated Attribute attributes = 5;

  enum OrganizationType {
    FOO = 0;
    BAR = 1;
    BAZ = 2;
  }

  message Attribute {
    string id = 1;
    int32 quantity = 2;
    int32 amount = 3;
    int32 size = 4;
    double percent = 5;
    bool active = 6;
  }

}

message Organizations {
  repeated Organization organizations = 1;
}
```

Protocol Buffers no serializa directamente tus POJOs, sino que necesitas copiar la información a los objetos generados por su compilador de esquemas.

El código necesario para serializar la información partiendo de los POJOs tendría [este aspecto](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/ToProtocolBuffers.java#L26):

```java
var organizations = dataFactory.getOrganizations(400_000)

var orgsBuilder = Organizations.newBuilder();
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
    orgsBuilder.addOrganizations(organizationBuilder.build());
}
Organizations orgsBuffer = orgsBuilder.build();
try (var os = new FileOutputStream("/tmp/organizations.protobuffer")) {
  orgsBuffer.writeTo(os);
}
```

El código es verboso, pero sencillo. Si por algún motivo decidieras hacer que tu lógica de negocio trabajara directamente con las clases de Protocol Buffers, todo ese código sería innecesario.

- Tiempo de serialización: 5 823 ms
- Tamaño del fichero: 1 044 MB
- Tamaño del fichero comprimido: 448 MB
- Memoria necesaria: instanciar todos esos objetos intermedios en memoria antes de serializarlos requiere de 1 315 MB
- Tamaño librería (protobuf-java-3.16.0.jar):  1 675 739 bytes
- Tamaño clases generadas: 41 229 bytes

### FlatBuffers

El fichero con el esquema podría ser [este](https://github.com/jerolba/xbuffers-article/blob/master/src/main/resources/organizations.fbs):

```bash
namespace com.jerolba.xbuffers.flat;

enum OrganizationType : byte { FOO, BAR, BAZ }

table Attribute {
    id: string;
    quantity: byte; 
    amount: byte;
    size: short;
    percent: double;
    active: bool;
}

table Organization {
    name: string;
    category: string;
    type: OrganizationType;
    country: string;
    attributes: [Attribute];
}

table Organizations {
    organizations: [Organization];
}

root_type Organizations;
```

Aquí es donde la cosa se pone complicada con FlatBuffers: es más complejo y no es automático. La operación de serialización requiere de un **proceso manual** donde vas rellenando el *buffer* binario en memoria. 

Según vas añadiendo elementos de tus estructuras de datos al *buffer*, te devuelve unos *offsets* o  **punteros**, que son los valores usados como referencias en las estructuras de datos que las contienen. Todo de forma recursiva. 

Si viéramos la estructura de datos como un árbol, tendríamos que hacer **[un recorrido en postorden](https://es.wikipedia.org/wiki/Recorrido_de_%C3%A1rboles)**.

El proceso es muy delicado y es muy fácil equivocarse, por lo que será necesario que esa parte la tengas cubierta con **tests unitarios**.

El código necesario para serializar la información partiendo de los POJOs tendría [este aspecto](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/ToFlatbuffers.java#L48):


```java
var organizations = dataFactory.getOrganizations(400_000)
FlatBufferBuilder builder = new FlatBufferBuilder();

int[] orgsArr = new int[organizations.size()];
int contOrgs = 0;
for (Org org : organizations) {
    int[] attributes = new int[org.attributes().size()];
    int contAttr = 0;
    for (Attr attr : org.attributes()) {
        int idOffset = builder.createString(attr.id());
        attributes[contAttr++] = Attribute.createAttribute(builder, idOffset,
                attr.quantity(), attr.amount(), attr.size(),
                attr.percent(), attr.active());
    }
    int attrsOffset = Organization.createAttributesVector(builder, attributes);

    int nameOffset = builder.createString(org.name());
    int categoryOffset = builder.createString(org.category());
    byte type = (byte) org.type().ordinal();
    int countryOffset = builder.createString(org.country());
    orgsArr[contOrgs++] = Organization.createOrganization(builder, nameOffset,
            categoryOffset, type, countryOffset, attrsOffset);
}
int organizationsOffset = Organizations.createOrganizationsVector(builder, orgsArr);
int root_table = Organizations.createOrganizations(builder, organizationsOffset);
builder.finish(root_table);

try (var os = new FileOutputStream("/tmp/organizations.flatbuffers")) {
  InputStream sizedInputStream = builder.sizedInputStream();
  sizedInputStream.transferTo(os);
}
```

Como puedes ver, un código bastante feo y donde te puedes equivocar muy fácilmente.

- Tiempo de serialización: 5 639 ms
- Tamaño del fichero: 1 284 MB
- Tamaño del fichero comprimido: 530 MB
- Memoria necesaria: internamente crea un `ByteBuffer` que va creciendo con tamaño potencia de dos, así que para meter los 1,2 GB de datos, necesita reservar 2 GB de memoria, a menos que lo configures inicialmente los 1,2 GB si sabes su tamaño de antemano.
- Tamaño librería (flatbuffers-java-1.12.0.jar): 64 873 bytes
- Tamaño clases generadas: 9 080 bytes

---

## Deserialización

Definir la deserialización en este análisis es complicado. El objetivo es recuperar el estado de las entidades a partir de su representación binaria, ¿pero qué entidades? ¿la clase original o nos vale la que nos proporcione la herramienta con una interface similar?

Para poder explotar la potencia de las herramientas, nos quedaremos con la representación de la entidad generada por cada librería.

### JSON

Jackson nos lo vuelve a poner muy fácil y se resuelve con [3 líneas](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/FromJson.java#L29) de código:

```java
try (InputStream is = new FileInputStream("/tmp/organizations.json")) {
  ObjectMapper mapper = new ObjectMapper();
  List<Org> organizations mapper.readValue(is, new TypeReference<List<Org>>() {});
  ....
}
```

- Tiempo de deserialización: 20 410 ms
- Memoria necesaria: al reconstruir las estructuras de objetos originales, ocupan 2 193 MB


### Protocol Buffers

También es bastante directo, y basta con pasarle un `InputStream` para [reconstruir en memoria](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/FromProtocolBuffers.java#L26) todo el grafo de objetos:

```java
try (InputStream is = new FileInputStream("/tmp/organizations.protobuffer")) {
    Organizations organizations = Organizations.parseFrom(is);
    .....
}
```

Los objetos son instancias de las clases generadas a partir del esquema, no los records originales.

- Tiempo de deserialización: 4 535 ms
- Memoria necesaria: al reconstruir las estructuras de objetos definidos por el esquema, ocupan 2 710 MB.


### FlatBuffers

La deserialización es más sencilla que la serialización, y la única dificultad radica en instanciar un `ByteBuffer` que "contenga" la información serializada.

Dependiendo de las necesidades podemos traernos todo el contenido a memoria o usar [un fichero mapeado a memoria](https://es.wikipedia.org/wiki/Archivo_proyectado_en_memoria).

Una vez deserializado (o más bien leido el fichero), los objetos que utilizas no contienen realmente la información, simplemente son un proxy que sabe cómo localizarla bajo demanda. Por tanto, si un dato no se accede, no se deserializa realmente... en contra, cada vez que accedes a un mismo valor, tiene que deserializarlo.

#### Leyendo todo el fichero en memoria

Si la memoria disponible te lo permite y vas a usar los datos intensivamente probablemente te interese más [leerlo todo en memoria](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/FromFlatBuffersMemoryAll.java#L27):

```java
try (RandomAccessFile file = new RandomAccessFile("/tmp/organizations.flatbuffers", "r")) {
    FileChannel inChannel = file.getChannel();
    ByteBuffer buffer = ByteBuffer.allocate((int) inChannel.size());
    inChannel.read(buffer);
    inChannel.close();
    buffer.flip();
    Organizations organizations = Organizations.getRootAsOrganizations(buffer);
    Organization organization = organizations.organizations(0);
    String name = organization.name();
    for (int i=0; i < organization.attributesLength(); i++){
        String attrId = organization.attributes(i).id();
    ......
```

- Tiempo de deserialización accediendo a algunos atributos: 640 ms
- Tiempo de deserialización accediendo a todos los atributos: 2 184 ms
- Memoria necesaria: cargando todo el fichero en memoria, 1 284 MB

#### Mapeando el fichero en memoria

El sistema de `FileChannel` de Java nos abstrae de si toda la información está directamente en memoria o si la va leyendo de disco según [va necesitando](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/FromFlatBuffersMappedFileAll.java#L21):

```java
try (RandomAccessFile file = new RandomAccessFile("/tmp/organizations.flatbuffers", "r")) {
  FileChannel inChannel = file.getChannel();
  MappedByteBuffer buffer = inChannel.map(MapMode.READ_ONLY, 0, inChannel.size());
  buffer.load();
  Organizations organizations = Organizations.getRootAsOrganizations(buffer);
    .....
  inChannel.close();
}
```

- Tiempo de deserialización accediendo a algunos atributos: 306 ms
- Tiempo de deserialización accediendo a todos los atributos: 2044 ms
- Memoria necesaria: como sólo crea objetos de lectura de ficheros y buffers temporales, no sabría cómo medirlo, y creo que se puede considerar despreciable.

Me sorprende que usando un fichero mapeado en memoria tarde ligeramente menos. Probablemente como ejecuto el *benchmark* múltiples veces el sistema operativo tendrá cacheado el fichero en memoria. Si fuera riguroso con la prueba debería cambiar el proceso, pero es suficiente para hacernos una idea.

---

## Análisis e impresiones

|   | JSON | Protocol Buffers | FlatBuffers | 
|---|---:|---:|---:|
| Tiempo serialización    | 11 718 ms | 5 823 ms |       5 639 ms | 
| Tamaño fichero          |  2 457 MB | 1 044 MB |       1 284 MB |
| Tamaño fichero gz       |    525 MB |   448 MB |         530 MB |
| Memoria serializando    |       N/A |  1,29 GB |  1,3 GB - 2 GB | 
| Tiempo deserialización  | 20 410 ms | 4 535 ms | 306 - 2 184 ms | 
| Memoria deserialización |  2 193 MB | 2 710 MB |   0 - 1 284 MB | 
| Tamaño librería JAR     |  1 910 KB | 1 636 KB |          64 KB |
| Tamaño clases generadas |       N/A |    40 KB |           9 KB |

De los datos y de lo que he podido ver jugando con los formatos, podemos concluir:

- JSON es sin duda más lento y pesado, pero es el sistema más cómodo y conveniente de todos.
- Protocol Buffers es una buena opción: rápido en serialización y deserialización, y con ficheros compactos y comprimibles. Su API es sencilla e intuitiva, y el formato es muy usado, llegando a ser ya un estándar de mercado con múltiples casos de uso.
- FlatBuffers es muy recomendable cuando el tiempo y consumo de memoria deserializando es importante. Esto explica porqué es tan usado en el mundo de los videojuegos y aplicaciones móviles. Su API serializando es muy delicada y propensa a errores.
- En FlatBuffers, en un ejemplo como el mío donde hay bastantes datos, a la hora de serializar es importante **configurar un tamaño del buffer** cercano al resultado final, si no tendrá que extender continuamente el buffer, gastando más memoria y tiempo.
- En FlatBuffers, la librería necesaria para serializar y deserializar, junto con las clases generadas, tiene un **tamaño ridículo**.
- En JSON y Protocol Buffers es un todo o nada: **necesitas deserializar toda la información para acceder a una parte de ella**. Mientras que en FlatBuffers puedes acceder a cualquier elemento sin tener que recorrer y parsear toda la información que la precede.
- Por las pruebas que he hecho, Protocol Buffers ocupa menos espacio que FlatBuffers porque el *overhead* por estructura de datos (message/table) es menor, y sobre todo porque Protocol Buffers usa enteros de 32 bits para todos los tipos enteros (int, short, byte), pero al serializar **los representa con el valor que menos bytes ocupe**.
- Por ese mismo motivo, cuando Protocol Buffers genera las clases a partir del IDL, lo define todo como **enteros de 32 bits** y deserializa los valores a int32.  Por eso el consumo de memoria de los objetos deserializados es un 23% mayor que el de JSON. Lo que gana comprimiendo enteros lo pierde en consumo de memoria.
- Para los valores escalares, tanto Protocol Buffers como FlatBuffers **no admiten null**. Si un valor no está presente toma el valor por defecto del primitivo correspondiente (0, 0.0 o false). Los Strings en Protocol Buffers se deserializan a "", mientras que en FlatBuffers será `null`. No sé qué dicen las buenas prácticas, pero entiendo que si de verdad es importante saber si un valor es `null` deberás gestionarlo tú manualmente con un campo boolean asociado.
- Aunque en el grafo de objetos original el nombre de los países o categorías en forma de `String` sólo estén en memoria una vez, al serializarse en el fichero aparecerá tantas veces como referencias tengas, y al deserializarse se crearán tantas instancias como referencias tuviera. Por eso en Protocol Buffers (y en JSON), la memoria consumida al deserializar **ocupa el doble de la memoria ocupada por los objetos creados originalmente para serializar**<a href="#1"><sup>1</sup></a>.


---

## Iterando la solución de FlatBuffers

La implementación de la serialización con FlatBuffers es realmente dura, pero si comprendes cómo funciona internamente, ese problema puede llegar a convertirse en una gran ventaja que juegue en su favor.

Cada vez que haces algo como esto: 

```java
int idOffset = builder.createString(attr.id());
```

estás añadiendo al buffer una cadena de caracteres y obteniendo una especie de puntero u *offset* que usar en el objeto que la contiene.

Si la misma cadena de caracteres se repite en una serialización, ¿puedo reutilizar el puntero cada vez que aparezca? **Sí**.

Según tu lógica de negocio, si en una serialización sabes que la misma cadena de caracteres se va a repetir múltiples veces puedes reutilizar su offset **sin romper la representación interna de la serialización**.

En el ejemplo que he puesto, usando un `Map<String, Integer>` y consultadolo cada vez que vamos a añadir una cadena, tendríamos algo [como esto](https://github.com/jerolba/xbuffers-article/blob/master/src/main/java/com/jerolba/xbuffers/ToFlatbuffersV2.java#L52):

```java
var organizations = dataFactory.getOrganizations(400_000)
FlatBufferBuilder builder = new FlatBufferBuilder();
Map<String, Integer> strOffsets = new HashMap<>();

int[] orgsArr = new int[organizations.size()];
int contOrgs = 0;
for (Org org : organizations) {
    int[] attributes = new int[org.attributes().size()];
    int contAttr = 0;
    for (Attr attr : org.attributes()) {
        int idOffset = strOffsets.computeIfAbsent(attr.id(), builder::createString);  // <--
        attributes[contAttr++] = Attribute.createAttribute(builder, idOffset,
                attr.quantity(), attr.amount(), attr.size(),
                attr.percent(), attr.active());
    }
    int attrsOffset = Organization.createAttributesVector(builder, attributes);

    int nameOffset = strOffsets.computeIfAbsent(org.name(), builder::createString);  // <--
    int categoryOffset = strOffsets.computeIfAbsent(org.category(), builder::createString);  // <--
    byte type = (byte) org.type().ordinal();
    int countryOffset = strOffsets.computeIfAbsent(org.country(), builder::createString);  // <--
    orgsArr[contOrgs++] = Organization.createOrganization(builder, nameOffset,
            categoryOffset, type, countryOffset, attrsOffset);
}
int organizationsOffset = Organizations.createOrganizationsVector(builder, orgsArr);
int root_table = Organizations.createOrganizations(builder, organizationsOffset);
builder.finish(root_table);

try (var os = new FileOutputStream("/tmp/flatbuffer.json")) {
  InputStream sizedInputStream = builder.sizedInputStream();
  sizedInputStream.transferTo(os);
}
```

- Tiempo de serialización: 3 803 ms
- Tamaño del fichero: 600 MB
- Tamaño del fichero comprimido: 414 MB
- Memoria necesaria: para guardar esos 600 MB usará un `ByteBuffer` que ocupará 1 GB si no lo preconfiguras.

En este ejemplo sintético, **la reducción del tamaño del fichero llega a más del 50%**, y a pesar de tener que consultar constantemente a un mapa, el tiempo que tarda en serializar es sensiblemente menor.

Como el formato no cambia, la **deserialización conserva las mismas propiedades** y el código de lectura no cambia. Si optas por leer todo el fichero en memoria, ganarás el mismo espacio en memoria, mientras que si lo lees como un fichero mapeado, el cambio no se notará salvo por el menor uso de I/O.

Si añadimos esta optimización a la comparativa, tenemos:

|   | JSON | Protocol Buffers | FlatBuffers | FlatBuffers V2 |
|---|---:|---:|---:|---:|
| Tiempo serialización    | 11 718 ms | 5 823 ms |       5 639 ms |       3 803 ms | 
| Tamaño fichero          |  2 457 MB | 1 044 MB |       1 284 MB |         600 MB | 
| Tamaño fichero gz       |    525 MB |   448 MB |         530 MB |         414 MB | 
| Memoria serializando    |       N/A |  1,29 GB |  1,3 GB - 2 GB |  0.6 GB - 1 GB |
| Tiempo deserialización  | 20 410 ms | 4 535 ms | 306 - 2 184 ms | 202 - 1 876 ms | 
| Memoria deserialización |  2 193 MB | 2 710 MB |   0 - 1 284 MB |     0 - 600 MB | 

En realidad lo que estamos haciendo es comprimir la información en tiempo de serialización, aprovechando que tenemos cierto conocimiento sobre los datos. Estamos creando un [diccionario de compresión](https://en.wikipedia.org/wiki/Dictionary_coder) a mano.

## Iterando otro vez la idea

**¿Ese proceso de compresión o normalización lo puedes llevar a las propias estructuras de datos que serializas?**

¿Y si la tupla de valores de los atributos se repitiera entre Organizaciones? ¿Podríamos reutilizarla?  **Sí**, podríamos reutilizar el puntero de una tupla serializada anteriormente para que fuera referenciada desde la serialización de otra organización. Sólo habría que crear un mapa donde la clave fuera la clase Attr y el valor fuera el offset de su primera aparición: `Map<Attr, Integer> attrOffsets = new HashMap<>()`

El ejemplo que he creado para este artículo es sintético y los valores que se usan son aleatorios. En mi caso real, con unas estructuras de datos similares a las del ejemplo, **los datos se repiten más y la reutilización de datos es mayor**. 

En mi caso real los números son estos:

- Los registros en MongoDB ocupan 737 MB (que los comprime en disco con [WiredTiger](https://docs.mongodb.com/manual/core/wiredtiger/) usando 510 MB)
- Si serializamos los mismos registros con FlatBuffers sin optimizaciones, ocupa 390 MB
- Si además optimizamos normalizando los Strings, ocupa 186 MB
- Si finalmente normalizamos los atributos, el fichero ocupa 45 MB
- Al comprimir el fichero con Gzip, pasamos a tener un fichero de sólo 25 MB

## Conclusión

Conocer cómo funcionan las tecnologías que usas, sus puntos fuertes y débiles, y en qué principios se basan te permiten optimizar su uso y llevarlas más allá de los casos de uso habituales que te cuentan.

Conocer cómo son tus datos también es importante cuando su volumen es elevado ¿De qué forma puedes estructurar tus datos para que pesen menos? ¿O que sea más rápido procesarlos? 

En nuestro caso estas optimizaciones nos han permitido hacer que un proceso de carga en un servicio online que tardaba 60 segundos pase a ser de sólo 3-4 segundos, y podremos posponer un cambio de arquitectura complejo y seguir manteniendo algo sencillo.

Si el volumen de datos pasa a ser Big Data, te aconsejaría que usaras formatos en donde esas optimizaciones ya están incorporadas, como los diccionarios o el agrupar los datos en columnas. 

¿Cual es vuestra experiencia con Parquet? ¿Alguno ha probado Arrow? ¿Sabías que Arrow [está implementado usando FlatBuffers](https://arrow.apache.org/faq/#how-does-arrow-relate-to-flatbuffers)?

---

<span id="1">*</span>  Desde la versión 8u20 de Java, gracias al [JEP 192](https://openjdk.java.net/jeps/192), disponemos de una opción en G1 para hacer que durante la recolección de basura desduplique los String. Pero está deshabilitado por defecto y no tenemos control sobre cuándo se ejecutará, por lo que no podemos contar con esa optimización para reducir el tamaño de la deserialización. 
