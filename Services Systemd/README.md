# Script d'activation des services et timers systemd

Ce dossier contient le script `activation_services.sh` destiné à activer et vérifier des services et timers systemd essentiels sur un système Arch/EndeavourOS. Le script propose une interface claire avec couleurs, des contrôles de disponibilité, et un récapitulatif de fin d'exécution.

## Fonctionnalités
- **Activation automatique de services essentiels** (`bluetooth.service`, `ufw.service`).
- **Gestion des timers** (`fstrim.timer`, `paccache.timer`).
- **Vérification de disponibilité** des unités avant traitement.
- **Affichage d'état** (status) et messages colorés.
- **Compteurs de succès/échecs** pour services et timers.
- **Résumé final** clair avec totaux et indicateurs.

## Prérequis
- Distribution basée sur Arch Linux (EndeavourOS, Arch, etc.).
- Privilèges administrateur: exécuter via `sudo`.
- `systemd` et l’outil `systemctl` disponibles.

## Installation
1. Copier le script dans un répertoire (par exemple dans ce dépôt ou `~/bin`).
2. Rendre le script exécutable:
```bash
chmod +x activation_services.sh
```

## Utilisation
Exécution standard (avec couleurs et vérifications):
```bash
sudo ./activation_services.sh
```

## Unités gérées par défaut
- **Services**:
  - `bluetooth.service`
  - `ufw.service`
- **Timers**:
  - `fstrim.timer`
  - `paccache.timer`

Ces listes sont définies dans le script et peuvent être adaptées en éditant les tableaux `services=(...)` et `timers=(...)`.

## Détails de fonctionnement
1. **Vérification root**: le script s'arrête si non exécuté avec `sudo`.
2. **Affichage d’en-têtes** et messages colorés (succès, info, avertissement, erreur).
3. **Services**:
   - Vérifie l'existence (`systemctl list-unit-files | grep`).
   - Affiche le statut (`systemctl status --no-pager`).
   - Démarre le service (`systemctl start`).
   - Active au démarrage (`systemctl enable`).
   - Incrémente les compteurs de succès/échecs.
4. **Timers**:
   - Vérifie l'existence.
   - Affiche le statut (`systemctl status --no-pager`).
   - Active le timer (`systemctl enable`).
   - Incrémente les compteurs.
5. **Vérification finale**:
   - Pour les services: contrôle `systemctl is-active` (actif/inactif).
   - Pour les timers: contrôle `systemctl is-enabled` (activé/non activé).
6. **Résumé final**:
   - Affiche totaux des succès/échecs pour services et timers.
   - Indique si tout est OK (🎉) ou s'il reste des avertissements (⚠️).

## Personnalisation
- Modifier les listes:
```bash
services=("bluetooth.service" "ufw.service" "mon.service")

# Timers
timers=("fstrim.timer" "paccache.timer" "mon.timer")
```
- Vous pouvez commenter/supprimer des unités non pertinentes pour votre système.

## Dépannage
- **"Ce script doit être exécuté en tant que root"**: relancer avec `sudo`.
- **Service/Timer n'existe pas**: le script continue mais compte un échec; vérifiez que le paquet fournissant l’unité est installé.
- **Service inactif après exécution**: consulter `systemctl status <service>` et les journaux `journalctl -u <service>`.
- **Timer non activé**: vérifier `systemctl list-timers` et l’unité correspondante.

## Bonnes pratiques
- Vérifier que les unités voulues existent avant de les ajouter aux listes.
- Lancer à nouveau le script après modification de la configuration des unités.
- Versionnez vos adaptations si vous personnalisez largement les listes.

## Avertissements
- Le script modifie l'état des services/timers (start/enable). Assurez-vous de comprendre l’impact sur votre système.
- Testé sur des systèmes de type Arch/EndeavourOS utilisant systemd.
