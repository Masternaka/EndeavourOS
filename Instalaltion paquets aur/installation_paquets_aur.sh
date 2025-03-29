#!/bin/bash
set -euo pipefail

###############################################################################
# Script pour l'installation de paquets via aur (yay)
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: installation_paquet_aur.sh
# 2. Rendez-le exécutable: chmod +x installation_paquet_aur.sh
# 3. Exécutez-le: sudo ./installation_paquet_aur.sh
###############################################################################

# Vérification des privilèges root
if [ "$EUID" -eq 0 ]; then
  echo "Ne pas exécuter ce script en tant qu'utilisateur root. Lancez-le en tant qu'utilisateur normal." >&2
  exit 1
fi

# Mise à jour des dépôts officiels
echo "Mise à jour des dépôts officiels..."
sudo pacman -Syu --noconfirm

# Liste des paquets AUR à installer (modifiez cette liste selon vos besoins)
packages=(
    # Utilitaire
    arch-update
    pacseek
    ipscan
    raindrop
    octopi
    peazip-qt-bin

    # Navigateur internet
    brave-bin
    zen-browser-bin
    librewolf-bin

    # Utilitaire terminal
    alacritty-themes

    # Développement
    sublime-text-4
    github-desktop
    #gitfiend
    #gitahead
    gitkraken
    visual-studio-code-bin

    # Multimédia
    deadbeef
    spotify

    # Communication
    vesktop-bin

    # Spécifique à KDE
    klassy

    # Spécifique à XFCE
    #ulauncher
)

# Journalisation des actions
log_file="install_log_$(date +%F).txt"
echo "Journal de l'installation : $log_file"
exec > >(tee -a "$log_file") 2>&1

# Installation des paquets AUR
for package in "${packages[@]}"; do
  echo "Installation du paquet : $package"
  if ! yay -S "$package" --noconfirm; then
    echo "Erreur : le paquet $package n'a pas pu être installé." >&2
  fi
done

echo "Installation et mise à jour terminées."
