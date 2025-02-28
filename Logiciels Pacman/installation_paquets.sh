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

# Spécifique à XFCE
mugshot
xfce4-appfinder
xfce4-calculator-plugin
xfce4-clipman-plugin
xfce4-cpufreq-plugin
xfce4-cpugraph-plugin
xfce4-diskperf-plugin
xfce4-docklike-plugin
xfce4-genmon-plugin
xfce4-indicator-plugin
xfce4-mailwatch-plugin
xfce4-mixer
xfce4-mpc-plugin
xfce4-notes-plugin
xfce4-panel-profiles
xfce4-places-plugin
#xfce4-power-manager
xfce4-sensors-plugin
xfce4-smartbookmark-plugin
xfce4-stopwatch-plugin
xfce4-systemload-plugin
#xfdashboard
thunar-shares-plugin
thunar-volman



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
helix

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
#zsh
fish
#alacritty
kitty
#ghostty

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
