#!/bin/bash

###############################################################################
# Instructions d'utilisation :
#
# Enregistrez ce script dans un fichier, par exemple installation_zsh_zinit_starship_arch.sh.
# Rendez-le exécutable avec la commande : chmod +x installation_zsh_zinit_starship_arch.sh.
# Exécutez-le en tant que root : sudo ./installation_zsh_zinit_starship_arch.sh.
# Une fois terminé, redémarrez votre terminal ou exécutez exec zsh pour voir Starship avec le thème Gruvbox Rainbow en action.
###############################################################################

# Vérification si l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root"
   exit 1
fi

# Installation des paquets nécessaires : Zsh, curl, git et Starship
echo "Installation de Zsh et Starship..."
pacman -Syu --noconfirm zsh curl git starship || { echo "Erreur lors de l'installation des paquets"; exit 1; }

# Définition de Zsh comme shell par défaut
echo "Définition de Zsh comme shell par défaut..."
chsh -s $(which zsh)

# Installation de Zinit pour gérer les plugins Zsh
echo "Installation de Zinit..."
sh -c "$(curl -fsSL https://git.io/zinit-install)"

# Configuration de Zinit avec des plugins utiles et initialisation de Starship
echo "Configuration de Zinit avec les plugins populaires et initialisation de Starship..."

# Sauvegarde de l'ancien fichier ~/.zshrc s'il existe
if [ -f ~/.zshrc ]; then
    mv ~/.zshrc ~/.zshrc.backup
fi

# Création d'un nouveau fichier ~/.zshrc
cat << EOF > ~/.zshrc
# Démarrage de Zinit
source ~/.zinit/bin/zinit.zsh

# Plugins Zinit
# Colorisation de la syntaxe des commandes
zinit light zdharma-continuum/fast-syntax-highlighting

# Suggestions automatiques des commandes
zinit light zsh-users/zsh-autosuggestions

# Amélioration de l'auto-complétion
zinit light zsh-users/zsh-completions

# Recherche dans l'historique des commandes
zinit light zsh-users/zsh-history-substring-search

# Activation de l'auto-complétion
autoload -U compinit && compinit

# Initialisation de Starship
eval "\$(starship init zsh)"

# Aliases utiles
alias ll='ls -la'
alias gs='git status'
alias gp='git pull'

# Options utiles pour Zsh
setopt autocd              # Permet de changer de dossier en tapant uniquement son nom
setopt correct             # Correction automatique des petites erreurs de frappe
setopt histignorealldups   # Évite les doublons dans l'historique

# Mise à jour des plugins installés
zinit update --all
EOF

# Configuration de Starship avec le thème Gruvbox Rainbow
echo "Configuration de Starship avec le preset Gruvbox Rainbow..."
mkdir -p ~/.config
starship preset gruvbox-rainbow > ~/.config/starship.toml

# Message final pour l'utilisateur
echo "Installation et configuration terminées. Veuillez redémarrer votre terminal ou exécuter 'exec zsh' pour activer Zsh avec Starship."
