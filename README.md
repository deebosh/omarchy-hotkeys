# deebosh.hotkeys

Hotkeys of the focused app in the [Omarchy](https://omarchy.org) bar: an icon in the bar center, a popup with the shortcut list on click or `SUPER + SHIFT + K`.

The panel follows focus: switch windows and the icon plus the list update. The language follows the system locale (Russian for `ru_*`, English otherwise). Unknown apps fall back to the global Hyprland bindings.

## Installation

```bash
omarchy plugin add https://github.com/<you>/omarchy-hotkeys.git --enable
# the widget lands in the bar center (manifest: barWidget.defaultSection)
```

Manually, without reinstalling:

```bash
omarchy bar put deebosh.hotkeys --section center
```

Optional panel hotkey (in `~/.config/hypr/bindings.lua`):

```lua
o.bind("SUPER + SHIFT + K", "Hotkeys", "omarchy-shell shell toggle deebosh.hotkeys")
```

Without it the panel opens on icon click. The plugin never writes to user configs — it only reads.

## Removal

```bash
omarchy plugin remove deebosh.hotkeys
```

This removes the widget from the bar and deletes the plugin folder. Remove the manual binding from `~/.config/hypr/bindings.lua` yourself if you added one.

## Dependencies

Only what Omarchy already ships: `hyprctl`, `jq`, `sh`, `ps` (procps). `tmux` is optional: without it, in-tmux app detection doesn't work, everything else does. No network access, no privileges needed.

## Settings (plugin entry in `shell.json`)

| Key | Type | Default | What it does |
|---|---|---|---|
| `showGlobals` | On/Off | Off | Append global Hyprland bindings at the bottom of the panel |
| `compact` | On/Off | Off | Compact view (no group headers) |
| `maxItems` | integer | 0 | Entry limit, 0 = unlimited |

## Data

`shortcuts/<appId>.json` — 102 sets (2600+ entries) from official sources. The file name must match `appId` (enforced by `scripts/check-data.js`):

```bash
node scripts/check-data.js   # schema + name match + counts
```

Entries are bilingual: English base fields (`title`, `action`, `displayName`, `note`) plus `*Ru` variants picked up automatically on Russian locales. The core set covers the Omarchy bundle and daily tools: zen, firefox, chromium, foot, alacritty/kitty/ghostty/wezterm, neovim, tmux, lazygit, lazydocker, nautilus, zed, vscode, helix, emacs, btop, LibreOffice (writer/calc/impress), thunderbird, obsidian, spotify, discord/telegram/signal, pinta, xournalpp, mpv, imv, obs-studio, kdenlive...
The full list is the file names in `shortcuts/`. Honest stubs (apps with no documented hotkeys, e.g. `localsend.json`): empty `groups` + `note`.

Format: `{ appId, displayName, source, groups: [{ title, items: [{ keys[], action }] }] }`.
Keys stay as in the original source.

`Model.js` — Qt-free logic (app-id normalization, filter, limit, locale), tested via node.

`scripts/detect-app.sh` — refines the focused app: window class plus process-tree walk (tmux clients resolved via `tmux list-clients/list-panes`, otherwise BFS over `ps`). Test: `scripts/detect-app.sh [pid]` (no args = focused window).

## Structure

```
manifest.json    # id deebosh.hotkeys, kinds [bar-widget], defaultSection center
BarWidget.qml    # bar icon + open/close/opened for shell.toggle + detect-app.sh polling (2s)
Panel.qml        # popup: search, groups, settings (effectiveKey taken from hostWidget)
Model.js         # logic + node test
shortcuts/       # data (lazy-loaded: current app + globals only)
scripts/         # detect-app.sh, check-data.js
preview.png      # marketplace preview
```

## Verification

```bash
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml
```

MIT license.
