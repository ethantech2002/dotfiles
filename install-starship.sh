#!/bin/bash

# Starship Linux/WSL Installation Script
# This script installs Starship, Hack Nerd Font, and configures your zsh shell

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================"
echo -e "  Starship Installation for Linux/WSL  "
echo -e "========================================${NC}"
echo ""

# Check if running in WSL
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    echo -e "${GREEN}✓ Running in WSL${NC}"
    IS_WSL=true
else
    echo -e "${GREEN}✓ Running in Linux${NC}"
    IS_WSL=false
fi

echo ""

# Install Starship
echo -e "${GREEN}📦 Installing Starship...${NC}"
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    echo -e "${GREEN}✅ Starship installed successfully!${NC}"
else
    echo -e "${YELLOW}ℹ️  Starship is already installed.${NC}"
fi

echo ""

# Install required tools if not present
echo -e "${GREEN}📦 Checking for required tools...${NC}"

# Check for zsh
if ! command -v zsh &> /dev/null; then
    echo -e "${YELLOW}   Installing zsh...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y zsh
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y zsh
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm zsh
    else
        echo -e "${RED}❌ Cannot install zsh automatically. Please install it manually.${NC}"
        exit 1
    fi
fi

# Check for exa (modern ls replacement)
if ! command -v exa &> /dev/null; then
    echo -e "${YELLOW}   Installing exa...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y exa
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y exa
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm exa
    else
        echo -e "${YELLOW}⚠️  Could not install exa. You may need to install it manually.${NC}"
    fi
fi

echo ""

# Prompt for custom starship config repo
echo -e "${CYAN}📥 Do you want to clone your custom Starship config repository?${NC}"
echo -e "${CYAN}   Enter the Git repository URL (or press Enter to skip):${NC}"
read -r REPO_URL

if [ -n "$REPO_URL" ]; then
    echo -e "${CYAN}   Cloning repository...${NC}"
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}   Installing git...${NC}"
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y git
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y git
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm git
        fi
    fi
    
    TEMP_REPO_PATH="/tmp/starship-config"
    rm -rf "$TEMP_REPO_PATH"
    
    if git clone "$REPO_URL" "$TEMP_REPO_PATH"; then
        mkdir -p "$HOME/.config"
        
        # Look for starship.toml in common locations
        if [ -f "$TEMP_REPO_PATH/starship.toml" ]; then
            cp "$TEMP_REPO_PATH/starship.toml" "$HOME/.config/starship.toml"
            echo -e "${GREEN}✅ Custom starship.toml copied successfully!${NC}"
        elif [ -f "$TEMP_REPO_PATH/.config/starship.toml" ]; then
            cp "$TEMP_REPO_PATH/.config/starship.toml" "$HOME/.config/starship.toml"
            echo -e "${GREEN}✅ Custom starship.toml copied successfully!${NC}"
        else
            echo -e "${YELLOW}⚠️  No starship.toml found in repository.${NC}"
            echo -e "${YELLOW}   Please manually copy your config to: $HOME/.config/starship.toml${NC}"
        fi
        
        rm -rf "$TEMP_REPO_PATH"
    else
        echo -e "${RED}❌ Failed to clone repository.${NC}"
        echo -e "${YELLOW}   You can manually download your config and place it at: $HOME/.config/starship.toml${NC}"
    fi
fi

echo ""

# Configure zsh
echo -e "${GREEN}⚙️  Configuring zsh...${NC}"

ZSHRC="$HOME/.zshrc"

# Create .zshrc if it doesn't exist
if [ ! -f "$ZSHRC" ]; then
    touch "$ZSHRC"
fi

# Check if Starship is already configured
if ! grep -q "starship init zsh" "$ZSHRC"; then
    # Add configuration to .zshrc
    cat >> "$ZSHRC" << 'EOF'

# Fix Interop Error that randomly occurs in vscode terminal when using WSL
fix_wsl_interop() {
    for i in {s,p,me}; do
        if [[ "$PSTREE" == *"$i"* ]] && grep -o '[0-9]' <<< "$i"; then
            export WSL_INTEROP=/mnt/wsl/$1/interop
        fi
    done
}

# Kubectl Functions
alias k='kubectl'
kns() {
    if [ "$1" != "" ]; then
        kubectl config set-context --current --namespace="$1"
        echo -e "\e[1;32m Namespace set to $1\e[0m"
    else
        echo -e "\e[1;31m Error, please provide a valid Namespace!\e[0m"
    fi
}
knd() {
    kubectl config unset current-context
    echo -e "\e[1;32m Unset kubernetes current-context\e[0m"
}

# Colormap
function colormap() {
    for i in {1..255}; do
        print -Px "${i} $(tput setaf $i)$1${2:-$(tput sgr0)}"
    done
}

# ALIAS COMMANDS
alias l='exa --icons --group-directories-first'
alias ll='exa --icons --group-directories-first -l'
alias g='goto'
alias grep='grep --color'

# Find out what distribution we are running on
_distro=$(awk '/ID=/ {print tolower($2)}' /etc/*release | awk -F'=' '{ print tolower($2) }')

# Set an icon based on the distro
# Make sure your font is compatible with https://github.com/lukas-w/font-logos
case $_distro in
    *kali*)                  ICON="ﴣ";;
    *arch*)                  ICON="";;
    *debian*)                ICON="";;
    *raspbian*)              ICON="";;
    *ubuntu*)                ICON="";;
    *elementary*)            ICON="";;
    *fedora*)                ICON="";;
    *coreos*)                ICON="";;
    *gentoo*)                ICON="";;
    *mageia*)                ICON="";;
    *centos*)                ICON="";;
    *opensuse*|*tumbleweed*) ICON="";;
    *sabayon*)               ICON="";;
    *slackware*)             ICON="";;
    *linuxmint*)             ICON="";;
    *alpine*)                ICON="";;
    *aosc*)                  ICON="";;
    *nixos*)                 ICON="";;
    *devuan*)                ICON="";;
    *manjaro*)               ICON="";;
    *rhel*)                  ICON="";;
    *macos*)                 ICON="";;
    *)                       ICON="";;
esac

export STARSHIP_DISTRO="$ICON "

# Load Starship
eval "$(starship init zsh)"
EOF

    echo -e "${GREEN}✅ zsh configured successfully!${NC}"
else
    echo -e "${YELLOW}ℹ️  Starship already configured in .zshrc${NC}"
fi

echo ""

# Set zsh as default shell if not already
if [ "$SHELL" != "$(which zsh)" ]; then
    echo -e "${CYAN}Would you like to set zsh as your default shell? (y/n)${NC}"
    read -r SET_ZSH_DEFAULT
    if [ "$SET_ZSH_DEFAULT" = "y" ] || [ "$SET_ZSH_DEFAULT" = "Y" ]; then
        chsh -s "$(which zsh)"
        echo -e "${GREEN}✅ zsh set as default shell${NC}"
    fi
fi

echo ""
echo -e "${GREEN}========================================"
echo -e "  ✨ Installation Complete! ✨"
echo -e "========================================${NC}"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo -e "${NC}1. Reload your shell configuration:${NC}"
echo -e "${NC}   source ~/.zshrc${NC}"
echo -e ""
echo -e "${NC}2. Or simply restart your terminal${NC}"
echo -e ""

if [ ! -f "$HOME/.config/starship.toml" ]; then
    echo -e "${YELLOW}⚠️  Note: If you haven't cloned your config yet, place your starship.toml at:${NC}"
    echo -e "${YELLOW}   $HOME/.config/starship.toml${NC}"
    echo -e ""
fi

echo -e "${CYAN}Enjoy your new terminal! 🚀${NC}"
echo ""
