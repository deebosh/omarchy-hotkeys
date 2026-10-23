#!/bin/bash
# test.sh — one-command verification for deebosh.hotkeys.
# Node checks run anywhere; omarchy checks need an Omarchy shell host.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== data schema =="
node scripts/check-data.js > /tmp/opencode/hotkeys-checkdata.log 2>&1
tail -n 1 /tmp/opencode/hotkeys-checkdata.log

echo "== model unit tests =="
node scripts/test-model.js

if command -v omarchy >/dev/null 2>&1; then
  echo "== plugin validate =="
  omarchy plugin validate .
  echo "validate OK"
else
  echo "== plugin validate skipped (no omarchy CLI) =="
fi

if command -v qmllint >/dev/null 2>&1 && [[ -n "${OMARCHY_PATH:-}" ]]; then
  echo "== qmllint =="
  qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml
  echo "qmllint OK"
else
  echo "== qmllint skipped (needs OMARCHY_PATH + qmllint) =="
fi

echo "ALL TESTS OK"
