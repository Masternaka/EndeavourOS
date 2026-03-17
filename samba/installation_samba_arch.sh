#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; exit 1; }

[[ $EUID -ne 0 ]] && error "Ce script doit être exécuté en root (sudo)."

echo -e "\n${BOLD}=== Installation de Samba — Arch Linux ===${RESET}\n"

# ── 1. Installation ───────────────────────────────────────────────────────────
info "Mise à jour de la base de données pacman..."
pacman -Sy --noconfirm

info "Installation de samba..."
pacman -S --noconfirm samba

success "Samba installé."

# ── 2. Configuration smb.conf ─────────────────────────────────────────────────
# Arch n'inclut pas de smb.conf par défaut — on en crée un minimal.
SMB_CONF="/etc/samba/smb.conf"

if [[ ! -f "$SMB_CONF" ]]; then
    info "Création d'un smb.conf minimal..."
    mkdir -p /etc/samba
    cat > "$SMB_CONF" <<'EOF'
[global]
   workgroup = WORKGROUP
   server string = Samba Server
   server role = standalone server
   log file = /var/log/samba/%m.log
   max log size = 50
   dns proxy = no
   map to guest = bad user

# ── Exemple de partage (décommenter et adapter) ──────────────────────────────
# [partage]
#    path = /srv/samba/partage
#    browsable = yes
#    writable = yes
#    guest ok = no
#    valid users = @samba
EOF
    success "smb.conf créé : $SMB_CONF"
else
    warn "smb.conf déjà présent, non modifié."
fi

# ── 3. Services ───────────────────────────────────────────────────────────────
info "Activation et démarrage des services smb et nmb..."
systemctl enable --now smb.service nmb.service
success "Services smb et nmb actifs."

# ── 4. Firewall ───────────────────────────────────────────────────────────────
echo
info "Détection du firewall..."

if command -v firewall-cmd &>/dev/null; then
    info "firewalld détecté."
    systemctl enable --now firewalld
    firewall-cmd --permanent --add-service=samba
    firewall-cmd --reload
    success "Règles Samba ajoutées dans firewalld."

elif command -v ufw &>/dev/null; then
    info "ufw détecté."
    ufw allow Samba
    success "Règles Samba ajoutées dans ufw."

else
    warn "Aucun firewall reconnu (ufw / firewalld) — configuration manuelle requise."
    warn "Ports à ouvrir : TCP 139, TCP 445, UDP 137, UDP 138"
fi

# ── 5. Résumé ─────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}=== Installation terminée ===${RESET}"
echo -e "  • Fichier de config : ${CYAN}$SMB_CONF${RESET}"
echo -e "  • Ajouter un utilisateur Samba : ${CYAN}smbpasswd -a <utilisateur>${RESET}"
echo -e "  • Vérifier la config : ${CYAN}testparm${RESET}"
echo -e "  • Statut des services : ${CYAN}systemctl status smb nmb${RESET}"
echo