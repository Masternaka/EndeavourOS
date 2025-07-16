
### Mes Alias début ###

alias ls='ls --color=auto'
alias la='ls -a'
alias pacinstall='sudo pacman -S'
alias pacsearch='sudo pacman -Ss'
alias pacremove='sudo pacman -R'
alias update='sudo pacman -Syyu'
alias upall='yay -Syu --noconfirm'
alias upmax='sudo pacman -Syu && yay -Syu && flatpak update'
alias grep='grep --color=auto'
alias df='df -h'
alias freemem="free -mt"
alias update-font='sudo fc-cache -fv'
alias bupskel='cp -Rf /etc/skel ~/.skel-backup-$(date +%Y.%m.%d-%H.%M.%S)'
alias cb='cp /etc/skel/.bashrc ~/.bashrc && exec bash'
alias cz='cp /etc/skel/.zshrc ~/.zshrc && echo "Copied."'
alias cf='cp /etc/skel/.config/fish/config.fish ~/.config/fish/config.fish && echo "Copied."'
alias tobash="sudo chsh $USER -s /bin/bash && echo 'Now log out.'"
alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Now log out.'"
alias tofish="sudo chsh $USER -s /bin/fish && echo 'Now log out.'"
alias kc='killall conky'
alias kp='killall polybar'
alias kpi='killall picom'
alias hw="hwinfo --short"
alias ff="fastfetch"
alias audio="pactl info | grep 'Server Name'"
alias mirrors="sudo reflector --latest 30 --number 10 --sort score --save /etc/pacman.d/mirrorlist"
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
alias riplong="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -3000 | nl"
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'
alias list="sudo pacman -Qqe"
alias listt="sudo pacman -Qqet"
alias listaur="sudo pacman -Qqem"
alias rg="rg --sort path"
alias jctl="journalctl -p 3 -xb"
alias npacman="sudo $EDITOR /etc/pacman.conf"
alias nmakepkg="sudo $EDITOR /etc/makepkg.conf"
alias nmirrorlist="sudo $EDITOR /etc/pacman.d/mirrorlist"
alias nfstab="sudo $EDITOR /etc/fstab"
alias nnsswitch="sudo $EDITOR /etc/nsswitch.conf"
alias nsamba="sudo $EDITOR /etc/samba/smb.conf"
alias nhosts="sudo $EDITOR /etc/hosts"
alias nhostname="sudo $EDITOR /etc/hostname"
alias nb="$EDITOR ~/.bashrc"
alias nz="$EDITOR ~/.zshrc"
alias nf="$EDITOR ~/.config/fish/config.fish"
alias nneofetch="$EDITOR ~/.config/neofetch/config.conf"
alias nfastfetch="$EDITOR ~/.config/fastfetch/config.jsonc"
alias nenvironment="sudo $EDITOR /etc/environment"
alias nalacritty="nano /home/$USER/.config/alacritty/alacritty.toml"
alias nkitty="$EDITOR ~/.config/kitty/kitty.conf"
alias lpacman="bat /var/log/pacman.log"
alias fix-permissions="sudo chown -R $USER:$USER ~/.config ~/.local"
alias sysfailed="systemctl list-units --failed"
alias ssn="sudo shutdown now"
alias sr="reboot"
alias xd="ls /usr/share/xsessions"
alias xdw="ls /usr/share/wayland-sessions"
alias kernel="ls /usr/lib/modules"

### Fin Mes Alias fin ###

