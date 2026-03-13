#!/bin/bash

# Script d'installation du dépôt Chaotic-AUR sur Arch Linux
# Auteur: Masternaka (Version corrigée)
# Date: $(date +%Y-%m-%d)

set -e

# Couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier si le script est exécuté en tant que root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Ce script ne doit pas être exécuté en tant que root"
        print_info "Utilisez: ./install_Chaotic_fixed.sh"
        exit 1
    fi
}

# Vérifier si pacman est disponible
check_pacman() {
    if ! command -v pacman &> /dev/null; then
        print_error "pacman n'est pas disponible. Ce script est destiné à Arch Linux."
        exit 1
    fi
}

# Vérifier la connexion internet
check_internet() {
    print_info "Vérification de la connexion internet..."
    if ! ping -c 1 archlinux.org &> /dev/null; then
        print_error "Pas de connexion internet. Veuillez vérifier votre connexion."
        exit 1
    fi
    print_success "Connexion internet OK"
}

# Mettre à jour le système
update_system() {
    print_info "Mise à jour du système..."
    sudo pacman -Syu --noconfirm
    print_success "Système mis à jour"
}

# Installer les dépendances requises
install_dependencies() {
    print_info "Installation des dépendances requises..."
    sudo pacman -S --needed --noconfirm base-devel curl wget
    print_success "Dépendances installées"
}

# Ajouter la clé GPG principale de Chaotic-AUR
add_primary_key() {
    print_info "Ajout de la clé GPG principale de Chaotic-AUR..."
    
    # Recevoir la clé depuis le serveur de clés
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    
    # Signer localement la clé pour lui faire confiance
    sudo pacman-key --lsign-key 3056513887B78AEB
    
    print_success "Clé GPG principale ajoutée et signée"
}

# Installer chaotic-keyring et chaotic-mirrorlist
install_chaotic_packages() {
    print_info "Installation de chaotic-keyring et chaotic-mirrorlist..."
    
    # URLs des paquets
    KEYRING_URL='https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    MIRRORLIST_URL='https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    
    # Télécharger et installer les paquets
    cd /tmp
    
    print_info "Téléchargement de chaotic-keyring..."
    wget -q --show-progress "$KEYRING_URL" -O chaotic-keyring.pkg.tar.zst
    
    print_info "Téléchargement de chaotic-mirrorlist..."
    wget -q --show-progress "$MIRRORLIST_URL" -O chaotic-mirrorlist.pkg.tar.zst
    
    print_info "Installation des paquets..."
    sudo pacman -U --noconfirm chaotic-keyring.pkg.tar.zst chaotic-mirrorlist.pkg.tar.zst
    
    # Nettoyage
    rm -f chaotic-keyring.pkg.tar.zst chaotic-mirrorlist.pkg.tar.zst
    
    print_success "chaotic-keyring et chaotic-mirrorlist installés"
}

# Ajouter le dépôt Chaotic-AUR à pacman.conf
add_chaotic_repo() {
    print_info "Ajout du dépôt Chaotic-AUR à pacman.conf..."
    
    PACMAN_CONF="/etc/pacman.conf"
    
    # Vérifier si le dépôt existe déjà
    if grep -q "\[chaotic-aur\]" "$PACMAN_CONF"; then
        print_warning "Le dépôt Chaotic-AUR existe déjà dans pacman.conf"
        print_info "Suppression de l'ancienne entrée..."
        sudo sed -i '/\[chaotic-aur\]/,/^$/d' "$PACMAN_CONF"
    fi
    
    # Sauvegarde du fichier original
    sudo cp "$PACMAN_CONF" "$PACMAN_CONF.backup.$(date +%Y%m%d_%H%M%S)"
    print_info "Sauvegarde créée: $PACMAN_CONF.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Ajouter le dépôt avec Include pour utiliser mirrorlist
    sudo tee -a "$PACMAN_CONF" > /dev/null << 'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
    
    print_success "Dépôt Chaotic-AUR ajouté à pacman.conf"
}

# Mettre à jour la base de données pacman
update_pacman_db() {
    print_info "Mise à jour de la base de données pacman..."
    sudo pacman -Sy --noconfirm
    print_success "Base de données mise à jour"
}

# Vérifier l'installation
verify_installation() {
    print_info "Vérification de l'installation..."
    
    # Vérifier si le dépôt est dans la liste
    if pacman -Sl chaotic-aur &> /dev/null; then
        print_success "Le dépôt Chaotic-AUR est correctement installé et accessible"
        
        # Afficher quelques statistiques
        local package_count=$(pacman -Sl chaotic-aur | wc -l)
        print_info "Nombre de paquets disponibles dans Chaotic-AUR: $package_count"
        
        echo
        print_success "═══════════════════════════════════════════════════"
        print_success "  Installation terminée avec succès!"
        print_success "═══════════════════════════════════════════════════"
        echo
        print_info "Exemples d'utilisation:"
        print_info "  • Rechercher un paquet: pacman -Ss <paquet>"
        print_info "  • Installer un paquet: sudo pacman -S <paquet>"
        print_info "  • Lister les paquets: pacman -Sl chaotic-aur"
        echo
        print_info "Paquets populaires de Chaotic-AUR:"
        print_info "  • brave-bin (navigateur)"
        print_info "  • visual-studio-code-bin"
        print_info "  • spotify"
        print_info "  • discord"
        echo
    else
        print_error "L'installation a échoué - le dépôt n'est pas accessible"
        print_info "Vérifiez les logs ci-dessus pour plus d'informations"
        exit 1
    fi
}

# Fonction principale
main() {
    echo
    print_info "═══════════════════════════════════════════════════"
    print_info "  Installation du dépôt Chaotic-AUR"
    print_info "═══════════════════════════════════════════════════"
    echo
    
    check_root
    check_pacman
    check_internet
    
    print_warning "Ce script va:"
    print_warning "  1. Mettre à jour votre système"
    print_warning "  2. Installer les dépendances nécessaires"
    print_warning "  3. Ajouter les clés GPG de Chaotic-AUR"
    print_warning "  4. Installer chaotic-keyring et chaotic-mirrorlist"
    print_warning "  5. Configurer le dépôt dans pacman.conf"
    echo
    print_warning "Assurez-vous de comprendre ces modifications"
    echo
    read -p "Voulez-vous continuer? (y/N): " -n 1 -r
    echo
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation annulée par l'utilisateur"
        exit 0
    fi
    
    update_system
    install_dependencies
    add_primary_key
    install_chaotic_packages
    add_chaotic_repo
    update_pacman_db
    verify_installation
    
    echo
    print_success "Installation complète! Profitez de Chaotic-AUR! 🎉"
    echo
}

# Exécuter la fonction principale
main "$@"