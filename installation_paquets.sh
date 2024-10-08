#!/bin/bash

#Script pour installer des paquets sur le Répertoire Arch Principal.

# Vérifier si l'utilisateur est root
if [ "$EUID" -ne 0 ]
then 
  echo "Veuillez exécuter ce script en tant que root (sudo)."
  exit
fi

# Mettre à jour les dépôts et les paquets existants
echo "Mise à jour des dépôts et des paquets existants..."
pacman -Syu --noconfirm

# Liste des paquets à installer via pacman
pacman_packages=(

# Utilitaire
alacritty
alacritty-themes
btop
catfish
fastfetch
flatpak
flameshot
gnome-disk-utility
gparted
gufw
openrgb
qbittorrent
transmission-qt
#transmission-gtk

# Sécurité
bitwarden
keepassxc

# Navigateur internet et email
brave-bin
firefox
opera
thunderbird
vivaldi
vivaldi-ffmpeg-codecs

# Multimédia
deadbeef
handbrake
simplescreenrecorder
spotify
strawberry
vlc

# Communication
discord
telegram-desktop

# Office
libreoffice-fresh
libreoffice-fresh-fr

# Virtualisation
qemu-full

# Shell et terminal
ranger
yazi
zsh

# Développement 
sublime-text-4
meld

)

# Installation des paquets avec pacman
echo "Installation des paquets via pacman..."
for package in "${pacman_packages[@]}"
do
  if pacman -Qi $package &> /dev/null
  then
    echo "$package est déjà installé."
  else
    pacman -S --noconfirm $package
  fi
done

echo "Installation terminée!"
