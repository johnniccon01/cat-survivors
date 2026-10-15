#!/usr/bin/env bash
# Runs every automated scenario headless (4 at a time) and reports script
# errors.
#   bash tools/run_checks.sh [path-to-godot-console-exe]
# Exit code is the number of failing scenarios.
GODOT="${1:-/c/Users/john.niccon/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe}"
JOBS="${JOBS:-4}"
cd "$(dirname "$0")/.." || exit 1

scenarios=(
  "apartment|--bot --bot-time=300"
  "basement|--bot --stage=BASEMENT --bot-time=300"
  "late_apartment|--bot --start-minute=12 --catch-up --bot-time=240"
  "final_vacuum|--bot --start-minute=19.9 --catch-up --bot-time=60"
  "final_rat|--bot --stage=BASEMENT --start-minute=19.9 --catch-up --bot-time=60"
  "garden|--bot --stage=GARDEN --bot-time=300"
  "rooftop|--bot --stage=ROOFTOP --bot-time=300"
  "late_rooftop|--bot --stage=ROOFTOP --start-minute=12 --catch-up --bot-time=240"
  "final_mower|--bot --stage=GARDEN --start-minute=19.9 --catch-up --bot-time=60"
  "final_pigeon|--bot --stage=ROOFTOP --start-minute=19.9 --catch-up --bot-time=60"
  "traps_garden|--bot --stage=GARDEN --traps --bot-time=60"
  "traps_rooftop|--bot --stage=ROOFTOP --traps --bot-time=60"
  "all_weapons|--bot --all-weapons --levels=30 --bot-time=200"
  "evolution_mica|--test-evolution --cat=MICA"
  "evolution_luna|--test-evolution --cat=LUNA"
  "evolution_snow|--test-evolution --cat=SNOWBALL"
  "evolution_pip|--test-evolution --cat=PIP"
  "evolution_tiger|--test-evolution --cat=TIGER"
  "evolution_baron|--test-evolution --cat=BARON"
  "quest_snowball|--bot --levels=20 --quest=SNOWBALL --bot-time=150"
  "quest_pip|--bot --levels=20 --quest=PIP --bot-time=150"
  "quest_luna|--bot --stage=BASEMENT --levels=20 --quest=LUNA --bot-time=150"
  "quest_tiger|--bot --stage=BASEMENT --levels=30 --quest=TIGER --bot-time=150"
  "quest_baron|--bot --levels=30 --quest=BARON --bot-time=150"
  "quest_collar|--bot --levels=20 --quest=COLLAR --bot-time=120"
  "quest_bowl|--bot --levels=20 --quest=DEFEND_BOWL --bot-time=120"
  "quest_dot|--bot --levels=20 --quest=RED_DOT --bot-time=90"
  "quest_fridge|--bot --levels=20 --quest=FRIDGE --bot-time=120"
  "duel_into_final|--bot --levels=30 --quest=TIGER --stage=BASEMENT --start-minute=19.8 --catch-up --bot-time=40"
  "extract_charm|--bot --drop-charm --extract --bot-time=60"
  "traps|--bot --traps --bot-time=60"
)

run_one() {
  local entry="$1" name args out errors summary
  name="${entry%%|*}"
  args="${entry#*|}"
  out=$(timeout 280 "$GODOT" --headless --path . -- $args 2>&1)
  errors=$(echo "$out" | grep -E "SCRIPT ERROR|Parse Error|ERROR: " | grep -vE "resources still in use|ObjectDB instances leaked" | sort | uniq -c | head -5)
  summary=$(echo "$out" | grep -E "^(BOT|TEST): (time|weapons after|quests_done|active quest)" | tr '\n' ' ' | cut -c1-200)
  if [ -n "$errors" ]; then
    printf 'FAIL %s: %s\n%s\n' "$name" "$summary" "$(echo "$errors" | sed 's/^/     /')"
  else
    printf 'ok   %s: %s\n' "$name" "$summary"
  fi
}
export -f run_one
export GODOT

printf '%s\n' "${scenarios[@]}" | xargs -P "$JOBS" -I{} bash -c 'run_one "$@"' _ {} | tee /tmp/catsurvivors_checks.txt
fail=$(grep -c '^FAIL' /tmp/catsurvivors_checks.txt)
echo "failing scenarios: $fail"
exit "$fail"
