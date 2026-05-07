#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$ROOT/resize_floater.sh"
CONFIG="$ROOT/config.kdl"

command -v niri >/dev/null 2>&1 || { echo "niri not found in PATH; ensure niri is installed and in PATH"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 not found in PATH; install python3"; exit 1; }

if [ -f "$SCRIPT" ]; then
  chmod +x "$SCRIPT"
  echo "Made $SCRIPT executable"
else
  echo "Error: $SCRIPT not found in $ROOT"
  exit 1
fi

if [ -f "$CONFIG" ]; then
  if ! grep -Fq "$SCRIPT" "$CONFIG"; then
    printf '\nspawn-at-startup "%s"\n' "$SCRIPT" >> "$CONFIG"
    echo "Appended spawn-at-startup entry to $CONFIG"
  else
    echo "Startup entry already present in $CONFIG"
  fi
else
  echo "Warning: $CONFIG not found; created minimal config with spawn entry"
  mkdir -p "$ROOT"
  printf 'spawn-at-startup "%s"\n' "$SCRIPT" > "$CONFIG"
fi

echo "Install complete. To apply changes, restart your session or reload niri configuration."
