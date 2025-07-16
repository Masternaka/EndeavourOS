#!/bin/bash
set -euo pipefail

###############################################################################
# Script d'installation de paquets pour Arch/EndeavourOS (avec AUR en option)
# Usage :
#   sudo ./installation_paquets.sh [--update] [--xfce|--kde|--gnome] [--aur] [--dry-run]
###############################################################################

# Couleurs
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# Fichier log
LOGFILE="/var/log/installation_paquets.log"
touch "$LOGFILE"

# Vérification du mode superutilisateur
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Veuillez exécuter ce script avec sudo.${RESET}"
  exit 1
fi

# Options
UPDATE_ONLY=false
USE_XFCE=false
USE_KDE=false
USE_GNOME=false
INSTALL_AUR=false
DRY_RUN=false

# Gestion des arguments
for arg in "$@"; do
  case $arg in
    --help)
      echo "Usage: $0 [--update] [--xfce|--kde|--gnome] [--aur] [--dry-run]"
      exit 0
      ;;
    --update) UPDATE_ONLY=true ;;
    --xfce) USE_XFCE=true ;;
    --kde) USE_KDE=true ;;
    --gnome) USE_GNOME=true ;;
    --aur) INSTALL_AUR=true ;;
    --dry-run) DRY_RUN=true ;;
    *)
      echo -e "${RED}Option inconnue: $arg${RESET}"
      exit 1
      ;;
  esac
done

# Vérification de la connexion Internet
check_internet() {
  if ! ping -q -c 1 -W 2 archlinux.org &>/dev/null; then
    echo -e "${RED}Pas de connexion Internet. Vérifiez votre réseau.${RESET}"
    exit 1
  fi
}

# Mise à jour système
update_system() {
  echo -e "${GREEN}Mise à jour du système...${RESET}"
  pacman -Syu --noconfirm | tee -a "$LOGFILE"
}

# Activer le téléchargement parallèle
enable_parallel_downloads() {
  if grep -q "^#ParallelDownloads" /etc/pacman.conf; then
    sed -i.bak "s/^#ParallelDownloads = .*/ParallelDownloads = 15/" /etc/pacman.conf
    echo -e "${GREEN}Téléchargement parallèle activé (15).${RESET}"
  fi
}

# Configurations post-installation
post_installation() {
  echo -e "${GREEN}Configuration post-installation...${RESET}"

 echo -e "${YELLOW}Mise à jour des miroirs (reflector)...${RESET}"
 $DRY_RUN || pacman -S --noconfirm reflector && reflector --country Canada,France --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

 # echo -e "${YELLOW}Mise à jour des locales...${RESET}"
 # $DRY_RUN || sed -i 's/^#\(fr_CA\.UTF-8\)/\1/' /etc/locale.gen && locale-gen && localectl set-locale LANG=fr_CA.UTF-8

  echo -e "${YELLOW}Activation des services recommandés...${RESET}"
  $DRY_RUN || systemctl enable --now fstrim.timer
  $DRY_RUN || systemctl enable --now paccache.timer
  $DRY_RUN || systemctl enable --now ufw.service || true
}

# Installer yay si manquant
install_yay() {
  if ! command -v yay &>/dev/null; then
    echo -e "${YELLOW}yay non détecté. Installation...${RESET}"
    if [ "$DRY_RUN" = false ]; then
      pacman -S --noconfirm --needed base-devel git
      sudo -u "$SUDO_USER" bash -c '
        cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm'
    fi
  fi
}

# Fonction installation de paquets
install_packages() {
  local packages=(

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
      # firewalld
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
      #vim
      neovim

      # Sécurité
      # bitwarden
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
      kitty
      #alacrity
      #ghostty

      # Développement
      code
      meld
      zed

  )

  if [ "$USE_XFCE" = true ]; then
    packages+=(
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
        xfce4-sensors-plugin
        xfce4-smartbookmark-plugin
        xfce4-stopwatch-plugin
        xfce4-systemload-plugin
        thunar-shares-plugin
        thunar-volman
        xfce4-goodies
        pavucontrol
        gvfs
        xarchiver
        xfce4-xkb-plugin
        xdg-desktop-portal-xapp
        xdg-user-dirs-gt
        network-manager-applet
        gnome-keyring
        xdg-user-dirs
        galculator
        gvfs-afc
        gvfs-gphoto2
        gvfs-mtp
        gvfs-nfs
        gvfs-smb
        thunar-archive-plugin
        thunar-media-tags-plugin
    )
  fi

  if [ "$USE_KDE" = true ]; then
    packages+=(
        kio-extras
        merkuro
        dolphin-plugins
        kio-admin
        filelight
        isoimagewriter
        yakuake
        krusader
        systemdgenie
        kwrite
        xdg-desktop-portal-kde
        print-manager
        ffmpegthumbs
        qt6-multimedia
        qt6-multimedia-gstreamer
        qt6-multimedia-ffmpeg
        qt6-wayland
        kdeplasma-addons
        plasma-systemmonitor
        kwalletmanager

    )
  fi

  if [ "$USE_GNOME" = true ]; then
    packages+=(
        gnome-tweaks
        gnome-shell-extensions
        gvfs
        gvfs-afc
        gvfs-gphoto2
        gvfs-mtp
        gvfs-nfs
        gvfs-smb
        xdg-user-dirs-gtk
        adw-gtk3
        qt6-wayland

    )
  fi


  for pkg in "${packages[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
      echo -e "${YELLOW}[$pkg] déjà installé.${RESET}"
    else
      echo -e "${GREEN}Installation de [$pkg]...${RESET}"
      $DRY_RUN || pacman -S --noconfirm --needed "$pkg" | tee -a "$LOGFILE"
    fi
  done
}

# Installation de paquets AUR
install_aur_packages() {
  local aur_packages=(

      # Utilitaire
      # arch-update
      pacseek
      ipscan
      # raindrop
      # octopi
      # peazip-qt-bin

      # Navigateur internet
      brave-bin
      # zen-browser-bin
      # librewolf-bin

      # Utilitaire terminal
      # alacritty-themes

      # Développement
      # sublime-text-4
      github-desktop
      #gitfiend
      #gitahead
      gitkraken
      visual-studio-code-bin

      # Multimédia
      deadbeef
      spotify

      # Communication
      # vesktop-bin

      # Spécifique à KDE
      # klassy

      # Spécifique à XFCE
      #ulauncher

  )
  install_yay

  for aur in "${aur_packages[@]}"; do
    echo -e "${GREEN}Installation AUR de [$aur]...${RESET}"
    $DRY_RUN || sudo -u "$SUDO_USER" yay -S --noconfirm --needed "$aur" | tee -a "$LOGFILE"
  done
}

# Exécution
check_internet
enable_parallel_downloads
update_system

if [ "$UPDATE_ONLY" = false ]; then
  install_packages
  if [ "$INSTALL_AUR" = true ]; then
    install_aur_packages
  fi
  post_installation
fi

echo -e "${GREEN}Installation terminée. Log : $LOGFILE${RESET}"
