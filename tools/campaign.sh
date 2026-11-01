#!/usr/bin/env bash
# Campaign test: one cat plays every map in unlock order, a whole night each
# (final boss included), on its own test profile so progress, gold, gear and
# unlocks carry from night to night like for a new player. The bot is raised
# again when it dies (--revive), so the run always reaches the final boss.
# After each night it spends its gold on upgrades (--shop) like a player.
#   bash tools/campaign.sh [path-to-godot-console-exe]
#   CAT=TIGER SPEED=8 STAGES="LIVING_ROOM BASEMENT" bash tools/campaign.sh
# Exit code is the number of maps that were not won or printed errors.
GODOT="${1:-/c/Users/john.niccon/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe}"
CAT="${CAT:-MICA}"
SPEED="${SPEED:-8}"
STAGES="${STAGES:-LIVING_ROOM BASEMENT GARDEN ROOFTOP SUPERMARKET HARBOR FACTORY PARK CEMETERY ISLAND STATION}"
cd "$(dirname "$0")/.." || exit 1
OUT="${TMPDIR:-/tmp}/catsurvivors_campaign"
mkdir -p "$OUT"
PROFILE="$(cd "$OUT" && pwd -W 2>/dev/null || pwd)/profile.cfg"
[ -z "$KEEP" ] && rm -f "$PROFILE"
fail=0
for stage in $STAGES; do
  start=$(date +%s)
  out=$(timeout 900 "$GODOT" --headless --log-file "$OUT/$stage.log" --path . -- \
    --bot --revive --cat="$CAT" --stage="$stage" --bot-time=1700 --bot-speed="$SPEED" \
    --profile="$PROFILE" --shop $EXTRA 2>&1)
  echo "$out" > "$OUT/$stage.out"
  errors=$(echo "$out" | grep -E "SCRIPT ERROR|Parse Error|ERROR: |TEST: FAIL" | grep -vE "resources still in use|ObjectDB instances leaked" | sort | uniq -c | head -5)
  line=$(echo "$out" | grep -E "^BOT: time=" | head -1)
  won=$(echo "$out" | grep -oE "won=(true|false)" | head -1)
  rev=$(echo "$out" | grep -oE "revives=[0-9]+ end=[a-z]*" | head -1)
  weapons=$(echo "$out" | grep -oE "^BOT: weapons=.*passives" | head -1 | sed 's/^BOT: //; s/ passives$//')
  quests=$(echo "$out" | grep -oE "quests_done=[0-9]+" | head -1)
  bosses=$(echo "$out" | grep -oE "bosses_killed=[0-9]+" | head -1)
  status=ok
  if [ "$won" != "won=true" ] || [ -n "$errors" ]; then status=FAIL; fail=$((fail + 1)); fi
  printf '%-4s %-12s %3ss %s %s %s %s %s\n     %s\n' "$status" "$stage" "$(( $(date +%s) - start ))" "$won" "$rev" "$bosses" "$quests" "$line" "$weapons"
  [ -n "$errors" ] && echo "$errors" | sed 's/^/     /'
done
echo "cleared: $(grep -E '^cleared=' "$PROFILE" 2>/dev/null)"
echo "unlocked cats: $(grep -E '^unlocked=' "$PROFILE" 2>/dev/null | head -1)"
echo "campaign maps failing: $fail"
exit "$fail"
