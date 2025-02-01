# Champs de formulaire avancés

## Objectifs
 
- Identifier les options pour gérer la saisie ou le choix d'une entité liée dans un formulaire.
- Mettre en place un sous formulaire obligatoire ou facultatif.

## RepeatedType

Ce type de champ présente deux contrôles pour obtenir confirmation de la saisie. Si les données des deux champs ne correspondent pas, le formulaire est invalide.

```php
$builder->add('email', RepeatedType::class, [
    'type' => EmailType::class,
    'invalid_message' => 'l'adresse email et sa confimation sont différentes.',
    'options' => ['attr' => ['class' => 'password-field']],
    'required' => true,
    'first_options'  => ['label' => 'email'],
    'second_options' => ['label' => 'confirmation email'],
]);
```

La clef `options` définit les options communes aux deux champs

## EntityType

Dans le cas d'une association, la valeur retournée n'est pas scalaire, c'est une instance d'entité. Il faut alors utiliser un `EntityType` qui offrira à l'utilisateur le choix, parmi une liste d'entités.

```php
class ArticleType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('title')
            ->add('content')
            ->add('category', EntityType::class, [
                'class' => Category::class,
                'choice_label' => 'categoryName',
            ])
            ->add('author', EntityType::class, [
                'class' => Person::class,
                'choice_label' => 'fullName',
            ])
        ;
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => Article::class,
        ]);
    }
}
```

Ici l'attribut `choice_label` indique la propriété de l'entité qui sera utilisée comme libéllé dans la liste des options.

Dans le cas de l'auteur, la propriété `fullName` n'existe pas, mais il existe une méthode `getFullName` qui sera à l'heure utilisée.

En l'absence d'attributs, `choice_label`, c'est la méthode magique `__toString` qui servira pour récupérer le libellé. Si cette méthode n'est pas implémentée, alors nous obtiendrons une erreur, car Symfony sera incapable de convertir notre entité en chaîne de caractère.

### Quelques options

#### Attribut `expanded`
Booléen, false par défaut.
Affiche les options sous la forme d'une liste de case à cocher ou boutons radio (en fonction de la valeur de l'attribut `multiple`)

#### Attribut `multiple`
Booléen, false par défaut.
Permet la sélection de plusieurs entités. Cela se traduira par un `select` multiple si l'attribut `expanded` est `false` ou par une liste de boutons radio dans le cas inverse.

#### Attribut `placeholder`
Définit le texte de la première option de la liste déroulante

#### Attribut `query_builder`
Définit une fonction qui retourne un `QueryBuilder`chargé de requêter sur l'entité pour hydrater le champ. Cet attribut est utile lorsque nous souhaitons n'afficher qu'une parties des données de l'entité ou bien changer l'ordre d'affichage.


```php
->add('category', EntityType::class, [
    'class' => Category::class,
    'choice_label' => 'categoryName',
    // 'expanded' => true,
    'placeholder' => 'Veuillez sélectionner une catégorie',
    'query_builder' => function (CategoryRepository $repo) {
        return $repo->createQueryBuilder('c')
                    ->orderBy('c.categoryName', 'ASC');
    },
])
```

## Sous formulaire

Symfony permet d'insérer un formulaire dans un autre. Pour cela il suffit d'utiliser le sous formulaire comme un type de champ dans le formulaire principal. Nous comprenons désormais pourquoi, par convention, les noms des classes formulaires se terminent par type.

Cette méthode est utile lorsque l'entité principale possède une association `ManyToOne` ou  `OneToOne` avec une autre entité.
Cela se traduit par la présence d'une instance de l'entité liée au sein de l'entité propriétaire de l'association. Nous pouvons donc afficher un seul formulaire pour saisir les données de l'entité. Liée.

```php
class PersonFormType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('firstName', TextType::class, ['label' => 'Prénom'])
            ->add('lastName', TextType::class, ['label' => 'Nom'])

            ->add('address', AddressType::class, [
                'label' => '<h3>Adresse</h3>',
                'label_html' => true,
            ])

            ->add('Valider', SubmitType::class)
        ;
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => Person::class,
        ]);
    }
}
```

![CleanShot 2025-01-25 at 08.21.39@2x.png](CleanShot 2025-01-25 at 08.21.39@2x.png)

### Afficher dynamiquement le sous formulaire

Nous pouvons ajouter un peu de javascript pour afficher ou masquer les formulaires dont la saisie est facultative.


**La classe du formulaire**

```php
$builder
   ->add('firstName', TextType::class, ['label' => 'Prénom'])
   ->add('lastName', TextType::class, ['label' => 'Nom'])


   // Case à cocher pour afficher le formulaire
   ->add('showAddressForm', CheckboxType::class, [
       'label' => 'Afficher le formulaire d\'adresse',
       'mapped' => false,
       'required' => false,
       // Identifiant de la case à cocher
       'attr' => ['id' => 'show-address-form'],
       
       // Valeur par défaut
       'value' => false,
   ])

   // Sous formulaire caché par défaut
   ->add('address', AddressType::class, [
       // Libéllé du sous formulaire
       'label' => '<h3>Adresse</h3>',
       'label_html' => true,
       
       // Le formulaire doit être facultatif
       'required' => false,
       
       'row_attr' => [
           // identifiant du sous formulaire
           'id'=>'address-form',
           // Formulaire masqué par défaut
           'style' => 'display: none'
       ],
   ])

   ->add('Valider', SubmitType::class)
;
```

**Le code Javascript dans la vue**

```javascript
{% block javascripts %}

    {# 
       Récupération du contenu du parent pour 
       que AssetMapper fonctionne toujours  
    #}
    {{ parent() }}

    <script>
        document.addEventListener(
        'DOMContentLoaded', 
        () => {
            const checkbox = document.querySelector('#person_form_showAddressForm');
            const dynamicFormContainer = document.querySelector('#address-form');

            function showHideAddressForm() {
                dynamicFormContainer.style.display = checkbox.checked ? 'block' : 'none';
            }

            checkbox.addEventListener(
                'change', 
                () => showHideAddressForm()
            );

            showHideAddressForm()
        });
    </script>

{% endblock %}
```

