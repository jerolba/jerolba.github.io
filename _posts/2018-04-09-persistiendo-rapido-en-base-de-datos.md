---
layout: post
title: "Persistiendo (rápido) en base de datos: JPA"
description: "Serie de posts donde veremos cómo persistir tu información en base datos lo más rápido posible. Primer post hablando de JPA."
modified: 2018-04-09
tags: 
image:
  path: images/fast-database.jpg
  feature: fast-database.jpg
#  layout: top
excerpt_separator: <!--more-->
---
A lo largo de mi carrera profesional, cuando una base de datos tenía varios millones de registros consideraba que manejábamos un gran volumen de datos (sin llegar al Big Data). En Otogami llegamos a manejar un histórico de unas decenas de millones de registros y ya se me hacía muy pesado.

**Trabajando en [Nextail](http://nextail.co/)** he visto que esos millones de registros eran calderilla, y que el volumen de datos que manejaba era bajo comparado con lo que es capaz de gestionar una base de datos moderna.<!--more-->

En Nextail cualquier dato de nuestros clientes es relevante, y por cada uno manejamos tablas con **miles de millones de filas**, llevando a la base de datos al límite.

La parte en la que estoy yo más centrado es la que hace toda la magia de nuestro producto, donde se magrea toda la información y se realizan todas las operaciones matemáticas para calcular cual es la distribución óptima de la mercancía de nuestros clientes. Como no puede ser de otra forma, está **construida con Java**.

Simplificándolo mucho, cualquier proceso de negocio se puede dividir en tres complejas fases:

- Carga de la información
- Procesamiento de la información según tus reglas de negocio produciendo nueva información
- Persistencia de la información generada

Nuestros procesos dan como resultado millones de registros nuevos que hay que persistir, y en los que se puede ir **el 20% del tiempo total del proceso**.

## ¿Qué me quieres contar, Jero?

En este post me centraré en el último punto: **cómo persistir la información en base de datos de la forma más rápida posible** (sin pérdida de datos por supuesto), y en concreto persistir nueva información (INSERT), no en actualizarla (UPDATE).

A raíz de la curiosidad sobre cómo llevar esa información a la base de datos de la forma más rápida posible y las distintas cosas que he ido descubriendo, me he decidido a escribir un post sobre **cómo mejorar la persistencia** y **errores comunes que podemos cometer**.

Para ilustrar el tema, plantearé un ejemplo de código que cargará un [juego de datos](https://www.citibikenyc.com/system-data) y lo persistirá en base de datos siguiendo diferentes técnicas. El código resultante lo podréis encontrar en [este repositorio de GitHub](https://github.com/jerolba/persistence-post).

El objetivo consiste en persistir datos en **una única tabla**, sin relaciones ni nada más allá de una simple tabla con muchas filas. Soy consciente de que JPA, que viene a resolver ese tipo de problemas, no podrá lucirse y no saldrá bien representado.

En el proceso iré poniendo código desde la versión más sencilla y lenta, hasta la más rápida, explicando qué cambios voy haciendo y porqué se mejora.

Además pongo la restricción de **no poder hacer todo el proceso en una única transacción**. Es necesario hacer la persistencia en múltiples commits, para no perder potencialmente información y para no agobiar a la base de datos con una transacción muy larga.

Para ver qué efecto tiene cada cambio según el motor de base de datos, tomaré métricas sobre las dos bases de datos _open source_ más populares: **MySQL y Postgres**. No es objetivo del post hacer una comparativa y descubrir qué base de datos es más rápida, aunque todo el mundo sabe cual es mejor :D

## Mediante JPA

Probablemente sea la librería de [persistencia más usada por los javeros](https://twitter.com/jerolba/status/979786402178240513) y también la que más odios genere (posiblemente sea porque la convertimos en nuestro martillo de la persistencia). Los ejemplos y métricas los haré con la implementación más usada y que mejor conozco: **Hibernate**.

### 1.- Registro a registro

Consistiría en persistir cada registro uno a uno según vamos iterando la colección. Es la versión más simple de todas, y simplificándolo y sustituyendo el comportamiento detrás de alguna anotación `@Transactional` de vuestro framework preferido, podríamos encontrarnos algo como esto:

```java
EntityTransaction tx = entityManager.getTransaction();
Iterator<TripEntity> iterator = trips.iterator();
while (iterator.hasNext()) {
    tx.begin();
    entityManager.persist(iterator.next());
    tx.commit();
}
```

[<img src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=1296644700&format=image"/>](https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=1296644700&format=interactive)

Un rendimiento bastante decepcionante la verdad.

### 2.- Registro a registro en transacciones de 1000 elementos

La primera mejora podría ser hacer que cada transacción la formara un conjunto grande de registros, ya que actualmente está creando una transacción por registro.

```java
EntityTransaction tx = entityManager.getTransaction();
Iterator<TripEntity> iterator = trips.iterator();
tx.begin();
int cont = 0;
while (iterator.hasNext()) {
    entityManager.persist(iterator.next());
    cont++;
    if (cont % batchSize == 0) {
        tx.commit();
        tx.begin();
    }
}
tx.commit();
```

[<img src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=751741576&format=image"/>](https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=751741576&format=interactive)

¡Una mejora de más de 20X! No era muy difícil partiendo de donde partíamos :)

### 3.- Flush

Por cómo funciona Hibernate (y el resto de implementaciones de JPA), para hacer toda su magia necesita mantener el control de todas las entidades que van pasando por él. Todas estas entidades las gestiona el `EntityManager`, manteniendo la unicidad de instancias, su estado y su ciclo de vida.

Cuantos más registros persistes, más entidades acaban en el `EntityManager`, más memoria ocupan y más objetos tiene que gestionar al hacer ciertas operaciones. Una de ellas es el `flush`, y la ejecuta por ejemplo cada vez que hacemos un commit.

Por tanto, si vas a persistir muchos registros, no te interesará tenerlos todos en el contexto y podrás limpiarlo a menudo, haciendo explícitamente el `flush` y el `clear` del `EntityManager`

```java
EntityTransaction tx = entityManager.getTransaction();
Iterator<TripEntity> iterator = trips.iterator();
tx.begin();
int cont = 0;
while (iterator.hasNext()) {
    entityManager.persist(iterator.next());
    cont++;
    if (cont % batchSize == 0) {
        entityManager.flush();
        entityManager.clear();
        tx.commit();
        tx.begin();
    }
}
tx.commit();
```

[<img src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=1835514121&amp;format=image"/>](https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=1835514121&format=image)

Hemos mejorado en torno a un 2X el rendimiento, y seguramente habremos evitado algún que otro `OutOfMemoryError`.

### 4.- En batches de 1000 registros

Hasta ahora he podido dar a entender que las operaciones contra base de datos se realizan por cada llamada al método `entityManager.persist(iterator.next())`. Pero no es así cómo funciona JPA.

JPA implementa el patrón de diseño de [_Unit of work_](https://martinfowler.com/eaaCatalog/unitOfWork.html), y almacena en el EntityManager los objetos nuevos, borrados y modificados, y él es quien decide cuando tiene que realizar las operaciones contra base de datos.

Se encarga de mantener un estado consistente de los cambios que has realizado, y si en una consulta le pides un objeto que has modificado en una operación anterior, ya se preocupa de devolvértelo aunque no se haya hecho todavía el update en la base de datos. Es parte de la magia y complejidad de un ORM.

Por tanto, en vez de enviar las operaciones de inserción una a una según vas llamándole, **Hibernate las acumula y las ejecuta todas** en una sucesión de llamadas a la base de datos.

Pero en vez de hacer un viaje a la base de datos por insert asociado a cada nuevo objeto creado, podemos decirle a Hibernate que los agrupe en _batches_  modificando el parámetro de configuración de `hibernate.jdbc.batch_size`. De esta forma sólo hará un viaje a la base de datos con todas las órdenes de inserción.

Para que nuestro proceso sea óptimo, sólo tenemos que preocuparnos de hacer que el valor del parámetro de `batch_size` coincida con el número de elementos que hayamos elegido para hacer el flush, si no estará desincronizado cada vez que hagamos flush con el número de elementos sobre los que hacer el batch.

[Vlad Mihalcea](https://twitter.com/vlad_mihalcea) lo explica mejor que yo en [este magnífico post](https://vladmihalcea.com/the-best-way-to-do-batch-processing-with-jpa-and-hibernate/) (no os perdáis su blog y su libro si os interesan los temas de persistencia de base de datos).

Si revisamos el código que tenemos hasta ahora vemos que coincide con lo que escribe Vlad, y lo único que tenemos que hacer es añadir la propiedad de `batch_size` en la configuración de Hibernate (en tu código probablemente vaya en un fichero XML o de properties):

```java
EntityManagerFactoryFactory factory = new EntityManagerFactoryFactory(dsFactory, TripEntity.class) {
    @Override
    public Properties properties() {
        Properties properties = super.properties();
        properties.put("hibernate.jdbc.batch_size", batchSize);
        return properties;
    }
};
```

[<img src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=463427836&amp;format=image"/>](https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=463427836&format=interactive)

Si comparamos los resultados con la versión anterior, vemos que no ha habido ninguna mejora de rendimiento, e incluso empeorado ligeramente. ¿Nos estará engañando Vlad?

No, no nos ha engañado, su ejemplo es más sencillo y no nos ha contado un pequeño detalle sobre **la clave primaria**.

### 5.- La clave primaria

JPA tiene un problema: le gusta tener el control todas tus entidades, y el único mecanismo que tiene para hacerlo y distinguir si dos instancias de tus objetos son la misma es mediante su clave primaria.

En este ejemplo no estoy creando y asignando yo el valor de la clave primaria, espero que lo genere la base de datos. Un objeto de JPA recién instanciado y no persistido en base de datos no tiene todavía clave primaria, y JPA se tiene que conformar todavía con la propia referencia del objeto para saber si dos referencias apuntan a la misma entidad.

En resumen, que JPA después de persistir las entidades en la base de datos necesita [recuperar el valor](https://docs.oracle.com/javase/8/docs/api/java/sql/Statement.html#RETURN_GENERATED_KEYS) de la clave primaria que acaba de generar.

Si os váis al código fuente, veréis que la entidad que estoy persistiendo tiene definida una clave primaria con la estrategia [`GenerationType.IDENTITY`](https://docs.oracle.com/javaee/7/api/javax/persistence/GenerationType.html#IDENTITY).

```java
@Entity
@Table(name = "bike_trip")
public class TripEntity implements Trip {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

```

Esto significa que le estoy diciendo que la clave primaria la tiene que generar la base de datos en el momento de la inserción con algún mecanismo de [secuencia](https://www.postgresql.org/docs/current/static/datatype-numeric.html#DATATYPE-SERIAL) o valor [autoincremental](https://dev.mysql.com/doc/refman/5.7/en/example-auto-increment.html).

Aunque JDBC implementa, mediante el método [`getGeneratedKeys`](https://docs.oracle.com/javase/8/docs/api/java/sql/Statement.html#getGeneratedKeys--), el mecanismo para obtener la clave primaria generada, por un _detalle_ de implementación de Hibernate [no puede utilizarlo](https://stackoverflow.com/questions/27697810/hibernate-disabled-insert-batching-when-using-an-identity-identifier-generator?answertab=active#tab-top) en operaciones batch y desactiva la optimización. Desconozco si otras implementaciones sufren del mismo problema, ¿alguno de vosotros lo sabe?

Posibles soluciones para evitar esto son:

- Buscar en nuestros datos una [_Natural Key_](https://en.wikipedia.org/wiki/Natural_key), evitando generar valores para la clave primaria.
- Utilizar un [UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) como identificador.
- Gestionar tú manualmente el valor del identificador jugando con su valor máximo actual (si no tienes problemas de concurrencia).
- Usar un [generador](https://vladmihalcea.com/hibernate-hidden-gem-the-pooled-lo-optimizer/) que implemente el [algoritmo hi-lo](https://www.quora.com/What-is-the-Hi-Lo-algorithm-and-when-is-it-useful).

Para seguir con el ejemplo optaré por asignar yo el valor del id con un contador mio. Así que una vez eliminada la anotación de `@GeneratedValue` de la entidad tendríamos el siguiente código:

```java
EntityTransaction tx = entityManager.getTransaction();
Iterator<TripEntityJpa> iterator = trips.iterator();
tx.begin();
int cont = 0;
int idSeq = 1;
while (iterator.hasNext()) {
    TripEntityJpa trip = iterator.next();
    trip.setId(idSeq++);
    entityManager.persist(trip);
    cont++;
    if (cont % batchSize == 0) {
        entityManager.flush();
        entityManager.clear();
        tx.commit();
        tx.begin();
    }
}
tx.commit();
```

[<img src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=105187721&amp;format=image"/>](https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=105187721&format=interactive)

Aquí tenemos la primera gran diferencia entre MySQL y Postgres: mientras que Postgres obtiene una mejora de 5X, en MySQL es de solo 1.3X.

Está claro que Postgres gestiona mejor las operaciones batch que MySQL, y por ahora no sé si será problema de la base de datos en sí o del driver JDBC. ¿Alguien en la "sala" que nos saque de dudas? Me lo apunto para investigar.

### 6.- Insert múltiple

Si hay algo más eficiente que enviar todas las sentencias de insert juntas es el enviar todos los insert en una única sentencia.

En vez de las dos sentencias:

```SQL
INSERT INTO persona (dni, nombre) VALUES ('12345Z', 'Alberto Zaplana');
INSERT INTO persona (dni, nombre) VALUES ('98765A', 'Zoe Alarcón');
```

enviar una única sentencia:

```SQL
INSERT INTO persona (dni, nombre) VALUES
 ('12345Z', 'Alberto Zaplana'),
 ('98765A', 'Zoe Alarcón');
```

Con esto, además de hacer un sólo viaje, le ahorramos trabajo a la base de datos a la hora de parsear y ejecutar la query.

Desgraciadamente Hibernate a pesar de saber eso, no generan ese tipo de querys.... tal vez porque sean unos vagos y delegan en el driver JDBC :)

Tanto MySQL como Postgres admiten configurar el driver para que cuando se encuentre un batch de inserts iguales en estructura, lo transforme en un único insert.

La activación se hace a nivel de URL como un parámetro más de la conexión, siendo en MySQL el parámetro `rewriteBatchedStatements` y en Postgres el parámetro `reWriteBatchedInserts`. No es necesario modificar el código, sólo la conexión a base de datos.

[<img src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=144879728&amp;format=image"/>](https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=144879728&format=image)

Este cambio nos ha traído entre un 1.5X y un 4X de rendimiento, dejando a MySQL a un nivel más razonable respecto a Postgres.

### ¿Siguiente paso?

La verdad es que no he encontrado muchas más opciones que mejoren dramáticamente el rendimiento sin salirnos de JPA. 

Aplicando alguna otra técnica sobre la configuración de la base de datos se pueden conseguir ciertas mejoras, pero eso me lo reservo para otro tipo de post.

Para simplificar el post me he limitado a usar 1000 como número de elementos en el _batch_, pero sería un ejercicio interesante probar con distintos tamaños hasta encontrar el más adecuado para cada base de datos y morfología de los datos a persistir. Probablemente los resultados que me han salido cambien si pruebo con otro tamaño de _batch_.

**En el próximo post realizaré el mismo ejercicio con casi los mismos pasos con JDBC _a pelo_ (prometo ser más breve), y veremos cómo se comporta cuando quitamos de en medio al ORM y atacamos directamente a la base de datos.**

### Conclusión

Hemos visto cómo mejorar el rendimiento de tu sistema es bastante sencillo y no requiere muchos cambios de código. Solamente tenemos que conocer cómo funcionan las herramientas que usamos para saber sacarles partido de verdad:

<iframe width="600" height="371" seamless frameborder="0" scrolling="no" src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRA9shz0_mslFRyCpLqNMczi0e5G8_Lv_QW7BHs1JQhxWalXGCFernTnwjrcUkYXei-Wztj_CKJAEyr/pubchart?oid=716229197&amp;format=interactive"></iframe>

**¿Conoces alguna técnica que pueda mejorar el rendimiento en JPA o Hibernate?** ¿Crees que soy un [bocachanclas](https://mailchi.mp/bonillaware/bocachanclismo) y no tengo ni idea de JPA? A todos nos gustará conocerla, y si nos la cuentas en los comentarios o en tu propio post todos aprenderemos.

#### Setup del benchmark

Cualquier benchmark que se precie y quiera ser tenido en cuenta debe especificar su configuración. La metodología del benchmark no ha sido muy rigurosa, pero considero que lo suficiente como para sacar conclusiones de cada prueba realizada.

Las pruebas las he hecho sobre un portátil Dell XPS 13 del 2017, con un procesador Core i7-7560U, con 16GB de memoria y disco SSD LiteOn CX2.

Las versiones del software utilizado son:

- MySQL 5.6.35
- Postgres 9.6.8
- Java 8u151

En ningún caso he hecho ningún _tuneo_ del motor de base de datos y está con la configuración que trae por defecto al instalarse.

En cada tests, he hecho 10 ejecuciones, descartando el mejor y peor resultado, y hecho la media de los 8 valores restantes.
