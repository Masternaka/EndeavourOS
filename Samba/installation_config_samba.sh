#!/bin/bash

# Mise à jour du système
sudo pacman -Syu --noconfirm

# Installation de Samba
sudo pacman -S samba --noconfirm

# Sauvegarde du fichier de configuration existant
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Écriture de la section globale dans le fichier de configuration Samba
sudo bash -c 'cat > /etc/samba/smb.conf' << EOF
[global]
   workgroup = WORKGROUP
   server string = Samba Server
   netbios name = ArchLinux
   security = user
   map to guest = Bad User
   dns proxy = no
EOF

# Demande à l'utilisateur d'ajouter plusieurs répertoires
while true; do
    echo "Entrez le chemin complet du répertoire que vous souhaitez partager : "
    read share_dir

    # Vérification que le répertoire existe
    if [ -d "$share_dir" ]; then
        echo "Entrez le nom de partage pour ce répertoire (ce nom sera visible sur le réseau) : "
        read share_name

        # Ajout de la configuration de partage pour ce répertoire
        sudo bash -c "cat >> /etc/samba/smb.conf" << EOF

[$share_name]
   path = $share_dir
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
EOF
        echo "Le répertoire $share_dir a été configuré sous le nom de partage $share_name."

        # Demande si l'utilisateur souhaite ajouter un autre répertoire
        echo "Voulez-vous ajouter un autre répertoire à partager ? (y/n) : "
        read add_another
        if [ "$add_another" != "y" ]; then
            break
        fi
    else
        echo "Le répertoire $share_dir n'existe pas. Veuillez entrer un chemin valide."
    fi
done

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
echo "Samba a été installé et configuré avec succès. Vous avez partagé les répertoires spécifiés."
