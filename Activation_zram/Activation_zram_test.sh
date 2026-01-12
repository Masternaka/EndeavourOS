#!/bin/bash

# ==============================================================================
# Script pour l'installation, configuration et désinstallation
# de ZRAM sur Arch Linux.
#
# La configuration est prédéfinie dans les variables ci-dessous.
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: Activation_zram.sh
# 2. Rendez-le exécutable: chmod +x Activation_zram.sh
# 3. Exécutez-le: ./Activation_zram.sh
# ==============================================================================

# --- Paramètres de Configuration (à modifier si besoin) ---

# Algorithme de compression. Options: zstd (recommandé), lz4, lzo-rle
ZRAM_COMP_ALGO="zstd"

# Taille du périphérique zram.
# 'ram / 2' (50% de la RAM totale) est une excellente valeur par défaut.
# Autres exemples : '4G', '8192M'.
ZRAM_SIZE="ram / 2"

# Priorité du swap. Une valeur élevée assure que ZRAM est utilisé en premier.
ZRAM_PRIORITY=100

# --- Variables de couleur ---
C_RESET='\e[0m'
C_RED='\e[0;31m'
C_GREEN='\e[0;32m'
C_YELLOW='\e[0;33m'
C_BLUE='\e[0;34m'
C_BOLD='\e[1m'

# --- Fonctions utilitaires ---
print_message() {
    local type="$1"
    local message="$2"
    case "$type" in
        "INFO") echo -e "${C_BLUE}[INFO]${C_RESET} ${message}" ;;
        "SUCCESS") echo -e "${C_GREEN}[SUCCESS]${C_RESET} ${message}" ;;
        "WARN") echo -e "${C_YELLOW}[WARN]${C_RESET} ${message}" ;;
        "ERROR") echo -e "${C_RED}[ERROR]${C_RESET} ${message}" >&2 ;;
        *) echo "${message}" ;;
    esac
}

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        print_message "ERROR" "Ce script doit être exécuté avec les privilèges root (sudo)."
        exit 1
    fi
}

# --- Fonctions principales ---

install_package() {
    print_message "INFO" "Vérification de l'installation de 'zram-generator'..."
    if pacman -Q zram-generator &>/dev/null; then
        print_message "SUCCESS" "'zram-generator' est déjà installé."
    else
        print_message "INFO" "Installation de 'zram-generator'..."
        if ! pacman -Syu --noconfirm zram-generator; then
            print_message "ERROR" "L'installation de zram-generator a échoué."
            exit 1
        fi
        print_message "SUCCESS" "'zram-generator' a été installé."
    fi
}

configure_zram() {
    local config_dir="/etc/systemd/zram-generator.conf.d"
    local config_file="${config_dir}/99-zram.conf"

    print_message "INFO" "Application de la configuration ZRAM prédéfinie..."
    print_message "INFO" "  - Algorithme : ${C_BOLD}${ZRAM_COMP_ALGO}${C_RESET}"
    print_message "INFO" "  - Taille       : ${C_BOLD}${ZRAM_SIZE}${C_RESET}"

    if [ -f "$config_file" ]; then
        print_message "WARN" "Un fichier de configuration existant sera écrasé : ${config_file}"
    fi

    mkdir -p "$config_dir"
    cat <<EOF > "$config_file"
# Fichier de configuration pour zram-generator
# Généré par le script install_zram_auto.sh

[zram0]
compression-algorithm = ${ZRAM_COMP_ALGO}
zram-size = ${ZRAM_SIZE}
swap-priority = ${ZRAM_PRIORITY}
EOF
    print_message "SUCCESS" "Fichier de configuration créé/mis à jour."
}

activate_zram() {
    print_message "INFO" "Rechargement de systemd et activation de ZRAM..."
    systemctl daemon-reload
    if systemctl start systemd-zram-setup@zram0.service; then
        print_message "SUCCESS" "Service ZRAM démarré avec succès."
    else
        print_message "ERROR" "Échec du démarrage du service ZRAM. Un redémarrage peut être nécessaire."
        exit 1
    fi
}

verify_zram() {
    print_message "INFO" "Vérification du statut de ZRAM..."
    echo -e "${C_YELLOW}--- zramctl ---${C_RESET}"
    zramctl
    echo -e "${C_YELLOW}--- swapon --show ---${C_RESET}"
    swapon --show
    if ! swapon --show | grep -q '/dev/zram0'; then
        print_message "WARN" "ZRAM ne semble pas être actif en tant que swap. Vérifiez les journaux (journalctl -u systemd-zram-setup@zram0.service)."
    fi
}

uninstall_zram() {
    local full_uninstall=false
    if [[ "$1" == "--purge" ]]; then
        full_uninstall=true
    fi

    print_message "INFO" "Désinstallation de ZRAM..."
    local config_file="/etc/systemd/zram-generator.conf.d/99-zram.conf"

    print_message "INFO" "Arrêt du service ZRAM..."
    systemctl stop systemd-zram-setup@zram0.service 2>/dev/null

    if [ -f "$config_file" ]; then
        print_message "INFO" "Suppression du fichier de configuration..."
        rm -f "$config_file"
        print_message "SUCCESS" "Fichier de configuration supprimé."
    fi

    systemctl daemon-reload
    print_message "SUCCESS" "ZRAM a été désactivé."

    if $full_uninstall; then
        print_message "INFO" "Désinstallation du paquet 'zram-generator'..."
        pacman -Rns --noconfirm zram-generator
        print_message "SUCCESS" "Paquet 'zram-generator' désinstallé."
    else
        print_message "INFO" "Le paquet 'zram-generator' est conservé. Utilisez 'uninstall --purge' pour le supprimer."
    fi

    print_message "SUCCESS" "Nettoyage terminé."
}

show_usage() {
    echo "Usage: sudo $0 [COMMAND]"
    echo
    echo "Commandes:"
    echo "  install          (défaut) Installe et configure ZRAM avec les paramètres du script."
    echo "  uninstall        Désactive ZRAM et supprime sa configuration."
    echo "  uninstall --purge  Fait la même chose que 'uninstall' et supprime aussi le paquet 'zram-generator'."
    echo "  verify           Vérifie le statut actuel de ZRAM."
}

# --- Point d'entrée du script ---

main() {
    check_root
    COMMAND=${1:-install} # 'install' est la commande par défaut

    case "$COMMAND" in
        install)
            install_package
            configure_zram
            activate_zram
            echo
            verify_zram
            print_message "SUCCESS" "Installation et configuration de ZRAM terminées !"
            ;;
        uninstall)
            uninstall_zram "$2" # Passe le second argument (ex: --purge)
            ;;
        verify)
            verify_zram
            ;;
        *)
            print_message "ERROR" "Commande non valide: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"