#!/bin/bash

# Script d'installation de zoxide et fzf sur Arch Linux
# zoxide: outil de navigation de répertoires intelligent
# fzf: outil de recherche floue en ligne de commande

set -e

echo "=== Installation de zoxide et fzf sur Arch Linux ==="
echo

# Vérifier si pacman est disponible
if ! command -v pacman &> /dev/null; then
    echo "❌ Erreur: pacman n'est pas installé. Ce script est destiné à Arch Linux."
    exit 1
fi

# Installation de zoxide
echo "📦 Installation de zoxide..."
sudo pacman -S --noconfirm zoxide
echo "✅ zoxide installé avec succès"
echo

# Installation de fzf
echo "📦 Installation de fzf..."
sudo pacman -S --noconfirm fzf
echo "✅ fzf installé avec succès"
echo

# Configuration pour bash/zsh
echo "⚙️  Configuration des shells..."
echo

# Demander si l'utilisateur veut la configuration recommandée
read -p "Voulez-vous ajouter la configuration recommandée (alias, intégration fzf)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    CONFIG_MODE="full"
else
    CONFIG_MODE="minimal"
fi

# Configuration pour bash
if [ -f ~/.bashrc ]; then
    if ! grep -q "zoxide init bash" ~/.bashrc; then
        echo "eval \"\$(zoxide init bash)\"" >> ~/.bashrc
        
        if [ "$CONFIG_MODE" = "full" ]; then
            cat >> ~/.bashrc << 'EOF'

# Configuration zoxide et fzf
alias cd='z'
alias cdi='zi'

# Options fzf recommandées
export FZF_DEFAULT_OPTS="--height 40% --reverse --border --multi"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
EOF
        fi
        echo "✅ zoxide ajouté à ~/.bashrc"
    else
        echo "ℹ️  zoxide déjà configuré dans ~/.bashrc"
    fi
fi

# Configuration pour zsh
if [ -f ~/.zshrc ]; then
    if ! grep -q "zoxide init zsh" ~/.zshrc; then
        echo "eval \"\$(zoxide init zsh)\"" >> ~/.zshrc
        
        if [ "$CONFIG_MODE" = "full" ]; then
            cat >> ~/.zshrc << 'EOF'

# Configuration zoxide et fzf
alias cd='z'
alias cdi='zi'

# Options fzf recommandées
export FZF_DEFAULT_OPTS="--height 40% --reverse --border --multi"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
EOF
        fi
        echo "✅ zoxide ajouté à ~/.zshrc"
    else
        echo "ℹ️  zoxide déjà configuré dans ~/.zshrc"
    fi
fi

echo
echo "🎉 Installation terminée!"
echo
echo "📋 Commandes disponibles:"
echo "   - zoxide: utiliser 'z' au lieu de 'cd' pour naviguer intelligemment"
echo "   - fzf: utiliser Ctrl+R pour chercher dans l'historique avec fzf"
echo

if [ "$CONFIG_MODE" = "full" ]; then
    echo "⚙️  Configuration appliquée:"
    echo "   - Alias 'cd' remplacé par 'z' (navigation intelligente)"
    echo "   - Alias 'cdi' pour navigation interactive avec fzf"
    echo "   - Options fzf personnalisées (hauteur, thème, multi-select)"
else
    echo "ℹ️  Mode minimal: configuration de base uniquement"
    echo "   Vous pouvez personnaliser manuellement ~/.bashrc ou ~/.zshrc"
fi
echo
echo "💡 Conseil: Redémarrez votre terminal pour appliquer les modifications"
