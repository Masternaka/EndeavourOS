#!/bin/bash

# Vérification si le script est exécuté en tant que root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root. Utilisez sudo."
    exit 1
fi

# Mise à jour du système
echo "Mise à jour du système..."
pacman -Syu --noconfirm

# Installer zram-generator et les dépendances nécessaires
echo "Installation de zram-generator..."
pacman -S --noconfirm zram-generator

# Créer le répertoire de configuration de zram
echo "Création du répertoire de configuration de zram..."
mkdir -p /etc/systemd/zram-generator.conf.d/

# Créer un fichier de configuration pour ZRAM
cat <<EOF > /etc/systemd/zram-generator.conf.d/00-zram.conf
# Configuration pour zram-generator

[zram0]
# Définir la taille de ZRAM à 50% de la RAM totale
size = 50%

# Utilisation de l'algorithme de compression lz4 pour de bonnes performances ou zstd pour un meilleur ratio de compression
compression_algorithm = lz4

# Définir la priorité de swap pour ZRAM (plus bas = plus haute priorité)
priority = 100
EOF

# Recharger systemd pour appliquer la configuration
echo "Rechargement de systemd..."
systemctl daemon-reload

# Activer et démarrer le service zram-generator
echo "Activation et démarrage de zram-generator..."
systemctl enable zram-generator.service
systemctl start zram-generator.service

# Activer le swap traditionnel si ce n'est pas déjà fait
echo "Vérification et activation du swap traditionnel..."

# Vérifier si un swap est déjà activé
SWAP_ACTIVE=$(swapon --show)

# Si aucun swap traditionnel n'est actif, activer le swap (modifier en fonction de votre partition)
if [ -z "$SWAP_ACTIVE" ]; then
    echo "Aucun swap traditionnel actif. Activation du swap traditionnel."

    # Modifier ce chemin si vous avez une partition de swap différente
    SWAP_PARTITION="/dev/sdX"  # Remplacez par votre partition de swap, par exemple /dev/sda2
    swapon $SWAP_PARTITION
else
    echo "Le swap traditionnel est déjà actif."
fi

# Vérifier l'état du swap
echo "Vérification de l'état du swap..."
swapon --show
lsblk

# Vérifier et ajuster la priorité des swaps
echo "Ajustement de la priorité du swap traditionnel..."

# Définir une priorité plus basse pour le swap traditionnel (par exemple 50)
# La priorité de ZRAM (100) sera plus haute que celle du swap traditionnel
echo "Ajustement de la priorité de swap pour le swap traditionnel..."

# Si nécessaire, vous pouvez utiliser un fichier swap :
# Exemple de fichier swap avec une priorité faible
echo "priority = 50" >> /etc/fstab

echo "Configuration de ZRAM et du swap traditionnel terminée."
