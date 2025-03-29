#!/bin/bash
set -euo pipefail

###############################################################################
# Script d'activation et de démarrage de services
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: activation-service_final.sh.
# 2. Rendez-le exécutable: chmod +x activation-service_final.sh.
# 3. Exécutez-le: sudo ./activation-service_final.sh
###############################################################################

# Vérification de la présence de systemctl
if ! command -v systemctl > /dev/null 2>&1; then
    echo "Erreur : systemctl n'est pas disponible. Ce script nécessite systemd." >&2
    exit 1
fi

# Définir sudo si nécessaire (si on n'est pas root)
SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

# Liste des services à activer (ajustez cette liste selon vos besoins)
SERVICES=(
    bluetooth.service
    fstrim.service
    fstrim.timer
    paccache.service
    paccache.timer
    ufw.service
    #firewalld
)

# Mise en cache de la liste des services disponibles
AVAILABLE_SERVICES=$(systemctl list-unit-files --type=service --no-pager)

# Fonctions de log avec coloration pour une meilleure lisibilité
log_info() {
    echo -e "\e[32m[INFO]\e[0m $1"
}

log_warning() {
    echo -e "\e[33m[ATTENTION]\e[0m $1"
}

log_error() {
    echo -e "\e[31m[ERREUR]\e[0m $1" >&2
}

# Fonction pour vérifier si un service existe parmi les unités disponibles.
# On vérifie si la ligne correspondante commence par le nom du service éventuellement
# suivi de '.service' et d'un espace.
service_exists() {
    grep -qE "^${1}(\.service)?\s" <<< "$AVAILABLE_SERVICES"
}

# Fonction pour activer (enable) et démarrer (start) un service
manage_service() {
    local service="$1"

    if ! service_exists "$service"; then
        log_warning "Le service '$service' n'existe pas sur ce système. Ignoré."
        return 0
    fi

    # Activation du service si nécessaire (enable)
    if ! systemctl is-enabled --quiet "$service"; then
        log_info "Activation du service : $service"
        $SUDO systemctl enable "$service"
    else
        log_info "Le service '$service' est déjà activé."
    fi

    # Démarrage du service si nécessaire (start)
    if ! systemctl is-active --quiet "$service"; then
        log_info "Démarrage du service : $service"
        $SUDO systemctl start "$service"
    else
        log_info "Le service '$service' est déjà en cours d'exécution."
    fi
}

# Parcours de la liste des services et gestion de chacun d'eux
for service in "${SERVICES[@]}"; do
    manage_service "$service"
done

log_info "Tous les services ont été vérifiés."
