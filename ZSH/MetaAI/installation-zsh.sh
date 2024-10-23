#!/bin/bash

# Vérification si l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root" 
   exit 1
fi

# Installer zsh
echo "Installation de Zsh..."
pacman -Syu --noconfirm zsh

# Définir zsh comme shell par défaut
echo "Définition de Zsh comme shell par défaut..."
chsh -s /bin/zsh

# Installer oh-my-zsh
echo "Installation de oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Installer powerlevel10k
echo "Installation de powerlevel10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

# Installer les plugins
echo "Installation des plugins"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-completions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-history-substring-search.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/z.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/z
git clone https://github.com/junegunn/fzf.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin

# Ajouter les configurations dans ~/.zshrc
echo "Installation du thèmes et des plugins"
echo "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" >> ~/.zshrc
echo "plugins=(zsh-syntax-highlighting zsh-autosuggestions zsh-completions zsh-history-substring-search powerlevel10k z fzf-zsh-plugin)" >> ~/.zshrc

# Redémarrer le shell
exec zsh

# Exécuter la configuration initiale de Powerlevel10k
echo "Lancer la configuration initiale de Powerlevel10k..."
zsh -c 'source ~/.zshrc && p10k configure'
