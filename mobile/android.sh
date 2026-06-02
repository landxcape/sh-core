# Android-specific Aliases and Functions

# Get Android device IP address (wlan0 with fallback)
# Usage: adbip [-r|--raw]
adbip() {
  local raw=false
  if [[ "$1" == "-r" || "$1" == "--raw" ]]; then
    raw=true
  fi

  # 1. Device Selection
  local devices=($(adb devices | grep -v "List" | awk '{print $1}' | grep .))
  local device_count=${#devices[@]}

  if [[ $device_count -eq 0 ]]; then
    echo "No devices connected."
    return 1
  elif [[ $device_count -eq 1 ]]; then
    local serial=${devices[0]}
  else
    echo "Multiple devices found. Select one:"
    select s in "${devices[@]}"; do
      if [[ -n "$s" ]]; then
        serial=$s
        break
      fi
    done
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
