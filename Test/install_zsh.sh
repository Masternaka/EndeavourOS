#!/usr/bin/env bash

set -euo pipefail
# Vérification des dépendances nécessaires
for dep in git curl fc-cache; do
  if ! command -v "$dep" &>/dev/null; then
    echo "> Erreur : dépendance manquante : $dep. Veuillez l'installer."
    exit 1
  fi
done

### Variables
ZINIT_HOME="${ZINIT_HOME:-$HOME/.zinit}"
ZSHRC="$HOME/.zshrc"
OMPOSH_BIN="/usr/local/bin/oh-my-posh"
FONTS_DIR="$HOME/.local/share/fonts"

### Fonctions auxiliaires
install_package() {
  if command -v apt &>/dev/null; then
    sudo apt update && sudo apt install -y "$@"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$@"
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm "$@"
  else
    echo "Unsupported package manager" >&2
    exit 1
  fi
}

### 1. Installer Zsh s'il n'existe pas
if ! command -v zsh &>/dev/null; then
  echo "> Installing Zsh..."
  install_package zsh && ZSH_INSTALLED=1 || ZSH_INSTALLED=0
  # Création du fichier .zshrc s'il n'existe pas
  if [[ ! -f "$ZSHRC" ]]; then
    echo "> Creating $ZSHRC..."
    touch "$ZSHRC"
    ZSHRC_CREATED=1
  else
    ZSHRC_CREATED=0
  fi
else
  echo "> Zsh already installed."
  # Création du fichier .zshrc s'il n'existe pas
  if [[ ! -f "$ZSHRC" ]]; then
    echo "> Creating $ZSHRC..."
    touch "$ZSHRC"
    ZSHRC_CREATED=1
  else
    ZSHRC_CREATED=0
  fi
fi

### 2. Définir Zsh comme shell par défaut
if [[ "$SHELL" != *zsh ]]; then
  echo "> Changing default shell to zsh..."
  if [ "$EUID" -eq 0 ]; then
    echo "> Erreur : Ne pas exécuter ce script en tant que root pour changer le shell."
    exit 1
  fi
  CURRENT_SHELL=$(basename "$SHELL")
  if [ "$CURRENT_SHELL" != "zsh" ]; then
    chsh -s "$(command -v zsh)" && SHELL_CHANGED=1 || SHELL_CHANGED=0
  fi
fi

### 3. Installer Zinit (anciennement zinit)
if [[ ! -d "$ZINIT_HOME" ]]; then
  echo "> Installing Zinit..."
  mkdir -p "$ZINIT_HOME" && \
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME/bin" && ZINIT_INSTALLED=1 || ZINIT_INSTALLED=0
else
  echo "> Zinit already installed."
fi

### 4. Installer Oh My Posh
if [[ ! -x "$OMPOSH_BIN" ]]; then
  echo "> Installing Oh My Posh..."
  sudo curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin && OMPOSH_INSTALLED=1 || OMPOSH_INSTALLED=0
else
  echo "> Oh My Posh already installed."
fi

### 5. Télécharger Nerd Fonts (Hack)
echo "> Installing Nerd Fonts (Hack)..."
mkdir -p "$FONTS_DIR"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/complete/Hack%20Nerd%20Font%20Complete.ttf"
curl -fLo "$FONTS_DIR/HackNerdFont-Regular.ttf" "$FONT_URL" && FONT_INSTALLED=1 || FONT_INSTALLED=0
fc-cache -fv

### 6. Ajouter config à ~/.zshrc (si pas déjà fait)
if ! grep -q "zinit light" "$ZSHRC" 2>/dev/null; then
  echo "> Adding Zinit plugins and Oh My Posh config to .zshrc"
  cat <<'EOF' >> "$ZSHRC"

### Zinit plugins
source "$HOME/.zinit/bin/zinit.zsh"
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-history-substring-search

### Oh My Posh init
eval "$(oh-my-posh init zsh --config $(oh-my-posh get theme agnosterplus))"
EOF
  ZSHRC_CONFIGURED=1
else
  echo "> .zshrc already configured."
  ZSHRC_CONFIGURED=0
fi

### 7. Terminé
echo ">✅ Installation complète. Relance ton terminal ou exécute 'exec zsh' pour activer."
echo "\n--- Résumé ---"
echo "Zsh installé : ${ZSH_INSTALLED:-déjà présent}"
echo "Shell changé : ${SHELL_CHANGED:-déjà zsh}"
echo ".zshrc créé : ${ZSHRC_CREATED:-déjà présent}"
echo "Zinit installé : ${ZINIT_INSTALLED:-déjà présent}"
echo "Oh My Posh installé : ${OMPOSH_INSTALLED:-déjà présent}"
echo "Police Hack Nerd Font installée : ${FONT_INSTALLED:-déjà présente}"
echo ".zshrc configuré : ${ZSHRC_CONFIGURED:-déjà configuré}"
