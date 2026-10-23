// Pure logic for deebosh.hotkeys: app-id normalization, glyph/display-name
// lookup, and shortcut filtering. Qt-free so it runs under node for tests.
//
// Data files live in shortcuts/<app>.json:
//   { appId, displayName, source, groups: [{ title, items: [{ keys: [], action }] }] }

var FALLBACK_APP = "globals";

// Glyphs verified against JetBrainsMono Nerd Font cmap (fc-query charset).
var GLYPHS = {
  zen: "\uDB81\uDD9F",
  foot: "\uE795",
  neovim: "\uE7C5",
  tmux: "\uDB81\uDCE9",
  lazygit: "\uF418",
  nautilus: "\uDB80\uDE4B",
  zed: "\uE796",
  globals: "\uDB80\uDF0C",
  firefox: "\uDB80\uDE39",
  chromium: "\uDB81\uDD9F",
  chrome: "\uDB81\uDD9F",
  brave: "\uDB81\uDD9F",
  edge: "\uDB81\uDD9F",
  alacritty: "\uE795",
  kitty: "\uE795",
  ghostty: "\uE795",
  wezterm: "\uE795",
  vscode: "\uE796",
  "sublime-text": "\uE796",
  micro: "\uE796",
  "gnome-text-editor": "\uE796",
  helix: "\uE796",
  emacs: "\uE796",
  obsidian: "\uDB80\uDED2",
  notion: "\uDB80\uDE19",
  todoist: "\uDB80\uDE19",
  anytype: "\uDB80\uDE19",
  logseq: "\uDB80\uDE19",
  "libreoffice-writer": "\uDB80\uDE19",
  "libreoffice-calc": "\uDB82\uDC3B",
  "libreoffice-impress": "\uDB81\uDC28",
  thunderbird: "\uDB80\uDDF0",
  evolution: "\uDB80\uDDF0",
  geary: "\uDB80\uDDF0",
  discord: "\uDB80\uDF69",
  whatsapp: "\uDB80\uDF69",
  telegram: "\uDB80\uDF69",
  signal: "\uDB80\uDF69",
  slack: "\uDB80\uDF69",
  zoom: "\uDB80\uDF69",
  element: "\uDB80\uDF69",
  skype: "\uDB80\uDF69",
  vlc: "\uDB81\uDC0A",
  mpv: "\uDB81\uDC0A",
  celluloid: "\uDB81\uDC0A",
  "obs-studio": "\uDB81\uDD7E",
  kdenlive: "\uDB81\uDD7E",
  "davinci-resolve": "\uDB81\uDD7E",
  blender: "\uDB81\uDD7E",
  shotcut: "\uDB81\uDD7E",
  spotify: "\uDB81\uDF5A",
  rhythmbox: "\uDB81\uDF5A",
  audacity: "\uDB81\uDF5A",
  gimp: "\uDB80\uDFD8",
  inkscape: "\uDB80\uDFD8",
  imv: "\uDB80\uDEE9",
  eog: "\uDB80\uDEE9",
  gthumb: "\uDB80\uDEE9",
  loupe: "\uDB80\uDEE9",
  xournalpp: "\uDB80\uDEE9",
  pinta: "\uDB80\uDFD8",
  evince: "\uDB80\uDED2",
  papers: "\uDB80\uDED2",
  okular: "\uDB80\uDED2",
  foliate: "\uDB80\uDED2",
  thunar: "\uDB80\uDE4B",
  ranger: "\uDB80\uDE4B",
  yazi: "\uDB80\uDE4B",
  dropbox: "\uDB80\uDD62",
  localsend: "\uDB80\uDD62",
  fragments: "\uDB80\uDD62",
  postman: "\uDB80\uDD62",
  filezilla: "\uDB80\uDD62",
  lazydocker: "\uF418",
  tig: "\uF418",
  meld: "\uDB81\uDC93",
  "docker-desktop": "\uDB82\uDC68",
  dbeaver: "\uDB80\uDDBC",
  godot: "\uDB80\uDE96",
  steam: "\uDB80\uDE96",
  heroic: "\uDB80\uDE96",
  lutris: "\uDB80\uDE96",
  retroarch: "\uDB80\uDE96",
  moonlight: "\uDB80\uDE96",
  "virt-manager": "\uDB81\uDC93",
  wireshark: "\uDB80\uDD27",
  "dconf-editor": "\uDB81\uDC93",
  "1password": "\uDB80\uDF3E",
  bitwarden: "\uDB80\uDF3E",
  keepassxc: "\uDB80\uDF3E",
  btop: "\uDB80\uDD27",
  htop: "\uDB80\uDD27",
  "gnome-system-monitor": "\uDB80\uDD27",
  "mission-center": "\uDB80\uDD27",
  baobab: "\uDB80\uDDBC",
  "gnome-disks": "\uDB80\uDDBC",
  gparted: "\uDB80\uDDBC",
  timeshift: "\uDB80\uDDBC",
  pavucontrol: "\uDB81\uDF5A",
  "gnome-extensions": "\uDB81\uDC93",
  "gnome-calendar": "\uDB80\uDF3D",
  "gnome-calculator": "\uDB80\uDDB2"
};

var DISPLAY_NAMES = {
  zen: "Zen Browser",
  foot: "Foot",
  neovim: "Neovim",
  tmux: "Tmux",
  lazygit: "Lazygit",
  nautilus: "Files",
  zed: "Zed",
  globals: "Hyprland",
  firefox: "Firefox",
  chromium: "Chromium",
  chrome: "Google Chrome",
  brave: "Brave",
  edge: "Microsoft Edge",
  alacritty: "Alacritty",
  kitty: "Kitty",
  ghostty: "Ghostty",
  wezterm: "WezTerm",
  vscode: "VS Code",
  "sublime-text": "Sublime Text",
  micro: "Micro",
  "gnome-text-editor": "Text Editor",
  helix: "Helix",
  emacs: "Emacs",
  obsidian: "Obsidian",
  notion: "Notion",
  todoist: "Todoist",
  anytype: "Anytype",
  logseq: "Logseq",
  "libreoffice-writer": "Writer",
  "libreoffice-calc": "Calc",
  "libreoffice-impress": "Impress",
  thunderbird: "Thunderbird",
  evolution: "Evolution",
  geary: "Geary",
  discord: "Discord",
  whatsapp: "WhatsApp",
  telegram: "Telegram",
  signal: "Signal",
  slack: "Slack",
  zoom: "Zoom",
  element: "Element",
  skype: "Skype",
  vlc: "VLC",
  mpv: "mpv",
  celluloid: "Celluloid",
  "obs-studio": "OBS Studio",
  kdenlive: "Kdenlive",
  "davinci-resolve": "DaVinci Resolve",
  blender: "Blender",
  shotcut: "Shotcut",
  spotify: "Spotify",
  rhythmbox: "Rhythmbox",
  audacity: "Audacity",
  gimp: "GIMP",
  inkscape: "Inkscape",
  pinta: "Pinta",
  xournalpp: "Xournal++",
  imv: "imv",
  eog: "Image Viewer",
  gthumb: "gThumb",
  loupe: "Loupe",
  evince: "Evince",
  papers: "Papers",
  okular: "Okular",
  foliate: "Foliate",
  thunar: "Thunar",
  ranger: "Ranger",
  yazi: "Yazi",
  dropbox: "Dropbox",
  localsend: "LocalSend",
  fragments: "Fragments",
  lazydocker: "Lazydocker",
  tig: "Tig",
  meld: "Meld",
  "docker-desktop": "Docker Desktop",
  dbeaver: "DBeaver",
  postman: "Postman",
  filezilla: "FileZilla",
  wireshark: "Wireshark",
  godot: "Godot",
  steam: "Steam",
  heroic: "Heroic",
  lutris: "Lutris",
  retroarch: "RetroArch",
  moonlight: "Moonlight",
  "virt-manager": "Virtual Machines",
  "dconf-editor": "dconf Editor",
  "1password": "1Password",
  bitwarden: "Bitwarden",
  keepassxc: "KeePassXC",
  btop: "btop",
  htop: "htop",
  "gnome-system-monitor": "System Monitor",
  "mission-center": "Mission Center",
  baobab: "Disk Usage",
  "gnome-disks": "Disks",
  gparted: "GParted",
  timeshift: "Timeshift",
  pavucontrol: "Volume",
  "gnome-extensions": "Extensions",
  "gnome-calendar": "Calendar",
  "gnome-calculator": "Calculator"
};

// Russian overrides; English is the base above.
var DISPLAY_NAMES_RU = {
  nautilus: "Файлы",
  "gnome-text-editor": "Текстовый редактор",
  eog: "Просмотр изображений",
  loupe: "Лупа",
  "virt-manager": "Виртуальные машины",
  "dconf-editor": "Редактор dconf",
  "gnome-system-monitor": "Системный монитор",
  baobab: "Анализ дисков",
  "gnome-disks": "Диски",
  pavucontrol: "Громкость",
  "gnome-extensions": "Расширения",
  "gnome-calendar": "Календарь",
  "gnome-calculator": "Калькулятор"
};

// ---- Locale -----------------------------------------------------------
// UI language follows the system locale: Russian when it starts with "ru",
// English otherwise. Data files carry EN base fields plus *Ru variants.

function isRussian(localeName) {
  return String(localeName || "").toLowerCase().indexOf("ru") === 0;
}

var UI_STRINGS = {
  searchPlaceholder: { en: "Search…", ru: "Поиск…" },
  shortcutsCount: { en: "shortcuts", ru: "хоткеев" },
  tooltipSuffix: { en: "shortcuts", ru: "хоткеи" },
  nothingFound: { en: "Nothing found", ru: "Ничего не найдено" },
  noEntries: { en: "No entries", ru: "Нет записей" },
  noData: { en: "No data for this app", ru: "Нет данных для этого приложения" },
  unknownAppNote: { en: "No data for “{app}” — global bindings", ru: "Для «{app}» данных нет — глобальные бинды" }
};

function tr(key, localeName) {
  var pair = UI_STRINGS[key];
  if (!pair) return "";
  return isRussian(localeName) ? pair.ru : pair.en;
}

function displayNameForKey(key, localeName) {
  if (isRussian(localeName) && DISPLAY_NAMES_RU[key]) return DISPLAY_NAMES_RU[key];
  return DISPLAY_NAMES[key] || DISPLAY_NAMES[FALLBACK_APP];
}

// Data-file helpers: EN base field, *Ru variant when Russian locale.
function dataDisplayName(data, key, localeName) {
  if (!data) return displayNameForKey(key, localeName);
  if (isRussian(localeName) && data.displayNameRu) return data.displayNameRu;
  return data.displayName || displayNameForKey(key, localeName);
}

function groupTitle(group, localeName) {
  if (isRussian(localeName) && group.titleRu) return group.titleRu;
  return group.title || "";
}

function itemAction(item, localeName) {
  if (isRussian(localeName) && item.actionRu) return item.actionRu;
  return item.action || "";
}

// Raw Wayland app-id / Hyprland class -> canonical key.
var ALIASES = {
  "zen-browser": "zen",
  "zen browser": "zen",
  "firefox": "firefox",
  "librewolf": "firefox",
  "chromium": "chromium",
  "chromium-browser": "chromium",
  "google-chrome": "chrome",
  "chrome": "chrome",
  "brave-browser": "brave",
  "brave": "brave",
  "microsoft-edge": "edge",
  "edge": "edge",
  "helium": "chromium",
  "footclient": "foot",
  "foot-server": "foot",
  "org.codeberg.dnkl.foot": "foot",
  "alacritty": "alacritty",
  "kitty": "kitty",
  "com.mitchellh.ghostty": "ghostty",
  "ghostty": "ghostty",
  "wezterm": "wezterm",
  "org.wezfurlong.wezterm": "wezterm",
  "org.gnome.nautilus": "nautilus",
  "nautilus": "nautilus",
  "org.gnome.files": "nautilus",
  "thunar": "thunar",
  "org.xfce.thunar": "thunar",
  "ranger": "ranger",
  "yazi": "yazi",
  "nvim": "neovim",
  "neovim": "neovim",
  "nvimpager": "neovim",
  "tmux": "tmux",
  "lazygit": "lazygit",
  "lazydocker": "lazydocker",
  "tig": "tig",
  "btop": "btop",
  "org.omarchy.btop": "btop",
  "htop": "htop",
  "hx": "helix",
  "helix": "helix",
  "emacs": "emacs",
  "micro": "micro",
  "dev.zed.zed": "zed",
  "zed": "zed",
  "code": "vscode",
  "code-oss": "vscode",
  "vscode": "vscode",
  "sublime_text": "sublime-text",
  "sublime-text": "sublime-text",
  "subl": "sublime-text",
  "org.gnome.texteditor": "gnome-text-editor",
  "gnome-text-editor": "gnome-text-editor",
  "obsidian": "obsidian",
  "notion-app": "notion",
  "notion": "notion",
  "todoist": "todoist",
  "anytype": "anytype",
  "logseq": "logseq",
  "libreoffice-writer": "libreoffice-writer",
  "libreoffice-calc": "libreoffice-calc",
  "libreoffice-impress": "libreoffice-impress",
  "libreoffice": "libreoffice-writer",
  "soffice.bin": "libreoffice-writer",
  "thunderbird": "thunderbird",
  "org.gnome.evolution": "evolution",
  "evolution": "evolution",
  "org.gnome.geary": "geary",
  "geary": "geary",
  "discord": "discord",
  "whatsapp": "whatsapp",
  "whatsapp-for-linux": "whatsapp",
  "org.telegram.desktop": "telegram",
  "telegram": "telegram",
  "telegram-desktop": "telegram",
  "signal": "signal",
  "signal-desktop": "signal",
  "slack": "slack",
  "zoom": "zoom",
  "zoom-client": "zoom",
  "element": "element",
  "element-desktop": "element",
  "skype": "skype",
  "skypeforlinux": "skype",
  "vlc": "vlc",
  "mpv": "mpv",
  "celluloid": "celluloid",
  "io.github.celluloid_player.celluloid": "celluloid",
  "com.obsproject.studio": "obs-studio",
  "obs": "obs-studio",
  "kdenlive": "kdenlive",
  "org.kde.kdenlive": "kdenlive",
  "resolve": "davinci-resolve",
  "davinci-resolve": "davinci-resolve",
  "blender": "blender",
  "shotcut": "shotcut",
  "org.shotcut.shotcut": "shotcut",
  "spotify": "spotify",
  "org.gnome.rhythmbox3": "rhythmbox",
  "rhythmbox": "rhythmbox",
  "audacity": "audacity",
  "gimp": "gimp",
  "org.inkscape.inkscape": "inkscape",
  "inkscape": "inkscape",
  "pinta": "pinta",
  "com.github.pintaproject.pinta": "pinta",
  "xournalpp": "xournalpp",
  "com.github.xournalpp.xournalpp": "xournalpp",
  "imv": "imv",
  "org.gnome.eog": "eog",
  "eog": "eog",
  "org.gnome.gthumb": "gthumb",
  "gthumb": "gthumb",
  "org.gnome.loupe": "loupe",
  "loupe": "loupe",
  "org.gnome.evince": "evince",
  "evince": "evince",
  "org.gnome.papers": "papers",
  "papers": "papers",
  "org.kde.okular": "okular",
  "okular": "okular",
  "com.github.johnfactotum.foliate": "foliate",
  "foliate": "foliate",
  "dropbox": "dropbox",
  "localsend_app": "localsend",
  "localsend": "localsend",
  "de.haeckerfelix.fragments": "fragments",
  "fragments": "fragments",
  "org.gnome.meld": "meld",
  "meld": "meld",
  "docker-desktop": "docker-desktop",
  "docker desktop": "docker-desktop",
  "dbeaver": "dbeaver",
  "postman": "postman",
  "filezilla": "filezilla",
  "org.wireshark.wireshark": "wireshark",
  "wireshark": "wireshark",
  "org.godotengine.godot": "godot",
  "godot": "godot",
  "steam": "steam",
  "heroic": "heroic",
  "heroicgameslauncher": "heroic",
  "net.lutris.lutris": "lutris",
  "lutris": "lutris",
  "retroarch": "retroarch",
  "com.moonlight_stream.moonlight": "moonlight",
  "moonlight": "moonlight",
  "virt-manager": "virt-manager",
  "ca.desrt.dconf-editor": "dconf-editor",
  "dconf-editor": "dconf-editor",
  "1password": "1password",
  "1password-client": "1password",
  "bitwarden": "bitwarden",
  "bitwarden-desktop": "bitwarden",
  "keepassxc": "keepassxc",
  "org.gnome.systemmonitor": "gnome-system-monitor",
  "gnome-system-monitor": "gnome-system-monitor",
  "io.missioncenter.missioncenter": "mission-center",
  "mission-center": "mission-center",
  "org.gnome.baobab": "baobab",
  "baobab": "baobab",
  "org.gnome.diskutility": "gnome-disks",
  "gnome-disks": "gnome-disks",
  "gparted": "gparted",
  "timeshift-gtk": "timeshift",
  "timeshift": "timeshift",
  "pavucontrol": "pavucontrol",
  "org.gnome.extensions": "gnome-extensions",
  "gnome-extensions": "gnome-extensions",
  "org.gnome.calendar": "gnome-calendar",
  "gnome-calendar": "gnome-calendar",
  "org.gnome.calculator": "gnome-calculator",
  "gnome-calculator": "gnome-calculator"
};

function normalizeAppId(raw) {
  var text = String(raw === undefined || raw === null ? "" : raw)
    .replace(/^\s+|\s+$/g, "").toLowerCase();
  if (text === "") return FALLBACK_APP;
  // "org.foo.Bar.desktop" -> "org.foo.bar"; strip a trailing ".desktop".
  text = text.replace(/\.desktop$/, "");
  if (ALIASES[text]) return ALIASES[text];
  // Last dotted segment: "org.gnome.Foo" -> "foo".
  var short = text.indexOf(".") !== -1 ? text.split(".").pop() : text;
  if (ALIASES[short]) return ALIASES[short];
  if (GLYPHS[short]) return short;
  return FALLBACK_APP;
}

function glyphFor(appKey) {
  return GLYPHS[appKey] || GLYPHS[FALLBACK_APP];
}

function displayNameFor(appKey) {
  return DISPLAY_NAMES[appKey] || DISPLAY_NAMES[FALLBACK_APP];
}

// Case-insensitive substring match over keys + action (both languages).
function filterItems(groups, query) {
  var q = String(query === undefined || query === null ? "" : query)
    .replace(/^\s+|\s+$/g, "").toLowerCase();
  if (q === "") return groups || [];
  var out = [];
  for (var g = 0; g < (groups || []).length; g++) {
    var group = groups[g];
    var items = [];
    for (var i = 0; i < (group.items || []).length; i++) {
      var item = group.items[i];
      var hay = ((item.keys || []).join(" ") + " " + (item.action || "") + " " + (item.actionRu || "")).toLowerCase();
      if (hay.indexOf(q) !== -1) items.push(item);
    }
    if (items.length > 0) {
      var outGroup = { title: group.title, items: items };
      if (group.titleRu !== undefined) outGroup.titleRu = group.titleRu;
      out.push(outGroup);
    }
  }
  return out;
}

function countItems(groups) {
  var n = 0;
  for (var g = 0; g < (groups || []).length; g++) n += ((groups[g] || {}).items || []).length;
  return n;
}

// Visible groups with maxItems cap applied (0 = unlimited).
function limitGroups(groups, maxItems) {
  var cap = Math.round(Number(maxItems) || 0);
  if (cap <= 0) return groups || [];
  var out = [];
  var left = cap;
  for (var g = 0; g < (groups || []).length && left > 0; g++) {
    var items = (groups[g].items || []).slice(0, left);
    left -= items.length;
    if (items.length > 0) {
      var entry = { title: groups[g].title, items: items };
      if (groups[g].titleRu !== undefined) entry.titleRu = groups[g].titleRu;
      out.push(entry);
    }
  }
  return out;
}

if (typeof module !== "undefined") {
  module.exports = {
    FALLBACK_APP: FALLBACK_APP,
    GLYPHS: GLYPHS,
    DISPLAY_NAMES: DISPLAY_NAMES,
    normalizeAppId: normalizeAppId,
    glyphFor: glyphFor,
    displayNameFor: displayNameFor,
    displayNameForKey: displayNameForKey,
    isRussian: isRussian,
    tr: tr,
    dataDisplayName: dataDisplayName,
    groupTitle: groupTitle,
    itemAction: itemAction,
    filterItems: filterItems,
    countItems: countItems,
    limitGroups: limitGroups
  };
}
