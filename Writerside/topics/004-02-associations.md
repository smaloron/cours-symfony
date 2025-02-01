# Les associations

## Objectifs

- Identifier les différents types d’associations dans Doctrine.
- Implémenter ces associations dans Symfony.

## Le principe

Les objets  sont liés entre eux par des agrégations. Une ou plusieurs instances d'un objet sont stockés dans un autre objet.

```php
class Address {

    private string $city;

    private string $zipCode;

    public function getCity(): string
    {
        return $this->city;
    }

    public function setCity(string $city): Address
    {
        $this->city = $city;
        return $this;
    }

    public function getZipCode(): string
    {
        return $this->zipCode;
    }

    public function setZipCode(string $zipCode): Address
    {
        $this->zipCode = $zipCode;
        return $this;
    }
}

class Person {

    private string $name;

    private Address $address;

    private array $friends;

    public function getName(): string
    {
        return $this->name;
    }

    public function setName(string $name): Person
    {
        $this->name = $name;
        return $this;
    }

    public function getAddress(): Address
    {
        return $this->address;
    }

    public function setAddress(Address $address): Person
    {
        $this->address = $address;
        return $this;
    }

    public function getFriends(): array
    {
        return $this->friends;
    }

    public function addFriend(Person $friends): Person
    {
        $this->friends[] = $friends;
        return $this;
    }
}
```

Dans l'exemple ci-dessus la classe `Person` référence une instance de la classe `Address` et une liste d'instances de la classe `Person`. 

Par le biais des associations, Doctrine propose de convertir ces agrégations dans le monde relationnel. Cela passera par la création de clefs étrangères et éventuellement de tables intermédiaires. 

Les règles de conversion sont indiquées dans les attributs PHP des entités.

### Les types d'assocations

- OneToOne (« Un à un »)

- ManyToOne (« Plusieurs à un »)

- OneToMany (« Un à plusieurs »)

- ManyToMany (« Plusieurs à plusieurs »)

## Ajout des associations

## OneToOne
L'association est assez rare. Elle fait correspondre une instance avec une et une seule autre et implique donc que les propriétés de la classe associée pourraient être intégrées dans la classe hôte.

Dans le monde relationnel, ce découpage a du sens quand la table associée contient des informations facultatives, cela évite la prolifération des colonnes nulles.

```php
namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class Photo
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private $id;
    
    #[ORM\Column(length: 255)]
    private ?string $fileName = null;;

    #[ORM\OneToOne(mappedBy: 'photo', 
    targetEntity: Person::class)]
    private Person $person;

    // Getters et setters...
}

```

```php
namespace App\Entity;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class Person
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private $id;
    
    #[ORM\Column(length: 50)]
    private ?string $name = null;

    #[ORM\OneToOne( targetEntity: Photo::class, 
                    cascade: ['persist', 'remove'])]
    #[ORM\JoinColumn(nullable: true)]
    private Photo $photo;

    // Getters et setters...
}
```
**Sur `Person`**

- La classe `Person` possède une propriété `$photo` qui définit l'association.
- L'attribut `ORM\OneToOne` possède un paramètre `targetEntity`qui indique la classe liée.
- Le paramètre `cascade` indique que l'entité `Photo` sera persistée ou supprimée en même temps que son entité hôte.
- L'attribut `ORM\JoinColumn(nullable:true)` indique que l'association est facultative.

**sur `Photo`**
- L'association inverse (facultative) est stockée dans une propriété `$person`.
- On retrouve le paramètre `targetEntity` qui pointe ici vers la classe `Person`.
- Le paramètre `mappedBy` indique que la propriété représente le côté inverse d'une association bidirectionnelle. L'autre côté est dit **propriétaire** de l'association. C'est lui qui portera la clef étrangère et qui contrôlera la persistance. 

>Dans la configuration actuelle, il sera possible de créer une photo à partir d'une personne, mais pas l'inverse puisque c'est la classe `Person` qui est propriétaire de l'association.

Il ne reste plus qu'à créer la migration et l'exécuter pour synchroniser les entités avec la base de données.

```
symfony console make:migration
```

Voici le code de la migration, on constate qu'une clef étrangère a été ajoutée à la table `person`.
```php
    public function up(Schema $schema): void
    {
        $this->addSql('CREATE TABLE person (id SERIAL NOT NULL, photo_id INT DEFAULT NULL, first_name VARCHAR(50) DEFAULT NULL, last_name VARCHAR(50) NOT NULL, PRIMARY KEY(id))');
        $this->addSql('CREATE UNIQUE INDEX UNIQ_34DCD1767E9E4C8C ON person (photo_id)');
        $this->addSql('CREATE TABLE photo (id SERIAL NOT NULL, file_name VARCHAR(255) NOT NULL, PRIMARY KEY(id))');
        $this->addSql('ALTER TABLE person ADD CONSTRAINT FK_34DCD1767E9E4C8C FOREIGN KEY (photo_id) REFERENCES photo (id) NOT DEFERRABLE INITIALLY IMMEDIATE');
    }
```

**Exécution de la migration**

```
symfony console doctrine:migrations:migrate
```

## Génération des méthodes
Quand on ajoute des propriétés à une entité, il faut également penser à écrire le code des méthodes getter et setter ce qui devient vite fastidieux. Heureusement, la commande suivante peut le faire à notre place. Elle ajoutera uniquement le code qui manque et ne touchera pas aux getters et setters déjà existants.

> Cette commande travaille sur toutes les entités d'un namespace

```
symfony console make:entity --regenerate
```

## ManyToOne
Sans doute l'association la plus fréquente, elle fait correspondre une instance d'une entité avec une collection d'entité cibles. Elle se traduira par une clef étrangère sur le côté propriétaire.

```php
#[ORM\Entity(repositoryClass: PersonRepository::class)]
class Person
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(length: 50, nullable: true)]
    private ?string $firstName = null;

    #[ORM\Column(length: 50)]
    private ?string $lastName = null;

    #[ORM\ManyToOne(inversedBy: 'people')]
    private ?Address $address = null;

    // getters et setters

}
```

Ici la classe `Person` possède une propriété `$address` de type `Address`. 

La classe qui possède une association `ManyToOne` est dite propriétaire de l'association.

L'association inverse sur la classe `Address` est facultative. Cette dernière n'aura de sens que pour Doctrine et ne changera pas le code `SQL` généré.

## OneToMany
Cette association ne peut exister seule, elle est l'inversion d'une association `ManyToOne` sur une classe propriétaire de l'association.

Une telle association est stockée dans une propriété de type `ArrayCollection` qui implémente l'interface `Collection`.

```php
#[ORM\Entity(repositoryClass: AddressRepository::class)]
class Address
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(length: 50)]
    private ?string $city = null;

    #[ORM\Column(length: 5)]
    private ?string $zipCode = null;

    #[ORM\Column(length: 50)]
    private ?string $street = null;

    /**
     * @var Collection<int, Person>
     */
    #[ORM\OneToMany(targetEntity: Person::class, mappedBy: 'address')]
    private Collection $people;

    public function __construct()
    {
        $this->people = new ArrayCollection();
    }

    // getters et setters

}
```

Pour ajouter ou supprimer des éléments à la collection Doctrine a besoin de deux méthodes supplémentaires. 

> `symfony console make:entity --regenerate` peut générer ce code pour nous.



```php
    public function addPerson(Person $person): static
    {
        if (!$this->people->contains($person)) {
            $this->people->add($person);
            $person->setAddress($this);
        }

        return $this;
    }

    public function removePerson(Person $person): static
    {
        if ($this->people->removeElement($person)) {
            // set the owning side to null (unless already changed)
            if ($person->getAddress() === $this) {
                $person->setAddress(null);
            }
        }

        return $this;
    }

```

## ManyToMany
Cette association fait correspondre plusieurs entités cibles avec l'entité propriétaire. Dans le monde relationnel, cela se traduit par l'ajout d'une table intermédiaire qui contient deux clefs étrangères.

```php
#[ORM\Entity(repositoryClass: PizzaRepository::class)]
class Pizza
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(length: 50)]
    private ?string $name = null;

    /**
     * @var Collection<int, Ingredient>
     */
    #[ORM\ManyToMany(targetEntity: Ingredient::class, 
                    inversedBy: 'pizzas')]
    private Collection $ingredients;

    public function __construct()
    {
        $this->ingredients = new ArrayCollection();
    }
    
    // getters et setters
```

```php
#[ORM\Entity(repositoryClass: IngredientRepository::class)]
class Ingredient
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(length: 50)]
    private ?string $label = null;

    #[ORM\Column]
    private ?int $price = null;

    /**
     * @var Collection<int, Pizza>
     */
    #[ORM\ManyToMany(targetEntity: Pizza::class, 
                    mappedBy: 'ingredients')]
    private Collection $pizzas;

    public function __construct()
    {
        $this->pizzas = new ArrayCollection();
    }
```

Ici il faut décider où placer le côté propriétaire de l'association (celui qui portera l'attribut `inversedBy`).

Avec la commande `make:entity --regenerate` nous pouvons ajouter les méthodes `add` et `remove`, nécessaires pour le bon fonctionnement de Doctrine.



## Assistance avec Maker
L'outil `Maker` peut nous aider à écrire le code des associations.

Pour cela, il suffit de modifier une entité avec `make:entity` et de créer la propriété qui portera l'association.

Ensuite quand `Maker` demandera le type de données il faudra choisir un type d'association parmi les options suivantes :

- OneToOne
- ManyToOne
- ManyToMany
- relation

La dernière option offre une assistance pour le choix du type d'association sous la forme d'un wizard.

**Exemple**

```bash

`seb@mac sf-playground % symfony console make:entity Person
Your entity already exists! So let's add some new fields!

New property name (press <return> to stop adding fields):
> address

Field type (enter ? to see all types) [string]:
> relation

What class should this entity be related to?:
> Address

What type of relationship is this?
 ------------ ---------------------------------------------------------------------- 
Type         Description
 ------------ ---------------------------------------------------------------------- 
ManyToOne    Each Person relates to (has) one Address.                             
Each Address can relate to (can have) many Person objects.

OneToMany    Each Person can relate to (can have) many Address objects.            
Each Address relates to (has) one Person.

ManyToMany   Each Person can relate to (can have) many Address objects.            
Each Address can also relate to (can also have) many Person objects.

OneToOne     Each Person relates to (has) exactly one Address.                     
Each Address also relates to (has) exactly one Person.
 ------------ ---------------------------------------------------------------------- 

Relation type? [ManyToOne, OneToMany, ManyToMany, OneToOne]:
> ManyToOne

Is the Person.address property allowed to be null (nullable)? (yes/no) [yes]:
> no

Do you want to add a new property to Address 
so that you cannaccess/update Person objects from it 
- e.g. $address->getPeople()? (yes/no) [yes]:
> yes

A new property will also be added to the Address class 
so that you can access the related Person objects from it.

New field name inside Address [people]:
> people

Do you want to activate orphanRemoval 
on your relationship?
A Person is "orphaned" when it is removed 
from its related Address.
e.g. $address->removePerson($person)

NOTE: If a Person may *change* 
from one Address to another, 
answer "no".

Do you want to automatically delete 
orphaned App\Entity\Person objects 
(orphanRemoval)? (yes/no) [no]:
> no

updated: src/Entity/Person.php
updated: src/Entity/Address.php

Add another property? Enter the property name 
(or press <return> to stop adding fields):
>
```

## Exercices

### Association OneToOne
Créez une entité Profile associée à une entité User avec une relation « un à un ».

**Objectif :**

Chaque utilisateur doit avoir un seul profil.


### Association ManyToOne
Créez une entité Article liée aux entités suivantes : 
- une entité Category avec une relation « plusieurs à un ».
- une entité Person (l'auteur de l'article) avec une relation « plusieurs à un ».

**Objectif :**

Plusieurs articles peuvent appartenir à une seule catégorie.

### Association ManyToMany
Créez une entité Project liée à une entité Developer avec une relation « plusieurs à plusieurs ».

**Objectif :**

Un développeur peut participer à plusieurs projets, et chaque projet peut inclure plusieurs développeurs.


### A faire pour chaque exercice :

- Créez les entités.

- Implémentez la relation.

- Générez et appliquez la migration avec Doctrine.

- Faire un commit avec Git

