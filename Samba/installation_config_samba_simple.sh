#!/bin/bash

# Mise à jour du système
sudo pacman -Syu --noconfirm

# Installation de Samba
sudo pacman -S samba --noconfirm

# Création d'un répertoire de partage
SHARE_DIR="/srv/samba/share"
sudo mkdir -p "$SHARE_DIR"

# Attribution des droits d'accès
sudo chmod 2770 "$SHARE_DIR"
sudo chown nobody:users "$SHARE_DIR"

# Sauvegarde du fichier de configuration existant
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Écriture du nouveau fichier de configuration
sudo bash -c 'cat > /etc/samba/smb.conf' << EOF
[global]
   workgroup = WORKGROUP
   server string = Samba Server
   netbios name = ArchLinux
   security = user
   map to guest = Bad User
   dns proxy = no

[Share]
   path = $SHARE_DIR
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
EOF

# Création d'un utilisateur Samba
echo "Entrez le nom d'utilisateur Samba : "
read samba_user

# Création de l'utilisateur si nécessaire et ajout à Samba
if id "$samba_user" &>/dev/null; then
    echo "L'utilisateur $samba_user existe déjà."
else
    sudo useradd -M -s /sbin/nologin "$samba_user"
fi

sudo smbpasswd -a "$samba_user"

# Démarrage et activation de Samba
sudo systemctl start smb.service nmb.service
sudo systemctl enable smb.service nmb.service

# Test de la configuration Samba
testparm

# Affichage d'informations finales
echo "Samba a été installé et configuré. Le dossier de partage est $SHARE_DIR."
