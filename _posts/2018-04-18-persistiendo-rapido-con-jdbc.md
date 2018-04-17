---
layout: post
title: "Persistiendo (rápido) en base de datos: JDBC"
description: "Segundo capítulo de la serie de posts donde vemos cómo persistir información en base datos lo más rápido posible. Esta vez centrado directamente en JDBC."
modified: 2018-04-18
tags: 
image:
  path: images/willie-fineberg-44916-unsplash.jpg
  feature: willie-fineberg-44916-unsplash.jpg
  credit: Willie Fineberg
  creditlink: https://unsplash.com/photos/64iuIOektb4
#  layout: top
excerpt_separator: <!--more-->
---

En el [post anterior](/persistiendo-rapido-en-base-de-datos/) os hablé de cómo persistir vuestra información cuando estáis limitados a JPA, y maneras de conseguir que vaya lo más rápido posible. En esta ocasión veremos cómo persistir la misma información directamente con JDBC, sin intermediarios.

 <!--more-->

Siguiendo la misma estructura del anterior post iré poniendo código y resultados en cada caso. Para simplificar los ejemplos he extraído código que se repite en todos ejemplos: `TripEntityInsert.INSERT` contiene el string con la sentencia insert y los `?` asociados, y el método `tripInsert.setParameters(..)` hace el set de los parámetros en el PreparedStatement.

Todo el código fuente lo tenéis en [este repositorio de GitHub](https://github.com/jerolba/persistence-post).

## Mediante JDBC a pelo

JDBC es la interface básica y estándar para la comunicación en Java con la base de datos y forma parte de Java SE. Personalmente considero que, **junto con la especificación de Servlets, fue la clave para que Java se convirtiera en la herramienta _Enterprise_** a finales de los 90.

Posiblemente es la opción más verbosa de todas, por tener que escribir un montón de código _boilerplate_ y de "bajo nivel". Pero al prescindir de todo el código de librerías y atacar directamente contra el driver, es la que menos _overhead_ tiene.

La incorporación de [try-with-resources](https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html) al lenguaje nos liberó de mucho de ese _boilerplate_, pero por ahora no nos ha librado del mapeo de atributos y nombres.

### PreparedStatement

[Statement](https://docs.oracle.com/javase/8/docs/api/index.html?java/sql/Statement.html) es la forma más simple de enviar sentencias insert, con la query y parámetros en un String. Directamente la doy por superada y la descarto :)

A la hora de repetir muchas veces la misma sentencia, el primer mecanismo que nos permitirá reducir el tiempo de ejecución de nuestras sentencias es el de [PreparedStatements](https://docs.oracle.com/javase/tutorial/jdbc/basics/prepared.html#overview_ps), que reutiliza la información de la query entre una invocación y otra.

Pero el principal motivo que debería llevarnos a utilizar `PreparedStatement` es el evitar ataques de [SQL Injection](https://www.owasp.org/index.php/SQL_Injection_Prevention_Cheat_Sheet)

### 1.- Registro a registro

La versión más sencilla de todas, en donde se ejecuta un `PreparedStatement` tras otro, con la conexión en modo `autocommit` a `true` (tras cada ejecución se hace commit a la base de datos):

```java
connection.setAutoCommit(true);
try (PreparedStatement pstmt = connection.prepareStatement(TripEntityInsert.INSERT)) {
    Iterator<TripEntity> iterator = trips.iterator();
    while (iterator.hasNext()) {
        tripInsert.setParameters(pstmt, iterator.next());
        pstmt.executeUpdate();
    }
}
```

[<img src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=2085781693&format=image">](https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=2085781693&format=interactive)

El resultado me ha dejado totalmente descolocado. Respecto a JPA, en el modo equivalente de "registro a registro", la mejora de MySQL me parece muy pobre (un 3X de mejora), mientras que la de Postgres me parece espectacular (un 30X). Desconozco por ahora el motivo de esa diferencia de comportamiento/rendimiento, y me lo apunto para investigar.

### 2.- Registro a registro en transacciones de 1000 elementos

Como gestionar el propio inicio de la transacción y su cierre lleva tiempo, quitamos el autocommit y sólo hacemos commit cada 1000 elementos:

```java
connection.setAutoCommit(false);
try (PreparedStatement pstmt = connection.prepareStatement(TripEntityInsert.INSERT)) {
    int cont = 0;
    Iterator<TripEntity> iterator = trips.iterator();
    while (iterator.hasNext()) {
        tripInsert.setParameters(pstmt, iterator.next());
        pstmt.executeUpdate();
        cont++;
        if (cont % batchSize == 0) {
            connection.commit();
        }
    }
    connection.commit();
}
```

[<img src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=629816726&format=image">](https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=629816726&format=interactive)

Bien! por fin MySQL parece que hace algo con sentido y consigue un 12X de mejora respecto a la versión anterior, mientras que en Postgres es de sólo el 40%.

Está claro que la gestión de transacciones a MySQL le cuesta, pero no sé si es un problema a nivel de driver JDBC o general de MySQL.

### 3.- En batches de 1000 registros

El siguiente paso natural parece que es persistir la información usando los métodos [addBatch](https://docs.oracle.com/javase/8/docs/api/java/sql/PreparedStatement.html#addBatch--) y [executeBatch](https://docs.oracle.com/javase/8/docs/api/java/sql/Statement.html#executeBatch--) que nos ofrece JDBC.

El método `addBatch` lo único que hace es acumular todas las peticiones que le mandes, y esperar a que se llame a `executeBatch`, para enviar toda la información a la base de de datos.

Que se ejecute en batch **no implica que se ejecute de forma transaccional**, y por tanto si configuras la conexión en autocommit después de cada sentencia que hayas pasado, la base de datos se asegurará de que el resultado se persiste correctamente antes de pasar a la siguiente sentencia (junto con los demás niveles de seguridad que tengas configurado en tu nivel de aislamiento).

En este caso haré un commit asociado a cada batch, evitando hacer una única transacción:

```java
connection.setAutoCommit(false);
try (PreparedStatement pstmt = connection.prepareStatement(TripEntityInsert.INSERT)) {
    int cont = 0;
    Iterator<TripEntity> iterator = trips.iterator();
    while (iterator.hasNext()) {
        TripEntity entity = iterator.next();
        tripInsert.setParameters(pstmt, entity);
        pstmt.addBatch();
        cont++;
        if (cont % batchSize == 0) {
            pstmt.executeBatch();
            connection.commit();
        }
    }
    connection.commit();
    }
```

[<img src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=1972137537&format=image">](https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=1972137537&format=interactive)

Aquí otra vez MySQL vuelve a decepcionarnos y consigue una mejora marginal. Parece que hacer operaciones en batch en MySQL no tiene ningún efecto significativo de por sí.

Mientras que a Postgres le sienta muy bien, y obtiene una mejora de 4X al trabajar en batches.

Al contrario de lo que pasaba en JPA, aquí no tenemos que preocuparnos de los problemas de las claves primarias, y podemos utilizar las secuencias que ofrece el motor de base de datos.

### 4.- Rewrite batch statements

En este caso también podemos utilizar las optimizaciones que ofrecen a nivel de driver JDBC tanto MySQL como Postgres a la hora de ejecutar operaciones batch.

Como ya expliqué en el [anterior post](/persistiendo-rapido-en-base-de-datos/#6--insert-múltiple), agrupa varias sentencias insert en una única, reduciendo aún más el número de operaciones con el servidor, y el trabajo que tiene que hacer con ellas.

El principal motivo para no utilizar por defecto esta configuración es porque no todas las posibles sentencias insert [están soportadas](https://github.com/pgjdbc/pgjdbc/issues/1045), y porque si en una de las sentencias tienes un error no te puede decir en qué parte de la query reescrita está el problema, mientras que con las querys en batch simple, te diría qué sentencia te ha dado el problema.

Si ninguno de estos problemas existe para tí, !yo modificaría YA la configuración de tu conexión a base de datos!

La activación se hace sobre la URL de conexión, añadiendo en MySQL el parámetro `rewriteBatchedStatements` y en Postgres el parámetro `reWriteBatchedInserts`. No es necesario modificar el código, sólo la conexión a base de datos:

[<img src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=1398187399&format=image">](https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=1398187399&format=interactive)

¡Por fin damos con la configuración correcta para MySQL! Esta vez sí hemos conseguido llevarlo a un nivel similar a Postgres, consiguiendo una mejora de 7X.

Postgres por otro lado, habiendo hecho los deberes en otras partes del sistema, "sólo" consigue una mejora del 70% de rendimiento, con cierto margen todavía sobre MySQL.

### ¿Siguiente paso?

Aquí se me acaban los _trucos_ para mejorar el rendimiento dentro de lo que es el ámbito de JDBC.

Nos siguen quedando técnicas sobre la configuración de la base de datos, donde se pueden conseguir algunas pequeñas mejoras cambiando su comportamiento habitual.

Al igual que en el post sobre JPA, he usado 1000 como número de elementos en el batch por ser un número _redondo_, pero estaría bien probar con distintos tamaños para encontrar el más adecuado para cada base de datos e información a persistir. Probablemente los resultados cambien si probamos con otro tamaño de batch.

**En el próximo artículo veremos cómo aún tenemos margen para persistir aún más rápido la información desde Java, aprovechando ciertas funcionalidades propias que nos proveen los drivers JDBC, y las bases de datos que soportan.**

### Conclusión

Hemos visto cómo mejorar fácilmente el rendimiento si puedes evitar tener que pasar por JPA o frameworks similares, llegando a la conclusión de que la forma más rápida es usando operaciones en batch y aprovechando la optimización de reescritura de queries de insert:

<iframe width="600" height="371" seamless frameborder="0" scrolling="no" src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=2049173189&amp;format=image"></iframe>

Claramente la única forma de trabajar de forma eficiente con MySQL es utilizando `rewriteBatchedStatements`, y si lo comparamos con Postgres parece que no realiza de forma muy ineficiente la comunicación con la base de datos. ¿Alguno de vosotros puede arrojarnos luz sobre el tema? A menos que me haya equivocado haciendo algún _setup_, personalmente creo que el rendimiento de MySQL es muy malo si no tienes la oportunidad de sacar partido a su optimización.

Todavía no he probado la [nueva versión del driver JDBC](https://dev.mysql.com/doc/connector-j/8.0/en/connector-j-overview.html) que Oracle está preparando para MySQL. Es el único que soportará la inminente versión 8 de MySQL, y es una reescritura completa del driver. ¿Habrán mejorado algo? El día que lo pruebe os cuento.

### Reconclusión

¿Cómo de diferente es el rendimiento entre JPA y JDBC directo? Lo mejor será mostrar el mejor resultado de cada opción, frente a frente:

<iframe width="600" height="371" seamless frameborder="0" scrolling="no" src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=791937749&amp;format=interactive"></iframe>

La mejora es de entorno a un 50% y un 25%, y no es de un orden de magnitud como alguno podría esperar.

Antes de tomar mis resultados como algo extrapolable a vuestro problema, os invito a que hagáis las pruebas con vuestros datos y saquéis conclusiones. Probablemente varíen, ya sea por la forma de los datos, la configuración del servidor o la simple latencia de red.

**La configuración de estos benchmark es la misma que en [el último post](/persistiendo-rapido-en-base-de-datos/setup-del-benchmark).**