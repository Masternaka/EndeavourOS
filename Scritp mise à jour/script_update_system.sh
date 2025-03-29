# Script de mise à jour de mon système

#!/bin/bash

echo "Mise à jour des paquets Pacman..."
if sudo pacman -Syu; then
    echo "Pacman terminé avec succès."
else
    echo "Erreur lors de la mise à jour Pacman."
    exit 1
fi

echo "Mise à jour des paquets AUR..."
if yay -Syu; then
    echo "AUR terminé avec succès."
else
    echo "Erreur lors de la mise à jour AUR."
    exit 1
fi

echo "Mise à jour des paquets Flatpak..."
if flatpak update; then
    echo "Flatpak terminé avec succès."
else
    echo "Erreur lors de la mise à jour Flatpak."
    exit 1
fi

echo "Mises à jour terminées avec succès !"
