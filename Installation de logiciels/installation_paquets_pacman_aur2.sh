#!/bin/bash
set -euo pipefail

###############################################################################
# Script d'installation de paquets pour Arch/EndeavourOS (avec AUR en option)
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: installation_paquets_pacman_aur.sh
# 2. Rendez-le exécutable: chmod +x installation_paquets_pacman_aur.sh
# 3. Exécutez-le: sudo ./installation_paquets_pacman_aur.sh [--update] [--xfce|--kde|--gnome] [--aur] [--dry-run]
#
# Options
# --help : Affiche l'aide et quitte.
# --update : Met à jour uniquement le système (sans installer de paquets supplémentaires).
# --base : Installe les paquets de base.
# --xfce : Installe les paquets de base + XFCE.
# --kde : Installe les paquets de base + KDE.
# --gnome : Installe les paquets de base + GNOME.
# --aur : Installe également les paquets AUR (via yay).
# --aur-only : Installe uniquement les paquets AUR.
# --dry-run : Simule les installations sans effectuer de modifications.
###############################################################################

# Couleurs
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# Configuration du dossier et fichier de log
USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
LOG_DIR="$USER_HOME/log"
LOGFILE="$LOG_DIR/installation_paquets_$(date +%Y%m%d_%H%M%S).log"

# Création du dossier de log s'il n'existe pas
mkdir -p "$LOG_DIR"
chown "$SUDO_USER:$SUDO_USER" "$LOG_DIR"
touch "$LOGFILE"
chown "$SUDO_USER:$SUDO_USER" "$LOGFILE"

# Options
UPDATE_ONLY=false
INSTALL_BASE=false
USE_XFCE=false
USE_KDE=false
USE_GNOME=false
INSTALL_AUR=false
AUR_ONLY=false
DRY_RUN=false

# Fonction de journalisation
log_message() {
  local message="$1"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $message" >> "$LOGFILE"
}

# Fonction de confirmation
confirm_installation() {
  if [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}Continuer avec l'installation ? (y/N)${RESET}"
    read -r -n 1 -p "> " response
    echo
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}Installation annulée.${RESET}"
      exit 0
    fi
  fi
}

# Fonction de nettoyage en cas d'interruption
cleanup_on_exit() {
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    log_message "ERREUR: Script interrompu (code: $exit_code)"
    echo -e "${RED}Installation interrompue. Consultez le log: $LOGFILE${RESET}"
  fi
}

# Validation du choix du menu
validate_menu_choice() {
  local choice="$1"
  if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 0 ] || [ "$choice" -gt 12 ]; then
    return 1
  fi
  return 0
}

# Menu avec validation améliorée
get_user_choice() {
  local choice
  while true; do
    show_interactive_menu
    read -r -p "Votre choix (0-12): " choice
    
    if validate_menu_choice "$choice"; then
      echo "$choice"
      return 0
    else
      echo -e "${RED}Choix invalide. Veuillez sélectionner un nombre entre 0 et 12.${RESET}"
      echo ""
    fi
  done
}

# Installation avec retry automatique
install_package_with_retry() {
  local package="$1"
  local max_attempts=3
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    
    if [ "$DRY_RUN" = false ]; then
      if pacman -S --noconfirm --needed "$package" 2>&1 | tee -a "$LOGFILE"; then
        log_message "[$package] installé avec succès"
        return 0
      else
        log_message "Tentative $attempt/$max_attempts échouée pour $package"
        if [ $attempt -lt $max_attempts ]; then
          echo -e "${YELLOW}Nouvelle tentative dans 5 secondes...${RESET}"
          sleep 5
        fi
      fi
    else
      echo "DRY-RUN: pacman -S --noconfirm --needed $package" | tee -a "$LOGFILE"
      return 0
    fi
    
    attempt=$((attempt + 1))
  done
  
  log_message "ERREUR: Impossible d'installer $package après $max_attempts tentatives"
  return 1
}

# Installation AUR avec retry
install_aur_package_with_retry() {
  local package="$1"
  local max_attempts=3
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    
    if [ "$DRY_RUN" = false ]; then
      if sudo -u "$SUDO_USER" yay -S --noconfirm --needed "$package" 2>&1 | tee -a "$LOGFILE"; then
        log_message "[$package] installé avec succès depuis AUR"
        return 0
      else
        log_message "Tentative AUR $attempt/$max_attempts échouée pour $package"
        if [ $attempt -lt $max_attempts ]; then
          echo -e "${YELLOW}Nouvelle tentative dans 5 secondes...${RESET}"
          sleep 5
        fi
      fi
    else
      echo "DRY-RUN: yay -S --noconfirm --needed $package" | tee -a "$LOGFILE"
      return 0
    fi
    
    attempt=$((attempt + 1))
  done
  
  log_message "ERREUR: Impossible d'installer $package depuis AUR après $max_attempts tentatives"
  return 1
}

# Sauvegarde des paquets installés
backup_installed_packages() {
  local backup_file="$LOG_DIR/packages_backup_$(date +%Y%m%d_%H%M%S).txt"
  echo -e "${GREEN}Sauvegarde de la liste des paquets installés...${RESET}"
  pacman -Qqe > "$backup_file"
  chown "$SUDO_USER:$SUDO_USER" "$backup_file"
  log_message "Sauvegarde des paquets: $backup_file"
  echo -e "${GREEN}Sauvegarde créée: $backup_file${RESET}"
}

# Création d'un script de récupération
create_recovery_script() {
  local recovery_script="$LOG_DIR/recovery_$(date +%Y%m%d_%H%M%S).sh"
  cat > "$recovery_script" << 'EOF'
#!/bin/bash
# Script de récupération généré automatiquement

echo "=== Script de récupération ==="
echo "Nettoyage des caches..."
sudo pacman -Sc --noconfirm

if command -v yay &>/dev/null; then
  echo "Nettoyage du cache AUR..."
  yay -Sc --noconfirm
fi

echo "Récupération terminée"
EOF
  chmod +x "$recovery_script"
  chown "$SUDO_USER:$SUDO_USER" "$recovery_script"
  log_message "Script de récupération créé: $recovery_script"
}

# Fonction pour afficher le menu interactif
show_interactive_menu() {
  echo -e "${GREEN}=== Script d'installation de paquets Arch/EndeavourOS ===${RESET}"
  echo -e "${GREEN}Par ${SUDO_USER} - $(date)${RESET}"
  echo ""
  echo "Que souhaitez-vous faire ?"
  echo ""
  echo "1) Mettre à jour le système uniquement"
  echo "2) Installation des paquets de base"
  echo "3) Installation des paquets de base + XFCE"
  echo "4) Installation des paquets de base + KDE"
  echo "5) Installation des paquets de base + GNOME"
  echo "6) Installation des paquets de base + AUR"
  echo "7) Installation des paquets de base + XFCE + AUR"
  echo "8) Installation des paquets de base + KDE + AUR"
  echo "9) Installation des paquets de base + GNOME + AUR"
  echo "10) Installation des paquets AUR uniquement"
  echo "11) Mode simulation (dry-run) - Installation complète"
  echo "12) Aide et informations"
  echo "0) Quitter"
  echo ""
  echo -e "${YELLOW}Le log sera sauvegardé dans: $LOGFILE${RESET}"
  echo ""
}

# Fonction pour traiter le choix de l'utilisateur
process_menu_choice() {
  local choice="$1"
  
  case $choice in
    1)
      echo -e "${GREEN}Mise à jour du système uniquement${RESET}"
      UPDATE_ONLY=true
      ;;
    2)
      echo -e "${GREEN}Installation des paquets de base${RESET}"
      INSTALL_BASE=true
      ;;
    3)
      echo -e "${GREEN}Installation des paquets de base + XFCE${RESET}"
      INSTALL_BASE=true
      USE_XFCE=true
      ;;
    4)
      echo -e "${GREEN}Installation des paquets de base + KDE${RESET}"
      INSTALL_BASE=true
      USE_KDE=true
      ;;
    5)
      echo -e "${GREEN}Installation des paquets de base + GNOME${RESET}"
      INSTALL_BASE=true
      USE_GNOME=true
      ;;
    6)
      echo -e "${GREEN}Installation des paquets de base + AUR${RESET}"
      INSTALL_BASE=true
      INSTALL_AUR=true
      ;;
    7)
      echo -e "${GREEN}Installation des paquets de base + XFCE + AUR${RESET}"
      INSTALL_BASE=true
      USE_XFCE=true
      INSTALL_AUR=true
      ;;
    8)
      echo -e "${GREEN}Installation des paquets de base + KDE + AUR${RESET}"
      INSTALL_BASE=true
      USE_KDE=true
      INSTALL_AUR=true
      ;;
    9)
      echo -e "${GREEN}Installation des paquets de base + GNOME + AUR${RESET}"
      INSTALL_BASE=true
      USE_GNOME=true
      INSTALL_AUR=true
      ;;
    10)
      echo -e "${GREEN}Installation des paquets AUR uniquement${RESET}"
      INSTALL_AUR=true
      AUR_ONLY=true
      ;;
    11)
      echo -e "${YELLOW}Mode simulation activé${RESET}"
      DRY_RUN=true
      INSTALL_BASE=true
      ;;
    12)
      show_help
      exit 0
      ;;
    0)
      echo -e "${YELLOW}Annulation de l'installation${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}Choix invalide. Veuillez sélectionner un nombre entre 0 et 12.${RESET}"
      return 1
      ;;
  esac
  return 0
}

# Fonction d'aide détaillée
show_help() {
  echo -e "${GREEN}=== Aide du script d'installation ===${RESET}"
  echo ""
  echo "Ce script permet d'installer automatiquement des paquets sur Arch/EndeavourOS."
  echo ""
  echo "MODES DISPONIBLES:"
  echo "  Mode ligne de commande: ./script.sh [options]"
  echo "  Mode interactif: ./script.sh (sans options)"
  echo ""
  echo "OPTIONS EN LIGNE DE COMMANDE:"
  echo "  --help      Affiche cette aide"
  echo "  --update    Met à jour uniquement le système"
  echo "  --base      Installe les paquets de base"
  echo "  --xfce      Installe les paquets de base + XFCE"
  echo "  --kde       Installe les paquets de base + KDE"
  echo "  --gnome     Installe les paquets de base + GNOME"
  echo "  --aur       Installe les paquets AUR (en plus des paquets de base)"
  echo "  --aur-only  Installe uniquement les paquets AUR"
  echo "  --dry-run   Simule sans installer"
  echo ""
  echo "PAQUETS INSTALLÉS:"
  echo "  - Utilitaires: catfish, flatpak, flameshot, gparted, etc."
  echo "  - Terminal: btop, fastfetch, yazi, neovim, kitty"
  echo "  - Sécurité: keepassxc"
  echo "  - Navigateurs: thunderbird, vivaldi"
  echo "  - Multimédia: strawberry, vlc"
  echo "  - Communication: discord"
  echo "  - Office: libreoffice-fresh"
  echo "  - Développement: code, meld, zed"
  echo "  - Virtualisation: qemu-full, virt-manager"
  echo ""
  echo "PAQUETS AUR (si sélectionné):"
  echo "  - brave-bin, github-desktop, gitkraken, spotify, etc."
  echo ""
  echo "Le log sera sauvegardé dans: $LOGFILE"
}

# Mise à jour système
update_system() {
  echo -e "${GREEN}Mise à jour du système...${RESET}"
  log_message "Début de la mise à jour système"
  if [ "$DRY_RUN" = false ]; then
    pacman -Syu --noconfirm 2>&1 | tee -a "$LOGFILE"
  else
    echo "DRY-RUN: pacman -Syu --noconfirm" | tee -a "$LOGFILE"
  fi
  log_message "Fin de la mise à jour système"
}

# Installer yay si manquant
install_yay() {
  if ! command -v yay &>/dev/null; then
    echo -e "${YELLOW}yay non détecté. Installation...${RESET}"
    log_message "Installation de yay"
    if [ "$DRY_RUN" = false ]; then
      pacman -S --noconfirm --needed base-devel git 2>&1 | tee -a "$LOGFILE"
      sudo -u "$SUDO_USER" bash -c '
        cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm' 2>&1 | tee -a "$LOGFILE"
    else
      echo "DRY-RUN: Installation de yay" | tee -a "$LOGFILE"
    fi
  else
    log_message "yay déjà installé"
  fi
}

# Fonction installation de paquets améliorée
install_packages() {
  log_message "Début de l'installation des paquets principaux"
  
  local packages=(
      # Spécifique à EndeavourOS
      akm
      eos-update-notifier

      # Utilitaires
      catfish
      flatpak
      flameshot
      gnome-disk-utility
      gparted
      gufw
      openrgb
      qbittorrent
      transmission-qt
      distrobox
      lshw
      fwupd
      timeshift
      p7zip

      # Utilitaires terminal
      btop
      fastfetch
      yazi
      neovim

      # Sécurité
      keepassxc

      # Navigateur internet et email
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

      # Virtualisation
      qemu-full
      virt-manager

      # Shell et terminal
      kitty

      # Développement
      code
      meld
      zed
  )

  if [ "$USE_XFCE" = true ]; then
    log_message "Ajout des paquets XFCE"
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
        xdg-user-dirs-gtk
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
    log_message "Ajout des paquets KDE"
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
    log_message "Ajout des paquets GNOME"
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

  local total_packages=${#packages[@]}
  local current_package=0
  local failed_packages=()

  for pkg in "${packages[@]}"; do
    current_package=$((current_package + 1))
    echo -e "${GREEN}[$current_package/$total_packages] Traitement de [$pkg]...${RESET}"
    
    if pacman -Qi "$pkg" &>/dev/null; then
      echo -e "${YELLOW}[$pkg] déjà installé.${RESET}"
      log_message "[$pkg] déjà installé"
    else
      echo -e "${GREEN}Installation de [$pkg]...${RESET}"
      log_message "Installation de [$pkg]"
      if ! install_package_with_retry "$pkg"; then
        failed_packages+=("$pkg")
        echo -e "${RED}Échec de l'installation de [$pkg]${RESET}"
      fi
    fi
  done

  # Rapport des échecs
  if [ ${#failed_packages[@]} -gt 0 ]; then
    echo -e "${RED}Packages non installés: ${failed_packages[*]}${RESET}"
    log_message "Packages échoués: ${failed_packages[*]}"
  fi
  
  log_message "Fin de l'installation des paquets principaux"
}

# Installation de paquets AUR améliorée
install_aur_packages() {
  log_message "Début de l'installation des paquets AUR"
  
  local aur_packages=(
      # Utilitaires
      pacseek
      ipscan

      # Navigateur internet
      brave-bin

      # Développement
      github-desktop
      gitkraken
      visual-studio-code-bin

      # Multimédia
      deadbeef
      spotify
  )
  
  install_yay

  local total_aur_packages=${#aur_packages[@]}
  local current_aur_package=0
  local failed_aur_packages=()

  for aur in "${aur_packages[@]}"; do
    current_aur_package=$((current_aur_package + 1))
    echo -e "${GREEN}[$current_aur_package/$total_aur_packages] Installation AUR de [$aur]...${RESET}"
    log_message "Installation AUR de [$aur]"
    
    if ! install_aur_package_with_retry "$aur"; then
      failed_aur_packages+=("$aur")
      echo -e "${RED}Échec de l'installation AUR de [$aur]${RESET}"
    fi
  done

  # Rapport des échecs AUR
  if [ ${#failed_aur_packages[@]} -gt 0 ]; then
    echo -e "${RED}Packages AUR non installés: ${failed_aur_packages[*]}${RESET}"
    log_message "Packages AUR échoués: ${failed_aur_packages[*]}"
  fi
  
  log_message "Fin de l'installation des paquets AUR"
}

# Fonction de nettoyage final
cleanup() {
  log_message "Nettoyage du cache des paquets"
  if [ "$DRY_RUN" = false ]; then
    pacman -Sc --noconfirm 2>&1 | tee -a "$LOGFILE"
    if [ "$INSTALL_AUR" = true ]; then
      sudo -u "$SUDO_USER" yay -Sc --noconfirm 2>&1 | tee -a "$LOGFILE"
    fi
  else
    echo "DRY-RUN: Nettoyage du cache" | tee -a "$LOGFILE"
  fi
}

# Résumé d'installation détaillé
show_installation_summary() {
  echo -e "${GREEN}=== Résumé de l'installation ===${RESET}"
  echo -e "Utilisateur: $SUDO_USER"
  echo -e "Date: $(date)"
  echo -e "Paquets installés: $(pacman -Q | wc -l)"
  echo -e "Log complet: $LOGFILE"
  
  if [ "$INSTALL_AUR" = true ] && command -v yay &>/dev/null; then
    local aur_count=$(yay -Qm | wc -l)
    echo -e "Paquets AUR installés: $aur_count"
  fi
  
  echo -e "${GREEN}Installation terminée avec succès !${RESET}"
}

# Vérification du mode superutilisateur
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Veuillez exécuter ce script avec sudo.${RESET}"
  exit 1
fi

# Vérification que SUDO_USER est défini
if [ -z "${SUDO_USER:-}" ]; then
  echo -e "${RED}SUDO_USER n'est pas défini. Veuillez exécuter avec sudo.${RESET}"
  exit 1
fi

# Gestion des signaux d'interruption
trap 'log_message "Installation interrompue par l'\''utilisateur"; cleanup_on_exit; exit 130' INT TERM
trap 'cleanup_on_exit' EXIT

# Gestion des arguments
if [ $# -eq 0 ]; then
  # Mode interactif si aucun argument
  choice=$(get_user_choice)
  process_menu_choice "$choice"
else
  # Mode ligne de commande avec arguments
  for arg in "$@"; do
    case $arg in
      --help)
        show_help
        exit 0
        ;;
      --update) UPDATE_ONLY=true ;;
      --base) INSTALL_BASE=true ;;
      --xfce) USE_XFCE=true; INSTALL_BASE=true ;;
      --kde) USE_KDE=true; INSTALL_BASE=true ;;
      --gnome) USE_GNOME=true; INSTALL_BASE=true ;;
      --aur) INSTALL_AUR=true ;;
      --aur-only) INSTALL_AUR=true; AUR_ONLY=true ;;
      --dry-run) DRY_RUN=true ;;
      *)
        echo -e "${RED}Option inconnue: $arg${RESET}"
        echo "Utilisez --help pour voir les options disponibles."
        exit 1
        ;;
    esac
  done
fi

# Affichage des paramètres et confirmation
echo -e "${GREEN}=== Configuration ===${RESET}"
echo -e "Utilisateur: $SUDO_USER"
echo -e "Dossier home: $USER_HOME"
echo -e "Fichier de log: $LOGFILE"
echo -e "Mode dry-run: $DRY_RUN"
echo -e "Installation paquets de base: $INSTALL_BASE"
echo -e "Installation AUR: $INSTALL_AUR"
echo -e "AUR uniquement: $AUR_ONLY"
echo -e "Environnement: $([ "$USE_XFCE" = true ] && echo "XFCE" || [ "$USE_KDE" = true ] && echo "KDE" || [ "$USE_GNOME" = true ] && echo "GNOME" || echo "Aucun spécifique")"
echo ""

# Demander confirmation avant de continuer
confirm_installation

log_message "=== Début de l'installation ==="
log_message "Configuration: UPDATE_ONLY=$UPDATE_ONLY, INSTALL_BASE=$INSTALL_BASE, USE_XFCE=$USE_XFCE, USE_KDE=$USE_KDE, USE_GNOME=$USE_GNOME, INSTALL_AUR=$INSTALL_AUR, AUR_ONLY=$AUR_ONLY, DRY_RUN=$DRY_RUN"

# Fonction principale
main() {
  # Sauvegarde et préparation
  backup_installed_packages
  create_recovery_script
  
  # Mise à jour système
  update_system

  if [ "$UPDATE_ONLY" = false ]; then
    # Installation des paquets de base (sauf si AUR_ONLY est activé)
    if [ "$INSTALL_BASE" = true ] && [ "$AUR_ONLY" = false ]; then
      install_packages
    fi
    
    # Installation des paquets AUR
    if [ "$INSTALL_AUR" = true ]; then
      install_aur_packages
    fi
    
    # Nettoyage uniquement si des paquets ont été installés
    if [ "$INSTALL_BASE" = true ] || [ "$INSTALL_AUR" = true ]; then
      cleanup
    fi
  fi

  # Résumé final
  show_installation_summary
  log_message "=== Installation terminée ==="
}

# Exécution
main
