#!/bin/bash

###############################################################################
# Script permet l'installation automatisée des applications Flatpak
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: installation_flatpak.sh
# 2. Rendez-le exécutable: chmod +x installation_flatpak.sh
# 3. Exécutez-le: sudo ./installation_flatpak.sh
###############################################################################

# Arrête le script en cas d'erreur
set -e

# Vérifie si flatpak est installé
if ! command -v flatpak &> /dev/null; then
    echo "❌ Flatpak n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifie si le remote Flathub est bien présent, sinon l'ajoute
if ! flatpak remotes | grep -q flathub; then
    echo "➕ Ajout du remote Flathub..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Liste des applications Flatpak à installer
applications=(
    com.usebottles.bottles
    org.dupot.easyflatpak
    io.github.flattool.Warehouse
    com.github.tchx84.Flatseal
    io.github.giantpinkrobots.flatsweep
)

# Installation des applications
for app in "${applications[@]}"; do
    echo "📦 Installation de $app ..."
    flatpak install -y flathub "$app" || {
        echo "⚠️ Échec de l'installation de $app"
    }
done

echo "✅ Installation terminée."
