
Créons également un script de mise à jour :

```update_zsh_config.sh#L1-50
#!/bin/bash

# Script de mise à jour de la configuration ZSH
# Met à jour zinit, oh-my-posh et les plugins

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

main() {
    log_info "Mise à jour de l'environnement zsh..."
    
    # Mise à jour de zinit
    if command -v zinit &> /dev/null; then
        log_info "Mise à jour de zinit..."
        zinit self-update
        zinit update
        log_success "Zinit mis à jour"
    fi
    
    # Mise à jour d'oh-my-posh
    log_info "Mise à jour d'oh-my-posh..."
    if command -v brew &> /dev/null && [[ "$OSTYPE" == "darwin"* ]]; then
        brew upgrade oh-my-posh
    else
        curl -s https://ohmyposh.dev/install.sh | bash -s
    fi
    log_success "Oh-my-posh mis à jour"
    
    # Recompilation des completions
    log_info "Recompilation des completions..."
    rm -f ~/.zcompdump
    autoload -U compinit && compinit
    log_success "Completions recompilées"
    
    log_success "Mise à jour terminée! Redémarrez votre terminal."
}

main "$@"
