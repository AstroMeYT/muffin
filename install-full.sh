#!/usr/bin/env bash

# Muffin Full Environment Installer
# Designed to download and install 'muffin', 'muffin-make', and 'muffin-gui' into ~/.local/bin and configure $PATH.

# Terminal colors for a premium installer feel
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BLUE}${BOLD}==================================================${NC}"
echo -e "${GREEN}${BOLD}         Muffin Full Installer Engine             ${NC}"
echo -e "${BLUE}${BOLD}==================================================${NC}"

# Define target directories
BIN_DIR="$HOME/.local/bin"
OLD_BIN_DIR="$HOME/bin"
DESKTOP_DIR="$HOME/.local/share/applications"

# URLs for the files
MUFFIN_URL="https://raw.githubusercontent.com/AstroMeYT/muffin/refs/heads/main/muffin"
MUFFIN_MAKE_URL="https://raw.githubusercontent.com/AstroMeYT/muffin/refs/heads/main/muffin-make"
MUFFIN_GUI_URL="https://raw.githubusercontent.com/AstroMeYT/muffin/refs/heads/main/muffin-gui"

# 1. Ensure target directories exist
if [ ! -d "$BIN_DIR" ]; then
    echo -e "${YELLOW}Creating local binary directory at $BIN_DIR...${NC}"
    mkdir -p "$BIN_DIR" || { echo -e "${RED}Error: Failed to create $BIN_DIR.${NC}"; exit 1; }
fi

if [ ! -d "$DESKTOP_DIR" ]; then
    mkdir -p "$DESKTOP_DIR"
fi

# Determine downloader
if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl -fsSL -o"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget -qO"
else
    echo -e "${RED}Error: Neither 'curl' nor 'wget' is installed. Please install one of them to proceed.${NC}"
    exit 1
fi

# Check if Muffin is already installed
if [ -f "$BIN_DIR/muffin" ] || [ -f "$BIN_DIR/muffin-make" ] || [ -f "$OLD_BIN_DIR/muffin" ]; then
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
            echo -e "  [1] Remove scripts only ('muffin', 'muffin-make', 'muffin-gui')"
            echo -e "  [2] Complete purge (Scripts, all installed apps, caches, icons, and library files)"
            echo -e "  [c] Cancel"
            read -p "Choose an option (1/2/c): " un_choice
            
            case "$un_choice" in
                1)
                    echo -e "\n${YELLOW}Removing scripts...${NC}"
                    rm -f "$BIN_DIR/muffin" "$BIN_DIR/muffin-make" "$BIN_DIR/muffin-gui"
                    rm -f "$OLD_BIN_DIR/muffin" "$OLD_BIN_DIR/muffin-make"
                    rm -f "$DESKTOP_DIR/org.muffin.GUI.desktop"
                    echo -e "${GREEN}✓ Scripts and shortcuts removed.${NC}"
                    exit 0
                    ;;
                2)
                    echo -e "\n${YELLOW}Purging all Muffin files...${NC}"
                    rm -f "$BIN_DIR/muffin" "$BIN_DIR/muffin-make" "$BIN_DIR/muffin-gui"
                    rm -f "$OLD_BIN_DIR/muffin" "$OLD_BIN_DIR/muffin-make"
                    echo -e "  - Scripts removed."
                    
                    if [ -d "$HOME/.local/share/muffin" ]; then
                        rm -rf "$HOME/.local/share/muffin"
                        echo -e "  - App cache and library removed."
                    fi
                    
                    # Safely find and delete Muffin-specific desktop shortcuts
                    find "$HOME/.local/share/applications" -name "muffin-*.desktop" -delete 2>/dev/null
                    find "$HOME/.local/share/applications" -name "org.muffin.GUI.desktop" -delete 2>/dev/null
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

# 2. Download files directly to bin directory
echo -e "\n${BLUE}Downloading files from GitHub...${NC}"

echo -n "  Downloading muffin... "
if $DOWNLOADER "$BIN_DIR/muffin" "$MUFFIN_URL"; then
    chmod +x "$BIN_DIR/muffin"
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Failed!${NC}"
    exit 1
fi

echo -n "  Downloading muffin-make... "
if $DOWNLOADER "$BIN_DIR/muffin-make" "$MUFFIN_MAKE_URL"; then
    chmod +x "$BIN_DIR/muffin-make"
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Failed!${NC}"
    exit 1
fi

echo -n "  Downloading muffin-gui... "
if $DOWNLOADER "$BIN_DIR/muffin-gui" "$MUFFIN_GUI_URL"; then
    chmod +x "$BIN_DIR/muffin-gui"
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Failed!${NC}"
    exit 1
fi

# 3. Create desktop entry for GUI
echo -n "  Creating desktop entry... "
cat <<EOF > "$DESKTOP_DIR/org.muffin.GUI.desktop"
[Desktop Entry]
Name=Muffin Manager
Comment=Graphical manager for Muffin portable web apps
Exec=$BIN_DIR/muffin-gui
Icon=application-x-muffin-portable-archive
Terminal=false
Type=Application
Categories=Utility;
StartupNotify=true
EOF

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null
fi
echo -e "${GREEN}✓${NC}"


# 4. Check if ~/.local/bin is in user's $PATH
path_configured=false
if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
    path_configured=true
fi

if [ "$path_configured" = true ]; then
    echo -e "\n${GREEN}${BOLD}✓ $BIN_DIR is already in your PATH environment variable!${NC}"
else
    echo -e "\n${YELLOW}${BOLD}⚠️  Action Required: $BIN_DIR is not in your system PATH.${NC}"
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
        read -p "Would you like this installer to automatically add $BIN_DIR to your PATH in this file? [Y/n] " -n 1 -r
        echo "" # New line
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            echo -e "\n# Added by Muffin Installer\nexport PATH=\"$BIN_DIR:\$PATH\"" >> "$RC_FILE"
            echo -e "${GREEN}✓ Successfully appended PATH export to $RC_FILE!${NC}"
            echo -e "${YELLOW}Please restart your terminal or run: ${BOLD}source $RC_FILE${NC}"
            path_configured=true
        fi
    fi

    # Manual instructions if they declined or have an unidentifiable shell
    if [ "$path_configured" = false ]; then
        echo -e "\n${BOLD}To manually add it, append this line to your shell configuration file:${NC}"
        echo -e "  ${BLUE}export PATH=\"$BIN_DIR:\$PATH\"${NC}"
    fi
fi

echo -e "\n${BLUE}${BOLD}==================================================${NC}"
echo -e "${GREEN}${BOLD}          Muffin successfully installed!           ${NC}"
echo -e "${BLUE}${BOLD}==================================================${NC}"
echo -e "You can now launch the Muffin Manager from your app launcher,"
echo -e "or use the command line:"
echo -e "  ${BOLD}muffin-gui${NC}           (Launch the GUI manager)"
echo -e "  ${BOLD}muffin-make <URL> <app-name>${NC}  (Make a new app via CLI)"
echo -e "  ${BOLD}muffin run <app-name>${NC}         (Launch an app via CLI)"
echo -e "${BLUE}${BOLD}==================================================${NC}"
