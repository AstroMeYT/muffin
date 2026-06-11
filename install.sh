#!/usr/bin/env bash

# Copyright (c) 2026 Gatlin Nicholson
#
# This software is released under the MIT License.
# https://opensource.org

# Muffin Environment Installer
# Designed to install 'muffin' and 'muffin-make' into ~/bin and configure $PATH.

# Terminal colors for a premium installer feel
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BLUE}${BOLD}==================================================${NC}"
echo -e "${GREEN}${BOLD}             Muffin Installer Engine              ${NC}"
echo -e "${BLUE}${BOLD}==================================================${NC}"

# Define target directory
BIN_DIR="$HOME/bin"

# 1. Ensure target directory exists
if [ ! -d "$BIN_DIR" ]; then
    echo -e "${YELLOW}Creating local binary directory at $BIN_DIR...${NC}"
    mkdir -p "$BIN_DIR" || { echo -e "${RED}Error: Failed to create $BIN_DIR.${NC}"; exit 1; }
fi

# 2. Check for the source files in the current directory (cloned repository)
SRC_MUFFIN="./muffin"
SRC_MAKE="./muffin-make"

missing_source=false
if [ ! -f "$SRC_MUFFIN" ]; then
    echo -e "${RED}Error: '$SRC_MUFFIN' not found in the current directory.${NC}"
    missing_source=true
fi
if [ ! -f "$SRC_MAKE" ]; then
    echo -e "${RED}Error: '$SRC_MAKE' not found in the current directory.${NC}"
    missing_source=true
fi

if [ "$missing_source" = true ]; then
    echo -e "${YELLOW}Please run this installer script from the root of your cloned Muffin repository.${NC}"
    exit 1
fi

# Check if Muffin is already installed
if [ -f "$BIN_DIR/muffin" ] || [ -f "$BIN_DIR/muffin-make" ]; then
    echo -e "\n${YELLOW}${BOLD}Muffin is already installed on this system.${NC}"
    echo -e "  [1] Update / Reinstall files"
    echo -e "  [2] Uninstall Muffin"
    echo -e "  [c] Cancel"
    read -p "Choose an option (1/2/c): " inst_choice
    
    case "$inst_choice" in
        1)
            echo -e "\n${BLUE}Proceeding with Update...${NC}"
            ;;
        2)
            echo -e "\n${YELLOW}${BOLD}Uninstall Options:${NC}"
            echo -e "  [1] Remove scripts only ('muffin' and 'muffin-make')"
            echo -e "  [2] Complete purge (Scripts, all installed apps, caches, icons, and library files)"
            echo -e "  [c] Cancel"
            read -p "Choose an option (1/2/c): " un_choice
            
            case "$un_choice" in
                1)
                    echo -e "\n${YELLOW}Removing scripts...${NC}"
                    rm -f "$BIN_DIR/muffin" "$BIN_DIR/muffin-make"
                    echo -e "${GREEN}✓ Scripts removed.${NC}"
                    exit 0
                    ;;
                2)
                    echo -e "\n${YELLOW}Purging all Muffin files...${NC}"
                    rm -f "$BIN_DIR/muffin" "$BIN_DIR/muffin-make"
                    echo -e "  - Scripts removed."
                    
                    if [ -d "$HOME/.local/share/muffin" ]; then
                        rm -rf "$HOME/.local/share/muffin"
                        echo -e "  - App cache and library removed."
                    fi
                    
                    # Safely find and delete Muffin-specific desktop shortcuts
                    find "$HOME/.local/share/applications" -name "muffin-*.desktop" -delete 2>/dev/null
                    echo -e "  - Desktop shortcuts removed."
                    
                    # Safely find and delete Muffin-specific icons
                    find "$HOME/.local/share/icons" -maxdepth 1 -name "muffin-*" -delete 2>/dev/null
                    echo -e "  - Icons removed."
                    
                    # Refresh the system's application cache so icons disappear immediately
                    if command -v update-desktop-database >/dev/null 2>&1; then
                        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null
                    fi
                    
                    echo -e "${GREEN}✓ Complete purge successful. We're sorry to see you go!${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "Cancelled. Exiting."
                    exit 0
                    ;;
            esac
            ;;
        *)
            echo -e "Cancelled. Exiting."
            exit 0
            ;;
    esac
fi

# 3. Copy and set executable permissions
echo -e "Installing scripts to ${BOLD}$BIN_DIR${NC}..."

cp "$SRC_MUFFIN" "$BIN_DIR/muffin" && chmod +x "$BIN_DIR/muffin"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} Installed ${BOLD}muffin${NC}"
else
    echo -e "  ${RED}✗${NC} Failed to install muffin"
    exit 1
fi

cp "$SRC_MAKE" "$BIN_DIR/muffin-make" && chmod +x "$BIN_DIR/muffin-make"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} Installed ${BOLD}muffin-make${NC}"
else
    echo -e "  ${RED}✗${NC} Failed to install muffin-make"
    exit 1
fi

# 4. Check if ~/bin is in user's $PATH
path_configured=false
if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
    path_configured=true
fi

if [ "$path_configured" = true ]; then
    echo -e "${GREEN}${BOLD}✓ ~/bin is already in your PATH environment variable!${NC}"
else
    echo -e "\n${YELLOW}${BOLD}⚠️  Action Required: ~/bin is not in your system PATH.${NC}"
    echo -e "To run 'muffin' from anywhere without typing its full directory path, it needs to be added."

    # Identify the user's default shell config file
    SHELL_NAME=$(basename "$SHELL")
    RC_FILE=""
    
    case "$SHELL_NAME" in
        bash)
            if [ -f "$HOME/.bashrc" ]; then
                RC_FILE="$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                RC_FILE="$HOME/.bash_profile"
            fi
            ;;
        zsh)
            RC_FILE="$HOME/.zshrc"
            ;;
        ksh)
            RC_FILE="$HOME/.kshrc"
            ;;
    esac

    # Auto-injection helper
    if [ -n "$RC_FILE" ]; then
        echo -e "\nDetected your shell profile config file at: ${BOLD}$RC_FILE${NC}"
        read -p "Would you like this installer to automatically add ~/bin to your PATH in this file? [Y/n] " -n 1 -r
        echo "" # New line
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            echo -e "\n# Added by Muffin Installer\nexport PATH=\"\$HOME/bin:\$PATH\"" >> "$RC_FILE"
            echo -e "${GREEN}✓ Successfully appended PATH export to $RC_FILE!${NC}"
            echo -e "${YELLOW}Please restart your terminal or run: ${BOLD}source $RC_FILE${NC}"
            path_configured=true
        fi
    fi

    # Manual instructions if they declined or have an unidentifiable shell
    if [ "$path_configured" = false ]; then
        echo -e "\n${BOLD}To manually add it, append this line to your shell configuration file:${NC}"
        echo -e "  ${BLUE}export PATH=\"\$HOME/bin:\$PATH\"${NC}"
    fi
fi

echo -e "${BLUE}${BOLD}==================================================${NC}"
echo -e "${GREEN}${BOLD}          Muffin successfully installed!           ${NC}"
echo -e "${BLUE}${BOLD}==================================================${NC}"
echo -e "To make a new portable app from a URL:"
echo -e "  ${BOLD}muffin-make <URL> <app-name>${NC}"
echo -e "To launch it:"
echo -e "  ${BOLD}muffin run <app-name>${NC}"
echo -e "${BLUE}${BOLD}==================================================${NC}"
