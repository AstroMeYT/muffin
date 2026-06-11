# 🧁 Muffin

Website: [Open Website](https://sites.google.com/view/Muffin-Portable)

Pre-built MPA Repo: [Open Repository](https://github.com/AstroMeYT/MPA-repo)

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
# Install with one command for all systems besides Arch
curl -fsSL https://raw.githubusercontent.com/AstroMeYT/muffin/refs/heads/main/install-full.sh | sh

```

*Note: If the installer asks to append `~/bin` to your system PATH, type `y` (or Enter) to complete the setup.*

## 🚀 How to Use

### 1. Build an App (`muffin-make`)

You can turn any live website **or** local project folder into an offline desktop application using the `muffin-make` utility. This utility automatically gathers the files, assigns an icon, packages the `.mpa` file, and adds it directly to your launcher library.

**Option A: Package from a URL**

```bash
# Usage: muffin-make url <URL> [custom-app-name]
muffin-make url [https://rawg.io](https://rawg.io) rawg-games

```

**Option B: Package from a Local Folder**

```bash
# Usage: muffin-make folder <path/to/folder> [custom-app-name]
muffin-make folder ~/Projects/calculator my-calculator

```

### 2. Run a Muffin Application (`muffin`)

To run a portable app, you can pass its clean name (if it's in your local library) or point it directly to a downloaded `.mpa` file path.

```bash
# Run an app installed in your local library
muffin run rawg-games

# Run a standalone .mpa file from anywhere
muffin run ~/Downloads/calculator.mpa

```

### 3. Uninstall/Delete an Application

To cleanly remove an application from your desktop launcher, delete its icon caches, and wipe it from your library:

```bash
muffin delete rawg-games

```

## 🛠️ The `.mpa` File Architecture

A `.mpa` (Muffin Portable Archive) is literally just a `.zip` archive renamed to `.mpa`.

For Muffin to parse and run your custom application correctly, ensure your archive contains at least an `index.html` at its core:

```text
your-app.mpa (ZIP Archive)
├── index.html       <-- The main application entrypoint (required)
├── favicon.png         <-- Application menu icon (optional, recommended)
├── styles.css       <-- Local stylesheet
├── app.js           <-- Local JavaScript functionality
└── assets/          <-- Local images, fonts, or media assets

```

If you compress your app's directory directly, **Muffin will automatically flatten nested directory structures** on extraction to make sure your app still launches flawlessly!

## ⚖️ Muffin vs. Electron / Tauri

| **Feature** | **Muffin 🧁** | **Electron ⚛️** | **Tauri 🦀** |
| --- | --- | --- | --- |
| **Average App Size** | **~10 KB - 5 MB** | ~120 MB+ | ~5 MB - 15 MB |
| **Memory Footprint** | **Minimal** (Shared Webkit) | Massive (Dedicated Chromium) | Medium (Dedicated Webview) |
| **Packaging File** | `.mpa` (Simple Zip) | Platform-specific installer | Platform-specific binary |
| **Compilation Required** | **No** (Zero compile-time) | Yes (Long compile-time) | Yes (Requires Rust toolchain) |
| **OS Integration** | Automatic `.desktop` shortcuts | Manual installation process | Manual installation process |

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to make Muffin even better.

Enjoy your lightweight portable web apps! 🧁

## ⏰ Future Ideas

- Windows-based MPA executer (it is possible!)

