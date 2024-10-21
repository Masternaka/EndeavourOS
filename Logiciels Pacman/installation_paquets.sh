6#!/bin/bash

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

# Spécifique à EndeavourOS
akm
eos-update-notifier

# Utilitaire
catfish
flatpak
flameshot
gnome-disk-utility
gparted
gufw
openrgb
qbittorrent
transmission-qt
#transmission-gtk
distrobox
lshw
fwupd
timeshift

# Utilitaire terminal
btop
fastfetch
ranger
#yazi
#fzf

# Sécurité
bitwarden
keepassxc

# Navigateur internet et email
firefox
thunderbird
vivaldi
vivaldi-ffmpeg-codecs

# Multimédia
#handbrake
strawberry
vlc

# Communication
discord
#telegram-desktop

# Office
libreoffice-fresh
libreoffice-fresh-fr
marknote
obsidian

# Virtualisation
qemu-full
virt-manager

# Shell et terminal
zsh
alacritty
#kitty

# Développement 
code
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
