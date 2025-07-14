#!/bin/bash
set -euo pipefail

###############################################################################
# Script de modification du nombre de téléchargements parallèles dans pacman.conf
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: mod-pacman.sh
# 2. Rendez-le exécutable: chmod +x mod-pacman.sh
# 3. Exécutez-le: sudo ./mod-pacman.sh
# 4. Pour restaurer: sudo ./mod-pacman.sh --restore
###############################################################################

PACMAN_CONF="/etc/pacman.conf"
BACKUP_FILE="/etc/pacman.conf.bak"
LOG_FILE="/var/log/pacman_parallel_downloads.log"

# Fonction d'affichage d'aide
show_help() {
    echo "Usage: $0 [--restore] [--help]"
    echo "  --restore : Restaure la configuration originale"
    echo "  --help    : Affiche cette aide"
}

# Fonction de journalisation
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

# Fonction de restauration
restore_config() {
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Erreur : Aucune sauvegarde trouvée ($BACKUP_FILE)"
        exit 1
    fi

    cp "$BACKUP_FILE" "$PACMAN_CONF"
    log_message "Configuration restaurée depuis $BACKUP_FILE"
    echo "Configuration restaurée avec succès."
}

# Fonction pour obtenir la valeur actuelle
get_current_value() {
    if grep -q "^ParallelDownloads" "$PACMAN_CONF"; then
        grep "^ParallelDownloads" "$PACMAN_CONF" | sed 's/.*= *//'
    elif grep -q "^#ParallelDownloads" "$PACMAN_CONF"; then
        echo "désactivé (commenté)"
    else
        echo "non configuré"
    fi
}

# Traitement des arguments
case "${1:-}" in
    --restore)
        if [[ $EUID -ne 0 ]]; then
            echo "Erreur : Veuillez exécuter ce script en tant qu'administrateur (sudo)."
            exit 1
        fi
        restore_config
        exit 0
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
    -*)
        echo "Erreur : Option inconnue $1"
        show_help
        exit 1
        ;;
esac

# Vérifier les permissions
if [[ $EUID -ne 0 ]]; then
    echo "Erreur : Veuillez exécuter ce script en tant qu'administrateur (sudo)."
    exit 1
fi

# Vérifier l'existence du fichier de configuration
if [ ! -f "$PACMAN_CONF" ]; then
    echo "Erreur : Le fichier $PACMAN_CONF n'existe pas."
    exit 1
fi

# Afficher la valeur actuelle
current_value=$(get_current_value)
echo "Valeur actuelle de ParallelDownloads : $current_value"

# Demander à l'utilisateur d'entrer une valeur
read -p "Entrez le nombre de téléchargements parallèles (entre 1 et 20, ou 0 pour désactiver) : " PARALLEL_DOWNLOADS

# Validation de la saisie
if ! [[ "$PARALLEL_DOWNLOADS" =~ ^[0-9]+$ ]]; then
    echo "Erreur : La valeur doit être un entier positif."
    exit 1
fi

if ((PARALLEL_DOWNLOADS < 0 || PARALLEL_DOWNLOADS > 20)); then
    echo "Erreur : Veuillez entrer un nombre entre 0 et 20."
    exit 1
fi

# Sauvegarde du fichier original (une seule fois)
if [ ! -f "$BACKUP_FILE" ]; then
    cp "$PACMAN_CONF" "$BACKUP_FILE"
    log_message "Sauvegarde effectuée : $BACKUP_FILE"
fi

# Modification de la configuration
if ((PARALLEL_DOWNLOADS == 0)); then
    # Désactiver en commentant la ligne
    sed -i 's/^ParallelDownloads/#ParallelDownloads/' "$PACMAN_CONF"
    log_message "ParallelDownloads désactivé (commenté)"
    echo "ParallelDownloads désactivé dans $PACMAN_CONF"
else
    # Activer avec la valeur spécifiée
    if grep -q "^#*ParallelDownloads" "$PACMAN_CONF"; then
        sed -i "s/^#*ParallelDownloads = .*/ParallelDownloads = ${PARALLEL_DOWNLOADS}/" "$PACMAN_CONF"
    else
        # Ajouter la ligne si elle n'existe pas
        echo "ParallelDownloads = ${PARALLEL_DOWNLOADS}" >> "$PACMAN_CONF"
    fi
    log_message "ParallelDownloads défini à ${PARALLEL_DOWNLOADS}"
    echo "ParallelDownloads mis à jour à ${PARALLEL_DOWNLOADS} dans $PACMAN_CONF"
fi

# Vérifier que la modification a fonctionné
new_value=$(get_current_value)
echo "Nouvelle valeur : $new_value"

echo "Modifications enregistrées dans $LOG_FILE"
echo "Pour restaurer la configuration originale, utilisez : sudo $0 --restore"
