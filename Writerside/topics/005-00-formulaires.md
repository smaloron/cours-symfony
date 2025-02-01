# Formulaires

## Objectifs

- Construire des formulaires avec Symfony
- Afficher les formulaires
- Traiter des formulaires
- Réaliser un CRUD sur une entité simple

## Principes

Symfony propose un composant de gestion des formulaires qu'il faut installer.

```
composer require symfony/form
```

### Création d'une classe formulaire

Les formulaires en Symfony sont souvent basés sur une entité qui sera persistée lors du traitement du formulaire.

Pour créer la classe formulaire, nous utiliserons `Maker`.

```
symfony console make:form
```

Cette commande nous demande deux informations.

- Le nom de la classe, formulaire.
- Éventuellement le nom de l'entité associée aux formulaires.

> Traditionnellement dans Symfony, les noms des classes de formulaire se terminent par `Type`.

Voici un exemple de formulaire créé avec la commande maker à partir de l'entité `Category`.

```php
class ArticleCategoryType extends AbstractType
{
    public function buildForm(
        FormBuilderInterface $builder, 
        array $options
    ): void
    {
        $builder
            ->add('cateroryName')
        ;
    }

    public function configureOptions(
            OptionsResolver $resolver
    ): void
    {
        $resolver->setDefaults([
            'data_class' => Category::class,
        ]);
    }
}
```

### Utilisation du formulaire dans un contrôleur

La méthode `createForm` de `AbstractController` retourne un formulaire, elle admet trois arguments :

- La classe du formulaire.
- L'entité éventuelle auquel le formulaire est lié.
- Un tableau d'options (facultatif)

Cet objet form est ensuite passé à la vue pour être affiché. Attention ici, il ne faut pas oublier d'exécuter la méthode `createView`.

```php
final class ArticleCategoryController extends AbstractController
{
    #[Route('/category/form', name: 'app_article_category_new')]
    public function index(): Response
    {
        $category = new Category();
        $form = $this->createForm(
           ArticleCategoryType::class,
           $category,
        );

        
        return $this->render(
            'article_category/form.html.twig', 
            ['categoryForm' => $form->createView()]
        );
    }
}
```

### Affichage du formulaire dans Twig

Pour afficher le formulaire dans la vue, nous utiliserons la fonction `form` de Twig en lui passant le `formView` généré dans le contrôleur.

```php
{% extends 'base.html.twig' %}

{% block title %}Catégories{% endblock %}

{% block body %}
<div style="padding: 20px">
  {{ form(categoryForm) }}
</div>
{% endblock %}
```

![CleanShot 2025-01-22 at 20.12.30@2x.png](CleanShot 2025-01-22 at 20.12.30@2x.png)

Ici, nous constatons qu'il manque le bouton `submit`, il faudra donc valider avec la touche ENTER.

### Traitement du formulaire

Pour traiter le formulaire, nous avons besoin de la requête. Nous injectant donc un objet Request dans l'action du contrôleur.

Ensuite, nous utilisons la méthode `handleRequest` de l'objet `form` en passant la requête en paramètre.

Cette méthode va hydrater le formulaire avec les données de la requête. Étant donné qu'ici l'entité est liée au formulaire, celle-ci sera également hydratée.

Dans le même temps. Les éventuels contrôlent de validation sont effectués sur le formulaire et nous pouvons donc tester si la saisie est valide avant de persister l'entité.

> Attention, l'objet `Request` attentdu et de type `Symfony\Component\HttpFoundation\Request`

Il nous reste ensuite plus qu'à utiliser `EntityManager` pour persister l'entité et enfin à faire une redirection afin d'éviter de reposter les données.

> Si le formulaire n'est pas lié à une entité, nous pouvons récupérer les données postées avec `$form->getData()` 

```php
    #[Route('/category/form', name: 'app_article_category_form')]
    public function index(Request $request, EntityManagerInterface $manager): Response
    {
        $category = new Category();
        $form = $this->createForm(
           ArticleCategoryType::class,
           $category,
        );

        $form->handleRequest($request);

        if($form->isSubmitted() && $form->isValid()){
            $manager->persist($category);
            $manager->flush();
            return $this->redirectToRoute('app_article_category_form');
        }

        return $this->render(
            'article_category/index.html.twig', 
            ['categoryForm' => $form->createView(),]
        );
    }
```

### Affichage du bouton submit

Nous avons deux choix pour ajouter un élément au formulaire

#### Dans la vue

```twig
{% extends 'base.html.twig' %}

{% block title %}Hello ArticleCategoryController!{% endblock %}

{% block body %}
<div style="padding: 20px">
    
    {# Début du formulaire #}
    {{ form_start(categoryForm) }}
    
        {# Affichage de tous les champs #}
        {{ form_widget(categoryForm) }}
    
        <button type="submit" value="Submit">
            Valider
        </button>
    
    {# Fin du formulaire #}
    {{ form_end(categoryForm) }}
    
</div>
{% endblock %}
```

#### Dans la classe formulaire

```php
public function buildForm(
    FormBuilderInterface $builder, 
    array $options
): void
    {
        $builder
            ->add('cateroryName')
            ->add('Valider', SubmitType::class)
        ;
    }
```

### Modification

La seule chose à faire pour réaliser une modification et de transmettre une entité hydratée plutôt qu'une nouvelle entité. Le reste des opérations étant totalement similaires à l'insertion, nous allons utiliser le même contrôleur afin d'éviter de recopier du code.


Nous aurons donc une fonction qui sera liée à deux routes. 

L'entité pourra ainsi être nulle ce qui est indiqué par le ? devant le nom de l'entité dans la signature de la méthode. Et nous lui donnons une valeur par défaut pour éviter une erreur lorsque la route est appelée sans ce paramètre.

Dans le corps de la méthode, il convient de tester la valeur de l'entité pour savoir s'il convient de l'instancier ou si elle est déjà hydratée.

Enfin, nous constatons que lorsque nous créons un formulaire à partir d'une entité hydratée, ce formulaire affiche automatiquement les données de l'entité.

```php
    #[Route('/category/form', name: 'app_article_category_form')]
    #[Route('/category/form/{id}', name: 'app_article_category_form_edit')]
    public function addEdit(
        Request $request,
        EntityManagerInterface $manager,
        ?Category $category = null
    ): Response
    {

        if(!$category) $category = new Category();

        $form = $this->createForm(
           ArticleCategoryType::class,
           $category,
        );

        $form->handleRequest($request);

        if($form->isSubmitted() && $form->isValid()){
            $manager->persist($category);
            $manager->flush();
            return $this->redirectToRoute('app_article_category_form');
        }
        
        return $this->render('article_category/index.html.twig', [
            'categoryForm' => $form->createView(),
        ]);
    }
```

### Affichage des catégories

Pour compléter le code, il faut désormais afficher la liste des catégories.

Pour ce faire, nous utiliserons le `Repository`, afin de faire une requête et de transmettre le résultat à la vue.

```php
    #[Route('/category/form', name: 'app_article_category_form')]
    #[Route('/category/form/{id}', name: 'app_article_category_form_edit')]
    public function addEdit(
        Request $request,
        EntityManagerInterface $manager,
        CategoryRepository $repository,
        ?Category $category = null
    ): Response
    {

        if(!$category) $category = new Category();

        $form = $this->createForm(
           ArticleCategoryType::class,
           $category,
        );

        // Récupération de la liste des catégories
        $categories = $repository->findAll();

        $form->handleRequest($request);

        if($form->isSubmitted() && $form->isValid()){
            $manager->persist($category);
            $manager->flush();
            return $this->redirectToRoute('app_article_category_form');
        }

        return $this->render('article_category/index.html.twig', [
            'categoryForm' => $form->createView(),
            'categoryList' => $categories,
        ]);
    }
```

Voici la vue avec un peu de style

```twig
{% extends 'base.html.twig' %}

{% block title %}Gestion des catégories{% endblock %}

{% block stylesheets %}
    <style>
        body {
            padding: 20px;
        }

        .margin-top-20 {
            margin-top: 20px;
        }

        .category-item {
            display: grid;
            grid-template-columns: 3fr minmax(100px, 1fr);
            grid-gap: 10px;
            width: 50%;
            min-width: 300px;
            max-width: 500px;
            padding: 5px;
        }

        .even {
            background-color: #acacac;
        }

        .odd {
            background-color: #a6ccff;
        }
    </style>
{% endblock %}

{% block body %}

    <h1>Gestion des catégories</h1>

    <div class="margin-top-20">
        {{ form(categoryForm) }}
    </div>

    <h2 class="margin-top-20">Categories</h2>
    
    {% for category in categoryList %}
        <div class="category-item 
        {{ loop.index is even? 'even': 'odd' }}">
            <div>
                {{ category.cateroryName }}
            </div>
            <div>supprimer</div>
        </div>
    {% endfor %}

{% endblock %}
```

### La suppression
Pour supprimer une catégorie, il nous faudra une nouvelle route dans laquelle nous transmettrons l'identifiant de la catégorie à supprimer. Il faudra également créer un lien dans la vue vers cette nouvelle route.

#### La route
```php
#[Route('/category/delete/{id}', 
        name: 'app_article_category_delete')]
    public function delete(
        Category $category, 
        EntityManagerInterface $manager): Response
   {
        $manager->remove($category);
        $manager->flush();
        
        return $this->redirectToRoute(
            'app_article_category_form'
        );
    }
```

### La vue

Notons que la fonction `path` de Twig, admet en argument le nom de la route vers laquelle on va faire un lien et éventuellement les arguments passés à cette route.

```twig
<a href="{{ path('app_article_category_delete', 
         {id: category.id}) }}">
    Supprimer
</a>
```


## Exercice

Faire un crud sur l'entité `Ingredient`.









