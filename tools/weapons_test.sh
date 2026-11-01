#!/usr/bin/env bash
# Every weapon (base and evolved) alone for a while: does it fire, hit and
# kill, and how much damage does it deal next to the others?
#   bash tools/weapons_test.sh [path-to-godot-console-exe]
#   WEAPONS="LASER BELL" TIME=120 bash tools/weapons_test.sh
#   EXTRA="--start-minute=10 --catch-up" bash tools/weapons_test.sh   (late game)
# Prints one line per weapon sorted by damage; exit code = weapons that dealt
# no damage or printed errors.
GODOT="${1:-/c/Users/john.niccon/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe}"
TIME="${TIME:-120}"
JOBS="${JOBS:-8}"
cd "$(dirname "$0")/.." || exit 1
WEAPONS="${WEAPONS:-$(python -c "import json;print(' '.join(json.load(open('data/weapons.json',encoding='utf-8'))))")}"
OUT="${TMPDIR:-/tmp}/catsurvivors_weapons"
mkdir -p "$OUT"

one() {
  local w="$1" out errors dealt kills
  # --no-new-weapons keeps the bot from picking up other weapons, so the damage
  # is this weapon's alone; the cat can't die so every weapon gets its time.
  out=$(timeout 300 "$GODOT" --headless --log-file "$OUT/$w.log" --path . -- \
    --bot --god --seed=7 --start-weapon="$w" --no-new-weapons --bot-time="$TIME" --bot-speed=8 $EXTRA 2>&1)
  errors=$(echo "$out" | grep -E "SCRIPT ERROR|Parse Error|ERROR: " | grep -vE "resources still in use|ObjectDB instances leaked" | sort -u | head -3)
  dealt=$(echo "$out" | grep -oE "^BOT: damage by weapon=.*" | sed 's/BOT: damage by weapon=//')
  kills=$(echo "$out" | grep -oE "kills=[0-9]+" | head -1)
  local mine
  mine=$(echo " $dealt " | grep -oE " $w:[0-9]+" | cut -d: -f2)
  printf '%8s %-16s %s | %s\n' "${mine:-0}" "$w" "$kills" "$dealt"
  [ -n "$errors" ] && echo "$errors" | sed "s/^/   ERR $w: /"
}
export -f one
export GODOT TIME OUT EXTRA
printf '%s\n' $WEAPONS | xargs -P "$JOBS" -I{} bash -c 'one "$@"' _ {} | tee "$OUT/all.txt" >/dev/null
sort -n -r "$OUT/all.txt" | grep -v ' ERR '
grep ' ERR ' "$OUT/all.txt"
bad=$(awk '$1 == "0" || /ERR/' "$OUT/all.txt" | wc -l)
echo "weapons without damage or with errors: $bad"
exit "$bad"
