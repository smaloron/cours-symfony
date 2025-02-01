# Le cycle de vie des entités

## Objectifs

- Identifier le rôle des `LifecycleCallbacks`
- Capturer les événements du cycle de vie

## LifecycleCallbacks

Doctrine propose un système d’évènements qui permet d’interagir à chaque étape du cycle de vie des entités. Voici les principaux évènements disponibles.

PrePersist 
: Avant qu’une entité soit persistée dans la base de données.
: Utile pour initialiser des valeurs ou effectuer une validation.

PostPersist 
: Après qu’une entité a été persistée.
: Utile pour des actions nécessitant que l'entité ait déjà un identifiant (ex. : journalisation, notifications).

PreUpdate 
: Avant qu’une entité soit mise à jour.
: Utile pour modifier des champs calculés ou mettre à jour des métadonnées avant la sauvegarde.

PostUpdate 
: Après qu’une entité a été mise à jour.
: Utile pour effectuer des actions après que les données ont été enregistrées (ex. : mise en cache, journalisation).

PreRemove 
: Avant qu’une entité soit supprimée.
: Utile pour effectuer des validations ou sauvegarder des données avant suppression.

PostRemove 
: Après qu’une entité a été supprimée.
: Utile pour effectuer des actions comme la suppression de fichiers associés.

PostLoad 
: Après qu’une entité a été chargée depuis la base de données.
: Utile pour initialiser des propriétés calculées ou effectuer des transformations non persistées.

PreFlush
: Avant que l'EntityManager exécute le flush().
: Utile pour valider ou synchroniser des entités avant leur écriture.

### Un exemple

```php
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
#[ORM\HasLifecycleCallbacks]
class Product
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private $id;

    #[ORM\Column(type: 'string')]
    private $name;

    #[ORM\Column(type: 'datetime')]
    private $createdAt;

    #[ORM\Column(type: 'datetime', nullable: true)]
    private $updatedAt;

    // Méthode déclenchée avant la persistance
    #[ORM\PrePersist]
    public function setCreatedAt(): void
    {
        $this->createdAt = new \DateTimeImmutable();
    }

    // Méthode déclenchée avant la mise à jour
    #[ORM\PreUpdate]
    public function setUpdatedAt(): void
    {
        $this->updatedAt = new \DateTimeImmutable();
    }

    // Méthode déclenchée après le chargement
    #[ORM\PostLoad]
    public function initialize(): void
    {
        // Exemple : initialisation d’une propriété non persistée
    }
}
```

### Bonnes pratiques

1. Utiliser les callbacks pour des opérations spécifiques : Éviter de placer trop de logique dans les callbacks afin de garder le code lisible et maintenable.

2. Ne pas modifier pas directement les relations dans `PostLoad` : Cela peut perturber Doctrine et générer des erreurs.

3. Valider les données en dehors des callbacks : Les callbacks ne doivent pas remplacer une bonne validation dans les formulaires ou services.


Les Lifecycle Callbacks sont très utiles dans les cas où des actions doivent être déclenchées automatiquement en réponse aux changements du cycle de vie des entités. Cependant, pour des tâches complexes, il convient de privilégier les event listeners ou les event subscribers pour maintenir un code propre et découplé.

