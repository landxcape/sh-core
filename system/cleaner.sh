# Function: find-leftovers / find-all-leftovers / purge-leftovers
# Highly optimized leftover finder and purger for macOS

find-leftovers() {
  if [ -z "$1" ]; then
    echo "Usage: find-leftovers <appname>"
    echo "Example: find-leftovers adobe"
    return 1
  fi

  local APP="$1"
  echo "⚡ Fast-scanning leftover locations for '${APP}'..."

  local SEARCH_PATHS=(
    /Applications
    /Library/Application\ Support
    /Library/LaunchAgents
    /Library/LaunchDaemons
    /Library/PrivilegedHelperTools
    /Library/Preferences
    ~/Library/Application\ Support
    ~/Library/LaunchAgents
    ~/Library/Preferences
    ~/Library/HTTPStorages
    ~/Library/Logs
    ~/Library/Containers
    ~/Library/Group\ Containers
    ~/Library/Application\ Scripts
  )

  find "${SEARCH_PATHS[@]}" -maxdepth 3 \
    \( -iname "*${APP}*" \) -not -path "*/Caches*" -not -path "*/.Trash*" 2>/dev/null
}

find-all-leftovers() {
  python3 -c '
import os, glob, plistlib, re, subprocess

user_home = os.path.expanduser("~")

active_tokens = set()

# 1. Recursive scan of all .app bundles across system and user Applications
app_dirs = ["/Applications", "/System/Applications", "/System/Applications/Utilities", os.path.join(user_home, "Applications")]
for app_dir in app_dirs:
    if os.path.exists(app_dir):
        for root, dirs, files in os.walk(app_dir):
            for d in dirs:
                if d.endswith(".app"):
                    app_name = d[:-4].lower()
                    active_tokens.add(app_name)
                    for tok in re.split(r"[^a-z0-9]", app_name):
                        if len(tok) > 2:
                            active_tokens.add(tok)
                    
                    info_plist = os.path.join(root, d, "Contents", "Info.plist")
                    if os.path.exists(info_plist):
                        try:
                            with open(info_plist, "rb") as f:
                                data = plistlib.load(f)
                                bid = data.get("CFBundleIdentifier")
                                if bid:
                                    bid_lower = bid.lower()
                                    active_tokens.add(bid_lower)
                                    for part in re.split(r"[^a-z0-9]", bid_lower):
                                        if len(part) > 2:
                                            active_tokens.add(part)
                        except Exception:
                            pass

# 2. Running processes (anything executing right now is ACTIVE)
try:
    ps_out = subprocess.check_output(["ps", "-ax", "-o", "command"], stderr=subprocess.DEVNULL).decode().splitlines()
    for line in ps_out:
        for word in re.findall(r"[a-z0-9_-]{3,}", line.lower()):
            active_tokens.add(word)
except Exception:
    pass

# 3. Homebrew packages (casks + formulae)
try:
    brew_out = subprocess.check_output(["brew", "list"], stderr=subprocess.DEVNULL).decode().split()
    for b in brew_out:
        active_tokens.add(b.lower())
        for part in re.split(r"[^a-z0-9]", b.lower()):
            if len(part) > 2:
                active_tokens.add(part)
except Exception:
    pass

# 4. PATH binaries ($PATH executables like lazygit, scrcpy, etc.)
for path_dir in os.environ.get("PATH", "").split(":"):
    if os.path.exists(path_dir):
        try:
            for b in os.listdir(path_dir):
                active_tokens.add(b.lower())
        except Exception:
            pass

# 5. Core macOS & system developer runtime whitelist
system_whitelist = {
    "apple", "com.apple", "google", "microsoft", "jetbrains", "xcode", "android",
    "go", "java", "dart", "kotlin", "node", "npm", "python", "ruby", "rust",
    "git", "homebrew", "fvm", "nvm", "pnpm", "yarn", "docker", "cloud-code",
    "addressbook", "callhistorydb", "clouddocs", "contactsd", "controlcenter",
    "crashreporter", "diskimages", "facetime", "fileprovider", "icdd", "icloud",
    "identityservicesd", "imovie", "instruments", "knowledge", "locationaccessstored",
    "mobilesync", "music", "networkserviceproxy", "quick look", "script editor",
    "syncservices", "tipsd", "vmware", "antigravity", "caches", "defaultcompany",
    "askpermission", "callhistorytransactions", "differentialprivacy", "homeenergyd",
    "kpeople", "kpeoplevcard", "privatecloudcomputed", "stickersd", "summary-events",
    "app store", "appstore", "system", "com.gamemac.www", "io.sentry", "segment",
    "cef", "chromium", "smart code ltd", "icloudmailagent", "proapps", "livefsd",
    "btserver"
}

# Special mapping for folder names -> purge target keyword
folder_aliases = {
    "com.operasoftware.opera": "opera",
    "steam": "steam",
    "ccp": "eve",
    "ibm": "spss",
    "cursor": "cursor",
    "poe": "poe",
    "elmedia video player": "elmedia",
    "vivaldi": "vivaldi",
    "minecraft": "minecraft",
    "tlauncher": "tlauncher",
    "portingkit": "portingkit",
    "scrcpygui": "scrcpy",
    "synologydrive": "synology",
    "bravesoftware": "brave"
}

detected_candidates = set()

print("🔍 Running deep leftover audit across processes, applications, and daemons...\n")

# A. Check LaunchAgents & LaunchDaemons for missing binaries
print("=== Orphaned Launch Services ===")
plists = glob.glob("/Library/LaunchAgents/*.plist") + \
         glob.glob("/Library/LaunchDaemons/*.plist") + \
         glob.glob(os.path.join(user_home, "Library/LaunchAgents/*.plist"))

found_plists = 0
for p in plists:
    try:
        with open(p, "rb") as f:
            data = plistlib.load(f)
            prog = data.get("Program")
            if not prog and "ProgramArguments" in data and len(data["ProgramArguments"]) > 0:
                prog = data["ProgramArguments"][0]
            if prog and not os.path.exists(prog):
                print(f"  - {p}\n    -> Missing binary: {prog}")
                found_plists += 1
                base = os.path.basename(p).replace(".plist", "").lower()
                clean = re.sub(r"^(com|org|net|io|ai)\.", "", base).split(".")[0]
                if clean not in system_whitelist and not any(t in active_tokens for t in re.split(r"[^a-z0-9]", clean) if len(t) > 2):
                    detected_candidates.add(clean)
    except Exception:
        pass

if found_plists == 0:
    print("  (None found)")

# B. Check Application Support Folders
print("\n=== Leftover Application Support Folders ===")
support_dirs = glob.glob(os.path.join(user_home, "Library/Application Support/*")) + \
               glob.glob("/Library/Application Support/*")

found_support = 0
for d in support_dirs:
    if not os.path.isdir(d):
        continue
    dirname = os.path.basename(d)
    dirname_lower = dirname.lower()

    if any(dirname_lower.startswith(w) or dirname_lower == w for w in system_whitelist):
        continue

    dir_tokens = set(re.split(r"[^a-z0-9]", dirname_lower))
    is_active = any(t in active_tokens for t in dir_tokens if len(t) > 2)

    if not is_active:
        print(f"  - {d}")
        found_support += 1
        clean_name = folder_aliases.get(dirname_lower, re.sub(r"^(com|org|net|io|ai)\.", "", dirname_lower).split(".")[0])
        if len(clean_name) > 2 and clean_name not in system_whitelist:
            detected_candidates.add(clean_name)

if found_support == 0:
    print("  (None found)")

print("\n========================================================")
print("📋 Ready-to-use purge command for detected candidates:")
print("========================================================")
if detected_candidates:
    print("purge-leftovers " + " ".join(sorted(detected_candidates)))
else:
    print("No uninstalled app leftovers detected!")
print("========================================================")
'
}

purge-leftovers() {
  if [ "$#" -eq 0 ]; then
    echo "Usage: purge-leftovers <appname1> [appname2 ...]"
    echo "Example: purge-leftovers adobe cursor opera"
    return 1
  fi

  for APP in "$@"; do
    echo "----------------------------------------"
    echo "🧹 Purging leftovers for '${APP}'..."
    
    echo "  -> Terminating running processes..."
    pkill -9 -i "$APP" 2>/dev/null

    echo "  -> Removing user-level files..."
    zsh -c "rm -rf ~/Library/Application\ Support/*${APP}*(N) \
                   ~/Library/LaunchAgents/*${APP}*(N) \
                   ~/Library/Preferences/*${APP}*(N) \
                   ~/Library/Preferences/ByHost/*${APP}*(N) \
                   ~/Library/HTTPStorages/*${APP}*(N) \
                   ~/Library/Logs/*${APP}*(N) \
                   ~/Library/Group\ Containers/*${APP}*(N) \
                   ~/Library/Containers/*${APP}*(N) \
                   ~/Library/Application\ Scripts/*${APP}*(N)"

    echo "  -> Removing system-level files (may require sudo)..."
    sudo zsh -c "rm -rf /Library/Application\ Support/*${APP}*(N) \
                       /Library/LaunchAgents/*${APP}*(N) \
                       /Library/LaunchDaemons/*${APP}*(N) \
                       /Library/PrivilegedHelperTools/*${APP}*(N) \
                       /Library/Preferences/*${APP}*(N)"
  done

  echo "----------------------------------------"
  echo "✅ All specified app purges complete!"
}
