#!/bin/bash

# Configuration
LOGFILE="$HOME/update_log_$(date +%Y-%m-%d).txt"
BACKUP_DIR="$HOME/system_backups"

# Fonction pour afficher et logger
log_message() {
    echo -e "$1" | tee -a "$LOGFILE"
}

# Fonction pour vérifier la connexion internet
check_internet() {
    if ! ping -c 1 google.com &> /dev/null; then
        log_message "❌ Pas de connexion internet détectée"
        exit 1
    fi
}

# Fonction pour créer une sauvegarde de la liste des paquets
backup_packages() {
    log_message "\n=== Sauvegarde de la liste des paquets ==="
    mkdir -p "$BACKUP_DIR"
    
    # Sauvegarde des paquets Pacman
    pacman -Qqe > "$BACKUP_DIR/pacman_packages_$(date +%Y-%m-%d).txt"
    
    # Sauvegarde des paquets AUR si yay est installé
    if command -v yay &> /dev/null; then
        yay -Qqm > "$BACKUP_DIR/aur_packages_$(date +%Y-%m-%d).txt"
    fi
    
    # Sauvegarde des paquets Flatpak si installé
    if command -v flatpak &> /dev/null; then
        flatpak list --app --columns=application > "$BACKUP_DIR/flatpak_packages_$(date +%Y-%m-%d).txt"
    fi
    
    log_message "✅ Sauvegarde terminée dans $BACKUP_DIR"
}

# Fonction pour mettre à jour Pacman
update_pacman() {
    log_message "\n=== Mise à jour des paquets Pacman ==="
    
    # Mise à jour de la base de données
    if sudo pacman -Sy >> "$LOGFILE" 2>&1; then
        log_message "✅ Base de données Pacman mise à jour"
    else
        log_message "❌ Erreur lors de la mise à jour de la base de données"
        return 1
    fi
    
    # Vérification des mises à jour disponibles
    updates=$(pacman -Qu | wc -l)
    if [ "$updates" -eq 0 ]; then
        log_message "ℹ️  Aucune mise à jour Pacman disponible"
        return 0
    fi
    
    log_message "📦 $updates mise(s) à jour Pacman disponible(s)"
    
    # Mise à jour des paquets
    if sudo pacman -Su --noconfirm >> "$LOGFILE" 2>&1; then
        log_message "✅ Pacman terminé avec succès"
        return 0
    else
        log_message "❌ Erreur lors de la mise à jour Pacman"
        return 1
    fi
}

# Fonction pour mettre à jour AUR
update_aur() {
    log_message "\n=== Mise à jour des paquets AUR ==="
    
    if ! command -v yay &> /dev/null; then
        log_message "⚠️  Yay n'est pas installé, passage de l'AUR"
        return 0
    fi
    
    # Vérification des mises à jour AUR disponibles
    aur_updates=$(yay -Qum 2>/dev/null | wc -l)
    if [ "$aur_updates" -eq 0 ]; then
        log_message "ℹ️  Aucune mise à jour AUR disponible"
        return 0
    fi
    
    log_message "📦 $aur_updates mise(s) à jour AUR disponible(s)"
    
    if yay -Syu --noconfirm >> "$LOGFILE" 2>&1; then
        log_message "✅ AUR terminé avec succès"
        return 0
    else
        log_message "❌ Erreur lors de la mise à jour AUR"
        return 1
    fi
}

# Fonction pour mettre à jour Flatpak
update_flatpak() {
    log_message "\n=== Mise à jour des paquets Flatpak ==="
    
    if ! command -v flatpak &> /dev/null; then
        log_message "⚠️  Flatpak n'est pas installé, passage de Flatpak"
        return 0
    fi
    
    # Vérification des mises à jour Flatpak disponibles
    flatpak_updates=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
    if [ "$flatpak_updates" -eq 0 ]; then
        log_message "ℹ️  Aucune mise à jour Flatpak disponible"
        return 0
    fi
    
    log_message "📦 $flatpak_updates mise(s) à jour Flatpak disponible(s)"
    
    if flatpak update -y >> "$LOGFILE" 2>&1; then
        log_message "✅ Flatpak terminé avec succès"
        return 0
    else
        log_message "❌ Erreur lors de la mise à jour Flatpak"
        return 1
    fi
}

# Fonction pour nettoyer le système
cleanup_system() {
    log_message "\n=== Nettoyage du système ==="
    
    # Nettoyage du cache Pacman (garde les 3 dernières versions)
    if sudo paccache -rk3 >> "$LOGFILE" 2>&1; then
        log_message "✅ Cache Pacman nettoyé"
    fi
    
    # Nettoyage du cache Yay si disponible
    if command -v yay &> /dev/null; then
        if yay -Scc --noconfirm >> "$LOGFILE" 2>&1; then
            log_message "✅ Cache Yay nettoyé"
        fi
    fi
    
    # Suppression des paquets orphelins
    orphans=$(pacman -Qtdq)
    if [ -n "$orphans" ]; then
        log_message "🧹 Suppression des paquets orphelins : $orphans"
        echo "$orphans" | sudo pacman -Rns - >> "$LOGFILE" 2>&1
    else
        log_message "ℹ️  Aucun paquet orphelin trouvé"
    fi
}

# Fonction principale
main() {
    log_message "🚀 Début des mises à jour : $(date)"
    log_message "📋 Fichier de log : $LOGFILE"
    
    # Vérifications préliminaires
    check_internet
    
    # Sauvegarde des paquets
    backup_packages
    
    # Mises à jour
    local failed=0
    
    if ! update_pacman; then
        failed=1
    fi
    
    if ! update_aur; then
        failed=1
    fi
    
    if ! update_flatpak; then
        failed=1
    fi
    
    # Nettoyage (même si des mises à jour ont échoué)
    cleanup_system
    
    # Résumé final
    log_message "\n=== Résumé ==="
    if [ "$failed" -eq 0 ]; then
        log_message "✅ Toutes les mises à jour ont été effectuées avec succès"
        log_message "🎉 Système mis à jour : $(date)"
    else
        log_message "⚠️  Certaines mises à jour ont échoué"
        log_message "📋 Consultez le fichier de log pour plus de détails"
    fi
    
    # Affichage des informations système
    log_message "\n=== Informations système ==="
    log_message "🐧 Noyau : $(uname -r)"
    log_message "💾 Espace disque utilisé : $(df -h / | awk 'NR==2{print $5}')"
    
    exit $failed
}

# Gestion des signaux (Ctrl+C)
trap 'log_message "\n❌ Script interrompu par l'\''utilisateur"; exit 1' INT TERM

# Vérifier si le script est exécuté en tant que root
if [[ $EUID -eq 0 ]]; then
   echo "❌ Ce script ne doit pas être exécuté en tant que root"
   exit 1
fi

# Exécution du script principal
main