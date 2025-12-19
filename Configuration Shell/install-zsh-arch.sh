#!/bin/bash

# Script d'installation de zsh, oh-my-zsh, powerlevel10k et plugins pour Arch Linux et distributions basées sur Arch
# Auteur: Script généré pour installation automatique

set -e  # Arrêter le script en cas d'erreur

echo "🚀 Début de l'installation de zsh et de ses composants..."

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérifier que nous sommes sur Arch Linux ou une distribution basée sur Arch
IS_ARCH_BASED=false

# Vérifier la présence du fichier /etc/arch-release (Arch et distributions basées sur Arch)
if [ -f /etc/arch-release ]; then
    IS_ARCH_BASED=true
fi

# Vérifier le champ ID_LIKE dans /etc/os-release
if grep -qE "^ID_LIKE=.*arch" /etc/os-release 2>/dev/null || grep -qE "^ID=.*arch" /etc/os-release 2>/dev/null; then
    IS_ARCH_BASED=true
fi

# Vérifier la présence de pacman (gestionnaire de paquets d'Arch)
if command -v pacman &> /dev/null; then
    IS_ARCH_BASED=true
fi

if [ "$IS_ARCH_BASED" = false ]; then
    echo -e "${YELLOW}⚠️  Attention: Ce script est conçu pour Arch Linux et les distributions basées sur Arch${NC}"
    read -p "Continuer quand même? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Vérifier si l'utilisateur est root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}❌ Ne pas exécuter ce script en tant que root${NC}"
    echo "Le script installera les composants pour l'utilisateur actuel"
    exit 1
fi

USER_HOME=$HOME
ZSHRC_FILE="$USER_HOME/.zshrc"
ZSH_DIR="$USER_HOME/.oh-my-zsh"

# 1. Installation de zsh
echo -e "\n${GREEN}📦 Étape 1/5: Installation de zsh...${NC}"
if command -v zsh &> /dev/null; then
    echo "zsh est déjà installé"
else
    echo "Installation de zsh avec pacman..."
    sudo pacman -S --noconfirm zsh
fi

# 2. Installation de oh-my-zsh
echo -e "\n${GREEN}📦 Étape 2/5: Installation de oh-my-zsh...${NC}"
if [ -d "$ZSH_DIR" ]; then
    echo "oh-my-zsh est déjà installé"
else
    echo "Installation de oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 3. Installation de powerlevel10k
echo -e "\n${GREEN}📦 Étape 3/5: Installation de powerlevel10k...${NC}"
P10K_DIR="$ZSH_DIR/custom/themes/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
    echo "powerlevel10k est déjà installé"
else
    echo "Installation de powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# 4. Installation des plugins
echo -e "\n${GREEN}📦 Étape 4/5: Installation des plugins...${NC}"
PLUGINS_DIR="$ZSH_DIR/custom/plugins"

# zsh-syntax-highlighting
SYNTAX_HIGHLIGHTING_DIR="$PLUGINS_DIR/zsh-syntax-highlighting"
if [ -d "$SYNTAX_HIGHLIGHTING_DIR" ]; then
    echo "zsh-syntax-highlighting est déjà installé"
else
    echo "Installation de zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_HIGHLIGHTING_DIR"
fi

# zsh-autosuggestions
AUTOSUGGESTIONS_DIR="$PLUGINS_DIR/zsh-autosuggestions"
if [ -d "$AUTOSUGGESTIONS_DIR" ]; then
    echo "zsh-autosuggestions est déjà installé"
else
    echo "Installation de zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$AUTOSUGGESTIONS_DIR"
fi

# zsh-history-substring-search
HISTORY_SUBSTRING_DIR="$PLUGINS_DIR/zsh-history-substring-search"
if [ -d "$HISTORY_SUBSTRING_DIR" ]; then
    echo "zsh-history-substring-search est déjà installé"
else
    echo "Installation de zsh-history-substring-search..."
    git clone https://github.com/zsh-users/zsh-history-substring-search.git "$HISTORY_SUBSTRING_DIR"
fi

# zsh-completions
COMPLETIONS_DIR="$PLUGINS_DIR/zsh-completions"
if [ -d "$COMPLETIONS_DIR" ]; then
    echo "zsh-completions est déjà installé"
else
    echo "Installation de zsh-completions..."
    git clone https://github.com/zsh-users/zsh-completions.git "$COMPLETIONS_DIR"
fi

# 5. Configuration du .zshrc
echo -e "\n${GREEN}📦 Étape 5/5: Configuration du .zshrc...${NC}"

# Sauvegarder le .zshrc existant s'il existe
if [ -f "$ZSHRC_FILE" ]; then
    BACKUP_FILE="${ZSHRC_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Sauvegarde du .zshrc existant vers $BACKUP_FILE"
    cp "$ZSHRC_FILE" "$BACKUP_FILE"
fi

# Créer un nouveau .zshrc avec la configuration
cat > "$ZSHRC_FILE" << 'EOF'
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins à charger
plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-history-substring-search
    zsh-completions
)

# Charger oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Configuration pour zsh-history-substring-search
# Recherche avec les flèches haut/bas
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Configuration pour zsh-autosuggestions
# Couleur des suggestions (gris clair)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#808080'

# Pour powerlevel10k, exécuter p10k configure après la première connexion
# pour personnaliser le thème
EOF

echo -e "${GREEN}✅ Configuration du .zshrc terminée${NC}"

# 6. Définir zsh comme shell par défaut
echo -e "\n${GREEN}🔧 Configuration du shell par défaut...${NC}"
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "zsh" ]; then
    echo "Changement du shell par défaut vers zsh..."
    chsh -s $(which zsh)
    echo -e "${YELLOW}⚠️  Le shell par défaut sera changé après la prochaine connexion${NC}"
else
    echo "zsh est déjà le shell par défaut"
fi

echo -e "\n${GREEN}✅ Installation terminée avec succès!${NC}"
echo ""
echo "📝 Prochaines étapes:"
echo "   1. Déconnectez-vous et reconnectez-vous pour utiliser zsh"
echo "   2. Ou exécutez: zsh"
echo "   3. Lors de la première utilisation, powerlevel10k vous proposera de configurer le thème"
echo "   4. Vous pouvez exécuter 'p10k configure' à tout moment pour reconfigurer le thème"
echo ""
echo "🎨 Les plugins suivants sont maintenant installés:"
echo "   - zsh-syntax-highlighting (coloration syntaxique)"
echo "   - zsh-autosuggestions (suggestions automatiques)"
echo "   - zsh-history-substring-search (recherche dans l'historique)"
echo "   - zsh-completions (completions supplémentaires)"
echo ""
