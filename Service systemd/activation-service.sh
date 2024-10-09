#!/bin/bash

# Liste des services à activer
SERVICES=(

 bluetooth
 fstrim.timer
 ufw.service
 paccache.timer

)

# Activer et démarrer les services
for SERVICE in "${SERVICES[@]}"
do
    # Vérifie si le service est déjà activé
    if systemctl is-enabled --quiet "$SERVICE"; then
        echo "Le service $SERVICE est déjà activé."
    else
        echo "Activation du service: $SERVICE"
        sudo systemctl enable "$SERVICE"
    fi

    # Vérifie si le service est déjà démarré
    if systemctl is-active --quiet "$SERVICE"; then
        echo "Le service $SERVICE est déjà en cours d'exécution."
    else
        echo "Démarrage du service: $SERVICE"
        sudo systemctl start "$SERVICE"
    fi
done

echo "Tous les services ont été vérifiés."

