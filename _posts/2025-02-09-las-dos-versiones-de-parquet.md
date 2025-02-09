---
layout: post
title: "Las dos versiones de Parquet"
description: "La adopción de la versión 2 de Parquet es limitada debido a la falta de soporte en el ecosistema, lo que afecta su evolución a pesar de sus mejoras en compresión y rendimiento."
modified: 2025-02-09
tags:
excerpt_separator: <!--more-->
---

Hace pocos días los creadores de DuckDB escribieron el artículo:
[Query Engines: Gatekeepers of the Parquet File Format](https://duckdb.org/2025/01/22/parquet-encodings.html), donde explicaban que los *engines* que procesan ficheros Parquet como tablas SQL están bloqueando la evolución del formato.
Esto es debido a que no terminan de soportar la última especificación, y sin ello, el resto del ecosistema no tiene incentivos para adoptarlo.

<!--more-->

En mi experiencia, esto no se limita sólo a los Query Engines, sino a las propias herramientas del ecosistema. Al poco tiempo de sacar la primera versión de [Carpet](https://github.com/jerolba/parquet-carpet) descubrí que había una versión 2 del formato y que la librería base no lo activa por defecto. Como la especificación llevaba tiempo cerrada consideré que lo mejor era [hacer que Carpet usara por defecto la versión 2](https://github.com/jerolba/parquet-carpet/commit/eecb813cdbddfde9a4b27c46104c5a8969ef4477).

A la semana descubrí en el trabajo por las malas que si no estás a la última de Pandas en Python, no puedes leer ficheros escritos con la versión 2. Tuve que hacer [rollback del cambio](https://github.com/jerolba/parquet-carpet/commit/983f87ec23b1d3c5c091daa4dc7dfb95c919f6ef) corriendo.

## Versión 2 de Parquet

Si te pones a investigar sobre el tema descubres que aunque el formato esté cerrado, no está implementado en todo el ecosistema.
Además, lo normal sería aceptar que el estándar es lo que se diga la especificación, pero realmente no hay un acuerdo sobre cuál es el mínimo conjunto de funcionalidades que debe soportar una implementación para ser compatible con la versión 2.

En [esta Pull Request](https://github.com/apache/parquet-format/pull/164), del proyecto que describe el formato del fichero, **llevan 4 años discutiendo sobre qué es el *core***, y no tiene visos de que vayan a llegar a un acuerdo pronto. Leyendo [este otro hilo](https://lists.apache.org/thread/th3ls02pd1yn74mtj12s05tbbx0x8bjj) de la lista de distribución, llego a la conclusión de que aunque formen parte de la especificación, se mezclan dos conceptos que podrían evolucionar de forma independiente:

* Dada una serie de valores de una columna, cómo se codifican de forma eficiente. Poder incorporar nuevas codificaciones como `RLE_DICTIONARY` o `DELTA_BYTE_ARRAY`, que mejoran más aún la compresión.
* Dada la información de una columna codificada, dónde escribirla dentro del fichero junto con su metainformación sobre cabeceras, nulos o estadísticas, que ayude a maximizar la metainformación disponible mientras que minimiza su tamaño y el número de lecturas del fichero. Es lo que llaman Data Page V2.

Probablemente a muchos les gustaría priorizar las mejoras de la codificación sobre la estructura de páginas. Encontrarse un fichero que usa un encoding desconocido haría que no pudieras leer una columna, pero un cambio en cómo se estructuran las páginas haría ilegible todo el fichero.

Lo que sí me ha parecido entender es que los [tipos lógicos](https://github.com/apache/parquet-format/blob/master/LogicalTypes.md) nuevos no se asocian a una versión del formato. Por un lado están los tipos primitivos que sí son fijos, pero encima suyo se van definiendo los tipos lógicos: una fecha es una representación de un `int64`, un Big Decimal o String se representan con un `BYTE_ARRAY`. Ahora se está [definiendo el tipo](https://github.com/apache/parquet-format/blob/master/LogicalTypes.md#variant) `VARIANT` y no he visto que esté asociado a ninguna de las dos versiones.

Mientras tanto en el mundo de Machine Learning, Parquet y ORC se les han quedado pequeños y requieren funcionalidades especiales, como poder procesar ficheros con muchos miles de columnas. Para resolverlo recientemente han surgido dos formatos que cubren sus casos de uso: [Nimble](https://github.com/facebookincubator/nimble) de Facebook y [LV2](https://blog.lancedb.com/lance-v2/) de LanceDB.

Si quieres profundizar en el tema, te recomiendo [este artículo introductorio](https://materializedview.io/p/nimble-and-lance-parquet-killers). Considero que estos dos formatos son de nicho y que **Parquet seguirá siendo la reina del mundo de la ingeniería de datos**.

## Performance de la Versión 2

Al leer el artículo de DuckDB, me di cuenta de que no había considerado medir su rendimiento en mi [último artículo sobre algoritmos de compresión](/algoritmos-compresion-parquet/).

Configurar la escritura de ficheros con la versión 2 es muy sencillo, sólo hay que configurar la propiedad en el *builder* del writer:

```java
CarpetWriter<T> writer = new CarpetWriter.Builder<>(outputFile, clazz)
    .withWriterVersion(WriterVersion.PARQUET_2_0)
    .build();
```

### Tamaño del fichero

Dataset del gobierno de Italia:

| Formato | Version 1| Version 2 | Mejora |
|---|---:|---:|---:|
| CSV | 1761 MB | 1761 MB | - |
| UNCOMPRESSED | 564 MB | 355 MB | 37 % |
| SNAPPY | 220 MB | 198 MB | 10 % |
| GZIP | 146 MB | 138 MB | 5 % |
| ZSTD | 148  MB | 144 MB | 2 % |
| LZ4_RAW | 209 MB | 192 MB | 8 % |
| LZO | 215 MB | 195 MB | 9 % |

Dataset de taxis de New York:

| Formato | Version 1 | Version 2 | Mejora |
|---|---:|---:|---:|
| CSV | 2983 MB | 2983 MB | - |
| UNCOMPRESSED |  760 MB | 511 MB | 33 % |
| SNAPPY | 542 MB | 480 MB | 11 % |
| GZIP | 448 MB | 444 MB| 1 % |
| ZSTD | 430 MB | 444 MB | -3 % |
| LZ4_RAW |  547 MB | 482 MB | 12 % |
| LZO |  518 MB | 479 MB | 7 % |

Se nota que los encodings nuevos permiten compactar más información de forma directa, y la versión UNCOMPRESSED reduce considerablemente su trabajo, dejando menos margen de mejora a los distintos algoritmos de compresión (o incluso empeorándolo ligeramente como ZSTD).

### Escritura

Dataset del gobierno de Italia en segundos:

| Formato | Version 1 | Version 2 | Mejora |
|---|---:|---:|---:|
| UNCOMPRESSED | 25,0 | 23,6 | 6 % |
| SNAPPY | 25,2 | 23,5 | 7 % |
| GZIP | 39,3 | 35,8 | 9 % |
| ZSTD | 27,3 | 25,7 | 6 % |
| LZ4_RAW | 24,9 | 23,8 | 4 % |
| LZO | 26,0 | 24,6 | 5 % |

Dataset de taxis de New York en segundos:

| Formato | Version 1 | Version 2 | Mejora |
|---|---:|---:|---:|
| UNCOMPRESSED | 57,9 | 50,2 | 13 % |
| SNAPPY | 56,4 | 50,7 | 10 % |
| GZIP | 91,1 | 66,9 | 27 % |
| ZSTD | 64,1 | 57,1 | 11 % |
| LZ4_RAW | 56,5 | 50,5 | 11 % |
| LZO | 56,1 | 51,1 | 9 % |

La mejora en los tiempos de escritura es reseñable, pero sobre todo en el dataset de taxis en Nueva York, con mayoría de valores numéricos. Destacar especialmente la mejora de los tiempos del formato GZIP.

### Lectura

Dataset del gobierno de Italia en segundos:

| Formato | Version 1 | Version 2 | Mejora |
|---|---:|---:|---:|
| UNCOMPRESSED | 11,4 | 11,3 | 1 % |
| SNAPPY | 12,5 | 11,5 | 8 % |
| GZIP | 13,6 | 12,8 | 6 % |
| ZSTD | 13,1 | 12,2 | 7 % |
| LZ4_RAW | 12,8 | 11,3 | 12 % |
| LZO | 13,1 | 12,1 | 7 % |

Dataset de taxis de New York en segundos:

| Formato | Version 1 | Version 2 | Mejora |
|---|---:|---:|---:|
| UNCOMPRESSED | 37,4 | 33,0 | 12 % |
| SNAPPY | 39,9 | 34,0 | 15 % |
| GZIP | 40,9 | 34,4 | 16  % |
| ZSTD | 41,5 | 34,1 | 18 % |
| LZ4_RAW | 41,5 | 33,6 | 19 % |
| LZO | 41,1 | 33,7 | 18 % |

En la lectura otra vez vemos una mejora destacable, pero mejor aún en el dataset de taxis con muchos tipos decimales.

## Conclusión

Aunque este post pueda parecer una crítica contra Parquet, no es mi intención.
Simplemente intento dejar por escrito las cosas que he ido aprendiendo y explicar las dificultades que tienen los mantenedores de un formato abierto a la hora de evolucionarlo.
**Todas las bondades y utilidades que tiene un formato como Parquet superan con creces estos inconvenientes**.

Las mejoras que trae la última versión de Parquet ayudan a que los ficheros sean menos pesados y se tarde menos en procesarlos, pero la diferencia no es espectacular.
Dada la escasa adopción de la versión 2 en el ecosistema, por ahora esas mejoras no ayudan a justificar potenciales problemas de compatibilidad cuando te integras con terceras personas.
Por el contrario, si controlas todas las partes del proceso, considera el adoptar la última especificación.

La mayor parte de lo que he escrito es mi interpretación y es posible que esté equivocado. Si tienes mejores fuentes o una opinión diferente, compártela en los comentarios.