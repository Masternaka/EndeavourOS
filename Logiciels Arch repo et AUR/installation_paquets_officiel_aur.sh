#!/bin/bash

# Mettre à jour le système
echo "Mise à jour du système..."
sudo pacman -Syu --noconfirm

# Vérifier si yay est installé, sinon l'installer
if ! command -v yay &> /dev/null; then
    echo "yay n'est pas installé. Installation de yay..."
    
    # Installer les dépendances nécessaires pour yay
    sudo pacman -S --needed git base-devel --noconfirm

    # Cloner le dépôt yay et l'installer
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo "yay est déjà installé."
fi

# Liste des applications à installer depuis les dépôts officiels (Arch)
APPS_PACMAN=(

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

# Liste des applications à installer depuis AUR
APPS_AUR=(

ipscan
octopi
pacseek
brave-bin
opera
deadbeef
simplescreenrecorder
spotify
alacritty-themes
sublime-text-4

)

# Installer les applications depuis les dépôts officiels
echo "Installation des applications depuis les dépôts officiels..."
for app in "${APPS_PACMAN[@]}"; do
    sudo pacman -S --noconfirm --needed $app
done

# Installer les applications depuis AUR avec yay
echo "Installation des applications depuis AUR..."
for app in "${APPS_AUR[@]}"; do
    yay -S --noconfirm $app
done

echo "Installation terminée!"
