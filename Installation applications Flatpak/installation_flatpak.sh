#!/bin/bash

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
    rg.dupot.easyflatpak
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
