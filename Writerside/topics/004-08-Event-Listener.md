# Event Listener

## Objectifs


## Principe

Les événements du cycle de vie des entités (lifecycleEvents) ont l'avantage de la simplicité, mais ils ne sont pas sans limites.

- Les entités ne peuvent recevoir de dépendances injectées (voir les exclusions dans `services.yml`).
- Si la logique métier doit être partagée par plusieurs entités, les `lifecycleEvents` ne permettent pas la factorisation.

Dans ces deux cas, quand la logique métier devient complexe et/ou qu'elle doit être partagée, nous aurons recours aux `Doctrine Event Listeners`.

Les `Doctrine Event Listeners` sont des classes qui écoutent des événements déclenchés par Doctrine ORM. Ces événements peuvent être liés à des actions comme la création, la mise à jour ou la suppression d'entités.

### Comment ça marche

1. Déclaration d'un `Event Listener` : Création d'une classe qui écoute un ou plusieurs événements de Doctrine. Cette classe est taggée avec l'attribut suivant. <br /> `#[AsTaggedItem('doctrine.event_listener')]`

2. Définition des événements auxquels la classe `Listener` réagira. Chaque événement doit correspondre à une méthode de la classe. L'attribut est le suivant. <br /> `#[AsDoctrineListener(event: 'prePersist')]` 

3. Doctrine déclenche automatiquement les événements.

Les noms des événements sont les mêmes que pour les `lifecycleEvents` :

- PrePersist et PostPersist
- PreUpdate et PostUpdate
- PreRemove et PostRemove
- PostLoad
- PreFlush

Les `Doctrine Event Listeners` se déclenchent sur toute opération sur les entités, il faudra donc récupérer le contexte de l'événement et tester si l'entité à l'origine de l'événement est bien celle qui nous intéresse.

### Un exemple simple

Cet écouteur d'événement définit la date de création avant la persistance d'une entité POST.

```php
namespace App\EventListener\Doctrine;

use App\Entity\Post;
use Doctrine\Bundle\DoctrineBundle\Attribute\AsDoctrineListener;
use Doctrine\Persistence\Event\LifecycleEventArgs;
use Symfony\Component\DependencyInjection\Attribute\AsTaggedItem;

#[AsDoctrineListener(event: 'prePersist')]
#[AsTaggedItem('doctrine.event_listener')]
class TimeStampEventListener
{

    public function prePersist(
        LifecycleEventArgs $args
    ): void
    {
        // Récupération de l'entité source de l'événement
        $entity = $args->getObject();

        // Filtre sur le contexte 
        if ($entity instanceof POST) {
            $entity->setCreatedAt(new \DateTimeImmutable());
        }
    }
}
```

## Cas d'utilisation : génération de slugs

Ici, nous avons besoin d'une dépendance `SluggerInterface` pour générer un slug à la persistance de l'entité Article.

Commençons par créer une nouvelle propriété

```
symfony console make:entity Article
```

Ajoutons une propriété slug : string : 120 : not nullable

Avant de migrer, il faut vider la table

```
symfony console doctrine:query:sql "TRUNCATE TABLE \"article\" "
```

```
symfony console make:migration
```

```
symfony console doctrine:migrations:migrate
```

Et enfin la classe

```php
namespace App\EventListener\Doctrine;

use App\Entity\Article;
use Doctrine\ORM\Event\LifecycleEventArgs;
use Symfony\Component\String\Slugger\SluggerInterface;
use Symfony\Component\DependencyInjection\Attribute\AsTaggedItem;
use Doctrine\Bundle\DoctrineBundle\Attribute\AsDoctrineListener;

#[AsDoctrineListener(event: 'prePersist', priority: 100)]
#[AsDoctrineListener(event: 'preUpdate', priority: 100)]
#[AsTaggedItem('doctrine.event_listener')]
class ArticleSlugListener
{
    public function __construct(
        private SluggerInterface $slugger
    ){}

    public function prePersist(LifecycleEventArgs $args): void
    {
        $entity = $args->getObject();
        if ($entity instanceof Article) {
            $this->setSlug($entity);
        }
    }

    public function preUpdate(LifecycleEventArgs $args): void
    {
        $entity = $args->getObject();
        if ($entity instanceof Article) {
            $this->setSlug($entity);
        }
    }

    private function setSlug(Article $article): void
    {
        if (!$article->getSlug()) {
            $slug = $this->slugger->slug(
                        $article->getTitle()
                    )->lower();
                         
            $article->setSlug($slug);
        }
    }
}
```



## Conclusions

- Le comportement est découplé des contrôleurs
- L'événement aura lieu lors de toute persistence, que celle-ci provienne d'une action de contrôleur ou de l'exécution de fixtures.