#!/usr/bin/env bash

set -e

echo "Installing Muffin Manager GUI..."

# Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

# Link or copy the GUI script
ln -sf "$(realpath muffin-gui)" "$HOME/.local/bin/muffin-gui"

# Install Desktop file
mkdir -p "$HOME/.local/share/applications"
cp org.muffin.GUI.desktop "$HOME/.local/share/applications/"
sed -i "s|Exec=muffin-gui|Exec=$HOME/.local/bin/muffin-gui|g" "$HOME/.local/share/applications/org.muffin.GUI.desktop"

# Refresh desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications"
fi

echo "Muffin Manager GUI installed successfully!"
