# Routes et contrôleurs

## Objectif
L’objectif de ce document est de comprendre le fonctionnement du routing dans Symfony afin de créer des réponses que l’on puisse appeler depuis un navigateur Web.


## Un peu d’histoire
Dans une application Web classique l’adresse de chaque page correspond à un fichier sur le serveur. Un peu comme si le serveur Web était votre disque dur et que vous naviguiez dans cette arborescence.

Cette façon de faire très populaire au début des années 2000 n’a plus vraiment cours actuellement. Quasiment tous les projets adoptent désormais un système de routage qui vise à découpler l’adresse Web et la ressource vers laquelle elle pointe. C’est bien entendu ce que propose Symfony.

![001-routing-http-classique.svg](001-routing-http-classique.png)

## Le principe du routing
Le routing ou aiguillage en français consiste à faire correspondre une adresse (que l’on appelle une route) avec une ressource. Les deux éléments ne sont toutefois pas intrinsèquement liés, en connaissant l’adresse, on ne peut inférer la ressource sans passer par une table de correspondances.

On peut faire une analogie avec un annuaire téléphonique. Rien dans le nom d’une personne ne me permet de deviner son numéro. Il me faut consulter l’annuaire (la table de correspondance) pour obtenir l’information désirée.

Avec Symfony, le routing fait donc correspondre une adresse (la partie de l’URL après le nom du serveur) avec une méthode d’une classe. On appelle ce type de classe un contrôleur (le C du pattern MVC).

### Le contrôleur
Un contrôleur Symfony est juste une classe qui possède au moins une méthode retournant une réponse HTTP.

```php
<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\Response;

class HomeController
{
    /**
     * Une route simple sans paramètres
     * @return Response
     */
    final public function index(): Response{
        return new Response("Hello Symfony");
    }
}
```

Il faut désormais ajouter les informations de routing pour établir la correspondance entre la méthode `index`du contrôleur et une adresse qui sera tapée das le navigateur Web.

Symfony propose plusieurs façons de définir cette correspondance, concentrons-nous sur la plus populaire.

Il s’agit d’ajouter des informations à la méthode par le biais des attributs de PHP8.

```php
<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class HomeController
{
    /**
     * Une route simple sans paramètres
     * @return Response
     */
     #[Route('/hello')]
    final public function index(): Response{
        return new Response("Hello Symfony");
    }
}
```

Ici deux choses ont changé :

- Import de la classe `Symfony\Component\Routing\Attribute\Route;`
- Ajout d’un attribut PHP8 avec l’appel de la fonction Route au-dessus de la méthode `index`qui fait correspondre l’adresse passée en argument avec la méthode de la classe.

## Utilisation de la requête

Avez-vous remarqué que parfois les adresses Web se terminent par une suite d’informations qui ressemblent à ceci ?

```
http://monserveur.com/contact?id=7
```

La partie après le `?`correspond à des paramètres passés à la route. Un peu comme les arguments d’une fonction. On appelle cette dernière partie de l’URL la chaîne de requête ou query string.

Pour exploiter ce type d’information, il faut importer une nouvelle classe, l’objet Request.

Ensuite en argument de la méthode, il faut ajouter l’objet Request. C’est Symfony qui se chargera d’exécuter la méthode et d’ajouter une instance de cet objet. Toutefois, pour qu’il sache quelle classe instancier il faut quand même lui préciser le type de la variable `$request`.

Enfin, la méthode `get`de l’objet `Request`permet de récupérer la valeur d’un paramètre du query string.


```php
<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\HttpFoundation\Request;

class HomeController
{
    /**
     * Cette route admet en argument la Requête HTTP,
     * cela permet de récupérer des données passées dans l'URL
     * L'objet Request de Symfony simplifie cette récupération 
     * en proposant une méthode get
     * qui interroge tout ce qui est récupérable 
     * dans la requête HTTP
     *
     * @param Request $request
     * @return Response
     *
     * exemple : /bonjour?name=Alice
     */
    #[Route('/bonjour')]
    final public function bonjour(Request $request): Response{
        // L'opérateur ?? définit une valeur par défaut 
        // si la méthode get retourne null
        $name = $request->get("name") ?? "inconnu";
        return new Response("Bonjour $name");
    }
}
```

## Les paramètres
En plus du query string, Symfony, propose une autre méthode pour passer des paramètres à une route. Cette dernière consiste à définir que la partie finale de la route correspondra aux valeurs des paramètres que nous souhaitons passer à la fonction.

On obtient donc ceci :

```
/hello/Pierre
```

Au lieu de cela :

```
/hello?name=Pierre
```

Pour définir un paramètre, il faut le déclarer à la fois dans la route et dans les arguments de la fonction. Mais attention le nom du paramètre doit être identique à ces deux endroits.

```php
    /**
     * Cette route possède un paramètre passé dans l'url 
     * (en dehors du querystring)
     * Remarquez que le nom du paramètre 
     * doit correspondre au nom de l'argument 
     * passé à la fonction (ici name et $name)
     *
     * @param string $name
     * @return Response
     */
    #[Route('/hello/{name}')]
    final public function hello(string $name): Response{
        return new Response("Hello $name");
    }
```

### Valeur par défaut

Pour définir une valeur par défaut, il suffit de l’indiquer dans la signature de la fonction.

```php
    /**
     * Cette route possède un paramètre passé dans l'url 
     * (en dehors du querystring)
     * Remarquez que le nom du paramètre 
     * doit correspondre au nom de l'argument 
     * passé à la fonction (ici name et $name)
     *
     * @param string $name
     * @return Response
     */
    #[Route('/hello/{name}')]
    final public function hello(string $name = ''): Response{
        return new Response("Hello $name");
    }
```

### Paramètres ou querystring
Les deux techniques produisent le même effet. On peut donc se poser la question de la pertinence d’utiliser l’une ou l’autre.

Les paramètres produisent des URL plus propres et explicites, dans la plupart des cas, on les préférera au query string.

Le query string peut être intéressant lorsque l’information qu’il donne est facultative, par exemple pour indiquer le numéro de la page en cours dans un affichage paginé ou bien un ordre de tri ou encore un filtre. Bref, dans les cas où les informations supplémentaires ne sont pas indispensables au bon fonctionnement de la route.

```php
<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\HttpFoundation\Request;

class HomeController
{
    /**
     * @param Request $request
     * @return Response
     *
     * exemple : 
     * /liste
     * /liste?page=5
     */
    #[Route('/liste')]
    final public function bonjour(Request $request): Response{
        $page = $request->get("page") ?? 1;
        return new Response("Vous êtes sur la page $page");
    }
}
```

### Contraindre les paramètres
Les paramètres possèdent un avantage supplémentaire par rapport au query string, il est possible de contraindre la valeur d’un paramètre. En fait, nous avons même deux méthodes pour définir cette contrainte. La première méthode consiste tout simplement à typer l’argument de la fonction. La seconde consiste à définir une expression régulière dans les attributs PHP8 par le biais du tableau`requirements`.

#### Typage

Ici le paramètre `$id`doit être un entier. Si tel n’est pas le cas, on obtient une erreur de typage.

```php
    /**
     * @param string $name
     * @return Response
     */
    #[Route('/details/{id}')]
    final public function hello(int $id = ''): Response{
        return new Response("Vous êtes sur la fiche $id");
    }
```

### Requirements

Ici, le paramètre `id`doit correspondre à l’expression régulière `\d+`(uniquement des chiffres). Si tel n’est pas le cas, la route n’est pas valide et le routeur passe à la route suivante pour tenter de résoudre le routing.

```php
    /**
     * @param string $name
     * @return Response
     */
    #[Route('/details/{id}', requirements: ['id'=>'\d+'])]
    final public function hello($id = ''): Response{
        return new Response("Vous êtes sur la fiche $id");
    }
```

Depuis Symfony 6.2 on dispose d'une suite d'expressions régulière prédéfinies dans l'énumération de la classe Requirement.

```php
    /**
     * @param string $name
     * @return Response
     */
    #[Route('/details/{id}', requirements: ['id'=>Requirement::DIGITS])]
    final public function hello($id = ''): Response{
        return new Response("Vous êtes sur la fiche $id");
    }
```

## Préfixage des routes
Si l’ensemble des routes dans le même contrôleur partage, certaines caractéristiques, on peut alors définir ces éléments communs dans un attribut PHP8 placé au-dessus de la classe. On évite ainsi d’avoir à ressaisir ces informations autant de fois qu’il y a de routes dans la classe.

Ici, les routes finales sont constituées de la combinaison de la route, de la classe et de celle de la méthode.

```
/home/hello
/home/details/{id}
/home/liste
```

```php
<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\HttpFoundation\Request;

#[Route('/home')]
class HomeController
{

    #[Route('/hello/{name}')]
    final public function hello(string $name = ''): Response{
        return new Response("Hello $name");
    }
    
    #[Route('/details/{id}')]
    final public function hello(int $id = ''): Response{
        return new Response("Vous êtes sur la fiche $id");
    }
    
    #[Route('/liste')]
    final public function bonjour(Request $request): Response{
        $page = $request->get("page") ?? 1;
        return new Response("Vous êtes sur la page $page");
    }
}
```

## Liste des routes
C’est vraiment très pratique d’avoir la définition de la route. Juste à côté de la fonction que cette route va invoquer. Cependant, on a parfois envie de lister l’ensemble des routes de notre application. Pour cela Symfony nous propose une commande console.

```
symfony console debug:router --show-controllers
```

```shell
  Name               Method   Scheme   Host   Path                       Controller                                
 ------------------ -------- -------- ------ -------------------------- ------------------------------------------ 
  _preview_error     ANY      ANY      ANY    /_error/{code}.{_format}   error_controller::preview()               
  app_home_index     ANY      ANY      ANY    /home                      App\Controller\HomeController::index()    
  app_home_bonjour   ANY      ANY      ANY    /bonjour                   App\Controller\HomeController::bonjour()  
  app_home_hello     ANY      ANY      ANY    /hello/{name}              App\Controller\HomeController::hello()    
  app_home_add       ANY      ANY      ANY    /add/{n1}/{n2}             App\Controller\HomeController::add()      
 ------------------ -------- -------- ------ -------------------------- ------------------------------------------ 
```

On peut constater deux choses :

- L’ordre des routes suit celui de la création des contrôleurs et des méthodes
- Les routes possèdent un nom automatiquement attribué par Symfony

### Changer le nom d’une route
C’est très simple, il suffit d’ajouter une clef `name`

```php

    #[Route('/hello/{name}', name: 'hello')]
    final public function hello(string $name = ''): Response{
        return new Response("Hello $name");
    }

```

Relancer la commande console pour constater le changement.

### Changer l’ordre des routes
L’ordre des routes est important, car c’est dans cet ordre que le routeur de Symfony va analyser chaque route pour s’arrêter à la première qui correspond à l’URL. Voilà pourquoi il est conseillé de définir les routes les plus spécifiques en premier.

On peut forcer l’ordre des routes en ajoutant une clef Priority dans les attributs PHP8. La valeur de cette clef est un entier et les règles sont les suivantes :

- Les routes sont ordonnées par ordre décroissant de priorité (la plus haute en premier).
- Les routes qui n’ont pas de priorité sont classées après celles qui en ont une.

```php
<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\HttpFoundation\Request;

#[Route('/home')]
class HomeController
{

    #[Route('/hello/{name}')]
    final public function hello(string $name = ''): Response{
        return new Response("Hello $name");
    }
    
    #[Route('/details/{id}', priority: 1)]
    final public function hello(int $id = ''): Response{
        return new Response("Vous êtes sur la fiche $id");
    }
    
    #[Route('/liste', priority: 2)]
    final public function bonjour(Request $request): Response{
        $page = $request->get("page") ?? 1;
        return new Response("Vous êtes sur la page $page");
    }
}
```




## Exercices

<procedure>
    <step>
        Créer un contrôleur `CalcController` avec un préfixe `/calcul` 
    </step>
    <step>
        Créer une route `/addition/{n1}/{n2}` qui admet deux arguments et affiche l’addition de ces deux éléments.
    </step>
    <step>
        Créer une route `/soustraction/{n1}/{n2}` qui admet deux arguments et affiche la soustraction de ces deux éléments.
    </step>
    <step>
        Créer une route `/{n1}/puissance/{n2}` qui admet deux arguments et affiche l’élément n1 élevé à la puissance n2.
    </step>
    <step>
        Placer la route `puissance` en premier et tester toutes les routes sans `requirements`, que constatez-vous ?
    </step>
    <step>
        Ajouter des `requirements` sur les paramètres et tester à nouveau
    </step>
</procedure>











