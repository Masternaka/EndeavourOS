#!/bin/bash

###############################################################################
# Script pour l'installation et la configuration de zram
#
# Utilisation:
# 1. Sauvegardez ce script sous un nom, par exemple: installation_configuration_zram.sh
# 2. Rendez-le exécutable: chmod +x installation_configuration_zram.sh
# 3. Exécutez-le: sudo ./installation_configuration_zram.sh
###############################################################################


# Vérifie si l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root"
   exit 1
fi

# Met à jour le système
pacman -Syyu --noconfirm

# Installe les outils nécessaires
pacman -S --noconfirm zram-generator

# Crée le fichier de configuration pour zram
cat > /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF

# Recharge la configuration systemd
systemctl daemon-reload

# Démarre et active le service zram
systemctl enable --now systemd-zram-setup@zram0.service
# systemctl enable --now zram-generator.service

# Vérifie le statut
echo "Vérification du statut de zram :"
zramctl

echo "Configuration de zram terminée !"
echo "Vous pouvez vérifier l'utilisation avec : swapon ou zramctl ou systemctl status systemd-zram-setup@zram0.service"
