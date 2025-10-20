#!/bin/bash
set -euo pipefail

###############################################################################
# Script d'installation automatisée des applications Flatpak
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: installation_flatpak.sh
# 2. Rendez-le exécutable: chmod +x installation_flatpak.sh
# 3. Exécutez-le: sudo ./installation_flatpak.sh [--help] [--dry-run] [--list]
#
# Options:
# --help : Affiche l'aide et quitte
# --dry-run : Simule les installations sans effectuer de modifications
# --list : Affiche la liste des applications qui seraient installées
###############################################################################

# Couleurs
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

# Options
DRY_RUN=false
SHOW_HELP=false
SHOW_LIST=false

# Configuration du dossier utilisateur
USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)

# Fonction d'aide
show_help() {
    echo -e "${GREEN}=== Aide du script d'installation Flatpak ===${RESET}"
    echo ""
    echo "Ce script permet d'installer automatiquement des applications Flatpak."
    echo ""
    echo "UTILISATION:"
    echo "  sudo ./installation_flatpak.sh [options]"
    echo ""
    echo "OPTIONS:"
    echo "  --help      Affiche cette aide"
    echo "  --dry-run   Simule les installations sans effectuer de modifications"
    echo "  --list      Affiche la liste des applications qui seraient installées"
    echo ""
    echo "APPLICATIONS INSTALLÉES:"
    echo "  - Bottles: Gestionnaire de bouteilles pour Wine"
    echo "  - EasyFlatpak: Interface graphique pour Flatpak"
    echo "  - Warehouse: Gestionnaire d'applications Flatpak"
    echo "  - Flatseal: Gestionnaire de permissions Flatpak"
    echo "  - FlatSweep: Nettoyeur de données Flatpak"
}

# Fonction de nettoyage en cas d'interruption
cleanup_on_exit() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}Installation interrompue.${RESET}"
    fi
}

# Fonction de confirmation
confirm_installation() {
    if [ "$DRY_RUN" = false ]; then
        echo -e "${YELLOW}Continuer avec l'installation des applications Flatpak ? (y/N)${RESET}"
        read -r -n 1 -p "> " response
        echo
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Installation annulée.${RESET}"
            exit 0
        fi
    fi
}

# Installation avec retry automatique
install_flatpak_with_retry() {
    local app="$1"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if [ "$DRY_RUN" = false ]; then
            if flatpak install -y flathub "$app"; then
                return 0
            else
                if [ $attempt -lt $max_attempts ]; then
                    echo -e "${YELLOW}Nouvelle tentative dans 5 secondes...${RESET}"
                    sleep 5
                fi
            fi
        else
            echo "DRY-RUN: flatpak install -y flathub $app"
            return 0
        fi
        
        attempt=$((attempt + 1))
    done
    
    return 1
}

# Vérifie si flatpak est installé
check_flatpak_installed() {
    if ! command -v flatpak &> /dev/null; then
        echo -e "${RED}❌ Flatpak n'est pas installé. Veuillez l'installer d'abord avec:${RESET}"
        echo -e "${YELLOW}sudo pacman -S flatpak${RESET}"
        exit 1
    fi
}

# Vérifie et ajoute le remote Flathub
setup_flathub_remote() {
    if ! flatpak remotes | grep -q flathub; then
        echo -e "${BLUE}➕ Ajout du remote Flathub...${RESET}"
        if [ "$DRY_RUN" = false ]; then
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        else
            echo "DRY-RUN: flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
        fi
    else
        echo -e "${GREEN}✓ Remote Flathub déjà configuré${RESET}"
    fi
}

# Liste des applications Flatpak à installer
applications=(
    "com.usebottles.bottles:Bottles - Gestionnaire de bouteilles Wine"
    #"org.dupot.easyflatpak:EasyFlatpak - Interface graphique Flatpak"
    "io.github.flattool.Warehouse:Warehouse - Gestionnaire d'applications Flatpak"
    "com.github.tchx84.Flatseal:Flatseal - Gestionnaire de permissions Flatpak"
    "io.github.giantpinkrobots.flatsweep:FlatSweep - Nettoyeur de données Flatpak"
    "io.github.kolunmi.Bazaar:Bazaar - Gestionnaire de paquets Flatpak"
    #"io.github.dvlv.boxbuddyrs:Box Buddy - Gestionnaire de paquets Flatpak"
    #"it.mijorus.gearlever:Gearlever - Gestionnaire de paquets Flatpak"
)

# Fonction pour afficher la liste des applications
show_applications_list() {
    echo -e "${GREEN}=== Applications Flatpak qui seront installées ===${RESET}"
    echo ""
    for app_info in "${applications[@]}"; do
        app_id="${app_info%%:*}"
        app_desc="${app_info##*:}"
        echo -e "${BLUE}•${RESET} $app_desc"
        echo -e "  ${YELLOW}ID:${RESET} $app_id"
        echo ""
    done
}

# Installation des applications
install_applications() {
    local total_apps=${#applications[@]}
    local current_app=0
    local failed_apps=()
    local success_count=0

    echo -e "${GREEN}=== Installation des applications Flatpak ===${RESET}"
    echo ""

    for app_info in "${applications[@]}"; do
        current_app=$((current_app + 1))
        app_id="${app_info%%:*}"
        app_desc="${app_info##*:}"
        
        echo -e "${GREEN}[$current_app/$total_apps] Installation de $app_desc...${RESET}"
        
        # Vérifier si l'application est déjà installée
        if flatpak list | grep -q "$app_id"; then
            echo -e "${YELLOW}[$app_id] déjà installé.${RESET}"
            success_count=$((success_count + 1))
        else
            echo -e "${GREEN}Installation de [$app_id]...${RESET}"
            if install_flatpak_with_retry "$app_id"; then
                echo -e "${GREEN}✓ [$app_id] installé avec succès${RESET}"
                success_count=$((success_count + 1))
            else
                failed_apps+=("$app_id")
                echo -e "${RED}✗ Échec de l'installation de [$app_id]${RESET}"
            fi
        fi
        echo ""
    done

    # Rapport final
    echo -e "${GREEN}=== Résumé de l'installation ===${RESET}"
    echo -e "Applications installées avec succès: $success_count/$total_apps"
    
    if [ ${#failed_apps[@]} -gt 0 ]; then
        echo -e "${RED}Applications non installées: ${failed_apps[*]}${RESET}"
    fi
    
    if [ "$DRY_RUN" = false ]; then
        echo -e "${GREEN}✅ Installation terminée.${RESET}"
    else
        echo -e "${YELLOW}🔍 Mode simulation terminé.${RESET}"
    fi
}

# Fonction de nettoyage final
cleanup() {
    if [ "$DRY_RUN" = false ]; then
        echo -e "${BLUE}🧹 Nettoyage du cache Flatpak...${RESET}"
        flatpak uninstall --unused -y 2>/dev/null || true
    else
        echo "DRY-RUN: Nettoyage du cache Flatpak"
    fi
}

# Gestion des arguments
for arg in "$@"; do
    case $arg in
        --help)
            show_help
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --list)
            SHOW_LIST=true
            ;;
        *)
            echo -e "${RED}Option inconnue: $arg${RESET}"
            echo "Utilisez --help pour voir les options disponibles."
            exit 1
            ;;
    esac
done

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
trap 'cleanup_on_exit; exit 130' INT TERM
trap 'cleanup_on_exit' EXIT

# Fonction principale
main() {
    echo -e "${GREEN}=== Script d'installation des applications Flatpak ===${RESET}"
    echo -e "Utilisateur: $SUDO_USER"
    echo -e "Date: $(date)"
    echo -e "Mode dry-run: $DRY_RUN"
    echo ""
    
    # Afficher la liste si demandé
    if [ "$SHOW_LIST" = true ]; then
        show_applications_list
        exit 0
    fi
    
    # Vérifications préliminaires
    check_flatpak_installed
    setup_flathub_remote
    
    # Demander confirmation avant de continuer
    confirm_installation
    
    # Installation
    install_applications
    
    # Nettoyage
    cleanup
}

# Exécution
main
