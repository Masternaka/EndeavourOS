#!/bin/bash

# Vérification si l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root" 
   exit 1
fi

# 1. Installation de Zsh
echo "Installation de Zsh..."
pacman -Syu --noconfirm zsh curl git

# 2. Définir Zsh comme shell par défaut
echo "Définition de Zsh comme shell par défaut..."
chsh -s $(which zsh)

# 3. Installation de Zinit
echo "Installation de Zinit..."
sh -c "$(curl -fsSL https://git.io/zinit-install)"

# 4. Installation et configuration de Powerlevel10k avec Zinit
echo "Configuration de Zinit avec Powerlevel10k et installation des plugins populaires..."

# Sauvegarder l'ancien ~/.zshrc
if [ -f ~/.zshrc ]; then
    mv ~/.zshrc ~/.zshrc.backup
fi

# Créer un nouveau ~/.zshrc avec Zinit et plugins
cat << EOF > ~/.zshrc
# Démarrage de Zinit
source ~/.zinit/bin/zinit.zsh

# Plugins Zinit

# 5. Installation de Powerlevel10k
zinit light romkatv/powerlevel10k

# 6. Syntaxe des commandes colorée
zinit light zdharma-continuum/fast-syntax-highlighting

# 7. Auto-suggestions des commandes
zinit light zsh-users/zsh-autosuggestions

# 8. Auto-completion améliorée
zinit light zsh-users/zsh-completions

# 9. Gestion de l'historique de commandes
zinit light zsh-users/zsh-history-substring-search

# Activer l'autocomplétion
autoload -U compinit && compinit

# Charger Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Aliases utiles
alias ll='ls -la'
alias gs='git status'
alias gp='git pull'

# Définir des options Zsh
setopt autocd              # Permet de changer de dossier en tapant uniquement son nom
setopt correct             # Correction automatique des petites erreurs de frappe
setopt histignorealldups   # Évite les doublons dans l'historique

# Chargement des plugins installés
zinit update --all

EOF

# 10. Finaliser l'installation
echo "Installation et configuration terminées. Veuillez redémarrer votre terminal ou exécuter 'exec zsh' pour activer Zsh."

# 11. Exécuter la configuration initiale de Powerlevel10k
echo "Lancer la configuration initiale de Powerlevel10k..."
zsh -c 'source ~/.zshrc && p10k configure'
