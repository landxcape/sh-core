#!/usr/bin/env zsh
# sh-core: Recursive script loader

# Get absolute path of this directory (works in Zsh and Bash)
if [ -n "$ZSH_VERSION" ]; then
  SH_CORE_DIR="${0:A:h}"
elif [ -n "$BASH_VERSION" ]; then
  SH_CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  SH_CORE_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Find all .sh files in subdirectories and source them
# Excludes this init.sh and hidden files
find "$SH_CORE_DIR" -type f -name "*.sh" -not -path "$SH_CORE_DIR/init.sh" | while read -r script; do
  source "$script"
done
