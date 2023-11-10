---
layout: post
title: "Mapas con clave compuesta"
description: "¿Qué estructura de datos es mejor para guardar de forma indexada un objeto con clave compuesta? ¿Es mejor un Map<Tuple<A,B>, Object> o un Map<A,Map<B,Object>>?"
modified: 2019-03-11
tags:
image:
  path: images/chunlea-ju-468174-unsplash.jpg
  feature: chunlea-ju-468174-unsplash.jpg
  credit: Chunlea Ju
  creditlink: https://unsplash.com/photos/8fs1X0JFgFE
excerpt_separator: <!--more-->
---

En mi [último post](/hashing-y-mapas/) hablé de los problemas de usar una función hash incorrecta cuando guardas un objeto con clave compuesta en un `HashMap` de Java, pero me quedé con la duda: **¿qué estructura de datos es mejor a la hora de indexar esos objetos?**

Siguiendo con el mismo ejemplo hablaré de productos y tiendas, y usaré sus identificadores para formar la clave del mapa. Las estructuras de datos propuestas son:

- Un único mapa con una clave que contenga sus índices:  `HashMap<Tuple<Integer, Integer>, MyObject>`, al que llamaré TupleMap.
- Un mapa anidado: `HashMap<Integer, HashMap<Integer, MyObject>>`, al que llamaré DoubleMap.

<!--more-->

Para salir de dudas y sacar conclusiones mediré:

- La memoria consumida al indexar una colección de objetos
- El tiempo necesario para guardar de forma aleatoria esa colección de objetos
- El tiempo necesario para recuperar, también de forma aleatoria, todos los elementos de la colección

<hr/>

**TL;DR:** este post es más aburrido, así que os ahorraré el trabajo de leerlo entero:
- **DoubleMap es más eficiente en memoria** y consume un 30% menos que TupleMap
- En colecciones grandes, DoubleMap es un 30% más rápido indexando, mientras que **en colecciones pequeñas es bastante más rápido**
- En colecciones grandes, DoubleMap y TupleMap tienen un rendimiento parecido consultando, mientras que **en colecciones pequeñas DoubleMap es sensiblemente más rápido**

<hr/>

Todo el código fuente necesario para reproducir las pruebas está en este repositorio de GitHub: [https://github.com/jerolba/hashcode-map](https://github.com/jerolba/hashcode-map).

En este caso aplicaré la función hash que genera menor número de colisiones y minimiza el consumo de memoria, por lo que no me tendré que preocupar de esa parte en mis *benchmarks* y estaré en un caso optimo (y optimista) en la versión de TupleMap de no tener que lidiar con las colisiones.

## Consumo de memoria

Si usamos un objeto como clave primaria, ¿cuánta memoria consumirán esas instancias de la clave primaria?
Si usamos HashMaps anidados, ¿penalizará el *overhead* de esos objetos?

Si rellenamos de forma aleatoria un mapa con 10.000 productos y 500 tiendas, obtenemos la siguiente gráfica de consumo de memoria, teniendo en cuenta sólo las clases involucradas en los mapas:

<iframe width="700" height="446" seamless frameborder="0" scrolling="no" src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRiwv5Uo_b2c7jklJn59b__EaUnNfnhakDaZUgjMue7tE9OL0IQPbwFmY7QR42VGCEH4jJJkHLIPpk2/pubchart?oid=387301845&amp;format=interactive"></iframe>

De media, el mapa con un objeto clave (Tuple) consume un 50% más de memoria, ocupando finalmente 299 MB frente a los 193 MB del DoubleMap.

Mirando el histograma de los objetos en memoria vemos que las instancias de la clase Tuple están ocupando 114 MB y no se están produciendo colisiones al no aparecer instancias del tipo TreeMap:

<table class="table-histogram">
<tbody>
<tr><td>Class</td><td>instances</td><td>size</td></tr>
<tr><td>java.util.HashMap$Node</td><td>5.000.000</td><td>160.000.000</td></tr>
<tr><td>com.jerolba.bikey.Tuple</td><td>5.000.000</td><td>120.000.000</td></tr>
<tr><td>java.util.HashMap$Node[]</td><td>1</td><td>33.554.448</td></tr>
<tr><td>java.util.HashMap</td><td>1</td><td>48</td></tr>
<tr><td>com.jerolba.bikey.TupleMap</td><td>1</td><td>16</td></tr>
</tbody>
</table>

mientras que en la versión de DoubleMap las instancias de HashMap extra están ocupando apenas medio megabyte, y la mayor diferencia radica en el espacio empleado en los arrays de nodos:

<table class="table-histogram">
<tbody>
<tr><td>Class</td><td>instances</td><td>size</td></tr>
<tr><td>java.util.HashMap$Node</td><td>5.010.000</td><td>160.320.000</td></tr>
<tr><td>java.util.HashMap$Node[]</td><td>10.001</td><td>41.185.552</td></tr>
<tr><td>java.util.HashMap</td><td>10.001</td><td>480.048</td></tr>
<tr><td>com.jerolba.bikey.DoubleMap</td><td>1</td><td>16</td></tr>
</tbody>
</table>

Por tanto, si al usar este tipo de mapas necesitas crear nuevas instancias del objeto que representa la clave primaria, yo optaría por usar una estructura de datos del tipo `HashMap<A, HashMap<B, MyObject>>`.

## Rendimiento en indexación

¿Cuánto se tarda en crear una colección grande en cada caso? ¿Influye mucho el número de elementos de cada tipo?

Para no aburriros con los detalles del *benchmark* lo resumo en una única gráfica donde se muestra el tiempo (en milisegundos) necesario para insertar una colección aleatoria de productos y tiendas según diferentes números totales de productos y tiendas:

<iframe width="700" height="438" seamless frameborder="0" scrolling="no" src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRiwv5Uo_b2c7jklJn59b__EaUnNfnhakDaZUgjMue7tE9OL0IQPbwFmY7QR42VGCEH4jJJkHLIPpk2/pubchart?oid=2002200322&amp;format=interactive"></iframe>

De media, mantener toda la información en un único mapa tiene una penalización de al menos un 40% de tiempo.

Aunque no muestre gráficas (tienes los datos al final del post), el aumento del número de datos en cualquiera de las dos variables (productos o tiendas) aumenta el tiempo de ejecución de forma lineal.

## Rendimiento en consulta

¿Cuánto se tarda en acceder al valor asociado a una clave compuesta? ¿Penalizará el tener que consultar en dos mapas? En la versión de TupleMap, ¿Se tarda más si por cada consulta tengo que instanciar un objeto Tuple?

Al igual que antes, resumiré en una única gráfica el *benchmark* de consultar en una colección grande todos sus valores de forma aleatoria, según diferentes números totales de productos y tiendas:

<iframe width="700" height="425" seamless frameborder="0" scrolling="no" src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRiwv5Uo_b2c7jklJn59b__EaUnNfnhakDaZUgjMue7tE9OL0IQPbwFmY7QR42VGCEH4jJJkHLIPpk2/pubchart?oid=1136030534&amp;format=interactive"></iframe>

Aunque el tiempo de ejecución de DoubleMap está siempre ligeramente por debajo de el de TupleMap podemos considerar que tienen un rendimiento muy similar, y por tanto el tiempo de acceso no debería condicionarnos la elección de una estructura de datos u otra.

Sorprendentemente tener que crear una instancia de `Tuple` por cada consulta no penaliza en el rendimiento, e incluso lo mejora ligeramente en colecciones grandes (las optimizaciones de la JVM son inescrutables)

## Colecciones pequeñas

Los problemas a los que me enfrento normalmente usan colecciones grandes, pero en los resultados de los benchmarks podemos ver que en colecciones pequeñas la implementación de DoubleMap tiene bastante mejor rendimiento.

**Indexación**

Para visualizarlo mejor mostraré dos gráficas: cuando la colección tiene 1.000 productos y cuando tiene 2.000.

<iframe width="665" height="336" seamless frameborder="0" scrolling="no" src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRiwv5Uo_b2c7jklJn59b__EaUnNfnhakDaZUgjMue7tE9OL0IQPbwFmY7QR42VGCEH4jJJkHLIPpk2/pubchart?oid=1416362454&amp;format=interactive"></iframe>

<iframe width="665" height="336" seamless frameborder="0" scrolling="no" src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRiwv5Uo_b2c7jklJn59b__EaUnNfnhakDaZUgjMue7tE9OL0IQPbwFmY7QR42VGCEH4jJJkHLIPpk2/pubchart?oid=1468096037&amp;format=interactive"></iframe>

Los tiempos de la versión TupleMap son entre 2 y 6 veces peores. Sin haber analizado el comportamiento interno de la JVM/CPU/Memoria, intuyo que el menor tamaño en datos influye en la localidad de la información y dará menos problema con las línea de caché.

**Consulta**

Igualmente lo analizamos viendo dos gráficas para distinto número de productos:

<iframe width="665" height="336" seamless frameborder="0" scrolling="no" src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRiwv5Uo_b2c7jklJn59b__EaUnNfnhakDaZUgjMue7tE9OL0IQPbwFmY7QR42VGCEH4jJJkHLIPpk2/pubchart?oid=1871636811&amp;format=interactive"></iframe>

<iframe width="665" height="336" seamless frameborder="0" scrolling="no" src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRiwv5Uo_b2c7jklJn59b__EaUnNfnhakDaZUgjMue7tE9OL0IQPbwFmY7QR42VGCEH4jJJkHLIPpk2/pubchart?oid=2017029969&amp;format=interactive"></iframe>

Los tiempos de la versión TupleMap son entre un 50% y un 150% peores. Tampoco me atrevo a asegurar a qué se debe, pero sigo creyendo que los tiros van por problemas con la caché.

## Conclusiones

A pesar de los resultados obtenidos, en este caso considero que es difícil sacar unas conclusiones claras realizando *microbenchmarking*. **El comportamiento de las estructuras de datos pueden variar entre el código de producción y el del *benchmark*.**

En código de producción, entre acceso y acceso al mapa, tu aplicación puede hacer muchas cosas que influyan en la disponibilidad de la información en las cachés, generando un patrón de acceso complentamente distinto al del *benchmark*.

Personalmente me quedo con la idea de consumir menos memoria no instanciando la clase Tuple y usar directamente HashMaps anidados. Para evitar el código feo de tanto generico, puedes abstraer y encapsular ese código en una clase.

Tener que **insertar/consultar en dos HashMaps parece que no supone un problema de rendimiento**, e incluso es más rápido, sobre todo en colecciones relativamente pequeñas.

Usando DoubleMap nos olvidamos del problema de tener que [elegir una función hash](/hashing-y-mapas/) que minimice las colisiones, ya que la clave estaría distribuida entre los dos niveles de HashMaps.

## Resultados de los *benchmarks*

El código fuente para ejecutar los *benchmarks* están en el [repositorio de GitHub](https://github.com/jerolba/hashcode-map), pero para que podáis ver los datos de las gráficas en crudo os copio los resultados. Así además podéis hacer vuestros análisis y sacar vuestras conclusiones.

**Indexación**

<table class="table-bench">
<tr><td>Nº Productos</td><td>Nº Tiendas</td><td>Total</td><td>TupleMap<br/>(ms)</td><td>DoubleMap<br/>(ms)</td></tr>
<tr><td>1.000</td><td>100</td><td>100.000</td><td>33,1</td><td>5,61</td></tr>
<tr><td>2.500</td><td>100</td><td>250.000</td><td>103,38</td><td>24,78</td></tr>
<tr><td>5.000</td><td>100</td><td>500.000</td><td>177,71</td><td>116,43</td></tr>
<tr><td>7.500</td><td>100</td><td>750.000</td><td>272,02</td><td>160,95</td></tr>
<tr><td>10.000</td><td>100</td><td>1.000.000</td><td>314,94</td><td>241,86</td></tr>
<tr><td>1.000</td><td>250</td><td>250.000</td><td>129,18</td><td>19,82</td></tr>
<tr><td>2.500</td><td>250</td><td>625.000</td><td>292,97</td><td>114,85</td></tr>
<tr><td>5.000</td><td>250</td><td>1.250.000</td><td>644,29</td><td>421,45</td></tr>
<tr><td>7.500</td><td>250</td><td>1.875.000</td><td>1.061,19</td><td>631,18</td></tr>
<tr><td>10.000</td><td>250</td><td>2.500.000</td><td>1.432,11</td><td>1.102,94</td></tr>
<tr><td>1.000</td><td>500</td><td>500.000</td><td>326,49</td><td>55,98</td></tr>
<tr><td>2.500</td><td>500</td><td>1.250.000</td><td>805,16</td><td>368,4</td></tr>
<tr><td>5.000</td><td>500</td><td>2.500.000</td><td>1.503,63</td><td>994,39</td></tr>
<tr><td>7.500</td><td>500</td><td>3.750.000</td><td>2.601,49</td><td>1.687,45</td></tr>
<tr><td>10.000</td><td>500</td><td>5.000.000</td><td>3.158,44</td><td>2.601,42</td></tr>
<tr><td>1.000</td><td>750</td><td>750.000</td><td>450,98</td><td>82,68</td></tr>
<tr><td>2.500</td><td>750</td><td>1.875.000</td><td>1.427,11</td><td>569,73</td></tr>
<tr><td>5.000</td><td>750</td><td>3.750.000</td><td>2.531,31</td><td>1.347,68</td></tr>
<tr><td>7.500</td><td>750</td><td>5.625.000</td><td>3.730,37</td><td>2.436,08</td></tr>
<tr><td>10.000</td><td>750</td><td>7.500.000</td><td>5.108,52</td><td>3.753,73</td></tr>
<tr><td>1.000</td><td>1.000</td><td>1.000.000</td><td>790,76</td><td>272,73</td></tr>
<tr><td>2.500</td><td>1.000</td><td>2.500.000</td><td>1.833,54</td><td>905,38</td></tr>
<tr><td>5.000</td><td>1.000</td><td>5.000.000</td><td>3.487,37</td><td>2.360,07</td></tr>
<tr><td>7.500</td><td>1.000</td><td>7.500.000</td><td>5.550,26</td><td>3.886,36</td></tr>
<tr><td>10.000</td><td>1.000</td><td>10.000.000</td><td>7.763,96</td><td>5.728,61</td></tr>
</table>

**Consulta**
<table class="table-bench">
<tr><td>Nº Productos</td><td>Nº Tiendas</td><td>Total</td><td>TupleMap<br/>(ms)</td><td>Tuple new<br/>(ms)</td><td>DoubleMap<br/>(ms)</td></tr>
<tr><td>1.000</td><td>100</td><td>100.000</td><td>12,08</td><td>12,55</td><td>3,81</td></tr>
<tr><td>2.500</td><td>100</td><td>250.000</td><td>37,11</td><td>38,21</td><td>14,35</td></tr>
<tr><td>5.000</td><td>100</td><td>500.000</td><td>77,40</td><td>77,39</td><td>46,84</td></tr>
<tr><td>7.500</td><td>100</td><td>750.000</td><td>125,96</td><td>126,35</td><td>68,53</td></tr>
<tr><td>10.000</td><td>100</td><td>1.000.000</td><td>148,55</td><td>141,47</td><td>163,37</td></tr>
<tr><td>1.000</td><td>250</td><td>250.000</td><td>48,96</td><td>50,41</td><td>18,30</td></tr>
<tr><td>2.500</td><td>250</td><td>625.000</td><td>140,25</td><td>144,70</td><td>70,04</td></tr>
<tr><td>5.000</td><td>250</td><td>1.250.000</td><td>332,23</td><td>344,52</td><td>242,27</td></tr>
<tr><td>7.500</td><td>250</td><td>1.875.000</td><td>533,58</td><td>498,65</td><td>428,10</td></tr>
<tr><td>10.000</td><td>250</td><td>2.500.000</td><td>689,37</td><td>656,38</td><td>640,08</td></tr>
<tr><td>1.000</td><td>500</td><td>500.000</td><td>112,44</td><td>115,91</td><td>67,37</td></tr>
<tr><td>2.500</td><td>500</td><td>1.250.000</td><td>426,38</td><td>436,60</td><td>236,71</td></tr>
<tr><td>5.000</td><td>500</td><td>2.500.000</td><td>838,11</td><td>827,97</td><td>721,81</td></tr>
<tr><td>7.500</td><td>500</td><td>3.750.000</td><td>1.092,23</td><td>1.032,17</td><td>1.146,23</td></tr>
<tr><td>10.000</td><td>500</td><td>5.000.000</td><td>1.659,28</td><td>1.671,45</td><td>1.445,54</td></tr>
<tr><td>1.000</td><td>750</td><td>750.000</td><td>220,95</td><td>228,46</td><td>104,46</td></tr>
<tr><td>2.500</td><td>750</td><td>1.875.000</td><td>690,21</td><td>694,86</td><td>493,78</td></tr>
<tr><td>5.000</td><td>750</td><td>3.750.000</td><td>1.224,58</td><td>1.185,30</td><td>1.052,61</td></tr>
<tr><td>7.500</td><td>750</td><td>5.625.000</td><td>1.950,89</td><td>2.206,49</td><td>1.735,02</td></tr>
<tr><td>10.000</td><td>750</td><td>7.500.000</td><td>2.750,52</td><td>2.567,10</td><td>2.750,77</td></tr>
<tr><td>1.000</td><td>1.000</td><td>1.000.000</td><td>342,89</td><td>351,78</td><td>216,07</td></tr>
<tr><td>2.500</td><td>1.000</td><td>2.500.000</td><td>973,66</td><td>1.019,16</td><td>677,97</td></tr>
<tr><td>5.000</td><td>1.000</td><td>5.000.000</td><td>1.838,45</td><td>1.968,09</td><td>1.618,03</td></tr>
<tr><td>7.500</td><td>1.000</td><td>7.500.000</td><td>2.789,49</td><td>2.598,46</td><td>2.448,23</td></tr>
<tr><td>10.000</td><td>1.000</td><td>10.000.000</td><td>4.468,78</td><td>4.318,66</td><td>3.970,30</td></tr>
</table>

<style>
.table-histogram td:nth-child(2), td:nth-child(3), td:nth-child(4), td:nth-child(5), td:nth-child(6) {
    text-align: right;
}
</style>