# AssetMapper

## Objectif
L'objectif de ce document est d'apprendre à gérer les ressources d'un projet Symfony avec le nouveau composant AssetMapper

## Intro
Avec la généralisation des navigateurs modernes, l’utilisation d’un bundler n’est plus aussi indispensable. Sensio Labs propose donc une solution alternative (et plus simple) à Webpack pour la gestion des assets.

#### Cette solution se base sur deux socles techniques :

- La capacité des navigateurs de nativement supporter les imports javascript.
- Le protocole HTTP/2 qui parallèlise le chargement des ressources et rend moins indispensable la consolidation dans un seul fichier.

#### Les services rendus par ce composant

- Gestion des ressources : Tous les fichiers contenus dans le dossier `assets` sont rendus disponibles pour le dossier `public`via une fonction Twig `{{ asset() }}`.
- Gestion des version : La fonction Twig ajoute un hash afin d'invalider le cache quand la ressource change.
- ImportMap : Un système d’alias qui fait correspondre l’identifiant d’une ressource avec l’url qui permet de la charger.


## Installation

```
composer require symfony/asset-mapper symfony/asset symfony/twig-pack
```

Grâce à la magie de `Symfony Flex` nous obtenons les ressources suivantes :

- Un dossier `assets` contenant les fichiers `app.js` et `styles/app.css`.
- Un fichier de configuration `config/packages/asset_mapper.yml`
- Un fichier `importmap.php`

## Utilisation

### Avec une image
C’est très simple, il suffit de placer le fichier dans le dossier `assets` et d’utiliser la fonction Twig `{{ asset() }}` dans le modèle.

``` Twig
<img src="{{ asset('photo.jpg')}}">
```

Ce qui donnera le résultat suivant dans le navigateur
``` html
<img src="/assets/photo-FxLwN4.jpg">
```

En développement, Symfony établit une correspondance entre la route `/assets` et le dossier `assets` qui est en dehors de la racine du serveur web.
En production, il est rare que l’on utilise le serveur interne de Symfony. Il faut donc exporter le dossier `assets` dans `public` avec la commande suivante :

```bash
symfony console asset-map:compile
```

### Javascript et CSS
Observons les fichiers générés par Flex lors de l’installation d’AssetMapper :

<!--<p class="codeblock-label">app.js</p>-->

**app.js**

```javascript
import './styles/app.css';

console.log('This log comes from assets/app.js - welcome to AssetMapper! 🎉');
```

**base.html.twig**

```Twig
{% block javascripts %}
   {% block importmap %}  
        {{ importmap('app') }}  
   {% endblock %}
{% endblock %}
```

**importmap.php**

```php
return [
    'app' => [
        'path' => './assets/app.js',
        'entrypoint' => true,
    ]
];
```

Quelques constats

- Le fichier `app.js` importe le css (comme avec Webpack).
- Le fichier `importmap.php` référence une entrée `app` et un chemin d’accès correspondant.
- Dans le Twig, on utilise le nom déclaré dans `importmap` pour charger la ressource correspondante.

#### Un test

<procedure>
<step>
        Dans <code>assets</code>, créer un fichier <code>messages.js</code> dans lequel vous ajouterez le code suivant :
        <code-block>
            console.log('message');
        </code-block>
</step>

<step>
        Importer ce fichier <code>messages.js</code> dans <code>app.js</code>
</step>

<step>
        Tester la page et constater le résultat dans la console du navigateur
</step>
</procedure>

#### Un autre test

<procedure>
<step>
        Dans <code>assets</code>, créer un fichier <code>cart.js</code> dans lequel vous ajouterez le code suivant :
        <code-block>
            console.log('gestion du panier');
        </code-block>
</step>

<step>
        Déclarer ce fichier dans <code>importmap.php</code> en suivant le modèle de <code>app</code>
</step>

<step>
        Importer ce fichier dans <code>base.html.twig</code> 
        <code-block>
            {% block javascripts %}
                {% block importmap %}  
                    {{ importmap('app') }}  
                    {{ importmap('cart') }}  
                {% endblock %}
            {% endblock %}
        </code-block>
</step>

<step>
        Tester la page et constater le résultat dans la console du navigateur
</step>

<step>
        Passer entrypoint à false et tester à nouveau
</step>
</procedure>

### Conclusions

- Les ressources très largement partagées sont importées dans `app.js`
- Les ressources qui ne concernent que quelques pages auront leur propre fichier js déclaré dans `importmap` avec une clef `entrypoint` fixée à true.

## Installation de bibliothèques

```bash
symfony console importmap:require <lib>
```

Cette commande télécharge la bibliothèque `<lib>` dans un sous dossier `vendors` de `assets`. Elle utilise la même source de package que `npm`.

Pourquoi utiliser cette commande plutôt que `npm` ?

- La commande Symfony ajoute automatiquement une entrée dans `importmap.php`.
- Elle place automatiquement les ressources dans un dossier disponible.

**Essayons d’installer `bootstrap` de cette façon**

1. `symfony console importmap:require bootstrap`
2. Dans `app.js` ajouter les imports : 
```javascript 
   import './vendor/bootstrap/dist/css/bootstrap.min.css';
   import 'bootstrap';
````
> Noter que pour le javascript, on utilise la clef déclarée dans `importmap.php` plutôt que le chemin vers le fichier js.
3. Dans `base.html.twig`, copier-coller le code d’une [navbar Bootstrap](https://getbootstrap.com/docs/5.3/components/navbar/)
4. Tester


### Un autre exemple

```
symfony console importmap:require sparticles
```

**app.js**

```javascript
import './styles/app.css';
import './vendor/bootstrap/dist/css/bootstrap.min.css';
import 'bootstrap';
import Sparticles from 'sparticles';

new Sparticles(document.body, { count: 100 }, 400);
```

Ici l’import est stocké dans une variable 

## Gestion des dépendances référencées
Lorsque l’on récupère un nouveau projet, le fichier `importmap.php` se comporte alors, comme le fichier `composer.json`, il référence les dépendances à télécharger avec les commandes suivantes :

Pour la réinstallation des dépendances telles que spécifiées dans `importmap.php`
```
symfony console importmap:install
```

Pour la mise à jour des dépendances vers une éventuelle version plus récente
```
symfony console importmap:update
```
 >Note : On peut ajouter une liste de package en argument de ces deux dernières commandes pour limiter la mise à jour ou l’installation aux seuls packages spécifiés


Pour lister les packages qui ne sont plus à jour
```
symfony console importmap:outdated
```

Pour supprimer un package
```
symfony console importmap:remove <package name>
```

Visualiser toutes les ressources 
```
symfony console debug:asset-map
```

## Exercices

Installer TinyCME dans une page avec AssetMapper

Utiliser AssetMapper pour installer les ressources suivantes :

- picocss
- feather-icons

- Lire la doc
- Utiliser ces ressources dans une nouvelle route avec une nouvelle vue

## Conclusion

AssetMapper offre une simplification par rapport aux empaqueteurs javacript (bundlers).

Il est parfait pour des applications web qui n'ont pas besoin de modifier les ressources.

Pour les applications frontend qui ont un build un peu élaboré (Vue, React, Angular...) il est sans doute préférable de séparer le fontend du backend. Développer deux projets séparés et utiliser les outils proposés par le framework frontend pour empaqueter l'application.

### Conseils d'utilisation

- Utiliser HTTP/2 ou HTTP/3 (config du serveur web)
- Utiliser la compression des réponses HTTP