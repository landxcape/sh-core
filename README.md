# sh-core | Portable Shell Environment

A modular, domain-specific shell configuration framework for aliases and functions.

## 🚀 Installation

1. **Clone the repository** (or copy to your shell directory):
   ```bash
   mkdir -p ~/.shell
   # git clone <repo_url> ~/.shell/sh-core
   ```

2. **Source the loader** in your `~/.zshrc` or `~/.bashrc`:
   ```bash
   if [ -f ~/.shell/sh-core/init.sh ]; then
     source ~/.shell/sh-core/init.sh
   fi
   ```

3. **Reload your shell**:
   ```bash
   source ~/.zshrc
   ```

## 📂 Structure

- `init.sh`: The entry point that recursively loads all `.sh` files.
- `general/`: Common shortcuts like `cls`, `ll`, and shell management.
- `mobile/`:
  - `android.sh`: ADB utilities, including the robust `adbip` command.
  - `flutter.sh`: Build and cleanup tools for Flutter development.
- `system/`: macOS-specific utility commands and fixes.

## 🛠️ Key Commands

### General
- `cls`: Clear the terminal screen.
- `ll`: List files in long format with hidden files.
- `sourcerc`: Quickly reload your Zsh configuration.

### Mobile Development
- `adbip`: Get the IP address of a connected Android device. Supports `-r` for raw output and interactive fallback if `wlan0` is missing.
- `fcbuild`: Full Flutter build (appbundle release) for Android/iOS.
- `fpclean_all`: Parallel recursive `flutter clean` for all projects in the current directory.

### System
- `reinitdisplay`: Fix display sleep issues.
- `hardreinitdisplay`: Force restart the macOS WindowServer.
