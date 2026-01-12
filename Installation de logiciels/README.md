# Scripts d'installation pour EndeavourOS/Arch Linux

Ce dossier contient une suite complète de scripts d'installation automatisés pour EndeavourOS et Arch Linux, divisés par catégorie pour plus de flexibilité.

## 📦 Scripts disponibles

Les scripts d'installation système sont maintenant séparés par catégorie :

### 1. `install_base.sh` - Paquets de base
Script pour installer les paquets de base communs à tous les systèmes.

**Paquets installés :**
- **EndeavourOS-spécifiques** (détection automatique) : akm, eos-update-notifier
- **Utilitaires** : catfish, flatpak, flameshot, gparted, gufw, openrgb, qbittorrent, transmission-qt, distrobox, lshw, fwupd, timeshift, p7zip
- **Terminal** : btop, fastfetch, yazi, neovim, kitty
- **Sécurité** : keepassxc
- **Navigateurs** : thunderbird, vivaldi
- **Multimédia** : strawberry, vlc
- **Communication** : discord
- **Office** : libreoffice-fresh, libreoffice-fresh-fr
- **Développement** : code, meld, zed
- **Virtualisation** : qemu-full, virt-manager

**Utilisation :**
```bash
# Installation normale
sudo ./install_base.sh

# Mode simulation
sudo ./install_base.sh --dry-run

# Aide
sudo ./install_base.sh --help
```

### 2. `install_xfce.sh` - Environnement XFCE
Script pour installer l'environnement de bureau XFCE avec tous ses plugins et extensions (37 paquets).

**Utilisation :**
```bash
sudo ./install_xfce.sh [--dry-run] [--help]
```

### 3. `install_kde.sh` - Environnement KDE Plasma
Script pour installer l'environnement de bureau KDE Plasma avec tous ses outils (20 paquets).

**Utilisation :**
```bash
sudo ./install_kde.sh [--dry-run] [--help]
```

### 4. `install_gnome.sh` - Environnement GNOME
Script pour installer l'environnement de bureau GNOME avec tweaks et extensions (11 paquets).

**Utilisation :**
```bash
sudo ./install_gnome.sh [--dry-run] [--help]
```

### 5. `install_aur.sh` - Paquets AUR
Script pour installer les paquets AUR via Yay.

**Paquets AUR installés :**
- **Utilitaires** : pacseek, ipscan
- **Navigateur** : brave-bin
- **Développement** : github-desktop, gitkraken, visual-studio-code-bin
- **Multimédia** : deadbeef, spotify

**Utilisation :**
```bash
sudo ./install_aur.sh [--dry-run] [--help]
```

### 6. `installation_flatpak.sh` - Applications Flatpak (LEGACY)
Script pour l'installation automatisée d'applications Flatpak.

**Applications installées :**
- Bottles, Warehouse, Flatseal, FlatSweep, Bazaar

**Utilisation :**
```bash
sudo ./installation_flatpak.sh [--dry-run] [--list] [--help]
```

### 7. `install_appimage.sh` - Gestionnaire AppImage (LEGACY)
Script pour l'installation et intégration d'AppImages.

**Utilisation :**
```bash
sudo ./install_appimage.sh install <URL|FICHIER> --name NOM [--icon /chemin] [--system]
sudo ./install_appimage.sh uninstall NOM [--system]
sudo ./install_appimage.sh list [--system]
```

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

### Méthode 1 : Installation complète (Recommandée)
```bash
# Rendre les scripts exécutables
chmod +x install_base.sh install_xfce.sh install_kde.sh install_gnome.sh install_aur.sh

# 1. Installer les paquets de base
sudo ./install_base.sh

# 2. Choisir un environnement de bureau
sudo ./install_xfce.sh    # ou install_kde.sh / install_gnome.sh

# 3. (Optionnel) Installer les paquets AUR
sudo ./install_aur.sh

# 4. (Optionnel) Installer les applications Flatpak
sudo ./installation_flatpak.sh
```

### Méthode 2 : Installation minimale (Base uniquement)
```bash
chmod +x install_base.sh
sudo ./install_base.sh
```

### Méthode 3 : Installation avec un DE spécifique
```bash
chmod +x install_base.sh install_kde.sh
sudo ./install_base.sh
sudo ./install_kde.sh
```

## 📋 Prérequis

- **EndeavourOS/Arch Linux** installé
- **Accès sudo** pour les installations
- **Connexion Internet** active
- **Pacman** configuré et fonctionnel

## 🔧 Fonctionnalités communes

Tous les scripts partagent les mêmes fonctionnalités :

- ✅ **Gestion d'erreurs robuste** avec `set -euo pipefail`
- ✅ **Détection du système** (EndeavourOS vs Arch)
- ✅ **Gestion des interruptions** (Ctrl+C)
- ✅ **Messages colorés** pour une meilleure lisibilité
- ✅ **Mode simulation** (--dry-run) pour tester sans installer
- ✅ **Retry automatique** (3 tentatives) en cas d'échec
- ✅ **Confirmation** avant installation
- ✅ **Aide complète** (--help)

## 📊 Résumé des options

| Script | Options | Description |
|--------|---------|-------------|
| `install_base.sh` | `--dry-run`, `--help` | Paquets de base avec détection EndeavourOS |
| `install_xfce.sh` | `--dry-run`, `--help` | Environnement XFCE (37 paquets) |
| `install_kde.sh` | `--dry-run`, `--help` | Environnement KDE (20 paquets) |
| `install_gnome.sh` | `--dry-run`, `--help` | Environnement GNOME (11 paquets) |
| `install_aur.sh` | `--dry-run`, `--help` | Paquets AUR via Yay (8 paquets) |
| `installation_flatpak.sh` | `--dry-run`, `--list`, `--help` | Applications Flatpak |
| `install_appimage.sh` | Voir --help | Gestionnaire AppImage |

## 💡 Conseils d'utilisation

### Tester avant d'installer
```bash
# Simuler l'installation sans rien installer
sudo ./install_base.sh --dry-run
sudo ./install_xfce.sh --dry-run
```

### Installation progressive
- Commencez par `install_base.sh` (paquets communs)
- Ajoutez un environnement de bureau (`install_xfce.sh` / `install_kde.sh` / `install_gnome.sh`)
- Complétez avec les AUR (`install_aur.sh`) et Flatpak (`installation_flatpak.sh`)

### Sur Arch Linux pur
Le script `install_base.sh` détecte automatiquement qu'il n'est pas sur EndeavourOS et ignore les paquets spécifiques.

## 🐛 Dépannage

**Erreur de permissions :**
```bash
# Les scripts nécessitent sudo
sudo ./install_base.sh
```

**Paquet non trouvé :**
- Vérifier que le paquet existe dans les dépôts
- Vérifier la syntaxe du nom du paquet
- Mettre à jour les dépôts : `sudo pacman -Sy`

**Installation interrompue :**
- Les paquets déjà installés ne seront pas réinstallés
- Vous pouvez relancer le script en toute sécurité

## 📝 Notes

- **Scripts modulaires** : Exécutez uniquement ce dont vous avez besoin
- **Idempotents** : Les scripts peuvent être exécutés plusieurs fois en toute sécurité
- **Sauvegarde automatique** : `install_base.sh` crée une sauvegarde des paquets installés
- **Script de récupération** : Un script de récupération est généré à chaque exécution
- **Compatibilité** : Support complet d'EndeavourOS et Arch Linux avec détection automatique
- **Retry intelligent** : Réessais automatiques en cas d'erreur réseau

## 🔄 Migration depuis `installation_Logiciels.sh`

Si vous utilisiez l'ancien script monolithique :

```bash
# Ancien système (toujours disponible)
sudo ./installation_Logiciels.sh --xfce --aur

# Nouveau système (recommandé)
sudo ./install_base.sh
sudo ./install_xfce.sh
sudo ./install_aur.sh
```

## 📄 Licence

Tous les scripts sont fournis sous licence libre. Libre de modification et redistribution.