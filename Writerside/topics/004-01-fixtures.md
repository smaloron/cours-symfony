# Les fixtures

## Objectif

L'objectif de ce document est d'apprendre à utiliser les fixtures pour injecter des informations dans la base de données lors de la phase de développement d'une application Symfony

## Le principe

L'idée ici est d'automatiser l'insertion afin que tous les membres de l'équipe partagent les mêmes données de test.

### Installation

```
composer require --dev orm-fixtures
```

Flex génère une classe `AppFixtures` dans un nouveau dossier `DataFixtures`.

```php
<?php

namespace App\DataFixtures;

use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;

class AppFixtures extends Fixture
{
    public function load(ObjectManager $manager): void
    {
        // $product = new Product();
        // $manager->persist($product);

        $manager->flush();
    }
}
```

### Premières fixtures
Le principe est simple, on instancie une entité et on utilise `ObjectManager` pour persister

```php
<?php

namespace App\DataFixtures;

use App\Entity\Pizza;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;

class AppFixtures extends Fixture
{
    public function load(ObjectManager $manager): void
    {
        $pizza = new Pizza();
        $pizza->setName('Calzone');
        $manager->persist($pizza);

        $anotherPizza = new Pizza();
        $anotherPizza->setName('Reine');
        $manager->persist($anotherPizza);
        

        $manager->flush();
    }
}
```

### Exécution des fixtures

```
symfony console doctrine:fixtures:load
```

### Un peu de factorisation
Plutôt que de répéter le code pour chaque nouvelle pizza, nous pouvons factoriser le nom de la pizza et faire une boucle.

```php
    public function load(ObjectManager $manager): void
    {
        $pizzaNames = ['Calzone', 'Reine', 'Napolitaine', 'Romaine'];

        foreach ($pizzaNames as $name) {
            $pizza = new Pizza();
            $pizza->setName($name);
            $manager->persist($pizza);
        }
        
        $manager->flush();
    }
```

## Fixtures multiples et dépendances

Il est conseillé de créer autant de fichier de fixtures que nous avons d'entités, cependant cette technique pose deux problèmes :

- Comment s'assurer de l'ordre d'exécution des fixtures
- Comment récupérer les instances d'une fixture dans une autre

> Pour créer une nouvelle classe de fixtures nous pouvons utiliser `make:fixtures`.

### Récupérer des instances

Les méthodes `addReference` et `getReference` permettent d'enregistrer puis de récupérer une référence à un objet. 

```php
class CategoryFixtures extends Fixture
{
    const CATEGORIES_LIST = [
        'Economie', 'Tech', 'Politique', 'Société'
    ];

    public function load(ObjectManager $manager): void
    {
        // Boucle sur l'ensemble des catérories
        foreach (self::CATEGORIES_LIST as $item) {
        
            $category = new Category();
            $category->setCateroryName($item);
            
            $manager->persist($category);

            // Enregistre une réference de l'entité persistée
            // admet en argument : 
            // - le nom de la référence
            // - l'objet référencé
            $this->addReference("categorie-$item", $category);
        }

        $manager->flush();
    }
}
```

```php
class ArticleFixtures extends Fixture
{
    public function load(ObjectManager $manager): void
    {
        // Récupération d'une instance
        // arguments :
        // - le nom de la référence
        // - le type de l'objet retourné
        $category = $this->getReference(
                    'categorie-Economie', 
                     Category::class
        );
        
        $article = new Article();
        $article->setTitle('Mon premier article')
        ->setContent('bla bla bla')
        ->setCategory($category);
        
        $manager->persist($article);

        $manager->flush();
    }
}
```

### Ordre d'éxécution des fixtures

Le problème ici est que les fixtures sont chargées par ordre alphabétique du nom de la classe. Nous pourrions bien entendu nommer les classes de sorte que les categories soient exécutées avant les articles, mais il existe une solution plus élégante.

- La classe `ArticleFixtures` doit implémenter `DependentFixtureInterface`.
- Dans la méthode `getDependencies` nous passons un tableau contenant les classes qui doivent être exécutées avant `ArticleFixtures`.

```php
class ArticleFixtures 
    extends Fixture 
    implements DependentFixtureInterface
{
    public function load(ObjectManager $manager): void
    {
        // Récupération d'une instance
        $category = $this->getReference(
                    'categorie-Economie', 
                    Category::class
        );

        $article = new Article();
        $article->setTitle('Mon premier article')
        ->setContent('bla bla bla')
        ->setCategory($category);
        
        $manager->persist($article);

        $manager->flush();
    }

    public function getDependencies(): array
    {
        return [CategoryFixtures::class];
    }
}
```

### Sélection aléatoire des catégories

Améliorons la fixture avec le choix aléatoire d'une catégorie. 

```php
    public function load(ObjectManager $manager): void
    {

        $titlesList = [
            "Les nouveautés de PHP",
            "Le bitcoin dans tous les coins",
            "Les nouvelles technologies du web",
            "Les meilleurs sites internet du monde",
            "Comment coder sans se fatiguer"
        ];

        foreach ($titlesList as $title) {

            $referenceName = "categorie-".
                CategoryFixtures::CATEGORIES_LIST[
                    array_rand(CategoryFixtures::CATEGORIES_LIST)
                ];

            $category = $this->getReference(
                                $referenceName, 
                                Category::class
            );

            $article = new Article();
            $article->setTitle($title)
                    ->setContent('bla bla bla')
                    ->setCategory($category);

            $manager->persist($article);
        }
    }
```


## Faker

```
composer require --dev fakerphp/faker
```

La bibliothèque `Faker` propose une série de générateurs de contenu aléatoire, très utile pour les fixtures.

```php
    public function load(ObjectManager $manager): void
    {
        $numberOfArticles = 20;

        $faker = \Faker\Factory::create();

        // Génération des articles en boucle
        foreach (range(1, $numberOfArticles) as $index) {
            $article = new Article();

            // Choix d'une catégorie aléatoire
            $ref = $faker->randomElement(
                   CategoryFixtures::CATEGORIES_LIST
            );
            $category = $this->getReference(
                    "categorie-$ref", 
                    Category::class
            );

            $article->setTitle($faker->sentence(8))
                ->setContent($faker->paragraph(10))
                ->setCategory($category);

            $manager->persist($article);
        }

        $manager->flush();
    }

```

## Exercice

- Créer des fixtures pour les pizzas et les ingrédients





