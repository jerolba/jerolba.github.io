---
layout: post
title: Mujeres y hombres y serverless
description: "Construyendo una aplicación serverless con Google Cloud Functions"
modified: 2017-03-20
tags: 
image:
  path: images/mujeres-hombres-viceversa.jpg
  feature: mujeres-hombres-viceversa.jpg
  credit: Tele5
  layout: top
excerpt_separator: <!--more-->
---
TL;DR - A lo largo del post cuento mis impresiones después de probar el servicio de Google Cloud Functions, y hago público un servicio Rest alojado allí, que dice si un nombre es de hombre o de mujer.

### La TarugoConf

Los organizadores de la [Tarugoconf](http://www.tarugoconf.com/#quiero-una-entrada) estamos concienciados de la necesidad **mejorar la diversidad de género** en los eventos técnicos, y por eso las 25 primeras entradas que se pongan a la venta estarán reservadas a las suscriptoras de la bonilista.

<!--more-->

El 2 de abril deberemos enviar una invitación solo a las Tarugas, pero hasta hace poco el formulario de inscripción de la bonilista no preguntaba por el género. Por tanto tenemos 7.000 suscriptores que no sabemos si son Tarugos o Tarugas.

Como estoy de "vacaciones" y soy el que más tiempo libre tiene, me ha tocado la tarea de preparar todo el tema del ticketing y clasificar por género a los suscriptores según su nombre, que es de los pocos datos que tenemos.

Para realizar la clasificación podría haber usado algún servicio SaaS de internet con algún tipo de API que dado un nombre te dice de qué género es y con qué probabilidad. Si googleas un poco te encontrarás webs como [genderize.io](http://genderize.io) o [gender-api.com](https://gender-api.com/). Pero como buen técnico español que soy, **¿por qué voy a pagar por un servicio si me lo puedo montar yo?!**

Por fortuna en España tenemos un censo relativamente actualizado y el INE (Instituto Nacional de Estadística) publica estadísticas como la de [nombres de los residentes en España](http://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177009&menu=resultados&secc=1254736195454&idp=1254734710990). ¡Justo la información que necesito!

Así que me descargo el excel y en una hora me monto un script en Java que me diga el género de cada suscriptor. El script parece que va bien, porque de los 7.250 inscritos no clasifica sólo a 450 personas porque en el nombre ponían cualquier cosa menos su nombre, o hay tanto hombres como mujeres registradas con el mismo nombre (como curiosidad, hay 10.790 hombres registrados en el censo como Yeray, frente a 101 mujeres)

### Motivación

Viendo el poco tiempo que me ha llevado y la fiabilidad del método, ¿por qué no llevarlo más allá? Estaría bien montar un servicio en la nube que proporcione un API parecida y publicarla en algún sitio, ¿no? Otra vez como buen técnico español que soy, **si me puede salir gratis, mejor!**

La semana pasada Google celebró en San Francisco por primera vez su conferencia sobre su nube: [Google Cloud Next 17](https://cloudnext.withgoogle.com/). Un megaevento donde [anunció](https://blog.google/topics/google-cloud/100-announcements-google-cloud-next-17/) un montón de tecnologías y proyectos. Entre ellos el lanzamiento de la Beta de [Cloud Functions](https://cloud.google.com/functions/) (el equivalente a [AWS Lambda](https://aws.amazon.com/es/lambda/details/) de Amazon).


### Manos a la obra

Para poder trabajar con Google Cloud lo primero que necesitáis es una cuenta de usuario de Google, así que si no sois ya usuarios de algún servicio de Google, no sé cómo has conseguido sobrevivir en este mundo técnico tan dependiente de Google.

Para que lo puedas probar bien y durante un buen tiempo, han modificado su *free tier* y ahora te dan **300$ de crédito** para gastar **en un año** en vez de los dos meses de antes. [Aquí](https://cloud.google.com/free/) os podéis dar de alta en su nube y acceder al crédito.

### Sobre Cloud Functions

Aquí Google no ha inventado nada y le va a la zaga a AWS en lo que a *serverless* se refiere. **Nunca he usado AWS Lambda** y me he enfrentado a esta tecnología como un novato, así que no pretendo hacer una comparativa de capacidades que ofrece, sin saber cómo lo hace de mejor o de peor AWS Lambda, u otros proveedores. Invito al lector a que nos descubra en los comentarios las diferencias (para mejor o peor).

El número de servicios que pueden provocar la ejecución de una función es limitado:

- Un mensaje en un *topic* de Cloud Pub/Sub
- Una creación, modificación o borrado de un fichero en un *bucket* de Cloud Storage (el S3 de Google)
- Una petición HTTP a una Url de un subdominio que te digan ellos

Como quiero montar un API Rest, **sólo he probado la parte de *triggers* HTTP**, pero entiendo que aparte de lo que es su invocación y el formato de los parámetros que se pasan, será todo igual.

### Node.js!!!

Y alguno se preguntará: ¿y sobre qué plataforma o lenguaje se montan las funciones? Pues, sí como habéis leído, sobre mi querido Node.js :)

En la documentación ni en ningún post hablan de si darán soporte a otras plataformas o lenguajes, pero es de esperar que sí, si quieren hacerle sombra a AWS Lambda.

Por lo que he podido leer en la documentación tu código se ejecuta sobre un Node.js usando una versión LTS (aunque no la última, ya que hablan de la v6.9.1 mientras que ahora está la 6.10.0). Supongo no podrás hacer ciertas cosas o acceder a algunos recursos, pero en la documentación no he sido capaz de encontrar nada sobre limitaciones sobre cosas que no puedas hacer y que en un entorno Node JS normal sí puedas.

### Escribiendo el "Hola mundo"

Por convención, el código principal estará en un fichero llamado `index.js`, o en el que indiques como main en `package.json`. En este fichero te tienes que limitar a exportar las funciones como un [módulo de Node.js](https://nodejs.org/api/modules.html). Por tanto no es responsabilidad tuya levantar ni configurar un [Express](http://expressjs.com/) o un [Meteor](https://www.meteor.com/)

El *Hola mundo* tendría esta pinta:

```js
exports.helloHttp = function helloHttp (req, res) {
  res.send('Hello World!');
};
```

¿Y qué información me llega en `req` y qué tengo que devolver en `res`? Pues parece que los ingenieros de Google no han reinventado la rueda y utilizan **Express 4**. Nos remiten a la documentación de [Request](http://expressjs.com/en/4x/api.html#req) y [Response](http://expressjs.com/en/4x/api.html#res) de Express.

Cada método que expongas en el módulo será susceptible de convertirse en una función publicada (luego veremos más en la parte de despliegue). Por defecto, el nombre que pongas en el export será el path de la Url junto con en el subdominio de tu proyecto en Cloud Functions. El *endpoint* final tendrá esta pinta:

`https://[YOUR_REGION]-[YOUR_PROJECT_ID].cloudfunctions.net/helloHttp`

No sé si algún hack de los módulos de Node permitirá hacer un export de una función que permita tener en el nombre `/`, y así poder darle más semántica a las urls si tu proyecto crece mucho en número de funciones.

Ni en el export del módulo, ni a la hora de desplegar se indica a qué método HTTP responde cada función (GET, POST, PUT, etc). Ésto es porque esa responsabilidad le corresponde a tu función, y deberás escribir código de este tipo si el método HTTP es relevante:

```js
function handleGET (req, res) {
  res.json({"foo": "bar"});
}

function handlePUT (req, res) {
  res.status(403).send('Forbidden!');
}

exports.helloHttp = function helloHttp (req, res) {
  switch (req.method) {
    case 'GET':
      handleGET(req, res);
      break;
    case 'PUT':
      handlePUT(req, res);
      break;
    default:
      res.status(500).send({ error: 'Something blew up!' });
      break;
  }
};
```

Como podéis ver, puedes usar el API habitual de Express a la hora de devolver los códigos de respuesta, cabeceras, un texto o incluso un objeto JSON.

### Dependencias

Como aplicación Node.JS, te permite incluir tus dependencias dentro de `package.json` y descargarlas de `npm`. Supongo que la limitación de qué módulos puedes incluir vendrá dada por las propias limitaciones que imponga el *sandbox* donde se ejecutan las funciones.

Puedes crear tus propios módulos en local e importarlos con `require`, por lo que no será necesario que metas todo tu código en el fichero principal, y podrás utilizar todas las buenas prácticas de modularización de código.

### Estado

Se supone que como función no deberías tener estado, pero hay veces que necesitas precargar cierta información o configurar un comportamiento en función de algún fichero de propiedades.

```js
cont foo = require('./foo');

var fooInfo = {};
foo.loadInfo((info) => fooInfo = info);

exports.helloHttp = function helloHttp (req, res) {
  res.send('Hello World! ' + fooInfo);
};
```

Todo el código que escribas además del `exports` de las funciones se ejecuta cuando se carga tu función en el contenedor donde residirá, por lo que ahí puedes inicializar y cargar información según necesites. Eso sí, ni se te ocurra guardar información a reutilizar entre llamada y llamada, porque no sabes cuando se destruirá ese "contexto". Debes ser pesimista y pensar que se creará y destruirá en cada invocación, aunque luego por eficiencia ese estado sobreviva más tiempo por reutilizar el servidor el código ya cargado y preparado.

En pruebas manuales, he visto que esta información permanecia viva hasta una hora sin realizar ninguna llamada. En la documentación no se cuenta cuanto puede llegar a estar una instancia de una función levantada, y sería un detalle de implementación que cambiará con el tiempo. Lo mejor es que trabajes con la idea de que con cada invocación a una función se instancia y mata un contexto.

He investigado y contado todo esto porque en mi caso aprovecho la inicialización (como en el último ejemplo) para cargar un fichero CSV de **más de un megabyte** con toda la información de nombres en un mapa de JS, y no me apetecía cargarlo en cada llamada a la función. Eso sí, ten cuidado porque, como es mi caso, si tu código de inicialización es asíncrono, el `exports` se ejecutará antes de que termines y el *endpoint* estará disponible para su invocación antes de que termines de configurarte. ¿Cómo resolverlo? No lo he pensado todavía. No tengo tanta experiencia en Node como para idear o conocer un patrón ya existente.

### CORS

Tu *endpoint* se publica como cualquier aplicación web, y sufre de los mismos problemas a la hora de gestionar peticiones de distintos dominios: [CORS](https://developer.mozilla.org/es/docs/Web/HTTP/Access_control_CORS).

El dominio en el que se publica es propio de Google, por lo que si quieres que esté disponible para usar con peticiones Ajax desde una aplicación web tuya, deberás lidiar con la gestión de cabeceras. Por fortuna, como han reutilizado Express, los mismos mecanismos que implementa Express se pueden aplicar aquí importando el módulo `cors` y configurándolo según indica su [documentación](https://www.npmjs.com/package/cors).

Si quieres autorizar a que te puedan invocar desde cualquier dominio quedaría así:

```js
const cors = require('cors')

function helloHttp (req, res) {
  res.send('Hello World!');
};

exports.helloHttp = function helloHttpCors(req, res) {
    var corsFn = cors();
    corsFn(req, res, function() {
        helloHttp(req, res);
    });
}

```

### Entorno de pruebas

Para poder desarrollar y probar han sacado un [emulador](https://cloud.google.com/functions/docs/emulator). Lo tienen todavía en versión alpha, pero las cuatro cosas que he hecho yo me ha ido bien y lo tienen [publicado](https://github.com/GoogleCloudPlatform/cloud-functions-emulator) como un proyecto Open Source.

Como es habitual en proyectos de Node, se instala como una dependencia global de NPM:

```
$ npm install -g @google-cloud/functions-emulator
``` 

y se arranca invocando:

```
$ functions start
```

Esto te levanta en *background* una instancia de Node a la que le irán enviando órdenes según ejecutes el comando `functions`. Para pararlo hay que usar el parámetro `stop` (no os olvidéis porque sino os estará ocupando recursos en vuestra máquina).

Nada más levantar el emulador no tiene ninguna función desplegada y es necesario pasárselo como un comando:

```
$ functions deploy helloHttp --trigger-http

Function helloHttp deployed.
┌────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Property   │ Value                                                                                           │
├────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Name       │ hello                                                                                           │
├────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Trigger    │ HTTP                                                                                            │
├────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Resource   │ http://localhost:8010/hello-world/us-central1/helloHttp                                         │
├────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Local path │ /Users/jerolba/Documents/gcfunctions/hello-world                                                │
├────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Archive    │ file:///var/folders/c2/kzchlcf92fd4md43_wbq4kqr0000gn/T/us-central1-hello-512839aFY44cYDBJM.zip │
└────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────┘

```

El segundo parámetro es el nombre de la función que hayáis declarado en el exports del módulo. Una vez desplegado, los cambios que hagas serán actualizados en el emulador (aunque alguna vez se queda tonto y hay que reiniciarlo).

Como resultado del despliegue te dice a qué url tienes que llamar para probar la función en local: `http://localhost:8010/hello-world/us-central1/helloHttp`.

En caso de ser una función de Storage o Pub/Sub lo harías por línea de comandos:

```
functions call helloPubSub --data='{"message":"Hello World"}'
```
Puedes activar un modo *debug*, pero no lo he probado. En la [documentación](https://cloud.google.com/functions/docs/emulator#debugging_with_the_emulator) te explican como hacerlo como un proceso más de Node.JS o mediante el nuevo inspector de V8.

### Despliegue

Una vez que tenemos desarrollada nuestra función toca desplegarla. Aquí tienes múltiples opciones, casi demasiadas cuando entras en su administración web.... Yo he optado por la línea de comandos. En la mayoría de los casos te pedirán que crees un *bucket* donde guardar ese código.

Usar la línea de comandos te exige [instalar](https://cloud.google.com/sdk/downloads) y [configurar](https://cloud.google.com/sdk/docs/initializing) con vuestra cuenta el [SDK](https://cloud.google.com/sdk/) de Google Cloud. Como Cloud Functions todavía está en Beta, será necesario además [instalar](https://cloud.google.com/sdk/docs/managing-components) el componente `gcloud Beta Commands`.

Una vez que tienes el SDK instalado, configurado con tu usuario y proyecto por defecto, y un bucket creado, solo tenemos que invocar el comando de deploy:

```
$ gcloud beta functions deploy helloHttp --trigger-http --stage-bucket gs://jerolba-helloWorld

Copying file:///var/folders/c2/kzchlcf92fd4md43_wbq4kqr0000gn/T/tmpJ92Nj6/fun.zip [Content-Type=application/zip]...
- [1 files][349.3 KiB/349.3 KiB]
Operation completed over 1 objects/349.3 KiB.
Waiting for operation to finish...done.
Deploying function (may take a while - up to 2 minutes)...done.

availableMemoryMb: 256
entryPoint: helloHttp
httpsTrigger:
  url: https://us-central1-tu-proyecto-gc.cloudfunctions.net/helloHttp
latestOperation: operations/aG9tYnJlLW8tbXVqZXIvdXMtY2VudHJhbDEvaGVsbG8vSHBiemw3ZkllMVk
name: projects/tu-proyecto-gc/locations/us-central1/functions/helloHttp
sourceArchiveUrl: gs://jerolba-helloWorld/us-central1-helloHttp-uzfoawtgibcw.zip
status: READY
timeout: 60s
updateTime: '2017-03-20T10:49:22Z'
```

De estos logs podemos obtener cierta información:

* **Zona en la que se despliega**: como están en modo Beta sólo hay una zona disponible, `us-central1`

* **Memoria asignada a la función**: por defecto le asigna 256MB, pero puedes ir desde los 128MB hasta los 2GB. Asociada a cada cantidad de memoria hay una capacidad de proceso (200MHz -> 2.4GHz). Cuidado con lo que pones porque el [coste](https://cloud.google.com/functions/pricing#compute_time) va en función del valor que elijas, el número de peticiones y lo que dure cada una.

* **Url pública donde se despliega**: En este caso sería `https://us-central1-tu-proyecto-gc.cloudfunctions.net/helloHttp`. Creo que en este punto está una de las principales diferencias con AWS Lambda, porque creo que te exige usar API Gateway para exponer tus funciones. Aquí tu función queda expuesta al público, y el único control de acceso y seguridad que tendrás será la que tú implementes en tu función.

La otra opción es desplegar **desde un repositorio de código Git**. Desgraciadamente no se puede hacer desde cualquier repositorio de código, sólo desde el suyo: [Cloud Source Repositories](https://cloud.google.com/source-repositories/docs/). Aunque han creado la opción de [sincronizar automáticamente](https://cloud.google.com/source-repositories/docs/connecting-hosted-repositories) un repositorio de GitHub o Bitbucket con el suyo, y no andar configurando otro repositorio remoto.

A la hora de desplegar, le indicas cual es el repositorio, qué rama o tag, y la ruta relativa donde está el código, junto con el nombre de la función que quieres, y listo.

En cualquiera de los métodos que uses para desplegar tu código, no se sube nunca lo que tengas en `node_modules`, y **es Cloud Functions el que se descargará ese código de NPM**.

Una funcionalidad que no he encontrado ha sido la de poder pasar variables de entorno a las funciones. Lo típico, que en tu código tienes que usar un API Key o una contraseña, y no quieres que vaya en claro en el código. Lo normal es configurarlo de alguna manera en la administración del servicio, y que al arrancar te la pase como variable de entorno que poder obtener y usar desde tu código.

### Múltiples funciones

Si os habéis fijado, cuando desplegamos siempre hay que indicar qué función se está desplegando. No he encontrado la forma de desplegar a la vez todas las existentes en tu código. Por tanto, aunque tengas múltiples funciones en un solo `index.js` que compartan un gran porcentaje de código, se ejecutarán en contextos independientes, y ese estado o contexto del que hablaba al principio será distinto para cada función, y no compartido entre distintas funciones del mismo código.

Ésto me plantea la duda de cómo gestionar el despliegue de un conjunto de funciones y que éstas tengan alguna dependencia funcional entre sí. Donde necesites que todas estén desplegadas a la vez, ya que un tercero espera un comportamiento consistente entre ellas. Imagínate que necesitas cambiar una constante de configuración... mientras estás desplegando unas responden en función de un valor, y las otras con el antiguo, teniendo el conjunto un comportamiento inconsistente.

Supongo que si necesitas un despliegue atómico de un conjunto de funciones, ésta no es la solución adecuada en tu arquitectura. No sé cómo se comportará AWS Lambda, y espero que algún lector con experiencia nos saque de dudas :)

### Concurrencia

En Node JS un servidor atiende y encola todas las peticiones que le llegan y las va procesando una a una según el loop de eventos, ¿Cómo lo hace Cloud Functions cuando le llegan N peticiones seguidas/concurrentemente? ¿Puedo llegar a tener problemas de concurrencia si se ejecutan a la vez dos funciones en la misma "instancia"?

En la documentación no hay nada referido a este tema y mi conclusión (posiblemente equivocada), después de unas cuantas pruebas por encima, es que cada instancia sólo atiende una petición, y aunque esté bloqueada por I/O y pueda atender a otras peticiones como haría Node JS, no ejecutará nada más. En este caso levantará tantas instancias como sean necesarias, reutilizandolas según vayan entrando más peticiones o matándolas si no llegan más. Es decir, lo que se espera de un servicio *serverless* con autoescalado :)

Según la [documentación](https://cloud.google.com/functions/quotas) puedes tener hasta 400 funciones ejecutándose a la vez (límite que se puede subir si justificas y pagas) y cada una puede tener una duración máxima de 9 minutos (540 segundos). Por tanto deduzco que habrá por defecto un máximo de 400 instancias levantadas a la vez. Ya como curiosidad, tienen un límite de 1.000 funciones por proyecto.

### Conclusión

Cuando me enfrento a una nueva tecnología, a parte de entender cómo es a nivel funcional (qué hace, cómo se usa o gestiona), como técnico me gusta conocer cómo funciona por debajo, y por eso puede que haya tratado temas tan extraños como el estado o la concurrencia.

Mi impresión particular es que a nivel de HTTP por ahora está bien para montar servicios *de juguete* (más estando en fase Beta), principalmente debido al poco control que tienes sobre la exposición de tu API y su uso. En cosas serias se debería complementar con un API Gateway.

En la parte de funciones *Background* me parece una buena opción si ya estás metido en la nube de Google y necesitas hacer ciertas tareas de forma asíncrona y con facilidad de escalar los recursos rápidamente sin preocuparte de su gestión.

Si la carga que va a soportar el sistema es muy alta, es probable que tengas que [echar cuentas](https://cloud.google.com/products/calculator/) para saber si te merece la pena usar un sistema como éste o gestionar tú las máquinas completas, utilizando igualmente todos los mecanismos de autoescalado que ofrezca tu plataforma.

Por último recordar que este servicio no tiene ningún tipo de API estándar, y cualquier cosa que desarrolles sobre esta plataforma será difícil de mover a otro proveedor.

En cualquier caso, no podía dejar escapar la oportunidad de *trolleo*, y espero que saquen pronto otros *stacks*, como por ejemplo Java, y así poder empezar a hacer cosas en serio :D

## Reconclusión

Después de toda esta chapa y pruebas para sacar las conclusiones que os he contado, conseguí desplegar mi servicio Rest, hyperescalable, y que si nadie me lo revienta a peticiones, dará servicio dentro del [*free tier*](https://cloud.google.com/functions/pricing) por tiempo indefinido.

La url del servicio es:

`https://us-central1-hombre-o-mujer.cloudfunctions.net/gender?name=NOMBRE`

```
$ curl https://us-central1-hombre-o-mujer.cloudfunctions.net/gender?name=jeronimo

{
  "gender": "Male",
  "probability": 1,
  "totalMale": 13748,
  "totalFemale": 0,
  "name": "jeronimo"
}

$ curl https://us-central1-hombre-o-mujer.cloudfunctions.net/gender?name=yeray

{
  "gender": "Male",
  "probability": 0.9907262877605362,
  "totalMale": 10790,
  "totalFemale": 101,
  "name": "yeray"
}

```