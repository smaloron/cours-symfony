# La classe Repository

## Objectifs

- Identifier le rôle de la classe `Repository`.
- Utiliser les méthodes de `ServiceEntityRepository` pour effectuer des requêtes simples.

## Principes
Chaque entité peut être liée à une classe `Repository` qui hérite de 
`ServiceEntityRepository`. Cette classe centralise les requêtes personnalisées sur cette entité.

`ServiceEntityRepository` fournit un ensemble de méthodes qui couvrent les besoins standards. 

## Les méthodes de `ServiceEntityRepository`

### Obtenir toutes les entités

La méthode `findAll` permet d'obtenir un tableau ordinal de toutes les entités persistées en base de données. Cette méthode très simple, n'admet aucun argument.

Si l'entité possède des associations, il sera possible d'obtenir également les données des entités liées.

**Le contrôleur**
```php
final class ArticleController extends AbstractController
{
    #[Route('/article', name: 'app_article')]
    public function index(ArticleRepository $repository): Response
    {
        $articles = $repository->findAll();
        
        return $this->render(
            'article/index.html.twig', 
            ['article-list' => $articles,]
        );
    }
}
```

**La vue**

```twig
{% extends 'base.html.twig' %}

{% block title %}Liste des articles{% endblock %}

{% block body %}
    
    <h1>Liste des articles</h1>
    <table>
        <thead>
            <tr>
                <th>Titre</th>
                <th>Catégorie</th>
            </tr>
        </thead>
        <tbody>
            {% for article in articleList %}
                <tr>
                    <td>{{ article.title }}</td>
                    <td>{{ article.category.categoryName }}</td>
                </tr>
            {% endfor %}
        </tbody>
    </table>
    
{% endblock %}
```

Nous constatons dans le profiler que Doctrine a effectué une requête pour récupérer les articles et autant de requêtes qu'il y avait deux catégories à récupérer.

![CleanShot 2025-01-23 at 08.14.31@2x.png](CleanShot 2025-01-23 at 08.14.31@2x.png)

### Obtenir une seule entité

Pour obtenir une seule entité en fonction de son identifiant, nous avons la méthode `find` qui admet en argument l'id recherchée.

> bien entendu. Dans cet exemple, il y a une solution plus simple que nous connaissons déjà et qui consiste à passer l'entité en argument de la méthode du contrôleur. Grâce aux composants `ParamConverter` Symfony sera capable de récupérer l'entité à partir de l'id passé dans la route.

**Le contrôleur**

```php
#[Route('/article/{id}', name: 'app_article_details')]
    public function show(
        ArticleRepository $repository,
        int $id): Response
    {
        $article = $repository->find($id);

        return $this->render(
            'article/details.html.twig',
            ['article' => $article,]
        );
    }
```

**La vue**

```twig
{% extends 'base.html.twig' %}

{% block title %}Détails d'un article{% endblock %}

{% block body %}

    <h1>Détails d'un article</h1>

    {{ dump(article) }}

{% endblock %}
```

**Un lien sur la vue index**

```twig
{% extends 'base.html.twig' %}

{% block title %}Liste des articles{% endblock %}

{% block body %}

    <h1>Liste des articles</h1>
    <table>
        <thead>
            <tr>
                <th>Titre</th>
                <th>Catégorie</th>
            </tr>
        </thead>
        <tbody>
            {% for article in articleList %}
                <tr>
                    <td>
                        <a href="{{ path('article_show', {'id': article.id}) }}">
                            {{ article.title }}
                        </a>
                    </td>
                    <td>{{ article.category.categoryName }}</td>
                </tr>
            {% endfor %}
        </tbody>
    </table>

{% endblock %}
```

### Recherche sur critères

Pour rechercher des entités selon un critère, nous disposons de deux méthodes `findBy` et `findOneBy`. La première retourne un tableau d'entité. La seconde ne retourne qu'une seule entité. Ces deux méthodes admettent en argument, un tableau associatif, représentant les critères et un second tableau facultatif représentant la clause `ORDER BY`.

```php
#[Route('/article-by-category/{categoryId}', 
        name: 'app_article_search_by_category')]
    public function searchByCategory(
        ArticleRepository $repository,
        int $categoryId
    ): Response
    {
        $articles = $repository->findBy(
            ['category' => $categoryId],
            ['title' => 'DESC']
        );

        return $this->render(
            'article/index.html.twig',
            ['articleList' => $articles,]
        );
    }
```

### Exercice

- Dans le contrôleur `index` récupérer l'ensemble des catégories et les passer à la vue
- Dans la vue `index`, afficher toutes les catégories et faites un lien vers la route `app_article_search_by_category`
- Afficher le nombre d'articles en face de chaque catégorie


## Les limites de ces méthodes simples

On ne peut requêter que sur les informations de l'entité principale. Dans notre exemple, on ne peut directement requêter sur `category.categoryName`.

Pour aller plus loin, il nous faudra utiliser la classe `QueryBuilder` qui est intégrée au `repository` des entités.




