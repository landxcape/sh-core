# sh-core

Modular shell configuration framework for aliases and functions. Designed for portability and structured management of shell environments.

## Installation

1. Clone the repository:
   ```bash
   mkdir -p ~/.shell
   git clone https://github.com/landxcape/sh-core.git ~/.shell/sh-core
   ```

2. Add the loader to your shell configuration file (~/.zshrc or ~/.bashrc):
   ```bash
   if [ -f ~/.shell/sh-core/init.sh ]; then
     source ~/.shell/sh-core/init.sh
   fi
   ```

3. Reload the shell environment:
   ```bash
   source ~/.zshrc  # For Zsh (macOS default)
   # or
   source ~/.bashrc # For Bash (Linux default)
   ```

## Directory Structure

- init.sh: Entry point for recursive script loading.
- general/: Standard aliases for command-line navigation and shell management.
- mobile/:
  - android.sh: ADB utilities including multi-device IP discovery.
  - flutter.sh: Build automation and workspace maintenance scripts for Flutter.
- system/: macOS-specific system utilities and display management.

## Primary Utilities & Aliases

### General Aliases (`general/aliases.sh`)
- **`cls`**: Clears the terminal screen (runs `clear`).
- **`ll`**: Detailed directory listing with hidden files (runs `ls -lah`).
- **`aledit`**: Opens the shell configuration directory in Neovim (`sudo nvim ~/.shell/sh-core/`).
- **`sourcerc`**: Quickly reloads and applies updates to the current shell config (runs `source ~/.zshrc`).

### Android & ADB Utilities (`mobile/android.sh`)
- **`adb`**: An intelligent wrapper for the standard `adb` command. If multiple devices are detected and no target (`-s`, `-d`, `-e`) is specified, it prompts you with a clean, single-column interactive selection menu showing model names, serials, and states. Support `q` to cancel the command. Bypasses target checks for device-agnostic commands (e.g., `devices`, `connect`, `disconnect`, `help`).
- **`adbip`**: Resolves the IPv4 address of a connected Android device. Uses the `adb` wrapper to resolve target devices interactively. Prioritizes the `wlan0` interface, with fallback options. Supports `-r` or `--raw` for verbose outputs.

### Flutter Utilities (`mobile/flutter.sh`)
- **`fcbuild`**: Automates production build sequences (`appbundle --release`) on Android and iOS (running Cocoapods sync).
- **`fcbuild-reset`**: Performs a clean sequence (`flutter clean`, deintegrates and updates Cocoapods) and builds the production package.
- **`fpclean_all`**: Executes a parallelized `flutter clean` across all project directories nested under the current path (auto-tuned for Apple Silicon / local CPU cores).

### macOS System Utilities (`system/macos.sh`)
- **`reinitdisplay`**: Puts displays to sleep and wakes them up immediately via power management (`pmset` and `caffeinate`) to resolve display wake failures.
- **`hardreinitdisplay`**: Performs a hard reload of the macOS desktop manager (runs `sudo killall -HUP WindowServer`).

## Portability
This framework is designed for cross-machine synchronization. The `init.sh` script resolves its absolute path at runtime to ensure all modules are sourced correctly regardless of the local installation path.

It is fully compatible with both Zsh and Bash environments on macOS and Linux, dynamically handling shell-specific behaviors (such as array indexing differences).
