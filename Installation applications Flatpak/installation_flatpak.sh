#!/bin/bash

# Vérifie si flatpak est installé
if ! command -v flatpak &> /dev/null
then
    echo "Flatpak n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Liste des applications Flatpak à installer
applications=(
  

  
)

# Installation des applications
for app in "${applications[@]}"; do
    echo "Installation de $app ..."
    flatpak install -y flathub $app
done

echo "Installation terminée."
