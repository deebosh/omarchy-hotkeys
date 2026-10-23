#!/bin/bash
# detect-app.sh — canonical app key for the focused Hyprland window.
# GUI apps: mapped from window class. Terminals (foot): resolved by walking
# the client's process tree, so tmux / nvim / lazygit running inside foot
# report as themselves instead of "foot".
# Prints one key per line: zen|foot|neovim|tmux|lazygit|nautilus|zed|globals.

set -u

# Optional $1 = client pid (testing / explicit queries). Default: focused window.
if [[ -n "${1:-}" && "$1" =~ ^[0-9]+$ ]]; then
  info=$(hyprctl clients -j 2>/dev/null | jq -c --argjson pid "$1" '[.[] | select(.pid == $pid)][0] // {}')
  class=$(printf '%s' "$info" | jq -r '.class // empty' 2>/dev/null)
  pid="$1"
else
  info=$(hyprctl activewindow -j 2>/dev/null) || { echo "globals"; exit 0; }
  class=$(printf '%s' "$info" | jq -r '.class // empty' 2>/dev/null)
  pid=$(printf '%s' "$info" | jq -r '.pid // 0' 2>/dev/null)
fi
[[ -n "$info" && "$info" != "{}" ]] || { echo "globals"; exit 0; }

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

normalize() {
  local t
  t=$(lower "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/\.desktop$//')
  case "$t" in
    "") echo "globals"; return;;
    zen-browser|zen\ browser) echo "zen"; return;;
    firefox) echo "firefox"; return;;
    librewolf) echo "firefox"; return;;
    chromium|chromium-browser) echo "chromium"; return;;
    google-chrome|chrome) echo "chrome"; return;;
    brave-browser|brave) echo "brave"; return;;
    microsoft-edge|edge) echo "edge"; return;;
    helium) echo "chromium"; return;;
    footclient|foot-server|org.codeberg.dnkl.foot|foot) echo "foot"; return;;
    alacritty) echo "alacritty"; return;;
    kitty) echo "kitty"; return;;
    com.mitchellh.ghostty|ghostty) echo "ghostty"; return;;
    wezterm|org.wezfurlong.wezterm) echo "wezterm"; return;;
    org.gnome.nautilus|nautilus|org.gnome.files) echo "nautilus"; return;;
    thunar|org.xfce.thunar) echo "thunar"; return;;
    ranger) echo "ranger"; return;;
    yazi) echo "yazi"; return;;
    nvim|neovim|nvimpager) echo "neovim"; return;;
    tmux) echo "tmux"; return;;
    lazygit) echo "lazygit"; return;;
    lazydocker) echo "lazydocker"; return;;
    tig) echo "tig"; return;;
    btop|org.omarchy.btop) echo "btop"; return;;
    htop) echo "htop"; return;;
    hx|helix) echo "helix"; return;;
    emacs) echo "emacs"; return;;
    micro) echo "micro"; return;;
    dev.zed.zed|zed) echo "zed"; return;;
    code|code-oss|vscode) echo "vscode"; return;;
    sublime_text|sublime-text|subl) echo "sublime-text"; return;;
    org.gnome.texteditor|gnome-text-editor) echo "gnome-text-editor"; return;;
    obsidian) echo "obsidian"; return;;
    notion-app|notion) echo "notion"; return;;
    todoist) echo "todoist"; return;;
    anytype) echo "anytype"; return;;
    logseq) echo "logseq"; return;;
    libreoffice-writer) echo "libreoffice-writer"; return;;
    libreoffice-calc) echo "libreoffice-calc"; return;;
    libreoffice-impress) echo "libreoffice-impress"; return;;
    libreoffice|soffice.bin) echo "libreoffice-writer"; return;;
    thunderbird) echo "thunderbird"; return;;
    org.gnome.evolution|evolution) echo "evolution"; return;;
    org.gnome.geary|geary) echo "geary"; return;;
    discord) echo "discord"; return;;
    whatsapp|whatsapp-for-linux) echo "whatsapp"; return;;
    org.telegram.desktop|telegram|telegram-desktop) echo "telegram"; return;;
    signal|signal-desktop) echo "signal"; return;;
    slack) echo "slack"; return;;
    zoom|zoom-client) echo "zoom"; return;;
    element|element-desktop) echo "element"; return;;
    skype|skypeforlinux) echo "skype"; return;;
    vlc) echo "vlc"; return;;
    mpv) echo "mpv"; return;;
    celluloid|io.github.celluloid_player.celluloid) echo "celluloid"; return;;
    com.obsproject.studio|obs) echo "obs-studio"; return;;
    kdenlive|org.kde.kdenlive) echo "kdenlive"; return;;
    resolve|davinci-resolve) echo "davinci-resolve"; return;;
    blender) echo "blender"; return;;
    shotcut|org.shotcut.shotcut) echo "shotcut"; return;;
    spotify) echo "spotify"; return;;
    org.gnome.rhythmbox3|rhythmbox) echo "rhythmbox"; return;;
    audacity) echo "audacity"; return;;
    gimp) echo "gimp"; return;;
    org.inkscape.inkscape|inkscape) echo "inkscape"; return;;
    pinta|com.github.pintaproject.pinta) echo "pinta"; return;;
    xournalpp|com.github.xournalpp.xournalpp) echo "xournalpp"; return;;
    imv) echo "imv"; return;;
    org.gnome.eog|eog) echo "eog"; return;;
    org.gnome.gthumb|gthumb) echo "gthumb"; return;;
    org.gnome.loupe|loupe) echo "loupe"; return;;
    org.gnome.evince|evince) echo "evince"; return;;
    org.gnome.papers|papers) echo "papers"; return;;
    org.kde.okular|okular) echo "okular"; return;;
    com.github.johnfactotum.foliate|foliate) echo "foliate"; return;;
    dropbox) echo "dropbox"; return;;
    localsend_app|localsend) echo "localsend"; return;;
    de.haeckerfelix.fragments|fragments) echo "fragments"; return;;
    org.gnome.meld|meld) echo "meld"; return;;
    docker-desktop|"docker desktop") echo "docker-desktop"; return;;
    dbeaver) echo "dbeaver"; return;;
    postman) echo "postman"; return;;
    filezilla) echo "filezilla"; return;;
    org.wireshark.wireshark|wireshark) echo "wireshark"; return;;
    org.godotengine.godot|godot) echo "godot"; return;;
    steam) echo "steam"; return;;
    heroic|heroicgameslauncher) echo "heroic"; return;;
    net.lutris.lutris|lutris) echo "lutris"; return;;
    retroarch) echo "retroarch"; return;;
    com.moonlight_stream.moonlight|moonlight) echo "moonlight"; return;;
    virt-manager) echo "virt-manager"; return;;
    ca.desrt.dconf-editor|dconf-editor) echo "dconf-editor"; return;;
    1password|1password-client) echo "1password"; return;;
    bitwarden|bitwarden-desktop) echo "bitwarden"; return;;
    keepassxc) echo "keepassxc"; return;;
    org.gnome.systemmonitor|gnome-system-monitor) echo "gnome-system-monitor"; return;;
    io.missioncenter.missioncenter|mission-center) echo "mission-center"; return;;
    org.gnome.baobab|baobab) echo "baobab"; return;;
    org.gnome.diskutility|gnome-disks) echo "gnome-disks"; return;;
    gparted) echo "gparted"; return;;
    timeshift-gtk|timeshift) echo "timeshift"; return;;
    pavucontrol) echo "pavucontrol"; return;;
    org.gnome.extensions|gnome-extensions) echo "gnome-extensions"; return;;
    org.gnome.calendar|gnome-calendar) echo "gnome-calendar"; return;;
    org.gnome.calculator|gnome-calculator) echo "gnome-calculator"; return;;
  esac
  local short="$t"
  [[ "$t" == *.* ]] && short="${t##*.}"
  case "$short" in
    zen|foot|nautilus|neovim|tmux|lazygit|zed|firefox|chromium|chrome|brave|edge|alacritty|kitty|ghostty|wezterm|vscode|helix|emacs|micro|yazi|ranger|thunar|btop|htop|tig|lazydocker|thunderbird|evolution|geary|discord|whatsapp|telegram|signal|slack|zoom|element|skype|vlc|mpv|celluloid|spotify|audacity|gimp|inkscape|pinta|xournalpp|imv|dropbox|localsend|meld|steam|godot|zoom) echo "$short"; return;;
  esac
  echo "globals"
}

key=$(normalize "$class")

# Only terminals need the process-tree walk; GUI apps are exact already.
if [[ "$key" != "foot" || ! "$pid" =~ ^[0-9]+$ || "$pid" -le 1 ]]; then
  echo "$key"
  exit 0
fi

# BFS over the process tree starting at the client pid; collect "pid comm".
# NOTE: tmux panes are children of the tmux *server*, not of this window, so
# a tmux client hit is resolved separately through the tmux CLI below.
mapfile -t descs < <(ps -e -o pid=,ppid=,comm= 2>/dev/null | awk -v root="$pid" '
  { pidv[$1] = $3; kids[$2] = kids[$2] " " $1 }
  END {
    queue = root; seen[root] = 1
    while (queue != "") {
      n = split(queue, q, " ")
      queue = ""
      for (i = 1; i <= n; i++) {
        c = q[i]
        if (c == "") continue
        if (pidv[c] != "") print c " " tolower(pidv[c])
        m = split(kids[c], ch, " ")
        for (j = 1; j <= m; j++) {
          if (ch[j] != "" && !seen[ch[j]]) { seen[ch[j]] = 1; queue = queue " " ch[j] }
        }
      }
    }
  }')

# Rank for TUI commands found inside a terminal (lower wins).
tui_rank() {
  case "$1" in
    lazygit) echo 1;;
    lazydocker) echo 2;;
    yazi) echo 3;;
    nvim|neovim) echo 4;;
    hx|helix) echo 5;;
    emacs) echo 6;;
    micro) echo 7;;
    htop|btop) echo 8;;
    tig|ranger) echo 9;;
    *) echo 99;;
  esac
}
tui_key() {
  case "$1" in
    hx) echo "helix";;
    nvim) echo "neovim";;
    *) echo "$1";;
  esac
}

direct=""; direct_rank=99; declare -A our_pids=()
for entry in "${descs[@]}"; do
  dpid="${entry%% *}"; comm="${entry#* }"
  our_pids["$dpid"]=1
  r=$(tui_rank "$comm")
  if (( r < direct_rank )); then direct_rank=$r; direct=$(tui_key "$comm"); fi
done
[[ -n "$direct" ]] && { echo "$direct"; exit 0; }

# Inside tmux: only sessions owned by OUR client pids count.
if command -v tmux >/dev/null 2>&1; then
  while IFS= read -r line; do
    cpid="${line%% *}"; sess="${line#* }"
    [[ -n "${our_pids[$cpid]:-}" ]] || continue
    panes=$(tmux list-panes -s -t "$sess" -F '#{pane_current_command}' 2>/dev/null)
    hit=""; hit_rank=99
    while IFS= read -r cmd; do
      c=$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')
      r=$(tui_rank "$c")
      if (( r < hit_rank )); then hit_rank=$r; hit=$(tui_key "$c"); fi
    done <<< "$panes"
    if [[ -n "$hit" ]]; then echo "$hit"; exit 0; fi
    echo "tmux"; exit 0
  done < <(tmux list-clients -F '#{client_pid} #{client_session}' 2>/dev/null)
fi

echo "foot"
