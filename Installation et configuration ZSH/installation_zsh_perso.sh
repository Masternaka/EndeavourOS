#!/bin/bash

# Script d'installation et configuration ZSH + Zinit + Oh-my-posh
# Systèmes supportés: Arch Linux, Ubuntu, Fedora
# Auteur: Masternaka
# Date: $(date +%Y-%m-%d)

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher des messages colorés
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Détection du système d'exploitation
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            OS="ubuntu"
        elif command -v dnf &> /dev/null; then
            OS="fedora"
        elif command -v pacman &> /dev/null; then
            OS="arch"
        else
            log_error "Distribution Linux non supportée"
            log_error "Ce script supporte uniquement: Ubuntu, Fedora, et Arch Linux"
            exit 1
        fi
    else
        log_error "Système d'exploitation non supporté"
        log_error "Ce script supporte uniquement: Ubuntu, Fedora, et Arch Linux"
        exit 1
    fi
}

# Installation de zsh selon l'OS
install_zsh() {
    log_info "Vérification de l'installation de zsh..."

    if command -v zsh &> /dev/null; then
        log_success "zsh est déjà installé"
        return 0
    fi

    log_info "Installation de zsh..."

    case $OS in
        ubuntu)
            sudo apt-get update
            sudo apt-get install -y zsh git curl unzip
            ;;
        fedora)
            sudo dnf install -y zsh git curl unzip
            ;;
        arch)
            sudo pacman -S --noconfirm zsh git curl unzip
            ;;
        *)
            log_error "Système d'exploitation non supporté"
            exit 1
            ;;
    esac

    log_success "zsh installé avec succès"
}

# Installation des fonts nécessaires pour oh-my-posh
install_fonts() {
    log_info "Installation des fonts pour oh-my-posh..."

    # Création du dossier fonts utilisateur
    FONTS_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONTS_DIR"

    case $OS in
        ubuntu)
            # Installation des fonts de base via apt
            sudo apt-get install -y fonts-powerline fonts-font-awesome
            ;;
        fedora)
            # Installation des fonts de base via dnf
            sudo dnf install -y powerline-fonts fontawesome-fonts
            ;;
        arch)
            # Installation des fonts de base via pacman
            sudo pacman -S --noconfirm powerline-fonts ttf-font-awesome
            ;;
    esac

    # Installation des Nerd Fonts via téléchargement direct
    download_and_extract_font() {
        local font_name=$1
        local zip_url=$2
        local temp_dir="/tmp/nerd_fonts_${font_name}"

        if [ ! -d "$FONTS_DIR" ]; then
            mkdir -p "$FONTS_DIR"
        fi

        # Vérifier si la font existe déjà
        if find "$FONTS_DIR" -name "*${font_name}*" -type f | grep -q .; then
            log_info "Font $font_name déjà installée"
            return 0
        fi

        log_info "Téléchargement et installation de $font_name..."

        # Créer un dossier temporaire
        mkdir -p "$temp_dir"

        # Télécharger et extraire
        curl -fL "$zip_url" -o "$temp_dir/${font_name}.zip"

        if [ -f "$temp_dir/${font_name}.zip" ]; then
            cd "$temp_dir"
            unzip -q "${font_name}.zip"

            # Copier les fichiers .ttf et .otf vers le dossier fonts
            find . -name "*.ttf" -o -name "*.otf" | while read font_file; do
                cp "$font_file" "$FONTS_DIR/"
            done

            # Nettoyer
            rm -rf "$temp_dir"
            log_success "Font $font_name installée"
        else
            log_warning "Échec du téléchargement de $font_name"
        fi
    }

    # URLs des Nerd Fonts les plus populaires pour oh-my-posh
    NERD_FONTS_VERSION="v3.1.1"
    NERD_FONTS_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}"

    # Installation des Nerd Fonts essentielles
    download_and_extract_font "FiraCode" "${NERD_FONTS_BASE_URL}/FiraCode.zip"
    download_and_extract_font "Hack" "${NERD_FONTS_BASE_URL}/Hack.zip"
    download_and_extract_font "JetBrainsMono" "${NERD_FONTS_BASE_URL}/JetBrainsMono.zip"
    download_and_extract_font "Meslo" "${NERD_FONTS_BASE_URL}/Meslo.zip"

    # Actualiser le cache des fonts
    log_info "Actualisation du cache des fonts..."
    fc-cache -fv "$FONTS_DIR" >/dev/null 2>&1

    log_success "Installation des fonts terminée"
    log_info "Fonts installées dans: $FONTS_DIR"
    log_info "Redémarrez votre terminal pour que les nouvelles fonts soient disponibles"
    log_info "Fonts recommandées pour oh-my-posh: FiraCode Nerd Font, Hack Nerd Font, JetBrains Mono Nerd Font"
}

# Installation de zinit
install_zinit() {
    log_info "Installation de zinit..."

    ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

    if [ -d "$ZINIT_HOME" ]; then
        log_warning "zinit est déjà installé"
        return 0
    fi

    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

    log_success "zinit installé avec succès"
}

# Installation d'oh-my-posh
install_oh_my_posh() {
    log_info "Installation d'oh-my-posh..."

    if command -v oh-my-posh &> /dev/null; then
        log_warning "oh-my-posh est déjà installé"
        return 0
    fi

    case $OS in
        ubuntu|fedora|arch)
            curl -s https://ohmyposh.dev/install.sh | bash -s
            ;;
        *)
            log_error "Système d'exploitation non supporté"
            exit 1
            ;;
    esac

    log_success "oh-my-posh installé avec succès"
}

# Configuration du .zshrc
configure_zshrc() {
    log_info "Configuration du fichier .zshrc..."

    # Sauvegarde du .zshrc existant
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Sauvegarde du .zshrc existant créée"
    fi

    # Création du nouveau .zshrc
    cat > "$HOME/.zshrc" << 'EOF'
# Configuration ZSH avec Zinit et Oh-my-posh
# Généré automatiquement pour Ubuntu, Fedora et Arch Linux

# Zinit installation et configuration
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Oh-my-posh configuration avec le thème agnosterplus
if command -v oh-my-posh &> /dev/null; then
    eval "$(oh-my-posh init zsh --config agnosterplus)"
fi

# Plugins zinit - Les plus populaires
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search

# Plugin pour les suggestions basées sur l'historique
zinit light zdharma-continuum/fast-syntax-highlighting

# Auto-completion améliorée
zinit light marlonrichert/zsh-autocomplete

# Plugin pour la navigation de dossiers
zinit light b4b4r07/enhancd

# Plugin pour les alias git
zinit light ohmyzsh/ohmyzsh --select="plugins/git"

# Plugin pour les couleurs ls
zinit light ohmyzsh/ohmyzsh --select="plugins/colored-man-pages"

# Configuration de l'historique
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# Aliases utiles
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias cls='clear'

# Configuration des touches pour zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Auto-completion
autoload -U compinit
compinit

# Correction automatique des commandes
setopt CORRECT
setopt CORRECT_ALL

# Navigation améliorée
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

EOF

    log_success "Fichier .zshrc configuré"
}

# Configuration d'oh-my-posh
configure_oh_my_posh() {
    log_info "Configuration d'oh-my-posh avec le thème agnosterplus..."

    # Pas besoin de créer un fichier de configuration personnalisé
    # Le thème agnosterplus est intégré à oh-my-posh

    log_success "Configuration d'oh-my-posh terminée avec le thème agnosterplus"
}

# Fonction pour changer le shell par défaut
change_default_shell() {
    log_info "Configuration de zsh comme shell par défaut..."

    if [ "$SHELL" = "$(which zsh)" ]; then
        log_success "zsh est déjà le shell par défaut"
        return 0
    fi

    # Ajouter zsh à /etc/shells s'il n'y est pas
    if ! grep -q "$(which zsh)" /etc/shells; then
        echo "$(which zsh)" | sudo tee -a /etc/shells
    fi

    # Changer le shell par défaut
    chsh -s "$(which zsh)"

    log_success "Shell par défaut changé vers zsh"
    log_warning "Vous devrez vous reconnecter pour que le changement prenne effet"
}

# Fonction principale
main() {
    log_info "Début de l'installation de l'environnement zsh..."
    log_info "Systèmes supportés: Ubuntu, Fedora, Arch Linux"

    detect_os
    log_info "Système détecté: $OS"

    install_zsh
    install_fonts
    install_zinit
    install_oh_my_posh
    configure_zshrc
    configure_oh_my_posh
    change_default_shell

    log_success "Installation terminée avec succès!"
    log_info "Redémarrez votre terminal ou exécutez 'zsh' pour commencer à utiliser votre nouvel environnement"
    log_info "N'oubliez pas de configurer votre terminal pour utiliser une Nerd Font (ex: FiraCode Nerd Font)"
    log_info "Vous pouvez personnaliser davantage votre configuration dans ~/.zshrc"
    log_info "Les thèmes oh-my-posh sont disponibles sur: https://ohmyposh.dev/docs/themes"
}

# Exécution du script
main "$@"
