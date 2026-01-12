#!/usr/bin/env bash
set -euo pipefail

FONT_NAME="JetBrainsMono"
FONT_ZIP="JetBrainsMono.zip"
FONT_DL_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"

echo "=== Installation Zsh + Antidote + plugins (Arch Linux) ==="

# Check for pacman (Arch, EndeavourOS, Manjaro, etc.)
if ! command -v pacman >/dev/null 2>&1; then
  echo "ERROR: pacman not found. This script is for Arch Linux and Arch-based distributions only."
  exit 1
fi

echo "Detected Arch Linux or Arch-based distribution"

echo "Installing prerequisites (zsh, git, curl, unzip, oh-my-posh)..."
sudo pacman -S --noconfirm --needed zsh git curl unzip oh-my-posh

echo ""
echo "=== Prompt Theme Selection ==="
echo "1) Oh My Posh with Catppuccin Mocha (default)"
echo "2) Powerlevel10k"
echo ""
read -p "Choose a theme (1 or 2, default 1): " THEME_CHOICE
THEME_CHOICE=${THEME_CHOICE:-1}

echo "Installing Antidote (zsh plugin manager)..."
ANTIDOTE_DIR="${ZDOTDIR:-$HOME}/.antidote"
if [ -d "$ANTIDOTE_DIR" ]; then
  echo "Antidote already present at $ANTIDOTE_DIR"
else
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

echo "Creating .zsh_plugins.txt with requested plugins..."
ZSH_PLUGINS_FILE="${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
cat > "$ZSH_PLUGINS_FILE" <<'EOF'
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-completions
zsh-users/zsh-history-substring-search
EOF

echo "Backing up existing .zshrc to .zshrc.bak if present..."
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
if [ -f "$ZSHRC" ] && [ ! -f "${ZSHRC}.bak" ]; then
  cp "$ZSHRC" "${ZSHRC}.bak"
  echo "Backup created: ${ZSHRC}.bak"
fi

echo "Configuring .zshrc to load Antidote and plugins..."
grep -q "antidote.zsh" "$ZSHRC" 2>/dev/null || cat >> "$ZSHRC" <<EOF
# Antidote (zsh plugin manager)
source "${ANTIDOTE_DIR}/antidote.zsh"
antidote load "${ZSH_PLUGINS_FILE}"
EOF

echo "Downloading Oh My Posh Catppuccin Mocha theme..."
OMP_THEME_DIR="${ZDOTDIR:-$HOME}/.config/omp"
mkdir -p "$OMP_THEME_DIR"
OMP_THEME_URL="https://raw.githubusercontent.com/catppuccin/oh-my-posh/main/themes/catppuccin_mocha.omp.json"
OMP_THEME_FILE="$OMP_THEME_DIR/catppuccin_mocha.omp.json"

if [ "$THEME_CHOICE" = "1" ]; then
  if [ ! -f "$OMP_THEME_FILE" ]; then
    curl -s -o "$OMP_THEME_FILE" "$OMP_THEME_URL"
    echo "Theme downloaded to $OMP_THEME_FILE"
  fi
elif [ "$THEME_CHOICE" = "2" ]; then
  echo "Installing Powerlevel10k..."
  P10K_DIR="${ZDOTDIR:-$HOME}/.powerlevel10k"
  if [ ! -d "$P10K_DIR" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    echo "Powerlevel10k installed to $P10K_DIR"
  else
    echo "Powerlevel10k already present at $P10K_DIR"
  fi
fi

echo "Adding zsh best-practice configurations to .zshrc..."
grep -q "# ===== Zsh Configuration Start" "$ZSHRC" 2>/dev/null || cat >> "$ZSHRC" <<'EOF'

# ===== Zsh Configuration Start =====

# Locale and UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# History improvements
export HISTSIZE=20000
export SAVEHIST=20000
export HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
setopt inc_append_history            # append history as commands are entered
setopt share_history                 # share history across sessions
setopt append_history                # append, don't overwrite
setopt hist_ignore_all_dups          # ignore duplicate entries

# Shell options
setopt no_nomatch                    # no error if pattern doesn't match
setopt extended_glob                # extended glob patterns

# PATH management (prepend user bins)
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Completion
autoload -Uz compinit
compinit -u

# Plugin-specific tweaks
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Key bindings for zsh-history-substring-search
bindkey '^R' history-incremental-search-backward
bindkey '\e[A' history-substring-search-up
bindkey '\e[B' history-substring-search-down

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias gs='git status'
alias gcam='git commit -am'
alias gco='git checkout'

# Prompt Theme Configuration
if [ "$THEME_CHOICE" = "1" ]; then
  # Oh My Posh with Catppuccin Mocha theme
  if command -v oh-my-posh >/dev/null 2>&1; then
    eval "$(oh-my-posh init zsh --config ${ZDOTDIR:-$HOME}/.config/omp/catppuccin_mocha.omp.json)"
  fi
elif [ "$THEME_CHOICE" = "2" ]; then
  # Powerlevel10k
  if [ -d "${ZDOTDIR:-$HOME}/.powerlevel10k" ]; then
    source "${ZDOTDIR:-$HOME}/.powerlevel10k/powerlevel10k.zsh-theme"
  fi
  # To customize Powerlevel10k, run: p10k configure
fi

# ===== Zsh Configuration End =====
EOF

echo "Installing Nerd Font (${FONT_NAME})..."
OSNAME=$(uname -s)
TMPDIR=$(mktemp -d)
pushd "$TMPDIR" >/dev/null
echo "Downloading ${FONT_DL_URL}..."
curl -L -o "${FONT_ZIP}" "$FONT_DL_URL"
unzip -q "${FONT_ZIP}"

if [ "$OSNAME" = "Darwin" ]; then
  echo "Installing fonts to ~/Library/Fonts"
  mkdir -p "$HOME/Library/Fonts"
  find . -type f -name "*.ttf" -exec cp {} "$HOME/Library/Fonts/" \;
else
  echo "Installing fonts to ~/.local/share/fonts"
  mkdir -p "$HOME/.local/share/fonts"
  find . -type f -name "*.ttf" -exec cp {} "$HOME/.local/share/fonts/" \;
  fc-cache -fv || true
fi
popd >/dev/null
rm -rf "$TMPDIR"

echo "Finished. You may need to change your default shell to zsh:"
echo "  chsh -s \\$(command -v zsh)"
echo "Restart your terminal session to apply changes."

echo "Notes:"
echo "- Antidote is installed to $ANTIDOTE_DIR. Your plugins list is $ZSH_PLUGINS_FILE."
echo "- If you use Oh My Zsh, you can include its plugins in the .zsh_plugins.txt as documented by Antidote."

exit 0
