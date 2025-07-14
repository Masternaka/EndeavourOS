#!/bin/bash

# Script d'installation et configuration de Zsh avec Zinit et Starship
# Compatible avec Arch Linux et dérivés
# Version: 2.0

set -euo pipefail  # Mode strict: arrête sur erreur, variables non définies, erreurs de pipe

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage avec couleurs
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction pour détecter l'utilisateur réel (même avec sudo)
get_real_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo "$SUDO_USER"
    else
        echo "$USER"
    fi
}

# Fonction pour obtenir le répertoire home de l'utilisateur réel
get_user_home() {
    local real_user=$(get_real_user)
    if [[ "$real_user" == "root" ]]; then
        echo "/root"
    else
        echo "/home/$real_user"
    fi
}

# Vérification des privilèges
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Ce script doit être exécuté avec les privilèges root (sudo)"
        print_status "Utilisation: sudo $0"
        exit 1
    fi
    
    local real_user=$(get_real_user)
    local user_home=$(get_user_home)
    
    print_status "Utilisateur réel: $real_user"
    print_status "Répertoire home: $user_home"
}

# Installation des paquets système
install_system_packages() {
    print_status "Mise à jour du système et installation des paquets..."
    
    # Mise à jour du système
    pacman -Syu --noconfirm
    
    # Installation des paquets nécessaires
    local packages=(
        "zsh"
        "curl"
        "git"
        "wget"
        "base-devel"
        "ttf-fira-code"  # Police avec ligatures pour le terminal
        "ttf-nerd-fonts-symbols"  # Symboles pour Starship
    )
    
    for package in "${packages[@]}"; do
        if pacman -Qi "$package" >/dev/null 2>&1; then
            print_success "$package est déjà installé"
        else
            print_status "Installation de $package..."
            pacman -S --noconfirm "$package"
        fi
    done
}

# Installation de Starship
install_starship() {
    print_status "Installation de Starship..."
    
    if command_exists starship; then
        print_success "Starship est déjà installé"
        starship --version
        return
    fi
    
    # Installation via le script officiel
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
    
    # Vérification de l'installation
    if command_exists starship; then
        print_success "Starship installé avec succès"
        starship --version
    else
        print_error "Échec de l'installation de Starship"
        exit 1
    fi
}

# Configuration de Zsh comme shell par défaut
configure_default_shell() {
    local real_user=$(get_real_user)
    local zsh_path=$(which zsh)
    
    print_status "Configuration de Zsh comme shell par défaut pour $real_user..."
    
    # Changer le shell pour l'utilisateur réel
    if [[ "$real_user" == "root" ]]; then
        chsh -s "$zsh_path"
    else
        chsh -s "$zsh_path" "$real_user"
    fi
    
    print_success "Shell par défaut configuré: $zsh_path"
}

# Installation de Zinit
install_zinit() {
    local user_home=$(get_user_home)
    local real_user=$(get_real_user)
    local zinit_dir="$user_home/.local/share/zinit"
    
    print_status "Installation de Zinit..."
    
    if [[ -d "$zinit_dir" ]]; then
        print_warning "Zinit semble déjà installé dans $zinit_dir"
        print_status "Mise à jour de Zinit..."
        sudo -u "$real_user" bash -c "cd '$zinit_dir' && git pull"
    else
        print_status "Installation de Zinit dans $zinit_dir..."
        sudo -u "$real_user" bash -c "
            mkdir -p '$zinit_dir' && 
            git clone https://github.com/zdharma-continuum/zinit.git '$zinit_dir/zinit.git'
        "
    fi
    
    print_success "Zinit installé/mis à jour avec succès"
}

# Création du fichier de configuration Zsh
create_zsh_config() {
    local user_home=$(get_user_home)
    local real_user=$(get_real_user)
    local zshrc_path="$user_home/.zshrc"
    local zinit_dir="$user_home/.local/share/zinit"
    
    print_status "Création de la configuration Zsh..."
    
    # Sauvegarde de l'ancien .zshrc
    if [[ -f "$zshrc_path" ]]; then
        local backup_path="$zshrc_path.backup.$(date +%Y%m%d_%H%M%S)"
        sudo -u "$real_user" cp "$zshrc_path" "$backup_path"
        print_warning "Ancien .zshrc sauvegardé dans $backup_path"
    fi
    
    # Création du nouveau .zshrc
    sudo -u "$real_user" tee "$zshrc_path" > /dev/null << 'EOF'
# Configuration Zsh avec Zinit et Starship
# Généré automatiquement

# Zinit installation path
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit"

# Télécharger Zinit si pas présent
if [[ ! -f $ZINIT_HOME/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$ZINIT_HOME" && command chmod g-rwX "$ZINIT_HOME"
    command git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

# Charger Zinit
source "$ZINIT_HOME/zinit.git/zinit.zsh"

# Plugins Zinit avec chargement conditionnel et optimisé

# Syntaxe highlighting (chargé en premier pour de meilleures performances)
zinit wait lucid for \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    blockf \
        zsh-users/zsh-completions

# Plugins utilitaires
zinit wait lucid for \
    OMZL::git.zsh \
    OMZL::directories.zsh \
    OMZL::history.zsh \
    OMZL::key-bindings.zsh \
    OMZL::theme-and-appearance.zsh

# Plugins Oh My Zsh sélectionnés
zinit wait lucid for \
    OMZP::git \
    OMZP::sudo \
    OMZP::extract \
    OMZP::cp \
    OMZP::systemd

# Plugin pour l'historique avec recherche par substring
zinit wait lucid for \
    atload"bindkey '^[[A' history-substring-search-up; bindkey '^[[B' history-substring-search-down" \
        zsh-users/zsh-history-substring-search

# Initialisation de Starship (à la fin pour éviter les conflits)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
else
    echo "Starship n'est pas installé. Veuillez l'installer avec: curl -sS https://starship.rs/install.sh | sh"
fi

# Configuration de l'historique
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# Options Zsh
setopt AUTO_CD                 # Permet de changer de dossier en tapant uniquement son nom
setopt CORRECT                 # Correction automatique des petites erreurs de frappe
setopt HIST_IGNORE_ALL_DUPS    # Évite les doublons dans l'historique
setopt HIST_IGNORE_SPACE       # Ignore les commandes qui commencent par un espace
setopt HIST_REDUCE_BLANKS      # Supprime les espaces superflus dans l'historique
setopt SHARE_HISTORY           # Partage l'historique entre les sessions
setopt EXTENDED_HISTORY        # Enregistre l'horodatage des commandes
setopt HIST_VERIFY             # Vérifie les commandes de l'historique avant exécution
setopt INTERACTIVE_COMMENTS    # Permet les commentaires dans les commandes interactives
setopt GLOB_DOTS               # Inclut les fichiers cachés dans les patterns glob

# Aliases utiles
alias ll='ls -la --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Aliases Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git pull'
alias gps='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Aliases système
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'
alias psg='ps aux | grep'
alias top='htop'
alias mkdir='mkdir -pv'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Aliases Arch Linux
alias pacup='sudo pacman -Syu'
alias pacin='sudo pacman -S'
alias pacrm='sudo pacman -R'
alias pacsearch='pacman -Ss'
alias pacinfo='pacman -Si'
alias pacclean='sudo pacman -Sc'
alias pacorphan='sudo pacman -Rns $(pacman -Qtdq)'

# Fonctions utiles
mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [ -f "$1" ] ; then
        case "$1" in
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
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Configuration spécifique pour les complétions
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
zstyle ':completion:*:warnings' format '%BSorry, no matches for: %d%b'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' squeeze-slashes true

# Configuration pour les autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Configuration pour fast-syntax-highlighting
FAST_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
FAST_HIGHLIGHT_STYLES[reserved-word]='fg=yellow'
FAST_HIGHLIGHT_STYLES[alias]='fg=green'
FAST_HIGHLIGHT_STYLES[builtin]='fg=green'
FAST_HIGHLIGHT_STYLES[function]='fg=green'
FAST_HIGHLIGHT_STYLES[command]='fg=green'
FAST_HIGHLIGHT_STYLES[precommand]='fg=green,underline'
FAST_HIGHLIGHT_STYLES[commandseparator]='none'
FAST_HIGHLIGHT_STYLES[hashed-command]='fg=green'
FAST_HIGHLIGHT_STYLES[path]='fg=cyan'
FAST_HIGHLIGHT_STYLES[globbing]='fg=blue'
FAST_HIGHLIGHT_STYLES[history-expansion]='fg=blue'
FAST_HIGHLIGHT_STYLES[single-hyphen-option]='fg=cyan'
FAST_HIGHLIGHT_STYLES[double-hyphen-option]='fg=cyan'
FAST_HIGHLIGHT_STYLES[back-quoted-argument]='none'
FAST_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
FAST_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
FAST_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=cyan'
FAST_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=cyan'
FAST_HIGHLIGHT_STYLES[assign]='none'

# Chargement des completions personnalisées
fpath=(~/.zsh/completions $fpath)

# Message de bienvenue
if [[ -o interactive ]]; then
    echo "🚀 Zsh avec Zinit et Starship configuré avec succès!"
    echo "💡 Tapez 'help-zsh' pour voir les raccourcis disponibles"
fi

# Fonction d'aide
help-zsh() {
    echo "🔧 Raccourcis et commandes utiles:"
    echo "  Ctrl+R    : Recherche dans l'historique"
    echo "  Ctrl+A    : Début de ligne"
    echo "  Ctrl+E    : Fin de ligne"
    echo "  Ctrl+U    : Effacer jusqu'au début"
    echo "  Ctrl+K    : Effacer jusqu'à la fin"
    echo "  Ctrl+L    : Effacer l'écran"
    echo "  Tab       : Autocomplétion"
    echo "  ↑/↓       : Recherche dans l'historique par préfixe"
    echo ""
    echo "📁 Aliases de navigation:"
    echo "  ..        : cd .."
    echo "  ...       : cd ../.."
    echo "  ....      : cd ../../.."
    echo ""
    echo "🔍 Aliases Git:"
    echo "  gs        : git status"
    echo "  ga        : git add"
    echo "  gc        : git commit"
    echo "  gp        : git pull"
    echo "  gps       : git push"
    echo ""
    echo "📦 Aliases Pacman:"
    echo "  pacup     : sudo pacman -Syu"
    echo "  pacin     : sudo pacman -S"
    echo "  pacrm     : sudo pacman -R"
    echo "  pacsearch : pacman -Ss"
}
EOF

    print_success "Configuration Zsh créée dans $zshrc_path"
}

# Création de la configuration Starship
create_starship_config() {
    local user_home=$(get_user_home)
    local real_user=$(get_real_user)
    local starship_config="$user_home/.config/starship.toml"
    
    print_status "Création de la configuration Starship..."
    
    # Créer le répertoire de config
    sudo -u "$real_user" mkdir -p "$user_home/.config"
    
    # Créer la configuration Starship
    sudo -u "$real_user" tee "$starship_config" > /dev/null << 'EOF'
# Configuration Starship
# Format du prompt personnalisé

format = """
$username\
$hostname\
$directory\
$git_branch\
$git_state\
$git_status\
$git_metrics\
$fill\
$nodejs\
$python\
$rust\
$golang\
$java\
$kotlin\
$haskell\
$swift\
$terraform\
$docker_context\
$package\
$c\
$cmake\
$dart\
$deno\
$dotnet\
$elixir\
$elm\
$erlang\
$fennel\
$lua\
$nim\
$ocaml\
$opa\
$perl\
$php\
$pulumi\
$purescript\
$red\
$ruby\
$scala\
$solidity\
$vlang\
$vcsh\
$zig\
$buf\
$nix_shell\
$conda\
$meson\
$spack\
$memory_usage\
$aws\
$gcloud\
$openstack\
$azure\
$env_var\
$crystal\
$custom\
$sudo\
$cmd_duration\
$line_break\
$jobs\
$battery\
$time\
$status\
$os\
$container\
$shell\
$character"""

# Attendez avant de continuer avec la prochaine commande
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

# Répertoire actuel
[directory]
style = "bold cyan"
read_only = "🔒"
truncation_length = 3
truncate_to_repo = true

# Informations Git
[git_branch]
symbol = "🌱 "
style = "bold purple"

[git_status]
style = "red"
ahead = "⇡${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
behind = "⇣${count}"
deleted = "✘"
renamed = "»"
modified = "!"
staged = "+"
untracked = "?"

[git_state]
format = '[\($state( $progress_current of $progress_total)\)]($style) '
cherry_pick = "[🍒 PICKING](bold red)"

[git_metrics]
added_style = "bold blue"
format = '[+$added]($added_style)/[-$deleted]($deleted_style) '

# Langages de programmation
[nodejs]
symbol = "⬢ "
style = "bold green"

[python]
symbol = "🐍 "
style = "bold yellow"

[rust]
symbol = "⚙️ "
style = "bold red"

[golang]
symbol = "🐹 "
style = "bold cyan"

[java]
symbol = "☕ "
style = "bold red"

[docker_context]
symbol = "🐳 "
style = "bold blue"

# Durée de la commande
[cmd_duration]
min_time = 2000
format = "⏱️ [$duration]($style) "
style = "bold yellow"

# Statut de la dernière commande
[status]
symbol = "🔴"
success_symbol = "🟢"
format = '[\[$symbol $common_meaning$signal_name$maybe_int\]]($style) '
map_symbol = true
disabled = false

# Utilisateur
[username]
style_user = "bold blue"
style_root = "bold red"
format = "[$user]($style) "
disabled = false
show_always = true

# Nom d'hôte
[hostname]
ssh_only = false
format = "[@$hostname]($style) "
style = "bold green"
disabled = false

# Heure
[time]
disabled = false
format = '🕙[\[ $time \]]($style) '
time_format = "%T"
style = "bold white"

# Mémoire
[memory_usage]
disabled = false
threshold = 70
symbol = "🐏 "
style = "bold dimmed red"

# Tâches en arrière-plan
[jobs]
symbol = "🏃‍♀️ "
style = "bold red"

# Batterie
[battery]
full_symbol = "🔋 "
charging_symbol = "⚡️ "
discharging_symbol = "💀 "

[[battery.display]]
threshold = 10
style = "bold red"

[[battery.display]]
threshold = 30
style = "bold yellow"

# Environnement Conda
[conda]
symbol = "🅒 "
style = "bold green"

# Variables d'environnement
[env_var]
variable = "SHELL"
default = "unknown shell"
EOF

    print_success "Configuration Starship créée dans $starship_config"
}

# Finalisation de l'installation
finalize_installation() {
    local user_home=$(get_user_home)
    local real_user=$(get_real_user)
    
    print_status "Finalisation de l'installation..."
    
    # Changer la propriété des fichiers
    chown -R "$real_user:$real_user" "$user_home/.zshrc" "$user_home/.config" "$user_home/.local" 2>/dev/null || true
    
    print_success "Installation terminée avec succès! 🎉"
    print_status ""
    print_status "Prochaines étapes:"
    print_status "1. Redémarrez votre terminal ou exécutez: exec zsh"
    print_status "2. Les plugins se chargeront automatiquement au premier démarrage"
    print_status "3. Tapez 'help-zsh' pour voir les raccourcis disponibles"
    print_status "4. Vous pouvez personnaliser Starship en éditant ~/.config/starship.toml"
    print_status ""
    print_status "Fonctionnalités installées:"
    print_status "• Zsh avec Zinit comme gestionnaire de plugins"
    print_status "• Starship comme prompt moderne"
    print_status "• Coloration syntaxique"
    print_status "• Autocomplétion avancée"
    print_status "• Suggestions automatiques"
    print_status "• Recherche dans l'historique"
    print_status "• Aliases utiles pour Git, Pacman, etc."
    print_status "• Polices Nerd Fonts pour les icônes"
}

# Fonction principale
main() {
    print_status "🚀 Démarrage de l'installation Zsh + Zinit + Starship"
    print_status "=================================================="
    
    check_privileges
    install_system_packages
    install_starship
    configure_default_shell
    install_zinit
    create_zsh_config
    create_starship_config
    finalize_installation
    
    print_success "🎉 Installation complète! Profitez de votre nouveau shell!"
}

# Gestion des signaux pour un arrêt propre
trap 'print_error "Installation interrompue par l'\''utilisateur"; exit 1' INT TERM

# Exécution du script principal
main "$@"