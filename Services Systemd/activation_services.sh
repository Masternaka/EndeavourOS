#!/usr/bin/env bash
set -euo pipefail

###############################################################################
#
# Script permettant l'activation automatique des services systemd
#
#Services pris en charge :
#   - bluetooth
#   - fstrim.timer
#   - ufw.service
#   - paccache.timer
#
# Options :
#   -h            Affiche l'aide et quitte
#   -n, --dry-run Affiche les commandes sans les exécuter
#   -t, --timeout SECS  Définit le timeout pour --now (par défaut 90)
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: activation_services.sh
# 2. Rendez-le exécutable: chmod +x activation_services.sh
# 3. Exécutez-le: sudo ./activation_services.sh
# Le journal se trouve dans /var/log/systemd-script/ reflètera ces statuts.
#
###############################################################################


# Liste des services prédéfinis
SERVICES=(
  bluetooth
  fstrim.timer
  ufw.service
  paccache.timer
)

# Valeurs par défaut
DRY_RUN=false
TIMEOUT=90
LOGDIR="$HOME/log"
LOGFILE="$LOGDIR/activation-systemd-$(date +%Y%m%d-%H%M%S).log"
LOG_CONTENT=()
SUCCESS_COUNT=0
FAIL_COUNT=0

usage() {
  grep '^#' "$0" | sed 's/^#//' 1>&2
  exit 1
}

# Lecture des options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    -n|--dry-run) DRY_RUN=true; shift ;;
    -t|--timeout)
      if [[ -n "${2:-}" && "${2}" =~ ^[0-9]+$ ]]; then
        TIMEOUT="$2"
        shift 2
      else
        echo "Erreur : --timeout requiert un nombre de secondes" >&2
        exit 1
      fi
      ;;
    *)
      echo -e "\e[31mOption inconnue : $1\e[0m" >&2
      usage
      ;;
  esac
done

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
  echo -e "\e[31mCe script doit être exécuté en tant que root (sudo).\e[0m" >&2
  exit 1
fi

# Création du dossier de log si nécessaire
mkdir -p "$LOGDIR"

run() {
  echo -e "\e[34m+ $*\e[0m"
  LOG_CONTENT+=("+ $*")
  if ! $DRY_RUN; then
    "$@"
  fi
}

# Exécution pour chaque service
for svc in "${SERVICES[@]}"; do
  name="$svc"
  [[ "$svc" != *.service && "$svc" != *.timer ]] && name="$svc.service"

  echo -e "\e[1m==> Traitement du service : $name\e[0m"
  LOG_CONTENT+=("==> Traitement du service : $name")

  run systemctl enable --now --timeout="$TIMEOUT" "$name"
  LOG_CONTENT+=("Service $name activé et démarré.")

  # Vérifier le statut
  if systemctl is-enabled "$name" &>/dev/null; then
    echo -e "\e[32m✔ $name est bien activé\e[0m"
    LOG_CONTENT+=("✔ $name est bien activé")
  else
    echo -e "\e[31m✖ $name n'est pas activé\e[0m"
    LOG_CONTENT+=("✖ $name n'est pas activé")
    ((FAIL_COUNT++))
    continue
  fi

  if systemctl is-active "$name" &>/dev/null; then
    echo -e "\e[32m✔ $name est en cours d'exécution\e[0m"
    LOG_CONTENT+=("✔ $name est en cours d'exécution")
    ((SUCCESS_COUNT++))
  else
    echo -e "\e[31m✖ $name n'est pas en cours d'exécution\e[0m"
    LOG_CONTENT+=("✖ $name n'est pas en cours d'exécution")
    ((FAIL_COUNT++))
  fi

  echo
  LOG_CONTENT+=("")
done

# Résumé global
echo -e "\e[1mRésumé :\e[0m"
echo -e "\e[32m$SUCCESS_COUNT service(s) activé(s) et fonctionnel(s)\e[0m"
echo -e "\e[31m$FAIL_COUNT échec(s)\e[0m"
LOG_CONTENT+=("Résumé :")
LOG_CONTENT+=("$SUCCESS_COUNT service(s) activé(s) et fonctionnel(s)")
LOG_CONTENT+=("$FAIL_COUNT échec(s)")

# Écriture du journal
{
  echo "--- Journal d'exécution - $(date) ---"
  printf "%s\n" "${LOG_CONTENT[@]}"
  echo "----------------------------------------"
} >> "$LOGFILE"

echo "Opération terminée. Journal écrit dans : $LOGFILE"
