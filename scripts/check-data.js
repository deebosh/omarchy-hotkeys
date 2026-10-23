#!/usr/bin/env node
// check-data.js — schema validation for shortcuts/*.json (+ manifest).
// Usage: node scripts/check-data.js
const fs = require("fs");
const path = require("path");
const root = path.join(__dirname, "..");
const dir = path.join(root, "shortcuts");

let fail = 0;
const err = (f, m) => { console.log(`FAIL ${f}: ${m}`); fail++; };

const files = fs.readdirSync(dir).filter((f) => f.endsWith(".json"));
const ids = new Set();
for (const f of files) {
  const p = path.join(dir, f);
  let d;
  try {
    d = JSON.parse(fs.readFileSync(p, "utf8"));
  } catch (e) {
    err(f, "invalid JSON: " + e.message);
    continue;
  }
  for (const k of ["appId", "displayName", "source", "groups"])
    if (d[k] === undefined || d[k] === "") err(f, `missing/empty '${k}'`);
  if (d.appId && d.appId !== "globals" && f !== `${d.appId}.json`)
    err(f, `file name must be <appId>.json (appId=${d.appId})`);
  if (d.appId) {
    if (ids.has(d.appId)) err(f, `duplicate appId ${d.appId}`);
    ids.add(d.appId);
  }
  if (!Array.isArray(d.groups) || d.groups.length === 0) {
    // Empty groups allowed only as an honest stub (e.g. localsend: the app
    // genuinely has no documented hotkeys). Warn, don't fail.
    if (!Array.isArray(d.groups)) err(f, "groups must be an array");
    else console.log(`WARN ${f}: empty groups (stub)`);
    console.log(`OK ${f} groups:0 items:0`);
    continue;
  }
  let n = 0;
  d.groups.forEach((g, gi) => {
    if (!g.title) err(f, `groups[${gi}].title missing (EN base required)`);
    if (g.titleRu !== undefined && !g.titleRu) err(f, `groups[${gi}].titleRu empty`);
    if (!Array.isArray(g.items) || g.items.length === 0) {
      err(f, `groups[${gi}].items empty`);
      return;
    }
    g.items.forEach((it, ii) => {
      n++;
      if (!Array.isArray(it.keys) || it.keys.length === 0 || it.keys.some((k) => !k))
        err(f, `groups[${gi}].items[${ii}].keys invalid`);
      if (!it.action) err(f, `groups[${gi}].items[${ii}].action missing (EN base required)`);
      if (it.actionRu !== undefined && !it.actionRu)
        err(f, `groups[${gi}].items[${ii}].actionRu empty`);
    });
  });
  console.log(`OK ${f} groups:${d.groups.length} items:${n}`);
}
console.log(fail === 0 ? `ALL OK (${files.length} files)` : `FAILURES: ${fail}`);
process.exit(fail === 0 ? 0 : 1);
