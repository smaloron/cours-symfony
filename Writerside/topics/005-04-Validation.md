# Validation

## Objectifs

- Mettre en place la validation de saisie sur une entité.
- Identifier les règles de validation les plus courantes.

## Principe

### Installation

```
composer require symfony/validator
```

### Définition des contraintes de validation 

Le système de validation peut fonctionner avec n'importe quelle classe, cependant il est principalement utilisé pour valider les données d'une entité.

Il faut importer la classe `Symfony\Component\Validator\Constraints` qui est traditionnellement renommée `Assert`.

```php
use Symfony\Component\Validator\Constraints as Assert;
```

Ensuite, nous pouvons établir des règles de validation en utilisant les attributs PHP au-dessus des propriétés ou méthode de notre classe.

Les règles de validation admettent en option le message d'erreur. 

D'autres options sont disponibles en fonction de la contrainte de validation. Par exemple pour `Length` nous devons spécifier la taille minimale et maximale.  

```php
#[ORM\Column(length: 50)]

#[Assert\NotBlank(message: 'Le nom ne peut être vide.')]
#[Assert\Length(min: 2, max: 50,
    minMessage: 'Le nom doit comporter plus de {{limit}} caractères',
    maxMessage: 'Le nom doit comporter moins de {{limit}} caractères'
)]
private ?string $lastName = null;
```

### Quelques règles de validation

Symfony propose 

[Liste complète des contraintes](https://symfony.com/doc/current/validation.html)

Blank
: Valide qu'une valeur est vide (chaîne vide ou `null`).
: [doc](https://symfony.com/doc/current/reference/constraints/Blank.html)

NotBlank
: Valide qu'une valeur n'est pas est vide.
: [doc](https://symfony.com/doc/current/reference/constraints/NotBlank.html)

IsTrue
: Valide qu'une valeur est 'true'. Étant donné que l'on peut valider des méthodes, nous pourrions n'utiliser que cette contrainte et effectuer l'ensemble des tests dans une fonction retournant un booléen. Ce faisant, nous perdrions toutefois la granularité des messages d'erreurs.
: [doc](https://symfony.com/doc/current/reference/constraints/IsTrue.html)

IsFalse
: Valide qu'une valeur est `false`.
: [doc](https://symfony.com/doc/current/reference/constraints/IsFalse.html)

Type
: Valide qu'une valeur est d'un type donné.
: [doc](https://symfony.com/doc/current/reference/constraints/Type.html)

Regex
: Valide qu'une valeur correspond à une expression régulière.
[doc](https://symfony.com/doc/current/reference/constraints/Regex.html)

Count
: Valide d'une collection contient un nombre minimum et/ou maximum d'éléments.
[doc](https://symfony.com/doc/current/reference/constraints/Count.html)

## Utilisation

### Validation des formulaires

Si le formulaire est basé sur une entité, alors les règles de validation définies dans cette dernière seront automatiquement testées lors de l'hydratation du formulaire avec la méthode `handleRequest`.

En cas d'erreur, le formulaire sera invalide et l'ensemble des messages d'erreur pourront être affichés dans la vue.

![CleanShot 2025-01-26 at 11.00.07@2x.png](CleanShot 2025-01-26 at 11.00.07@2x.png)

### Validation manuelle

Le système de validation peut être utilisé pour valider n'importe quelles données. Il est donc tout à fait possible d'utiliser la validation en dehors d'un formulaire. Nous en avons ici un exemple.

```php
use Symfony\Component\Validator\Validation;

$validator = Validation::createValidator();
$user = new Person();
$user->setLastName('J'); // Invalide

// Instanciation du validateur
$violations = $validator->validate($user);

$errors = [];

if (count($violations) > 0) {
    foreach ($violations as $violation) {
        $errors[] = $violation->getMessage();
    }
}
```

### Validation des champs non liés

Il est fortement conseillé de définir les règles de validation au niveau des entités. En effet cela permet de centraliser la validation et d'éviter d'avoir à répéter ses règles à différents endroits. 

Il est des cas, assez rare, où nous éprouverons le besoin de valider un champ qui n'a pas vocation à être stocké dans l'entité. 

Dans l'exemple suivant nous avons une case à cocher qui confirme que l'utilisateur accepte les conditions générales de vente. Il y a peu d'intérêt à stocker cette variable au sein de notre entité.

```php
$builder
    ->add('terms', CheckboxType::class, [
        'label' => "J'accepte les CGV",
        'mapped' => false, // non lié à l'entité
        'required' => true,
        'constraints' => [
            new Assert\IsTrue([
                'message' => 'Vous devez accepter les CGV.',
            ]),
        ],
    ])
```