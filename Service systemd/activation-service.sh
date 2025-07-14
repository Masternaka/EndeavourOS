#!/bin/bash
set -euo pipefail

###############################################################################
# Script d'activation et de démarrage de services systemd
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: activation-service.sh
# 2. Rendez-le exécutable: chmod +x activation-service.sh
# 3. Exécutez-le: ./activation-service.sh [options]
#
# Options:
#   -h, --help      Affiche l'aide
#   -d, --dry-run   Mode simulation (aucune action réelle)
#   -v, --verbose   Mode verbeux
#   -l, --log FILE  Fichier de log
#   -c, --config FILE  Fichier de configuration personnalisé
#
# ***Exécution normale***
# ./activation-service.sh

# ***Mode simulation***
# ./activation-service.sh --dry-run

# ***Avec logging et mode verbeux***
# ./activation-service.sh -v -l /tmp/services.log

# ***Configuration personnalisée***
# ./activation-service.sh -c my_services.conf
###############################################################################

# Configuration par défaut
SCRIPT_NAME=$(basename "$0")
DEFAULT_CONFIG_FILE="$HOME/.config/service-manager/services.conf"
LOGFILE=""
DRY_RUN=false
VERBOSE=false
CONFIG_FILE=""

# Couleurs pour le logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Script d'activation et de démarrage de services systemd.

OPTIONS:
    -h, --help          Affiche cette aide
    -d, --dry-run       Mode simulation (aucune action réelle)
    -v, --verbose       Mode verbeux
    -l, --log FILE      Spécifie un fichier de log
    -c, --config FILE   Utilise un fichier de configuration personnalisé

EXEMPLES:
    $SCRIPT_NAME                    # Exécution normale
    $SCRIPT_NAME -d                 # Mode simulation
    $SCRIPT_NAME -v -l /tmp/services.log  # Mode verbeux avec log
    $SCRIPT_NAME -c my_services.conf      # Configuration personnalisée

FICHIER DE CONFIGURATION:
    Le fichier de configuration peut contenir :
    - Des noms de services (un par ligne)
    - Des commentaires (lignes commençant par #)
    - Des sections [enable], [start], [restart]

    Exemple:
        # Services essentiels
        bluetooth.service
        ufw.service

        [timers]
        fstrim.timer
        paccache.timer
EOF
}

# Gestion des arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -l|--log)
                LOGFILE="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            *)
                echo "Option inconnue: $1" >&2
                echo "Utilisez -h pour l'aide" >&2
                exit 1
                ;;
        esac
    done
}

# Fonction de logging améliorée
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

    local formatted_message="[$timestamp] [$level] $message"

    # Affichage console avec couleur
    echo -e "${color}[$level]${NC} $message"

    # Écriture dans le fichier de log (sans couleur)
    if [[ -n "$LOGFILE" ]]; then
        echo "$formatted_message" >> "$LOGFILE"
    fi
}

log_info() { log_message "INFO" "$1"; }
log_warning() { log_message "WARNING" "$1"; }
log_error() { log_message "ERROR" "$1"; }
log_debug() { [[ "$VERBOSE" == true ]] && log_message "DEBUG" "$1"; }
log_success() { log_message "SUCCESS" "$1"; }

# Vérifications préliminaires
check_prerequisites() {
    log_debug "Vérification des prérequis..."

    # Vérification de systemctl
    if ! command -v systemctl > /dev/null 2>&1; then
        log_error "systemctl n'est pas disponible. Ce script nécessite systemd."
        exit 1
    fi

    # Vérification des permissions
    if [[ "$EUID" -eq 0 ]]; then
        log_warning "Exécution en tant que root détectée"
    else
        log_debug "Exécution en tant qu'utilisateur normal (sudo sera utilisé si nécessaire)"
    fi

    # Création du répertoire de log si nécessaire
    if [[ -n "$LOGFILE" ]]; then
        local log_dir=$(dirname "$LOGFILE")
        if [[ ! -d "$log_dir" ]]; then
            mkdir -p "$log_dir"
            log_debug "Répertoire de log créé : $log_dir"
        fi
    fi
}

# Chargement de la configuration
load_configuration() {
    local config_file="$CONFIG_FILE"

    # Utilisation du fichier par défaut si aucun spécifié
    if [[ -z "$config_file" ]]; then
        config_file="$DEFAULT_CONFIG_FILE"
    fi

    # Services par défaut si aucun fichier de configuration
    if [[ ! -f "$config_file" ]]; then
        log_info "Aucun fichier de configuration trouvé, utilisation des services par défaut"
        SERVICES=(
            "bluetooth.service"
            "ufw.service"
            "fstrim.timer"
            "paccache.timer"
        )
        return 0
    fi

    log_info "Chargement de la configuration depuis : $config_file"

    # Lecture du fichier de configuration
    SERVICES=()
    local current_section="default"

    while IFS= read -r line; do
        # Ignorer les lignes vides et les commentaires
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Détecter les sections
        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            current_section="${BASH_REMATCH[1]}"
            continue
        fi

        # Ajouter les services
        SERVICES+=("$line")

    done < "$config_file"

    log_debug "Configuration chargée : ${#SERVICES[@]} service(s)"
}

# Fonction pour vérifier si un service existe
service_exists() {
    local service="$1"
    systemctl list-unit-files --type=service,timer --no-pager | grep -qE "^${service}(\.service|\.timer)?\s"
}

# Fonction pour obtenir le statut d'un service
get_service_status() {
    local service="$1"
    local enabled_status=""
    local active_status=""

    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        enabled_status="enabled"
    else
        enabled_status="disabled"
    fi

    if systemctl is-active --quiet "$service" 2>/dev/null; then
        active_status="active"
    else
        active_status="inactive"
    fi

    echo "$enabled_status,$active_status"
}

# Fonction pour exécuter une commande avec gestion du dry-run
execute_command() {
    local cmd="$1"
    local description="$2"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] $description"
        log_debug "[DRY-RUN] Commande qui serait exécutée : $cmd"
        return 0
    fi

    log_debug "Exécution : $cmd"

    if eval "$cmd" &>/dev/null; then
        log_success "$description"
        return 0
    else
        log_error "Échec : $description"
        return 1
    fi
}

# Fonction principale de gestion des services
manage_service() {
    local service="$1"
    local sudo_cmd=""
    local failed=0

    # Déterminer si sudo est nécessaire
    if [[ "$EUID" -ne 0 ]]; then
        sudo_cmd="sudo"
    fi

    log_info "Traitement du service : $service"

    # Vérifier l'existence du service
    if ! service_exists "$service"; then
        log_warning "Le service '$service' n'existe pas sur ce système. Ignoré."
        return 0
    fi

    # Obtenir le statut actuel
    local status=$(get_service_status "$service")
    local enabled_status=$(echo "$status" | cut -d',' -f1)
    local active_status=$(echo "$status" | cut -d',' -f2)

    log_debug "Statut actuel : enabled=$enabled_status, active=$active_status"

    # Activation du service si nécessaire
    if [[ "$enabled_status" != "enabled" ]]; then
        if ! execute_command "$sudo_cmd systemctl enable '$service'" "Activation du service '$service'"; then
            failed=1
        fi
    else
        log_info "Le service '$service' est déjà activé"
    fi

    # Démarrage du service si nécessaire
    if [[ "$active_status" != "active" ]]; then
        if ! execute_command "$sudo_cmd systemctl start '$service'" "Démarrage du service '$service'"; then
            failed=1
        fi
    else
        log_info "Le service '$service' est déjà en cours d'exécution"
    fi

    return $failed
}

# Fonction pour créer un fichier de configuration par défaut
create_default_config() {
    local config_dir=$(dirname "$DEFAULT_CONFIG_FILE")

    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
    fi

    cat > "$DEFAULT_CONFIG_FILE" << 'EOF'
# Configuration des services système
# Lignes commençant par # sont des commentaires
# Un service par ligne

# Services réseau et sécurité
bluetooth.service
ufw.service

# Services de maintenance
fstrim.timer
paccache.timer

# Services optionnels (décommentez si nécessaire)
# firewalld.service
# docker.service
# sshd.service
EOF

    log_info "Fichier de configuration par défaut créé : $DEFAULT_CONFIG_FILE"
}

# Fonction pour générer un rapport
generate_report() {
    log_info "=== RAPPORT DE TRAITEMENT ==="

    local total_services=${#SERVICES[@]}
    local processed=0
    local failed=0

    for service in "${SERVICES[@]}"; do
        if service_exists "$service"; then
            processed=$((processed + 1))
            local status=$(get_service_status "$service")
            local enabled_status=$(echo "$status" | cut -d',' -f1)
            local active_status=$(echo "$status" | cut -d',' -f2)

            local status_icon="✅"
            if [[ "$enabled_status" != "enabled" || "$active_status" != "active" ]]; then
                status_icon="⚠️"
                failed=$((failed + 1))
            fi

            log_info "$status_icon $service : $enabled_status / $active_status"
        else
            log_warning "❌ $service : service inexistant"
        fi
    done

    log_info "=== RÉSUMÉ ==="
    log_info "Services total : $total_services"
    log_info "Services traités : $processed"
    log_info "Services en échec : $failed"

    if [[ "$failed" -eq 0 ]]; then
        log_success "Tous les services ont été traités avec succès !"
    else
        log_warning "Certains services nécessitent une attention particulière"
    fi
}

# Fonction principale
main() {
    log_info "=== DÉMARRAGE DU SCRIPT D'ACTIVATION DE SERVICES ==="
    log_info "Mode: $([ "$DRY_RUN" == true ] && echo "SIMULATION" || echo "RÉEL")"

    # Vérifications préliminaires
    check_prerequisites

    # Chargement de la configuration
    load_configuration

    # Création du fichier de configuration par défaut si nécessaire
    if [[ ! -f "$DEFAULT_CONFIG_FILE" && -z "$CONFIG_FILE" ]]; then
        create_default_config
    fi

    # Traitement des services
    local total_failed=0
    for service in "${SERVICES[@]}"; do
        if ! manage_service "$service"; then
            total_failed=$((total_failed + 1))
        fi
    done

    # Génération du rapport
    generate_report

    # Code de sortie
    if [[ "$total_failed" -eq 0 ]]; then
        log_success "Script terminé avec succès"
        exit 0
    else
        log_error "Script terminé avec des erreurs ($total_failed service(s) en échec)"
        exit 1
    fi
}

# Gestion des signaux
trap 'log_error "Script interrompu par l'\''utilisateur"; exit 1' INT TERM

# Point d'entrée principal
parse_arguments "$@"
main
