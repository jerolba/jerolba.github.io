---
layout: post
title: "Cosas de Mapas"
description: "HashMap es una de las estructuras de datos más usadas y sencillas de Java, pero si no tienes cuidado puedes meter la pata hasta el fondo."
modified: 2019-08-05
tags: 
image:
  path: images/circuit_board.jpg
  feature: circuit_board.jpg
  credit: Mathew Schwartz
  creditlink: https://unsplash.com/photos/iGheu30xAi8
excerpt_separator: <!--more-->
---

Al Construir la librería [Bikey](https://github.com/jerolba/bikey), para hacer que fuera lo más fácil y natural de usar para cualquier programador con experiencia en Java, intenté que el API siguiera los mismos patrones y semánticas que la librería de Collecciones de Java. Para eso estudié y repliqué el comportamiento (e incluso Javadoc) del [API de Map](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/Map.html).

Al hacerlo, me di cuenta de una cosa de la que no era consciente (o nunca me había planteado): los métodos [`Collection<V> values()`](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/Map.html#values()), [`Set<K> keySet()`](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/Map.html#keySet()), y [`Set<Map.Entry<K,​V>> entrySet()`](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/Map.html#entrySet()) **devuelven vistas del mapa**:

<!--more-->

<img src="/images/API_HashMap_values.png"/>

¿Qué significa eso? Los Sets y Collections devueltos por esos métodos no son nuevas instancias de colecciones que contengan referencias a las claves y/o valores del mapa, sino que **son implementaciones que simulan su comportamiento y que por detrás usan directamente los elementos que forman Map**.

## Bugs

No tener esto en cuenta puede ser una fuente de _bugs_, y dependiendo de lo lejos que esté el código que obtiene esa colecciones de su uso, puede traerte más de un quebradero de cabeza.

Cada acción sobre uno de esos Sets o Collections se ve reflejado en el mapa asociado:

- Cuando iteras un `values()`, estas iterando los elementos que forman el mapa y obteniendo sólo el valor asociado a cada clave.
- Cuando preguntas si existe un valor de `keySet()`, estás indirectamente llamando al método `containsKey` del mapa.
- Cuando eliminas un valor de `keySet()`, estas eliminando un elementos del mapa.
- Cuando llamas al método `clear()` de `entrySet()`, estás vaciando el mapa.
- Cuando añades elementos al mapa, estás modificando las colecciones asociadas.

Por tanto cuando uses las colecciones procedentes de un mapa tienes que ser consciente de que **al modificar el mapa estas modificando los objetos `Collection<V>` o `Set<K>` del mapa que tuvieras referenciados.** Es decir, tiene efectos secundarios.

Si quieres asegurarte de no tener _side effects_, deberás hacerte una copia de las colecciones:

- `Set<K> keysCopy = new HashSet<>(map.keySet());`
- `List<V> valuesCopy = new ArrayList<>(map.values());`
- `Set<Map.Entry<K,​V>> entryCopy = new HashSet<>(map.entrySet());`

### Ejemplo

Mejor verlo con un [ejemplo real de código](https://gist.github.com/jerolba/070c725b96ee8178492815d93f87a7a3):

{% highlight java linenos %}

void foo() {
    mapChangeModifiesValuesSet();
    mapChangeModifiesKeysSet();
    valuesSetChangeModifiesMap();
}

void mapChangeModifiesValuesSet() {
    Map<Integer, User> usersMap = loadUsersFromWherever();
    UseValues withValues = new UseValues(usersMap.values());
    usersMap.put(4, new User(4, "Donald"));
    withValues.doSomething();
}

UseKeys mapChangeModifiesKeysSet() {
    Map<Integer, User> usersMap = loadUsersFromWherever();
    UseKeys withKeys = new UseKeys(usersMap.keySet());
    usersMap.put(4, new User(4, "Donald"));
    withKeys.doSomething();
    return withKeys;
}

void valuesSetChangeModifiesMap() {
    Map<Integer, User> usersMap = loadUsersFromWherever();
    UseValues withValues = new UseValues(usersMap.values());
    withValues.clear();
    System.out.println("Map content: " + usersMap);
}

class UseValues {

    private final Collection<User> users;

    public UseValues(Collection<User> users) {
        this.users = users;
        System.out.println("UseValues constructor: " + users);
    }

    public void doSomething() {
        System.out.println("UseValues doSomething: " + users);
    }

    public void clear() {
        users.clear();
    }

}

class UseKeys {

    private final Collection<Integer> ids;

    public UseKeys(Collection<Integer> ids) {
        this.ids = ids;
        System.out.println("UseKeys constructor: " + ids);
    }

    public void doSomething() {
        System.out.println("UseKeys doSomething: " + ids);
    }

}

class User {
    private final Integer id;
    private final String name;
    public User(Integer i, String name) {
        this.id = i;
        this.name = name;
    }
    public Integer getId() { return id; }
    public String getName() { return name; }
    public String toString() { return id + ": " + name; }
}

Map<Integer, User> loadUsersFromWherever() {
    Map<Integer, User> users = new HashMap<>();
    users.put(1, new User(1, "John"));
    users.put(2, new User(2, "Peter"));
    users.put(3, new User(3, "Rose"));
    return users;
}
{% endhighlight %}

Al ejecutar el método `mapChangeModifiesValuesSet`, vemos que la colección de usuarios se vé modificada:

```console
UseValues constructor: [1: John, 2: Peter, 3: Rose]
UseValues doSomething: [1: John, 2: Peter, 3: Rose, 4: Donald]
```

Al ejecutar el método `mapChangeModifiesKeysSet`, vemos que la colección de identificadores también se modifica:

```console
UseKeys constructor: [1, 2, 3]
UseKeys doSomething: [1, 2, 3, 4]
```

Al ejecutar el método `valuesSetChangeModifiesMap` vemos que la modificación va en los dos sentidos, y que el mapa también se puede cambiar indirectamente:

```console
UseValues constructor: [1: John, 2: Peter, 3: Rose]
Map content: {}
```

Por tanto, si vas a usar estas colecciones asegúrate de:

- o bien realizar una copia de las mismas si no sabes donde van a acabar
- o de usarlas en un ámbito o contexto muy cercano a su obtención para iterar.

Mi recomendación es usar sólo esas colecciones cuando necesitas iterar el mapa por clave y/o valor:

```java
for (Set<Integer> id: users.keySet()) {
  ...
}

users.entrySet().stream()
     .filter(u -> u.getValue().getAge() > 18)
     .collect(toMap(u -> u.getKey(), u -> createReccord(u.getValue())));
```

## _Memory Leak_

Si te quedas con alguna referencia a cualquiera de las tres colecciones, otro problema importante que puedes encontrar es el de tener un _memory leak_.

Las colecciones que devuelven los tres métodos están implementadas como _inner classes_ no estáticas dentro de `HashMap`, y por tanto **contienen una referencia al `Map` y los atributos miembros de la clase.**

Si de un mapa te guardas la referencia de su keySet/values/entrySet, te estarás quedando con todo el `HashMap`, y con los valores que lo forman. Por lo que el recolector de basura no podrá liberar el espacio ocupado por el mapa y los valores asociados.

En el ejemplo, si nos guardamos la referencia al objeto `UseKeys` devuelto por el método `mapChangeModifiesKeysSet`, aunque el ámbito de la variable `usersMap` termine y se libere la referencia, el mapa y todos sus valores de tipo `User` seguirán vivos en memoria porque su referencia es capturada indirectamente por el objeto `UseKeys`. El mapa estará en memoria tanto tiempo como lo esté la instancia de `UseKeys` devuelta.

Aunque el Set sólo parezca que contiene las claves (simples Integers), estaremos consumiendo toda la memoria asociada a cada [`Map.Entry`](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/Map.Entry.html) del mapa, y la memoria asociada a cada valor del mapa, que dependiendo de su tamaño puede ser aún peor.

<style>
.highlight .lineno {
    padding-right: 0px;
}
</style>