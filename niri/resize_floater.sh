#!/usr/bin/env bash

set -eu

target_width="${1:-800}"
target_height="${2:-600}"

resize_floating_windows() {
	python3 -c '
import json
import subprocess
import sys

target_width = int(sys.argv[1])
target_height = int(sys.argv[2])
windows = json.load(sys.stdin)

for window in windows:
	if not window.get("is_floating"):
		continue

	layout = window.get("layout") or {}
	window_size = layout.get("window_size") or []
	current_width = window_size[0] if len(window_size) > 0 else None
	current_height = window_size[1] if len(window_size) > 1 else None
	window_id = window.get("id")

	if window_id is None:
		continue

	if current_width != target_width:
		subprocess.run([
			"niri",
			"msg",
			"action",
			"set-window-width",
			"--id",
			str(window_id),
			str(target_width),
		], check=True)

	if current_height != target_height:
		subprocess.run([
			"niri",
			"msg",
			"action",
			"set-window-height",
			"--id",
			str(window_id),
			str(target_height),
		], check=True)
' "$target_width" "$target_height" < <(niri msg -j windows)
}

resize_floating_windows

while IFS= read -r event; do
	case "$event" in
		Windows\ changed:*|Workspaces\ changed:*|Config\ loaded\ successfully)
			resize_floating_windows
			;;
	esac
done < <(niri msg event-stream)
