#!/usr/bin/env node
// test-model.js — unit tests for Model.js (no Qt needed).
// Usage: node scripts/test-model.js
const fs = require("fs");
const path = require("path");
const M = require("../Model.js");

let fail = 0;
const check = (name, cond) => {
  if (!cond) {
    console.log(`FAIL ${name}`);
    fail++;
  }
};

// normalizeAppId
const normCases = [
  ["zen-browser", "zen"], ["Firefox", "firefox"], ["footclient", "foot"],
  ["org.gnome.Nautilus.desktop", "nautilus"], ["nvim", "neovim"],
  ["dev.zed.Zed", "zed"], ["code", "vscode"], ["org.telegram.desktop", "telegram"],
  ["Alacritty", "alacritty"], ["", "globals"], [null, "globals"],
  ["SomeUnknownApp-1.2", "globals"],
];
for (const [input, want] of normCases)
  check(`normalize(${JSON.stringify(input)})=${want}`, M.normalizeAppId(input) === want);

// every glyph key has a display name and vice versa
for (const k of Object.keys(M.GLYPHS)) {
  check(`glyph non-empty ${k}`, !!M.glyphFor(k));
  check(`display name ${k}`, !!M.displayNameFor(k));
}

// every data file id is known to the Model (icon + name render)
const dir = path.join(__dirname, "..", "shortcuts");
for (const f of fs.readdirSync(dir)) {
  if (!f.endsWith(".json")) continue;
  const d = JSON.parse(fs.readFileSync(path.join(dir, f), "utf8"));
  check(`model knows ${d.appId}`, M.GLYPHS[d.appId] !== undefined);
}

// locale: all UI keys resolve in all supported locales, fallback to EN
for (const l of ["en_US", "ru_RU", "de_DE", "fr_FR", "es_ES", "pt_BR", "ja_JP"])
  for (const k of ["searchPlaceholder", "shortcutsCount", "tooltipSuffix", "nothingFound", "noEntries", "noData", "unknownAppNote"])
    check(`tr(${k},${l})`, !!M.tr(k, l));

// locale data picks + cross-language search
const groups = [{ title: "Tabs", titleRu: "Вкладки", items: [{ keys: ["Ctrl+T"], action: "New tab", actionRu: "Новая вкладка", actionDe: "Neuer Tab" }] }];
check("groupTitle ru", M.groupTitle(groups[0], "ru_RU") === "Вкладки");
check("itemAction de", M.itemAction(groups[0].items[0], "de_DE") === "Neuer Tab");
check("search en", M.filterItems(groups, "tab").length === 1);
check("search ru", M.filterItems(groups, "вкладка").length === 1);
check("search de", M.filterItems(groups, "neuer").length === 1);
check("limit keeps variants", M.limitGroups(groups, 5)[0].titleRu === "Вкладки");

console.log(fail === 0 ? "MODEL TESTS OK" : `MODEL FAILURES: ${fail}`);
process.exit(fail === 0 ? 0 : 1);
