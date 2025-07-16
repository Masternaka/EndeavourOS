#!/bin/bash

###############################################################################
# Script permettant l'activation automatique des services systemd
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: activation_services.sh
# 2. Rendez-le exécutable: chmod +x activation_services.sh
# 3. Exécutez-le: sudo ./activation_services.sh
###############################################################################

# Liste des services à activer
SERVICES=(
    bluetooth
    fstrim.timer
    ufw.service
    paccache.timer
)

# Fonction pour vérifier si un service existe
service_exists() {
    systemctl list-unit-files --type=service | grep -q "$1"
}

# Activer et démarrer les services
for SERVICE in "${SERVICES[@]}"
do
    # Vérifier si le service existe
    if ! service_exists "$SERVICE"; then
        echo "Le service $SERVICE n'existe pas sur ce système. Ignoré."
        continue
    fi

    # Activation du service si nécessaire
    if ! systemctl is-enabled --quiet "$SERVICE"; then
        echo "Activation du service: $SERVICE"
        sudo systemctl enable "$SERVICE"
    else
        echo "Le service $SERVICE est déjà activé."
    fi

    # Démarrage du service si nécessaire
    if ! systemctl is-active --quiet "$SERVICE"; then
        echo "Démarrage du service: $SERVICE"
        sudo systemctl start "$SERVICE"
    else
        echo "Le service $SERVICE est déjà en cours d'exécution."
    fi
done

echo "Tous les services ont été vérifiés."
