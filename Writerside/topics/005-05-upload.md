# Upload : le téléversement de fichiers

## Objectifs

- Mettre en place le téléversement de fichiers
- Valider les fichiers téléversés


## Principe

### Mise en place

Tout d'abord, il faut créer le dossier qui va recevoir les fichiers. Il est ensuite conseiller de définir le chemin vers ce fichier dans un paramètre de façon à pouvoir le récupérer à différents endroits de notre code.

```bash
mkdir public/uploads
```

```yaml
parameters:
    upload_dir: '%kernel.project_dir%/public/uploads'
```

Il nous faudra également installer le composant suivant pour que Symfony soit capable de lire le mime type des fichiers.

```bash
composer require symfony/mime
```

### L'entité

Il faut ajouter une nouvelle propriété pous stocker le nom de l'image dans l'entité.

```bash
symfony console make:entity Ingredient
```

- name : photoFileName
- type : string
- size : 255
- nullable : yes

```bash
symfony console make:migration
```

```bash
symfony console doctrine:migrations:migrate
```

### Le formulaire

Nous souhaitons ajouter une photo aux ingrédients des pizzas. 

Pour ce faire, nous ajoutons un champ `FileType` qui ne sera pas lié à une propriété.

Sur ce champ, nous plaçons une contrainte de type `File` afin de limiter le type et la taille du fichier. Nous en profitons pour ajouter nos propres messages d'erreur. 

> Note : l'objet `File` que l'on doit utiliser est le suivant :
> `Symfony\Component\Validator\Constraints\File`

> Concernant la limite de taille de fichier, il peut y en avoir trois :
> - dans la contrainte `maxSize`
> - dans le fichier php.ini du serveur (upload_max_filesize)
> - dans le formulaire HTML (attribut MAX_FILE_SIZE)

```php
class IngredientType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('label', TextType::class, ['label' => 'Nom'])
            ->add('price', MoneyType::class, ['label' => 'prix'])
            ->add('image', FileType::class, [
                'label' => 'Photo du produit',
                'mapped' => false,
                'required' => false,
                'constraints' => [
                    new File([
                        'maxSize' => '2M',
                        'mimeTypes' => [
                            'image/jpeg',
                            'image/png'
                        ],
                        'mimeTypesMessage' => 'seuls les fichiers {{ types }} sont autorisés',
                        'maxSizeMessage' => 'Le fichier est trop volumineux {{ limit }} {{ suffix }} maximum.',
                        'notReadableMessage' => 'Le fichier n\'est pas accessible en lecture.',
                        'uploadIniSizeErrorMessage' => 'Le fichier est trop volumineux.',
                        'uploadFormSizeErrorMessage' => 'Le fichier est trop volumineux.',
                        'uploadErrorMessage' => 'Erreur dans le téléversement du fichier.'
                    ]),
                ]
            ])
        ;
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => Ingredient::class,
        ]);
    }
}
```

### Le contrôleur

Pour traiter le formulaire, il faut d'abord récupérer le choix du fichier. Nous obtenons ici un objet de classe UploadedFile. Si un fichier a été télétransmis, nous devons ensuite définir non unique pour ce fichier. Enfin nos déplaçons le fichier télétransmis dans son dossier de destination en le renommant avec le nom unique que nous avons défini.

Tout ceci est très similaire à ce que nous avons fait avec PHP. Symfony cependant nous offre une assistance pour la détermination par exemple de l'extension du fichier en fonction du type de ce fichier.

```php
<?php

namespace App\Controller;

use App\Entity\Ingredient;
use App\Form\IngredientType;
use App\Repository\IngredientRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\Form\Extension\Core\Type\SubmitType;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/ingredient', name: 'app_ingredient')]
final class IngredientController extends AbstractController
{
    #[Route('/', name: '_index')]
    public function index(
        IngredientRepository $repository,
    ): Response
    {

        return $this->render('ingredient/index.html.twig', [
            'ingredientList' => $repository->findAll(),
        ]);
    }

    #[Route('/form', name: '_form')]
    public function form(
        Request $request,
        EntityManagerInterface $entityManager,
    ): Response
    {
        $ingredient = new Ingredient();

        $form = $this->createForm(IngredientType::class, $ingredient);
        $form->add('Valider', SubmitType::class, []);

        $form->handleRequest($request);

        if($form->isSubmitted() && $form->isValid()){
            // récupération du fichier
            $uploadedFile = $form->get('image')->getData();

            if($uploadedFile){
                // Définition d'un nom unique
                $newFilename = uniqid('ingredient-', true) . '.' . $uploadedFile->guessExtension();

                // Déplacement du fichier
                $uploadDir = $this->getParameter('upload_dir');
                $uploadedFile->move($uploadDir, $newFilename);

                // Persistance de l'entité
                $ingredient->setPhotoFileName($newFilename);
                $entityManager->persist($ingredient);
                $entityManager->flush();

                return $this->redirectToRoute('app_ingredient_index');
            }

        }

        return $this->render('ingredient/form.html.twig', [
            'ingredientForm' => $form->createView(),
        ]);
    }
}
```

**La vue index**

```twig
{% extends 'base.html.twig' %}

{% block title %}Hello IngredientController!{% endblock %}

{% block body %}

    {% for ingredient in ingredientList %}
        <div>
            <h3>{{ ingredient.label }}</h3>
            {% if ingredient.photoFileName %}
                <img src="/uploads/{{ ingredient.photoFileName }}" alt="Photo"
                style="width: 300px">
            {% endif %}
        </div>
    {% endfor %}

{% endblock %}
```