#!/bin/bash

# Mise à jour du système et installation de Samba
sudo pacman -Syu
sudo pacman -S samba

# Création du fichier de configuration de Samba
sudo cp /etc/samba/smb.conf.default /etc/samba/smb.conf

# Répertoires à partager
directories=("/mnt/disque1/partage1" "/mnt/disque2/partage2")

# Configuration des répertoires partagés dans smb.conf
for dir in "${directories[@]}"; do
    echo "
[$(basename $dir)]
   path = $dir
   browseable = yes
   writable = yes
   guest ok = yes
" | sudo tee -a /etc/samba/smb.conf
done

# Démarrage et activation du service Samba
sudo systemctl start smb
sudo systemctl enable smb

echo "Samba a été installé et configuré avec succès."





# Dans cet exemple, les répertoires /mnt/disque1/partage1 et /mnt/disque2/partage2 sont partagés. Vous pouvez remplacer ces chemins par ceux de vos propres répertoires.

# N’oubliez pas de rendre ce script exécutable avec chmod +x nom_du_script.sh avant de l’exécuter.
