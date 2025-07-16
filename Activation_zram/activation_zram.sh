#!/bin/bash

# Vérifie si l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root"
   exit 1
fi

echo "=== Configuration de zram sur Arch Linux ==="
echo

# Met à jour le système
echo "Mise à jour du système..."
pacman -Syyu --noconfirm

# Installe les outils nécessaires
echo "Installation de zram-generator..."
pacman -S --noconfirm zram-generator

# Vérifie si zswap est activé (peut interférer avec zram)
if [[ -f /sys/module/zswap/parameters/enabled ]]; then
    zswap_status=$(cat /sys/module/zswap/parameters/enabled)
    if [[ "$zswap_status" == "Y" ]]; then
        echo "⚠️  AVERTISSEMENT: zswap est activé et peut interférer avec zram"
        echo "   Pour désactiver zswap, ajoutez 'zswap.enabled=0' aux paramètres du kernel"
        echo "   Ou ajoutez-le à GRUB_CMDLINE_LINUX dans /etc/default/grub"
        echo
    fi
fi

# Crée le fichier de configuration pour zram
echo "Configuration de zram..."
cat > /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF

echo "Fichier de configuration créé : /etc/systemd/zram-generator.conf"

# Recharge la configuration systemd
echo "Rechargement de la configuration systemd..."
systemctl daemon-reload

# Tente de démarrer le service (peut échouer si le générateur n'a pas encore créé les unités)
echo "Tentative de démarrage du service zram..."
if systemctl start systemd-zram-setup@zram0.service 2>/dev/null; then
    echo "✅ Service zram démarré avec succès"
    systemctl enable systemd-zram-setup@zram0.service
else
    echo "ℹ️  Le service sera créé automatiquement au prochain démarrage"
fi

# Vérifie le statut actuel
echo
echo "=== Vérification du statut de zram ==="
if command -v zramctl &> /dev/null; then
    zramctl 2>/dev/null || echo "Aucun device zram actif actuellement"
else
    echo "Commande zramctl non disponible"
fi

echo
echo "=== Configuration terminée ==="
echo "✅ zram-generator installé et configuré"
echo "✅ Configuration : /etc/systemd/zram-generator.conf"
echo "📋 Taille zram : 50% de la RAM"
echo "📋 Algorithme de compression : zstd"
echo "📋 Priorité swap : 100"
echo
echo "🔄 REDÉMARRAGE RECOMMANDÉ pour activer zram automatiquement"
echo
echo "Commandes utiles après redémarrage :"
echo "  • Vérifier zram : zramctl"
echo "  • Vérifier swap : swapon -s"
echo "  • Statut service : systemctl status systemd-zram-setup@zram0.service"
echo "  • Logs : journalctl -u systemd-zram-setup@zram0.service"
