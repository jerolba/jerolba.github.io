---
layout: post
title: Revisitando Google App Engine
description: "A raíz de los recientes lanzamientos de Google sobre su servicio de App Engine decidí reevaluarlo 6 años después de mi última experiencia con él."
modified: 2017-08-06
tags: 
image:
  path: images/app-engine.png
  feature: app-engine.png
#  layout: top
excerpt_separator: <!--more-->
---

A raíz de los [recientes](https://cloudplatform.googleblog.com/2017/06/Google-App-Engine-standard-now-supports-Java-8.html) lanzamientos de Google sobre su servicio de App Engine decidí reevaluarlo, 6 años después de mi última experiencia con él.

TL;DR: Esta vez realizo un repaso de lo que es App Engine junto con los principales problemas que ha tenido la gente, las novedades de su última versión completamente reformada y muchísimo más flexible, además de la última *release* de la versión clásica con soporte a Java 8.

<!--more-->
Si te da pereza leerte el ladrillaco vete a las [conclusiones](#conclusiones) :D

### Primer contacto

Mi primer contacto con App Engine fue para hacer **una ridícula aplicación llamada [Pelotator](https://twitter.com/pelotator)**, ¡la primera tontería que hicimos juntos [David](https://twitter.com/david_bonilla) y yo! (el único rastro que ha quedado en internet fue [este post](http://elblogdedimco.blogspot.com.es/2011/09/pelotator-20.html)).

<img src="/images/pelotator.jpg" class="mfp-img"/>

En aquella época para un javero desplegar una aplicación en un servidor a **un precio asequible** era muy ~~complicado~~ caro, ya que los servidores VPS no salían de PHP, y no fue hasta ese año que Heroku [permitió desplegar aplicaciones Java]((https://www.wired.com/2012/09/heroku-enterprise-java/)) o al siguiente que salió un [Digital Ocean](https://en.wikipedia.org/wiki/DigitalOcean).

Sobre el papel, App Engine tenía muy buena pinta, ya que Google había puesto a nuestra disposición la "misma" tecnología que manejaban ellos. Nos permitía escalar de forma "ilimitada" y transparente, sin tener que lidiar con ninguna infraestructura, ya que **es un PaaS** que ofrece entre otras cosas: 
 * Desplegar sobre un servidor de aplicaciones (Jetty)
 * Una base de datos, [Datastore](https://cloud.google.com/datastore/docs/concepts/overview)
 * Una instancia de Memcache
 * Programación de trabajos Cron
 * Colas de tareas si necesitas trabajos en background

En resumen, que incluyen todo lo que necesitas para poder hacer una aplicación completa. Incluso puedes dividir tu [aplicación en microservicios](https://cloud.google.com/appengine/docs/standard/java/microservices-on-app-engine) desplegando, versionando y dimensionando cada uno de ellos según tus necesidades de uso.

Si tu aplicación no consume muchos recursos y entra dentro de los límites de las [cuotas gratuitas diarias](https://cloud.google.com/appengine/quotas), te puede salir totalmente gratis, y a la vez asumir de forma elástica cualquier pico de uso que puedas tener a un precio razonable y con cero conocimientos de administración de sistemas.

Gracias a ese escalado ilimitado es cómo [funciona Snapchat](https://gigaom.com/2013/05/07/snapchats-act-of-faith-in-building-on-google-compute-engine/), o es como Javi Santana fue capaz de dar servicio el [día que salió en la portada de Google](http://javisantana.com/2013/06/27/como-aguantamos-una-portada-de-google.html).

### En la oscuridad

A pesar de todas las bondades y maravillas técnicas de la plataforma creo que App Engine no tuvo ni por asomo el uso ni el impacto que los directivos de Google se imaginaron. Seguro que todavía debe haber algún ingeniero de Google preguntándose por qué tan poca gente usa la tecnología que les ha servido para llegar donde están.

No sé en qué medida esa tecnología se parece en algo a lo que usaba Google para programar sus aplicaciones, pero viendo los post de gente que lo ha usado en producción real estos años, impone una serie de prácticas o técnicas a la hora de desarrollar tu aplicación en pos de esa deseada escalabilidad:
 * Ninguna petición puede durar más de 30 segundos, sino tienes que lanzar una tarea en background.
 * Peticiones http hacia otros servidores no pueden durar más de 5 segundos...  ¿y si el API de Facebook tarda más?.
 * En la plataforma Java, por seguridad dicen, limita el acceso a un [subconjunto de clases ](https://cloud.google.com/appengine/docs/standard/java/jrewhitelist) del JRE. Muchas librerías y frameworks hacen su "magia" usando alguna de las clases no permitidas, limitando las dependencias que puedes usar u obligando a usar versiones especiales capadas.
 * En la versión Python, por la misma razón, no permiten usar librerías hechas en C, algo que es muy habitual cuando desarrollas en Python.
 * También por seguridad y debido a la naturaleza efímera de las instancias, no puedes acceder al sistema de ficheros local para crear ficheros temporales.
 * Los recursos de CPU asignados a cada instancia parece que son escasos y las peticiones se ejecutan más lentas de lo deseable, por lo que tienes que minimizar las cosas que haces en cada una y recurrir mucho a caché, tanto al Memcache disponible, como a la memoria local de la instancia.
 * Aunque permite escalar en instancias muy bien, parece que en cuanto lo haces a un gran número, de forma continua y muy habitual, es decir, que siempre tienes mucho tráfico, es muy caro.

Todo lo relativo a la base de datos merecería un capítulo aparte y es donde se centran la mayoría de las quejas: 
 * Datastore no es una base de datos relacional, sino que es una NoSql con un montón de [ventajas](https://cloud.google.com/datastore/docs/concepts/overview) a la hora de escalar, pero con muchas restricciones y cambios sobre la forma en la que estamos acostumbrados a trabajar.
 * En Java, para facilitar la adopción, hicieron una [implementación de JPA/JDO](https://cloud.google.com/appengine/docs/standard/java/datastore/jpa/overview), pero también llenas de limitaciones, y al final recomiendan usar [otra librería](https://github.com/objectify/objectify) que se adapta mejor a su API.
 * Por su modelo NoSql, no puedes hacer JOINs
 * Tampoco puedes hacer LIKE, teniendo que usar su servicio de [full text search](https://cloud.google.com/appengine/docs/standard/java/search/) que no cubre todas las casuísticas de un LIKE.
 * En sus primeras versiones solo podías obterner 1.000 filas de cada query.
 * Ahora no sé, pero cuando yo lo probé, no había ninguna herramienta para hacer un *dump* de tu base de datos de producción y tenías que hacerlo tú con tu código.
 * O es lenta o tiene mucha latencia, pero en cuanto haces una serie de queries los tiempos de ejecución se alargan, obligándote a recurrir a la caché y a planificar muy bien tus patrones de acceso a base de datos y por tanto tu modelo de datos.

Desde finales de 2011 todos estos problemas con la base de datos pueden salvarse mediante el uso de una instancia externa de [Google Cloud SQL](https://cloud.google.com/sql/) a donde conectar tus instancias de App Engine. Es una base de datos con la interfaz de MySql, donde ya entras en el modelo de pagar por una instancia reservada, la uses constantemente o no, y un coste proporcional a su tamaño.

Ningúno de estos "problemas" supone un problema real o un impedimieto insalvable a la hora de hacer una aplicación, y en determinadas circunstancias puede compensar. Pero si lo que te falta es tiempo para hacer las cosas, tener que buscar soluciones a estos problemas que resuelven un problema que no tienes, posiblemente no sea la mejor estratégia.

Todo esto es una recopilación de problemas que he visto, y **puede que alguno se haya ido solventando según fueran sacando nuevas versiones de la plataforma**. Pero persiste la sensación general de ser una plataforma con demasiadas restricciones.

### La próxima generación

A principios de 2016 con Google metido de lleno en la lucha por hacerse con un trozo del pastel de la computación en la nube, y con un [conjunto de servicios](https://cloud.google.com/products/) cada vez más completo, sacó en preview lo que han llamado [App Engine **Flexible Environment**](https://cloud.google.com/appengine/docs/flexible/), llamando a la versión de toda la vida **Standar Environment**.

Lanzado finalmente como *General Availability* [un año después](https://cloudplatform.googleblog.com/2017/03/your-favorite-languages-now-on-Google-App-Engine.html) lo venden como una nueva versión en donde están disponibles más lenguajes (Node.js, Ruby, PHP o ASP.NET Core), y llevan a la última versión los lenguajes que ya tenían soportados (Java 8, Pyton 3.5 o Go 1.8).

Pero a poco que lees la documentación te cuentan que simplemente lo que están haciendo es **ejecutar contenedores [Docker](https://es.wikipedia.org/wiki/Docker_(software))** y que dichos lenguajes y plataformas soportados no dejan de ser imágenes de Docker ya preconfiguradas por ellos, de las que extender con tu propio Dockerfile. Tú mismo puedes [crear tus propios Dockerfiles](https://cloud.google.com/appengine/docs/flexible/custom-runtimes/), directamente clonar y personalizar las versiones estándar que tienen publicadas en [GitHub](https://github.com/GoogleCloudPlatform/nodejs-docker), o partir de [ejemplos](https://github.com/GoogleCloudPlatform/appengine-custom-runtimes-samples) en otros lenguajes como Elixir, Perl, Ruby o Swift.

*Inciso: cuando digo que ejecutan contenedores Docker, es que usan el mismo formato, por lo menos de Dockerfiles. Luego internamente puede que usen otra tecnología que no tenga nada que ver con lo que nosotros usamos de Docker.*

Como podéis ver el panorama cambia un montón, y donde antes eran todo restricciones y problemas ahora pasa a ser flexibilidad y libertad. Te dejan configurar todo tu stack manteniendo la flexibilidad de escalado y cero administración de sistemas. El despliegue es algo tan sencillo como construir la imagen de Docker y subirla a Google Cloud, todo ayudado por las herramientas de línea de comandos de Cloud SDK.

Al igual que en la versión Standar, sigue permitiendo tener varias versiones desplegadas a la vez para hacer pruebas en paralelo, o [dividir el tráfico](https://cloud.google.com/appengine/docs/flexible/java/splitting-traffic) entre dos versiones para hacer Test A/B o [Canary Release](https://martinfowler.com/bliki/CanaryRelease.html)

Google es el rey de la _containerización_ de aplicaciones y ya lo hacían mucho antes de que saliera Docker. Su plataforma [Borg](https://www.quora.com/What-is-Borg-at-Google) ha sido el gran secreto que ha sido celosamente guardado durante muchos años. Hasta la publicación de [este paper](https://research.google.com/pubs/pub43438.html) no se conocían sus detalles. 

La tecnología de contenedores ha permitido a Google crecer y escalar como lo ha hecho, y entiendo que la versión Standar de App Engine se ejecuta de alguna manera sobre esa infraestructura y sigue los patrones de sus contenedores. No ha sido hasta la popularización de Docker y todas sus tecnologías asociadas (como [Kubernetes](https://kubernetes.io/)), que no han decidido cambiar el sistema de contenedores a uno como Docker, permitiendo al usuario elegir si desplegar sobre un sistema u otro de forma sencilla.

Por tanto si necesitas desplegar una aplicación que tienes dockerizada pero no necesitas la complejidad (y ventajas) de desplegar en [Container Engine](https://cloud.google.com/container-engine/) (un Kubernetes as a Service), esta nueva versión de App Engine Flexible puede ser una buena solución intermedia que no te cierra las puertas a migrarlo a cualquier otra plataforma que soporte imágenes Docker.

Personalmente **habría lanzado comercialmente el nuevo App Engine Flexible Environment como un nuevo producto independiente** por completo del Standar Environment y lo habría desvinculado. Creo que la mala fama que atesoró ha creado muchos prejuicios sobre el mismo, y mucha gente ni se habrá planteado evaluarlo pensando que es más de los mismos problemas.

Vale, no puede ser todo tan bonito, ¿qué tiene de malo? Como muchas cosas en esa vida: el precio! **Desaparecen las cuotas y _free tiers_**, y desde el minuto cero de consumo te cobran, pero no precisamente algo barato: tener una instancia de un solo nodo de 1GB de memoria y con 1GB de disco sale por 43 dólares al mes!

<img src="/images/AppEnginePricing.png" class="mfp-img"/>

Para proyectos pequeños, si lo comparas con el tiempo (y dinero) que te lleva configurar y administrar una máquina, aún te puede salir rentable, pero en cuanto se incrementen tus requisitos de recursos me plantearía otro tipo de soluciones más económicas.

### La última frontera

Pero volvemos a lo que me trajo a este post: las novedades de la última versión del Standar Environment. La principal y más importante de todas es **el soporte de Java 8**! Aunque todavía la tienen en versión Beta las cuatro pruebas que he hecho yo me han ido bien....

La verdad es que era difícil aceptar seguir trabajando con Java 7 cuando éste alcanzó el *End Of Life* en [abril del 2015](https://www.infoq.com/news/2015/05/Oracle-Ends-Java-7Public-Updates) y podíamos calificar a Java 8 como la versión con más mejoras de sintaxis desde Java 5. 

Tener que renunciar a trabajar con Java 8 (a pesar de sus carencias como lenguaje moderno) era difícil de aceptar. No me quiero imaginar cómo debe estar de quemada la gente de Android, y eso explica porqué se van en masa hacia Kotlin.

Las principales novedades de esta versión son:

 * Desaparece la [WhiteList](https://cloud.google.com/appengine/docs/standard/java/jrewhitelist) de clases de la JRE accesibles y ya no hay ningún tipo de restricción.
 * Eliminan el security manager que impedía hacer ciertas cosas, como por ejemplo aplicar cosas básicas de reflexión.
 * El servidor de aplicaciones sobre el que se despliega pasa a ser Jetty 9 (antes era la versión 6) con soporte a Servlets 3.1
 * Se puede escribir ficheros en el directorio `/tmp` (que está mapeado directamente en memoria y ocupa por tanto memoria disponible en la instancia)

Todas estas mejoras permiten que frameworks como [Spring Boot](https://projects.spring.io/spring-boot/) o lenguajes como [Groovy](http://groovy-lang.org/) o [Kotlin](https://kotlinlang.org/) puedan ejecutarse contra la nueva versión de App Engine sin problemas de que hagan uso de cierta funcionalidad o clase no permitida, y deberían ya correr directamente sin ningún *hack*.

Si tienes alguna aplicación hecha con App Engine y quieres probar la nueva versión, aparte de cambiar la configuración de tu proyecto para que use Java 8, presta atención a esto:
 * Asegúrate de tener la última versión del Cloud SDK
 * Tener configurado el plugin de maven de appengine a su última versión:

```xml
<plugin>
  <groupId>com.google.cloud.tools</groupId>
  <artifactId>appengine-maven-plugin</artifactId>
  <version>1.3.1</version>
  <configuration>
  </configuration>
</plugin>
```

 * Configurar el fichero `appengine-web.xml` para usar la versión `java8` del runtime:

 ```xml
<appengine-web-app xmlns="http://appengine.google.com/ns/1.0">
  <runtime>java8</runtime>
  <threadsafe>true</threadsafe>
</appengine-web-app>
 ```

Con estos cambios ya deberías poder desplegar con la nueva versión, pero recuerda que está todavía en Beta!

### Más allá

Por ahora Google Cloud va con bastante retraso en la nueva moda del Serverless y Lambda. Su servicio, llamado [Functions](https://cloud.google.com/functions/), todavía está en Alfa y sólo soporta implementar funciones con código en JavaScript. Por ahora se desconoce cuando saldrá su versión final ni si soportará Java para los *tarados* como yo.

Pero la verdad es que no hay necesidad de esperar a que lo haga, porque si analizas bien App Engine, **podríamos considerar que cumple con lo necesario para poder ser llamado un servicio serverless** según [la definición de Martin Fowler](https://martinfowler.com/articles/serverless.html):
 * Nunca despliegas tu aplicación en una máquina en concreto, ya se encarga Google de gestionarlo
 * Está siempre disponible y, si no la has cagado mucho metiendo frameworks, arranca rápido tu aplicación bajo demanda ante cualquier petición
 * Escala según necesites ante el número de peticiones
 * Puedes definir funciones fácilmente mediante algo tan simple como un Servlet de toda la vida, o cualquier abstracción sencilla que te montes encima de ellos
 * Tienes diferentes mecanismos de invocación
    * Directamente mediante peticiones HTTP
    * Mediante peticiones a [push queues](https://cloud.google.com/appengine/docs/standard/java/taskqueue/push/) en su versión [rest](https://cloud.google.com/appengine/docs/standard/java/taskqueue/rest/)
    * Mediante el uso del servicio [Pub/Sub](https://cloud.google.com/pubsub/docs/overview) de Google Cloud
    * Con algo tan tonto como un [cron](https://cloud.google.com/appengine/docs/standard/java/config/cron) si su ejecución se puede programar

En cualquiera de los casos puedes publicar esas "funciones" como un API mediante el uso de [Cloud Endpoints](https://cloud.google.com/endpoints/) con un [free tier muy generoso](https://cloud.google.com/endpoints/pricing-and-quotas), permitiéndote securizar y monitorizar su acceso.

<div id="conclusiones"/>
### Conclusión

Los primeros pasos de Google ofreciendo servicios de infraestructura en Cloud tuvieron poco éxito, pero no ha tardado en subirse el carro de ofrecer todo un ecosistema de servicios capaz de cubrir la mayoría de las necesidades de cualquier usuario. Todavía está lejos de alcanzar la cantidad que opciones que tiene [AWS](https://aws.amazon.com/es/), pero no dudo de que les llegarán a alcanzar.

App Engine ha tenido un *reboot* en forma de App Engine Flexible Environment. No adivino cuales serán sus intenciones con él, porque la verdad es que no le han dado mucho bombo, y si no indagas por su documentación **no te enteras de lo que es, ni de que lo han sacado**.

Aunque pudiera parecer competencia a su servicio de [Container Engine](https://cloud.google.com/container-engine/?hl=es), yo habría aprovechado para **relanzarlo con otro nombre comercial aprovechando el tirón de Docker**, y lo habría puesto como una forma sencilla de adoptar Docker, y puerta de entrada hacia un sistema más complejo como Container Engine.

Dado el grado de "abandono" que tenía App Engine, supongo que la nueva versión del Standar Environment habrá sido más cosa del empuje de los ingenieros detrás del servicio que de una acción comercial, pero le da una nueva vida y **con un cambio de perspectiva se le puede llegar a sacar partido**.

Si has llegado hasta aquí, ¡**muchas gracias por leerte todo el ladrillo**! Probablemente mi interpretación, análisis y conclusiones estén equivocadas, así que **os invito a sacarme de mi error o dar tu opinión en los comentarios**!