# Entités et héritage

## Objectifs
- Identifier les stratégies d'héritage proposées par Doctrine.

## Le principe

L’héritage dans Doctrine ORM permet aux entités de partager des propriétés et des comportements tout en étant mappées efficacement à une base de données. Doctrine propose plusieurs stratégies pour implémenter l’héritage dans les classes d’entités.

### Héritage par table unique (Single Table Inheritance - STI)

Dans cette approche :

- Toutes les entités de la hiérarchie partagent une seule table.
- Une colonne discriminante permet d’identifier le type d’entité.

**Exemple concret : Utilisateurs et Administrateurs**

Un site e-commerce a des clients et des administrateurs. 
Les administrateurs ont un rôle supplémentaire, 
mais partagent certaines informations avec les clients.

```php
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
#[ORM\Table(name: "users")]
#[ORM\InheritanceType("SINGLE_TABLE")]
#[ORM\DiscriminatorColumn(name: "type", type: "string")]
#[ORM\DiscriminatorMap(
    [
        "client" => Client::class, 
        "admin" => Admin::class
    ]
)]
class User {
    #[ORM\Id, ORM\GeneratedValue, ORM\Column(type: "integer")]
    private int $id;

    #[ORM\Column(type: "string")]
    private string name;

    #[ORM\Column(type: "string", unique: true)]
    private string $email;

    // Getters et Setters...
}

#[ORM\Entity]
class Client extends User {
    #[ORM\Column(type: "datetime")]
    private \DateTime enrolledAt;
}

#[ORM\Entity]
class Admin extends User {
    #[ORM\Column(type: "string")]
    private string $role;
}
```

![CleanShot 2025-01-29 at 16.45.28@2x.png](CleanShot 2025-01-29 at 16.45.28@2x.png)

#### ✅ Avantages :

- Simple à interroger (une seule table).
- Pas de jointures complexes.

#### ❌ Inconvénients : {id="inconvenients_2"}

- Certaines colonnes ne sont pas utilisées pour certains types d'entités (ex : date_inscription n'a pas de sens pour un Admin).
- Peut poser des problèmes de performance si trop d'entités différentes sont stockées dans la même table.

### Héritage par table de classe (Class Table Inheritance - CTI)

Dans cette approche :

- Chaque classe d’entité a sa propre table.
- Les tables enfants contiennent uniquement les champs spécifiques, tout en référençant la table parent via une clé primaire.

**Exemple : Véhicules (voitures, camions)**

Une application de location de véhicules distingue les voitures et les camions, qui partagent certains attributs communs.

```php
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
#[ORM\Table(name: "vehicules")]
#[ORM\InheritanceType("JOINED")]
#[ORM\DiscriminatorColumn(name: "type", type: "string")]
#[ORM\DiscriminatorMap(["car" => Car::class, "truck" => Truck::class])]
class Vehicule {
    #[ORM\Id, ORM\GeneratedValue, ORM\Column(type: "integer")]
    protected int $id;

    #[ORM\Column(type: "string")]
    protected string $brand;

    #[ORM\Column(type: "integer")]
    protected int $year;
}

#[ORM\Entity]
#[ORM\Table(name: "cars")]
class Car extends Vehicule {
    #[ORM\Column(type: "integer")]
    private int $numberOfDoors;
}

#[ORM\Entity]
#[ORM\Table(name: "trucks")]
class Truck extends Vehicule {
    #[ORM\Column(type: "float")]
    private float $loadCapacity;
}
```

![CleanShot 2025-01-29 at 16.58.09@2x.png](CleanShot 2025-01-29 at 16.58.09@2x.png)

#### ✅ Avantages : {id="avantages_1"}

- Structure normalisée et efficace.
- Pas de colonnes inutilisées.

#### ❌ Inconvénients :

- Requêtes plus complexes car nécessitent des jointures pour récupérer toutes les données.
- Performance potentiellement affectée sur de gros volumes.

### Mapped Superclass (Classe Mappée mais Non Entité)

Dans cette approche :

- La classe parent n’a pas de table propre.
- Seules les classes filles sont stockées en base de données.
- Idéal pour éviter la duplication de code sans imposer une hiérarchie stricte.

**Exemple concret : Audit des entités**
On veut ajouter un champ createdAt et updatedAt à plusieurs entités sans créer une hiérarchie complète.

```php
use Doctrine\ORM\Mapping as ORM;

#[ORM\MappedSuperclass]
class Timestampable {
    #[ORM\Column(type: "datetime")]
    protected \DateTime $createdAt;

    #[ORM\Column(type: "datetime", nullable: true)]
    protected ?\DateTime $updatedAt;
}

#[ORM\Entity]
#[ORM\Table(name: "products")]
class Product extends Timestampable {
    #[ORM\Id, ORM\GeneratedValue, ORM\Column(type: "integer")]
    private int $id;

    #[ORM\Column(type: "string")]
    private string $name;
}

#[ORM\Entity]
#[ORM\Table(name: "orders")]
class Order extends Timestampable {
    #[ORM\Id, ORM\GeneratedValue, ORM\Column(type: "integer")]
    private int $id;

    #[ORM\Column(type: "integer")]
    private int $quantity;
}
```

![CleanShot 2025-01-29 at 16.57.26@2x.png](CleanShot 2025-01-29 at 16.57.26@2x.png)

#### ✅ Avantages : {id="avantages_2"}

- Réutilisation facile des propriétés sans créer de relation d’héritage.
- Plus performant que STI ou CTI.

#### ❌ Inconvénients : {id="inconv-nients_1"}

- Pas de requêtes polymorphiques (Doctrine ne reconnaît pas Timestampable comme une entité).


## Quelle stratégie choisir ?

| Stratégie | Avantages | Inconvénients | Meilleur cas d'utilisation |
|-----------|----------|---------------|----------------------------|
| **STI (Single Table Inheritance)** | Simple, pas de jointures | Colonnes inutilisées, moins optimisé | Peu de différences entre les sous-classes |
| **CTI (Class Table Inheritance)** | Bien structuré, performant | Requêtes complexes | Différences majeures entre entités |
| **Mapped Superclass** | Réutilisable, léger | Pas de polymorphisme | Partage de champs sans créer de hiérarchie |

