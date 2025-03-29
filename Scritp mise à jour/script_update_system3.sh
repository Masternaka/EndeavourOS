#!/bin/bash

LOGFILE="$HOME/update_log_$(date +%Y-%m-%d).txt"

echo "Début des mises à jour : $(date)" > "$LOGFILE"

echo -e "\n=== Mise à jour des paquets Pacman ===" | tee -a "$LOGFILE"
if sudo pacman -Syu >> "$LOGFILE" 2>&1; then
    echo "Pacman terminé avec succès." | tee -a "$LOGFILE"
else
    echo "Erreur lors de la mise à jour Pacman." | tee -a "$LOGFILE"
    exit 1  # Arrête le script ici si Pacman échoue
fi

echo -e "\n=== Mise à jour des paquets AUR ===" | tee -a "$LOGFILE"
if yay -Syu >> "$LOGFILE" 2>&1; then
    echo "AUR terminé avec succès." | tee -a "$LOGFILE"
else
    echo "Erreur lors de la mise à jour AUR." | tee -a "$LOGFILE"
    exit 1  # Arrête le script ici si AUR échoue
fi

echo -e "\n=== Mise à jour des paquets Flatpak ===" | tee -a "$LOGFILE"
if flatpak update >> "$LOGFILE" 2>&1; then
    echo "Flatpak terminé avec succès." | tee -a "$LOGFILE"
else
    echo "Erreur lors de la mise à jour Flatpak." | tee -a "$LOGFILE"
    exit 1  # Arrête le script ici si Flatpak échoue
fi

echo -e "\nMises à jour terminées : $(date)" | tee -a "$LOGFILE"
