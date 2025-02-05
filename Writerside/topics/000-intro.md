# Introduction

## Objectif

L’objectif de ce document est d’apprendre à installer un projet Symfony et tester notre installation en lançant un
serveur.

## Les outils

- PHP 8.4
- Visual Studio Code ou PHPStorm
- Docker
- Composer

## Présentation de Symfony

Symfony est un cadre de travail ou framework PHP, qui propose une architecture moderne pour la réalisation d’application
Web.
Les avantages d’utiliser un framework en général et Symfony, en particulier, sont multiples :

- La rapidité, Symfony propose des outils de génération de code qui font gagner du temps. En outre, le framework expose
  de nombreuses classes pour résoudre les problèmes récurrents que se posent tous les développeurs d’application Web.
- La fiabilité, le code de Symfony a été testé par la communauté et sera sans doute plus robuste que celui de notre
  propre solution maison.
- La sécurité, par défaut Symfony intègre les bonnes pratiques de sécurité
- L’architecture, Symfony promeut une architecture moderne et nous guide vers les bonnes pratiques
- La maintenance, Symfony permet un degré de factorisation qui facilite grandement la maintenance de notre application

## Installation

Bien que non strictement indispensable, il est toutefois fortement conseillé d’installer et d’utiliser l’outil console
développé par Sensio Labs (l’éditeur de Symfony) pour travailler avec Symfony.

[Téléchargement de Symfony CLI](https://symfony.com/download)

Pour Windows, le plus simple est de choisir l’option `download binaries` et de placer le fichier `symfony.phar` dans un dossier déclaré dans la variable d’environnement `PATH`.

### Les prérequis

```symfony check:requirements```

Cette commande console vérifie si notre configuration est compatible avec Symfony

### Création d’un projet

Pour créer un nouveau projet Symfony, il suffit d’ouvrir un terminal et de saisir la commande suivante :

```symfony new [dossier]```

> Où `[dossier]`représente le nom du dossier dans lequel Symfony enregistrera les fichiers du projet.  
> Attention, le dossier ne doit pas déjà exister, car Symfony ne veut pas prendre le risque d’écraser nos fichiers.

### Lancement du serveur

Pour tester le projet, il faut un serveur Web. Heureusement Symfony CLI permet de lancer simplement un tel serveur.

1. Tout d’abord, on se déplace dans le dossier de notre projet Symfony avec la commande `cd`(change directory).
2. Ensuite, on lance le serveur avec la commande`symfoy serve -d`. L’option `-d`indique que le processus doit tourner
   en arrière-plan (en mode daemon) et ainsi libérer la console.

```
cd [dossier]
symfony serve -d
```

![000-intro-symfony-landing-page.png](000-intro-symfony-landing-page.png)

### L’arborescence du projet

![arborescence d’un projet Symfony](000-intro-arborescence-premier-projet-symfony.gif)

Comme on peut le constater, Symfony a bien travaillé et a généré une quantité de fichiers et de dossiers pour mettre en
place notre projet.

<deflist type="medium">
    <def title="bin">
        Ce dossier contient les outils binaires qui nous aideront à créer notre application.
    </def>
    <def title="config">
        Ce dossier contient les fichiers de configuration de l’application. Il abrite principalement des fichiers au format <code>YAML</code>.
    </def>
    <def title="public">
        Ce dossier est le seul qui soit exposé sur le web, il s’agit de la racine du serveur Symfony et du point d’entrée de toutes les requêtes.
    </def>
    <def title="var">
        Ce dossier est utilisé par Symfony pour stocker les fichiers dont il a besoin pendant l’exécution de l’application. Il abrite principalement le cache (fichiers de travail qui améliorent la vitesse du serveur) et les logs (fichiers de suivi qui enregistrent l’activité du serveur).
    </def>
    <def title="vendor">
        Ce dossier contient les dépendances de l’application, c’est-à-dire l’ensemble des fichiers tiers. Attention le contenu de ce dossier est généré automatiquement, il ne faut donc pas modifier son contenu à la main, car le travail sera perdu à la prochaine mise à jour.
    </def>
    <def title=".env">
        Ce fichier contient les paramètres d’environnement utilisés lorsque l’on travaille en mode développement. À la mise en production, ce sont les véritables variables d’environnement du server qui seront utilisées. 
    </def>
    <def title=".gitignore">
        Ce fichier contient la liste des fichiers et des dossiers que Git doit ignorer pour des raisons de sécurité et confidentialité ou parce que leur contenu est généré automatiquement.
    </def>
    <def title="composer.json">
        Ce fichier contient entre autre, la liste des dépendances du projet. Il permet de recréer le dossier <code>vendor</code> avec la commande <code>composer install</code> ou <code>composer update</code>. Il contient également d’autres informations et constitue en quelques sorte la carte d’identité du projet.
    </def>
    <def title="composer.lock">
        Ce fichier contient les versions des dépendances installées par <code>Composer</code>.
        Grâce à lui un collègue pourra installer mon projet avec les mêmes versions que moi au moyen de la commande <code>composer install</code>
    </def>
    <def title="symfony.lock">
        Symfony propose une surcouche de composer nommée Flex. Ce fichier contient la définition des recettes Flex qui doivent être exécutée à l’installation de notre projet pour le configurer et le rendre prêt à l’exécution.
    </def>
</deflist>

Beaucoup de choses pour un projet qui a à peine commencé. La plupart des fichiers de Symfony sont automatiquement
générés et le gros du travail résidera dans le dossier `src`avec quelques incursions dans le dossier`config`.

### Créer des projets plus complets

Le projet de base est volontairement simpliste, l’idée ici étant de ne pas forcer les utilisateurs à télécharger ce dont ils n’ont pas besoin. Nous avons donc un squelette sur lequel nous ajouterons les bibliothèques requises au fur et à mesure. De cette façon, nous obtiendrons le projet le plus léger possible puisqu’il ne contiendra que ce qui nous est indispensable.

Si nous souhaitons un projet plus complet, nous pouvons ajouter des options à la ligne de commande dont voici les plus courantes :


<deflist type="medium">
    <def title="--webapp">
        Installe toutes les dépendances indispensables pour créer une application Web.
    </def>
    <def title="--demo">
        Installe l’application démo de Symfony. Un projet complet que l’on peut étudier pour apprendre des bonnes pratiques des ingénieurs de Sensio Labs.
    </def>
    <def title="--book">
        Installe le projet du livre de Fabien Potencier (le créateur historique de Symfony) </def>
    <def title="--api">
        Installe les outils pour créer une application API qui doit fournir des données ou des services à d’autres applications. 
    </def>
    <def title="--docker">
        Ajoute le support <code>Docker</code> à notre nouveau projet Symfony
    </def>

</deflist>

#### Exemple

```
symfony new [dossier] --webapp --docker
```

## Configuration de l'IDE

Voici quelques plugins por Visual Studio Code

- Symfony Essential Extension Pack
- PHP Language Essential Extension Pack
- Modern Twig
- Twig Link Resolver
- Twigs IntelliSense
- Mysql (Weijan Chen)
- Docker Essentials
- HTML to CSS completion suggestions
- HTML CSS Support

## Symfony une approche modulaire


## À votre tour

<procedure>
    <step>
        Créer un nouveau projet pour chaque modèle proposé par Symfony 
    </step>
    <step>
        Lancer un serveur
    </step>
    <step>
        Tester dans un navigateur Web
    </step>
</procedure>
 
