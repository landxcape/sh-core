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
   source ~/.zshrc
   ```

## Directory Structure

- init.sh: Entry point for recursive script loading.
- general/: Standard aliases for command-line navigation and shell management.
- mobile/:
  - android.sh: ADB utilities including multi-device IP discovery.
  - flutter.sh: Build automation and workspace maintenance scripts for Flutter.
- system/: macOS-specific system utilities and display management.

## Primary Utilities

### adbip
Retrieves the IPv4 address of a connected Android device.
- Handles multiple connected devices via an interactive selection menu.
- Prioritizes the wlan0 interface.
- Includes a fallback mechanism to query all network interfaces if wlan0 is unavailable.
- Supports the -r or --raw flag for full command output.

### fcbuild
Automates the production build sequence for Flutter applications on Android and iOS.

### fpclean_all
Executes a parallelized flutter clean across all projects in the current directory, optimized for local CPU core counts.

### reinitdisplay
Addresses macOS display wake failures through power management and caffeinate utilities.

## Portability
This framework is designed for cross-machine synchronization. The init.sh script resolves its absolute path at runtime to ensure all modules are sourced correctly regardless of the local installation path.
