---
layout: post
title: "Algoritmos de compresión en Parquet"
description: "Parquet soporta múltiples algoritmos de compresión. En el artículo analizamos y medimos GZIP, LZ4, Snappy, ZSTD y Brotli"
modified: 2025-01-13
tags:
excerpt_separator: <!--more-->
---
Apache Parquet es un formato de almacenamiento columnar optimizado para cargas de trabajo analíticas, aunque también se puede utilizar para almacenar cualquier tipo de datos estructurados con múltiples casos de uso.

Una de sus características más destacadas es la capacidad de comprimir datos de manera eficiente usando diferentes técnicas de compresión en distintas partes de su proceso. Esto reduce los costos de almacenamiento y mejora el rendimiento en la lectura.

Este artículo explica la compresión de ficheros en Parquet, da ejemplos de uso y analiza su rendimiento.
<!--more-->

## Técnicas de compresión

A diferencia de los formatos de almacenamiento tradicionales basados en filas, Parquet utiliza un enfoque columnar, permitiendo aplicar técnicas de compresión más específicas y efectivas basadas en la localidad del dato y la redundancia de valores del mismo tipo.

Parquet, al escribir la información en binario, aplica compresión en dos niveles distintos y en cada uno usa diferentes técnicas:
* Escribiendo los valores de una columna, de forma adaptativa según los valores que se encuentran al principio, elige el [tipo de codificación](https://parquet.apache.org/docs/file-format/data-pages/encodings/): Diccionario, Run-Length Encoding Bit-Packing, Delta Encoding, etc
* Cada vez que se alcanza cierta cantidad de bytes (1MB por defecto) se forma una página, y el bloque binario se comprime con el algoritmo de compresión configurado por el programador (ninguno, GZip, Snappy, LZ4, etc)

Si bien el algoritmo de compresión se configura a nivel de fichero, la codificación de cada columna se decide automáticamente mediante una heurística interna (al menos en la implementación de parquet-java).

El rendimiento de las distintas técnicas de compresión será muy dependiente de cómo sean tus datos, por lo que no hay una bala de plata que garantice el menor tiempo de procesamiento y de menor consumo de espacio. **Tendrás que hacer tus propias pruebas**.

## Código

La configuración es muy sencilla, y sólo es necesario hacerla explícitamente a la hora de escribir. Cuando se va a leer un fichero, Parquet descubre qué algoritmo de compresión se usó y aplica el algoritmo de descompresión correspondiente.

### Configuración del algoritmo o codec

Tanto en [Carpet](https://github.com/jerolba/parquet-carpet) como en Parquet con [Protocol Buffers](https://www.jerolba.com/trabajando-con-ficheros-parquet-en-java-usando-protocol-buffers/) y [Avro](https://www.jerolba.com/trabajando-con-ficheros-parquet-en-java-usando-avro/), para configurar el algoritmo de compresión sólo necesitas llamar al método `withCompressionCodec` del builder:

**Carpet**

```java
CarpetWriter<T> writer = new CarpetWriter.Builder<>(outputFile, clazz)
    .withCompressionCodec(CompressionCodecName.ZSTD)
    .build();
```

**Avro**

```java
ParquetWriter<Organization> writer = AvroParquetWriter.<Organization>builder(outputFile)
    .withSchema(new Organization().getSchema())
    .withCompressionCodec(CompressionCodecName.ZSTD)
    .build();
```

**Protocol Buffers**

```java
ParquetWriter<Organization> writer = ProtoParquetWriter.<Organization>builder(outputFile)
    .withMessage(Organization.class)
    .withCompressionCodec(CompressionCodecName.ZSTD)
    .build();
```

El valor tiene que ser uno de los disponibles en el enum [CompressionCodecName](https://github.com/apache/parquet-java/blob/master/parquet-common/src/main/java/org/apache/parquet/hadoop/metadata/CompressionCodecName.java#L26):
UNCOMPRESSED, SNAPPY, GZIP, LZO, BROTLI, LZ4, ZSTD y LZ4_RAW (LZ4 está deprecado, y deberías usar LZ4_RAW).

### Nivel de compresión

Algunos de estos algoritmos pueden configurar el nivel de compresión. Este nivel suele estar relacionado con el esfuerzo que tienen que hacer para encontrar el patrón de repetición, y a mayor compresión, más tiempo tienen que emplear en el proceso de compresión.

Aunque vienen con un valor por defecto, es modificable usando el mecanismo de configuración genérica de Parquet, aunque cada codec usa una clave distinta.

Además, el valor que hay que elegir no es estándar y depende de cada codec, por lo que hay que recurrir a la documentación de cada algoritmo para entender qué aporta cada nivel.

**ZSTD**

Para referenciar la configuración del nivel declara una constante: `ZstandardCodec.PARQUET_COMPRESS_ZSTD_LEVEL`.

Los posibles valores van del [1 al 22](https://facebook.github.io/zstd/zstd_manual.html#Chapter1), y su valor por defecto es 3.

```java
ParquetWriter<Organization> writer = ProtoParquetWriter.<Organization>builder(outputFile)
    .withMessage(Organization.class)
    .withCompressionCodec(CompressionCodecName.ZSTD)
    .config(ZstandardCodec.PARQUET_COMPRESS_ZSTD_LEVEL, "6")
    .build();
```

**LZO**

Para referenciar la configuración del nivel declara una constante: `LzoCodec.LZO_COMPRESSION_LEVEL_KEY`.

Los posibles valores van del [1 al 9, 99 y 999](https://github.com/nemequ/lzo/blob/master/doc/LZO.TXT#L74), y su valor por defecto es "999".

```java
ParquetWriter<Organization> writer = ProtoParquetWriter.<Organization>builder(outputFile)
    .withMessage(Organization.class)
    .withCompressionCodec(CompressionCodecName.LZO)
    .config(LzoCodec.LZO_COMPRESSION_LEVEL_KEY, "99")
    .build();
```

**GZIP**

No declara ninguna constante, y hay que usar directamente el String `"zlib.compress.level"`, y los posibles valores van del [0 al 9](https://www.euccas.me/zlib/#zlib_compression_levels), con un valor por defecto de "6".

```java
ParquetWriter<Organization> writer = ProtoParquetWriter.<Organization>builder(outputFile)
    .withMessage(Organization.class)
    .withCompressionCodec(CompressionCodecName.GZIP)
    .config("zlib.compress.level", "9")
    .build();
```

<hr/>

## Pruebas de rendimiento

Para analizar el rendimiento de los distintos algoritmos de compresión voy a usar dos datasets públicos que contienen diferentes tipos de datos:
* [Viajes de taxis en New York:](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page) con gran cantidad de valores numéricos y pocos valores String, en pocas columnas. Tiene 23 columnas y contiene 19,6 millones de registros.
* [Proyectos de cohesión del gobierno de Italia](https://opencoesione.gov.it/en/opendata/#!basedati_section): muchas columnas con valores float y gran cantidad y variedad de cadenas de texto. Tiene 91 columnas y contiene 2 millones de filas.

Evaluaré algunos de los algoritmos de compresión habilitados en Parquet Java: UNCOMPRESSED, SNAPPY, GZIP, LZO, ZSTD, LZ4_RAW

Como no puede ser de otra forma, las pruebas las haré usando [Carpet](https://github.com/jerolba/parquet-carpet) con la configuración por defecto que trae [parquet-java](https://github.com/apache/parquet-java/blob/4aeba6cb7348a8fb57d8585058d27f53ce592b48/parquet-column/src/main/java/org/apache/parquet/column/ParquetProperties.java#L49), y el nivel de compresión por defecto de cada algoritmo.

Puedes encontrar el código fuente [en GitHub](https://github.com/jerolba/parquet-compression) y las pruebas las he hecho en un portatil con CPU AMD Ryzen 7 4800HS y JDK 17.

### Tamaño del fichero

Para entender en qué medida rinde cada compresión, tomaremos como referencia el fichero CSV equivalente.

| Formato | gov.it | NYC Taxis |
|---|---:|---:|
| CSV | 1761 MB |  2983 MB |
| UNCOMPRESSED | 564 MB | 760 MB |
| SNAPPY | 220 MB | 542 MB |
| GZIP | **146 MB** | 448 MB |
| ZSTD | 148  MB | **430 MB** |
| LZ4_RAW | 209 MB | 547 MB |
| LZO | 215 MB | 518 MB |

En ambas pruebas la compresión con GZip y Zstandard destacan como las más eficientes.

Usando sólo técnicas de codificación Parquet es capaz de dejar el fichero en un 25-32% del tamaño original del CSV. Aplicando además la compresión lo deja entre un **9% y un 15% del tamaño del CSV**.

### Escritura

¿Cuánto *overhead* trae el comprimir la información?

Si escribimos la misma información 3 veces y hacemos la media en segundos obtenemos:

| Algoritmo | gov.it | NYC Taxis |
|---|---:|---:|
| UNCOMPRESSED | 25,0 | 57,9 |
| SNAPPY | 25,2 | 56,4 |
| GZIP | 39,3 | 91,1 |
| ZSTD | 27,3 | 64,1 |
| LZ4_RAW | **24,9** | 56,5 |
| LZO | 26,0 | **56,1** |

SNAPPY, LZ4  y LZO obtienen tiempos similares a no comprimir, mientras que ZSTD añade un poco de *overhead*. El peor parado es GZIP, que empeora en un 50% el tiempo de escritura.

### Lectura

La lectura de los ficheros es más rápida que la escritura ya que tiene que realizar menos computaciones.

Leyendo todas las columnas del fichero, los tiempos en segundos son:

| Algoritmo | gov.it | NYC Taxis |
|---|---:|---:|
| UNCOMPRESSED | 11,4 | 37,4 |
| SNAPPY | **12,5** | **39,9** |
| GZIP | 13,6 | 40,9 |
| ZSTD | 13,1 | 41,5 |
| LZ4_RAW | 12,8 | 41,6 |
| LZO | 13,1 | 41,1 |

Los tiempos de lectura son cercanos a no comprimir la información, y el *overhead* de la descompresión está entre el 10% y el 20%.

### Conclusión

Por tiempos de lectura y escritura no hay ningún algoritmo que haya destacado sobre los demás, estando todos en un margen similar. **En la mayoría de los casos comprimir la información compensa el ahorro de espacio (y transmisión) sobre la penalización de tiempo**.

En estos dos casos de uso probablemente el factor determinante para seleccionar uno u otro sería por el ratio de compresión conseguido, destacando especialmente ZSTD y Gzip (pero con un penoso tiempo de escritura).

Cada algoritmo tiene sus puntos fuertes, así que la mejor opción es que hagas pruebas con tus datos teniendo en cuenta qué factor prima más:
 * Minimizar el uso de almacenamiento, porque guardas muchos datos que pocas veces vas a usar.
 * Minimizar el tiempo de generación de ficheros.
 * Minimizar el tiempo de lectura, ya que se leen muchas veces.

Como todo en la vida, es un *trade-off* y te tocará ver qué compensa más. En Carpet por defecto si no configuras nada se comprime con Snappy.

## Detalles de implementación

El valor tiene que ser uno de los disponibles en el enum [CompressionCodecName](https://github.com/apache/parquet-java/blob/master/parquet-common/src/main/java/org/apache/parquet/hadoop/metadata/CompressionCodecName.java#L26). Asociado a cada valor del enum hay el nombre de la clase que implementa el algoritmo:

```java
public enum CompressionCodecName {
  UNCOMPRESSED(null, CompressionCodec.UNCOMPRESSED, ""),
  SNAPPY("org.apache.parquet.hadoop.codec.SnappyCodec", CompressionCodec.SNAPPY, ".snappy"),
  GZIP("org.apache.hadoop.io.compress.GzipCodec", CompressionCodec.GZIP, ".gz"),
  LZO("com.hadoop.compression.lzo.LzoCodec", CompressionCodec.LZO, ".lzo"),
  BROTLI("org.apache.hadoop.io.compress.BrotliCodec", CompressionCodec.BROTLI, ".br"),
  LZ4("org.apache.hadoop.io.compress.Lz4Codec", CompressionCodec.LZ4, ".lz4hadoop"),
  ZSTD("org.apache.parquet.hadoop.codec.ZstandardCodec", CompressionCodec.ZSTD, ".zstd"),
  LZ4_RAW("org.apache.parquet.hadoop.codec.Lz4RawCodec", CompressionCodec.LZ4_RAW, ".lz4raw");
  ...
```

Parquet, mediante reflexión, instanciará la clase especificada, que debe implementar la interface [`CompressionCodec`](https://github.com/apache/hadoop/blob/trunk/hadoop-common-project/hadoop-common/src/main/java/org/apache/hadoop/io/compress/CompressionCodec.java).
Si miráis donde está su código fuente veréis que está dentro del proyecto de Hadoop, no de Parquet. Esto es una muestra de lo acoplado que está Parquet de Hadoop en la implementación de Java.

Para poder usar uno de los codecs deberías asegurarte de que has añadido como dependencia un JAR que contenga su implementación.

No todas las implementaciones están disponibles en las dependencias transitivas que tienes al añadir `parquet-java` o puede que se te haya ido la mano excluyendo dependencias de Hadoop.

En la dependencia `org.apache.parquet:parquet-hadoop` está la implementación de `SnappyCodec`, `ZstandardCodec` y `Lz4RawCodec`, que importa transitivamente las dependencias de `snappy-java`, `zstd-jni` y `aircompressor` con la implementación real de los tres algoritmos.

En la dependencia `hadoop-common:hadoop-common` está la implementación de `GzipCodec`.

¿Dónde está la implementación de `BrotliCodec` y `LzoCodec`? **No están en ninguna de las dependencias de Parquet o Hadoop**, por lo que si lo usas sin meter dependencias adicionales, tu aplicación no funcionará con ficheros comprimidos con esos formatos.
* Para soportar LZO necesitarás añadir la [dependencia](https://central.sonatype.com/artifact/org.anarres.lzo/lzo-hadoop/1.0.1) `org.anarres.lzo:lzo-hadoop` en tu pom o gradle.
* Más complejo aún es el caso de Brotli: la [dependencia](https://github.com/rdblue/brotli-codec) ni siquiera está en maven central y deberás añadir además el repositorio de [JitPack](https://jitpack.io).



