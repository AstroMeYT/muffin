#!/usr/bin/env bash

# Muffin - Portable Web App Runner & Installer
# Usage: 
#   muffin run <path/to/app.mpa_or_app_name>
#   muffin delete <path/to/app.mpa_or_app_name>

# Function to display errors and exit
die() {
    echo "Error: $1" >&2
    exit 1
}

install_dependencies() {
    if command -v dnf >/dev/null 2>&1; then
        echo "Detected dnf (Fedora/RHEL). Installing dependencies..."
        sudo dnf install -y python3-gobject webkit2gtk4.1 unzip
    elif command -v apt-get >/dev/null 2>&1; then
        echo "Detected apt (Debian/Ubuntu). Installing dependencies..."
        sudo apt-get update
        sudo apt-get install -y python3-gi gir1.2-webkit2-4.1 unzip || sudo apt-get install -y python3-gi gir1.2-webkit2-4.0 unzip
    elif command -v pacman >/dev/null 2>&1; then
        echo "Detected pacman (Arch Linux). Installing dependencies..."
        sudo pacman -S --needed --noconfirm python-gobject webkit2gtk-4.1 unzip
    elif command -v zypper >/dev/null 2>&1; then
        echo "Detected zypper (openSUSE). Installing dependencies..."
        sudo zypper install -y python3-gobject typelib-1_0-WebKit2-4_1 unzip
    else
        die "Could not detect your package manager. Please manually install unzip, Python3 GObject, and WebKit2GTK."
    fi
}

check_dependencies() {
    local missing=0

    # Check for base binaries
    if ! command -v unzip >/dev/null 2>&1; then missing=1; fi
    if ! command -v python3 >/dev/null 2>&1; then missing=1; fi
    
    # Check for specific python bindings without failing the script yet
    if [ $missing -eq 0 ]; then
        if ! python3 -c "import gi" 2>/dev/null; then
            missing=1
        elif ! (python3 -c "import gi; gi.require_version('WebKit2', '4.1')" 2>/dev/null || python3 -c "import gi; gi.require_version('WebKit2', '4.0')" 2>/dev/null); then
            missing=1
        fi
    fi

    if [ $missing -eq 1 ]; then
        echo "Missing required system dependencies. Attempting auto-install..."
        install_dependencies
        
        # Final sanity check after install
        if ! command -v unzip >/dev/null 2>&1 || ! python3 -c "import gi" 2>/dev/null; then
            die "Auto-install failed. Please install dependencies manually."
        fi
    fi
}

# Verify arguments
if { [ "$1" != "run" ] && [ "$1" != "delete" ]; } || [ -z "$2" ]; then
    echo "Muffin Portable Archive Launcher & Manager"
    echo "Usage:"
    echo "  muffin run <path/to/app.mpa_or_app_name>"
    echo "  muffin delete <path/to/app.mpa_or_app_name>"
    exit 1
fi

COMMAND="$1"
INPUT_ARG="$2"
MUFFIN_LIB="$HOME/.local/share/muffin/library"

# Extract the clean application name (stripping paths and extensions)
APP_NAME=$(basename "$INPUT_ARG" .mpa)

# --- DELETE COMMAND LOGIC ---
if [ "$COMMAND" = "delete" ]; then
    echo "Uninstalling Muffin App: $APP_NAME"
    
    DESKTOP_FILE="$HOME/.local/share/applications/muffin-$APP_NAME.desktop"
    APP_DIR="$HOME/.local/share/muffin/apps/$APP_NAME"
    LIBRARY_MPA="$MUFFIN_LIB/${APP_NAME}.mpa"
    
    deleted_any=false

    # Remove the system shortcut
    if [ -f "$DESKTOP_FILE" ]; then
        rm -f "$DESKTOP_FILE"
        echo "  - Removed application menu shortcut."
        deleted_any=true
    fi

    # Remove any registered system menu icons matching this app (handles various extensions)
    for ext in png svg ico jpeg gif; do
        SYSTEM_ICON_DEST="$HOME/.local/share/icons/muffin-$APP_NAME.$ext"
        if [ -f "$SYSTEM_ICON_DEST" ]; then
            rm -f "$SYSTEM_ICON_DEST"
            echo "  - Removed application icon (.$ext)."
            deleted_any=true
        fi
    done

    # Remove extracted application runtime cache files
    if [ -d "$APP_DIR" ]; then
        rm -rf "$APP_DIR"
        echo "  - Cleaned extracted application files."
        deleted_any=true
    fi

    # Remove the .mpa package ONLY if it resides in Muffin's default library directory
    if [ -f "$LIBRARY_MPA" ]; then
        rm -f "$LIBRARY_MPA"
        echo "  - Deleted package from Muffin library ($LIBRARY_MPA)."
        deleted_any=true
    fi

    if [ "$deleted_any" = true ]; then
        # Force GNOME/KDE/XFCE to reload the applications menu cache immediately
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$HOME/.local/share/applications"
        fi
        echo "Successfully deleted '$APP_NAME'."
    else
        echo "No installed components found for app '$APP_NAME'."
    fi
    exit 0
fi

# --- RUN COMMAND LOGIC ---

# Only run dependency checks when executing an application
check_dependencies

MPA_FILE=""

# Resolve Application Path
# Check if the input is a direct file path, otherwise look inside the Muffin Library
if [ -f "$INPUT_ARG" ]; then
    MPA_FILE="$INPUT_ARG"
elif [ -f "$MUFFIN_LIB/$INPUT_ARG" ]; then
    MPA_FILE="$MUFFIN_LIB/$INPUT_ARG"
elif [ -f "$MUFFIN_LIB/${INPUT_ARG}.mpa" ]; then
    MPA_FILE="$MUFFIN_LIB/${INPUT_ARG}.mpa"
else
    die "Could not find application '$INPUT_ARG' locally or in your library ($MUFFIN_LIB)."
fi

# Convert to absolute path so the .desktop file always works
if [[ "$MPA_FILE" != /* ]]; then
    MPA_FILE="$(pwd)/$MPA_FILE"
fi

# Setup Muffin base directories
MUFFIN_DIR="$HOME/.local/share/muffin"
APP_DIR="$MUFFIN_DIR/apps/$APP_NAME"
PYTHON_RUNNER="$MUFFIN_DIR/runner.py"

mkdir -p "$APP_DIR"
mkdir -p "$HOME/.local/share/icons"
mkdir -p "$HOME/.local/share/applications"

# 1. Extract the .mpa archive
echo "Loading $APP_NAME..."
# Clear out the old directory to avoid mixed files if updating
rm -rf "$APP_DIR"/*
# Unzip silently, overwriting files (-o) in case the .mpa was updated
unzip -q -o "$MPA_FILE" -d "$APP_DIR" || die "Failed to extract $MPA_FILE. Is it a valid zip archive?"

# Handle nested archive directory structures (if zipped folder directly instead of folder contents)
INDEX_PATH=$(find "$APP_DIR" -maxdepth 3 -name "index.html" | head -n 1)
if [ -n "$INDEX_PATH" ]; then
    INDEX_DIR=$(dirname "$INDEX_PATH")
    if [ "$INDEX_DIR" != "$APP_DIR" ]; then
        echo "Normalizing nested directory structure..."
        # Safely move everything up a level
        shopt -s dotglob
        mv "$INDEX_DIR"/* "$APP_DIR/" 2>/dev/null
        shopt -u dotglob
        # Clean up any empty directory leftovers
        find "$APP_DIR" -mindepth 1 -type d -empty -delete
    fi
else
    die "Invalid Muffin App: index.html is missing anywhere in the archive."
fi

# 2. Handle Icon and Desktop Shortcut
# Look for standard icon.png, fallback to any file starting with 'favicon.' (any extension)
ICON_PATH=""
if [ -f "$APP_DIR/icon.png" ]; then
    ICON_PATH="$APP_DIR/icon.png"
else
    # Locate any file starting with 'favicon.' in the root extracted folder (case-insensitive)
    FAVICON_PATH=$(find "$APP_DIR" -maxdepth 2 -iname "favicon.*" | head -n 1)
    if [ -n "$FAVICON_PATH" ]; then
        ICON_PATH="$FAVICON_PATH"
    fi
fi

DESKTOP_FILE="$HOME/.local/share/applications/muffin-$APP_NAME.desktop"

# Check if shortcut exists, if not, create it
if [ ! -f "$DESKTOP_FILE" ]; then
    echo "Adding $APP_NAME to system applications menu..."
    
    # Process icon setup dynamically supporting any source extension
    if [ -n "$ICON_PATH" ]; then
        ICON_EXT="${ICON_PATH##*.}"
        SYSTEM_ICON_DEST="$HOME/.local/share/icons/muffin-$APP_NAME.$ICON_EXT"
        cp "$ICON_PATH" "$SYSTEM_ICON_DEST"
        ICON_LINE="Icon=$SYSTEM_ICON_DEST"
    else
        echo "Warning: Neither icon.png nor favicon file was found in archive. Using default system icon."
        ICON_LINE="Icon=application-x-executable"
    fi

    # Find where the muffin command actually lives to put in the Exec line
    MUFFIN_BIN=$(command -v muffin)
    if [ -z "$MUFFIN_BIN" ]; then
        # Fallback if muffin isn't in PATH yet
        MUFFIN_BIN="$HOME/bin/muffin" 
    fi

    # Generate .desktop file
    cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=$APP_NAME
Exec=$MUFFIN_BIN run "$MPA_FILE"
$ICON_LINE
Terminal=false
Categories=Utility;
Comment=Muffin Portable App
EOF
    
    chmod +x "$DESKTOP_FILE"
    
    # Update desktop database so the menu refreshes immediately
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications"
    fi
fi

# 3. Create or update the Python Webview Runner (always overwrite to ensure latest features/bugfixes run)
cat << 'EOF' > "$PYTHON_RUNNER"
#!/usr/bin/env python3
import sys
import os

try:
    import gi
    gi.require_version('Gtk', '3.0')
    # Try WebKit2 version 4.1 first (newer Linux), fallback to 4.0
    try:
        gi.require_version('WebKit2', '4.1')
    except ValueError:
        gi.require_version('WebKit2', '4.0')
        
    from gi.repository import Gtk, WebKit2, Gio
except ImportError:
    print("Error: Missing Python GTK/WebKit2 dependencies.")
    print("Please ensure python3-gi and gir1.2-webkit2-4.0 (or 4.1) are installed.")
    sys.exit(1)

if len(sys.argv) < 3:
    print("Usage: runner.py <Title> <URL>")
    sys.exit(1)

app_title = sys.argv[1]
app_url = sys.argv[2]

def apply_system_theme():
    """Detects system color scheme and applies dark theme styling to GTK window if enabled."""
    try:
        settings = Gtk.Settings.get_default()
        
        # 1. Attempt to check the GNOME/FreeDesktop portal color-scheme
        try:
            gsettings = Gio.Settings.new("org.gnome.desktop.interface")
            color_scheme = gsettings.get_string("color-scheme")
            if "dark" in color_scheme.lower():
                settings.set_property("gtk-application-prefer-dark-theme", True)
                return
        except Exception:
            pass

        # 2. Fallback to checking active GTK theme name
        try:
            theme_name = settings.get_property("gtk-theme-name")
            if "dark" in theme_name.lower():
                settings.set_property("gtk-application-prefer-dark-theme", True)
                return
        except Exception:
            pass
    except Exception:
        pass

class MuffinWindow(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title=app_title)
        self.set_default_size(1024, 768)
        
        # Position in center of screen
        self.set_position(Gtk.WindowPosition.CENTER)

        self.webview = WebKit2.WebView()
        self.webview.load_uri(app_url)
        
        self.add(self.webview)
        self.connect("destroy", Gtk.main_quit)
        self.show_all()

if __name__ == "__main__":
    apply_system_theme()
    app = MuffinWindow()
    Gtk.main()
EOF
chmod +x "$PYTHON_RUNNER"

# 4. Launch the application
TARGET_URL="file://$APP_DIR/index.html"
exec "$PYTHON_RUNNER" "$APP_NAME" "$TARGET_URL"