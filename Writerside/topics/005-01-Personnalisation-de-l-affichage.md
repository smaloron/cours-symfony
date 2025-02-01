# Personnalisation de l'affichage

## Objectifs

- Identifier les options d'affichage des formulaires
- Styler les formulaires

## Les fonctions Twig

Les fonctions Twig gèrent l'affichage du formulaire dans une vue.

| fonction                        | description                                                                               |
|---------------------------------|-------------------------------------------------------------------------------------------|
| `{{ form }}`                    | affiche tout le formulaire                                                                |
| `{{ form_start  }}`             | génère la balise `<form>` avec les différents attributs                                   |
| `{{ form_end }}`                | génère la fermeture de `<form>` avec les différents champs restants non affichés          |
| `{{ form_errors }}`             | affiche les erreurs éventuelles du formulaire                                             |
| `{{ form_widget(form.field) }}` | affiche le champs                                                                         |
| `{{ form_label(form.field) }}`  | affiche le label du champs                                                                |
| `{{ form_row(form.field) }}`    | affiche le form_widget et form_label                                                      |
| `{{ form_rest }}`               | affiche les champs restants non récupéré précédemment (token de vérification par exemple) |

### Exemple

Soit le formulaire suivant :

```php
<?php

namespace App\Form;

use App\Entity\Address;
use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\Extension\Core\Type\SubmitType;
use Symfony\Component\Form\FormBuilderInterface;
use Symfony\Component\OptionsResolver\OptionsResolver;

class AddressType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('city')
            ->add('zipCode')
            ->add('street')
            ->add('Valider', SubmitType::class)
        ;
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => Address::class,
        ]);
    }
}
```

et le contrôleur suivant :

```php
<?php

namespace App\Controller;

use App\Entity\Address;
use App\Form\AddressType;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class AddressController extends AbstractController
{
    #[Route('/address/form', name: 'address_form')]
    public function addEdit(): Response
    {
        $address = new Address();

        $form = $this->createForm(AddressType::class, $address);


        return $this->render('address/form.html.twig', [
            'addressForm' => $form->createView(),
        ]);
    }
}
```

Imaginons que nous souhaitions obtenir le résultat ci-dessous. Dans ce cas, il nous faut afficher chaque champ de formulaire individuellement.

![CleanShot 2025-01-23 at 13.18.47@2x.png](CleanShot 2025-01-23 at 13.18.47@2x.png)

Voici la vue

```twig
{% extends 'base.html.twig' %}

{% block title %}Gestion des adresses{% endblock %}

{% block stylesheets %}
    <style>
        body {
            padding: 20px;
        }
        .two-rows {
            display: grid;
            grid-template-columns: 1fr 1fr;
            margin-top: 10px;
            margin-bottom: 20px;
            gap: 10px;
        }

        label {
            display: block !important;
            margin-bottom: 5px;
        }

        input {
            width: 100%;
        }

        button {
            width: 100%;
        }
    </style>
{% endblock %}

{% block body %}

    {{ form_start(addressForm) }}


        {{ form_row(addressForm.street) }}


        <div class="two-rows">
            {{ form_row(addressForm.city) }}
            {{ form_row(addressForm.zipCode) }}
        </div>

    {{ form_end(addressForm) }}

{% endblock %}
```

> notons que le champ correspondant au bouton "valider", qui est absent du code de notre vue, est tout de même affiché. Lorsqu'il manque des champs Twig les ajoute automatiquement à la fin du formulaire.

## Utiliser Bootstrap

Plutôt que de gérer nous-mêmes la mise en forme des formulaires, nous pouvons utiliser Bootstrap. Symfony intègre cette bibliothèque et nous n'avons qu'à indiquer que nous voulons styler les formulaires avec Bootstrap.

Dans le fichier `config/packages/twig.yaml` nous ajoutons un thème pour nos formulaires

```yaml
twig:
    form_themes:
        - 'bootstrap_5_layout.html.twig'
```

![CleanShot 2025-01-23 at 13.32.14@2x.png](CleanShot 2025-01-23 at 13.32.14@2x.png)
 
## Créer un thème personnalisé

### Créer le fichier du thème

Il s'agit d'un fichier `Twig` que nous plaçons par convention dans le dossier `templates/form`. Nous le nommerons `custom_form_theme.html.twig`.

Ce fichier viendra surcharger le thème par défaut fournit pas `Twig`.

### Surcharge des blocs

Ici, nous surchargeons le modèle utilisé par la fonction `form_row`.

```twig
{% block form_row %}
    <div class="two-rows">
        {{ form_label(form) }}
        <div>
            {{ form_widget(form) }}
            {{ form_errors(form) }}
        </div>
    </div>
{% endblock %}
```
Il est également possible de surcharger les modèles suivants :

- form_widget
- form_errors
- form_label
- form_help

### Appliquer le thème

#### Application globale

Comme nous avons pu le faire pour Bootstrap, nous modifions le fchier `config/packages/twig.yaml`.

```yaml
twig:
    form_themes:
        - 'bootstrap_5_layout.html.twig'
        - 'form/custom_form_theme.html.twig'
```

#### Application locale

En passant un tableau d'options en troisième argument de la méthode `render`. Attention la clef `form_theme` attend un tableau de thèmes, même s'il n'y en a qu'un.

```php

return $this->render(
    'address/form.html.twig', 
     ['addressForm' => $form->createView()],
     [
        'form_theme' => 
        ['form/custom_form_theme.html.twig']
     ]
 );
```

![CleanShot 2025-01-23 at 14.36.43@2x.png](CleanShot 2025-01-23 at 14.36.43@2x.png)

> Nous pouvons désormais placer le code `CSS` dans `assets/styles/app.css` de sorte qu'il soit disponible pour toutes les pages.


 
