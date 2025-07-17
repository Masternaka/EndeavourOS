#!/bin/bash

LOG_FILE="activation_services.log"
: > "$LOG_FILE" # Vide le fichier log au début

if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root (sudo)." | tee -a "$LOG_FILE"
    exit 1
fi

# Liste fixe des services à gérer
services=("bluetooth" "fstrim.timer" "ufw.service" "paccache.timer")

for service in "${services[@]}"; do
    if systemctl enable --now "$service"; then
        echo "Le service $service a été activé avec succès." | tee -a "$LOG_FILE"
    else
        echo "Erreur lors de l'activation du service $service :" | tee -a "$LOG_FILE"
        systemctl status "$service" --no-pager | tee -a "$LOG_FILE"
    fi
done

echo -e "\n--- Vérification du statut des services ---" | tee -a "$LOG_FILE"
for service in "${services[@]}"; do
    systemctl is-active "$service" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "$service : actif" | tee -a "$LOG_FILE"
    else
        echo "$service : inactif ou erreur" | tee -a "$LOG_FILE"
    fi
done

echo "Log généré dans $LOG_FILE"
