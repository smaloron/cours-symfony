# Les voters

## Objectifs

- Utiliser les voters pour définir des autorisations contextuelles

## Le principe

Parfois l'autorisation d'accès à une ressource dépend du contexte. Nous ne pouvons alors, nous contenter de tester le rôle de l'utilisateur. 

Par exemple, dans le cas d'une application où les auteurs écrivent des articles, l'autorisation de modification de l'article pourrait dépendre du fait que l'utilisateur authentifié soit l'auteur de cet article. Il ne suffit donc pas de tester que l'utilisateur possède un rôle particulier.

Pour traiter cette question Symfony utilise des classes Voters.

## Mise en place

### Création du voter

Nous disposons d'une commande console pour créer le code des voters.

```
symfony console make:voter
```

```php
<?php
namespace App\Security\Voter;

use App\Entity\Article;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Authentication\Token\TokenInterface;
use Symfony\Component\Security\Core\Authorization\Voter\Voter;
use Symfony\Component\Security\Core\User\UserInterface;

class ArticleVoter extends Voter
{
    // Définition des actions possibles sur l'entité Article
    public const EDIT = 'ARTICLE_EDIT';
    public const DELETE = 'ARTICLE_DELETE';

    // Injection du service Security dans le constructeur
    public function __construct(private Security $security) {}

    /**
     * Vérifie si ce Voter doit être appliqué au cas donné.
     *
     * @param string $attribute L'action demandée (ex: ARTICLE_EDIT, ARTICLE_DELETE)
     * @param mixed $subject L'objet sur lequel on veut appliquer l'autorisation (ici un Article)
     * @return bool True si le Voter doit gérer cette vérification, sinon False
     */
    protected function supports(string $attribute, mixed $subject): bool
    {
        return in_array($attribute, [self::EDIT, self::DELETE]) 
                        && $subject instanceof Article;
    }

    /**
     * Vérifie si l'utilisateur a l'autorisation pour effectuer l'action donnée sur le Post
     *
     * @param string $attribute L'action demandée (POST_EDIT ou POST_DELETE)
     * @param mixed $subject L'objet concerné (ici un Post)
     * @param TokenInterface $token Le token de l'utilisateur connecté
     * @return bool True si l'utilisateur a l'autorisation, sinon False
     */
    protected function voteOnAttribute(
        string $attribute, 
        mixed $subject, 
        TokenInterface $token
    ): bool
    {
        $user = $token->getUser();

        // Si l'utilisateur n'est pas connecté, il n'a pas d'autorisation
        if (!$user instanceof UserInterface) {
            return false;
        }

        /** @var Article $article */
        $article = $subject;

        // L'administrateur a toujours tous les droits
        if ($this->security->isGranted('ROLE_ADMIN')) {
            return true;
        }

        // Vérification spécifique selon l'action demandée
        return match ($attribute) {
            self::EDIT => $this->canEdit($article, $user),
            self::DELETE => $this->canDelete($article, $user),
            default => false,
        };
    }

    /**
     * Vérifie si l'utilisateur peut modifier un Article
     *
     * @param Article $article L'article à modifier
     * @param UserInterface $user L'utilisateur en cours
     * @return bool True si l'utilisateur est l'auteur de l'article, sinon False
     */
    private function canEdit(
        Article $article, 
        UserInterface $user
    ): bool
    {
        return $article->getAuthor() === $user;
    }

    /**
     * Vérifie si l'utilisateur peut supprimer un Post
     *
     * @param Article $article L'article à supprimer
     * @param UserInterface $user L'utilisateur en cours
     * @return bool True si l'utilisateur est l'auteur du Post ou a le rôle "MODERATOR"
     */
    private function canDelete(
        Article $article, 
        UserInterface $user
    ): bool
    {
        return $article->getAuthor() === $user || $this->security->isGranted('ROLE_MODERATOR');
    }
}
```

### Utilisation du voter

#### Dans un contrôleur

```php
$this->denyAccessUnlessGranted('ARTICLE_EDIT', $article);
```

ou

```
#[IsGranted('ARTICLE_DELETE', 'article')]
```

##### Exemple

```php
class ArticleController extends AbstractController
{
    #[Route('/article/{id}/edit', name: 'article_edit')]
    public function edit(Article $article): Response
    {
        $this->denyAccessUnlessGranted('ARTICLE_EDIT', $article);

        // Si on arrive ici, c'est que l'utilisateur a la permission
        return new Response('Formulaire d\'édition');
    }

    #[Route('/post/{id}/delete', name: 'post_delete')]
    #[IsGranted('POST_DELETE', 'article')]
    // le deuxième argument de IsGranted fait référence
    // à l'argument $article passé à la méthode delete
    public function delete(Article $article): Response
    {
        // L'utilisateur a la permission de supprimer
        return new Response('Post supprimé !');
    }
}
```

#### Dans une vue

```twig
{% if is_granted('ARTICLE_EDIT', article) %}
    <a href="{{ path('article_edit', { id: article.id }) }}">Modifier</a>
{% endif %}

{% if is_granted('ARTICLE_DELETE', article) %}
    <a href="{{ path('article_delete', { id: article.id }) }}">Supprimer</a>
{% endif %}
```

## Quelques Cas d'utilisation des voters

Contrôler l'accès à l'édition et la suppression d'une entité.
: Seul le créateur peut modifier ou supprimer.

Autoriser l'accès à une ressource uniquement pendant une période donnée.
: Un utilisateur ne peut modifier un document qu'avant la deadline.

Restreindre l'accès en fonction du statut d'une entité.
: Un utilisateur ne peut modifier un ticket si celui-ci a été clôturé.

Autoriser l'accès en fonction d'un groupe ou d'une équipe
: Un utilisateur peut voir un projet uniquement s'il fait partie de l'équipe.

Vérifier si l'utilisateur a déjà effectué une action sur une ressource.
: Un utilisateur ne peut "liker" qu'une seule fois.

Restreindre l'accès en fonction du nombre de ressources possédées.
: Un utilisateur ne peut créer que 5 articles maximum, sauf s'il a un rôle ROLE_PREMIUM.