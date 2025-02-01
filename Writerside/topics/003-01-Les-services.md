# Les services

## Objectifs

- Identifier ce qu'est un service dans Symfony.
- Créer et utiliser un service.
- Identifier le rôle de l'auto-configuration et de l'auto-injection (autowiring).
- Explorer les différentes façons de paramétrer un service

## Définition

Dans Symfony, les services sont des objets réutilisables et configurables qui encapsulent une logique ou une fonctionnalité spécifique. Ils permettent de structurer et d’organiser le code de manière modulaire et maintenable. Symfony s'appuie sur un conteneur de services (ou conteneur d'injection de dépendances) pour gérer ces services.

### Qu'est-ce-qu'un service

Un service est simplement une classe qui accomplit une tâche spécifique, par exemple :

- Effectuer des calculs ou des transformations.
- Interagir avec une base de données.
- Envoyer des emails.
- Effectuer des appels API externes.
- Gérer la sécurité, etc.

En fait dans Symfony tout est service et le simple fait de créer une classe dans le dossier `src` la transforme automatiquement en service.

### Exemple

Voici un service très simple

Une interface
```php
// src/Service/GreetingInterface.php
namespace App\Service;

Interface GreetingInterface
{
    public function sayHello(string $name): string    
}
```

Une classe

```php
// src/Service/GreetingService.php
namespace App\Service;

class GreetingService implements GreetingInterface
{
    public function sayHello(string $name): string
    {
        return "Hello, $name!";
    }
}
```

Et son utilisation dans un contrôleur

```php
// src/Controller/HelloController.php
namespace App\Controller;

use App\Service\GreetingInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;

class MyController extends AbstractController
{
    public function __construct(
    private GreetingInterface $greeter){}

    public function index(): Response
    {
        $message = $this->greeter->sayHello('Symfony');
        return new Response($message);
    }
}
```

Ici l'injecteur de dépendance de Symfony fait un tour de magie. Le simple fait de déclarer la dépendance dans le constructeur injecte automatiquement une instance du service.

### Bonnes pratiques

- **Interface** : Préférer typer sur des interfaces si le service est susceptible de changer. Pour les composants de Symfony, toujours typer sur une interface.
- **Modularité** : Déporter la logique métier dans des services pour simplifier les contrôleurs
- **Autowiring** : Tirer parti de l'autowiring pour injecter les dépendances. Cette fonctionnalité est active pour toutes les classes, y compris les services eux-mêmes.

### Commandes utiles

Symfony propose des outils pour interagir avec les services :

Lister tous les services disponibles :

```bash
symfony console debug:container
```

Rechercher un service spécifique :

```bash
php bin/console debug:container <service_name>
```

## Un exemple plus concret

Un service d'envoi d'email

```php
// src/Service/EmailService.php
namespace App\Service;

use Symfony\Component\Mailer\MailerInterface;
use Symfony\Component\Mime\Email;

class EmailService
{
    private MailerInterface $mailer;

    public function __construct(MailerInterface $mailer)
    {
        $this->mailer = $mailer;
    }

    public function sendEmail(string $to, string $subject, string $content): void
    {
        $email = (new Email())
            ->from('you@example.com')
            ->to($to)
            ->subject($subject)
            ->text($content);

        $this->mailer->send($email);
    }
}
```

Et son utilisation dans un contrôleur, notons qu'ici, nous injectons la dépendance dans la méthode utilisatrice et non dans le constructeur.

```php
public function sendEmail(EmailService $emailService): Response
{
    $emailService->sendEmail(
        'test@example.com', 
        'Subject', 
        'Hello World!');
    return new Response('Email sent');
}
```

## Configurer un service

L'injection automatique (autowiring) ne fonctionne que pour les classes ou les interfaces. Si nous souhaitons passer un paramètre scalaire au service, il faudra le configurer.

Les paramètres sont des constantes que nous pouvons définir de plusieurs façons :

- En tant que constante de classe dans le service.
- Dans la clef `parameters` de `config/services.yaml`.


Si l'information ne doit pas être partagée par plusieurs services, nous opterons pour la première solution.

### Un service d'upload

Ici le service d'upload a besoin de connaitre le chemin dans lequel déplacer le fichier. Ce chemin pourrait être utilisé par d'autres services donc nous en ferons un paramètre.

```yaml
# config/services.yaml
parameters:
    app.upload_directory: '%kernel.project_dir%/public/uploads'
```

Ensuite dans le service, nous utilisons un attribut PHP pour indiquer la valeur qui doit être injectée.

```php
// src/Service/FileUploader.php
namespace App\Service;

use Symfony\Component\HttpFoundation\File\UploadedFile;

class FileUploader
{
    private string $uploadDirectory;

    public function __construct(
        #[Autowire('%app.upload_directory%')]
        string $uploadDirectory)
    {
        $this->uploadDirectory = $uploadDirectory;
    }

    public function upload(UploadedFile $file): string
    {
        // Génération d'un nom de fichier unique
        $fileName = uniqid() . '.' . $file->guessExtension();

        // Déplacement du fichier dans le répertoire de téléchargement
        $file->move($this->uploadDirectory, $fileName);

        return $fileName;
    }
}
```

### Un générateur de code promo

Ici, le préfixe du code promo est variable, plutôt que de l'injecter dans le constructeur, on préférera donc définir sa valeur avec un setter.

```php
// src/Service/PromoCodeGenerator.php
namespace App\Service;

class PromoCodeGenerator
{
    private string $prefix = 'BLACKFRIDAY';

    public function setPrefix(string $prefix): self{
        $this->prefix = strtoupper($prefix);
    }

    public function generateCode(int $length = 8): string
    {
        $randomString = bin2hex(random_bytes($length / 2));
        return $this->prefix . '-' . $randomString;
    }
}
```

### Un calculateur de frais de port

Ici le tarif de base de l'expédition est uniquement utilisé par ce service, inutile donc de l'injecter. Nous pourrions tout de même le récupérer soit en appellant la constante, soit en utilisant la méthode `getBaseFee`.

Cet exemple est simplifié pour les besoins de la démonstration. Dans un cas réél, nous aurions sans doute besoin d'un autre service pour calculer le surcoût de l'expédition à l'international.

```php
// src/Service/DeliveryService.php
namespace App\Service;

class DeliveryService
{
    // Définir une constante pour le tarif de base
    private const BASE_DELIVERY_FEE = 5.99;

    public function calculateFee(
        float $weight, 
        string $destination): float
    {
        // Exemple simple : les frais augmentent avec le poids et en fonction de la destination
        $extraFee = $destination === 'international' ? 15.00 : 0.00;

        return self::BASE_DELIVERY_FEE + ($weight * 0.50) + $extraFee;
    }

    public function getBaseFee(): float
    {
        return self::BASE_DELIVERY_FEE;
    }
}
```

## Services et interfaces

Créer des interfaces pour les services dans Symfony n'est pas obligatoire, mais cela peut être une bonne pratique dans certaines situations. Cela dépend du contexte et des besoins de notre application. Voici un guide pour décider quand et pourquoi créer des interfaces pour nos services, ainsi que leurs avantages et inconvénients.

### Pourquoi créer des interfaces pour les services ?

1. **Respect du principe SOLID :**

   Le D de SOLID (Principe d'inversion des dépendances) recommande de coder contre une interface plutôt qu'une implémentation concrète.
    
   Cela rend notre code plus flexible et maintenable.

2. **Facilité de remplacement :**

   Une interface permet de remplacer facilement une implémentation par une autre.

   Exemple : si nous souhaitons avoir plusieurs implémentations d’un service (une pour un environnement local et une pour la production), une interface facilite le changement.

3. **Tests unitaires :**

    Les interfaces permettent d'utiliser des mocks ou des stubs pendant les tests unitaires.

    Exemple : simuler une dépendance au lieu d'utiliser la vraie classe (comme une API ou un service externe).

4. **Contrats clairs :**

    Une interface agit comme un contrat, définissant ce que le service doit faire sans révéler comment il le fait.
    Cela aide à garder une séparation claire entre la logique métier et les détails d'implémentation.

### Quand créer une interface pour un service ?

#### Cas où il est pertinent :

1. **Services critiques :**

    Si le service est au cœur de notre application et peut évoluer ou être remplacé.
    
    Exemple : services de paiement, services d’envoi d’email.

2. **Services polymorphiques :**

    Si nous prévoyons d'avoir plusieurs implémentations.

    Exemple : un service de stockage pouvant utiliser des fichiers locaux ou un service cloud (S3, Azure Blob, etc.).

3. **Travail en équipe :**

    Les interfaces permettent à plusieurs développeurs de travailler indépendamment : un développeur peut implémenter une interface pendant qu'un autre écrit le code qui utilise l'interface.

4. **Projets évolutifs :**

    Si notre projet est complexe et susceptible d’évoluer avec de nouvelles fonctionnalités ou intégrations.

#### Cas où ce n’est pas nécessaire :

1. **Services simples :**

    Si le service effectue une tâche simple et stable, comme convertir une chaîne ou traiter une liste.
    
    Exemple : un service qui calcule des taux d'imposition pour une région fixe.

2. **Pas de remplacement prévu :**

    Si nous sommes certains qu’il n’y aura jamais besoin de plusieurs implémentations.

3. Projets petits ou MVPs :
    
    Si nous développons un projet simple ou un prototype, ajouter des interfaces peut être un surcoût inutile.

### Un exemple

**L'interface**
```php
// src/Service/NotifierInterface.php
namespace App\Service;

interface NotifierInterface
{
    public function send(string $recipient, string $subject, string $message): void;
}
```

**Une implémentation**
```php
// src/Service/EmailNotifier.php
namespace App\Service;

class EmailNotifier implements NotifierInterface
{
    public function send(string $recipient, string $subject, string $message): void
    {
        echo sprintf("Email envoyé à %s : [%s] %s", $recipient, $subject, $message);
    }
}
```

**Une autre implémentation**
```php
// src/Service/SmsNotifier.php
namespace App\Service;

class SmsNotifier implements NotifierInterface
{
    public function send(string $recipient, string $subject, string $message): void
    {
        echo sprintf("SMS envoyé à %s : [%s] %s", $recipient, $subject, $message);
    }
}
```

Il faut préciser l'implémentation qui sera injectée autmatiquement quand on typera sur l'interface.

```yaml
# config/services.yaml
services:
   App\Service\NotifierInterface: '@App\Service\EmailNotifier'
```

## Les tags

Les tags permettent d'ajouter des métadonnées aux services et d'influencer leur comportement. Symfony utilise les tags pour des fonctionnalités comme les événements, les commandes console, les écouteurs de requêtes, etc.

Symfony est un framework événementiel et les tags permettent de brancher notre propre code sur les différents événements du traitement d'une requête HTTP.

### Exemple, une commande console

Ici l'attribut `#[AsCommand(name: 'app:say-hello')]` déclare notre classe comme une commande console.

```php
// dans src/Command

namespace App\Command;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Attribute\AsCommand;

#[AsCommand(name: 'app:say-hello')]
class HelloCommand extends Command
{
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $output->writeln('Hello, Symfony!');
        return Command::SUCCESS;
    }
}
```

Listons les commandes de Symfony

```bash
symfony console list
```

La commande `app:say-hello` apparaît car elle est automatiquement taggée avec `console.command`.

Exécutons la commande :

```bash
symfony console app:say-hello
```

### Autre exemple, injection dans la requête

Ici nous ajoutons une information dans la requête.

```php
// dans src/EventListener

namespace App\EventListener;

use Symfony\Component\HttpKernel\Event\RequestEvent;

class RequestListener
{
   #[AsEventListener(
      event: 'kernel.request', 
      priority: 100
    )]
    public function onKernelRequest(RequestEvent $event): void
    {
        $request = $event->getRequest();
        $request->attributes->set('_custom_attribute', 'Ceci est un attribut personnalisé.');
    }
}
```

Dans le profiler, nous retrouvons notre attribut

![CleanShot 2025-01-30 at 14.22.01@2x.png](CleanShot 2025-01-30 at 14.22.01@2x.png)

Dans un contrôleur, nous pouvons récupérer cette valeur avec : `$request->get('_custom_attribute')`

```php
class HomeController extends AbstractController
{
    #[Route('/', name: 'home')]
    public function index(Request $request)
    {
        dump(
            $request->get('_custom_attribute')
        );
        
        return $this->render('home/index.html.twig');
    }
}
```

### Liste des tags et des attributs PHP

| **Attribut PHP**                          | **Remplace le tag `services.yaml`**      | **Description** |
|--------------------------------------------|--------------------------------|------------------------------------|
| `#[AsEventListener]`                       | `kernel.event_listener`        | Ajoute un écouteur d'événement |
| `#[AsEventListener]`                       | `kernel.event_subscriber`      | Ajoute un abonné d'événements (remplace `getSubscribedEvents()`) |
| `#[AsCommand]`                             | `console.command`              | Déclare une commande console |
| `#[AsValidator]`                           | `validator.constraint_validator` | Déclare un validateur personnalisé |
| `#[AsTaggedItem('twig.extension')]`       | `twig.extension`               | Enregistre une extension Twig |
| `#[AsTaggedItem('monolog.logger')]`       | `monolog.logger`               | Déclare un logger personnalisé |
| `#[AsTaggedItem('form.type')]`            | `form.type`                    | Enregistre un champ personnalisé pour les formulaires |
| `#[AsTaggedItem('serializer.normalizer')]` | `serializer.normalizer`        | Enregistre un normalizer personnalisé |
| `#[AsTaggedItem('serializer.encoder')]`   | `serializer.encoder`           | Enregistre un encodeur personnalisé |
| `#[AsTaggedItem('doctrine.event_listener')]` | `doctrine.event_listener`     | Déclare un écouteur d'événements Doctrine |
| `#[AsTaggedItem('doctrine.event_subscriber')]` | `doctrine.event_subscriber` | Déclare un abonné aux événements Doctrine |
| `#[AsTaggedItem('security.voter')]`        | `security.voter`               | Déclare un voter de sécurité personnalisé |
| `#[IsGranted]`                             | `security.is_granted`          | Vérifie un rôle avant d'exécuter une action |



