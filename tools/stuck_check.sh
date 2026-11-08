#!/usr/bin/env bash
# Stuck-enemy check on every map, several maps at once (fast):
#   bash tools/stuck_check.sh [path-to-godot-console-exe]
#   JOBS=6 SECONDS_PER_MAP=180 bash tools/stuck_check.sh
# Prints one line per map: how many enemies stood pressed against a wall or
# tree for 6 s while far from the cat (Enemy manager, --stuck-check).
GODOT="${1:-/c/Users/john.niccon/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe}"
JOBS="${JOBS:-6}"
export GODOT T="${SECONDS_PER_MAP:-180}"
cd "$(dirname "$0")/.." || exit 1
python -c "import json;print('\n'.join(json.load(open('data/stages.json',encoding='utf-8'))))" | tr -d '\r' |
  xargs -P "$JOBS" -I{} bash -c 'out=$(timeout 300 "$GODOT" --headless --path . -- --bot --god --stage={} --bot-time=$T --stuck-check 2>&1 | grep -E "^STUCK|SCRIPT ERROR" | head -2); printf "%-16s %s\n" {} "$out"' | sort
