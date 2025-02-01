# Variables globales

## Objectifs

- Identifier les variables du framework disponibles dans les vues
- Lister les solutions pour créer nos propres variables globales

## Les variables du framework

Symfony injecte automatiquement une variable app dans tous les templates Twig. Cette variable donne accès à diverses informations de l'application :

- `app.user` : L'utilisateur courant ou null si non authentifié
- `app.request` : L'objet Request courant
- `app.session` : L'objet Session courant
- `app.flashes` : Les messages flash stockés en session
- `app.environment` : L'environnement courant (dev, prod, etc.)

```twig

<p> 
Votre adresse IP est : 
{{ app.request.clientIP }}
</p>

<p> 
La route Symfony est : 
{{ app.request.attributes.get('_route') }}
</p>

<p>
L'URL est : 
La route Symfony est : 
{{ app.request.requesturi }}
</p>

<p>
Votre user agent est : 
{{ app.request.headers.get('User-Agent') }}
</p>
```

## Variables globales personnalisées

### La configuration Twig

Si notre "variable" est en fait une constante, le plus simple est de la déclarer dans la configuration de Twig.

```yaml
# config/packages/twig.yaml
twig:
    globals:
        site_name: 'Mon Site Web'
        contact_email: 'contact@monsite.com'
```

```twig
<h1>Vous êtes sur {{ site_name }}</h1>

vous pouvez me contacter à {{ contact_email }}
```

Très simple, mais les valeurs sont statiques.

Si les variables doivent également être disponibles pour les classes et pas seulement pour les vues, il sera judicieux de déclarer ces variables dans la clef `parameters` de `services.yaml`.

```yaml
# config/services.yaml
parameters:
    app.siteName: 'Mon Site Web'
    app.contactEmail: 'contact@monsite.com'
```

Et d'y faire ensuite référence dans la configuration de Twig

```yaml
# config/packages/twig.yaml
twig:
    globals:
        site_name: '%app.siteName%'
        contact_email: '%app.contactEmail'
```

> Notons que le nom des paramètres est arbitraire, nous aurions pu utiliser les mêmes noms que pour les variables Twig

### Les extensions Twig

Si l'information que nous souhaitons partager est dynamique, la solution précédente ne sera pas satisfaisante. Pour gérer ce cas, nous utiliserons une extension Twig.

l'attribut PHP `#[AsTaggedItem('twig.extension')]` marque ce service comme une extension Twig et le rend disponible pour toutes les vues.

La méthode `getGlobals` retourne un tableau de toutes les variables que nous souhaitons rendre disponible pour nos vues.

```php
// src/Twig/AppContextExtension

namespace App\Twig;

use Symfony\Component\DependencyInjection\Attribute\AsTaggedItem;
use Twig\Extension\AbstractExtension;
use Twig\Extension\GlobalsInterface;

#[AsTaggedItem('twig.extension')]
class AppContextExtension extends AbstractExtension implements GlobalsInterface
{
    public function getGlobals(): array
    {
        return [
            'currentYear' => date('Y'),
        ];
    }
}
```
#### Fonctions Twig

Nous pouvons également exposer des fonctions avec la méthode `getFunctions`.

Imaginons un service météo 

```php
// src/Service/WeatherService.php

namespace App\Service;

class WeatherService
{
    const array locations = [
        'Paris' => 'Temps couvert',
        'Madrid' => 'Il fait beau',
        'Vladivostok' => 'On se pèle'
    ];
    public function getWeather(string $location): string
    {
        return self::locations[$location] 
                    ?? "Pas d'infos pour cette ville";
    }
}
```

Nous ajoutons la méthode `getFunctions` à notre extension et nous injectons également le service dans le constructeur.

```php
// src/Twig/AppContextExtension.php

#[AsTaggedItem('twig.extension')]
class AppContextExtension extends AbstractExtension implements GlobalsInterface
{


    public function __construct(
        private WeatherService $weatherService
    ) {}

    public function getGlobals(): array
    {
        return [
            'currentYear' => date('Y'),
        ];
    }

    public function getFunctions()
    {
        return [
            new TwigFunction('get_weather', [
                $this->weatherService,
                'getWeather'
            ]),
        ];
    }
}
```

Nous pouvons ensuite utiliser le service dans les vues comme ceci :

```twig
{{ get_weather('Paris') }}
```

#### Filtre Twig

Les extensions Twig peuvent également définir de nouveaux filtres. Imaginons un service qui expose une fonction de réduction de texte.

```php
// src/Service/TextUtils.php

namespace App\Service;

class TextUtils
{

    public function truncateText(
        string $text,
        int $maxLength = 50): string
    {
        if (strlen($text) <= $maxLength) {
            return $text;
        }

        return substr($text, 0, $maxLength) . '...';
    }
}
```

```php
// src/Twig/AppContextExtension.php

#[AsTaggedItem('twig.extension')]
class AppContextExtension extends AbstractExtension implements GlobalsInterface
{

    public function __construct(
        private WeatherService $weatherService,
        private TextUtils $textUtils
    ) {}

    public function getGlobals(): array
    {
        return [
            'currentYear' => date('Y'),
        ];
    }

    public function getFunctions(): array
    {
        return [
            new TwigFunction('get_weather', [
                $this->weatherService,
                'getWeather'
            ]),
        ];
    }

    public function getFilters(): array {
        return [
            new TwigFilter('truncate', [
                $this->textUtils,
                'truncateText'
            ]),
        ];
    }
}
```

```twig
{{ 'Il était une fois dans un pays' | truncate(20) }}
```




