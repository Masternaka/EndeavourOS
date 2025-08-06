#!/bin/bash

# Script d'installation et configuration ZSH + Zinit + Oh-my-posh (Version corrigée)
# Systèmes supportés: Arch Linux, Ubuntu, Fedora
# Auteur: Masternaka (Version corrigée)
# Date: $(date +%Y-%m-%d)

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables globales
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
FONTS_DIR="$HOME/.local/share/fonts"
NERD_FONTS_VERSION="v3.2.1"
NERD_FONTS_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}"

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

# Fonction pour vérifier la connectivité internet
check_internet() {
    log_info "Vérification de la connexion internet..."
    if ! curl -s --head --connect-timeout 5 https://github.com &> /dev/null; then
        log_error "Pas de connexion internet ou GitHub inaccessible"
        log_error "Vérifiez votre connexion et réessayez"
        exit 1
    fi
    log_success "Connexion internet OK"
}

# Détection du système d'exploitation
detect_os() {
    log_info "Détection du système d'exploitation..."
    
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
    
    log_success "Système détecté: $OS"
}

# Vérification des dépendances système
check_dependencies() {
    log_info "Vérification des dépendances système..."
    
    local missing_deps=()
    
    # Vérifier curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    # Vérifier git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    # Vérifier unzip
    if ! command -v unzip &> /dev/null; then
        missing_deps+=("unzip")
    fi
    
    # Vérifier wget
    if ! command -v wget &> /dev/null; then
        missing_deps+=("wget")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_warning "Dépendances manquantes: ${missing_deps[*]}"
        log_info "Installation des dépendances..."
        
        case $OS in
            ubuntu)
                sudo apt-get update
                sudo apt-get install -y "${missing_deps[@]}"
                ;;
            fedora)
                sudo dnf install -y "${missing_deps[@]}"
                ;;
            arch)
                sudo pacman -S --noconfirm "${missing_deps[@]}"
                ;;
        esac
        
        log_success "Dépendances installées"
    else
        log_success "Toutes les dépendances sont présentes"
    fi
}

# Installation de zsh selon l'OS
install_zsh() {
    log_info "Vérification de l'installation de zsh..."

    if command -v zsh &> /dev/null; then
        log_success "zsh est déjà installé ($(zsh --version))"
        return 0
    fi

    log_info "Installation de zsh..."

    case $OS in
        ubuntu)
            sudo apt-get update
            sudo apt-get install -y zsh
            ;;
        fedora)
            sudo dnf install -y zsh
            ;;
        arch)
            sudo pacman -S --noconfirm zsh
            ;;
    esac

    # Vérifier que l'installation a réussi
    if command -v zsh &> /dev/null; then
        log_success "zsh installé avec succès ($(zsh --version))"
    else
        log_error "Échec de l'installation de zsh"
        exit 1
    fi
}

# Installation des fonts nécessaires pour oh-my-posh
install_fonts() {
    log_info "Installation des fonts pour oh-my-posh..."

    # Création du dossier fonts utilisateur
    mkdir -p "$FONTS_DIR"

    # Installation des fonts de base selon l'OS
    case $OS in
        ubuntu)
            sudo apt-get install -y fonts-powerline fonts-font-awesome 2>/dev/null || true
            ;;
        fedora)
            sudo dnf install -y powerline-fonts fontawesome-fonts 2>/dev/null || true
            ;;
        arch)
            sudo pacman -S --noconfirm powerline-fonts ttf-font-awesome 2>/dev/null || true
            ;;
    esac

    # Fonction pour télécharger et installer une Nerd Font
    download_and_extract_font() {
        local font_name=$1
        local zip_url=$2
        local temp_dir="/tmp/nerd_fonts_${font_name}"

        # Vérifier si la font existe déjà
        if find "$FONTS_DIR" -name "*${font_name}*" -type f 2>/dev/null | grep -q .; then
            log_info "Font $font_name déjà installée"
            return 0
        fi

        log_info "Téléchargement et installation de $font_name..."

        # Créer un dossier temporaire
        mkdir -p "$temp_dir"

        # Télécharger avec timeout et retry
        if timeout 30 curl -fL --retry 3 --retry-delay 2 "$zip_url" -o "$temp_dir/${font_name}.zip" 2>/dev/null; then
            cd "$temp_dir"
            
            # Extraire silencieusement
            if unzip -q "${font_name}.zip" 2>/dev/null; then
                # Copier les fichiers .ttf et .otf vers le dossier fonts
                find . -name "*.ttf" -o -name "*.otf" 2>/dev/null | while read -r font_file; do
                    cp "$font_file" "$FONTS_DIR/" 2>/dev/null || true
                done
                
                log_success "Font $font_name installée"
            else
                log_warning "Échec de l'extraction de $font_name"
            fi
            
            # Nettoyer
            rm -rf "$temp_dir"
        else
            log_warning "Échec du téléchargement de $font_name (timeout ou erreur réseau)"
            rm -rf "$temp_dir"
        fi
    }

    # Installation des Nerd Fonts essentielles
    download_and_extract_font "FiraCode" "${NERD_FONTS_BASE_URL}/FiraCode.zip"
    download_and_extract_font "Hack" "${NERD_FONTS_BASE_URL}/Hack.zip"
    download_and_extract_font "JetBrainsMono" "${NERD_FONTS_BASE_URL}/JetBrainsMono.zip"
    download_and_extract_font "Meslo" "${NERD_FONTS_BASE_URL}/Meslo.zip"

    # Actualiser le cache des fonts
    if command -v fc-cache &> /dev/null; then
        log_info "Actualisation du cache des fonts..."
        fc-cache -fv "$FONTS_DIR" >/dev/null 2>&1 || true
    fi

    log_success "Installation des fonts terminée"
    log_info "Fonts installées dans: $FONTS_DIR"
}

# Installation de zinit
install_zinit() {
    log_info "Installation de zinit..."

    if [ -d "$ZINIT_HOME" ]; then
        log_warning "zinit est déjà installé"
        return 0
    fi

    log_info "Téléchargement de zinit..."
    mkdir -p "$(dirname $ZINIT_HOME)"
    
    if git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"; then
        log_success "zinit installé avec succès"
    else
        log_error "Échec de l'installation de zinit"
        exit 1
    fi
}

# Installation d'oh-my-posh
install_oh_my_posh() {
    log_info "Installation d'oh-my-posh..."

    if command -v oh-my-posh &> /dev/null; then
        log_success "oh-my-posh est déjà installé ($(oh-my-posh version))"
        return 0
    fi

    case $OS in
        ubuntu|fedora)
            log_info "Téléchargement d'oh-my-posh..."
            # Télécharger le binaire directement
            if sudo wget -q --timeout=30 --tries=3 \
                "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64" \
                -O /usr/local/bin/oh-my-posh; then
                sudo chmod +x /usr/local/bin/oh-my-posh
                log_success "oh-my-posh installé avec succès"
            else
                log_error "Échec du téléchargement d'oh-my-posh"
                exit 1
            fi
            ;;
        arch)
            # Essayer d'abord avec yay (AUR helper)
            if command -v yay &> /dev/null; then
                log_info "Installation via AUR (yay)..."
                if yay -S --noconfirm oh-my-posh; then
                    log_success "oh-my-posh installé via AUR"
                else
                    log_warning "Échec de l'installation via AUR, tentative avec le binaire..."
                    if sudo wget -q --timeout=30 --tries=3 \
                        "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64" \
                        -O /usr/local/bin/oh-my-posh; then
                        sudo chmod +x /usr/local/bin/oh-my-posh
                        log_success "oh-my-posh installé avec succès"
                    else
                        log_error "Échec du téléchargement d'oh-my-posh"
                        exit 1
                    fi
                fi
            else
                log_info "Installation via téléchargement direct..."
                if sudo wget -q --timeout=30 --tries=3 \
                    "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64" \
                    -O /usr/local/bin/oh-my-posh; then
                    sudo chmod +x /usr/local/bin/oh-my-posh
                    log_success "oh-my-posh installé avec succès"
                else
                    log_error "Échec du téléchargement d'oh-my-posh"
                    exit 1
                fi
            fi
            ;;
    esac

    # Vérifier que l'installation a réussi
    if command -v oh-my-posh &> /dev/null; then
        log_success "oh-my-posh installé et fonctionnel ($(oh-my-posh version))"
    else
        log_error "oh-my-posh n'est pas accessible après l'installation"
        exit 1
    fi
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
# Généré automatiquement - Version corrigée

# Zinit installation et configuration
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Vérifier si zinit est installé
if [ ! -d "$ZINIT_HOME" ]; then
    echo "Zinit n'est pas installé. Installation en cours..."
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Charger zinit
source "${ZINIT_HOME}/zinit.zsh"

# Ajouter oh-my-posh au PATH si nécessaire
if [ -f "/usr/local/bin/oh-my-posh" ]; then
    export PATH="/usr/local/bin:$PATH"
fi

# Oh-my-posh configuration avec le thème agnoster
if command -v oh-my-posh &> /dev/null; then
    # Utiliser un thème intégré qui existe
    eval "$(oh-my-posh init zsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/agnoster.omp.json)"
else
    # Fallback si oh-my-posh n'est pas disponible
    echo "Oh-my-posh n'est pas disponible"
fi

# Plugins zinit - Configuration stable
zinit wait lucid for \
    atinit"zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
        zsh-users/zsh-completions

# Plugin pour l'historique
zinit light zsh-users/zsh-history-substring-search

# Plugins Oh-My-Zsh
zinit snippet OMZP::git
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::command-not-found

# Configuration de l'historique
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

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
alias h='history'
alias hg='history | grep'

# Configuration des touches pour zsh-history-substring-search
if [ -n "${terminfo[kcuu1]}" ]; then
    bindkey "${terminfo[kcuu1]}" history-substring-search-up
else
    bindkey '^[[A' history-substring-search-up
fi

if [ -n "${terminfo[kcud1]}" ]; then
    bindkey "${terminfo[kcud1]}" history-substring-search-down
else
    bindkey '^[[B' history-substring-search-down
fi

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
setopt PUSHD_SILENT

# Améliorer les performances
setopt NO_BEEP
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

# Fonctions utiles
# Fonction pour extraire différents types d'archives
extract() {
    if [ -f "$1" ]; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' ne peut pas être extrait via extract()" ;;
        esac
    else
        echo "'$1' n'est pas un fichier valide"
    fi
}

# Fonction pour créer et naviguer dans un dossier
mkcd() {
    mkdir -p "$1" && cd "$1"
}

EOF

    log_success "Fichier .zshrc configuré avec succès"
}

# Fonction pour changer le shell par défaut
change_default_shell() {
    log_info "Configuration de zsh comme shell par défaut..."

    local zsh_path
    zsh_path=$(which zsh)

    if [ "$SHELL" = "$zsh_path" ]; then
        log_success "zsh est déjà le shell par défaut"
        return 0
    fi

    # Ajouter zsh à /etc/shells s'il n'y est pas
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
        log_info "zsh ajouté à /etc/shells"
    fi

    # Changer le shell par défaut
    if chsh -s "$zsh_path"; then
        log_success "Shell par défaut changé vers zsh"
        log_warning "Vous devrez vous reconnecter pour que le changement prenne effet"
    else
        log_error "Échec du changement de shell par défaut"
        log_info "Vous pouvez le faire manuellement avec: chsh -s $zsh_path"
    fi
}

# Fonction de vérification finale
verify_installation() {
    log_info "Vérification de l'installation..."
    
    local errors=0
    
    # Vérifier zsh
    if ! command -v zsh &> /dev/null; then
        log_error "zsh n'est pas installé correctement"
        errors=$((errors + 1))
    fi
    
    # Vérifier oh-my-posh
    if ! command -v oh-my-posh &> /dev/null; then
        log_error "oh-my-posh n'est pas installé correctement"
        errors=$((errors + 1))
    fi
    
    # Vérifier zinit
    if [ ! -d "$ZINIT_HOME" ]; then
        log_error "zinit n'est pas installé correctement"
        errors=$((errors + 1))
    fi
    
    # Vérifier le fichier .zshrc
    if [ ! -f "$HOME/.zshrc" ]; then
        log_error ".zshrc n'existe pas"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "Toutes les vérifications sont passées ✓"
        return 0
    else
        log_error "$errors erreur(s) détectée(s)"
        return 1
    fi
}

# Fonction principale
main() {
    echo "============================================"
    echo "  Installation ZSH + Zinit + Oh-My-Posh"
    echo "         Version corrigée"
    echo "============================================"
    echo ""
    
    log_info "Début de l'installation de l'environnement zsh..."
    log_info "Systèmes supportés: Ubuntu, Fedora, Arch Linux"
    echo ""

    # Vérifications préalables
    check_internet
    detect_os
    check_dependencies
    
    echo ""
    log_info "Installation des composants..."
    
    # Installation des composants
    install_zsh
    install_fonts
    install_zinit
    install_oh_my_posh
    
    echo ""
    log_info "Configuration..."
    
    # Configuration
    configure_zshrc
    change_default_shell
    
    echo ""
    log_info "Vérification finale..."
    
    # Vérification
    if verify_installation; then
        echo ""
        echo "============================================"
        log_success "Installation terminée avec succès! 🎉"
        echo "============================================"
        echo ""
        log_info "Prochaines étapes:"
        echo "  1. Redémarrez votre terminal ou exécutez 'zsh'"
        echo "  2. Configurez votre terminal pour utiliser une Nerd Font"
        echo "     (ex: FiraCode Nerd Font, Hack Nerd Font, JetBrains Mono Nerd Font)"
        echo "  3. Personnalisez votre configuration dans ~/.zshrc"
        echo ""
        log_info "Ressources utiles:"
        echo "  - Thèmes oh-my-posh: https://ohmyposh.dev/docs/themes"
        echo "  - Plugins zinit: https://github.com/zdharma-continuum/zinit"
        echo "  - Documentation zsh: https://zsh.sourceforge.io/Doc/"
        echo ""
    else
        log_error "L'installation s'est terminée avec des erreurs"
        log_info "Vérifiez les messages d'erreur ci-dessus"
        exit 1
    fi
}

# Gestion des signaux
trap 'log_error "Installation interrompue par l'\''utilisateur"; exit 1' INT TERM

# Exécution du script
main "$@"
