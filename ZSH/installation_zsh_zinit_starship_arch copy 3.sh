#!/bin/bash

# Script d'installation et configuration de Zsh, Zinit et Starship
# Compatible Arch Linux.
# Version: 3.0
# Améliorations: modularité, gestion des permissions, flexibilité.

set -euo pipefail

# --- Configuration et Constantes ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CONFIG_DIR="$SCRIPT_DIR/config_files"

# --- Fonctions utilitaires ---
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }
get_real_user() { echo "${SUDO_USER:-$USER}"; }
get_user_home() { getent passwd "$(get_real_user)" | cut -d: -f6; }

# --- Fonctions principales ---

check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Ce script doit être exécuté avec sudo: sudo $0"
    fi
    if ! command_exists "sudo"; then
        print_error "'sudo' n'est pas installé. Ce script ne peut pas continuer."
    fi
    print_status "Utilisateur détecté : $(get_real_user)"
}

install_packages() {
    print_status "Mise à jour du système et installation des dépendances..."
    pacman -Syu --noconfirm

    local packages=("zsh" "curl" "git" "wget" "ttf-fira-code" "nerd-fonts")

    # Utilisation de --needed pour ne pas réinstaller ce qui est déjà à jour
    pacman -S --noconfirm --needed "${packages[@]}"
    print_success "Paquets système installés."
}

install_starship() {
    print_status "Installation de Starship..."
    if command_exists starship; then
        print_success "Starship est déjà installé."
        return
    fi

    # Méthode plus sécurisée : installation du binaire
    print_status "Installation du binaire Starship dans /usr/local/bin..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes

    if ! command_exists starship; then
        print_error "Échec de l'installation de Starship."
    fi
    print_success "Starship installé."
}

configure_shell_for_user() {
    local real_user
    real_user=$(get_real_user)

    if [[ "$(getent passwd "$real_user" | cut -d: -f7)" != "$(which zsh)" ]]; then
        print_status "Configuration de Zsh comme shell par défaut pour $real_user..."
        chsh -s "$(which zsh)" "$real_user"
        print_success "Shell par défaut configuré. Un redémarrage de session est requis."
    else
        print_success "Zsh est déjà le shell par défaut pour $real_user."
    fi
}

install_zinit_for_user() {
    local real_user user_home zinit_dir
    real_user=$(get_real_user)
    user_home=$(get_user_home)
    zinit_dir="$user_home/.local/share/zinit"

    print_status "Installation ou mise à jour de Zinit..."

    # Exécuter les opérations en tant que l'utilisateur final
    sudo -u "$real_user" bash -c "
        if [[ -d '$zinit_dir' ]]; then
            echo 'Mise à jour de Zinit...'
            (cd '$zinit_dir/zinit.git' && git pull)
        else
            echo 'Installation de Zinit...'
            git clone https://github.com/zdharma-continuum/zinit.git '$zinit_dir/zinit.git'
        fi
    "
    print_success "Zinit installé/mis à jour."
}

deploy_dotfiles() {
    local real_user user_home
    real_user=$(get_real_user)
    user_home=$(get_user_home)

    print_status "Déploiement des fichiers de configuration..."

    if [[ ! -d "$CONFIG_DIR" ]]; then
        print_error "Le dossier de configuration '$CONFIG_DIR' est introuvable."
    fi

    # Création des répertoires de configuration en tant que l'utilisateur
    sudo -u "$real_user" mkdir -p "$user_home/.config"

    # Copie du .zshrc
    local zshrc_dest="$user_home/.zshrc"
    if [[ -f "$zshrc_dest" ]]; then
        mv "$zshrc_dest" "$zshrc_dest.bak.$(date +%F-%T)"
        print_warning "Ancien .zshrc sauvegardé."
    fi
    cp "$CONFIG_DIR/zshrc" "$zshrc_dest"
    print_success ".zshrc déployé."

    # Copie de starship.toml
    local starship_dest="$user_home/.config/starship.toml"
    cp "$CONFIG_DIR/starship.toml" "$starship_dest"
    print_success "starship.toml déployé."

    # Assurer que l'utilisateur est propriétaire de ses fichiers
    chown -R "$real_user:$real_user" "$user_home/.config" "$user_home/.zshrc" "$user_home/.local"
    print_success "Permissions des fichiers de configuration appliquées."
}

main() {
    check_privileges

    install_packages
    install_starship

    configure_shell_for_user
    install_zinit_for_user
    deploy_dotfiles

    print_success "🎉 Installation terminée !"
    print_status "Veuillez redémarrer votre terminal ou lancer 'exec zsh' pour appliquer les changements."
}

# Gestion de l'interruption
trap 'echo -e "\n${RED}Installation interrompue.${NC}"; exit 1' INT TERM

main "$@"
