# Installation ZSH + Zinit + Oh-my-posh

Ce script automatise l'installation et la configuration d'un environnement zsh moderne avec:

- **ZSH** : Shell avancé avec de nombreuses fonctionnalités
- **Zinit** : Gestionnaire de plugins rapide et flexible
- **Oh-my-posh** : Personnalisation avancée du prompt
- **Plugins populaires** : Autocomplétion, coloration syntaxique, suggestions, etc.

## Fonctionnalités

### Plugins Zinit inclus
- `zsh-syntax-highlighting` : Coloration syntaxique en temps réel
- `zsh-completions` : Autocomplétion avancée
- `zsh-autosuggestions` : Suggestions basées sur l'historique
- `zsh-history-substring-search` : Recherche dans l'historique
- `fast-syntax-highlighting` : Coloration syntaxique rapide
- `zsh-autocomplete` : Autocomplétion améliorée
- `enhancd` : Navigation de dossiers améliorée
- Plugins Oh-my-zsh (git, colored-man-pages)

### Configuration Oh-my-posh
- Thème personnalisé avec informations Git
- Affichage du chemin actuel
- Support Python et Node.js
- Horodatage
- Design moderne avec des icônes

## Installation

### Prérequis
- Git
- curl
- Connexion internet

### Installation automatique

1. Rendez le script exécutable :
chmod +x install_zsh_setup.sh

2. Exécutez le script :
./install_zsh_setup.sh

3. Redémarrez votre terminal ou exécutez :
zsh

Systèmes supportés

- **Ubuntu/Debian** (apt-get)
- **CentOS/RHEL** (yum)
- **Arch Linux** (pacman)
- **macOS** (Homebrew)

## Personnalisation

### Modifier le thème Oh-my-posh

1. Explorez les thèmes disponibles :
oh-my-posh get themes

2. Prévisualisez un thème :
oh-my-posh init zsh --config ~/.cache/oh-my-posh/themes/THEME_NAME.omp.json

3. Changez le thème dans `~/.zshrc` :
eval "$(oh-my-posh init zsh --config ~/.cache/oh-my-posh/themes/THEME_NAME.omp.json)"

### Ajouter des plugins Zinit

Ajoutez dans votre `~/.zshrc` :
zinit light nom-utilisateur/nom-plugin

### Aliases personnalisés

Ajoutez vos aliases dans `~/.zshrc` :
alias mon_alias='ma_commande

## Dépannage

### Le script échoue
- Vérifiez que vous avez les permissions sudo
- Assurez-vous que Git est installé
- Vérifiez votre connexion internet

### Oh-my-posh ne s'affiche pas correctement
- Installez une police avec des icônes (Nerd Fonts)
- Configurez votre terminal pour utiliser une police compatible

### Plugins ne se chargent pas
- Redémarrez votre terminal
- Exécutez `zinit self-update` puis `zinit update`

## Sauvegarde

Le script sauvegarde automatiquement votre `.zshrc` existant avec un horodatage.

## Désinstallation

Pour revenir à votre configuration précédente :

# Restaurer l'ancien .zshrc
mv ~/.zshrc.backup.TIMESTAMP ~/.zshrc

# Changer le shell par défaut
chsh -s /bin/bash  # ou votre shell précédent

## Mise à jour

Pour mettre à jour les plugins :
zinit self-update
zinit update

Pour mettre à jour oh-my-posh :
- **macOS** : `brew upgrade oh-my-posh`
- **Linux** : Réexécutez le script d'installation