#!/bin/bash

###############################################################################
#
# Script permettant l'ajout de alias dans le fichier de configuration du shell
#
# Options :
#   -n, --dry-run Affiche les commandes sans les exécuter
#   -h, --help Affiche cette aide
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: ajout_alias.sh
# 2. Rendez-le exécutable: chmod +x ajout_alias.sh
# 3. Exécutez-le: ./ajout_alias.sh
# Le journal se trouve dans ~/log/ajout_alias.log
#
###############################################################################

ALIAS_FILE="$HOME/mes_alias_bashzsh.sh"
START_MARKER="# >>> ALIAS START <<<"
END_MARKER="# <<< ALIAS END <<<"
DRY_RUN=false
LOG_DIR="$HOME/log"
LOG_FILE="$LOG_DIR/ajout_alias.log"

# Fonction d'affichage d'aide
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -n, --dry-run    Affiche les commandes sans les exécuter"
    echo "  -h, --help       Affiche cette aide"
}

# Fonction de logging
log_message() {
    local message="$1"
    # Créer le dossier log s'il n'existe pas
    mkdir -p "$LOG_DIR"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
}

# Fonction de gestion d'erreur
error_exit() {
    local message="$1"
    echo "❌ Erreur: $message" >&2
    log_message "ERREUR: $message"
    exit 1
}

# Parsing des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Vérification de l'existence du fichier d'alias
if [[ ! -f "$ALIAS_FILE" ]]; then
    error_exit "Le fichier d'alias '$ALIAS_FILE' n'existe pas. Veuillez le créer d'abord."
fi

# Détection préférentielle bashrc > zshrc
if [[ -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
elif [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
else
    error_exit "Aucun fichier .bashrc ou .zshrc trouvé."
fi

ALIAS_BLOCK="$START_MARKER
# Chargé automatiquement depuis $ALIAS_FILE
if [ -f \"$ALIAS_FILE\" ]; then
    source \"$ALIAS_FILE\"
fi
$END_MARKER"

if $DRY_RUN; then
    echo "--- DRY RUN ---"
    echo "Fichier ciblé : $SHELL_RC"
    echo "Fichier d'alias : $ALIAS_FILE"
    echo "Bloc qui serait inséré :"
    echo "$ALIAS_BLOCK"
    echo "(aucune modification écrite)"
    exit 0
fi

# Sauvegarde
if ! cp "$SHELL_RC" "$SHELL_RC.bak"; then
    error_exit "Impossible de créer la sauvegarde de $SHELL_RC"
fi

# Supprime section existante
if ! sed -i "/$START_MARKER/,/$END_MARKER/d" "$SHELL_RC"; then
    error_exit "Impossible de supprimer la section existante dans $SHELL_RC"
fi

# Insertion en tête
if ! { echo "$ALIAS_BLOCK"; echo; cat "$SHELL_RC"; } > "$SHELL_RC.tmp" || ! mv "$SHELL_RC.tmp" "$SHELL_RC"; then
    error_exit "Impossible d'insérer le bloc d'alias dans $SHELL_RC"
fi

# Messages de succès
echo "✅ Aliases ajoutés à $SHELL_RC"
echo "📁 Fichier d'alias source : $ALIAS_FILE"
echo "🔁 Pour appliquer les changements, rechargez votre shell avec:"
echo "   source $SHELL_RC"
echo "   ou redémarrez votre terminal"

# Logging
log_message "Aliases insérés dans $SHELL_RC par $USER (fichier source: $ALIAS_FILE)"
echo "📝 Événement enregistré dans $LOG_FILE"
