# Utilisation des associations

## Objectifs
 - Persister des entités associées avec Doctrine
 - Comprendre l'importance de la cascade

## Insertion

### OneToOne et ManyToOne

Le code suivant présente un exemple de persistance avec une entité associée.

> Ce code ne fonctionne que si l'association dans `Person` est configurée pour persister en cascade. Sinon il faudrait persister séparément toutes les entités liées.
> `#[ORM\ManyToOne(cascade: ['persist'], inversedBy: 'people')]` 

```php
final class PersonController extends AbstractController
{
    #[Route('/person/insert', name: 'app_person_insert')]
    public function insert(
        EntityManagerInterface $manager): Response
    {
        // Création de l'adresse
        $address = new Address();
        $address->setCity('Paris')
                ->setZipCode('75020')
                ->setStreet('2 rue Orfila');

        // Création de la personne
        $jane = new Person();
        $jane->setFirstName('Jane')->setLastName('Doe');
        
        // Association entre la personne et son adresse
        $jane->setAddress($address);

        // Persistance
        $manager->persist($jane);
        $manager->flush();

        return $this->render('person/index.html.twig', [
            'person' => $jane,
            'address' => $address,
        ]);
    }
}
```

![CleanShot 2025-01-22 at 11.42.20@2x.png](CleanShot 2025-01-22 at 11.42.20@2x.png)

> Notons que l'association contient une entité `Address` hydratée et persistée. L'association inverse sur `Address` n'est en revanche pas hydratée par défaut, car cela provoquerait une association récursive sans fin.

En cliquant sur la barre de debug de Symfony nous accèdons au Profiler et pouvons observer les requêtes exécutées par Doctrine.

![CleanShot 2025-01-22 at 11.56.48@2x.png](CleanShot 2025-01-22 at 11.56.48@2x.png)

### ManyToMany

Ici encore, l'entité propriétaire peut persister les entités associée grâce à `cascade: ['persist']`.

```php
    #[Route('/pizza/insert', name: 'pizza_insert')]
    public function insert(
        // Injection automatique de l'EntityManager
        EntityManagerInterface $entityManager,
    ): Response
    {
        // Instanciation de la pizza
        $pizza = new Pizza();
        $pizza->setName('Reine');
        
        // Ajout des ingrédients
        $pizza->addIngredient(new Ingredient()
            ->setLabel('Jambon')->setPrice(3));
        $pizza->addIngredient(new Ingredient()
            ->setLabel('Champignon')->setPrice(3));
        $pizza->addIngredient(new Ingredient()
            ->setLabel('Fromage')->setPrice(3));

        // Persistance de l'entité
        $entityManager->persist($pizza);
        // Validation des opérations
        $entityManager->flush();

        return $this->render('pizza/index.html.twig', [
            'pizza' => $pizza,
        ]);
    }
```

## Exercices
Reprendre les entités `Article` et `Project` des exercices précédents. Créer des classes contrôleur et des routes pour tester la persistance.


