#!/bin/bash

# ==============================================================================
# Script pour l'installation, configuration et désinstallation
# de ZRAM sur Arch Linux.
#
# Version améliorée avec sécurité renforcée et configuration adaptative
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: activation_zram.sh
# 2. Rendez-le exécutable: chmod +x activation_zram.sh
# 3. Exécutez-le: ./activation_zram.sh
# ==============================================================================

# --- Paramètres de Configuration (à modifier si besoin) ---

# Algorithme de compression. Options: zstd (recommandé), lz4, lzo-rle, lzo
ZRAM_COMP_ALGO="zstd"

# Taille du périphérique zram.
# 'ram / 2' (50% de la RAM totale) est une excellente valeur par défaut.
# Autres exemples : '4G', '8192M', 'ram / 4'.
ZRAM_SIZE="ram / 2"

# Priorité du swap. Une valeur élevée assure que ZRAM est utilisé en premier.
ZRAM_PRIORITY=100

# Type de système de fichiers. Pour un swap ZRAM, utiliser 'swap'.
ZRAM_FS_TYPE="swap"

# Variables de contrôle
PERFORM_TEST=false
VERBOSE=false
AUTO_CONFIG=true
LOG_FILE="/var/log/zram-install.log"

# --- Variables de couleur ---
C_RESET='\e[0m'
C_RED='\e[0;31m'
C_GREEN='\e[0;32m'
C_YELLOW='\e[0;33m'
C_BLUE='\e[0;34m'
C_BOLD='\e[1m'
C_CYAN='\e[0;36m'

# --- Variables globales ---
CONFIG_FILE="/etc/systemd/zram-generator.conf.d/99-zram.conf"
BACKUP_DIR="/etc/systemd/zram-generator.conf.d/backups"
EXIT_SUCCESS=0
EXIT_ERROR=1
EXIT_INSUFFICIENT_PERMS=2
EXIT_MISSING_DEPENDENCIES=3

# --- Fonctions utilitaires ---

# Validation des entrées avec regex
validate_input() {
    local input="$1"
    local pattern="$2"
    local description="$3"
    
    if [[ ! "$input" =~ $pattern ]]; then
        print_message "ERROR" "$description invalide: $input"
        exit 1
    fi
}

# Initialisation sécurisée du fichier log
init_log_file() {
    # Créer le répertoire si nécessaire avec permissions sécurisées
    mkdir -p "$(dirname "$LOG_FILE")"
    chmod 755 "$(dirname "$LOG_FILE")"

    # Vérifier les permissions d'écriture
    if ! touch "$LOG_FILE" 2>/dev/null; then
        LOG_FILE="/tmp/zram-install.log"
        print_message "WARN" "Impossible d'écrire dans /var/log, utilisation de /tmp à la place"
    fi

    # Définir des permissions sécurisées sur le fichier log
    chmod 640 "$LOG_FILE" 2>/dev/null

    # Initialiser le log
    log_message "--- Démarrage du script ZRAM v2.1 (Amélioré) ---"
}

# Fonction de logging sécurisée
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE" 2>/dev/null || true
}

# Fonction d'affichage améliorée avec validation
print_message() {
    local type="$1"
    local message="$2"
    local timestamp=$(date '+%H:%M:%S')

    # Validation des entrées
    case "$type" in
        "INFO"|"SUCCESS"|"WARN"|"ERROR"|"DEBUG") ;;
        *) 
            echo "[$timestamp] $message"
            return
            ;;
    esac

    # Logging automatique
    log_message "[$type] $message"

    case "$type" in
        "INFO") echo -e "${C_BLUE}[$timestamp] [INFO]${C_RESET} ${message}" ;;
        "SUCCESS") echo -e "${C_GREEN}[$timestamp] [SUCCESS]${C_RESET} ${message}" ;;
        "WARN") echo -e "${C_YELLOW}[$timestamp] [WARN]${C_RESET} ${message}" ;;
        "ERROR") echo -e "${C_RED}[$timestamp] [ERROR]${C_RESET} ${message}" >&2 ;;
        "DEBUG")
            if [ "$VERBOSE" = true ]; then
                echo -e "${C_CYAN}[$timestamp] [DEBUG]${C_RESET} ${message}"
            fi
            ;;
        *) echo "[$timestamp] ${message}" ;;
    esac
}

# Fonction de nettoyage améliorée en cas d'erreur
cleanup_on_error() {
    print_message "ERROR" "Une erreur s'est produite. Nettoyage en cours..."

    # Arrêter le service ZRAM s'il est actif
    if systemctl is-active --quiet systemd-zram-setup@zram0.service 2>/dev/null; then
        print_message "INFO" "Arrêt du service ZRAM..."
        systemctl stop systemd-zram-setup@zram0.service 2>/dev/null || true
    fi

    # Recharger systemd
    systemctl daemon-reload 2>/dev/null || true

    print_message "ERROR" "Nettoyage terminé. Consultez les logs pour plus d'informations."
    exit 1
}

# Vérification des privilèges root avec validation
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        print_message "ERROR" "Ce script doit être exécuté avec les privilèges root (sudo)."
        exit $EXIT_INSUFFICIENT_PERMS
    fi
}

# Détection automatique de la configuration optimale
detect_optimal_config() {
    if [ "$AUTO_CONFIG" = false ]; then
        return 0
    fi

    print_message "INFO" "Détection de la configuration optimale..."
    
    local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    local ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    
    print_message "INFO" "Mémoire totale détectée: ${ram_gb}GB (${ram_mb}MB)"

    # Configuration adaptative selon la RAM
    if [ "$ram_gb" -le 2 ]; then
        ZRAM_SIZE="ram / 4"
        ZRAM_PRIORITY=50
        print_message "INFO" "RAM faible détectée. Configuration conservatrice: ram/4, priorité 50"
    elif [ "$ram_gb" -le 4 ]; then
        ZRAM_SIZE="ram / 2"
        ZRAM_PRIORITY=100
        print_message "INFO" "RAM modérée détectée. Configuration équilibrée: ram/2, priorité 100"
    elif [ "$ram_gb" -le 8 ]; then
        ZRAM_SIZE="ram / 2"
        ZRAM_PRIORITY=150
        print_message "INFO" "RAM suffisante détectée. Configuration standard: ram/2, priorité 150"
    else
        ZRAM_SIZE="min(ram / 2, 8G)"
        ZRAM_PRIORITY=200
        print_message "INFO" "RAM importante détectée. configuration optimisée: min(ram/2, 8G), priorité 200"
    fi

    # Vérification des autres swap actifs
    local existing_swap_priority=$(swapon --show=PRIO --noheadings | sort -n | head -1 2>/dev/null || echo "100")
    if [ "$existing_swap_priority" -ne "" ] && [ "$existing_swap_priority" -ge "$ZRAM_PRIORITY" ]; then
        ZRAM_PRIORITY=$((existing_swap_priority + 10))
        print_message "INFO" "Ajustement de la priorité du swap à $ZRAM_PRIORITY pour être plus élevé que les swap existants"
    fi
}

# Validation des paramètres de configuration renforcée
validate_config() {
    print_message "DEBUG" "Validation de la configuration..."

    # Validation de l'algorithme de compression
    validate_input "$ZRAM_COMP_ALGO" "^(zstd|lz4|lzo-rle|lzo)$" "Algorithme de compression"
    print_message "DEBUG" "Algorithme de compression valide: $ZRAM_COMP_ALGO"

    # Validation de la taille ZRAM avec regex améliorée
    validate_input "$ZRAM_SIZE" "^(ram\s*/\s*[2-4])$|^([0-9]+[GMK])$|^min\(ram\s*/\s*[2-4],\s*[0-9]+[GMK]\)$" "Taille ZRAM"
    print_message "DEBUG" "Taille ZRAM valide: $ZRAM_SIZE"

    # Validation de la priorité
    validate_input "$ZRAM_PRIORITY" "^[0-9]+$" "Priorité"
    if [ "$ZRAM_PRIORITY" -lt 0 ] || [ "$ZRAM_PRIORITY" -gt 32767 ]; then
        print_message "ERROR" "Priorité invalide (0-32767): $ZRAM_PRIORITY"
        exit 1
    fi
    print_message "DEBUG" "Priorité valide: $ZRAM_PRIORITY"

    print_message "SUCCESS" "Configuration validée avec succès"
}

# Vérification des prérequis système améliorée
check_system_requirements() {
    print_message "INFO" "Vérification des prérequis système..."

    # Vérification de la version du kernel
    local kernel_version=$(uname -r | cut -d. -f1-2)
    local kernel_major=$(echo "$kernel_version" | cut -d. -f1)
    local kernel_minor=$(echo "$kernel_version" | cut -d. -f2)

    if [ "$kernel_major" -lt 3 ] || ([ "$kernel_major" -eq 3 ] && [ "$kernel_minor" -lt 15 ]); then
        print_message "WARN" "Version de kernel ancienne détectée: $kernel_version"
        print_message "WARN" "ZRAM nécessite au minimum le kernel 3.15"
    else
        print_message "SUCCESS" "Version de kernel compatible: $kernel_version"
    fi

    # Vérification de l'espace disque disponible
    local disk_space=$(df /var | awk 'NR==2 {print $4}')
    if [ "$disk_space" -lt 1024 ]; then
        print_message "WARN" "Espace disque faible dans /var: ${disk_space}KB (recommandé: 1GB+)"
    else
        print_message "SUCCESS" "Espace disque suffisant: ${disk_space}KB"
    fi

    # Vérification de la disponibilité des commandes essentielles
    local required_commands=("systemctl" "pacman" "free" "awk" "grep" "sed")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            print_message "ERROR" "Commande requise manquante: $cmd"
            exit $EXIT_MISSING_DEPENDENCIES
        fi
    done

    print_message "SUCCESS" "Tous les prérequis sont satisfaits"
}

# Sauvegarde atomique des configurations existantes
backup_existing_config() {
    local config_file="$1"

    if [ -f "$config_file" ]; then
        mkdir -p "$BACKUP_DIR"
        chmod 700 "$BACKUP_DIR"
        
        local backup_file="${BACKUP_DIR}/99-zram.conf.backup.$(date +%Y%m%d_%H%M%S)"
        local temp_backup=$(mktemp "${BACKUP_DIR}/temp_backup.XXXXXX")

        # Copie atomique
        if cp "$config_file" "$temp_backup" && mv "$temp_backup" "$backup_file"; then
            chmod 640 "$backup_file"
            print_message "SUCCESS" "Configuration existante sauvegardée: $backup_file"
        else
            rm -f "$temp_backup" 2>/dev/null || true
            print_message "WARN" "Impossible de sauvegarder la configuration existante"
        fi
    fi
}

# Installation du paquet zram-generator avec validation
install_package() {
    print_message "INFO" "Vérification de l'installation de 'zram-generator'..."

    if pacman -Q zram-generator &>/dev/null; then
        print_message "SUCCESS" "'zram-generator' est déjà installé."
        local version=$(pacman -Q zram-generator | awk '{print $2}')
        print_message "INFO" "Version installée: $version"

        # Vérifier que le service est disponible
        if ! systemctl list-unit-files | grep -q "systemd-zram-setup"; then
            print_message "WARN" "Le paquet est installé mais les services ne sont pas disponibles"
        fi
    else
        print_message "INFO" "Installation de 'zram-generator'..."

        # Mise à jour de la base de données des paquets
        print_message "INFO" "Mise à jour de la base de données des paquets..."
        if ! pacman -Sy --noconfirm 2>&1 | grep -q "total"; then
            print_message "WARN" "Échec de la mise à jour de la base de données"
        fi

        # Installation du paquet
        if pacman -S --noconfirm zram-generator; then
            print_message "SUCCESS" "'zram-generator' a été installé avec succès."
        else
            print_message "ERROR" "L'installation de zram-generator a échoué."
            log_message "Installation échouée. Code de sortie: $?"
            exit $EXIT_ERROR
        fi
    fi
}

# Configuration de ZRAM avec écriture atomique
configure_zram() {
    print_message "INFO" "Application de la configuration ZRAM..."
    print_message "INFO" "  - Algorithme : ${C_BOLD}${ZRAM_COMP_ALGO}${C_RESET}"
    print_message "INFO" "  - Taille       : ${C_BOLD}${ZRAM_SIZE}${C_RESET}"
    print_message "INFO" "  - Priorité     : ${C_BOLD}${ZRAM_PRIORITY}${C_RESET}"
    print_message "INFO" "  - Type FS      : ${C_BOLD}${ZRAM_FS_TYPE}${C_RESET}"

    # Sauvegarder la configuration existante
    backup_existing_config "$CONFIG_FILE"

    # Créer le répertoire de configuration
    mkdir -p "$(dirname "$CONFIG_FILE")"
    chmod 755 "$(dirname "$CONFIG_FILE")"

    # Création atomique du fichier de configuration
    local temp_config=$(mktemp "${CONFIG_FILE}.tmp.XXXXXX")
    
    cat <<EOF > "$temp_config"
# Fichier de configuration pour zram-generator
# Généré par le script activation_zram.sh v2.1 (Amélioré)
# Date: $(date)
#
# Documentation:
#   compression-algorithm: Algorithme de compression (zstd, lz4, lzo-rle, lzo)
#   zram-size: Taille du device ZRAM (ex: 4G, ram/2, ram/4)
#   swap-priority: Priorité du swap (0-32767, plus élevé = utilisé en premier)
#   fs-type: Type de système de fichiers (swap)

[zram0]
compression-algorithm = ${ZRAM_COMP_ALGO}
zram-size = ${ZRAM_SIZE}
swap-priority = ${ZRAM_PRIORITY}
fs-type = ${ZRAM_FS_TYPE}
EOF

    # Déplacement atomique
    if mv "$temp_config" "$CONFIG_FILE"; then
        chmod 644 "$CONFIG_FILE"
        print_message "SUCCESS" "Fichier de configuration créé/mis à jour: $CONFIG_FILE"
    else
        rm -f "$temp_config" 2>/dev/null || true
        print_message "ERROR" "Échec de la création du fichier de configuration"
        exit $EXIT_ERROR
    fi
}

# Activation de ZRAM avec vérifications améliorées
activate_zram() {
    print_message "INFO" "Rechargement de systemd et activation de ZRAM..."

    # Recharger systemd
    if systemctl daemon-reload; then
        print_message "SUCCESS" "systemd rechargé avec succès"
    else
        print_message "ERROR" "Échec du rechargement de systemd"
        exit $EXIT_ERROR
    fi

    # Démarrer le service ZRAM
    if systemctl start systemd-zram-setup@zram0.service; then
        print_message "SUCCESS" "Service ZRAM démarré avec succès"
    else
        print_message "ERROR" "Échec du démarrage du service ZRAM"
        print_message "INFO" "Vérifiez les logs: journalctl -u systemd-zram-setup@zram0.service"
        exit $EXIT_ERROR
    fi

    # Activer le service au boot
    if systemctl enable systemd-zram-setup@zram0.service; then
        print_message "SUCCESS" "Service ZRAM activé au démarrage"
    else
        print_message "WARN" "Impossible d'activer le service au démarrage"
    fi

    # Attendre un peu pour que le service s'initialise
    sleep 2

    # Vérifier que le service est actif
    if systemctl is-active --quiet systemd-zram-setup@zram0.service; then
        print_message "SUCCESS" "Service ZRAM actif et fonctionnel"
    else
        print_message "ERROR" "Service ZRAM non actif après démarrage"
        exit $EXIT_ERROR
    fi
}

# Test de performance ZRAM (optionnel)
test_zram_performance() {
    print_message "INFO" "Test de performance ZRAM..."

    # Vérifier que ZRAM est actif
    if ! systemctl is-active --quiet systemd-zram-setup@zram0.service; then
        print_message "WARN" "ZRAM non actif, impossible de tester les performances"
        return 1
    fi

    # Test d'écriture simple avec validation
    local test_file=$(mktemp /tmp/zram_test_XXXXXX)
    local test_size="100M"

    print_message "INFO" "Test d'écriture de $test_size..."

    if dd if=/dev/zero of="$test_file" bs=1M count=100 2>/dev/null; then
        print_message "SUCCESS" "Test d'écriture réussi"

        # Test de lecture
        print_message "INFO" "Test de lecture..."
        if dd if="$test_file" of=/dev/null bs=1M 2>/dev/null; then
            print_message "SUCCESS" "Test de lecture réussi"
        else
            print_message "WARN" "Test de lecture échoué"
        fi
    else
        print_message "WARN" "Test d'écriture échoué"
    fi

    # Nettoyage sécurisé
    rm -f "$test_file" 2>/dev/null || true

    print_message "SUCCESS" "Tests de performance terminés"
}

# Vérification complète du statut ZRAM
verify_zram() {
    print_message "INFO" "Vérification complète du statut ZRAM..."

    # Vérifier le service
    if systemctl is-active --quiet systemd-zram-setup@zram0.service; then
        print_message "SUCCESS" "Service ZRAM actif"
    else
        print_message "ERROR" "Service ZRAM inactif"
        return 1
    fi

    # Vérifier le périphérique
    if [ -b "/dev/zram0" ]; then
        print_message "SUCCESS" "Périphérique /dev/zram0 détecté"
    else
        print_message "ERROR" "Périphérique /dev/zram0 non trouvé"
        return 1
    fi

    # Afficher les statistiques détaillées
    echo -e "\n${C_YELLOW}--- Statistiques ZRAM ---${C_RESET}"
    zramctl

    echo -e "\n${C_YELLOW}--- Swap actif ---${C_RESET}"
    swapon --show

    # Vérifier l'utilisation
    local zram_usage=$(zramctl | awk 'NR>1 {print $4}' | head -1)
    if [ -n "$zram_usage" ] && [ "$zram_usage" != "0" ]; then
        print_message "SUCCESS" "ZRAM utilisé: $zram_usage"
    else
        print_message "INFO" "ZRAM configuré mais pas encore utilisé"
    fi

    # Afficher les informations de compression
    echo -e "\n${C_YELLOW}--- Informations de compression ---${C_RESET}"
    if [ -f "/sys/block/zram0/comp_algorithm" ]; then
        echo "Algorithme actuel: $(cat /sys/block/zram0/comp_algorithm)"
    fi

    if [ -f "/sys/block/zram0/compression_ratio" ]; then
        echo "Ratio de compression: $(cat /sys/block/zram0/compression_ratio)"
    fi

    print_message "SUCCESS" "Vérification ZRAM terminée"
}

# Désinstallation de ZRAM avec nettoyage sécurisé
uninstall_zram() {
    local full_uninstall=false
    if [[ "$1" == "--purge" ]]; then
        full_uninstall=true
    fi

    print_message "INFO" "Désinstallation de ZRAM..."

    # Arrêter le service ZRAM
    print_message "INFO" "Arrêt du service ZRAM..."
    if systemctl is-active --quiet systemd-zram-setup@zram0.service; then
        if systemctl stop systemd-zram-setup@zram0.service; then
            print_message "SUCCESS" "Service ZRAM arrêté"
        else
            print_message "WARN" "Impossible d'arrêter le service ZRAM"
        fi
    else
        print_message "INFO" "Service ZRAM déjà arrêté"
    fi

    # Supprimer le fichier de configuration
    if [ -f "$CONFIG_FILE" ]; then
        print_message "INFO" "Suppression du fichier de configuration..."
        if rm -f "$CONFIG_FILE"; then
            print_message "SUCCESS" "Fichier de configuration supprimé"
        else
            print_message "WARN" "Impossible de supprimer le fichier de configuration"
        fi
    fi

    # Recharger systemd
    systemctl daemon-reload 2>/dev/null || true
    print_message "SUCCESS" "ZRAM a été désactivé"

    # Désinstaller le paquet si demandé
    if $full_uninstall; then
        print_message "INFO" "Désinstallation du paquet 'zram-generator'..."
        if pacman -Rns --noconfirm zram-generator; then
            print_message "SUCCESS" "Paquet 'zram-generator' désinstallé"
        else
            print_message "WARN" "Impossible de désinstaller le paquet"
        fi
    else
        print_message "INFO" "Le paquet 'zram-generator' est conservé. Utilisez 'uninstall --purge' pour le supprimer."
    fi

    print_message "SUCCESS" "Désinstallation terminée"
}

# Fonction de rollback améliorée
rollback_installation() {
    print_message "INFO" "Rollback de l'installation..."

    # Arrêter le service
    systemctl stop systemd-zram-setup@zram0.service 2>/dev/null || true

    # Supprimer la configuration
    rm -f "$CONFIG_FILE" 2>/dev/null || true

    # Recharger systemd
    systemctl daemon-reload 2>/dev/null || true

    print_message "SUCCESS" "Rollback terminé"
}

# Affichage des informations de configuration
show_config_info() {
    echo -e "\n${C_BOLD}Configuration ZRAM:${C_RESET}"
    echo "  Algorithme: $ZRAM_COMP_ALGO"
    echo "  Taille: $ZRAM_SIZE"
    echo "  Priorité: $ZRAM_PRIORITY"
    echo "  Type FS: $ZRAM_FS_TYPE"
    echo "  Auto-config: $AUTO_CONFIG"
    echo "  Fichier de config: $CONFIG_FILE"
    echo "  Log: $LOG_FILE"
    echo
}

# Parsing des arguments en ligne de commande avec validation
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --size)
                validate_input "$2" "^(ram\s*/\s*[2-4])$|^([0-9]+[GMK])$|^min\(ram\s*/\s*[2-4],\s*[0-9]+[GMK]\)$" "Taille"
                ZRAM_SIZE="$2"
                shift 2
                ;;
            --algorithm)
                validate_input "$2" "^(zstd|lz4|lzo-rle|lzo)$" "Algorithme"
                ZRAM_COMP_ALGO="$2"
                shift 2
                ;;
            --priority)
                validate_input "$2" "^[0-9]+$" "Priorité"
                if [ "$2" -lt 0 ] || [ "$2" -gt 32767 ]; then
                    print_message "ERROR" "Priorité invalide (0-32767): $2"
                    exit 1
                fi
                ZRAM_PRIORITY="$2"
                shift 2
                ;;
            --test)
                PERFORM_TEST=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --no-auto-config)
                AUTO_CONFIG=false
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                COMMAND="$1"
                shift
                ;;
        esac
    done
}

# Affichage de l'aide
show_usage() {
    echo "Usage: sudo $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commandes:"
    echo "  install          (défaut) Installe et configure ZRAM avec les paramètres du script."
    echo "  uninstall        Désactive ZRAM et supprime sa configuration."
    echo "  uninstall --purge  Fait la même chose que 'uninstall' et supprime aussi le paquet."
    echo "  verify           Vérifie le statut actuel de ZRAM."
    echo "  test             Teste les performances de ZRAM."
    echo "  rollback         Annule l'installation et restaure l'état précédent."
    echo
    echo "Options:"
    echo "  --size SIZE      Définit la taille ZRAM (ex: '4G', 'ram / 2')"
    echo "  --algorithm ALGO Définit l'algorithme de compression (zstd, lz4, lzo-rle, lzo)"
    echo "  --priority PRIO  Définit la priorité du swap (0-32767)"
    echo "  --test           Effectue des tests de performance après installation"
    echo "  --verbose, -v    Active le mode verbeux"
    echo "  --no-auto-config Désactive la configuration automatique adaptative"
    echo "  --help, -h       Affiche cette aide"
    echo
    echo "Exemples:"
    echo "  sudo $0 install --size '8G' --algorithm lz4 --test"
    echo "  sudo $0 uninstall --purge"
    echo "  sudo $0 verify"
    echo
    echo "Nouveautés v2.1:"
    echo "  - Configuration automatique adaptative selon la RAM disponible"
    echo "  - Validation renforcée des entrées utilisateur"
    echo "  - Opérations atomiques pour la sécurité"
    echo "  - Gestion améliorée des erreurs et permissions"
}

# --- Point d'entrée du script ---

main() {
    # Initialisation du fichier log
    init_log_file

    # Configuration du trap pour la gestion d'erreurs
    trap cleanup_on_error ERR

    # Vérification des privilèges
    check_root

    # Parsing des arguments
    COMMAND=${1:-install}
    parse_arguments "$@"

    # Détection automatique de la configuration optimale
    detect_optimal_config

    # Affichage des informations de configuration
    show_config_info

    # Validation de la configuration
    validate_config

    # Vérification des prérequis système
    check_system_requirements

    case "$COMMAND" in
        install)
            install_package
            configure_zram
            activate_zram
            echo
            verify_zram

            if [ "$PERFORM_TEST" = true ]; then
                echo
                test_zram_performance
            fi

            print_message "SUCCESS" "Installation et configuration de ZRAM terminées !"
            print_message "INFO" "Logs disponibles dans: $LOG_FILE"
            ;;
        uninstall)
            uninstall_zram "$2"
            ;;
        verify)
            verify_zram
            ;;
        test)
            test_zram_performance
            ;;
        rollback)
            rollback_installation
            ;;
        *)
            print_message "ERROR" "Commande non valide: $COMMAND"
            show_usage
            exit 1
            ;;
    esac
}

# Exécution du script principal
main "$@"
