#!/bin/bash

# Script pour installer et configurer ZSWAP sur EndeavourOS

# Vérification si le script est exécuté en tant que root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root (utilisez sudo)"
    exit 1
fi

# Mise à jour du système
echo "Mise à jour du système..."
pacman -Syu --noconfirm

# Installation du package systemd-swap
echo "Installation de systemd-swap..."
pacman -S --noconfirm systemd-swap

# Configuration de ZSWAP dans /etc/systemd/swap.conf
echo "Configuration de ZSWAP..."

# Sauvegarde du fichier original si nécessaire
cp /etc/systemd/swap.conf /etc/systemd/swap.conf.bak

# Écriture de la nouvelle configuration dans swap.conf
cat <<EOL > /etc/systemd/swap.conf
# Désactive zswap et active zram
zswap_enabled=1
zram_enabled=0

# Taille du zswap : 50% de la RAM
zswap_size=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 2 ))

# Compression avec zstd (plus rapide et efficace)
zswap_compression_algorithm=zstd
EOL

# Activation et démarrage du service systemd-swap
echo "Activation et démarrage de systemd-swap..."
systemctl enable --now systemd-swap

# Vérification du statut du service
echo "Vérification du statut du service systemd-swap..."
systemctl status systemd-swap

echo "ZSWAP a été configuré et activé avec succès."

