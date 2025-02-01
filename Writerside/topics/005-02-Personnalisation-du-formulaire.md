# Personnalisation du formulaire

## Objectifs

- Forcer le type de champ dans un formulaire
- Identifier quelques attributs optionnels des champs de formulaire

## Le type des champs

Par défaut, Symfony peut inférer le type des champs en fonction du type de données de l'entité liée. Cependant, nous pouvons spécifier un autre type si l'inférence ne correspond pas à nos besoins.

Soit l'entité suivante :

```php
#[ORM\Entity(repositoryClass: CommentRepository::class)]
class Comment
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column]
    private ?\DateTimeImmutable $createdAt = null;

    #[ORM\Column(type: Types::TEXT)]
    private ?string $content = null;

    #[ORM\Column(length: 80)]
    private ?string $author = null;

    // getters et setters
}
```

Et le formulaire suivant

```php
class CommentType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('createdAt', DateType::class)
            ->add('content', TextareaType::class)
            ->add('author', EmailType::class)
        ;
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => Comment::class,
        ]);
    }
}
```
Nous constatons ici qu'en face de chaque champ, nous avons précisé le type attendu. Il ne faut pas oublier d'importer les classes demandées avec un `use` en début de fichier.

Voici la liste des types de champs dans Symfony :

[Liste de types de champs](https://symfony.com/doc/current/reference/forms/types.html)

## Les attributs de champs

La méthode `add` du `FormBuilder` admet en troisième argument optionnel un tableau associatif des attributs du champ.

### Le libéllé du champ

Par défaut, le libellé du champ est le même que le nom de la propriété dans l'entité. Si nous souhaitons changer cela, nous devrons utiliser l'attribut label.

```php
$builder
     ->add('createdAt', DateType::class, [
         'label' => 'Date de création'
     ])
     ->add('content', TextareaType::class, [
         'label' => 'Texte du commentaire'
     ])
     ->add('author', EmailType::class, [
         'label' => 'Adresse email de l\'auteur'
     ])
;
```

### La date sur un seul champ
Par défaut, un champ `DateType` sera transformé dans la vue en une série de listes déroulantes pour choisir le jour le mois et l'année. Si nous souhaitons en avoir qu'un seul champ, en ce cas, il faut ajouter un attribut `widget` avec la valeur `single_text`.

```php
->add('createdAt', DateType::class, [
       'label' => 'Date de création',
       'widget' => 'single_text',
])
```

### Les attributs HTML

Les attributs HTML du champ sont indiqués dans une clef `attr`, qui elle-même, admet en valeur un tableau associatif où les clefs sont les noms des attributs.

```php
->add('content', TextareaType::class, [
      'label' => 'Texte du commentaire',
      'attr' => ['rows' => 10]
])
->add('Valider', SubmitType::class, [
       'label' => 'Valider le commentaire',
       'attr' => ['class' => 'btn btn-success']
])
```

### Sécurisation de la saisie

Pour éviter les attaques XSS, il est bon de nettoyer la saisie, afin d'éliminer toute balise qui pourrait poser problème. Nous pouvons faire cela individuellement, champ par champ, mais également définir cette option sur l'ensemble du formulaire.

Il faut tout d'abord installer une bibliothèque supplémentaire comme ceci.

```
composer require symfony/html-sanitizer
```

#### Sécurisation d'un champ

```php
->add('content', TextareaType::class, [
    'label' => 'Texte du commentaire',
    'attr' => ['rows' => 10],
    'sanitize_html' => true,
])
```

#### Sécurisation de l'ensemble des champs d'un formulaire

```php
public function configureOptions(
   OptionsResolver $resolver
): void
{
    $resolver->setDefaults([
        'sanitize_html' => true,
    ]);
}
```

#### Sécurisation dans les vues

```twig
{{ comment.content|sanitize_html }}
```

### Champs non liés
Parfois, nous souhaitons afficher des champs qui n'on pas vocation à être persistés, ni même stockés dans une entité. Par exemple, une case à cocher indiquant que le visiteur accepte les conditions générales de vente lors d'une commande.

```php
->add('cgv', CheckboxType::class, [
    'mapped' => false,
    'label' => "J'accepte les conditions générales de vente"
])
```

### Obligation de saisie

L'attribut `required` possède une valeur booléenne qui indique si la saisie est requise ou facultative. Ce contrôle de validité est effectué côté client. 

```php
->add('content', TextareaType::class, [
    'label' => 'Texte du commentaire',
    'attr' => ['rows' => 10],
    'sanitize_html' => true,
    'required' => true
])
```




