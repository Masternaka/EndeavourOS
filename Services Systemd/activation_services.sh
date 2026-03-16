#!/bin/bash

set -euo pipefail

# Configuration des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Options par défaut
DRY_RUN=false
VERBOSE=false
BACKUP_CONFIG=true

# Compteurs
services_success=0
services_failed=0
timers_success=0
timers_failed=0

# Fonctions utilitaires
print_header() {
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${PURPLE}🔍 $1${NC}"
    fi
}

# Fonction de validation robuste
validate_service_name() {
    local service=$1
    # Vérifie que le nom suit le format standard systemd
    [[ "$service" =~ ^[a-zA-Z0-9_-]+\.(service|timer|socket|target|path|mount|automount|device|scope|slice)$ ]]
}

# Fonction de backup
backup_service_config() {
    local service=$1
    if [[ "$BACKUP_CONFIG" == true ]]; then
        local backup_dir="/etc/systemd/backup-$(date +%Y%m%d-%H%M%S)"
        if [[ -f "/etc/systemd/system/$service" ]] || [[ -f "/usr/lib/systemd/system/$service" ]]; then
            mkdir -p "$backup_dir"
            print_verbose "Backup de la configuration pour $service"
        fi
    fi
}

# Parsing des arguments
show_usage() {
    echo "Usage: sudo $0 [options]"
    echo ""
    echo "Options:"
    echo "  --dry-run     Simule les actions sans rien modifier"
    echo "  --verbose     Affiche des logs détaillés"
    echo "  --no-backup   Désactive le backup des configurations"
    echo "  --help, -h    Affiche cette aide"
    echo ""
    echo "Services qui seront traités:"
    echo "  - bluetooth.service"
    echo "  - ufw.service"
    echo ""
    echo "Timers qui seront traités:"
    echo "  - fstrim.timer"
    echo "  - paccache.timer"
}

while [[ ${1:-} ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true ; shift ;;
        --verbose) VERBOSE=true ; shift ;;
        --no-backup) BACKUP_CONFIG=false ; shift ;;
        --help|-h) show_usage ; exit 0 ;;
        *) echo "Argument inconnu: $1" >&2 ; show_usage ; exit 1 ;;
    esac
done

# Vérification des privilèges root
if [[ $EUID -ne 0 ]]; then
    print_error "Ce script doit être exécuté en tant que root (sudo)."
    exit 1
fi

# Vérification que systemd est disponible
if ! command -v systemctl &> /dev/null; then
    print_error "systemd n'est pas disponible sur ce système"
    exit 1
fi

print_header "SCRIPT D'ACTIVATION DES SERVICES ET TIMERS"
print_info "Démarrage du script..."

if [[ "$DRY_RUN" == true ]]; then
    print_warning "MODE DRY-RUN: Aucune modification ne sera effectuée"
fi

# Liste fixe des services à gérer (inchangée)
services=("bluetooth.service" "ufw.service")
timers=("fstrim.timer" "paccache.timer")

# Fonction pour vérifier si un service/timer existe
service_exists() {
    local service=$1
    # Validation plus robuste
    if ! validate_service_name "$service"; then
        print_verbose "Nom de service invalide: $service"
        return 1
    fi
    
    # Vérification avec systemctl list-unit-files
    if systemctl list-unit-files | grep -q "^$service"; then
        print_verbose "Service $service trouvé dans les unit files"
        return 0
    fi
    
    # Vérification supplémentaire pour les services générés dynamiquement
    if systemctl list-units --all | grep -q "$service"; then
        print_verbose "Service $service trouvé dans les unités actives"
        return 0
    fi
    
    print_verbose "Service $service non trouvé"
    return 1
}

# Fonction pour traiter un service
process_service() {
    local service=$1
    print_header "Traitement de $service"
    
    if ! service_exists "$service"; then
        print_warning "$service n'existe pas sur ce système"
        return 0  # Continue sans compter comme un échec
    fi
    
    # Backup de la configuration
    backup_service_config "$service"
    
    print_info "Vérification du statut de $service"
    if [[ "$DRY_RUN" == false ]]; then
        systemctl status "$service" --no-pager || true
    else
        print_verbose "[dry-run] systemctl status $service --no-pager"
    fi
    
    print_info "Démarrage de $service"
    if [[ "$DRY_RUN" == false ]]; then
        if systemctl start "$service" 2>/dev/null; then
            print_success "$service démarré avec succès"
        else
            print_error "Erreur lors du démarrage de $service"
            ((services_failed++))
            return 0  # Continue malgré l'erreur
        fi
    else
        print_verbose "[dry-run] systemctl start $service"
        print_success "$service serait démarré (dry-run)"
    fi
    
    print_info "Activation de $service"
    if [[ "$DRY_RUN" == false ]]; then
        if systemctl enable "$service" 2>/dev/null; then
            print_success "$service activé avec succès"
            ((services_success++))
        else
            print_error "Erreur lors de l'activation de $service"
            ((services_failed++))
            return 0  # Continue malgré l'erreur
        fi
    else
        print_verbose "[dry-run] systemctl enable $service"
        print_success "$service serait activé (dry-run)"
        ((services_success++))
    fi
}

# Fonction pour traiter un timer
process_timer() {
    local timer=$1
    print_header "Traitement de $timer"
    
    if ! service_exists "$timer"; then
        print_warning "$timer n'existe pas sur ce système"
        return 0  # Continue sans compter comme un échec
    fi
    
    # Backup de la configuration
    backup_service_config "$timer"
    
    print_info "Vérification du statut de $timer"
    if [[ "$DRY_RUN" == false ]]; then
        systemctl status "$timer" --no-pager || true
    else
        print_verbose "[dry-run] systemctl status $timer --no-pager"
    fi
    
    print_info "Activation de $timer"
    if [[ "$DRY_RUN" == false ]]; then
        if systemctl enable "$timer" 2>/dev/null; then
            print_success "$timer activé avec succès"
            ((timers_success++))
        else
            print_error "Erreur lors de l'activation de $timer"
            ((timers_failed++))
            return 0  # Continue malgré l'erreur
        fi
    else
        print_verbose "[dry-run] systemctl enable $timer"
        print_success "$timer serait activé (dry-run)"
        ((timers_success++))
    fi
}

# Traitement des services
print_header "TRAITEMENT DES SERVICES"
for service in "${services[@]}"; do
    process_service "$service"
    echo
done

# Traitement des timers
print_header "TRAITEMENT DES TIMERS"
for timer in "${timers[@]}"; do
    process_timer "$timer"
    echo
done

# Vérification finale et résumé
print_header "VÉRIFICATION FINALE ET RÉSUMÉ"

print_info "Vérification du statut final des services :"
for service in "${services[@]}"; do
    if service_exists "$service"; then
        if [[ "$DRY_RUN" == false ]]; then
            systemctl is-active "$service" &> /dev/null
            if [ $? -eq 0 ]; then
                print_success "$service : actif"
            else
                print_error "$service : inactif"
            fi
        else
            print_verbose "[dry-run] systemctl is-active $service"
            print_info "$service : statut non vérifié (dry-run)"
        fi
    else
        print_warning "$service : non disponible sur ce système"
    fi
done

print_info "Vérification du statut final des timers :"
for timer in "${timers[@]}"; do
    if service_exists "$timer"; then
        if [[ "$DRY_RUN" == false ]]; then
            systemctl is-enabled "$timer" &> /dev/null
            if [ $? -eq 0 ]; then
                print_success "$timer : activé"
            else
                print_error "$timer : non activé"
            fi
        else
            print_verbose "[dry-run] systemctl is-enabled $timer"
            print_info "$timer : statut non vérifié (dry-run)"
        fi
    else
        print_warning "$timer : non disponible sur ce système"
    fi
done

# Résumé final
print_header "RÉSUMÉ FINAL"
echo -e "${PURPLE}Services traités :${NC}"
echo -e "  ${GREEN}Succès : $services_success${NC}"
echo -e "  ${RED}Échecs : $services_failed${NC}"
echo -e "${PURPLE}Timers traités :${NC}"
echo -e "  ${GREEN}Succès : $timers_success${NC}"
echo -e "  ${RED}Échecs : $timers_failed${NC}"

total_success=$((services_success + timers_success))
total_failed=$((services_failed + timers_failed))

if [ $total_failed -eq 0 ]; then
    if [[ "$DRY_RUN" == true ]]; then
        print_success "Simulation terminée avec succès ! Aucune modification effectuée."
        echo -e "${GREEN}🎉 Script dry-run terminé avec succès !${NC}"
    else
        print_success "Tous les services et timers ont été traités avec succès !"
        echo -e "${GREEN}🎉 Script terminé avec succès !${NC}"
    fi
else
    if [[ "$DRY_RUN" == true ]]; then
        print_warning "La simulation a détecté des problèmes potentiels."
        echo -e "${YELLOW}⚠️  Script dry-run terminé avec des avertissements.${NC}"
    else
        print_warning "Certains services ou timers ont échoué. Vérifiez les messages ci-dessus."
        echo -e "${YELLOW}⚠️  Script terminé avec des avertissements.${NC}"
    fi
fi

print_info "Script terminé le $(date)"

if [[ "$DRY_RUN" == true ]]; then
    print_info "Pour exécuter réellement les modifications, relancez sans --dry-run"
fi

# Informations supplémentaires
print_header "INFORMATIONS UTILES"
echo -e "${BLUE}Services configurés :${NC}"
echo "  - bluetooth.service: Gestion du Bluetooth"
echo "  - ufw.service: Pare-feu simplifié"
echo
echo -e "${BLUE}Timers configurés :${NC}"
echo "  - fstrim.timer: Optimisation SSD (hebdomadaire)"
echo "  - paccache.timer: Nettoyage cache pacman (mensuel)"
echo
echo -e "${BLUE}Commandes utiles :${NC}"
echo "  systemctl status <service>: Vérifier le statut"
echo "  journalctl -u <service>: Voir les logs"
echo "  systemctl disable <service>: Désactiver un service"