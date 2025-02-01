# UserChecker

## Objectifs

## Principe
Le UserChecker dans Symfony est une classe permettant de vérifier l’état d’un utilisateur avant et après l'authentification. Il permet d'ajouter des règles de sécurité supplémentaires avant d’autoriser l'accès à un utilisateur.

Symfony propose une interface UserCheckerInterface qui expose deux méthodes :

- `checkPreAuth(UserInterface $user)`: exécutée avant l'authentification, pour empêcher un utilisateur de se connecter.
- `checkPostAuth(UserInterface $user)`: exécutée après l'authentification, pour bloquer un utilisateur même s’il a fourni de bonnes informations d’identification.

## Mise en place

Tout d'abord nous devons coder une classe qui implémente `UserCheckerInterface`. Cette classe sera taggée sur l'événement `security.user_checker`.

```php
// src/Security/UserChecker.php

namespace App\Security;

use Symfony\Component\DependencyInjection\Attribute\AsTaggedItem;
use Symfony\Component\Security\Core\Exception\CustomUserMessageAccountStatusException;
use Symfony\Component\Security\Core\User\UserCheckerInterface;
use Symfony\Component\Security\Core\User\UserInterface;

#[AsTaggedItem('security.user_checker')]
class UserChecker implements UserCheckerInterface
{
    public function checkPreAuth(UserInterface $user): void
    {
        // Test du statut de l'utilisateur avant authentification
        if (method_exists($user, 'isBanned') && $user->isBanned()) {
            throw new CustomUserMessageAccountStatusException(
                'Votre compte a été banni.'
             );
        }
    }

    public function checkPostAuth(UserInterface $user): void
    {
        // Test de l'email après authentification
        if (method_exists($user, 'isVerified') 
            && !$user->isVerified()) 
        {
            throw new CustomUserMessageAccountStatusException(
                'Votre adresse email n'est pas vérifiée.'
            );
        }
    }
}
```

Ensuite, il faut déclarer ce `UserChecker` dans la configuration du `firewall`.

```yaml
    firewalls:
        main:
            user_checker: App\Security\UserChecker
```

Et enfin ajouter les nouvelles propriétés à l'entité `User`, créer et exécuter la migration, puis ajouter deux nouveaux utilisateurs aux fixtures pour tester

```
Symfony console make:entity User
```

Ajoutons deux boooléens `banned` et `verified`.

```
Symfony console make:migration
```

```
Symfony console doctrine:migrations:migrate
```

Par défaut ces deux booléens sont faux.
```php
// src/Entity/User.php

#[ORM\Column]
    private bool $banned = false;

    #[ORM\Column]
    private bool $verified = false;
```

```php
// src/DataFixtures/UserFixtures.php
// dans ma méthode load

$user = new User();
        $user->setEmail('banned@user.com')
             ->setUsername('le banni')
             ->setFirstName('Jean')
             ->setLastName('Valjean')
             ->setPassword(
            $this->passwordHasher->hashPassword(
                $user, '123'
            )
        );
        $manager->persist($user);
        
$user = new User();
        $user->setEmail('unverified@user.com')
             ->setUsername('unverified')
             ->setFirstName('Paul Enigme')
             ->setLastName('Victor')
             ->setPassword(
            $this->passwordHasher->hashPassword(
                $user, '123'
            )
        );
        $manager->persist($user);
```

## Multiples User Checkers

Dans le cas où nous devrions tester beaucoup de conditions différentes avant ou après l'authentification, il pourrait être judicieux de créer plusieurs classes afin de respecter la règle qui va qu'une classe n'est qu'une responsabilité. 

Ici, nous rencontrons un problème, en effet, nous ne pouvons déclarer qu'une classe dans la configuration du Firewall.

Il existe une solution :  
1. Nous créons une classe maîtresse avec le tag `security.user_checker`. Elle sera déclarée dans la configuration de le sécurité comme étant notre `user_checker`.
2. Dans cette classe, nous déclarons un tableau de checkers 
3. Dans les méthodes `checkPreAuth` et `checkPostAuth` nous bouclons sur les checkers pour exécuter leur méthode.

4. Il ne reste qu'à peupler ce tableau, pour ce faire, nous injectons le tableau dans le constructeur et taggons cette propriété comme suit : ` #[TaggedIterator('user_checker')]`. Désormais, tous les services portant le tag `user_checker` seront automatiquement collectés dans ce tableau.


#### La classe maitresse

```php
namespace App\Security;

use Symfony\Component\DependencyInjection\Attribute\TaggedIterator;
use Symfony\Component\Security\Core\User\UserCheckerInterface;
use Symfony\Component\Security\Core\User\UserInterface;

#[AsTaggedItem('security.user_checker')]
class CompositeUserChecker implements UserCheckerInterface
{
    /** @var iterable<UserCheckerInterface> */
    private iterable $checkers;

    public function __construct(
        #[TaggedIterator('user_checker')] 
        iterable $checkers
    ) {
        $this->checkers = $checkers;
    }

    public function checkPreAuth(UserInterface $user): void
    {
        foreach ($this->checkers as $checker) {
            $checker->checkPreAuth($user);
        }
    }

    public function checkPostAuth(UserInterface $user): void
    {
        foreach ($this->checkers as $checker) {
            $checker->checkPostAuth($user);
        }
    }
}
```

#### Les classes taggées avec `user_checker`

```php
namespace App\Security;

use Symfony\Component\DependencyInjection\Attribute\AsTaggedItem;
use Symfony\Component\Security\Core\User\UserCheckerInterface;
use Symfony\Component\Security\Core\User\UserInterface;
use Symfony\Component\Security\Core\Exception\AccountExpiredException;

#[AsTaggedItem('user_checker')]
class IsActiveUserChecker implements UserCheckerInterface
{
    public function checkPreAuth(UserInterface $user): void
    {
        if (!$user->isActive()) {
            throw new AccountExpiredException('
                Le compte n'est plus actif.'
            );
        }
    }

    public function checkPostAuth(UserInterface $user): void
    {
        // Pas de code pour ce cas
    }
}
```

```php
namespace App\Security;

use Symfony\Component\DependencyInjection\Attribute\AsTaggedItem;
use Symfony\Component\Security\Core\User\UserCheckerInterface;
use Symfony\Component\Security\Core\User\UserInterface;
use Symfony\Component\Security\Core\Exception\CustomUserMessageAccountStatusException;

#[AsTaggedItem('user_checker')]
class IsBannedUserChecker2 implements UserCheckerInterface
{
    public function checkPreAuth(UserInterface $user): void
    {
        if ($user->isBanned()) {
            throw new CustomUserMessageAccountStatusException(
                'Cet utilisateur est banni.'
            );
        }
    }

    public function checkPostAuth(UserInterface $user): void
    {
        // pas de code pour ce cas
    }
}

```

### Avantages de cette solution

- Chaque classe ne porte qu'une seule responsabilité (SRP).
- Il est possible de tester chaque checker individuellement.
- Il est facile d'ajouter une nouvelle règle sans avoir à modifier le code existant (Open/Close).

## Conclusions

Le UserChecker est un moyen puissant de bloquer un utilisateur avant ou après l'authentification en fonction de son statut. Il est idéal pour : 

- Empêcher la connexion des comptes bannis.
- Vérifier si un utilisateur a activé son compte.
- Ajouter des contrôles de sécurité supplémentaires (ex: expiration du compte, double authentification, etc.).
- Forcer la réinitialisation du mot de passe après X jours.
- Bloquer un utilisateur après trop d'échecs de connexion.
- Empêcher l'accès aux comptes inactifs depuis trop longtemps.
- Vérifier si l'utilisateur a accepté les nouvelles conditions d'utilisation.
- Vérifier si l'utilisateur est à jour de sa cotisation.
- Bloquer l'accès selon l'adresse IP (liste noire).
- Désactiver temporairement la connexion (Maintenance Mode), seuls les admin peuvent se connecter.
- Vérifier si l’utilisateur s’est connecté depuis un appareil inconnu (user-agent).
- Restreindre l'accès à certaines périodes (heures de bureau par exemple).

### Pourquoi utiliser UserChecker plutôt qu’un autre mécanisme ?
- Automatique : Il est exécuté avant ou après chaque connexion.
- Sécurisé : Empêche les connexions non autorisées sans modifier le contrôleur.
- Centralisé : Toutes les règles de sécurité sont regroupées au même endroit.
- Facile à étendre : On peut ajouter des règles en fonction des besoins.

## Exercice

Implémenter un des cas évoqué dans les conclusions.
