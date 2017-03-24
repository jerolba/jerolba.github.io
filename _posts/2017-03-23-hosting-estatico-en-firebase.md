---
layout: post
title: Hosting estático en Firebase
description: "Desplegando un sitio estático en Firebase"
modified: 2017-03-23
tags: 
image:
  feature: google-datacenter.jpg
  credit: Google
  creditlink: https://www.google.com/about/datacenters/
#  layout: top
excerpt_separator: <!--more-->
---

Explorando la idea de hacer una aplicación *Serverless*, además de montar el API, me he animado a hacer una [web sencilla](hombre-o-mujer.jerolba.com) que haga uso del API que he creado para averiguar el nombre de una persona según su nombre.

Existen múltiples sitios donde alojar una web estática, siendo [GitHub Pages](https://pages.github.com/) una de las opciones que más de moda se han puesto entre la comunidad de desarrolladores para publicar la web de proyectos *open source* o el blog personal. 

Pero tiene un pequeño inconveniente: solo puedes tener un dominio personalizado por cuenta de GitHub, y el de mi cuenta está con este blog (o yo no he sabido encontrar la opción).

Así que siguiendo con mi viaje por la nube de Google he decidido probar el servicio de Firebase, que ya lleva un tiempo en el mercado.

<!--more-->

### Firebase

Firebase nació en 2011 como un *Backend as a Service* para aplicaciones móviles. La más conocida llegó a ser [Parse](http://parseplatform.org/), que no sobrevivió a la compra de Facebook. Firebase fue adquirida por Google en 2014, y tuvo mejor suerte que Parse, ya que lo integraron como un servicio de Google Cloud.

Sus principales servicios son:

* Servicio notificaciones push a móvil y mensajería
* Autenticación en los principales servicios OAuth (Google, Twitter, FaceBook o GitHub)
* Base de datos NoSQL (es decir, JSON) que autosincroniza los datos entre el servidor y los dispositivos
* Almacenamiento de ficheros, apoyándose en [Cloud Storage](https://cloud.google.com/storage/)
* Functions: No hace falta [más explicaciones](/mujeres-y-hombres-y-serverless/) :)
* Hosting: Servir un site estático, que es lo que yo necesito

### Pricing

Incluye un *free tier* que cubrirá con holgura cualquier *side project* que te plantees hacer.

Su nivel gratuito de [Spark](https://firebase.google.com/pricing/) (nada que ver con la tecnología de Big Data) en la parte de hosting ofrecen almacenamiento de 1GB en ficheros y hasta 10GB de transferencia al mes (aunque en GitHub no te dan [un toque](https://www.quora.com/What-are-bandwidth-and-traffic-limits-for-GitHub-pages/answer/Rachel-Berry-9) hasta que no llegas a los 100GB!).

Con [AWS S3](http://docs.aws.amazon.com/gettingstarted/latest/swh/getting-started-hosting-your-website.html) también puedes servir sites estáticos con un [free tier](https://aws.amazon.com/es/s3/pricing/) de hasta 15GB, pero solo durante el primer año, pasando luego a sólo 1GB al mes.

Algo interesante, que incluyen ya directamente en su versión gratuita, es que lo **sirven bajo SSL**, olvidándote tú de la gestión de certificados.

El primer plan de pago ya lo descartaría si el único servicio que usas es el de hosting de ficheros estáticos y me plantearía migrarlo a otro tipo de proveedores.

No he sabido ver en la documentación si el crédito de 300$ que dan por registrarte en Google Cloud también aplica al consumo que hagas por aquí, o si al ser comercialmente productos distintos no aplica.

### Manos a la obra

La verdad es que la web es más simple que el asa de un cubo: un formulario con un campo donde recoger el nombre y un botón para hacer la petición Ajax.

Una vez creado el HTML y el JavaScript que lo dinamice todo vamos a subirlo!

### Setup

Una vez que nos hemos dado de alta en Firebase (con una cuenta de usuario de Google), creamos un nuevo proyecto en su administración web.

Luego tendremos que instalarnos su herramienta de línea de comandos, donde va ganando últimamente la moda de NPM:

```
$ npm install -g firebase-tools
```

Para que se pueda conectar a los servidores de Firebase para mandarle los comandos necesitaremos logarnos en la línea de comandos (solo la primera vez que vayamos a usarlo):

```
$ firebase login
```

(espero que deje mis credenciales en algún sitio seguro dentro de mi máquina)

Con eso ya tendremos todo listo para iniciar el proyecto con la orden:

```
$ firebase init
```

donde nos sacará un *wizzard* en modo texto bastante currado con *checkboxes* para elegir opciones y navegar con los cursores. En este caso solo seleccionaré Hosting:

<img src="/images/FirebaseMenu.png"/>

A continuación nos preguntará:

* A qué proyecto de los que tenemos creados asociarse
* Carpeta donde se ubicarán los ficheros a publicar (por defecto public)
* Si queremos que las urls que acaben en `/` intente servirlas con el `index.html` correspondiente

Al finalizar nos creará una serie de ficheros de configuración.

### Despliegue

La única forma que he encontrado de desplegar el site es mediante el comando deploy. No he visto ninguna opción de hacer un *upload* en la administración web.

No sé si internamente el comando hará un `rsync` de los ficheros en local y los ficheros ya existentes en remoto, porque a poco que tengas un site con muchos ficheros o imágenes pesadas puede llegar a tardar mucho:

```
$ firebase deploy

=== Deploying to 'jeropost-9f310'...

i  deploying hosting
i  hosting: preparing public directory for upload...
Uploading: [                                        ] 0%✔  hosting: public folder uploaded successfully
✔  hosting: 1 files uploaded successfully
i  starting release process (may take several minutes)...

✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/jeropost-9f310/overview
Hosting URL: https://jeropost-9f310.firebaseapp.com
```

¡Con esto ya tendremos su hola mundo publicado y funcionando! Al final del todo os encontraréis la url asignada a tu site recién desplegado.

Ya solo tendréis que meter todo vuestro código html, css y demás recursos en la carpeta public, y volver a hacer deploy para tener vuestro site de verdad.

Me ha sorprendido no encontrarme ninguna opción de despliegue asociada a un repositorio de código, ya sea el suyo propio de [Cloud Service Repositories](https://cloud.google.com/source-repositories/docs/) o GitHub.

Acostumbrado a GiHub Pages, se echa de menos que el deploy no se haga de forma automática con un simple push al repositorio de código. Aunque no creo que costara mucho montar algún tipo de *webhook* que lo hiciera automáticamente.

Si vieras que la has cagado en el despliegue y necesitaras deshacer un cambio, en el panel de administración web tienes un listado de los últimos despliegues que has hecho y **te permite hacer *rollback* a cualquiera de ellos.**

### Dominio personalizado

Desde el panel de administración web puedes [gestionar el dominio](https://firebase.google.com/docs/hosting/custom-domain) final de la web. Una vez que les dices qué dominio quieres usar te pedirán **verificar la propiedad del dominio** creando un registro `TXT` en tu archivo de zona DNS. Un vez verificado te darán dos direcciones IP que asociar a dos registros `A` del DNS.

Todo este proceso de modificación de los registros del DNS dependerá de donde tengas alojado el DNS, pero suele ser bastante sencillo.

### HTTP/2 y CDN

Google históricamente se ha preocupado mucho en optimizar el rendimiento a la hora de servir webs, y ha sido uno de los impulsores de [HTTP/2](https://es.wikipedia.org/wiki/HTTP/2). Así que en un servicio suyo no podía faltar esa funcionalidad, y **todo el tráfico es servido mediante HTTP/2**. 

Si miramos cómo son las peticiones en webs alojadas en GitHub Pages, S3 o incluso en [CloudFront](https://aws.amazon.com/es/cloudfront/) de Amazon, encontraremos que por ahora todas son servidas mediante HTTP/1.1 (por lo menos en los sitios que he probado).

Como comenté antes, el soporte de SSL es automático y se encargan ellos de gestionar el certificado SSL, mientras que con AWS creo que tienes que proporcionarselo tú y en GitHub Pages no he encontrado ni la opción. 

Aunque en la especificación de HTTP/2 el uso de cifrado TLS es opcional, los navegadores harán obligatorio el uso de SSL para usar HTTP/2, así que alguna facilidad deberán ofrecer otros proveedores, aunque sea mediante [Let’s Encrypt](https://letsencrypt.org/) si no quieren quedarse atrás.

Otra característica reseñable de Firebase como servicio de hosting es que también **se comporta como un [CDN](https://es.wikipedia.org/wiki/Red_de_entrega_de_contenidos)**, haciendo que los ficheros sean servidos desde el *data center* más cercano al usuario, despreocupándote de si está en EE.UU., Europa o en la China.

Una alternativa sería usar [Cloudflare](https://www.cloudflare.com/es/) como complemento a tu hosting, ya que también ofrece servicio de CDN, sirve HTTP/2 y gestiona el certificado SSL. Aunque nunca lo he usado tiene buenas [referencias](https://www.cloudflare.com/case-studies/) y una versión [gratuita](https://www.cloudflare.com/es/plans/) bastante completa.

### Configuración avanzada

Revisando la documentación me ha sorprendido encontrarme [opciones de configuración avanzadas](https://firebase.google.com/docs/hosting/full-config#section-advanced-properties) propias de la configuración de un Apache o Nginx:

* **Redireccionamientos**: dado un patrón, redirigir a otra url con un 301 o 302. Esa url de destino puede ser relativa en tu web o absoluta hacia otro dominio. Esta opción viene muy bien cuando has movido o eliminado un recurso y no quieres dar un 404, ya que perderías páginas vistas, provocarás frustración en tus usuarios o sufrirías penalizaciones por parte de Google a nivel SEO.
* **Rewrite**: Dado un patrón de url, sirve el fichero que se indique como destino. Aunque no es tan potente a la hora de crear reglas como pueda ser Nginx o Apache, porque no deja capturar variables o usar los parámetros de la url (en la documentación no menciona nada al respecto).
* **Cabeceras**: Dado un patrón de url o fichero de recursos (ficheros los css, js, etc), permiten establecer las cabeceras HTTP de la respuesta. Esto permite personalizar, por ejemplo, el tiempo de caché `Cache-Control` según el tipo de fichero o ruta, controlar el [CORS](https://en.wikipedia.org/wiki/Cross-origin_resource_sharing), o especificar el `Content-Type` en concreto. 

Esos patrones de urls siguen la notación [glob](https://en.wikipedia.org/wiki/Glob_%28programming%29), que habréis usado ya en el fichero `.gitignore` de [Git](https://git-scm.com/docs/gitignore).

A poco que tengas un poco de cariño a cómo se sirve tu web, te preocupes por su rendimiento y que no haya enlaces rotos, estas configuraciones te vendrán muy bien.

### Conclusión

Si lo que necesitas es crear una web estática sencilla, sin mucho tráfico, olvidarte de contratar un alojamiento y de gestionar su disponibilidad, el servicio de hosting de **Firebase cubrirá con creces tus necesidades**.

A poco que necesites algún comportamiento dinámico o pienses que vayas a tener más tráfico, deberías pensar en usar algún servicio en Cloud que, por muy poco dinero (desde 5 dólares), te dan una instancia lo suficientemente potente para la parte dinámica y con hasta 1TB de transferencia. A parte de la infinidad de servicios de VPS, los más conocidos a nivel de Cloud, entre otros, son: [Digital Ocean](https://m.do.co/c/6f902f4f0ee6), [Amazon Lightsail](https://amazonlightsail.com/) o [Linode](https://www.linode.com/). 

El soporte de HTTP/2, SSL, ser un CDN y dar cierto control con los redireccionamientos o cabeceras, todo dentro del mismo producto y sin tener que contratar ni configurar más opciones, son un plus a tener en cuenta a la hora de determinar dónde alojar una web estática.

### Reconclusión

Como ya contaba en la introducción he creado una web donde poder averiguar el género de una persona según el nombre: [https://hombre-o-mujer.jerolba.com](https://hombre-o-mujer.jerolba.com) 

La web es muy sencilla, y la verdad es que engancha porque a lo tonto te tiras un buen rato probando nombres... ¿sabías que en España hay censadas 23 mujeres llamadas [Daenerys](https://es.wikipedia.org/wiki/Daenerys_Targaryen)? :)

Sobre el diseño de la web en sí, agradecer a [José Luis Antúnez](https://twitter.com/jlantunez) el haber creado una herramienta para hacer presentaciones llamada [WebSlides](https://webslides.tv/), que permite además crear landings sencillas y resultonas como esta. Os recomiendo que le echéis un vistazo porque está muy bien.

