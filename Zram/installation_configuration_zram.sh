#!/bin/bash
set -euo pipefail

###############################################################################
# Script pour l'installation et la configuration de zram
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: zram-manager.sh
# 2. Rendez-le exécutable: chmod +x zram-manager.sh
# 3. Exécutez-le: sudo ./zram-manager.sh [options]
#
# Options:
#   -h, --help          Affiche l'aide
#   -i, --install       Installe et configure zram
#   -r, --remove        Supprime zram et restaure la configuration
#   -s, --status        Affiche le statut de zram
#   -c, --config        Configure zram avec des paramètres personnalisés
#   --size SIZE         Taille de zram (ex: 2G, 50%, ram/2)
#   --compression ALG   Algorithme de compression (zstd, lzo, lz4)
#   --priority NUM      Priorité du swap (1-32767)
#   --dry-run          Mode simulation
#
# ***Installation standard***
# sudo ./zram-manager.sh install

# ***Configuration personnalisée***
# sudo ./zram-manager.sh --size 4G --compression lz4 install

# ***Vérification du statut***
# sudo ./zram-manager.sh status

# ***Recommandations système***
# sudo ./zram-manager.sh recommendations

# ***Suppression complète***
# sudo ./zram-manager.sh remove

# ***Mode simulation***
# sudo ./zram-manager.sh --dry-run install
###############################################################################

# Configuration par défaut
SCRIPT_NAME=$(basename "$0")
ZRAM_CONFIG_FILE="/etc/systemd/zram-generator.conf"
BACKUP_DIR="/var/backups/zram-manager"
LOGFILE="/var/log/zram-manager.log"

# Paramètres par défaut
DEFAULT_SIZE="ram / 2"
DEFAULT_COMPRESSION="zstd"
DEFAULT_PRIORITY="100"
DEFAULT_DEVICE="zram0"

# Variables globales
DRY_RUN=false
VERBOSE=false
FORCE=false
CUSTOM_SIZE=""
CUSTOM_COMPRESSION=""
CUSTOM_PRIORITY=""

# Couleurs pour le logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] [COMMAND]

Script de gestion de zram pour optimiser les performances système.

COMMANDES:
    install     Installe et configure zram (par défaut)
    remove      Supprime zram et restaure la configuration
    status      Affiche le statut de zram
    config      Reconfigure zram avec de nouveaux paramètres

OPTIONS:
    -h, --help              Affiche cette aide
    -v, --verbose           Mode verbeux
    -f, --force             Force l'opération sans confirmation
    --dry-run              Mode simulation (aucune action réelle)
    --size SIZE            Taille de zram (ex: 2G, 50%, ram/2)
    --compression ALG      Algorithme de compression (zstd, lzo, lz4, lzo-rle)
    --priority NUM         Priorité du swap (1-32767, défaut: 100)
    --logfile FILE         Fichier de log personnalisé

EXEMPLES:
    $SCRIPT_NAME install                    # Installation standard
    $SCRIPT_NAME --size 4G install         # Installation avec 4GB de zram
    $SCRIPT_NAME --compression lz4 install # Installation avec compression LZ4
    $SCRIPT_NAME status                     # Affiche le statut
    $SCRIPT_NAME remove                     # Supprime zram
    $SCRIPT_NAME --dry-run install         # Simulation d'installation

ALGORITHMES DE COMPRESSION:
    zstd     - Meilleur ratio, CPU moyen (recommandé)
    lzo      - Bon compromis vitesse/ratio
    lz4      - Plus rapide, ratio moyen
    lzo-rle  - Optimisé pour données répétitives

TAILLES SUPPORTÉES:
    Absolue: 1G, 2G, 4G, etc.
    Relative: 25%, 50%, 75%, etc.
    Formule: ram/2, ram/4, etc.
EOF
}

# Fonction de logging
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""

    case "$level" in
        "INFO")     color="$GREEN" ;;
        "WARNING")  color="$YELLOW" ;;
        "ERROR")    color="$RED" ;;
        "DEBUG")    color="$BLUE" ;;
        "SUCCESS")  color="$GREEN" ;;
    esac

    # Affichage console
    echo -e "${color}[$level]${NC} $message"

    # Écriture dans le fichier de log
    echo "[$timestamp] [$level] $message" >> "$LOGFILE"
}

log_info() { log_message "INFO" "$1"; }
log_warning() { log_message "WARNING" "$1"; }
log_error() { log_message "ERROR" "$1"; }
log_debug() { [[ "$VERBOSE" == true ]] && log_message "DEBUG" "$1"; }
log_success() { log_message "SUCCESS" "$1"; }

# Fonction pour exécuter une commande avec gestion du dry-run
execute_command() {
    local cmd="$1"
    local description="$2"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] $description"
        log_debug "[DRY-RUN] Commande: $cmd"
        return 0
    fi

    log_debug "Exécution: $cmd"

    if eval "$cmd" >> "$LOGFILE" 2>&1; then
        log_success "$description"
        return 0
    else
        log_error "Échec: $description"
        return 1
    fi
}

# Vérifications préliminaires
check_prerequisites() {
    log_debug "Vérification des prérequis..."

    # Vérifier si on est root
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi

    # Vérifier si on est sur Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        log_warning "Ce script est optimisé pour Arch Linux"
    fi

    # Vérifier la disponibilité de pacman
    if ! command -v pacman &> /dev/null; then
        log_error "pacman n'est pas disponible"
        exit 1
    fi

    # Vérifier le support du noyau pour zram
    if [[ ! -d /sys/class/zram-control ]]; then
        log_info "Module zram non chargé, tentative de chargement..."
        if ! modprobe zram; then
            log_error "Impossible de charger le module zram"
            exit 1
        fi
    fi

    # Créer les répertoires nécessaires
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$LOGFILE")"

    log_debug "Prérequis vérifiés avec succès"
}

# Fonction pour obtenir les informations système
get_system_info() {
    local total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_ram_gb=$((total_ram_kb / 1024 / 1024))
    local cpu_cores=$(nproc)

    log_debug "RAM totale: ${total_ram_gb}GB"
    log_debug "Cœurs CPU: $cpu_cores"

    # Recommandations basées sur la RAM
    if [[ $total_ram_gb -le 4 ]]; then
        log_info "Système avec peu de RAM ($total_ram_gb GB) - zram fortement recommandé"
    elif [[ $total_ram_gb -le 8 ]]; then
        log_info "Système avec RAM modérée ($total_ram_gb GB) - zram bénéfique"
    else
        log_info "Système avec beaucoup de RAM ($total_ram_gb GB) - zram optionnel"
    fi
}

# Fonction pour créer une sauvegarde
create_backup() {
    local backup_timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/zram-config-backup-$backup_timestamp.tar.gz"

    log_info "Création d'une sauvegarde..."

    # Sauvegarder la configuration existante
    local files_to_backup=""

    if [[ -f "$ZRAM_CONFIG_FILE" ]]; then
        files_to_backup+=" $ZRAM_CONFIG_FILE"
    fi

    if [[ -f /etc/fstab ]]; then
        files_to_backup+=" /etc/fstab"
    fi

    if [[ -n "$files_to_backup" ]]; then
        if ! tar -czf "$backup_file" $files_to_backup 2>/dev/null; then
            log_warning "Impossible de créer la sauvegarde complète"
        else
            log_success "Sauvegarde créée: $backup_file"
        fi
    fi

    # Sauvegarder l'état actuel du swap
    swapon --show > "$BACKUP_DIR/swap-status-$backup_timestamp.txt" 2>/dev/null || true
}

# Fonction pour valider les paramètres
validate_parameters() {
    # Validation de la taille
    if [[ -n "$CUSTOM_SIZE" ]]; then
        if [[ ! "$CUSTOM_SIZE" =~ ^[0-9]+[GMK]?$|^[0-9]+%$|^ram/[0-9]+$ ]]; then
            log_error "Format de taille invalide: $CUSTOM_SIZE"
            log_info "Formats supportés: 2G, 50%, ram/2"
            exit 1
        fi
    fi

    # Validation de l'algorithme de compression
    if [[ -n "$CUSTOM_COMPRESSION" ]]; then
        case "$CUSTOM_COMPRESSION" in
            zstd|lzo|lz4|lzo-rle) ;;
            *)
                log_error "Algorithme de compression invalide: $CUSTOM_COMPRESSION"
                log_info "Algorithmes supportés: zstd, lzo, lz4, lzo-rle"
                exit 1
                ;;
        esac
    fi

    # Validation de la priorité
    if [[ -n "$CUSTOM_PRIORITY" ]]; then
        if [[ ! "$CUSTOM_PRIORITY" =~ ^[0-9]+$ ]] || [[ "$CUSTOM_PRIORITY" -lt 1 ]] || [[ "$CUSTOM_PRIORITY" -gt 32767 ]]; then
            log_error "Priorité invalide: $CUSTOM_PRIORITY (doit être entre 1 et 32767)"
            exit 1
        fi
    fi
}

# Fonction pour installer zram
install_zram() {
    log_info "=== INSTALLATION DE ZRAM ==="

    # Vérifier si zram est déjà installé
    if systemctl is-active --quiet "systemd-zram-setup@$DEFAULT_DEVICE.service" 2>/dev/null; then
        if [[ "$FORCE" == false ]]; then
            log_warning "zram est déjà actif. Utilisez --force pour forcer la réinstallation"
            return 0
        else
            log_info "Arrêt de zram existant..."
            systemctl stop "systemd-zram-setup@$DEFAULT_DEVICE.service" || true
        fi
    fi

    # Créer une sauvegarde
    create_backup

    # Mise à jour du système
    log_info "Mise à jour du système..."
    if ! execute_command "pacman -Sy --noconfirm" "Synchronisation des paquets"; then
        log_error "Impossible de synchroniser les paquets"
        exit 1
    fi

    # Installation des paquets nécessaires
    log_info "Installation de zram-generator..."
    if ! execute_command "pacman -S --needed --noconfirm zram-generator" "Installation de zram-generator"; then
        log_error "Impossible d'installer zram-generator"
        exit 1
    fi

    # Configuration de zram
    configure_zram

    # Activation du service
    log_info "Activation du service zram..."
    if ! execute_command "systemctl daemon-reload" "Rechargement de la configuration systemd"; then
        log_error "Impossible de recharger systemd"
        exit 1
    fi

    if ! execute_command "systemctl enable --now systemd-zram-setup@$DEFAULT_DEVICE.service" "Activation du service zram"; then
        log_error "Impossible d'activer le service zram"
        exit 1
    fi

    # Vérification
    sleep 2
    check_zram_status

    log_success "Installation de zram terminée avec succès!"
}

# Fonction pour configurer zram
configure_zram() {
    log_info "Configuration de zram..."

    local size="${CUSTOM_SIZE:-$DEFAULT_SIZE}"
    local compression="${CUSTOM_COMPRESSION:-$DEFAULT_COMPRESSION}"
    local priority="${CUSTOM_PRIORITY:-$DEFAULT_PRIORITY}"

    log_debug "Paramètres: size=$size, compression=$compression, priority=$priority"

    # Création du fichier de configuration
    local config_content="# Configuration zram générée par $SCRIPT_NAME
# Date: $(date)
# Taille: $size
# Compression: $compression
# Priorité: $priority

[$DEFAULT_DEVICE]
zram-size = $size
compression-algorithm = $compression
swap-priority = $priority
"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Configuration qui serait écrite dans $ZRAM_CONFIG_FILE:"
        echo "$config_content"
        return 0
    fi

    if echo "$config_content" > "$ZRAM_CONFIG_FILE"; then
        log_success "Configuration écrite dans $ZRAM_CONFIG_FILE"
    else
        log_error "Impossible d'écrire la configuration"
        exit 1
    fi
}

# Fonction pour supprimer zram
remove_zram() {
    log_info "=== SUPPRESSION DE ZRAM ==="

    if [[ "$FORCE" == false ]]; then
        echo -n "Êtes-vous sûr de vouloir supprimer zram? [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Suppression annulée"
            return 0
        fi
    fi

    # Créer une sauvegarde avant suppression
    create_backup

    # Arrêter le service
    log_info "Arrêt du service zram..."
    execute_command "systemctl stop systemd-zram-setup@$DEFAULT_DEVICE.service" "Arrêt du service zram" || true
    execute_command "systemctl disable systemd-zram-setup@$DEFAULT_DEVICE.service" "Désactivation du service zram" || true

    # Supprimer la configuration
    if [[ -f "$ZRAM_CONFIG_FILE" ]]; then
        execute_command "rm -f $ZRAM_CONFIG_FILE" "Suppression de la configuration zram"
    fi

    # Recharger systemd
    execute_command "systemctl daemon-reload" "Rechargement de systemd"

    # Optionnel: supprimer le paquet (demander confirmation)
    if [[ "$FORCE" == false ]]; then
        echo -n "Voulez-vous également supprimer le paquet zram-generator? [y/N]: "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            execute_command "pacman -Rs --noconfirm zram-generator" "Suppression du paquet zram-generator"
        fi
    fi

    log_success "Suppression de zram terminée"
}

# Fonction pour vérifier le statut de zram
check_zram_status() {
    log_info "=== STATUT DE ZRAM ==="

    # Vérifier le service systemd
    if systemctl is-active --quiet "systemd-zram-setup@$DEFAULT_DEVICE.service" 2>/dev/null; then
        log_success "Service zram: ACTIF"
    else
        log_warning "Service zram: INACTIF"
    fi

    # Vérifier la configuration
    if [[ -f "$ZRAM_CONFIG_FILE" ]]; then
        log_info "Configuration trouvée: $ZRAM_CONFIG_FILE"
        if [[ "$VERBOSE" == true ]]; then
            echo "--- Configuration actuelle ---"
            cat "$ZRAM_CONFIG_FILE"
            echo "--- Fin de configuration ---"
        fi
    else
        log_warning "Aucune configuration trouvée"
    fi

    # Afficher les détails zram
    if command -v zramctl &> /dev/null; then
        echo -e "\n--- Détails zram ---"
        zramctl 2>/dev/null || log_warning "Aucun périphérique zram trouvé"
    fi

    # Afficher l'état du swap
    echo -e "\n--- État du swap ---"
    swapon --show 2>/dev/null || log_info "Aucun swap actif"

    # Statistiques mémoire
    echo -e "\n--- Utilisation mémoire ---"
    free -h
}

# Fonction pour afficher des recommandations
show_recommendations() {
    log_info "=== RECOMMANDATIONS ==="

    local total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_ram_gb=$((total_ram_kb / 1024 / 1024))

    echo "Recommandations basées sur votre système ($total_ram_gb GB RAM):"
    echo

    if [[ $total_ram_gb -le 2 ]]; then
        echo "• Taille recommandée: ram/2 ou 1G"
        echo "• Compression: lz4 (plus rapide)"
        echo "• Priorité: 100 (haute)"
    elif [[ $total_ram_gb -le 4 ]]; then
        echo "• Taille recommandée: ram/2 ou 2G"
        echo "• Compression: zstd (équilibré)"
        echo "• Priorité: 100"
    elif [[ $total_ram_gb -le 8 ]]; then
        echo "• Taille recommandée: ram/4 ou 2G"
        echo "• Compression: zstd"
        echo "• Priorité: 50"
    else
        echo "• Taille recommandée: ram/4 ou 4G"
        echo "• Compression: zstd (meilleur ratio)"
        echo "• Priorité: 10 (basse)"
    fi

    echo
    echo "Commandes suggérées:"
    echo "• Installation standard: $SCRIPT_NAME install"
    echo "• Configuration optimisée: $SCRIPT_NAME --size ram/4 --compression zstd install"
    echo "• Vérification: $SCRIPT_NAME status"
}

# Gestion des arguments
parse_arguments() {
    local command=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --size)
                CUSTOM_SIZE="$2"
                shift 2
                ;;
            --compression)
                CUSTOM_COMPRESSION="$2"
                shift 2
                ;;
            --priority)
                CUSTOM_PRIORITY="$2"
                shift 2
                ;;
            --logfile)
                LOGFILE="$2"
                shift 2
                ;;
            install|remove|status|config|recommendations)
                command="$1"
                shift
                ;;
            *)
                log_error "Option inconnue: $1"
                echo "Utilisez -h pour l'aide"
                exit 1
                ;;
        esac
    done

    # Commande par défaut
    if [[ -z "$command" ]]; then
        command="install"
    fi

    echo "$command"
}

# Fonction principale
main() {
    local command
    command=$(parse_arguments "$@")

    log_info "=== GESTIONNAIRE ZRAM ==="
    log_info "Commande: $command"
    log_info "Mode: $([ "$DRY_RUN" == true ] && echo "SIMULATION" || echo "RÉEL")"

    # Vérifications préliminaires
    check_prerequisites

    # Validation des paramètres
    validate_parameters

    # Informations système
    get_system_info

    # Exécution de la commande
    case "$command" in
        install)
            install_zram
            ;;
        remove)
            remove_zram
            ;;
        status)
            check_zram_status
            ;;
        config)
            configure_zram
            systemctl restart "systemd-zram-setup@$DEFAULT_DEVICE.service"
            check_zram_status
            ;;
        recommendations)
            show_recommendations
            ;;
        *)
            log_error "Commande inconnue: $command"
            exit 1
            ;;
    esac

    log_success "Opération terminée avec succès"
}

# Gestion des signaux
trap 'log_error "Script interrompu par l'\''utilisateur"; exit 1' INT TERM

# Point d'entrée principal
main "$@"
