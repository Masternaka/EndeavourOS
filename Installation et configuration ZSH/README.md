## Installation Zsh + Zinit + Oh My Posh (Catppuccin) pour Arch/EndeavourOS

Ce script automatise l’installation et la configuration d’un environnement Zsh moderne sur Arch/EndeavourOS:
- Installe Zsh, Zinit, Oh My Posh et une Nerd Font
- Configure le thème Oh My Posh par défaut sur Catppuccin (mocha), avec variantes au choix
- Ajoute des plugins Zsh utiles (complétions, suggestions, historique, highlighting)
- Met Zsh en shell par défaut si nécessaire
- N’écrase pas votre `~/.zshrc` existant (sauvegarde + bloc géré)

### Prérequis
- Système Arch/EndeavourOS (pacman)
- Accès root (sudo)
- Connexion internet

### Installation
1) Rendre le script exécutable
```bash
chmod +x installation_zsh.sh
```
2) Exécuter avec sudo
```bash
sudo ./installation_zsh.sh
```

### Options disponibles
- `--dry-run` : simule les actions sans rien modifier
- `--verbose` : affiche des logs détaillés (trace des commandes)
- `--theme NAME` : sélectionne la variante Catppuccin `latte | frappe | macchiato | mocha`
- `--theme-url URL` : URL directe vers un thème Oh My Posh (prioritaire sur `--theme`)
- `-h, --help` : affiche l’aide

Vous pouvez aussi définir des variables d’environnement avant l’appel:
- `THEME_NAME=latte` ou `THEME_URL=https://…/mon_theme.omp.json`

### Exemples d’usage
- Simulation complète:
```bash
sudo ./installation_zsh.sh --dry-run
```
- Installation verbeuse avec thème Macchiato:
```bash
sudo ./installation_zsh.sh --verbose --theme macchiato
```
- Thème personnalisé via URL:
```bash
sudo ./installation_zsh.sh --theme-url https://raw.githubusercontent.com/catppuccin/oh-my-posh/main/themes/catppuccin_latte.omp.json
```

### Ce que le script installe et configure
- Paquets: `zsh`, `git`, `curl`, `wget`, `unzip` (et `oh-my-posh` si dispo via pacman, sinon script officiel)
- Zinit dans `/usr/local/share/zinit/zinit.git`
- Bloc de configuration ajouté dans `~/.zshrc` (sans écraser votre contenu existant):
  - Initialisation Zinit
  - Plugins:
    - `zsh-users/zsh-completions`
    - `zsh-users/zsh-autosuggestions`
    - `zsh-users/zsh-history-substring-search`
    - `zsh-users/zsh-syntax-highlighting` (chargé en dernier)
  - Initialisation Oh My Posh avec `~/.poshtheme.omp.json`
  - Quelques alias (`ls`, `ll`) et initialisation `compinit`/`colors`
- Thème Oh My Posh téléchargé dans `~/.poshtheme.omp.json`
- Police Meslo Nerd Font (via pacman si dispo, sinon téléchargement direct), puis `fc-cache`
- Shell par défaut commuté vers Zsh si pas déjà le cas

### Choix du thème Catppuccin
- Par défaut: Catppuccin Mocha
- Variantes: `latte` (clair), `frappe`, `macchiato`, `mocha` (foncé)
- Sans flags et en terminal interactif, le script propose un menu pour choisir la variante.

### Idempotence et sécurité
- Le script est réexécutable sans casser la config existante
- `~/.zshrc` est sauvegardé sous `~/.zshrc.backup-YYYYMMDD-HHMMSS` avant modification
- Utilisation de `set -euo pipefail`, `trap` d’erreur et téléchargements via `curl -fsSL`

### Désinstallation / Retour arrière (manuel)
- Restaurer votre `~/.zshrc` depuis la sauvegarde la plus récente
- Supprimer le bloc délimité par `# >>> zsh-setup managed block >>> ... # <<< zsh-setup managed block <<<`
- Facultatif: remettre Bash comme shell par défaut
```bash
chsh -s /bin/bash $USER
```
- Facultatif: supprimer Zinit et le thème
```bash
sudo rm -rf /usr/local/share/zinit
rm -f ~/.poshtheme.omp.json
```

### Dépannage
- Oh My Posh ne s’affiche pas correctement:
  - Vérifiez que le terminal utilise une Nerd Font (ex. MesloLGS Nerd Font)
  - Relancez le terminal ou exécutez `exec zsh`
- Complétions Zsh lentes ou warnings `compaudit`:
  - Vous pouvez exécuter `compaudit` et corriger les permissions
  - Ou forcer `compinit -u` dans votre config si vous savez ce que vous faites
