#!/bin/bash

#Script pour installer des paquets sur le Répertoire AUR.

# Vérification des privilèges root
if [ "$EUID" -eq 0 ]; then
  echo "Ne pas exécuter ce script en tant qu'utilisateur root. Lancez-le en tant qu'utilisateur normal."
  exit 1
fi

# Mise à jour des dépôts officiels
echo "Mise à jour des dépôts officiels..."
sudo pacman -Syu --noconfirm

# Installation des dépendances nécessaires pour compiler des paquets AUR
echo "Installation des dépendances requises..."
sudo pacman -S --needed base-devel git --noconfirm

# Vérification si yay est déjà installé
if ! command -v yay &> /dev/null; then
  echo "yay n'est pas installé. Installation en cours..."

  # Clonage du dépôt yay depuis l'AUR
  cd /tmp
  git clone https://aur.archlinux.org/yay.git

  # Compilation et installation de yay
  cd yay
  makepkg -si --noconfirm
else
  echo "yay est déjà installé."
fi

# Liste des paquets AUR à installer (modifiez cette ligne pour ajouter les paquets)
package_list=(

arch-update
ipscan
#octopi
pacseek
brave-bin
#opera
deadbeef
#simplescreenrecorder
spotify
alacritty-themes
sublime-text-4
#beaver-notes
#cider
raindrop
ulauncher
zen-browser-bin

  )

# Installation de chaque paquet dans la liste
for package in "${package_list[@]}"; do
  echo "Installation du paquet : $package"
  yay -S "$package" --noconfirm
done

# Mise à jour des paquets AUR installés
echo "Mise à jour de tous les paquets AUR..."
yay -Sua --noconfirm

echo "Installation et mise à jour terminées."
