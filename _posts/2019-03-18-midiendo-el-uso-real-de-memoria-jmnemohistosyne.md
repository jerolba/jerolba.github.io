---
layout: post
title: "Midiendo el uso real de memoria: JMnemohistosyne"
description: "¿Sabes cuánta memoria consumen las estructura de datos o algoritmos que desarrollas? ¿Qué clases concretas consumen más memoria? "
modified: 2019-03-11
tags: 
image:
  path: images/mnemosyne_color_rossetti.jpg
  feature: mnemosyne_color_rossetti.jpg
  credit: Gabriel Dante Rosetti, Mnemosyne
  creditlink: https://commons.wikimedia.org/wiki/File:Gabriel_Dante_Rosetti,_Mnemosyne.jpg
excerpt_separator: <!--more-->
---

**TL;DR: en este post os presento [JMnemohistosyne](https://github.com/jerolba/jmnemohistosyne) una pequeña utilidad para calcular el histograma de clases con la memoria consumida en una sección de código.**

En mis [dos](https://www.jerolba.com/hashing-y-mapas/) [últimos](https://www.jerolba.com/mapas-con-clave-compuesta/) artículos tenía una especial preocupación por conocer cuál era el consumo de memoria de algunas estructuras de datos y cómo se distribuía el espacio ocupado entre las distintas clases que las forman.

En mi caso concreto, dado un fragmento de código necesitaba averiguar:

- ¿Cuánta memoria han consumido los objetos que se han instanciado y quedan residentes en memoria?
- ¿Cuántas instancias de cada clase existen?
- ¿Cuánta memoria consumen?

<!--more-->

En ese fragmento de código se pueden crear objetos de forma temporal (iteradores, streams, helpers, etc) que al finalizar pueden estar todavía en el _heap_, pero deberían ser ignorados por no pertenecer a los objetos que deseo inspeccionar.

**¿Qué funcionalidad o herramienta de todas las disponibles en la JVM podemos usar?**

Para obtener el consumo de memoria en bytes, la JVM nos proporciona el objeto JMX para el control de la memoria: [MemoryMXBean](https://docs.oracle.com/en/java/javase/11/docs/api/java.management/java/lang/management/MemoryMXBean.html), y uno de [sus métodos](https://docs.oracle.com/javase/7/docs/api/java/lang/management/MemoryMXBean.html#getHeapMemoryUsage()) nos devuelve el número de bytes en uso en el _heap_. Por tanto, consultado el espacio consumido antes y después de ejecutar nuestro código podremos calcular la memoria empleada en su ejecución:

```java
MemoryMXBean mbean = ManagementFactory.getMemoryMXBean();
MemoryUsage beforeHeapMemoryUsage = mbean.getHeapMemoryUsage();

Object instance  = codeThatCreatesComplexDataStructure();

MemoryUsage afterHeapMemoryUsage = mbean.getHeapMemoryUsage();
long consumed =  afterHeapMemoryUsage.getUsed() - beforeHeapMemoryUsage.getUsed();
System.out.println("Total consumed Memory:" + consumed);
```

Este código tiene un problema: el método `getHeapMemoryUsage` devuelve el espacio del _heap_ usado, con todo tipo de objetos: los vivos y los no referenciados, que necesitan ser liberados por el recolector de basura.

Por tanto es necesario invocar la recolección de basura: `System.gc()` antes de cada invocación a `getHeapMemoryUsage()` para asegurarnos de que sólo se contabiliza el espacio ocupado por los objetos vivos. 

La ejecución de una recolección de basura en ese instante no está garantizada, y sólo es una indicación a la JVM de que queremos que lo ejecute, pero para simplificar la explicación no entraré en cómo resolverlo.

Con esto conseguimos obtener la diferencia de memoria ocupada antes y después de nuestro código a inspeccionar, pero no tenemos información de qué clases son ni cómo se distribuye ese consumo entre las clases.

### Histograma de memoria

La JVM permite obtener el histograma de la memoria consumida por un programa en ejecución mediante los comandos [jmap](https://docs.oracle.com/en/java/javase/11/tools/jmap.html) o [jcmd](https://docs.oracle.com/en/java/javase/11/tools/jcmd.html):

- `$ jmap -histo:live PID`
- `$ jcmd PID GC.class_histogram`

siendo PID el identificador del proceso Java a inspeccionar.

Los dos comandos son equivalentes y generan el mismo resultado en un "hola mundo":

```aa
 num    #instances        #bytes  class name
---------------------------------------------
   1:          512        367920  [B
   2:         2754        252224  [C
   3:          857         99896  java.lang.Class
   4:         2736         65664  java.lang.String
   5:          792         43872  [Ljava.lang.Object;
   6:          675         41600  [I
   7:          454         18160  java.util.LinkedHashMap$Entry
   8:          471         15072  java.util.Hashtable$Entry
   9:          458         14656  java.util.HashMap$Node
  10:          127         14552  [Ljava.util.HashMap$Node;
  11:          341         10912  sun.misc.FDBigInteger
  12:          173          6920  java.lang.ref.Finalizer
  13:          201          6432  java.util.concurrent.ConcurrentHashMap$Node
  14:          256          6144  java.lang.Long
  15:           85          6120  java.lang.reflect.Field
  16:          126          6048  java.util.HashMap
  17:           69          5520  java.lang.reflect.Constructor
  18            80          5120  java.net.URL
  19:          160          5120  sun.security.util.ObjectIdentifier
  20:          118          4720  java.lang.ref.SoftReference
  ...          ...         .....  
```

De esta forma podemos obtener el número de instancias de cada clase y el espacio total ocupado en memoria por los objetos de cada clase.

En el comando `jmap`, gracias al modificador `:live`, le estaremos indicando a la JVM que sólo tenga en cuenta los objetos vivos y fuerce la ejecución del recolector de basura. Mientras que `jmcd` con `GC.class_histogram` es [implícito](http://hg.openjdk.java.net/jdk8u/jdk8u/hotspot/file/ff3b27e6bcc2/src/share/vm/services/diagnosticCommand.cpp#l387) que ejecute la recolección de basura.

Esto es muy útil para hacerte una idea del estado de tu aplicación en cualquier momento, y buscar valores muy altos y anómalos para encontrar un _memory leak_. 

Haciendo la diferencia entre dos histogramas tomados en dos momentos distintos podremos obtener el incremento de instancias y memoria en ese periodo de tiempo (o decremento).

Pero al ser instrucciones que se ejecutan por línea de comandos **no tenemos control del momento exacto en el que se ejecuta cada histograma**.

Para solucionarlo yo he optado por invocar al comando desde código usando el método `exec` del `Runtime` de la JVM:

```java
public void memoryHistogram() {
    String name = ManagementFactory.getRuntimeMXBean().getName();
    String PID = name.substring(0, name.indexOf("@"));
    Process p = Runtime.getRuntime().exec("jcmd " + PID + " GC.class_histogram");
    try (BufferedReader input = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
        input.lines().forEach(System.out::println);
    }
}

public void memoryAnalysis(){
    memoryHistogram();
    Object instance = codeThatCreatesComplexDataStructure();
    memoryHistogram();
}
```

Así, si parseamos la salida estándar del comando y hacemos la diferencia entre los valores asociados a cada clase podremos obtener la información que necesitamos.

¿Cómo podemos hacer esto de forma sencilla? Yo no encontré ninguna y tuve que escribir un código que parseara y calculara la diferencia. 

**El poco código que me salió lo he adecentado y publicado en Maven Central para que lo podáis usar cuando os surja una necesidad parecida:** [https://github.com/jerolba/jmnemohistosyne](https://github.com/jerolba/jmnemohistosyne)

## Dependencia

Si usáis Maven sólo tenéis que añadir la dependencia:

```xml
<dependency>
  <groupId>com.jerolba</groupId>
  <artifactId>jmnemohistosyne</artifactId>
  <version>0.2.3</version>
</dependency>
```

Y si tenéis Gradle:

`implementation 'com.jerolba:jmnemohistosyne:0.2.3'`

La librería sólo ocupa 11KB y no tiene ninguna otra dependencia transitiva.

## Histograma simple

Para obtener un histograma de todos los objetos que hay en memoria creas un objeto de tipo `Histogramer` y ejecutas el método `createHistogram()`, que devolverá un `MemoryHistogram`:

```java
Histogramer histogramer = new Histogramer();
MemoryHistogram histogram = histogramer.createHistogram();

HistogramEntry arrayList = histogram.get("java.util.ArrayList");
System.out.println(arrayList.getInstances());
System.out.println(arrayList.getSize());

for (HistogramEntry entry : histogram) {
    System.out.println(entry);
}
```

La clase `MemoryHistogram` es una colección iterable de objetos `HistogramEntry` que contienen: nombre de la clase, número de instancias y tamaño total de todas las instancias.

También se puede buscar una clase en concreto pasando su nombre completo al método `get`.

## Histograma de objetos nuevos creados

Podemos medir la cantidad de objetos vivos instanciados dentro de una sección de código usando una _lambda_ que lo contenga:

```java
MemoryHistogram diff = Histogramer.getDiff(() -> {
    HashMap<Integer, String> map = new HashMap<>();
    for (int i = 0; i < 10000; i++) {
        map.put(i, "" + i);
    }
    return map;
});

HistogramEntry nodes = diff.get("java.util.HashMap$Node");
System.out.println(nodes.getInstances());
System.out.println(nodes.getSize());
```

Dentro de la _lambda_ puedes meter todo el código que quieras y que llame a todo el código que necesites, pero asegúrate de que todas las instancias que quieras que sean tenidas en cuenta estén referenciadas por algún objeto que ya existiera fuera de la _lambda_ o que esté referenciado por el objeto que retorne la lambda (que implementa `Supplier<?>`). Sino, **al forzar la recolección de basura las instancias no aparecerán en el histograma** y se perderán en la memoria, como lágrimas en la lluvia.

En el siguiente ejemplo sólo aparecerá una instancia de la clase `ArrayList`, otra de `Object[]` y 10.000 de `String`, pero no habrá rastro de las clases que forman `HashMap`:

```java
MemoryHistogram diff = Histogramer.getDiff(() -> {
    HashMap<Integer, String> map = new HashMap<>();
    for (int i = 0; i < 10000; i++) {
        map.put(i, "" + i);
    }
    return new ArrayList<>(map.values());
});
System.out.println(diff);
```

## Filtrado de clases

La colección `MemoryHistogram` puede ser filtrada usando el método `filter` que admite un array de argumentos variables que pueden ser:

- El nombre completo de una clase (incluyendo el paquete): `java.util.HashMap`
- El nombre completo de una clase usando un `*` al final para indicar que comience por: `java.util.HashMap*`
- Una instancia de `Class`: `HashMap.class`
- Una expresión regular que aplicar sobre el nombre completo de clase: `Pattern.compile(".*List")`

Todas las opciones se aplican al histograma y se unen en forma de OR en un nuevo `MemoryHistogram`.

Un ejemplo completo sería:

```java
MemoryHistogram filterd = diff.filter("Object[]", "java.util.HashMap*",
ArrayList.class, Pattern.compile(".*Hibernate.*"));
```

Como el número de clases presentes en la JVM puede llegar a ser muy alto, puedes quedarte con el Top N de clases que más memoria consuman:
```java
System.out.println(diff.getTop(20));
```

## Recomendaciones de uso

### ¡¡No usar en producción!!

Para poder hacer todas las mediciones la JVM hace una recolección de basura completa, y a continuación se tiene que recorrer todo el _heap_ contando instancias de clases y tomando nota de su tamaño.

Esta es una operación muy costosa y puede bloquear por completo tu proceso durante varios segundos (un tiempo proporcional a la memoria consumida).

Si no lo puedes ejecutar en un test unitario/integración, no vayas más allá de un entorno de preproducción.

### No ejecutar en concurrencia

Si estás en un entorno donde hay concurrencia, como en un servidor web, junto con tu código puede estar ejecutándose otro código de otras peticiones que pueden "contaminar" la memoria y darte resultados inesperados.

**Asegúrate de que no hay nada más ejecutándose y que sólo está corriendo el código que te interesa analizar**.

### La propia JVM se ejecuta en concurrencia

Aunque a ti te parezca que estás con un sólo hilo y no tienes concurrencia, la JVM está por detrás haciendo sus cosas, y como gran parte del código de la JVM está escrito en Java (más ahora si activas [Graal](https://www.graalvm.org/docs/reference-manual/languages/jvm/)), sus clases te aparecerán en el histograma.

En mi experiencia lo que más aparece son clases relacionadas con la carga de clases (las clases que mides tienen que ser cargadas en algún momento), así que **si necesitas precisión en el número de instancias y su consumo, te recomendaría preejecutar tu código antes de tomar ninguna muestra**:

```java
metodoQueHaceCosas();
MemoryHistogram diff = Histogramer.getDiff(() -> {
    return metodoQueHaceCosas();
});
System.out.println(diff);
```

de esta forma nos aseguraremos de que todo lo necesario para cargar y ejecutar tu código ya se ha hecho antes.

Antes de aceptar como válido el primer resultado que obtengas, sé crítico si algún valor no te encaja, y trata de ejecutar tu código con diferente contexto.

### Necesita acceder a la JDK

El comando `jcmd` pertenece a las utilidades que van en la JDK, por lo que necesitaremos tener instalado un JDK y que sus ejecutables estén accesibles en el path.

En Circle CI lo tengo validando con la versión 8 del JDK de Oracle, y las versiones 8 y 11 de OpenJDK. **Si encuentras alguna versión en la que no te funcione, se aceptan PRs :)**