#!/usr/bin/env bash

###############################################################################
# Script d'installation Zsh + Zinit + Oh My Posh (Catppuccin) pour Arch/EndeavourOS
#
# Description:
# - Installe Zsh, Zinit, Oh My Posh, une Nerd Font, et configure un thème Catppuccin
# - Ajoute les plugins Zsh: zsh-completions, zsh-autosuggestions,
#   zsh-history-substring-search, zsh-syntax-highlighting (chargé en dernier)
# - Modifie le shell par défaut uniquement si nécessaire
# - N'écrase pas votre ~/.zshrc: crée une sauvegarde et ajoute un bloc géré
#
# Prérequis:
# - Système basé Arch (EndeavourOS/Arch) avec pacman
# - Droits administrateur (sudo/root)
# - Connexion internet
#
# Utilisation rapide:
# 1. Sauvegardez ce script: install-zsh-env.sh
# 2. Rendez-le exécutable: chmod +x install-zsh-env.sh
# 3. Exécutez-le: sudo ./install-zsh-env.sh [options]
#
# Options:
#   --dry-run         Simule les actions sans rien modifier
#   --verbose         Affiche des logs détaillés
#   --theme NAME      Variante Catppuccin: latte | frappe | macchiato | mocha
#   --theme-url URL   URL d'un thème Oh My Posh (prioritaire sur --theme)
#   -h, --help        Affiche l'aide et quitte
#
# Exemples:
#   sudo ./install-zsh-env.sh --dry-run
#   sudo ./install-zsh-env.sh --verbose --theme macchiato
#   sudo ./install-zsh-env.sh --theme-url https://exemple/mon_theme.omp.json
#
# Notes:
# - Le thème est téléchargé dans ~/.poshtheme.omp.json
# - La configuration ajoutée est délimitée par: # >>> zsh-setup managed block >>>
# - Le script est idempotent: réexécutable sans casser l'environnement
###############################################################################

set -euo pipefail
IFS=$'\n\t'

# Gestion d'erreurs globale
trap 'echo "❗ Une erreur est survenue à la ligne ${LINENO}. Arrêt." >&2' ERR

# -------------------- Options CLI --------------------
DRY_RUN=false
VERBOSE=false
THEME_FLAG_SET=false
THEME_NAME=${THEME_NAME:-"catppuccin"}
THEME_URL=${THEME_URL:-"https://raw.githubusercontent.com/catppuccin/oh-my-posh/main/themes/catppuccin_mocha.omp.json"}

print_usage() {
  cat <<USAGE
Usage: sudo $0 [options]

Options:
  --dry-run       Simuler les actions sans rien modifier
  --verbose       Afficher des logs détaillés
  --theme NAME    Nom du thème (par défaut: catppuccin)
  --theme-url URL URL du thème OMP (prioritaire sur --theme)
  -h, --help      Afficher cette aide
USAGE
}

while [[ ${1:-} ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ; shift ;;
    --verbose) VERBOSE=true ; shift ;;
    --theme) THEME_NAME="$2" ; THEME_FLAG_SET=true ; shift 2 ;;
    --theme-url) THEME_URL="$2" ; THEME_FLAG_SET=true ; shift 2 ;;
    -h|--help) print_usage ; exit 0 ;;
    *) echo "Argument inconnu: $1" >&2 ; print_usage ; exit 1 ;;
  esac
done

if [[ "$VERBOSE" == true ]]; then
  set -x
fi

run() {
  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

# --- Vérifications préliminaires ---
if [[ $EUID -ne 0 ]]; then
  echo "❌ Ce script doit être exécuté en tant que root (sudo)." >&2
  exit 1
fi

# --- Paquets requis ---
echo "📦 Installation des dépendances..."
run pacman -Sy --noconfirm --needed zsh git curl wget unzip || {
  echo "❌ Impossible de mettre à jour la base de paquets ou d’installer les dépendances." >&2
  exit 1
}

# --- Installation de Oh My Posh ---
echo "✨ Installation de Oh My Posh..."
if ! command -v oh-my-posh &>/dev/null; then
  # Tentative via les dépôts officiels (si disponible)
  if pacman -Si oh-my-posh &>/dev/null; then
    run pacman -S --noconfirm --needed oh-my-posh || true
  fi
  # Repli via script officiel si la commande n'est toujours pas disponible
  if ! command -v oh-my-posh &>/dev/null; then
    echo "↘️ Repli: installation via le script officiel (HTTPS)"
    if [[ "$DRY_RUN" == true ]]; then
      echo "[dry-run] curl -fsSL https://ohmyposh.dev/install.sh | bash -s"
    else
      curl -fsSL https://ohmyposh.dev/install.sh | bash -s || {
        echo "❌ Échec de l’installation de Oh My Posh." >&2
        exit 1
      }
    fi
  fi
else
  echo "ℹ️ Oh My Posh est déjà installé."
fi

# --- Installation de Zinit ---
ZINIT_DIR="/usr/local/share/zinit/zinit.git"
if [[ ! -d $ZINIT_DIR ]]; then
  echo "⚙️ Installation de Zinit..."
  run install -d -m 0755 "$ZINIT_DIR"
  # Cloner dans un répertoire parent puis déplacer pour conserver les permissions
  tmp_dir=$(mktemp -d)
  run git clone https://github.com/zdharma-continuum/zinit.git "$tmp_dir/zinit.git"
  run cp -a "$tmp_dir/zinit.git/." "$ZINIT_DIR/"
  run rm -rf "$tmp_dir"
else
  echo "ℹ️ Zinit est déjà présent."
fi

# --- Configuration Zsh utilisateur ---
# Détermination robuste de l’utilisateur cible
USER_NAME=${SUDO_USER:-$(logname 2>/dev/null || true)}
if [[ -z "${USER_NAME:-}" ]]; then
  USER_NAME=$(id -un)
fi
USER_HOME=$(eval echo "~$USER_NAME")
ZSHRC="$USER_HOME/.zshrc"

echo "🧩 Configuration de Zsh pour l’utilisateur $USER_NAME..."

# Sauvegarde éventuelle et append via marqueurs pour éviter d’écraser la conf
timestamp=$(date +%Y%m%d-%H%M%S)
if [[ -f "$ZSHRC" && -z "$(grep -F "# >>> zsh-setup managed block >>>" "$ZSHRC" || true)" ]]; then
  run cp -a "$ZSHRC" "${ZSHRC}.backup-${timestamp}"
  echo "💾 Sauvegarde de .zshrc -> ${ZSHRC}.backup-${timestamp}"
fi

run sudo -u "$USER_NAME" touch "$ZSHRC"
if ! grep -Fq "# >>> zsh-setup managed block >>>" "$ZSHRC"; then
  cat >> "$ZSHRC" <<'EOF'
# >>> zsh-setup managed block >>>
# --- Configuration Zsh ---
export ZINIT_HOME="/usr/local/share/zinit/zinit.git"
source "$ZINIT_HOME/zinit.zsh"

# --- Plugins Zinit ---
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light zsh-users/zsh-syntax-highlighting

# --- Oh My Posh ---
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config ~/.poshtheme.omp.json)"
fi

# --- Prompt coloré ---
autoload -Uz compinit && compinit
autoload -Uz colors && colors

# --- Alias utiles ---
alias ls='ls --color=auto'
alias ll='ls -lah'
# <<< zsh-setup managed block <<<
EOF
else
  echo "ℹ️ Bloc de configuration déjà présent dans $ZSHRC."
fi

# --- Téléchargement d’un thème Oh My Posh ---
echo "🎨 Installation du thème Oh My Posh..."
run sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.config/oh-my-posh"

# Sélection du thème (priorité: THEME_URL > THEME_NAME)
THEME_DEST="$USER_HOME/.poshtheme.omp.json"
# Choix interactif si aucun flag fourni et terminal interactif
if [[ "$THEME_FLAG_SET" != true && -t 0 && -t 1 && "$DRY_RUN" == false ]]; then
  echo "Souhaitez-vous choisir une variante Catppuccin ?"
  echo "1) latte (clair)"
  echo "2) frappe"
  echo "3) macchiato"
  echo "4) mocha (foncé)"
  echo -n "Votre choix [4]: "
  read -r choice || true
  case "${choice:-4}" in
    1) THEME_NAME="catppuccin-latte" ; THEME_URL="https://raw.githubusercontent.com/catppuccin/oh-my-posh/main/themes/catppuccin_latte.omp.json" ;;
    2) THEME_NAME="catppuccin-frappe" ; THEME_URL="https://raw.githubusercontent.com/catppuccin/oh-my-posh/main/themes/catppuccin_frappe.omp.json" ;;
    3) THEME_NAME="catppuccin-macchiato" ; THEME_URL="https://raw.githubusercontent.com/catppuccin/oh-my-posh/main/themes/catppuccin_macchiato.omp.json" ;;
    4|*) THEME_NAME="catppuccin-mocha" ; THEME_URL="https://raw.githubusercontent.com/catppuccin/oh-my-posh/main/themes/catppuccin_mocha.omp.json" ;;
  esac
fi
if [[ -n "${THEME_URL:-}" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] curl -fsSL -o '$THEME_DEST' '$THEME_URL'"
  else
    if ! sudo -u "$USER_NAME" curl -fsSL -o "$THEME_DEST" "$THEME_URL"; then
      echo "⚠️ Impossible de télécharger le thème depuis THEME_URL. Étape ignorée." >&2
    fi
  fi
else
  case "$THEME_NAME" in
    catppuccin|catppuccin-mocha|mocha)
      THEME_URL="https://raw.githubusercontent.com/catppuccin/oh-my-posh/main/themes/catppuccin_mocha.omp.json" ;;
    catppuccin-latte|latte)
      THEME_URL="https://raw.githubusercontent.com/catppuccin/oh-my-posh/main/themes/catppuccin_latte.omp.json" ;;
    catppuccin-frappe|frappe)
      THEME_URL="https://raw.githubusercontent.com/catppuccin/oh-my-posh/main/themes/catppuccin_frappe.omp.json" ;;
    catppuccin-macchiato|macchiato)
      THEME_URL="https://raw.githubusercontent.com/catppuccin/oh-my-posh/main/themes/catppuccin_macchiato.omp.json" ;;
    *)
      THEME_URL="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/paradox.omp.json" ;;
  esac
  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] curl -fsSL -o '$THEME_DEST' '$THEME_URL'"
  else
    sudo -u "$USER_NAME" curl -fsSL -o "$THEME_DEST" "$THEME_URL" || echo "⚠️ Impossible de télécharger le thème ($THEME_NAME)." >&2
  fi
fi

if [[ "$VERBOSE" == true ]]; then
  echo "Thème sélectionné: ${THEME_NAME} -> ${THEME_URL}"
  echo "Chemin du thème: $THEME_DEST"
fi

# --- Installation de Nerd Fonts (pour les symboles Oh My Posh) ---
echo "🔤 Installation d’une police Nerd Fonts..."
# Tentative via pacman si disponible
if pacman -Si ttf-meslo-nerd &>/dev/null; then
  run pacman -S --noconfirm --needed ttf-meslo-nerd || true
fi

if ! fc-list | grep -qi "MesloLGS Nerd Font"; then
  run sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.local/share/fonts"
  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] curl -fsSL -o '$USER_HOME/.local/share/fonts/MesloLGSNerdFont-Regular.ttf' 'https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Regular/MesloLGSNerdFont-Regular.ttf'"
  else
    if sudo -u "$USER_NAME" curl -fsSL -o "$USER_HOME/.local/share/fonts/MesloLGSNerdFont-Regular.ttf" \
      https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Regular/MesloLGSNerdFont-Regular.ttf; then
      run fc-cache -fv >/dev/null
    else
      echo "⚠️ Impossible d’installer la police Meslo Nerd Font. Étape ignorée." >&2
    fi
  fi
else
  echo "ℹ️ Police Meslo Nerd Font déjà disponible."
fi

# --- Changement du shell par défaut ---
echo "🔁 Passage de Bash à Zsh..."
zsh_path="$(command -v zsh || true)"
if [[ -z "${zsh_path:-}" ]]; then
  echo "❌ Zsh n’est pas installé correctement (binaire introuvable)." >&2
  exit 1
fi
current_shell=$(getent passwd "$USER_NAME" | cut -d: -f7 || echo "")
if [[ "$current_shell" != "$zsh_path" ]]; then
  run chsh -s "$zsh_path" "$USER_NAME"
else
  echo "ℹ️ Zsh est déjà le shell par défaut pour $USER_NAME."
fi

echo "✅ Installation terminée !"
echo "👉 Déconnectez-vous / reconnectez-vous pour activer Zsh et Oh My Posh."
