# 🧁 Muffin

Muffin is a lightweight, zero-dependency portable application runtime and packaging format for local web applications (`.mpa`).

Instead of bundling a massive browser engine with every single app like Electron does, Muffin uses your system's existing native Webkit GTK engine. It packages any standard website or web application directory into a single portable ZIP archive (renamed to `.mpa`), handles automatic system application-menu integration (with custom icons), and respects system-wide dark/light mode configurations.

## ✨ Features

* 📦 **Ultra-Lightweight:** Portable apps are just zipped web directories (with an `.mpa` extension). A basic app can be as small as a few kilobytes.

* 🖥️ **Desktop Native Integration:** Automatically generates `.desktop` shortcuts with custom `icon.png` files, placing your web apps directly in your system's applications menu.

* 🌓 **Dynamic System Theming:** The Webview frame automatically detects and respects your system-wide dark or light mode preferences (supports GNOME, KDE, etc.).

* 🌐 **Muffin Maker (`muffin-make`):** Quickly scrape and package any online web application, **or package local HTML/JS projects**, into an offline portable desktop app.

* 🗑️ **Clean Uninstallation:** Built-in `delete` utility to fully wipe shortcuts, cached files, icons, and library `.mpa` files.

* 🔌 **Auto-Dependency Resolution:** The core script automatically detects your active package manager (`dnf`, `apt`, `pacman`, or `zypper`) and installs the required light-weight system libraries for you.

## 📥 Installation

Simply clone this repository and run the installer script. It will copy the binaries into your local `~/bin` directory and help you set up your system path if needed.

```bash
# Clone the repository
git clone [https://github.com/yourusername/muffin.git](https://github.com/yourusername/muffin.git)
cd muffin

# Make the installer executable and run it
chmod +x install.sh
./install.sh
