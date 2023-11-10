---
layout: post
title: "Persistiendo muy rápido en base de datos: JFleet"
description: "Último capítulo de la serie de posts donde vemos cómo persistir información en base datos lo más rápido posible. Además se presenta la herramienta JFleet"
modified: 2018-05-05
tags:
image:
  path: images/PlanesFleet.jpg
  feature: PlanesFleet.jpg
  credit: Robinson Kuntz
  creditlink: https://www.dailyrepublic.com/media-post/photo-kc-10-fleet-fate-up-in-the-air/attachment/kc-10-9_11_13/
excerpt_separator: <!--more-->
---

En los anteriores artículos os hablé de cómo persistir vuestra información lo más rápido posible [cuando estáis limitados a JPA](/persistiendo-rapido-en-base-de-datos/) y [cómo hacerlo con sólo JDBC](/persistiendo-rapido-con-jdbc/). A pesar de que JDBC sea la pieza básica de comunicación con la base de datos, hay formas de saltarsela y, sin salir de la JVM, persistir la información aún más rápido con la ayuda de ciertos métodos de los drivers JDBC de cada base de datos.

Spoiler: Al final del post os presentaré JFleet, una librería que os permitirá hacer esto de una forma muy sencilla.

 <!--more-->

## Los comandos `LOAD DATA` y `COPY`

El lenguaje para comunicarnos con las bases de datos es SQL y el 99.99% del tiempo es el mecanismo que usamos para comunicarnos con ellas. Pero si os fijáis, cuando hacemos inserts en una tabla con un insert múltiple en una sentencia:

```
INSERT INTO persona (dni, nombre, edad) VALUES
 ('12345Z', 'Alberto Zaplana', 26),
 ('98765A', 'Zoe Alarcón', 62);
```

si le quitamos la sintaxis SQL, lo que nos queda es un CSV:

```
dni,nombre,edad
'12345Z','Alberto Zaplana',26
'98765A','Zoe Alarcón',62
```

que es mucho más fácil de parsear, interpretar e insertar en una estructura de tablas "idéntica".

Por eso a las bases de datos, en un import grande, les gusta más los datos en formato CSV que como una query. En MySQL tenemos el comando [`LOAD DATA`](https://dev.mysql.com/doc/refman/5.7/en/load-data.html), en Postgres el comando [`COPY`](https://www.postgresql.org/docs/9.6/static/sql-copy.html) y el Sql Server, el comando [`BULK INSERT`](https://docs.microsoft.com/en-us/sql/t-sql/statements/bulk-insert-transact-sql?view=sql-server-2017).

El mayor problema es establecer el formato del CSV, ya que normalmente es necesario fijar cosas como:

- Cuál será el carácter separador de columnas
- Si las cadenas necesitan estar entrecomilladas y con qué carácter
- Cuál será el carácter de cambio de línea/registro
- Cuál será el carácter para indicar el valor nulo (normalmente en CSV que no exista valor es cadena vacía, distinto del valor nulo).
- Cuál será el carácter para escapar cuando nos encontremos un carácter de los anteriores.

Un ejemplo de cada comando con mi dataset de ejemplo sería:

- Sobre el fichero `mifichero.csv` con un formato preparado para ser consumido:

```
23	2016-01-01 00:00:00	2016-01-01 00:16:00	268	Howard St & Centre St	40.71910537	-73.99973337	3002	South End Ave & Liberty St	40.711512	-74.015756	22285	Subscriber	1958	1
379	2016-01-01 00:00:00	2016-01-01 00:07:00	476	E 31 St & 3 Ave	40.74394314	-73.97966069	498	Broadway & W 32 St	40.74854862	-73.98808416	17827	Subscriber	1969	1
589	2016-01-01 00:00:00	2016-01-01 00:10:00	489	10 Ave & W 28 St	40.75066386	-74.00176802	284	Greenwich Ave & 8 Ave	40.7390169121	-74.0026376103	21997	Subscriber	1982	2
889	2016-01-01 00:01:00	2016-01-01 00:15:00	268	Howard St & Centre St	40.71910537	-73.99973337	3002	South End Ave & Liberty St	40.711512	-74.015756	22794	Subscriber	1961	2
1480	2016-01-01 00:01:00	2016-01-01 00:25:00	2006	Central Park S & 6 Ave	40.76590936	-73.97634151	2006	Central Park S & 6 Ave	40.76590936	-73.97634151	14562	Subscriber	\N	1
```

- Para MySQL:

```
LOAD DATA LOCAL INFILE 'mifichero.csv' INTO TABLE bike_trip CHARACTER SET UTF8
    FIELDS TERMINATED BY '\t' ENCLOSED BY '' ESCAPED BY '\\'
    LINES TERMINATED BY '\n' STARTING BY ''
(tripduration, starttime, stoptime, start_station_id, start_station_name,
 start_station_latitude, start_station_longitude, end_station_id,
 end_station_name, end_station_latitude, end_station_longitude,
 bike_id, user_type, birth_year, gender)
```

- Para Postgres:

```
COPY bike_trip (tripduration, starttime, stoptime, start_station_id,
 start_station_name, start_station_latitude, start_station_longitude,
 end_station_id, end_station_name, end_station_latitude,
 end_station_longitude, bike_id, user_type, birth_year, gender)
FROM 'mifichero.csv' WITH (FORMAT TEXT, ENCODING 'UTF-8', DELIMITER '\t', HEADER false)
```

A pesar de ser comandos especiales a ejecutar en sus líneas de comandos, las distintas implementaciones de los drivers JDBC lo han incorporado como extensión fuera del estándar.

Su funcionamiento es el mismo en todos los casos: le pasamos al driver una sentencia similar a la que escribiríamos en línea de comandos y le _adjuntamos_ un `InputStream` con el CSV (en [MySQL](https://github.com/spullara/mysql-connector-java/blob/master/src/main/java/com/mysql/jdbc/Statement.java#L77) y en [Postgres](https://github.com/pgjdbc/pgjdbc/blob/master/pgjdbc/src/main/java/org/postgresql/copy/CopyManager.java#L216)).

En cada caso requiere hacer distintas acciones sobre la conexión y lo mejor será verlo directamente con código real. Esta vez tendremos más código del habitual.

El código hará lo mismo que hemos hecho hasta ahora, intentando persistir la información en bloques de 1000 registros, con commits en cada batch (en este caso estará en autocommit), y mediremos el número de registros persistidos por segundo para poder comparar.

## MySQL: `LOAD DATA`

De la conexión que nos haya devuelto el _datasource_, primero debemos obtener un objeto con la interface `Connection` propia de MySQL. De alguna manera haremos un _casting_ hacia la interface que le pasamos. Si no pudiera nos lanzaría una excepción.

Con eso ya podemos acceder al método `setAllowLoadLocalInfile` que habilita al driver a utilizar el comando.

```java
com.mysql.jdbc.Connection unwrapped = connection.unwrap(com.mysql.jdbc.Connection.class);
unwrapped.setAllowLoadLocalInfile(true);
```

Luego ya sólo necesitaremos formar el CSV a partir de los objetos que tengamos en memoria según el formato que hayamos definido:

```java
String LOADDATA = "LOAD DATA LOCAL INFILE '' INTO TABLE `bike_trip` "
+ "CHARACTER SET UTF8 FIELDS TERMINATED BY '\t' ENCLOSED BY '' "
+ "ESCAPED BY '\\\\' LINES TERMINATED BY '\n'  STARTING BY '' "
+ "(tripduration, starttime, stoptime, start_station_id, start_station_name, "
+ "start_station_latitude, start_station_longitude, end_station_id, "
+ "end_station_name, end_station_latitude, end_station_longitude, "
+ "bike_id, user_type, birth_year, gender)";

int cont = 0;
StringBuilder sb = new StringBuilder();
Iterator<TripEntity> iterator = trips.iterator();
while (iterator.hasNext()) {
    TripEntity trip = iterator.next();
    sb.append(trip.getTripduration()).append("\t");
    sb.append(sdfDateTime.format(trip.getStarttime())).append("\t");
    sb.append(sdfDateTime.format(trip.getStoptime())).append("\t");
    sb.append(trip.getStartStationId()).append("\t");
    sb.append(trip.getStartStationName()).append("\t");
    sb.append(trip.getStartStationLatitude()).append("\t");
    sb.append(trip.getStartStationLongitude()).append("\t");
    sb.append(trip.getEndStationId()).append("\t");
    sb.append(trip.getEndStationName()).append("\t");
    sb.append(trip.getEndStationLatitude()).append("\t");
    sb.append(trip.getEndStationLongitude()).append("\t");
    sb.append(trip.getBikeId()).append("\t");
    sb.append(trip.getUserType()).append("\t");
    sb.append(nullify(trip.getBirthYear())).append("\t");
    sb.append(trip.getGender()).append("\t");
    sb.append("\n");
    cont++;
```

Cuando hayamos llegado al tamaño correspondiente del batch, le pasamos el CSV mediante un método propio de su implementación de `Statement`, que es necesario castear esta vez a mano:

```java
    if (cont % batchSize == 0) {
        InputStream is = new ByteArrayInputStream(sb.toString().getBytes());
        Statement statement = (Statement) unwrapped.createStatement();
        statement.setLocalInfileInputStream(is);
        statement.execute(LOADDATA);
        sb.setLength(0);
    }
}
```

El método guarda en una variable interna del objeto `Statement` el `InputStream` de donde leer el CSV a enviar a la base de datos.
Como es información generada al vuelo, lo meto en un `InputStream` en memoria.

Luego ejecutamos la sentencia de `LOAD DATA` como un _statement_ más, y la base de datos internamente nos responderá que necesita la información. El driver finalmente le enviará a la base de datos todo el contenido del `InputStream`.

## Postgres: `COPY`

En el caso de Postgres, está mejor hecho y no tenemos que modificar un flag de la conexión para que haga algo excepcional, sino que simplemente tenemos que pedirle un objeto especial que se encarga de toda esa parte: el `CopyManager`.

```java
PgConnection unwrapped = connection.unwrap(PgConnection.class);
CopyManager copyManager = unwrapped.getCopyAPI();
```

Igualmente tenemos que formar el CSV con los valores a persistir según el formato que usemos (en este ejemplo usaré el formato [TEXT](https://www.postgresql.org/docs/9.6/static/sql-copy.html#AEN77946)):

```java
String COPY = "COPY bike_trip (tripduration, starttime, stoptime,"
+ "start_station_id, start_station_name, start_station_latitude, "
+ "start_station_longitude, end_station_id, end_station_name,"
+ "end_station_latitude, end_station_longitude, bike_id,"
+ "user_type, birth_year, gender)"
+ " FROM STDIN WITH (FORMAT TEXT, ENCODING 'UTF-8', DELIMITER '\t',"
+ " HEADER false)";

int cont = 0;
StringBuilder sb = new StringBuilder();
Iterator<TripEntity> iterator = trips.iterator();
while (iterator.hasNext()) {
    TripEntity trip = iterator.next();
    sb.append(trip.getTripduration()).append("\t");
    sb.append(sdfDateTime.format(trip.getStarttime())).append("\t");
    sb.append(sdfDateTime.format(trip.getStoptime())).append("\t");
    sb.append(trip.getStartStationId()).append("\t");
    sb.append(trip.getStartStationName()).append("\t");
    sb.append(trip.getStartStationLatitude()).append("\t");
    sb.append(trip.getStartStationLongitude()).append("\t");
    sb.append(trip.getEndStationId()).append("\t");
    sb.append(trip.getEndStationName()).append("\t");
    sb.append(trip.getEndStationLatitude()).append("\t");
    sb.append(trip.getEndStationLongitude()).append("\t");
    sb.append(trip.getBikeId()).append("\t");
    sb.append(trip.getUserType()).append("\t");
    sb.append(nullify(trip.getBirthYear())).append("\t");
    sb.append(trip.getGender());
    sb.append("\n");
    cont++;
```

y por último cuando alcancemos el número de registros del batch, mandaremos el CSV a la base de datos con el `CopyManager`, usando también un InputStream en memoria:

```java
    if (cont % batchSize == 0) {
        InputStream is = new ByteArrayInputStream(sb.toString().getBytes());
        copyManager.copyIn(COPY, is);
        sb.setLength(0);
    }
}
```

## Resultados

Tras ejecutar el código (que tenéis disponible [aquí](https://github.com/jerolba/persistence-post)) obtenemos los siguientes valores:

[<img src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=712589279&format=image"/>](https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=712589279&format=interactive)

¡Por primera vez superamos la barrera de los 50.000 registros por segundo!

Pero para saber cuánto hemos conseguido mejorar, comparemos con los resultados de los post pasados:

<iframe width="640" height="371" seamless frameborder="0" scrolling="no" src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=1137378401&amp;format=interactive"></iframe>

¡No está mal!, en torno a un 50% de mejora de rendimiento comparado con la versión más compleja de JDBC y entre un 80% y un 130% más rápido que la de JPA.

## ¿Siguiente paso?

Existen más técnicas para mejorar la velocidad de inserción, y algunas que he ido viendo por ahí (y no he probado todas) son:

- Prueba con distintos tamaños de batch. Cada tabla te pedirá un tamaño distinto dependiendo de sus tipos de datos y tamaños.
- Si estás haciendo una carga desde cero, desactiva los índices al empezar y actívalos al terminar. Crear los índices sobre toda la tabla cuesta menos que crearlos según se insertan los datos.
- Lo mismo pasa con las Foreign Keys, mejor no tenerlos cuando estás haciendo los inserts. Si tu lógica de negocio te lo permite, le ahorrarás tener que validar cada referencia.
- Si tus datos ya contienen la Primary Key, a MySQL le gusta más que se los insertes ordenados por ella.
- Tunea la configuración de la base de datos para minimizar la escritura a disco, o la memoria dedicada a tareas específicas de insert:
    - En Postgres modificando los valores de [`maintenance_work_mem`](https://www.postgresql.org/docs/9.5/static/runtime-config-resource.html#GUC-MAINTENANCE-WORK-MEM) y [`max_wal_size`](https://www.postgresql.org/docs/9.5/static/runtime-config-wal.html#GUC-MAX-WAL-SIZE), [desactivando la escritura del WAL](https://blog.4xxi.com/sacrificing-resilience-for-performance-with-postgresql-wal-unlogged-tables-d8db7253160b) o [creando tablas `UNLOGGED`](https://www.compose.com/articles/faster-performance-with-unlogged-tables-in-postgresql/)
    - En MySQL puedes tunear las variables [`bulk_insert_buffer_size`](https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_bulk_insert_buffer_size), [`innodb_autoinc_lock_mode`](https://dev.mysql.com/doc/refman/8.0/en/innodb-parameters.html#sysvar_innodb_autoinc_lock_mode) o el [tamaño del fichero de log](https://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html#sysvar_innodb_log_file_size)

Respecto a los dos últimos puntos, documentaros bien antes de hacer nada, porque las consecuencias pueden ser catastróficas.

También os recomiendo revisar vuestra configuración de la base de datos con alguien que sepa, ya que normalmente la configuración por defecto que suele venir cuando haces el típico `apt-get install ....` suele ser muy conservadora, y necesita estar adaptada a las características de memoria y CPU de vuestro servidor, el tipo de carga de trabajo, e incluso al sistema de ficheros que tengáis por debajo.

## One more thing...

![Steve Jobs one more thing](/images/steve-jobs-one-more-thing.jpg){: .mx-auto.d-block :}

Poder usar los comandos `LOAD DATA` y `COPY` está muy bien porque permite exprimir la última gota de rendimiento a la hora de persistir muchos datos, pero el ejemplo que os he puesto es sencillo para ilustrar cómo usarlo, y la cosa se complica si quieres usarlo bien.

Por cómo son los datos del ejemplo, no he tenido que lidiar mucho con los nulos, con formatos o tener que escapar los caracteres especiales. La sintaxis de los comandos no es estándar SQL y es difícil de portar, y el código se vuelve aún más feo si además tienes que andar concatenando _strings_ en un `StringBuilder` si no te quieres cargar el rendimiento que pretendes ganar.

Cuando me documenté sobre el tema para no tener que hacerlo a mano, estuve buscando si había alguna librería que me abstrayera de esto y que me permitiera fácilmente persistir los datos con estos mecanismos, pero no la encontré. Así que... ¿por qué no crear una?! y de ahí nació [JFleet](https://github.com/jerolba/jfleet).

**JFleet te permite guardar grandes colecciones de datos en una tabla usando el mecanismo más rápido disponible en cada base de datos.**

Para no extenderme mucho más en este post, os invito a entrar en su web [https://github.com/jerolba/jfleet](https://github.com/jerolba/jfleet) y que le echéis un vistazo a la documentación para ver cómo funciona, y que **me déis todo el _feedback_ posible**.

La librería está publicada en Maven Central, y es un proyecto de **código abierto** con licencia Apache 2, por lo que se aceptan todo tipo de contribuciones para mejorarla y arreglar _bugs_ (que seguro que alguno tiene).

Aunque he intentado que la documentación cubra todo lo que necesites saber para usar JFleet, y tener algunos [ejemplos](https://github.com/jerolba/jfleet/tree/master/jfleet-samples/src/main/java/org/jfleet/citibikenyc) de uso, en próximos posts intentaré enseñar ejemplos interesantes y características reseñables.

Cualquier duda sobre su funcionamiento no dudéis es preguntarme por aquí, con un _issue_ o directamente en [StackOverflow](https://stackoverflow.com/search?q=jfleet).
