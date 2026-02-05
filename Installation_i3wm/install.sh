#!/bin/bash

# Based on JustAGuy Linux - i3 Setup, but 
# https://codeberg.org/justaguylinux/i3-setup for the original

set -e

# Command line options
ONLY_CONFIG=false
EXPORT_PACKAGES=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --only-config)
            ONLY_CONFIG=true
            shift
            ;;
        --export-packages)
            EXPORT_PACKAGES=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "  --only-config      Only copy config files (skip packages and external tools)"
            echo "  --export-packages  Export package lists for different distros and exit"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/i3"
TEMP_DIR="/tmp/i3_$$"
LOG_FILE="$HOME/i3-install.log"

# Logging and cleanup
exec > >(tee -a "$LOG_FILE") 2>&1
trap "rm -rf $TEMP_DIR" EXIT

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

die() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
msg() { echo -e "${CYAN}$*${NC}"; }

# Export package lists for different distros
export_packages() {
    echo "=== i3 Setup - Package Lists for Different Distributions ==="
    echo
    
    # Combine all packages
    local all_packages=(
        "${PACKAGES_CORE[@]}"
        "${PACKAGES_UI[@]}"
        "${PACKAGES_FILE_MANAGER[@]}"
        "${PACKAGES_AUDIO[@]}"
        "${PACKAGES_UTILITIES[@]}"
        "${PACKAGES_TERMINAL[@]}"
        "${PACKAGES_FONTS[@]}"
        "${PACKAGES_BUILD[@]}"
    )
    
    echo "ARCH LINUX:"
    echo "sudo pacman -S ${all_packages[*]}"
    echo
    echo "After installing packages, you can use:"
    echo "  $0 --only-config    # To copy just the i3 configuration files"
}

# Check if we should export packages and exit
if [ "$EXPORT_PACKAGES" = true ]; then
    export_packages
    exit 0
fi

# Check if running on Arch Linux
if [ ! -f /etc/arch-release ]; then
    die "This script is designed to run only on Arch Linux. Detected distribution is not Arch."
fi

# Banner
clear
echo -e "${CYAN}"
echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+ "
echo " |j|u|s|t|a|g|u|y|l|i|n|u|x| "
echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+ "
echo " |i|3| |s|e|t|u|p|          | "
echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+ "
echo -e "${NC}\n"

read -p "Install i3? (y/n) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

# Update system
if [ "$ONLY_CONFIG" = false ]; then
    msg "Updating system..."
    sudo pacman -Syu --noconfirm
else
    msg "Skipping system update (--only-config mode)"
fi

# Package groups for better organization
PACKAGES_CORE=(
    xorg-server xorg-xinit xorg-xbacklight xbindkeys xvkbd xorg-xinput
    base-devel i3 sxhkd xdotool
    libnotify arandr 
)

PACKAGES_UI=(
    polybar rofi dunst feh lxappearance network-manager-applet lxsession
)

PACKAGES_FILE_MANAGER=(
    thunar thunar-archive-plugin thunar-volman thunar-shares-plugin
    gvfs dialog mtools smbclient cifs-utils ripgrep fd unzip
)

PACKAGES_AUDIO=(
    pavucontrol pulsemixer pamixer pipewire-audio pipewire-pulse
)

PACKAGES_UTILITIES=(
    avahi acpi acpid xfce4-power-manager
    flameshot ristretto firefox micro xdg-user-dirs-gtk autotiling
)

PACKAGES_TERMINAL=(
    dmenu lsw slock xorg-xprop slop wmname xssstate eza i3status xsel util-linux xdotool tmux
)

PACKAGES_FONTS=(
    awesome-terminal-fonts otf-firamono-nerd ttf-jetbrains-mono-nerd ttf-meslo-nerd
)

PACKAGES_BUILD=(
    cmake cmake-extras meson ninja curl pkgconf wget
)


# Install packages by group
if [ "$ONLY_CONFIG" = false ]; then
    msg "Installing core packages..."
    sudo pacman -S --noconfirm "${PACKAGES_CORE[@]}" || die "Failed to install core packages"

    msg "Installing UI components..."
    sudo pacman -S --noconfirm "${PACKAGES_UI[@]}" || die "Failed to install UI packages"

    msg "Installing file manager..."
    sudo pacman -S --noconfirm "${PACKAGES_FILE_MANAGER[@]}" || die "Failed to install file manager"

    msg "Installing audio support..."
    sudo pacman -S --noconfirm "${PACKAGES_AUDIO[@]}" || die "Failed to install audio packages"

    msg "Installing system utilities..."
    sudo pacman -S --noconfirm "${PACKAGES_UTILITIES[@]}" || die "Failed to install utilities"
    
    # Firefox is available as firefox in Arch
    sudo pacman -S --noconfirm firefox || msg "Note: firefox not available, skipping..."

    msg "Installing terminal tools..."
    sudo pacman -S --noconfirm "${PACKAGES_TERMINAL[@]}" || die "Failed to install terminal tools"
    
    # eza is available in Arch
    sudo pacman -S --noconfirm eza || msg "Note: eza not available, skipping..."

    msg "Installing fonts..."
    sudo pacman -S --noconfirm "${PACKAGES_FONTS[@]}" || die "Failed to install fonts"

    msg "Installing build dependencies..."
    sudo pacman -S --noconfirm "${PACKAGES_BUILD[@]}" || die "Failed to install build tools"

    # Enable services
    sudo systemctl enable avahi-daemon acpid
else
    msg "Skipping package installation (--only-config mode)"
fi

# Handle existing config
if [ -d "$CONFIG_DIR" ]; then
    clear
    read -p "Found existing i3 config. Backup? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv "$CONFIG_DIR" "$CONFIG_DIR.bak.$(date +%s)"
        msg "Backed up existing config"
    else
        clear
        read -p "Overwrite without backup? (y/n) " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || die "Installation cancelled"
        rm -rf "$CONFIG_DIR"
    fi
fi

# Copy configs
msg "Setting up configuration..."
mkdir -p "$CONFIG_DIR"

# Copy i3 config files
cp -r "$SCRIPT_DIR"/i3/* "$CONFIG_DIR"/ || die "Failed to copy i3 config"

# Configuration directories are already in the i3 folder, so we don't need to copy them separately

# Make scripts executable
find "$CONFIG_DIR"/scripts -type f -exec chmod +x {} \; 2>/dev/null || true

# Setup directories
xdg-user-dirs-update
mkdir -p ~/Screenshots

# Butterscript helper
get_script() {
    wget -qO- "https://codeberg.org/justaguylinux/butterscripts/raw/branch/main/$1" | bash
}

# Install essential components
if [ "$ONLY_CONFIG" = false ]; then
    mkdir -p "$TEMP_DIR" && cd "$TEMP_DIR"

    msg "Installing picom..."
    get_script "setup/install_picom.sh"

    msg "Installing wezterm..."
    get_script "wezterm/install_wezterm.sh"

    msg "Installing st terminal..."
    wget -O "$TEMP_DIR/install_st.sh" "https://codeberg.org/justaguylinux/butterscripts/raw/branch/main/st/install_st.sh"
    chmod +x "$TEMP_DIR/install_st.sh"
    # Run in current terminal session to preserve interactivity
    bash "$TEMP_DIR/install_st.sh"

    msg "Installing fonts..."
    get_script "theming/install_nerdfonts.sh"

    msg "Installing themes..."
    get_script "theming/install_theme.sh"
    
    msg "Downloading wallpaper directory..."
    cd "$CONFIG_DIR"
    git clone --depth 1 --filter=blob:none --sparse https://codeberg.org/justaguylinux/butterscripts.git "$TEMP_DIR/butterscripts-wallpaper" || die "Failed to clone butterscripts"
    cd "$TEMP_DIR/butterscripts-wallpaper"
    git sparse-checkout set wallpaper || die "Failed to set sparse-checkout"
    cp -r wallpaper "$CONFIG_DIR"/ || die "Failed to copy wallpaper directory"

    msg "Downloading display manager installer..."
    wget -O "$TEMP_DIR/install_lightdm.sh" "https://codeberg.org/justaguylinux/butterscripts/raw/branch/main/system/install_lightdm.sh"
    chmod +x "$TEMP_DIR/install_lightdm.sh"
    msg "Running display manager installer..."
    # Run in current terminal session to preserve interactivity
    bash "$TEMP_DIR/install_lightdm.sh"

 # Optional tools
    clear
    read -p "Install optional tools (browsers, editors, etc)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        msg "Downloading optional tools installer..."
        wget -O "$TEMP_DIR/optional_tools.sh" "https://codeberg.org/justaguylinux/butterscripts/raw/branch/main/setup/optional_tools.sh"
        chmod +x "$TEMP_DIR/optional_tools.sh"
        msg "Running optional tools installer..."
        # Run in current terminal session to preserve interactivity
        if bash "$TEMP_DIR/optional_tools.sh"; then
            msg "Optional tools completed successfully"
        else
            msg "Optional tools exited (this is normal if cancelled by user)"
        fi
    fi
else
    msg "Skipping external tool installation (--only-config mode)"
fi

# Done
echo -e "\n${GREEN}Installation complete!${NC}"
echo "1. Log out and select 'i3' from your display manager"
echo "2. Press Super+H for keybindings"
