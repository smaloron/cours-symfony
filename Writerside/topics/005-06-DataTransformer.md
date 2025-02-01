# DataTransformer

## Objectifs

- Identifier le rôle des DataTransformer.
- Étudier des exemples de cas d'utilisation.

## Principe

Les DataTransformers dans Symfony sont des classes qui permettent de convertir des données d'un format à un autre, notamment entre :

- Le modèle (données utilisées par l’application, souvent des objets)
- Le formulaire (valeurs affichées et soumises par l’utilisateur)

- Ils sont souvent utilisés pour des formulaires qui nécessitent un format spécifique pour l'affichage ou l'enregistrement.

Symfony utilise déjà des transformateurs en interne pour convertir certaines valeurs comme les entités dans un EntityType ou les valeurs booléennes.

### Fonctionnement 

Un `DataTransformer` est une classe qui implémente `DataTransformerInterface`, cette interface expose deux méthodes :

- `transform` pour gérer le passage du modèle au formulaire.
- `reverseTransform` pour gérer le passage du formulaire au modèle.

## Exemple, conversion de prix en centimes

Les applications de gestion et de comptabilité stockent souvent les valeurs monétaires en centimes dans une colonne de type `integer`. Cela évite les problèmes de précision causés par les calculs sur des nombres à virgule flottante.

Cependant, nous n'allons pas demander aux utilisateurs de notre application de saisir les montants en centimes.

```php
namespace App\Form\DataTransformer;

use Symfony\Component\Form\DataTransformerInterface;

class PriceToCentsTransformer implements DataTransformerInterface
{
    public function transform(mixed $value): ?float
    {

        return (float) number_format($value / 100, 2, '.', '');
    }

    public function reverseTransform(mixed $value): ?int
    {
        if (!$value) {
            return null;
        }
        $price = (float)str_replace(',', '.', $value);
        return (int) ($price * 100);
    }
}
```

### Conversion du prix dans un formulaire

Nous injectons le `DataTransformer` et utilisons la méthode `addModelTransformer` pour lier cette classe à un champ du formulaire. 

```php
use App\Form\DataTransformer\PriceTransformer;
use Symfony\Component\Form\FormBuilderInterface;
use Symfony\Component\Form\Extension\Core\Type\MoneyType;

class ProductType extends AbstractType
{
    public function __construct(
        private PriceToCentsTransformer $priceTransformer
    ){}

    public function buildForm(
        FormBuilderInterface $builder, 
        array $options
    )
    {
        $builder->add('price', MoneyType::class);
        $builder->get('price')
                ->addModelTransformer(
                    $this->priceTransformer
                );
    }
}
```

## Un autre exemple plus complexe

Imaginons une entité Post qui stocke un `ArrayCollection` d'entités Tag au sein d'une association `ManyToMany`.

Le formulaire propose la saisie sous la forme d'un champ texte ou les tags sont séparés par une virgule.

A l'affichage du formulaire, il faut donc Convertir l'objet `ArrayCollection` en une chaine de caractères.

Au traitement du formulaire les opérations sont plus compliquées, car il faut :

- Convertir la chaîne de caractère en tableau ordinal
- Dédupliquer le tableau (pour éviter les tags en double) et éliminer les espaces aux extrémités des tags (trim).
- Vérifier si chaque tag existe dans la base de données et le créer s'il n'existe pas.
- Retourner un objet ArrayCollection qui pourra être persisté.

### Le code {collapsible="true"}

#### Le DataTransformer

```php
// src/Form\DataTransformer/TagsTransformer.php

namespace App\Form\DataTransformer;

use App\Entity\Tag;
use App\Repository\TagRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Form\DataTransformerInterface;
use Symfony\Component\Form\Exception\TransformationFailedException;
use Doctrine\Common\Collections\Collection;

class TagsTransformer implements DataTransformerInterface
{
    

    public function __construct(
        private EntityManagerInterface $entityManager,
        private TagRepository $tagRepository
    ) {}

    /**
     * Transforme une collection de Tag en une chaîne de texte.
     * Ex: Collection[Tag("Symfony"), Tag("API")] → "Symfony, API"
     */
    public function transform(mixed $tags): string
    {
        if (!$tags instanceof Collection) {
            return '';
        }

        // La méthode toArray transforme
        // un ArrayCollection en un tableau ordinal
        return implode(
            ', ',
            $tags->map(
                fn(Tag $tag) => $tag->getTagName()
            )->toArray()
        );
    }

    /**
     * Transforme une chaîne de tags en une collection d'objets Tag.
     * Ex: "Symfony, API" → Collection[Tag("Symfony"), Tag("API")]
     */
    public function reverseTransform(mixed $value): Collection
    {
        if (!$value) {
            return new ArrayCollection();
        }

        // Conversion de la chaine en tableau,
        // nettoyage de la saisie
        // et déduplication
        $tagNames = array_unique(
            //array_filter(
                array_map(
                    'trim',
                    explode(',', $value)
                )
            //)
        );
        
        // Recherche de tous les tags existants
        $existingTags = $this->tagRepository
                             ->findBy(['tagName' => $tagNames]);
        
        // Transformation de la collection d'entités 
        // en un tableau ordinal de chaînes de caractère
        $existingTagNames = array_map(
            fn(Tag $tag) => $tag->getTagName(), $existingTags
        );

        // Création des nouveaux tags
        $newTags = [];
        foreach ($tagNames as $tagName) {
            // Si le tag n'existe pas,
            // il est créé et persisté
            if (!in_array(
                $tagName, 
                $existingTagNames, true)
            ) {
                $tag = new Tag();
                $tag->setTagName($tagName);
                $this->entityManager->persist($tag);
                $newTags[] = $tag;
            }
        }

        // Fusion des deux tableaux de tags
        $tags = array_merge($existingTags, $newTags);
        
        // Conversion en ArrayCollection
        return new ArrayCollection($tags);
    }
}
```
#### Le formulaire

```php
// src/Form/PostType.php

namespace App\Form;

use App\Entity\Post;
use App\Entity\Tag;
use App\Form\DataTransformer\TagsTransformer;
use Symfony\Bridge\Doctrine\Form\Type\EntityType;
use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\Extension\Core\Type\TextareaType;
use Symfony\Component\Form\Extension\Core\Type\TextType;
use Symfony\Component\Form\FormBuilderInterface;
use Symfony\Component\OptionsResolver\OptionsResolver;

class PostType extends AbstractType
{
    public function __construct(
        private TagsTransformer $tagsTransformer,
    ) {}

    public function buildForm(
        FormBuilderInterface $builder, 
        array $options
    ): void
    {
        $builder
            ->add('createdAt', null, [
                'widget' => 'single_text',
            ])
            ->add('title', TextType::class, [])
            ->add('content', TextareaType::class, [])
            ->add('tags', TextType::class, [
                'attr' => [
                    'placeholder' => 'Entrez les tags, séparés par une virgule'
                ],
                'required' => false,
            ]);

        $builder->get('tags')
                ->addModelTransformer($this->tagsTransformer);
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => Post::class,
        ]);
    }
}
```


