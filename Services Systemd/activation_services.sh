#!/bin/bash
set -euo pipefail

###############################################################################
# Script de modification activation des services et timers
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: activation_services.sh
# 2. Rendez-le exécutable: chmod +x activation_services.sh
# 3. Exécutez-le: sudo ./activation_services.sh
#
# Fonctionnalités:
# - Activation automatique des services système essentiels
# - Gestion séparée des services et timers
# - Vérification de disponibilité avant traitement
# - Compteurs de succès/échecs
# - Interface colorée et claire
###############################################################################

# Configuration des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# Vérification des privilèges root
if [[ $EUID -ne 0 ]]; then
    print_error "Ce script doit être exécuté en tant que root (sudo)."
    exit 1
fi

print_header "SCRIPT D'ACTIVATION DES SERVICES ET TIMERS"
print_info "Démarrage du script..."

# Liste fixe des services à gérer
services=("bluetooth.service" "ufw.service")
timers=("fstrim.timer" "paccache.timer")

# Fonction pour vérifier si un service/timer existe
service_exists() {
    systemctl list-unit-files | grep -q "^$1"
}

# Fonction pour traiter un service
process_service() {
    local service=$1
    print_header "Traitement de $service"
    
    if ! service_exists "$service"; then
        print_warning "$service n'existe pas sur ce système"
        return 0  # Continue sans compter comme un échec
    fi
    
    print_info "Vérification du statut de $service"
    systemctl status "$service" --no-pager || true
    
    print_info "Démarrage de $service"
    if systemctl start "$service" 2>/dev/null; then
        print_success "$service démarré avec succès"
    else
        print_error "Erreur lors du démarrage de $service"
        ((services_failed++))
        return 0  # Continue malgré l'erreur
    fi
    
    print_info "Activation de $service"
    if systemctl enable "$service" 2>/dev/null; then
        print_success "$service activé avec succès"
        ((services_success++))
    else
        print_error "Erreur lors de l'activation de $service"
        ((services_failed++))
        return 0  # Continue malgré l'erreur
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
    
    print_info "Vérification du statut de $timer"
    systemctl status "$timer" --no-pager || true
    
    print_info "Activation de $timer"
    if systemctl enable "$timer" 2>/dev/null; then
        print_success "$timer activé avec succès"
        ((timers_success++))
    else
        print_error "Erreur lors de l'activation de $timer"
        ((timers_failed++))
        return 0  # Continue malgré l'erreur
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
        systemctl is-active "$service" &> /dev/null
        if [ $? -eq 0 ]; then
            print_success "$service : actif"
        else
            print_error "$service : inactif"
        fi
    fi
done

print_info "Vérification du statut final des timers :"
for timer in "${timers[@]}"; do
    if service_exists "$timer"; then
        systemctl is-enabled "$timer" &> /dev/null
        if [ $? -eq 0 ]; then
            print_success "$timer : activé"
        else
            print_error "$timer : non activé"
        fi
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
    print_success "Tous les services et timers ont été traités avec succès !"
    echo -e "${GREEN}🎉 Script terminé avec succès !${NC}"
else
    print_warning "Certains services ou timers ont échoué. Vérifiez les messages ci-dessus."
    echo -e "${YELLOW}⚠️  Script terminé avec des avertissements.${NC}"
fi

print_info "Script terminé le $(date)"