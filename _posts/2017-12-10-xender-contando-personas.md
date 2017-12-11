---
layout: post
title: "Xender: Contando personas"
description: "Dado un listado de nombres de personas, ¿cuantas mujeres u hombres hay? Xender te ayuda a contarlos."
modified: 2017-12-10
tags: 
image:
  path: images/party.jpg
  feature: party.jpg
#  layout: top
excerpt_separator: <!--more-->
---
En mi último post [revisitando App Engine](/revisitando-google-app-engine/) me propuse hacerlo probando a construir una aplicación que poder usar y desplegar de verdad. Siguiendo con la temática de mis [anteriores](/mujeres-y-hombres-y-serverless/) [posts](/hosting-estatico-en-firebase/) decidí evolucionar la funcionalidad.<!--more-->

### Xender

Hasta ahora solo era capaz de determinar el género de **una persona** según su nombre, pero dada una lista de nombres, ¿cuántas personas hay por género? Con un listado grande de nombres, usar manualmente la web de [*hombre o mujer*](https://hombre-o-mujer.jerolba.com) puede ser un poco tedioso, y no todo el mundo tiene conocimientos para poder usar [el API](https://hombre-o-mujer.jerolba.com/#slide=2).

<!--more-->
En [Xender](http://xender.jerolba.com/) puedes pegar un listado de nombres y con un simple *click* saber cuántas personas pertenecen a cada género:
<a href="http://xender.jerolba.com/" target="_blank"><img src="/images/snapshot-xender.png" class="mfp-img"/></a>
¿Cuántos hombres y mujeres hay en el [congreso de los diputados](http://xender.jerolba.com/contar/diputados)?
¿y en el [senado](http://xender.jerolba.com/contar/senadores)? En la **política española no parece que haya paridad** porque en ambos casos la proporción de hombres ronda el 60% frente al 40% de las mujeres. Eso sí, parece que en Podemos si que la [cumplen](http://xender.jerolba.com/contar/diputados-podemos) y tienen el 50% - 50% en el congreso de los diputados

¿Y en Codemotion?, el evento sobre desarrollo más multitudinario de España ¿Cuantos ponentes hay en la edición de [este año](https://2017.codemotion.es/agenda.html)?
Las mujeres representan casi el 23% de los ponentes de [esta edición](http://xender.jerolba.com/contar/ponentes-codemotion-2017) y aunque sigue siendo un número bajo, parece que el [trabajo](http://blog.codemotion.es/you-look-like-an-engineer/) [realizado](http://blog.codemotion.es/bienvenido-tech-shessions-2/) por la organización está dando sus frutos si lo comparamos con el 9% de mujeres de la [edición del 2016](http://xender.jerolba.com/contar/ponentes-codemotion-2016) o el 8% de la [del 2015](http://xender.jerolba.com/contar/ponentes-codemotion-2015).

### La parte técnica

Como era de esperar, está construida para que funcione sobre App Engine Standard Environment, pero dada la simplicidad de la aplicación no hace uso de una base de datos -ni de ninguna característica propia de App Engine- por lo que podría desplegarse en cualquier servidor capaz de comerse un War o ejecutar un Jar con un Jetty embebido.

Para poner a prueba los supuestos cambios que eliminan las [restricciones](https://cloudplatform.googleblog.com/2017/06/Google-App-Engine-standard-now-supports-Java-8.html) que imponía App Engine en Java, he usado librerías que ya había probado en su momento y sabía que fallaban.

La aplicación usa el miniframework web que hace uso del API de reflexión y funcionalidades de Java 8 que no funcionaba con la versión anterior de App Engine. A su vez uso la última versión de [Freemarker](http://freemarker.org/), que hasta ahora habían tenido que sacar con una versión especial para poder [funcionar en App Engine](https://issuetracker.google.com/u/1/issues/35886701?pli=1).

Aparte de esto, sólo uso [Guice](https://github.com/google/guice) para la inyección de dependencias y [Jackson](https://github.com/FasterXML/jackson) para poder generar el json para la aplicación web. Todo tecnologías *cutting edge* :)

Dentro de la simplicidad de la parte servidora de la aplicación, hago un uso intensivo de alguna de las funcionalidades estrellas de Java 8: Streams y funciones lambda.

{% comment %}
```java
Map<String, String> parameters = lines.stream()
    .map(String::trim)
    .filter(l->l.startsWith("#"))
    .map(l->l.substring(1))
    .map(String::trim)
    .filter(l->l.length()>0)
    .map(l->l.split("="))
    .filter(arr->arr.length>1)
    .collect(toMap(arr->arr[0], arr->arr[1]));
```
{% endcomment %}

Como curiosidad, no me he comido mi propia comida de perro y no he usado el API que había creado. Llamar centenares de veces al API Rest hacía muy lenta la web, alcanzando el límite que aún impone App Engine de tiempo por petición web, y preferí reimplementar esa parte otra vez dentro de la aplicación.

### La parte funcional

Al igual que en las funcionalidades anteriores, me baso exclusivamente en la información que ofrece el Instituto Nacional de Estadística sobre los [nombres de los residentes en España](http://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177009&menu=resultados&secc=1254736195454&idp=1254734710990)  según el padrón municipal.

Para que un nombre aparezca en la estadística del INE, por lo menos tiene que aparecer en el padrón con una frecuencia igual o mayor a 20 personas. Así que si tu nombre es "exclusivo" probablemente no aparezca y salga como **desconocido**.

Algunos nombres se pueden usar tanto para hombres como para mujeres. En este caso he tomado la decisión de elegir el que supere el 98% de frecuencia. Por ejemplo, en España hay 37.572 Alex registrados como hombre y 90 como mujer, lo que es lo mismo que decir que el 99,8% son hombres. Ante esa coincidencia Xender determinará que ese nombre pertenece a un hombre. En caso de no llegar al 98% el nombre aparecerá como **indeterminado**

### Conclusiones
Hasta ahora, **no poder usar la última versión de Java y las limitaciones del runtime de App Engine en Java, suponían una clara molestia** a la hora de plantearse el desarrollar una aplicación compleja que desplegar en su plataforma. Tener que lidiar con restricciones y versiones especiales de librerías provocaba una pérdida de tiempo pocas veces justificable.

**En la última versión ya no encontramos ese tipo de problemas** y podemos tomar en consideración su uso, e incluso si te vas a la versión Flexible se abre un mundo de posibilidades.

Que App Engine Standard sea una solución buena para tí pasa a ser una decisión sobre si la arquitectura que te propone App Engine es válida para tus necesidades, dejando atrás la mayoría de las consideraciones técnicas de antaño.