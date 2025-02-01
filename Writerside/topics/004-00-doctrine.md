# Doctrine

## Objectif
L’objectif de ce document est d’apprendre à utiliser Doctrine pour créer des entités et les persister dans une base de données.

## Intro
Doctrine est un ORM (Object Relational Mapper). Son travail consiste à réconcilier la logique objet avec la logique de la base de donnée relationnelle.

### Installation

```
composer require symfony/orm-pack
composer require --dev symfony/maker-bundle
```

Support Docker 

![CleanShot 2025-01-20 at 16.53.55@2x.png](CleanShot 2025-01-20 at 16.53.55@2x.png)

#### Environnement
Le fichier `.env` contient désormais la configuration de la connexion à la base de données en mode développement. En production, ces informations seront récupérées depuis les vraies variables d’environnement du serveur.
L’ORM Doctrine peut fonctionner avec de nombreux SGBDR, le fichier de configuration ne propose que des options gratuites (SQLite, MariaDB, MySQL et PostgreSQL) mais libre à vous d’utiliser Oracle ou MS SQL Server. 

#### Docker compose
Le fichier `compose.yaml` décrit la configuration d’un conteneur Docker pour la base de données. Il s’agit par défaut d’un serveur PostgreSQL.

Si le support Docker est installé, on peut instancier le conteneur

```
docker compose up -d
```

#### Création de la base de données
Cette étape est inutile si nous utilisons Docker, car en ce cas la base de données est déjà créée. 
```
symfony console doctrine:database:create
```

## Les entités
Une entité est une classe chargée de modéliser des données qui seront persistées en base de données. Pour spécifier la correspondance entre les propriétés de cet objet et la base de données Doctrine utilise des attributs PHP.

Le composant Maker propose un outil en ligne de commande pour nous aider à générer les entités.

```
symfony console make:entity
```

Il suffit de se laisser guider et de répondre aux questions. Inutile de définir une propriété id, celle-ci est automatiquement générée.

```
seb@mac sf-playground % symfony console make:entity                

 Class name of the entity to create or update (e.g. GentlePuppy):
 > Pizza

 created: src/Entity/Pizza.php
 created: src/Repository/PizzaRepository.php
 
 Entity generated! Now let's add some fields!
 You can always add more fields later manually or by re-running this command.

 New property name (press <return> to stop adding fields):
 > name

 Field type (enter ? to see all types) [string]:
 > 

 Field length [255]:
 > 50

 Can this field be null in the database (nullable) (yes/no) [no]:
 > 

 updated: src/Entity/Pizza.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 > 
```

> Il est toujours possible de revenir sur une entité déjà créée afin d’ajouter de nouvelles propriétés

```
symfony console make:entity Pizza
```

**Le code de l’entité générée**

```php
<?php

namespace App\Entity;

use App\Repository\PizzaRepository;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: PizzaRepository::class)]
class Pizza
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(length: 50)]
    private ?string $name = null;

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getName(): ?string
    {
        return $this->name;
    }

    public function setName(string $name): static
    {
        $this->name = $name;
        return $this;
    }
}
```

Une classe très simple, uniquement composée de propriétés et de méthodes getters et setters. La spécificité réside dans les attributs qui gèrent la correspondance avec la base de données.

Ajoutons le nom de la table dans l’attribut de la classe

```php
#[
    ORM\Entity(repositoryClass: PizzaRepository::class), 
    ORM\Table(name: 'pizzas')
]
```

### Les types de données

Dans l’outil Maker, au moment du choix d’un type de données, nous obtenons la liste des types disponible si nous tapons ? puis validons avec ENTER.

```
Main Types
  * string or ascii_string
  * text
  * boolean
  * integer or smallint or bigint
  * float

Relationships/Associations
  * relation a wizard 🧙 will help you build the relation
  * ManyToOne
  * OneToMany
  * ManyToMany
  * OneToOne

Array/Object Types
  * array or simple_array
  * json
  * object
  * binary
  * blob

Date/Time Types
  * datetime or datetime_immutable
  * datetimetz or datetimetz_immutable
  * date or date_immutable
  * time or time_immutable
  * dateinterval

Other Types
  * enum
  * decimal
  * guid

```

### La migration
Pour l’heure, nous n’avons qu'une classe, mais à partir de celle-ci, nous pouvons demander à Doctrine de créer la table dans la base de données. 
C’est là le côté magique de l’ORM, la base de données devient un service de persistance dont le développeur ne se préoccupe plus. Ce principe n’est pas sans limites, mais force est de constater que dans bien des cas, il est très efficace.

```
symfony console make:migration
```

Cette dernière commande compare l’état de la base de données avec celui des entités. Elle génère un fichier de migration contenant le code SQL nécessaire pour synchroniser la base de données avec les entités.

**Le fichier de migration**

```php
<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20250120212924 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE pizzas (id SERIAL NOT NULL, name VARCHAR(50) NOT NULL, PRIMARY KEY(id))');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE SCHEMA public');
        $this->addSql('DROP TABLE pizzas');
    }
}
```

**Pour obtenir la liste des migrations avec leurs statuts**

```
symfony console doctrine:migrations:list
```

![CleanShot 2025-01-21 at 07.17.20@2x.png](CleanShot 2025-01-21 at 07.17.20@2x.png)

#### Exécuter les migrations en suspend

```
symfony console doctrine:migrations:migrate
```

Cette commande exécute les fichiers de migrations pour synchroniser la base de donneés avec les entités. Afin d’éviter d’exécuter plusieurs fois la même migration, la commande enregistre les opérations effectuées dans une table des migrations sur la base de données.

![CleanShot 2025-01-21 at 07.35.51@2x.png](CleanShot 2025-01-21 at 07.35.51@2x.png)

![CleanShot 2025-01-21 at 07.37.02@2x.png](CleanShot 2025-01-21 at 07.37.02@2x.png)

Doctrine offre une commande qui exécute des requêtes sql depuis la console. Usons de cet outil pour Afficher le contenu de la table de migrations.

```
symfony console doctrine:query:sql 'select * from doctrine_migration_versions'
```

![CleanShot 2025-01-21 at 07.44.20@2x.png](CleanShot 2025-01-21 at 07.44.20@2x.png)


### Exercice
Créer les entités suivantes :

**Book**

- title : string not nullable
- publishedAt : date not nullable
- language : string not nullable

**Author**
- firstName : string nullable
- lastName : string not nullable
- nationality : string not nullable

**Ingredient**
- label : string not nullable
- price : integer not nullable

Générer, puis exécuter les migrations

## La Persistance des entités

Pour tester la persistance, il nous faut un contrôleur et une vue.

```php
<?php

namespace App\Controller;

use App\Entity\Pizza;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;


final class PizzaController extends AbstractController
{
    #[Route('/pizza/insert', name: 'pizza_insert')]
    public function index(): Response
    {
        // Instanciation de l'entité
        $pizza = new Pizza();
        $pizza->setName('Calzone');

        return $this->render('pizza/index.html.twig', [
            'pizza' => $pizza,
        ]);
    }
}
```

```Twig
{% extends 'base.html.twig' %}

{% block title %}Hello PizzaController!{% endblock %}

{% block body %}
    <h1>Pizza</h1>
    
    {{ dump(pizza) }}
    
{% endblock %}
```

![CleanShot 2025-01-21 at 08.15.41@2x.png](CleanShot 2025-01-21 at 08.15.41@2x.png)


L’entité n’est pas persistée, sa propriété `id` est nulle.

### Mise en place de la persistance

```php
    #[Route('/pizza/insert', name: 'pizza_insert')]
    public function insert(
        // Injection automatique de l'EntityManager
        EntityManagerInterface $entityManager
    ): Response
    {
        $pizza = new Pizza();
        $pizza->setName('Calzone');

        // Persistance de l'entité
        $entityManager->persist($pizza);
        // Validation des opérations
        $entityManager->flush();

        return $this->render('pizza/index.html.twig', [
            'pizza' => $pizza,
        ]);
    }
```

1. L’objet `EntityManager` est chargé de la gestion des entités (insertion, mise à jour et suppression).
2. Cette instance est automatiquement injectée, il suffit de la déclarer dans la signature de la méthode et bien entendu de la typer.
3. Toutes les opérations de persistance s’effectuent au sein d’une transaction `SQL. La méthode `flush` valide la transaction et exécute toutes les commandes en attente.

![CleanShot 2025-01-21 at 08.27.22@2x.png](CleanShot 2025-01-21 at 08.27.22@2x.png)

L’entité est persistée, son id n’est plus nul. Nous pouvons constater avec une requête SQL que les données sont bien enregistrées dans la base.

![CleanShot 2025-01-21 at 08.28.55@2x.png](CleanShot 2025-01-21 at 08.28.55@2x.png)

### EntityManager et Repository
Comme son nom l’indique, l’EntityManager s’occupe des entités et communique avec la base de données pour enregistrer (persister) l’état de ces entités.

En simplifiant un peu, on pourrait dire que les classes Repository font l’inverse, elles interrogent la base de données pour hydrater des entités.

```php
#[Route('/pizza/select', name: 'pizza_select')]
    public function select(
        // Injection automatique de l'EntityManager
        PizzaRepository $pizzaRepository
    ): Response
    {
        $pizza = $pizzaRepository->findOneById(1);

        return $this->render('pizza/index.html.twig', [
            'pizza' => $pizza,
        ]);
    }
```

![CleanShot 2025-01-21 at 08.41.35@2x.png](CleanShot 2025-01-21 at 08.41.35@2x.png)

> On obtient les mêmes données qu'avec l’insertion, mais l’entité n’est pas la même (#1531 ici).

### Une simplification

```php
    #[Route('/pizza/select/{id}',
        name: 'pizza_select',
        requirements: ['id' => Requirement::DIGITS])]
    public function select(
        Pizza $pizza
    ): Response
    {
        return $this->render('pizza/index.html.twig', [
            'pizza' => $pizza,
        ]);
    }
```

Ici la route demande un paramètre `id`, mais c’est un objet `Pizza` qui est passé en argument. Symfony effectue automatiquement la requête et nous retourne une entité hydratée. Pour que ce tour de magie fonctionne, il faut que le paramètre porte le même nom que la clef primaire de l’entité (`id`).

### Amélioration de l’insertion

Ici le nom de la pizza est passé en paramètre ce qui nous évitera de créer de multiples calzones.

```php
    #[Route('/pizza/insert/{name}', name: 'pizza_insert')]
    public function index(
        // Injection automatique de l'EntityManager
        EntityManagerInterface $entityManager,
        string $name
    ): Response
    {
        // Pas d'espace dans les url
        $name = str_replace(['-', '_'], ' ', $name);
        $pizza = new Pizza();
        $pizza->setName($name);

        // Persistance de l'entité
        $entityManager->persist($pizza);
        // Validation des opérations
        $entityManager->flush();

        return $this->render('pizza/index.html.twig', [
            'pizza' => $pizza,
        ]);
    }
```

### La suppression

```php
    #[Route('/pizza/delete/{id}',
        name: 'pizza_delete',
        requirements: ['id' => Requirement::DIGITS])]
    public function delete(
        EntityManagerInterface $entityManager,
        Pizza $pizza
    ): Response
    {

        $entityManager->remove($pizza);
        $entityManager->flush();

        return $this->render('pizza/index.html.twig', [
            'pizza' => $pizza,
        ]);
    }
```

![CleanShot 2025-01-21 at 09.11.06@2x.png](CleanShot 2025-01-21 at 09.11.06@2x.png)

### La mise à jour
Ici la seule différence avec l’insertion réside dans l’entité de départ qui est nouvelle dans un cas et hydratée par la base de données dans l’autre.

```php
    #[Route('/pizza/update/{id}',
        name: 'pizza_update',
        requirements: ['id' => Requirement::DIGITS])]
    public function update(
        EntityManagerInterface $entityManager,
        Pizza $pizza
    ): Response
    {

        $pizza->setName('Quatre fromages');
        $entityManager->persist($pizza);
        $entityManager->flush();

        return $this->render('pizza/index.html.twig', [
            'pizza' => $pizza,
        ]);
    }
```

### Exercice sur la persistance

Réaliser les mêmes opérations (insertion, mise à jour et suppression) pour l’entité `Author` dans un nouveau contrôleur 





