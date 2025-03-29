#!/bin/bash
set -euo pipefail

###############################################################################
# Script pour l'installation de paquets via pacman
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: installation_paquet.sh
# 2. Rendez-le exécutable: chmod +x installation_paquet.sh
# 3. Exécutez-le: sudo ./installation_paquet.sh
###############################################################################

# Définition des couleurs pour améliorer la lisibilité
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# Vérification si le script est exécuté en tant que root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Veuillez exécuter ce script en tant que root (sudo).${RESET}"
  exit 1
fi

# Fonction d'affichage de l'aide
usage() {
  echo "Usage : $0 [--update] [--help]"
  echo "  --update    Met à jour uniquement le système."
  echo "  --help      Affiche ce message d'aide."
  exit 0
}

# Gestion des arguments
UPDATE_ONLY=false

for arg in "$@"; do
  case $arg in
    --help)
      usage
      ;;
    --update)
      UPDATE_ONLY=true
      ;;
    *)
      echo -e "${RED}Option inconnue : $arg${RESET}"
      usage
      ;;
  esac
done

# Sauvegarde de la configuration de pacman avec horodatage
backup_file="/etc/pacman.conf.$(date +%Y%m%d_%H%M%S).bak"
cp /etc/pacman.conf "$backup_file"
echo -e "${GREEN}Sauvegarde de /etc/pacman.conf effectuée dans $backup_file${RESET}"

# Activer le téléchargement parallèle de 15 paquets si désactivé
if grep -q "^#ParallelDownloads = 5" /etc/pacman.conf; then
  sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 15/' /etc/pacman.conf
  echo -e "${GREEN}Téléchargement parallèle activé avec 15 paquets.${RESET}"
else
  echo -e "${YELLOW}La configuration ParallelDownloads est déjà activée ou modifiée.${RESET}"
fi

# Restauration du fichier pacman.conf en cas d'interruption
trap 'echo -e "${RED}Interruption détectée. Restauration du fichier pacman.conf...${RESET}"; mv "$backup_file" /etc/pacman.conf; exit 1' INT TERM

# Fonction pour mettre à jour le système
update_system() {
  echo -e "${GREEN}Mise à jour des dépôts et des paquets existants...${RESET}"
  pacman -Syu --noconfirm || { echo -e "${RED}Erreur lors de la mise à jour.${RESET}"; exit 1; }
}

# Liste des paquets à installer via pacman
pacman_packages=(
    # Spécifique à EndeavourOS
    #akm
    #eos-update-notifier

    # Spécifique à XFCE
    #mugshot
    #xfce4-appfinder
    #xfce4-calculator-plugin
    #xfce4-clipman-plugin
    #xfce4-cpufreq-plugin
    #xfce4-cpugraph-plugin
    #xfce4-diskperf-plugin
    #xfce4-docklike-plugin
    #xfce4-genmon-plugin
    #xfce4-indicator-plugin
    #xfce4-mailwatch-plugin
    #xfce4-mixer
    #xfce4-mpc-plugin
    #xfce4-notes-plugin
    #xfce4-panel-profiles
    #xfce4-places-plugin
    #xfce4-sensors-plugin
    #xfce4-smartbookmark-plugin
    #xfce4-stopwatch-plugin
    #xfce4-systemload-plugin
    #thunar-shares-plugin
    #thunar-volman

    # Spécifique à KDE
    #marknote
    #akregator
    #kcontacts

    # Utilitaire
    catfish
    flatpak
    flameshot
    gnome-disk-utility
    gparted
    #gufw
    openrgb
    qbittorrent
    transmission-qt
    distrobox
    lshw
    fwupd
    timeshift
    7zip

    # Utilitaire terminal
    btop
    fastfetch
    #ranger
    #helix
    yazi
    vim
    #neovim

    # Sécurité
    bitwarden
    keepassxc

    # Navigateur internet et email
    #firefox
    thunderbird
    vivaldi
    vivaldi-ffmpeg-codecs

    # Multimédia
    strawberry
    vlc

    # Communication
    discord

    # Office
    libreoffice-fresh
    libreoffice-fresh-fr
    #obsidian

    # Virtualisation
    qemu-full
    virt-manager

    # Shell et terminal
    #zsh
    #fish
    #kitty
    alacrity
    #ghostty

    # Développement
    code
    meld
    zed
)

# Fonction pour installer les paquets
install_packages() {
  echo -e "${GREEN}Installation des paquets via pacman...${RESET}"
  for package in "${pacman_packages[@]}"; do
    if pacman -Qi "$package" &>/dev/null; then
      echo -e "${YELLOW}[$package] est déjà installé.${RESET}"
    else
      echo -e "${GREEN}Installation de [$package]...${RESET}"
      pacman -S --noconfirm "$package" || echo -e "${RED}Erreur lors de l'installation de $package.${RESET}"
    fi
  done
}

# Exécution en fonction des arguments
update_system

if [ "$UPDATE_ONLY" = false ]; then
  install_packages
fi

echo -e "${GREEN}Installation terminée !${RESET}"
