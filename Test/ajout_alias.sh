#!/bin/bash

###############################################################################
#
# Script permettant l'ajout de alias dans le fichier de configuration du shell
#
# Options :
#   -n, --dry-run Affiche les commandes sans les exécuter
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: ajout_alias.sh
# 2. Rendez-le exécutable: chmod +x ajout_alias.sh
# 3. Exécutez-le: sudo ./ajout_alias.sh
# Le journal se trouve dans /var/log/ajout_alias/ reflètera ces statuts.
#
###############################################################################

ALIAS_FILE="$HOME/mes_alias_bashzsh.sh"
START_MARKER="# >>> ALIAS START <<<"
END_MARKER="# <<< ALIAS END <<<"
DRY_RUN=false
LOG_FILE="/var/log/ajout_alias.log"

# Option --dry-run
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
    esac
done

# Détection préférentielle bashrc > zshrc
if [[ -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
elif [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
else
    echo "❌ Aucun fichier .bashrc ou .zshrc trouvé."
    exit 1
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
    echo "Bloc inséré :"
    echo "$ALIAS_BLOCK"
    echo "(aucune modification écrite)"
    exit 0
fi

# Sauvegarde
cp "$SHELL_RC" "$SHELL_RC.bak"

# Supprime section existante
sed -i "/$START_MARKER/,/$END_MARKER/d" "$SHELL_RC"

# Insertion en tête
{ echo "$ALIAS_BLOCK"; echo; cat "$SHELL_RC"; } > "$SHELL_RC.tmp" && mv "$SHELL_RC.tmp" "$SHELL_RC"

# Rechargement
echo "✅ Aliases ajoutés à $SHELL_RC"
echo "🔁 Rechargement en cours..."
source "$SHELL_RC"

# Logging (requiert droits root pour écriture)
if [ -w "$LOG_FILE" ] || sudo touch "$LOG_FILE" &>/dev/null; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Aliases insérés dans $SHELL_RC par $USER" | sudo tee -a "$LOG_FILE" > /dev/null
else
    echo "⚠️ Impossible d'écrire dans $LOG_FILE. Droits root requis."
fi
