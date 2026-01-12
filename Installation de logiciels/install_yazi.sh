#!/bin/bash

# Script d'installation et configuration de Yazi pour Arch Linux
# Yazi est un gestionnaire de fichiers modal, rapide et full-featured écrit en Rust

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        Installation et Configuration de Yazi              ║"
echo "║           Gestionnaire de fichiers moderne                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Vérifier si on est sur Arch Linux
if ! command -v pacman &> /dev/null; then
    echo "❌ Ce script est conçu pour Arch Linux"
    exit 1
fi

# Installation de yazi
echo "📦 Installation de Yazi..."
sudo pacman -S --noconfirm yazi

# Installation des dépendances recommandées
echo "📦 Installation des dépendances recommandées..."
sudo pacman -S --noconfirm \
    ueberzug+ \
    jq \
    poppler \
    fd \
    ripgrep \
    fzf \
    zoxide

# Créer la structure de configuration
echo "🔧 Création de la structure de configuration..."
mkdir -p ~/.config/yazi/{plugins,flavors}

# Configuration principale (yazi.toml)
echo "📝 Configuration principale..."
cat > ~/.config/yazi/yazi.toml << 'EOF'
# Configuration complète de Yazi

# Manager configuration
[manager]
ratio = [1, 4, 3]
sort_by = "modified"
sort_reverse = false
sort_dir_first = true
linemode = "permissions"
show_hidden = false
scrolloff = 5

# Prévieweur
[preview]
uifmt = "kitty"  # ou "sixel" pour d'autres terminaux

# Comportement
[behavior]
# Quitter après exécuter des fichiers
quit_on_run = false
# Recharger les répertoires automatiquement
auto_reload = true
# Rester au premier enfant lors de la navigation
stay_first = false

# Thème
[theme]
# Couleur de sélection active
active = { fg = "white", bg = "blue", bold = true }
# Couleur des fichiers modifiés
modified = { fg = "yellow" }
# Couleur des liens symboliques
symlink = { fg = "cyan" }

# Images
[image]
protocol = "sixel"

EOF

# Fichier de configuration des keybindings (keymap.toml)
echo "⌨️  Configuration des raccourcis clavier..."
cat > ~/.config/yazi/keymap.toml << 'EOF'
# Configuration complète des keybindings de Yazi

[[manager.keymap]]
on = [ "c" ]
run = "create"
desc = "Create a new file or folder"

[[manager.keymap]]
on = [ "r" ]
run = "rename"
desc = "Rename the selected file"

[[manager.keymap]]
on = [ "y" ]
run = "copy"
desc = "Copy the selected files"

[[manager.keymap]]
on = [ "x" ]
run = "cut"
desc = "Cut the selected files"

[[manager.keymap]]
on = [ "p" ]
run = "paste"
desc = "Paste the files"

[[manager.keymap]]
on = [ "d" ]
run = "remove"
desc = "Delete the selected files"

[[manager.keymap]]
on = [ "u" ]
run = "undo"
desc = "Undo the last operation"

# Navigation
[[manager.keymap]]
on = [ "k" ]
run = "arrow -1"
desc = "Move cursor up"

[[manager.keymap]]
on = [ "j" ]
run = "arrow 1"
desc = "Move cursor down"

[[manager.keymap]]
on = [ "h" ]
run = "leave"
desc = "Go to parent directory"

[[manager.keymap]]
on = [ "l" ]
run = "enter"
desc = "Enter the selected directory"

[[manager.keymap]]
on = [ "K" ]
run = "arrow -5"
desc = "Move cursor up (5 steps)"

[[manager.keymap]]
on = [ "J" ]
run = "arrow 5"
desc = "Move cursor down (5 steps)"

# Search and filter
[[manager.keymap]]
on = [ "/" ]
run = "find"
desc = "Find files"

[[manager.keymap]]
on = [ "?" ]
run = "find --reverse"
desc = "Find files (reverse)"

[[manager.keymap]]
on = [ "f" ]
run = "filter"
desc = "Filter files"

# Selection
[[manager.keymap]]
on = [ "v" ]
run = "select_all --state=toggle"
desc = "Toggle selection on all files"

[[manager.keymap]]
on = [ "V" ]
run = "select_all --state=true"
desc = "Select all files"

# Sorting
[[manager.keymap]]
on = [ "s" ]
run = "sort modified --reverse=no"
desc = "Sort by modification time"

[[manager.keymap]]
on = [ "S" ]
run = "sort modified --reverse=yes"
desc = "Sort by modification time (reverse)"

# Help and info
[[manager.keymap]]
on = [ "?" ]
run = "help"
desc = "Show help"

# Exit
[[manager.keymap]]
on = [ "q" ]
run = "quit"
desc = "Quit yazi"

# Prévieweur
[[preview.keymap]]
on = [ "j" ]
run = "arrow 1"
desc = "Scroll down"

[[preview.keymap]]
on = [ "k" ]
run = "arrow -1"
desc = "Scroll up"

[[preview.keymap]]
on = [ "q" ]
run = "quit"
desc = "Quit preview"

EOF

# Theme personnalisé (flavors)
echo "🎨 Configuration du thème..."
cat > ~/.config/yazi/theme.toml << 'EOF'
# Configuration du thème Yazi - Catppuccin Mocha

[colors]
# Palette Catppuccin Mocha
# Source: https://github.com/catppuccin/catppuccin

# Couleurs principales
foreground = "#cdd6f4"
background = "#1e1e2e"

# Couleurs spécifiques (Catppuccin Mocha)
black = "#45475a"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#cba6f7"
cyan = "#94e2d5"
white = "#cdd6f4"

# Couleurs du contraste élevé
bright_black = "#6c7086"
bright_red = "#f38ba8"
bright_green = "#a6e3a1"
bright_yellow = "#f9e2af"
bright_blue = "#89b4fa"
bright_magenta = "#cba6f7"
bright_cyan = "#94e2d5"
bright_white = "#f5e0dc"

[ui]
# Couleurs de l'interface utilisateur (Catppuccin Mocha)

# Barre d'état
status_bar = { fg = "#1e1e2e", bg = "#89b4fa", bold = true }
status_bar_mode = { fg = "#1e1e2e", bg = "#cba6f7", bold = true }

# Fichiers sélectionnés
selection = { fg = "#1e1e2e", bg = "#a6e3a1", bold = true }

# Fichiers modifiés
modified = { fg = "#f9e2af", bold = true }

# Liens symboliques
symlink = { fg = "#94e2d5", bold = true }

# Répertoires
folder = { fg = "#89b4fa", bold = true }

# Fichiers exécutables
executable = { fg = "#a6e3a1", bold = true }

EOF

# Script d'initialisation shell
echo "🐚 Configuration shell (init)..."
cat > ~/.config/yazi/init.sh << 'EOF'
#!/bin/bash
# Script d'initialisation pour Yazi
# Ajoute des alias et des fonctions utiles

# Alias pour yazi
alias y='yazi'
alias ya='yazi --chooser-file'

# Fonction pour changer de répertoire après avoir fermé yazi
function yz() {
    local chosen=$(yazi "$@" --chooser-file /tmp/yazi-chooser.txt; cat /tmp/yazi-chooser.txt)
    if [ -n "$chosen" ]; then
        if [ -f "$chosen" ]; then
            builtin cd "$(dirname "$chosen")"
        else
            builtin cd "$chosen"
        fi
    fi
}

export YAZI_FILE_ONE=1

EOF
chmod +x ~/.config/yazi/init.sh

# Script de plugins populaires
echo "🔌 Configuration des plugins recommandés..."
cat > ~/.config/yazi/plugins.toml << 'EOF'
# Configuration des plugins Yazi
# Les plugins augmentent les fonctionnalités de Yazi

[[plugin]]
name = "max-preview"
repo = "yazi-rs/plugins:max-preview"

[[plugin]]
name = "sudo"
repo = "yazi-rs/plugins:sudo"

[[plugin]]
name = "fast-enter"
repo = "yazi-rs/plugins:fast-enter"

EOF

# Archive de configurations de plugins
echo "📥 Téléchargement des plugins..."
mkdir -p ~/.config/yazi/plugins
cd ~/.config/yazi/plugins

# Plugin max-preview pour un meilleur aperçu
if [ ! -d "max-preview" ]; then
    git clone https://github.com/yazi-rs/plugins.git yazi-plugins 2>/dev/null || true
    if [ -d "yazi-plugins/max-preview" ]; then
        cp -r yazi-plugins/max-preview . 2>/dev/null || true
    fi
    rm -rf yazi-plugins 2>/dev/null || true
fi

cd ~

# Créer un fichier de documentation
echo "📚 Création du fichier de documentation..."
cat > ~/.config/yazi/README.md << 'EOF'
# Configuration de Yazi

Yazi est un gestionnaire de fichiers modal, rapide et full-featured écrit en Rust.

## Keybindings principaux

### Navigation
- `k` / `j` - Monter / Descendre
- `h` / `l` - Parent / Entrer
- `K` / `J` - Monter/Descendre (5 étapes)
- `Home` / `End` - Début / Fin
- `:` - Exécuter une commande

### Édition
- `c` - Créer un fichier/dossier
- `r` - Renommer
- `y` - Copier
- `x` - Couper
- `p` - Coller
- `d` - Supprimer
- `u` - Annuler

### Sélection
- `Space` - Sélectionner
- `v` - Basculer tous
- `V` - Sélectionner tous

### Recherche
- `/` - Chercher
- `?` - Chercher (inverse)
- `f` - Filtrer

### Tri
- `s` - Trier par modification
- `S` - Trier par modification (inverse)

### Autres
- `~` - Aller à la maison
- `?` - Aide
- `q` - Quitter

## Fichiers de configuration

- `yazi.toml` - Configuration principale
- `keymap.toml` - Raccourcis clavier
- `theme.toml` - Thème et couleurs
- `plugins.toml` - Configuration des plugins

## Variables d'environnement utiles

```bash
export YAZI_FILE_ONE=1  # Ouvrir le fichier sélectionné avec Enter
export YZ_SORT_BY="modified"  # Tri par défaut
```

## Intégration avec le shell

Ajoutez à votre `.bashrc` ou `.zshrc`:

```bash
source ~/.config/yazi/init.sh
```

## Plugins recommandés

- `max-preview` - Aperçu amélioré
- `sudo` - Exécuter avec sudo
- `fast-enter` - Entrée rapide

EOF

# Afficher les informations d'installation
echo ""
echo "✅ Installation et configuration de Yazi terminées!"
echo ""
echo "📌 Prochaines étapes:"
echo "1. Ajoutez cette ligne à votre ~/.bashrc ou ~/.zshrc:"
echo "   source ~/.config/yazi/init.sh"
echo ""
echo "2. Redémarrez votre shell ou exécutez:"
echo "   source ~/.bashrc  # ou source ~/.zshrc"
echo ""
echo "3. Lancez Yazi avec:"
echo "   yazi"
echo ""
echo "4. Documentation disponible à:"
echo "   ~/.config/yazi/README.md"
echo ""
echo "🚀 Bonne utilisation!"
EOF
