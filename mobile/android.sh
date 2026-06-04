# Android-specific Aliases and Functions

# Helper to select a device when multiple are connected
_adb_select_device() {
  local list=()
  local serials=()
  local line serial state model choice index COLUMNS device_count

  # Parse adb devices -l to get descriptive names
  while read -r line; do
    [[ -z "$line" || "$line" == "List of devices"* ]] && continue
    
    serial=$(echo "$line" | awk '{print $1}')
    state=$(echo "$line" | awk '{print $2}')
    
    # Extract model name and replace underscores with spaces
    model=$(echo "$line" | grep -o 'model:[^ ]*' | cut -d: -f2 | tr '_' ' ')
    if [[ -z "$model" ]]; then
      model="Unknown Device"
    fi

    serials+=("$serial")
    list+=("$model ($serial) [$state]")
  done < <(command adb devices -l)

  device_count=${#serials[@]}

  if [[ $device_count -eq 0 ]]; then
    echo "No devices connected." >/dev/tty
    return 1
  elif [[ $device_count -eq 1 ]]; then
    # Zsh is 1-indexed, Bash is 0-indexed
    if [[ -n "$ZSH_VERSION" ]]; then
      echo "${serials[1]}"
    else
      echo "${serials[0]}"
    fi
  else
    echo "Multiple devices found. Select one (or 'q' to quit):" >/dev/tty
    # Force select menu to print one item per line
    COLUMNS=1
    select choice in "${list[@]}"; do
      if [[ -n "$choice" ]]; then
        index=$REPLY
        if [[ "$index" -ge 1 && "$index" -le $device_count ]]; then
          # Zsh is 1-indexed (use index directly), Bash is 0-indexed (subtract 1)
          if [[ -n "$ZSH_VERSION" ]]; then
            serial="${serials[index]}"
          else
            serial="${serials[index-1]}"
          fi
          break
        fi
      elif [[ "$REPLY" == "q" || "$REPLY" == "Q" ]]; then
        echo "Selection cancelled." >/dev/tty
        return 1
      fi
    done </dev/tty >/dev/tty 2>/dev/tty
    echo "$serial"
  fi
}

# Wrapper for adb command to handle automatic multi-device selection
adb() {
  # If device target options (-s, -d, -e) are already present, or if it's a non-device command, bypass wrapper
  local bypass=false
  local non_device_cmds=("devices" "connect" "disconnect" "start-server" "kill-server" "version" "help")

  for arg in "$@"; do
    if [[ "$arg" == "-s" || "$arg" == "-d" || "$arg" == "-e" ]]; then
      bypass=true
      break
    fi
  done

  if [[ -n "$1" ]] && [[ " ${non_device_cmds[*]} " =~ " $1 " ]]; then
    bypass=true
  fi

  if [ "$bypass" = true ]; then
    command adb "$@"
    return $?
  fi

  local devices=($(command adb devices | grep -v "List" | awk '{print $1}' | grep .))
  if [[ ${#devices[@]} -gt 1 ]]; then
    local serial
    serial=$(_adb_select_device)
    local exit_status=$?
    if [[ $exit_status -eq 0 && -n "$serial" ]]; then
      command adb -s "$serial" "$@"
    else
      return $exit_status
    fi
  else
    command adb "$@"
  fi
}

# Get Android device IP address (wlan0 with fallback)
# Usage: adbip [-r|--raw]
adbip() {
  local raw=false
  if [[ "$1" == "-r" || "$1" == "--raw" ]]; then
    raw=true
  fi

  # Resolve the device serial using the adb wrapper
  local serial
  serial=$(adb get-serialno 2>/dev/null) || return 1
  if [[ -z "$serial" || "$serial" == "unknown" ]]; then
    echo "No active device selected or found." >&2
    return 1
  fi

  # 2. Attempt wlan0
  local output
  output=$(adb -s "$serial" shell ip addr show wlan0 2>/dev/null)
  local ip=$(echo "$output" | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

  if [[ -n "$ip" ]]; then
    if [ "$raw" = true ]; then
      echo "$output"
    else
      echo "$ip"
    fi
    return 0
  fi

  # 3. Fallback
  echo "No IP address found on wlan0."
  echo -n "Try other interfaces? (y/n) "
  read -k 1 choice
  echo
  if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    if [ "$raw" = true ]; then
      adb -s "$serial" shell ip addr
    else
      # Shows "interface: ip" for all non-loopback inet addresses
      adb -s "$serial" shell ip addr | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $NF ": " $2}' | cut -d/ -f1
    fi
  fi
}
