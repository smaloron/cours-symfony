# Twig factorisation

## Objectif
L’objectif de ce document est de recenser les solutions de factorisation proposées par Twig, de les mettre en pratique afin d’évaluer leur intérêt dans le cadre d’un usage professionnel.

## Inclusions
Twig permet l'inclusion du code d'un modèle dans un autre modèle. Cette fonction, à l'instar de l'include de PHP réalise un copier-coller au niveau du serveur avant l'interprétation des expressions entre moustaches et l'envoi de la réponse au client. Cela implique que les données disponibles pour le parent le sont également pour le modèle enfant.  
Cette inclusion permet d'extraire des parties d'interfaces graphiques récurrentes et évite ainsi de répéter du code de page en page au risque de rendre la maintenance plus fastidieuse.

Par exemple, une barre de navigation qui doit apparaitre sur chaque page devrait être extraite dans un fichier séparé.

Par convention, nous commencerons le nom des fichiers Twig, qui ne représentent qu'une page partielle par un caractère "_". Nous enregistrerons également ces fichiers dans un dossier séparé nommé `fragments`

#### Exemple d'inclusion


`fragments/_nav.html.twig`

```html
<nav>
    <ul>
        <li>
            <a href="{{ path('twig_grocery_list') }}">Liste de courses</a>
        </li>

        <li>
            <a href="{{ path('twig_book_list') }}">Ma bibliothèque</a>
        </li>

        <li>
            <a href="{{ path('twig_team') }}">Mon équipe</a>
        </li>

        <li>
            <a href="{{ path('twig_hello', {'age': '25', 'name': 'Alex'}) }}">hello</a>
        </li>
    </ul>
</nav>
```

`books.html.twig`

```html
<!doctype html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Premier modèle Twig</title>
</head>
<body>

{{ include('fragments/_nav.html.twig') }}

<h1>Ma bibliothèque</h1>
<table>
    <thead>
        <tr>
            <th>Titre</th>
            <th>Auteur</th>
        </tr>
    </thead>
    {% for book in bookList %}
        <tr>
            <td>{{ book.title }}</td>
            <td>{{ book.author }}</td>
        </tr>
    {% endfor %}
</table>
</body>
</html>
```

### Passage de paramètres
L'inclusion hérite du contexte de son parent, mais nous pouvons passer des paramètres supplémentaires en argument de la fonction include.

Le code ci-dessous passe à la barre de navigation une information sur la page parente. Cette donnée est ensuite utilisée pour changer l'apparence du lien pointant vers la page en-cours.

`fragments/_nav.html.twig`

```html
<nav>
    <ul>
        <li class="{{ activePage == 'grocery'?'active':''}}">
            <a href="{{ path('twig_grocery_list') }}">Liste de courses</a>
        </li>

        <li class="{{ activePage == 'books'?'active':''}}">
            <a href="{{ path('twig_book_list') }}">Ma bibliothèque</a>
        </li>

        <li class="{{ activePage == 'team'?'active':''}}">
            <a href="{{ path('twig_team') }}">Mon équipe</a>
        </li>

        <li class="{{ activePage == 'hello'?'active':''}}">
            <a href="{{ path('twig_hello', {'age': '25', 'name': 'Alex'}) }}">hello</a>
        </li>
    </ul>
</nav>
```

`books.html.twig`

```html
<!doctype html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Premier modèle Twig</title>
</head>
<body>

{{ include('fragments/_nav.html.twig', { activePage: 'books'}) }}

<h1>Ma bibliothèque</h1>
<table>
    <thead>
        <tr>
            <th>Titre</th>
            <th>Auteur</th>
        </tr>
    </thead>
    {% for book in bookList %}
        <tr>
            <td>{{ book.title }}</td>
            <td>{{ book.author }}</td>
        </tr>
    {% endfor %}
</table>
</body>
</html>
```

## L'héritage des modèles
Pour aller encore plus loin dans la factorisation, et l'élimination de la redondance, Twig propose un système d'héritage des modèles. Le principe est similaire à ce que l'on trouve dans la programmation orientée objet. Un modèle parent que nous pourrons appeler gabarit, propose un contenu dont ses enfants hériteront. Pour garantir la souplesse du système, les enfants peuvent surcharger le contenu du parent.

Il est également possible un enfant d'être lui-même parent d'un modèle.

Au cœur de ce système se trouve le principe des blocs. Ce sont des régions modifiables, déclarées dans le code du modèle parent, et éventuellement surchargées dans le code du modèle enfant.

### Exemple

#### Le parent
``base.html.twig``

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>{% block title %}Welcome!{% endblock %}</title>
    <link rel="icon"
          href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 128 128%22><text y=%221.2em%22 font-size=%2296%22>⚫️</text><text y=%221.3em%22 x=%220.2em%22 font-size=%2276%22 fill=%22%23fff%22>sf</text></svg>">
    
    {% block stylesheets %}
    <link href="
https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css
" rel="stylesheet">
    {% endblock %}

    {% block javascripts %}
    <script src="
    https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.min.js
    "></script>
    {% endblock %}
</head>
<body class="container-fluid p-4">
{% block body %}{% endblock %}
</body>
</html>
```

#### Un enfant

```html
{% extends 'base.html.twig' %}

{% block body %}
    {{ include('fragments/_nav.html.twig', {activePage: 'books'}) }}
    <h1>Ma bibliothèque</h1>
    <table>
        <thead>
            <tr>
                <th>Titre</th>
                <th>Auteur</th>
            </tr>
        </thead>
        {% for book in bookList %}
            <tr>
                <td>{{ book.title }}</td>
                <td>{{ book.author }}</td>
            </tr>
        {% endfor %}
    </table>
{% endblock %}
```

Ici l’enfant redéfinit le contenu du bloc body

> Attention : Le tag {% extends %} doit être la première ligne du fichier et à partir du moment où un modèle hérite d’un autre, il ne peut contenir de code en dehors de la portée d’un bloc.

L’intérêt de l’héritage, c’est que nous allons pouvoir définir dans le gabarit parent, l’ensemble des éléments qui sont répétés sur la majorité des pages de notre application. Pour les cas particuliers, nous pouvons toujours surcharger les blocs et ainsi proposer un contenu différent de celui de la plupart des pages de notre application. Il faut ici arbitrer entre la souplesse et la simplicité. Si nous souhaitons un maximum de souplesse alors, il nous faudra définir de nombreux blocs. Si on revanche, nous voulons simplifier notre travail, il vaudra mieux limiter le nombre de ces blocs.

Comme souvent, lorsqu’il est question de factorisation, le plus grand bénéfice, apparaît lorsque nous devons faire la maintenance de l’application. C’est à ce moment-là que la duplication du code provoque frustration et risque d’erreur.

## Surcharge et héritage
Parfois, nous souhaitons conserver le code du parent et y ajouter celui de l’enfant. Twig a prévu ce cas et propose une fonction `parent` qui insère ce code du bloc du parent.

```html
{% block javascript %}
    {{ parent() }}
    <script>
        alert('page enfant')
    </script>
{% endblock %}
```

## Héritage et gestion des chemins
Imaginons que nous souhaitions ranger nos modèles Twig dans des dossiers, par exemple un dossier par contrôleur. Nous aurions donc une arborescence ressemblant à ceci.

```
templates
    base.html.twig
    product
        index.html.twig
        details.html.twig       
```

À l’intérieur du dossier `product`, le chemin utilisé dans le bloc `extends` ne sera pas un chemin relatif, nous aurons donc ceci.

```
{% extends 'base.html.twig' %}
```

La résolution du chemin s’effectue donc toujours par rapport à une racine immuable, le dossier `templates`.

Si par exemple, nous avons l’arborescence suivante :

```
templates
    layout
        base.html.twig
    product
        index.html.twig
        details.html.twig       
```

Le chemin vers le parent sera le suivant :

```
{% extends 'layout/base.html.twig' %}
```


