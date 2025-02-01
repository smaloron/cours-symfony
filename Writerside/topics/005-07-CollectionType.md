# CollectionType

## Objectifs


## Principe

Nous avons vu comment gérer les associations `ManyToOne` dans un formulaire en utilisant soit un `EntityType` soit un formulaire imbriqué. Mais quid des associations `ManyToMany` où une même entité peut accueillir un tableau d'entités associées ?

Pour traiter ce genre de cas Symfony propose un champ de type `CollectionType`.

### Cas d'utilisation

- Une pizza, une recette avec une collection d'ingrédients.
- Un Article possédant une collection de tags.
- Une commande référençant plusieurs produits.


## Mise en place

Imaginons une relation de plusieurs à plusieurs entre une entité post et une entité tag. Lors de la saisie d'un nouveau poste, nous devons pouvoir ajouter des tags. Nous avons vu une solution à ce problème dans le chapitre précédent, nous allons désormais étudier une alternative avec `CollectionType`.

Tout d'abord, nous définissons un formulaire pour les tags.

```php
namespace App\Form;

use App\Entity\Tag;
use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\Extension\Core\Type\ButtonType;
use Symfony\Component\Form\FormBuilderInterface;
use Symfony\Component\OptionsResolver\OptionsResolver;

class TagType extends AbstractType
{
    public function buildForm(
        FormBuilderInterface $builder, 
        array $options
    ): void
    {
        $builder
            ->add('tagName', null, [
                'label' => false,
                'attr' => [
                    'placeholder' => 'Entrez votre tag'
                ]
            ])
            // Ajout d'un bouton pour la suppression
            // la classe delete-tag sera utilisée
            // pour la délégation d'événement
            ->add('delete', ButtonType::class, [
                'label' => 'Supprimer',
                'attr' => [
                    'class' => 'btn btn-danger delete-tag',
                ],
            ]);
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => Tag::class,
            // Ajout d'une classe sur la racine du formulaire
            // pour gérer l'affichage du bouton et du champ texte 
            // côte à côte 
            'attr' => ['class' => 'tag-item'
            ]
        ]);
    }
}
```

Et ensuite, nous modifions le formulaire pour les posts

```php
namespace App\Form;

use App\Entity\Post;
use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\Extension\Core\Type\TextareaType;
use Symfony\Component\Form\Extension\Core\Type\TextType;
use Symfony\Component\Form\FormBuilderInterface;
use Symfony\Component\OptionsResolver\OptionsResolver;
use Symfony\Component\Form\Extension\Core\Type\CollectionType;

class PostType extends AbstractType
{
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

            ->add('tags', CollectionType::class, [
                'entry_type' => TagType::class,
                'allow_add' => true,
                'allow_delete' => true,
                'entry_options' => [
                    // Supprime la légende du prototype
                    'label' => false
                ],

                // Important pour que Doctrine gère bien l'ajout
                'by_reference' => false,
            ]);
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => Post::class,
        ]);
    }
}
```

Un collectionType est donc un moyen pour imbriquer de multiples instances du même formulaire dans un formulaire principal.

Si nous testons la route `/post/form` nous obtenons ce résultat. Il est bien fait mention de tags, mais impossible d'en ajouter.

![CleanShot 2025-02-01 at 13.27.56@2x.png](CleanShot 2025-02-01 at 13.27.56@2x.png)

### Ajout de nouveaux tags

Pour ajouter de nouveau tag, il nous faudrait ajouter au formulaire déjà chargé une nouvelle instance du formulaire tag. Comme cette opération s'effectue après le chargement de la page, c'est donc JavaScript qui va devoir s'occuper d'ajouter le formulaire.

Si nous inspectons la page, nous constatons que nous avons un attribut `data-prototype` qui contient le code html de notre sous formulaire. 

![CleanShot 2025-02-01 at 13.34.25@2x.png](CleanShot 2025-02-01 at 13.34.25@2x.png)

Voici le contenu de `data-prototype` dans un format plus lisible :

```
<fieldset class="mb-3">
    <div id="post_tags___name__">
        <div class="mb-3">
            <input type="text" id="post_tags___name___tagName" 
                name="post[tags][__name__][tagName]" 
                required="required" 
                maxlength="80" 
                placeholder="Entrez votre tag" 
                class="form-control" 
            />
        </div>
    </div>
</fieldset>
```

Et voici ce que nous devons faire avec javascript :

1. Cibler le conteneur des tags, ici `#post-tags` dans une constante `CollectionHolder`.
2. Récupérer l'attribut `data-prototype` de cet élément dans une constante `template`.
3. Définir un attribut `data-index` sur `CollectionHolder` et lui attribuer comme valeur le nombre d'enfants de `CollectionHolder`.
4. Créer un bouton et l'ajouter aux enfants du conteneur `CollectionHolder`.
5. Créer une fonction qui réagit au clic sur ce bouton et fait les choses suivantes :
   - Récupérer la valeur de `data-index`.
   - Remplacer `__name__` dans `template` par `data-index` et stocker le résultat dans une variable `newForm`.
   - Incrémenter `data-index`.
   - Convertir `newForm` en élément HTML.
   - Ajouter cet élément à  `CollectionHolder`.
   - Gérer la suppression des tags (au clic sur le bouton supprimer on supprime le parent du parent du parent).

**La fonction de conversion**

```javascript
/**
 * Conversion d'une chaine de caractères
 * contenant du code HTML
 * en un objet de type HTMLElement
 * @param htmlString
 * @returns {Element}
 */
function createElementFromHTML(htmlString) {
    const div = document.createElement('div');
    div.innerHTML = htmlString.trim();
    
    return div.firstElementChild;
}
```

#### Le code JavaScript {collapsible="true"}
```javascript
{% block javascripts %}
    {{ parent() }}

    <script>

        /**
         * Conversion d'une chaine de caractères
         * contenant du code HTML
         * en un objet de type HTMLElement
         * @param htmlString
         * @returns {Element}
         */
        function createElementFromHTML(htmlString) {
            const div = document.createElement('div');
            div.innerHTML = htmlString.trim();
            
            return div.firstElementChild;
        }

        document.addEventListener('DOMContentLoaded', function () {
            // Ciblage du conteneur des tags
            let collectionHolder = document.querySelector('#post_tags');

            // Définition de l'index de départ
            collectionHolder.setAttribute(
                'data-index',
                collectionHolder.children.length + ''
            );

            // Création du bouton pour ajouter les tags
            let addButton = document.createElement('button');
            addButton.innerText = 'Ajouter un tag';
            addButton.type = 'button';
            addButton.setAttribute('class', 'btn btn-secondary');
            // Prepend pour que le bouton apparaisse avant les tags
            collectionHolder.prepend(addButton);


            // Récupération du modèle du formulaire
            const template = collectionHolder
                .getAttribute('data-prototype');

            // Evénement d'ajout de tag
            addButton.addEventListener('click', function () {
                // Récupération de l'index
                let index = collectionHolder.getAttribute('data-index');
                
                // Préparation du code d'un nouveau tag
                // on remplace __name__ par l'index en cours
                let newForm = template.replace(
                    /__name__/g,
                    index
                );

                // Incrémentation de l'index
                index = parseInt(index) + 1;
                collectionHolder.setAttribute('data-index', index + '');
                
                // Conversion du code du formulaire en élément HTML
                const newFormContainer = createElementFromHTML(newForm)
                
                // Ajout du sous formulaire au parent
                collectionHolder.appendChild(newFormContainer);
                
            });

            // Gestion de la suppression
            collectionHolder.addEventListener('click', function (even){
                if(even.target.classList.contains('delete-tag')){
                    even.target .parentElement
                        .parentElement
                        .parentElement
                        .remove();
                }
            });
        });

    </script>
{% endblock %}
```

## Exercice

Faire de même pour les Pizzas et les Ingrédients