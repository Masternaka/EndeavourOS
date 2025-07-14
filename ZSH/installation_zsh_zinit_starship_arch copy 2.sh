#!/usr/bin/env bash
# Installation et configuration optimisée de Zsh, Zinit et Starship sur Arch Linux
# Usage:
#   chmod +x install_zsh_zinit_starship_arch.sh
#   ./install_zsh_zinit_starship_arch.sh

set -euo pipefail
IFS=$'\n\t'

# Variables
USER_HOME="${HOME}"
ZSHRC_PATH="$USER_HOME/.zshrc"
ZINIT_DIR="$USER_HOME/.local/share/zinit"
STARSHIP_CONFIG_DIR="$USER_HOME/.config"
STARSHIP_CONFIG_FILE="$STARSHIP_CONFIG_DIR/starship.toml"

# Fonctions de log
log_info()   { echo -e "\e[32m[INFO]    $*\e[0m"; }
log_warn()   { echo -e "\e[33m[WARNING] $*\e[0m"; }
log_error()  { echo -e "\e[31m[ERROR]   $*\e[0m"; exit 1; }

# Vérifier pacman
command -v pacman >/dev/null || log_error "Pacman non trouvé. Ce script est pour Arch Linux."

# Mise à jour et installation des paquets nécessaires
install_packages() {
    log_info "Mise à jour du système et installation des paquets nécessaires..."
    sudo pacman -Syu --noconfirm zsh curl git starship || log_error "Échec de l'installation des paquets"
}

# Définir zsh comme shell par défaut
set_default_shell() {
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [[ "$current_shell" != "$(command -v zsh)" ]]; then
        log_info "Définition de Zsh comme shell par défaut pour l'utilisateur $USER"
        chsh -s "$(which zsh)" "$USER" || log_warn "Impossible de changer le shell, relancez ce script sans sudo ou manuellement."
    else
        log_info "Zsh est déjà le shell par défaut"
    fi
}

# Installation de Zinit
install_zinit() {
    if [[ -d "$ZINIT_DIR" ]]; then
        log_info "Zinit est déjà installé, mise à jour..."
        "${ZINIT_DIR}"/bin/zinit self-update || log_warn "Échec de la mise à jour de Zinit"
    else
        log_info "Installation de Zinit..."
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_DIR" || log_error "Échec du clonage de Zinit"
    fi
}

# Création et configuration de .zshrc
configure_zshrc() {
    if [[ -f "$ZSHRC_PATH" ]]; then
        timestamp=$(date +"%Y%m%d_%H%M%S")
        log_warn "Sauvegarde de l'ancien .zshrc -> .zshrc.backup.$timestamp"
        mv "$ZSHRC_PATH" "$ZSHRC_PATH.backup.$timestamp"
    fi
    log_info "Génération du nouveau .zshrc"
    cat << 'EOF' > "$ZSHRC_PATH"
# Chargement de Zinit
source "$ZHOME/.local/share/zinit/bin/zinit.zsh"

# Plugins Zsh via Zinit
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-history-substring-search

# Initialisation de l'autocompletion
autoload -Uz compinit && compinit

# Initialisation de Starship
if command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

# Aliases utiles
alias ll='ls -lah'
alias gs='git status'
alias gp='git pull'

# Options Zsh
setopt autocd          # cd avec le nom du répertoire
setopt correct         # correction typo
setopt histignorealldups

# Mise à jour automatique des plugins Zinit
zinit update --all
EOF
}

# Configuration de Starship
configure_starship() {
    log_info "Configuration de Starship (preset gruvbox-rainbow)..."
    mkdir -p "$STARSHIP_CONFIG_DIR"
    if [[ ! -s "$STARSHIP_CONFIG_FILE" ]]; then
        starship preset gruvbox-rainbow > "$STARSHIP_CONFIG_FILE" || log_warn "Échec de la création du fichier starship.toml"
    else
        log_info "starship.toml existe déjà, aucune modification."
    fi
}

# Exécution des étapes
install_packages
set_default_shell
install_zinit
configure_zshrc
configure_starship

log_info "Installation et configuration terminées avec succès !"
log_info "Veuillez redémarrer votre terminal ou exécuter 'exec zsh' pour prendre effet."
