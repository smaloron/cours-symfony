# Custom Authenticator

## Objectifs
- Définir un comportement d'authentification personnalisé
- Identifier le rôle du passeport et des badges

## Une classe Authenticator

Symfony utilise une classe `Authenticator` par défaut qui convient parfaitement pour le cas le plus fréquent. Nous pouvons cependant lui substituer notre propre logique si nos besoins diffèrent du comportement par défaut.

Pour ce faire, il faut créer une classe qui hérite de `AbstractAuthenticator`.

```php
// dans src/Security/CustomAuthenticator

namespace App\Security;

class CustomAuthenticator extends AbstractAuthenticator
{

    /**
    * Retourne un booléen indiquant si 
    * l'Authenticator doit être exécuté
    * Ici la route doit être /login et la méthode POST
    */
    public function supports(Request $request): ?bool
    {
        return $request->attributes->get('_route') === 'app_login' && $request->isMethod('POST');
    }

    /**
    * Authentifie l'utilisateur
    */
    public function authenticate(Request $request): Passport
    {
        // Informations saisies
        $email = $request->request->get('email');
        $password = $request->request->get('password');

        return new Passport(
            new UserBadge($email),
            new PasswordCredentials($password)
        );
    }

    /**
    * Code a éxécuter en cas de succès
    */
    public function onAuthenticationSuccess(Request $request, TokenInterface $token, string $firewallName): ?Response
    {
        return new Response('Authentication successful', Response::HTTP_OK);
    }

    /**
    * Code a éxécuter en cas d'échec
    */
    public function onAuthenticationFailure(Request $request, AuthenticationException $exception): ?Response
    {
        return new Response('Authentication failed', Response::HTTP_UNAUTHORIZED);
    }
}
```

Il faut ensuite changer la configuration de la sécurité comme suit :

```yaml
firewalls:
        main:
            custom_authenticators:
                - App\Security\CustomAuthenticator
```

### Le passeport
Un Passport est une structure qui regroupe toutes les informations nécessaires pour valider une authentification. Il est utilisé par le Authenticator pour vérifier si l'utilisateur peut accéder à l'application.

Un Passport contient :

- Les informations d’identification (ex. : nom d'utilisateur, mot de passe, token…).
- Les badges (qui définissent des exigences supplémentaires, comme la vérification du mot de passe ou la vérification en deux étapes).

Le principal avantage du Passport est qu'il permet de séparer la logique d'authentification et les exigences de sécurité.

#### Quelques types de passports

Symfony propose plusieurs types de Passport via l'interface `Symfony\Component\Security\Http\Authenticator\Passport\PassportInterface`.

##### SelfValidatingPassport
Il est utilisé lorsqu'il n'y a pas besoin de vérifier le mot de passe, comme pour :

- Une authentification via un jeton (API token, JWT…).
- Une authentification par clé publique.

```php
$passport = new SelfValidatingPassport(new UserBadge('username'));
```

##### Passport classique

Ce type de Passport est utilisé lorsque des identifiants doivent être validés (ex. : nom d'utilisateur et mot de passe).

```php
$passport = new Passport(
    new UserBadge('username'),
    new PasswordCredentials('password')
);
```

### Les badges
 Outre `UserBadge` et `PasswordCredentials`, Symfony propose, un système de badges optionnels qui ajoutent des règles supplémentaires à l'authentification.

- `CsrfTokenBadge` : Utilisé pour vérifier la présence et la validité du token CSRF du formulaire de login.
- `TwoFactorCodeBadge` : Utilisé pour l'athentification à deux facteurs.
- `RememberMeBadge` : Utilisé pour l'authentification automatique pas cookie.
- `UserCheckerBadge` : Utilisé pour vérifier des conditions supplémentaires pour valider un utilisateur (compte actif, non banni ...)

Nous pouvons également coder nos propres badges pour ajouter des règles métiers.



## Identifiants multiples

Imaginons que nous souhaitions identifier les utilisateurs avec leur nom d'utilisateur, mais également leur adresse e-mail. Par défaut Symfony, ne nous permet de définir qu'une seule information qui portera l'identification. Il nous faut donc créer une classe personnalisée pour implémenter ce comportement de double information pour l'authentification.

### Mise en place

Commençons par ajouter une propriété pour l'adresse e-mail au sein de l'entité.

```bash
symfony console make:entity User
```

Nous précisons également dans les attributs PHP, que l'adresse e-mail doit être unique. Ceci est important puisque nous allons rechercher des utilisateurs selon cette adresse e-mail.

L'adresse e-mail est déclarée comme nullable. En effet, nous avons déjà des utilisateurs enregistrés dans la base de données et donc la migration échoua. Si l'adresse e-mail ne peut être nulle. Après la migration et l'exécution des fixtures, nous pourrons modifier cet attribut.

```php
#[ORM\Column(length: 50, unique: true, nullable: true)]
    private ?string $email = null;
```

Ensuite, nous créons la migration et nous l'exécutons.

```bash
symfony console make:migration
```

```bash
symfony console doctrine:migrations:migrate
```

#### Les fixtures

Nous ajoutons la propriété e-mail à nos fixtures.

```php
// src/DataFixtures/UserFixtures.php

public function load(
        ObjectManager $manager,
    ): void
    {
        // Un admin
        $user = new User();
        $user->setEmail('god@heaven.com')
             ->setUsername('admin')
             ->setRoles(['ROLE_ADMIN'])
             ->setFirstName('God')
             ->setLastName('Almighty')
             ->setPassword(
                 $this->passwordHasher->hashPassword(
                     $user, '123'
                 )
             );
        $manager->persist($user);

        // Un utilisateur lambda
        $user = new User();
        $user->setEmail('joe@user.com')
             ->setUsername('user')
             ->setFirstName('Joe')
             ->setLastName('User')
             ->setPassword(
                $this->passwordHasher->hashPassword(
                    $user, '123'
                )
             );
             
        $manager->persist($user);

        $manager->flush();
    }
```

#### Le formulaire

Nous modifions également le formulaire d'inscription.

```php
// dans src/Form/RegisterType.php

->add('email', EmailType::class, [
               'label' => 'Adresse email'
])
```

### Une requête dans le repository

Ensuite, nous aurons besoin d'une requête pour récupérer un utilisateur en fonction d'un identifiant que nous rechercher dans les colonnes `username` ou `email`.

Nous ajouterons donc une nouvelle requête dans le repository de l'entité User.

```php
// dans src/Repository/UserRepository.php

public function findOneByEmailOrUserName(string $identifier): ?User{
    return $this->createQueryBuilder('u')
        ->andWhere('u.email = :identifier OR u.username = :identifier')
        ->setParameter('identifier', $identifier)
        ->getQuery()
        ->getOneOrNullResult()
    ;
}
```

### La classe Authenticator

```php
<?php

namespace App\Security;

use App\Repository\UserRepository;
use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Generator\UrlGeneratorInterface;
use Symfony\Component\Security\Core\Authentication\Token\TokenInterface;
use Symfony\Component\Security\Core\Exception\AuthenticationException;
use Symfony\Component\Security\Http\Authenticator\AbstractAuthenticator;
use Symfony\Component\Security\Http\Authenticator\Passport\Badge\CsrfTokenBadge;
use Symfony\Component\Security\Http\Authenticator\Passport\Badge\UserBadge;
use Symfony\Component\Security\Http\Authenticator\Passport\Credentials\PasswordCredentials;
use Symfony\Component\Security\Http\Authenticator\Passport\Passport;

class AppAuthenticator extends AbstractAuthenticator
{
    public function __construct(
        private UserRepository $userRepository,
        private UrlGeneratorInterface $urlGenerator
    ) {}


    /**
     * @inheritDoc
     */
    public function supports(Request $request): ?bool
    {
        return  $request->attributes->get('_route') === 'app_login'
                && $request->isMethod('POST');
    }

    /**
     * @inheritDoc
     */
    public function authenticate(Request $request): Passport
    {
        // Récupération des données du formulaire de login
        $identifier = $request->request->get('_username', '');
        $password = $request->request->get('_password');
        $csrfToken = $request->request->get('_csrf_token');


        if (!$identifier || !$password) {
            throw new AuthenticationException(
                "Informations d'authentification incomplètes"
            );
        }

        // Check if identifier is email or username
        $user = $this->userRepository
                     ->findOneByEmailOrUserName($identifier);


        if (!$user) {
            throw new AuthenticationException('utilisateur inconnu.');
        }

        return new Passport(
            new UserBadge($user->getUsername()),
            new PasswordCredentials($password),
            [
                new CsrfTokenBadge(
                    'authenticate', $csrfToken
                )
            ]
        );
    }

    /**
     * @inheritDoc
     */
    public function onAuthenticationSuccess(
        Request $request, 
        TokenInterface $token, 
        string $firewallName): ?Response
    {
        // Récupération de la cible de redirection
        $targetPath = $request->getSession()->get(
            "_security.$firewallName.target_path"
        );

        // Redirection
        return new RedirectResponse($targetPath ?? '/');

    }

    /**
     * @inheritDoc
     */
    public function onAuthenticationFailure(
        Request $request, 
        AuthenticationException $exception): ?Response
    {
        // définition d'un message flash
        $request->getSession()
                ->getBag('flashes')
                ->add(
                    'error',
                    'Identifiant ou mot de passe incorrect'
                );
        
        // Redirection vers la route de login
        return new RedirectResponse(
            $this->urlGenerator->generate('app_login')
        );
    }
}
```

N'oublions pas de déclarer notre classe d'authentification dans la configuration de la sécurité.

```yaml
# dans config/packages/security.yaml
    firewalls:
        main:
            custom_authenticators:
                - App\Security\AppAuthenticator

```

<!-- TODO  
UserCheckerBadge
Custom badge (business hours)
Api token authentication
JWT

-->
