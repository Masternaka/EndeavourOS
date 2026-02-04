#!/bin/bash

# Script d'installation zsh + oh-my-zsh + powerlevel10k + plugins pour Arch Linux
# Auteur: Claude
# Date: 2026-02-04

set -e  # Arrêter le script en cas d'erreur

echo "=========================================="
echo "Installation de zsh et configuration"
echo "=========================================="
echo ""

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# Vérifier si le script est exécuté en tant que root
if [ "$EUID" -eq 0 ]; then 
    print_error "Ne pas exécuter ce script en tant que root (sans sudo)"
    exit 1
fi

# Mise à jour du système
print_info "Mise à jour du système..."
sudo pacman -Syu --noconfirm

# Installation de zsh
print_info "Installation de zsh..."
sudo pacman -S --needed --noconfirm zsh

# Installation des dépendances
print_info "Installation des dépendances (git, curl, wget, bat, fzf, zoxide)..."
sudo pacman -S --needed --noconfirm git curl wget bat fzf zoxide

# Installation de la police JetBrainsMono Nerd Font
print_info "Installation de JetBrainsMono Nerd Font..."
sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd

# Sauvegarde de l'ancien .zshrc s'il existe
if [ -f ~/.zshrc ]; then
    print_info "Sauvegarde de l'ancien .zshrc vers .zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
fi

# Installation de oh-my-zsh
if [ ! -d ~/.oh-my-zsh ]; then
    print_info "Installation de oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    print_status "oh-my-zsh est déjà installé"
fi

# Installation de Powerlevel10k
print_info "Installation de Powerlevel10k..."
if [ ! -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
else
    print_status "Powerlevel10k est déjà installé"
fi

# Répertoire des plugins personnalisés
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

# Installation des plugins zsh
print_info "Installation des plugins zsh..."

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
    print_status "zsh-autosuggestions installé"
else
    print_status "zsh-autosuggestions déjà installé"
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
    print_status "zsh-syntax-highlighting installé"
else
    print_status "zsh-syntax-highlighting déjà installé"
fi

# zsh-autocomplete
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]; then
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git $ZSH_CUSTOM/plugins/zsh-autocomplete
    print_status "zsh-autocomplete installé"
else
    print_status "zsh-autocomplete déjà installé"
fi

# zsh-completions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
    git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions
    print_status "zsh-completions installé"
else
    print_status "zsh-completions déjà installé"
fi

# zsh-history-substring-search
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
    git clone https://github.com/zsh-users/zsh-history-substring-search $ZSH_CUSTOM/plugins/zsh-history-substring-search
    print_status "zsh-history-substring-search installé"
else
    print_status "zsh-history-substring-search déjà installé"
fi

# fzf-zsh-plugin
if [ ! -d "$ZSH_CUSTOM/plugins/fzf-zsh-plugin" ]; then
    git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git $ZSH_CUSTOM/plugins/fzf-zsh-plugin
    print_status "fzf-zsh-plugin installé"
else
    print_status "fzf-zsh-plugin déjà installé"
fi

# Installation et configuration de fzf
print_info "Configuration de fzf..."
if [ ! -d ~/.fzf ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
    print_status "fzf installé et configuré"
else
    print_status "fzf déjà installé"
fi

# Configuration du .zshrc
print_info "Configuration du fichier .zshrc..."

cat > ~/.zshrc << 'EOF'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-autocomplete
    zsh-completions
    zsh-history-substring-search
    fzf-zsh-plugin
)

source $ZSH/oh-my-zsh.sh

# User configuration

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias cat='bat'
alias grep='grep --color=auto'

# History configuration
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# Key bindings for history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# fzf configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# fzf colors and options
export FZF_DEFAULT_OPTS="
--height 40%
--layout=reverse
--border
--inline-info
--preview 'bat --style=numbers --color=always --line-range :500 {}'
--preview-window right:60%:wrap
--bind 'ctrl-/:toggle-preview'
--bind 'ctrl-u:preview-page-up'
--bind 'ctrl-d:preview-page-down'
--color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
--color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
--color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
--color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
"

# Source fzf key bindings and completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fzf additional functions
# Ctrl+R - Search command history
# Ctrl+T - Search files
# Alt+C - cd into directory

# Initialize zoxide (must be after compinit)
eval "$(zoxide init zsh)"

# Aliases for zoxide
alias cd='z'
alias cdi='zi'  # Interactive selection with fzf

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF

print_status "Fichier .zshrc configuré"

# Vérifier et installer fd (pour fzf)
print_info "Installation de fd (pour fzf)..."
sudo pacman -S --needed --noconfirm fd

# Changer le shell par défaut
print_info "Changement du shell par défaut vers zsh..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s $(which zsh)
    print_status "Shell par défaut changé vers zsh"
else
    print_status "zsh est déjà le shell par défaut"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Installation terminée avec succès!${NC}"
echo "=========================================="
echo ""
echo "Pour finaliser l'installation:"
echo "1. Déconnectez-vous et reconnectez-vous (ou redémarrez)"
echo "2. Au premier lancement de zsh, Powerlevel10k vous guidera"
echo "   dans la configuration avec 'p10k configure'"
echo ""
echo "Raccourcis clavier configurés:"
echo "  ${YELLOW}Ctrl+R${NC}  - Recherche dans l'historique avec fzf"
echo "  ${YELLOW}Ctrl+T${NC}  - Recherche de fichiers avec fzf"
echo "  ${YELLOW}Alt+C${NC}   - Recherche de répertoires et cd avec fzf"
echo "  ${YELLOW}↑/↓${NC}     - Recherche dans l'historique (substring)"
echo ""
echo "Commandes utiles:"
echo "  ${YELLOW}z <dir>${NC}     - Naviguer vers un répertoire (zoxide)"
echo "  ${YELLOW}zi${NC}          - Naviguer interactivement avec fzf"
echo "  ${YELLOW}z -${NC}         - Retourner au répertoire précédent"
echo "  ${YELLOW}zoxide query${NC} - Voir les répertoires fréquemment visités"
echo ""
echo "Note: Assurez-vous que votre terminal utilise la police"
echo "      JetBrainsMono Nerd Font pour un affichage optimal"
echo ""
echo -e "${YELLOW}Pour démarrer zsh maintenant, exécutez: zsh${NC}"
echo ""