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

# Install Hack Nerd Font
echo -e "${GREEN}📦 Installing Hack Nerd Font...${NC}"

FONT_DIR="$HOME/.local/share/fonts"
TEMP_DIR="/tmp/hack-nerd-font"

# Create fonts directory if it doesn't exist
mkdir -p "$FONT_DIR"
mkdir -p "$TEMP_DIR"

# Download and install Hack Nerd Font
echo -e "${CYAN}   Downloading Hack Nerd Font...${NC}"
cd "$TEMP_DIR"
wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip

echo -e "${CYAN}   Extracting font files...${NC}"
unzip -q Hack.zip -d Hack

echo -e "${CYAN}   Installing fonts...${NC}"
cp Hack/*.ttf "$FONT_DIR/"

# Refresh font cache
echo -e "${CYAN}   Refreshing font cache...${NC}"
fc-cache -fv > /dev/null 2>&1

echo -e "${GREEN}✅ Hack Nerd Font installed successfully!${NC}"

# Clean up
rm -rf "$TEMP_DIR"

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
echo -e "${NC}1. Configure your terminal to use 'Hack Nerd Font Mono'${NC}"

if [ "$IS_WSL" = true ]; then
    echo -e "${NC}   For Windows Terminal:${NC}"
    echo -e "${NC}   Settings → Profiles → Ubuntu/Your WSL → Appearance → Font face → 'Hack Nerd Font Mono'${NC}"
fi

echo -e ""
echo -e "${NC}2. Reload your shell configuration:${NC}"
echo -e "${NC}   source ~/.zshrc${NC}"
echo -e ""
echo -e "${NC}3. Or simply restart your terminal${NC}"
echo -e ""

if [ ! -f "$HOME/.config/starship.toml" ]; then
    echo -e "${YELLOW}⚠️  No starship.toml found. Creating default configuration...${NC}"
    
    cat > "$HOME/.config/starship.toml" << 'STARSHIP_CONFIG'
# ~/.config/starship.toml
# Inserts a blank line between shell prompts
add_newline = true

# Change the default prompt format
format = """
[╭╴](238)$os$username$hostname$directory$git_branch$git_status$docker_context$kubernetes$terraform$python$nodejs$ruby
[╰─](238)$character"""

# Change the default prompt characters
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

# Shows an icon that should be included by zshrc script based on the distribution or os
[os]
disabled = false

# Shows the username
[username]
style_user = "white bold"
style_root = "black bold"
format = "[$user]($style) "
disabled = false
show_always = true

# Shows the hostname
[hostname]
ssh_only = false
format = "on [$hostname](bold yellow) "
disabled = false

# Shows the directory
[directory]
truncation_length = 3
truncation_symbol = "…/"
home_symbol = "🏠 ~"
read_only_style = "197"
read_only = " 🔒"
format = "at [$path]($style)[$read_only]($read_only_style) "

# Shows the git branch
[git_branch]
symbol = " "
format = "via [$symbol$branch]($style) "
truncation_length = 4
truncation_symbol = "…/"
style = "bold green"

# Shows the git status
[git_status]
format = '[\($all_status$ahead_behind\)]($style) '
conflicted = "🏳"
up_to_date = "✓"
untracked = "🤷"
ahead = "⇡${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
behind = "⇣${count}"
stashed = "📦"
modified = "📝"
staged = '[++\($count\)](green)'
renamed = "👅"
deleted = "🗑"

# Shows kubernetes context and namespace
[kubernetes]
format = 'via [⎈ $context\($namespace\)](bold purple) '
disabled = false
[kubernetes.context_aliases]
"clcreative-k8s-staging" = "cl-k8s-staging"
"clcreative-k8s-production" = "cl-k8s-prod"

# Shows the terraform workspace
[terraform]
format = "via [🏗️ $workspace]($style) "

# Shows the vagrant version
[vagrant]
format = "via [⍱ $version](bold white) "

# Shows the docker context
[docker_context]
format = "via [🐋 $context](bold blue) "

# Shows the helm context
[helm]
format = "via [⎈ $version](bold purple) "

# Python
[python]
symbol = "🐍 "
python_binary = "python3"
format = 'via [${symbol}${pyenv_prefix}(${version} )(\($virtualenv\) )]($style)'

# Node.js
[nodejs]
format = "via [⬢ $version](bold green) "
disabled = false

# Ruby
[ruby]
format = "via [💎 $version](bold red) "
STARSHIP_CONFIG

    echo -e "${GREEN}✅ Default starship.toml created!${NC}"
    echo -e ""
fi

echo -e "${CYAN}Enjoy your new terminal! 🚀${NC}"
echo ""
