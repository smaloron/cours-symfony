# Sécurité

## Objectifs

- Identifier le fonctionnement de la sécurité dans Symfony
- Utiliser les outils de Symfony pour rapidement mettre en place la sécurité

## Installation

```bash
composer require security
```
Flex génère deux nouveaux fichiers `security.yaml`. Un dans `config/packages` et un autre dans `config/routes`.

```yaml
# config/routes/security.yaml

_security_logout:
    resource: security.route_loader.logout
    type: service
```

```yaml
# config/packages/security.yaml

security:
    # https://symfony.com/doc/current/security.html#registering-the-user-hashing-passwords
    password_hashers:
        Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface: 'auto'
    # https://symfony.com/doc/current/security.html#loading-the-user-the-user-provider
    providers:
        users_in_memory: { memory: null }
    firewalls:
        dev:
            pattern: ^/(_(profiler|wdt)|css|images|js)/
            security: false
        main:
            lazy: true
            provider: users_in_memory

            # activate different ways to authenticate
            # https://symfony.com/doc/current/security.html#the-firewall

            # https://symfony.com/doc/current/security/impersonating_user.html
            # switch_user: true

    # Easy way to control access for large sections of your site
    # Note: Only the *first* access control that matches will be used
    access_control:
        # - { path: ^/admin, roles: ROLE_ADMIN }
        # - { path: ^/profile, roles: ROLE_USER }

when@test:
    security:
        password_hashers:
            # By default, password hashers are resource intensive and take time. This is
            # important to generate secure password hashes. In tests however, secure hashes
            # are not important, waste resources and increase test times. The following
            # reduces the work factor to the lowest possible values.
            Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface:
                algorithm: auto
                cost: 4 # Lowest possible value for bcrypt
                time_cost: 3 # Lowest possible value for argon
                memory_cost: 10 # Lowest possible value for argon
```

#### password_hashers
Indique l'algorithme utilisé pour hacher les mots de passe. Il est possible de définir un algorithme différent pour chaque classe ou interface possédant un mot de passe. 

Symfony dispose d'un service de hachage de mot de passe qui implémente `UserPasswordHasherInterface` et utilisera le bon algorithme en fonction de la classe qui sera passée en argument.

#### providers
Dans la clef `providers`, nous indiquons la source d'authentification. Il y a ici quatre options :

- **entity** : Le cas le plus fréquent, les informations d'authentification résident dans une entité Doctrine.
- **ldap** : Les informations d'authentification sont récupérées depuis un annuaire LDAP. Cette option est utilisée pour créer une application intranet dans laquelle nous récupérons l'authentification du réseau.
- **memory** : Les informations d'authentification résident dans le fichier `security.yaml` lui-même ou dans un autre fichier `yaml` inclus dans `security`.
- **chain** : Les informations d'authentification résident dans plusieurs sources. Cette option existe, car un `firewall` Symfony ne peut avoir qu'un seul provider. 

#### firewall
Le `firewall` détermine quelles parties de notre application sera sécurisée et quelles règles seront appliquées. Dans la plupart des cas, nous n'avons be soin que de deux firewalls, `dev` qui désactive la sécurité pour les assets et `main` qui sécurise tout ou partie de l'application.

## Mise en place de la sécurité

### Une classe User

Commençons par définir une classe User. 

```bash
symfony console make:user
```

![CleanShot 2025-01-29 at 08.35.23@2x.png](CleanShot 2025-01-29 at 08.35.23@2x.png)

Nous constatons que Symfony a modifié le fichier `security.yaml`.

```yaml
    providers:
        # used to reload user from session & other features (e.g. switch_user)
        app_user_provider:
            entity:
                class: App\Entity\User
                property: username
```

```yaml
   main:
       lazy: true
       provider: app_user_provider
```

Et qu'il a également créé ou modifié la classe User.

- La classe implémente `UserInterface`.
- La classe implémente `PasswordAuthenticatedUserInterface`.
- Nous avons de nouvelles propriétés et méthodes
  - `username` comme nous l'avons défini lors de l'exécution de `make:user`.
  - `roles` qui stocke un tableau des roles de l'utilisateur
  - `password` qui stocke le mot de passe haché
  - `getUserIdentifier()` retourne la propriété utilisée comme identifiant.
  - `eraseCredentials()` qui sera invoquée avant la sérialisation de l'objet User et supprimera les informations confidentielles comme un éventuel mot de passe en clair.

```php
<?php

namespace App\Entity;

use App\Repository\UserRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface;
use Symfony\Component\Security\Core\User\UserInterface;

#[ORM\Entity(repositoryClass: UserRepository::class)]
#[ORM\Table(name: '`user`')]
#[ORM\UniqueConstraint(name: 'UNIQ_IDENTIFIER_USERNAME', fields: ['username'])]
class User implements UserInterface, PasswordAuthenticatedUserInterface
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(length: 180)]
    private ?string $username = null;

    /**
     * @var list<string> The user roles
     */
    #[ORM\Column]
    private array $roles = [];

    /**
     * @var string The hashed password
     */
    #[ORM\Column]
    private ?string $password = null;

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getUsername(): ?string
    {
        return $this->username;
    }

    public function setUsername(string $username): static
    {
        $this->username = $username;

        return $this;
    }

    /**
     * A visual identifier that represents this user.
     *
     * @see UserInterface
     */
    public function getUserIdentifier(): string
    {
        return (string) $this->username;
    }

    /**
     * @see UserInterface
     *
     * @return list<string>
     */
    public function getRoles(): array
    {
        $roles = $this->roles;
        // guarantee every user at least has ROLE_USER
        $roles[] = 'ROLE_USER';

        return array_unique($roles);
    }

    /**
     * @param list<string> $roles
     */
    public function setRoles(array $roles): static
    {
        $this->roles = $roles;

        return $this;
    }

    /**
     * @see PasswordAuthenticatedUserInterface
     */
    public function getPassword(): ?string
    {
        return $this->password;
    }

    public function setPassword(string $password): static
    {
        $this->password = $password;

        return $this;
    }

    /**
     * @see UserInterface
     */
    public function eraseCredentials(): void
    {
        // If you store any temporary, sensitive data on the user, clear it here
        // $this->plainPassword = null;
    }
}
```

Notre entité possède de nouvelles propriétés liées à Doctrine, il faut donc créer une nouvelle migration et l'exécuter.

```
symfony console make:migration
```

```
symfony console doctrine:migrations:migrate
```

### Création du formulaire de login

```
symfony console make:security:form-login
```

Ajoute un nouveau contrôleur et une nouvelle vue

```php
<?php

namespace App\Controller;

use App\Entity\User;
use App\Repository\UserRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Authentication\AuthenticationUtils;

class SecurityController extends AbstractController
{
    #[Route(path: '/login', name: 'app_login')]
    public function login(
        AuthenticationUtils $authenticationUtils
    ): Response
    {
        // get the login error if there is one
        $error = $authenticationUtils->getLastAuthenticationError();

        // last username entered by the user
        $lastUsername = $authenticationUtils->getLastUsername();

        return $this->render('security/login.html.twig', [
            'last_username' => $lastUsername,
            'error' => $error,
        ]);
    }

    #[Route(path: '/logout', name: 'app_logout')]
    public function logout(): void
    {
        throw new \LogicException(
            "This method can be blank 
            - it will be intercepted 
            by the logout key on your firewall."
        );
    }
}
```

Et une modification dans `security.yaml`

```yaml
 form_login:
     login_path: app_login
     check_path: app_login
     enable_csrf: true
 logout:
     path: app_logout
```

### Fixtures

Pour tester le login, il nous faut des utilisateurs.

Nous injectons le service de hachage des mots de passe dans le constructeur. Ce service utilisera la configuration dans `service.yaml` pour déterminer l'algorithme à utiliser.

```
symfony make:fixtures
```

```php
<?php

namespace App\DataFixtures;

use App\Entity\User;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;

class UserFixtures extends Fixture
{
    public function __construct(
        private UserPasswordHasherInterface $passwordHasher
    ) {}

    public function load(
        ObjectManager $manager,
    ): void
    {
        // Un admin
        $user = new User();
        $user->setUsername('admin');
        $user->setRoles(['ROLE_ADMIN']);
        $user->setPassword(
            $this->passwordHasher->hashPassword(
                $user, '123'
            )
        );
        $manager->persist($user);

        // Un utilisateur lambda
        $user = new User();
        $user->setUsername('user');
        $user->setPassword(
            $this->passwordHasher->hashPassword(
                $user, '123'
            )
        );
        $manager->persist($user);


        $manager->flush();
    }
}
```

### Test du login

Si nous testons le formulaire de login avec des informations valides, nous obtenons une redirection vers la page d'accueil (Il est possible de modifier la route de redirection dans `security.yaml`).

Dans la `debugbar`, nous constatons que nous sommes authentifiés.

- Symfony a généré un token d'authentification, cette information réside dans la session et est chargée à chaque nouvelle requête.

- Dans l'onglet `Authenticators` nous constatons que Symfony a utilisé une classe `FormLoginAuthenticator`pour traiter le formulaire.

Le système de sécurité de Symfony est très souple, il permet de mettre en place de multiples stratégies d'authentification. Cependant, pour le cas le plus fréquent nous n'avons pas grand-chose à faire puisque tout est déjà géré par le Framework.

Si nous souhaitons définir des règles d'authentification alternatives, nous n'auront qu'à créer notre propre classe qui héritera de `AbstractAuthenticator`.

![CleanShot 2025-01-29 at 12.29.48@2x.png](CleanShot 2025-01-29 at 12.29.48@2x.png)

![CleanShot 2025-01-29 at 12.31.51@2x.png](CleanShot 2025-01-29 at 12.31.51@2x.png)

### Formulaire d'inscription

Pour inscrire un nouvel utilisateur, nous ajouterons une propriété `plainPassword` à la classe User.

Cette propriété ne sera pas liée à Doctrine, nous coderons donc cette modification à la main.

```php
// Dans scr/entity/User.php

private ?string $plainPassword = null;

public function getPlainPassword(): ?string
{
    return $this->plainPassword;
}

public function setPlainPassword(string $password): static
{
    $this->plainPassword = $password;

    return $this;
}
```

#### Création du formulaire

```
symfony console make:Form
```

Nous créons une classe `RegisterType` liée à l'entité `User`.

```php
// Dans src/Form/RegisterType.php


public function buildForm(FormBuilderInterface $builder, array $options): void
{
    $builder
        ->add('username', null, [
            'label' => 'Nom d\'utilisateur'
        ])
        ->add('roles', ChoiceType::class, [
            'choices' => [
                'Utilisateur' => 'ROLE_USER',
                'Administrateur' => 'ROLE_ADMIN']
            ,
            'expanded' => true,
            'multiple' => true,
        ])
        ->add('plainPassword', PasswordType::class, [
            'label' => 'Mot de passe'
        ])
    ;
}
```

Pour les rôles, nous utilisons un `ChoiceType`. Si d'aventure, nous souhaitions pouvoir ajouter des rôles, nous opterions pour un EntityType lié à une entité `Role`.

Concernant le mot de passe, nous pourrions également opter pour un `RepeatedType` afin de nous assurer de la bonne saisie de cette information cruciale.

#### L'affichage et le traitement du formulaire

```php
// Dans src/Controller/SecurityController

    #[Route(path: '/register', name: 'app_register')]
    public function register(
        Request $request,
        EntityManagerInterface $manager,
        UserRepository $repository,
        UserPasswordHasherInterface $passwordHasher
    ): Response
    {
        $user = new User();

        $form = $this->createForm(RegisterType::class, $user);
        $form->add('Valider', SubmitType::class);

        $form->handleRequest($request);

        if($form->isSubmitted() && $form->isValid()){

            // Test de l'existence d'un utilisateur avec le même username
            if($repository->findOneBy(['username' => $user->getUsername()])){
                $form->addError(
                    new FormError(
                        "Cet utilisateur {$user->getUsername()} existe déjà"
                    )
                );
            } else{
                // Hachage du mot de passe
                $user->setPassword(
                    $passwordHasher->hashPassword(
                        $user, $user->getPlainPassword()
                    )
                );
                
                // Persistance de l'entité
                $manager->persist($user);
                $manager->flush();

                // Message flash et redirection
                $this->addFlash('success', 'Vous êtes inscrit');
                return $this->redirectToRoute('app_login');
            }
        }

        return $this->render('security/register.html.twig', [
            'registerForm' => $form->createView(),
        ]);
    }
```

#### Factorisation

Essayez de déporter une partie de la logique dans un service afin de simplifier le contrôleur.


##### Correction {collapsible="true"}
```php
// Dans src/Service

<?php

namespace App\Service;

use App\Repository\UserRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Form\FormError;
use Symfony\Component\Form\FormInterface;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface;
use Symfony\Component\Security\Core\User\UserInterface;

class UserRegistrationService
{

    private UserInterface|PasswordAuthenticatedUserInterface $user;

    public function __construct(
        private UserRepository $userRepository,
        private EntityManagerInterface $entityManager,
        private UserPasswordHasherInterface $passwordHasher
    ) {
    }

    public function isUserAlreadyRegistered(
        FormInterface $form
    )
    {
        $foundUser = $this->userRepository->findOneBy(
            ['username' => $this->user->getUserIdentifier()]
        );

        if($foundUser){
            $form->addError(
                new FormError(
                    "Cet utilisateur 
                    {$this->user->getUserIdentifier()}
                     existe déjà"
                )
            );
            return true;
        }

        return false;
    }

    private function hashPassword():void{
        $this->user->setPassword(
            $this->passwordHasher->hashPassword(
                $this->user, 
                $this->user->getPlainPassword()
            )
        );
    }

    public function register(): void{
        $this->hashPassword();
        $this->entityManager->persist($this->user);
        $this->entityManager->flush();
    }

    public function setUser(
        UserInterface|PasswordAuthenticatedUserInterface $user
    ): void {
        $this->user = $user;
    }
}
```

Et le nouveau contrôleur

```php
#[Route(path: '/register', name: 'app_register')]
    public function register(
        Request $request,
        UserRegistrationService $registrationService
    ): Response
    {
        $user = new User();

        $form = $this->createForm(RegisterType::class, $user);
        $form->add('Valider', SubmitType::class);

        $form->handleRequest($request);

        $registrationService->setUser($user);

        // Test de l'existence d'un utilisateur avec le même username
        if($form->isSubmitted()
            && $form->isValid()
            && !$registrationService->isUserAlreadyRegistered($form))
        {
            // Création de l'utilisateur
            $registrationService->register();

            // Message flash et redirection
            $this->addFlash('success', 'Vous êtes inscrit');
            return $this->redirectToRoute('app_login');
        }

        return $this->render('security/register.html.twig', [
            'registerForm' => $form->createView(),
        ]);
    }
```

### Les autorisations

Une fois réglée la question de l'authentification, il faut se poser celle de l'autorisation. L'idée est de restreindre l'accès à certaines routes aux seuls utilisateurs qui possèdent un rôle donné.

#### Restrictions sur un ensemble de routes

La clef `access_control` de `security.yaml` permet d'associer un chemin à un ou plusieurs rôles. Ce chemin est une expression régulière qui sera testée sur la route de la requête.

```yaml
# dans config/packages/security.yaml

access_control:
  - { path: ^/admin, roles: ROLE_ADMIN }
```

#### Restrictions sur une route

Dans une action de contrôleur, nous pouvons restreindre l'accès comme ceci :

```php
$this->denyAccessUnlessGranted('ROLE_USER');
```

Nous pouvons également utiliser un attribut PHP pour faire la même chose. Un attribut pouvant être placé au-dessus d'une méthode ou d'une classe, cette solution nous permet de gérer les autorisations sur l'ensemble des routes d'un contrôleur. 

```php
#[IsGranted('ROLE_USER')]
```

##### Exemple

```php
#[Route('/article/form', name: 'app_article_form')]
    public function form(): Response
    {
        // Seuls les utilisateurs authentifiés
        // peuvent écrire des articles
        $this->denyAccessUnlessGranted('ROLE_USER');

        $article = new Article();
        // L'auteur de l'article est l'utilisateur authentifié
        $article->setAuthor($this->getUser());


        $form = $this->createForm(ArticleType::class, $article);

        return $this->render('article/form.html.twig', [
            'articleForm' => $form->createView(),
        ]);
    }
```

Ici, nous avons un problème, car l'entité Article attend une instance de Person et non de User. Un solution pourrait consister à mettre en place une relation d'héritage.

**Dans Person, nous ajoutons les informations concernant l'héritage.**

```php
#[ORM\InheritanceType("JOINED")]
#[ORM\DiscriminatorColumn(name: "type", type: "string")]
#[ORM\DiscriminatorMap([
  "user" => User::class, 
  "person" => Person::class]
 )]
class Person {
// code de la classe
}
```

**Dans User nous supprimons l'attribut id et héritons de Person.**

```php
#[ORM\Entity(repositoryClass: UserRepository::class)]
#[ORM\Table(name: '`user`')]
#[ORM\UniqueConstraint(name: 'UNIQ_IDENTIFIER_USERNAME', fields: ['username'])]
class User extends Person implements UserInterface, PasswordAuthenticatedUserInterface
{
// cde de la classe sans propriété id ni méthode getId()
}
```

**Suppression des utilisateurs existants**

Sans cela, il sera impossible d'exécuter la migration, car nos utilisateurs existants ne sont pas liés à une personne.

> Note : Les guillemets autour du nom de la table sont obligatoires avec PostgreSQL.
> 
```bash
symfony console doctrine:query:sql "TRUNCATE TABLE \"user\""
```

**Création et exécution des migrations.**

```bash
symfony console make:migration
```

```bash
symfony console doctrine:migrations:migrate
```

**Ajout des informations supplémentaires dans les fixtures**

```php
// Dans src/DataFixtures/UserFixtures.php

public function load(
        ObjectManager $manager,
    ): void
    {
        // Un admin
        $user = new User();
        $user->setUsername('admin');
        $user->setRoles(['ROLE_ADMIN']);
        $user->setFirstName('God');
        $user->setLastName('Almighty');
        $user->setPassword(
            $this->passwordHasher->hashPassword(
                $user, '123'
            )
        );
        $manager->persist($user);

        // Un utilisateur lambda
        $user = new User();
        $user->setUsername('user');
        $user->setFirstName('Joe');
        $user->setLastName('User');
        $user->setPassword(
            $this->passwordHasher->hashPassword(
                $user, '123'
            )
        );
        $manager->persist($user);


        $manager->flush();
    }
```

```bash
symfony console doctrine:fixtures:load
```


**Ajout des propriétés de Person dans le formulaire d'inscription**

```php
// Dans src/Form/RegisterType.php

public function buildForm(
  FormBuilderInterface $builder, 
  array $options
): void
{
   $builder
       ->add('firstName', TextType::class, [
           'label' => 'Prénom'
       ])
       ->add('lastName', TextType::class, [
           'label' => 'Nom'
       ])
       ->add('username', null, [
           'label' => 'Nom d\'utilisateur'
       ])
       ->add('roles', ChoiceType::class, [
           'choices' => [
               'Utilisateur' => 'ROLE_USER',
               'Administrateur' => 'ROLE_ADMIN']
           ,
           'expanded' => true,
           'multiple' => true,
       ])
       ->add('plainPassword', PasswordType::class, [
           'label' => 'Mot de passe'
       ])
   ;
}
```

## La sécurité dans Twig

Dès lors qu'un utilisateur est authentifié, nous pouvons récupérer ses informations dans une vue avec le code suivant :

```twig
{{ app.user }}
```

Ce qui nous permet de faire ceci par exemple

```twig
{% if app.user %}
    <h2>Bonjour {{ app.user.useridentifier }}</h2>
    <a href="{{ path('app_logout') }}">Logout</a>
{% else %}
    <a href="{{ path('app_login') }}">Login</a>
{% endif %}
```

### Tester les autorisations

La fonction `is_granted` permet de tester le rôle de l'utilisateur connecté

```twig
{% if is_granted('ROLE_ADMIN') %}
    Liens spécifiques à admin
{% endif %}
```

#### Etats de l'authentification

Symfony propose trois états supplémentaires qui peuvent être testés avec `is_granted`.

- `IS_AUTHENTICATED_ANONYMOUSLY` : s'applique à tous les utilisateurs même ceux qui ne sont pas authentifiés.

- `IS_AUTHENTICATED_REMEMBERED` : s'applique aux utilisateurs connectés automatiquement via un cookie `remember me`.

- `IS_AUTHENTICATED_FULLY` : s'applique aux utilisateurs qui se sont connectés via un `Authenticator`, par exemple en utilisant un formulaire de login.

#### Connection automatique
Pour activer la connection automatique via un cookie, il faut configurer le `firewall` comme ceci :

```yaml
firewalls:
    main:
        remember_me:
            secret: '%kernel.secret%'
            lifetime: 604800 # 1 semaine
            path: /
            always_remember_me: true
```

Nous pouvons également donner le choix à l'utilisateur. Dans ce cas, nous supprimons la clef `always_remember_me` et décommentons la section remember me dans `security/login.html.twig`.

```twig
<form method="post">
        {% if error %}
            <div class="alert alert-danger">{{ error.messageKey|trans(error.messageData, 'security') }}</div>
        {% endif %}

        {% if app.user %}
            <div class="mb-3">
                You are logged in as {{ app.user.userIdentifier }}, <a href="{{ path('app_logout') }}">Logout</a>
            </div>
        {% endif %}

        <h1 class="h3 mb-3 font-weight-normal">Please sign in</h1>
        <label for="username">Username</label>
        <input type="text" value="{{ last_username }}" name="_username" id="username" class="form-control" autocomplete="username" required autofocus>
        <label for="password">Password</label>
        <input type="password" name="_password" id="password" class="form-control" autocomplete="current-password" required>

        <input type="hidden" name="_csrf_token"
               value="{{ csrf_token('authenticate') }}"
        >

        {#
            Uncomment this section and add a remember_me option below your firewall to activate remember me functionality.
            See https://symfony.com/doc/current/security/remember_me.html

            <div class="checkbox mb-3">
                <input type="checkbox" name="_remember_me" id="_remember_me">
                <label for="_remember_me">Remember me</label>
            </div>
        #}

        <button class="btn btn-lg btn-primary" type="submit">
            Sign in
        </button>
    </form>
```




