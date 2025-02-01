# Messages Flash

## Objectifs
- Identifier le rôle des messages Flash.
- Créer et consommer des messages Flash.


## Principe

Un message Flash est une information temporaire stockée dans la session, mais qui disparaît après avoir été affichée une seule fois. Il est principalement utilisé pour les notifications dans les applications web.

Exemple d'utilisation typique :

- Un utilisateur soumet un formulaire.
- L'application traite les données et enregistre un message de succès en session.
- Après la redirection, le message est affiché à l’utilisateur.
- Le message est supprimé automatiquement après affichage.

## Exemple d'utilisation

Dans un contrôleur héritant de `AbstractConroller`, nous utilisons la méthode `addFlash` en passant deux arguments :

- Le type de message.
- Le message.

```php
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Session\SessionInterface;
use Symfony\Component\Routing\Annotation\Route;

class DemoController extends AbstractController
{
    #[Route('/flash-message', name: 'flash_message')]
    public function flashMessage(SessionInterface $session)
    {
        $this->addFlash(
            'success', 
            'Votre action a été réalisée avec succès !'
        );

        // Rediection
        return $this->redirectToRoute('app_home'); 
    }
}
```

### Affichage du message Flash

Dans une vue, nous pouvons boucler sur les messages de type "success".

```twig
{% for message in app.flashes('success') %}
    <div class="alert alert-success">
        {{ message }}
    </div>
{% endfor %}
```

Ou mieux encore, boucler sur l'ensemble des types de messages

```twig
{% for label, messages in app.flashes %}
    {% for message in messages %}
        <div class="alert alert-{{ label }}">
            {{ message }}
        </div>
    {% endfor %}
{% endfor %}
```

> Ce dernier code pourrait résider dans un gabarit (layout) afin que chaque vue héritant de ce gabarit puisse afficher les messages Flash.

### Message Flash dans les services

Si nous souhaitons définir un message Flash dans un service, il nous faut injecter la session et récupérer le `FlashBag` depuis cette session.

```php
namespace App\Service;

use Symfony\Component\HttpFoundation\Session\Flash\FlashBagInterface;
use Symfony\Component\HttpFoundation\Session\SessionInterface;

class MyService
{
    private FlashBagInterface $flashBag;

    public function __construct(SessionInterface $session)
    {
        $this->flashBag = $session->getFlashBag();
    }

    public function doStuff(): void
    {
        $this->flashBag->add(
            'success', 
            'MyService a fait son job'
        );
    }
}
```

#### Factorisation dans un service

Il serait également possible de factoriser tout cela dans un service qui pourrait être injecté partout où nous en avons besoin.

```php

namespace App\Service;

use Symfony\Component\HttpFoundation\Session\Flash\FlashBagInterface;
use Symfony\Component\HttpFoundation\Session\SessionInterface;

class FlashMessageService
{
private FlashBagInterface $flashBag;

    public function __construct(SessionInterface $session)
    {
        $this->flashBag = $session->getFlashBag();
    }

    public function addSuccess(string $message): void
    {
        $this->flashBag->add('success', $message);
    }

    public function addError(string $message): void
    {
        $this->flashBag->add('error', $message);
    }

    public function addWarning(string $message): void
    {
        $this->flashBag->add('warning', $message);
    }

    public function addInfo(string $message): void
    {
        $this->flashBag->add('info', $message);
    }
}
```

Ce qui nous permettrait de simplifier le code de `MyService`.

```php
namespace App\Service;

use Symfony\Component\HttpFoundation\Session\Flash\FlashBagInterface;
use Symfony\Component\HttpFoundation\Session\SessionInterface;

class MyService
{
    public function __construct(
    FlashMessageService $flashService){}

    public function doStuff(): void
    {
        $this->flashService->addSuccess(
            'MyService a fait son job'
        );
    }
}
```