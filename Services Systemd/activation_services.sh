#!/bin/bash

LOG_DIR="$HOME/log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/activation_services.log"
: > "$LOG_FILE" # Vide le fichier log au début

if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root (sudo)." | tee -a "$LOG_FILE"
    exit 1
fi

# Liste fixe des services à gérer
services=("bluetooth.service" "fstrim.timer" "ufw.service" "paccache.timer")

for service in "${services[@]}"; do
    echo "--- Vérification du statut de $service ---" | tee -a "$LOG_FILE"
    systemctl status "$service" --no-pager | tee -a "$LOG_FILE"

    echo "--- Démarrage de $service ---" | tee -a "$LOG_FILE"
    if systemctl start "$service"; then
        echo "$service démarré avec succès." | tee -a "$LOG_FILE"
    else
        echo "Erreur lors du démarrage de $service." | tee -a "$LOG_FILE"
    fi

    echo "--- Activation de $service ---" | tee -a "$LOG_FILE"
    if systemctl enable "$service"; then
        echo "$service activé avec succès." | tee -a "$LOG_FILE"
    else
        echo "Erreur lors de l'activation de $service." | tee -a "$LOG_FILE"
    fi
done

echo -e "\n--- Vérification finale du statut des services ---" | tee -a "$LOG_FILE"
for service in "${services[@]}"; do
    systemctl is-active "$service" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "$service : actif" | tee -a "$LOG_FILE"
    else
        echo "$service : inactif ou erreur" | tee -a "$LOG_FILE"
    fi
done

echo "Log