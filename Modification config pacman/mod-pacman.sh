#!/bin/bash
set -e

###############################################################################
# Script de modification du nombre de téléchargements parallèles dans pacman.conf
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: mod-pacman.sh.
# 2. Rendez-le exécutable: chmod +x mod-pacman.sh.
# 3. Exécutez-le: sudo ./mod-pacman.sh.
###############################################################################

# Vérifier les permissions
if [[ $EUID -ne 0 ]]; then
    echo "Veuillez exécuter ce script en tant qu'administrateur (sudo)."
    exit 1
fi

# Demander à l'utilisateur d'entrer une valeur
read -p "Entrez le nombre de téléchargements parallèles (entre 1 et 20) : " PARALLEL_DOWNLOADS

# Validation de la saisie
if ! [[ "$PARALLEL_DOWNLOADS" =~ ^[0-9]+$ ]]; then
    echo "Erreur : La valeur doit être un entier positif."
    exit 1
fi

if ((PARALLEL_DOWNLOADS < 1 || PARALLEL_DOWNLOADS > 20)); then
    echo "Erreur : Veuillez entrer un nombre entre 1 et 20."
    exit 1
fi

# Sauvegarde du fichier original
BACKUP_FILE="/etc/pacman.conf.bak"
if [ ! -f "$BACKUP_FILE" ]; then
    sudo cp /etc/pacman.conf "$BACKUP_FILE"
    echo "Sauvegarde effectuée : $BACKUP_FILE"
fi

# Modification de la configuration
sudo sed -i "s/^#*ParallelDownloads = .*/ParallelDownloads = ${PARALLEL_DOWNLOADS}/" /etc/pacman.conf
echo "ParallelDownloads mis à jour à ${PARALLEL_DOWNLOADS} dans /etc/pacman.conf"

# Journalisation
LOG_FILE="$HOME/parallel_downloads.log"
echo "$(date): ParallelDownloads défini à ${PARALLEL_DOWNLOADS}" >> "$LOG_FILE"
echo "Modifications enregistrées dans $LOG_FILE"
