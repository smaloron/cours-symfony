# Profilage et automatisation

## Objectifs
L’objectif de ce document est d’identifier en quoi Symfony peut rendre le développement plus facile.

## La génération de code
Symfony propose un outil de génération de code qui facilite grandement le développement.

### Installation

```
composer require maker --dev
```

L’option `--dev` indique que la dépendance ne sera pas téléchargée lors du déploiement dans un environnement de production. Il est inutile en effet de rendre disponible la génération de code dans ce contexte.

### Creation d'un contrôleur

```
symfony console make:controler
```

Génère un fichier contrôleur avec une méthode, une route et même un modèle Twig. C'est assez simple, mais cela fait quand même gagner du temps et nous verrons plus tard que la génération de code peut aller bien plus loin.

## Les outils de profilage et de debug

On installe ces outils avec la commande suivante :
```
composer require debug
```

> Note : Il ne faut pas ici utiliser l'option `--dev` car un des composants (monolog) est utile en mode production. Les autres seront automatiquement placés dans les dépendances de développement.

### La debug bar
L'effet immédiatement visible de cette installation consiste en l'apparition d'une barre en bas de nos écrans. Cette debugbar contient de nombreuses informations utiles sur le contexte d'exécution de notre application.


![004-debugbar.png](004-debugbar.png)

Encore mieux !
En cliquant sur la barre, nous ouvrons une page qui regroupe des informations plus amples et précises.

![004-debug-details.png](004-debug-details.png)

Le menu "performance" regroupe des informations sur la consommation de mémoire et surtout un graphique indiquant le temps d'exécution de chaque composant ayant participé au traitement de la requête. Avec un tel outil, repérer les goulets d'étranglement devient bien plus facile.

![004-debug-profiler.png](004-debug-profiler.png)

### Dump

Pour corriger les erreurs, il est essentiel de pouvoir afficher la valeur de nos variables. PHP propose pour cela une fonction `var_dump`.

#### Un  exemple

```php
#[Route('/recette')]
    public function index(): Response
    {
        // dump de la liste des recettes
        var_dump($this->getRecipeList());

        return $this->render("recipe/list.html.twig", [
            "recipeList" => $this->getRecipeList(),
            "pageTitle" => "Liste de toutes les recettes"
        ]);
    }
```

Ce qui donne ceci dans le navigateur web :

![CleanShot_2024-03-28_at_10.50.25@2x.png](CleanShot_2024-03-28_at_10.50.25@2x.png)

#### Un meilleur dump avec Symfony
Plutôt que `var_dump`, si nous utilisons la fonction `dump` de Symfony, nous obtenons un affichage plus lisible. Les données sont regroupées dans la debug bar et ne polluent plus l'affichage de notre page. 


```php
#[Route('/recette')]
    public function index(): Response
    {
        // dump de la liste des recettes avec la fonction de Symfony
        dump($this->getRecipeList());

        return $this->render("recipe/list.html.twig", [
            "recipeList" => $this->getRecipeList(),
            "pageTitle" => "Liste de toutes les recettes"
        ]);
    }
```


![CleanShot_2024-03-28_at_10.53.53@2x.png](CleanShot_2024-03-28_at_10.53.53@2x.png)

#### Dump dans Twig
Nous pouvons également obtenir la même information intégrée dans Twig avec la même fonction.

```html
{% extends 'base.html.twig' %}

{% block body %}

    <h1>{{ pageTitle }}</h1>

    {# fonction dump dans Twig #}
    {{ dump(recipeList) }}

    <ul>
        {% for recipe in recipeList %}
            <li>
                <a href="{{ path('app_recipe_details', {'id': recipe.id}) }}">
                {{ recipe.title }}
                </a>
                ( <a href="{{ path('app_recipe_bykind', {'kind': recipe.kind}) }}">
                    {{ recipe.kind }}
                </a> )
                - {{ recipe.ingredients | length }} ingrédients
            </li>
        {% endfor %}
    </ul>

{% endblock %}

{% block title %}
```

![CleanShot_2024-03-28_at_10.58.34@2x.png](CleanShot_2024-03-28_at_10.58.34@2x.png)

### Les logs
Les logs sont des fichiers texte qui capturent les événements du cycle de vie de notre application. 

```
[2024-03-28T10:04:03.165367+00:00] request.INFO: Matched route "app_recipe_index". {"route":"app_recipe_index","route_parameters":{"_route":"app_recipe_index","_controller":"App\\Controller\\RecipeController::index"},"request_uri":"http://localhost:8000/recette","method":"GET"} []
[2024-03-28T10:04:03.168125+00:00] app.INFO: Affichage de la liste des recettes [] []
```


