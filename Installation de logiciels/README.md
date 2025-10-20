# Scripts d'installation pour EndeavourOS

Ce dossier contient deux scripts d'installation automatisés pour EndeavourOS/Arch Linux.

## 📦 Scripts disponibles

### 1. `installation_Logiciels.sh` - Installation des paquets système
Script principal pour l'installation automatisée de paquets via Pacman et AUR.

**Fonctionnalités :**
- Installation de paquets de base (utilitaires, navigateurs, multimédia, etc.)
- Support des environnements de bureau (XFCE, KDE, GNOME)
- Installation de paquets AUR via Yay
- Mode interactif avec menu
- Options en ligne de commande
- Mode simulation (dry-run)
- Système de retry automatique
- Sauvegarde et récupération

**Utilisation :**
```bash
# Mode interactif
sudo ./installation_Logiciels.sh

# Paquets de base seulement
sudo ./installation_Logiciels.sh --base

# Paquets AUR seulement
sudo ./installation_Logiciels.sh --aur-only

# Paquets de base + XFCE
sudo ./installation_Logiciels.sh --xfce

# Paquets de base + XFCE + AUR
sudo ./installation_Logiciels.sh --xfce --aur

# Mode simulation
sudo ./installation_Logiciels.sh --dry-run

# Aide
sudo ./installation_Logiciels.sh --help
```

**Menu interactif :**
1. Mise à jour système uniquement
2. Paquets de base
3. Paquets de base + XFCE
4. Paquets de base + KDE
5. Paquets de base + GNOME
6. Paquets de base + AUR
7. Paquets de base + XFCE + AUR
8. Paquets de base + KDE + AUR
9. Paquets de base + GNOME + AUR
10. Paquets AUR uniquement
11. Mode simulation
12. Aide

### 2. `installation_flatpak.sh` - Installation des applications Flatpak
Script spécialisé pour l'installation automatisée d'applications Flatpak.

**Fonctionnalités :**
- Installation d'applications Flatpak essentielles
- Configuration automatique du remote Flathub
- Mode simulation (dry-run)
- Système de retry automatique
- Vérification des applications déjà installées
- Nettoyage automatique du cache
- Interface colorée et informative

**Applications installées :**
- **Bottles** - Gestionnaire de bouteilles Wine
- **Warehouse** - Gestionnaire d'applications Flatpak
- **Flatseal** - Gestionnaire de permissions Flatpak
- **FlatSweep** - Nettoyeur de données Flatpak
- **Bazaar** - Gestionnaire de paquets Flatpak

**Utilisation :**
```bash
# Installation normale
sudo ./installation_flatpak.sh

# Mode simulation
sudo ./installation_flatpak.sh --dry-run

# Voir la liste des applications
sudo ./installation_flatpak.sh --list

# Aide
sudo ./installation_flatpak.sh --help
```

## 🚀 Installation rapide

1. **Rendre les scripts exécutables :**
   ```bash
   chmod +x installation_Logiciels.sh
   chmod +x installation_flatpak.sh
   ```

2. **Exécuter les scripts :**
   ```bash
   # Installation des paquets système
   sudo ./installation_Logiciels.sh

   # Installation des applications Flatpak
   sudo ./installation_flatpak.sh
   ```

## 📋 Prérequis

- **EndeavourOS/Arch Linux** installé
- **Accès sudo** pour les installations
- **Connexion Internet** active

## 🔧 Fonctionnalités communes

- **Gestion d'erreurs robuste** avec `set -euo pipefail`
- **Gestion des interruptions** (Ctrl+C)
- **Messages colorés** pour une meilleure lisibilité
- **Logs détaillés** des opérations
- **Mode simulation** pour tester sans installer
- **Retry automatique** en cas d'échec réseau

## 📝 Notes

- Les scripts sont conçus pour être utilisés ensemble
- Commencez par `installation_Logiciels.sh` puis `installation_flatpak.sh`
- Les deux scripts peuvent être exécutés en mode simulation pour tester
- Une sauvegarde automatique des paquets installés est créée