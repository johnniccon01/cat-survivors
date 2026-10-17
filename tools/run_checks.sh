#!/usr/bin/env bash
# Runs every automated scenario headless (12 at a time) and reports script
# errors.
#   bash tools/run_checks.sh [path-to-godot-console-exe]
# Exit code is the number of failing scenarios.
GODOT="${1:-/c/Users/john.niccon/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe}"
JOBS="${JOBS:-12}"
cd "$(dirname "$0")/.." || exit 1

# "name|args after --" or "name|args after --|engine args" (e.g. a -s script).
scenarios=(
  "menus|--ui-test|-s res://tools/ui_test.gd"
  "apartment|--bot --bot-time=300"
  "basement|--bot --stage=BASEMENT --cat=TIGER --bot-time=300"
  "late_apartment|--bot --start-minute=12 --catch-up --bot-time=240"
  "final_vacuum|--bot --start-minute=19.9 --catch-up --bot-time=60"
  "final_rat|--bot --stage=BASEMENT --start-minute=19.9 --catch-up --bot-time=60"
  "garden|--bot --stage=GARDEN --cat=TIGER --bot-time=300"
  "rooftop|--bot --stage=ROOFTOP --cat=TIGER --bot-time=300"
  "late_rooftop|--bot --stage=ROOFTOP --start-minute=12 --catch-up --bot-time=240"
  "final_mower|--bot --stage=GARDEN --start-minute=19.9 --catch-up --bot-time=60"
  "final_bruno|--bot --stage=ROOFTOP --start-minute=19.9 --catch-up --bot-time=60"
  "traps_garden|--bot --stage=GARDEN --traps --bot-time=60"
  "traps_rooftop|--bot --stage=ROOFTOP --traps --bot-time=60"
  "all_weapons|--bot --all-weapons --levels=30 --bot-time=200"
  "evolution_mica|--test-evolution --cat=MICA"
  "evolution_luna|--test-evolution --cat=LUNA"
  "evolution_snow|--test-evolution --cat=SNOWBALL"
  "evolution_pip|--test-evolution --cat=PIP"
  "evolution_tiger|--test-evolution --cat=TIGER"
  "evolution_baron|--test-evolution --cat=BARON"
  "evolution_clover|--test-evolution --cat=CLOVER"
  "evolution_bruno|--test-evolution --cat=BRUNO"
  "evolution_mouse|--test-evolution --start-weapon=MOUSE_TOY"
  "evolution_cobweb|--test-evolution --start-weapon=COBWEB"
  "evolution_sprinkler|--test-evolution --start-weapon=SPRINKLER"
  "evolution_antenna|--test-evolution --start-weapon=ANTENNA"
  "branches_fx|--bot --start-weapon=SCRATCH,LASER,MILK,HAIRBALL,BELL,ANTENNA --branch=SCRATCH:FLAME_CLAWS:2,LASER:OVERLOAD:2,MILK:ICY_MILK:2,HAIRBALL:EXPLOSIVE:2,BELL:THUNDER_RING:1,ANTENNA:SHORT_CIRCUIT:2 --levels=10 --bot-time=120"
  "branches_misc|--bot --start-minute=6 --catch-up --start-weapon=FISHBONES,SCRATCH,YARN,COBWEB,SPRINKLER,MOUSE_TOY --branch=FISHBONES:SHARP_BONES:2,SCRATCH:BLOODTHIRST:2,YARN:RICOCHET:2,COBWEB:VENOM:1,SPRINKLER:BOILING:2,MOUSE_TOY:FIRECRACKER:2 --bot-time=500"
  "new_weapons|--bot --start-minute=8 --catch-up --start-weapon=ANTENNA --all-weapons --bot-time=600"
  "quest_clover|--bot --stage=GARDEN --levels=20 --quest=CLOVER --bot-time=150"
  "angel_devil|--bot --stage=ROOFTOP --start-minute=16 --catch-up --angel-chance=1 --kill-cat-every=8 --bot-time=90"
  "devil_kills|--bot --stage=ROOFTOP --start-minute=16 --catch-up --angel-chance=1 --devil --bot-time=60"
  "devil_mortal|--bot --stage=ROOFTOP --start-minute=29.9 --catch-up --devil --bot-time=30"
  "quest_snowball|--bot --levels=20 --quest=SNOWBALL --bot-time=150"
  "quest_pip|--bot --levels=20 --quest=PIP --bot-time=150"
  "quest_luna|--bot --stage=BASEMENT --levels=20 --quest=LUNA --bot-time=150"
  "quest_tiger|--bot --stage=BASEMENT --levels=30 --quest=TIGER --bot-time=150"
  "quest_baron|--bot --levels=30 --quest=BARON --bot-time=150"
  "story_map|--bot --stage=BASEMENT --cat=TIGER --levels=20 --quest=OLD_MAP --bot-time=120"
  "story_key|--bot --stage=GARDEN --cat=TIGER --levels=20 --quest=ROOF_KEY --bot-time=120"
  "story_note|--bot --stage=ROOFTOP --cat=TIGER --levels=20 --quest=BRUNO_NOTE --bot-time=120"
  "quest_collar|--bot --levels=20 --quest=COLLAR --bot-time=120"
  "quest_bowl|--bot --levels=20 --quest=DEFEND_BOWL --bot-time=120"
  "quest_dot|--bot --levels=20 --quest=RED_DOT --bot-time=90"
  "quest_fridge|--bot --levels=20 --quest=FRIDGE --bot-time=120"
  "duel_into_final|--bot --levels=30 --quest=TIGER --stage=BASEMENT --start-minute=19.8 --catch-up --bot-time=40"
  "extract_charm|--bot --drop-charm --extract --bot-time=60"
  "traps|--bot --traps --bot-time=60"
  "champions|--bot --start-minute=6 --catch-up --champions --bot-time=480"
  "golden_mouse|--bot --golden --levels=20 --bot-time=60"
  "endless|--bot --stage=GARDEN --start-minute=20 --catch-up --cat=TIGER --endless-now --bot-time=480"
  "midboss_iron|--bot --stage=LIVING_ROOM --start-minute=11.9 --catch-up --cat=TIGER --bot-time=120"
  "midboss_boiler|--bot --stage=BASEMENT --start-minute=12.9 --catch-up --cat=TIGER --bot-time=120"
  "midboss_scarecrow|--bot --stage=GARDEN --start-minute=12.9 --catch-up --cat=TIGER --bot-time=120"
  "midboss_cloud|--bot --stage=ROOFTOP --start-minute=12.9 --catch-up --cat=TIGER --bot-time=120"
  "challenges|--bot --challenges=HYPER,GLASS,NO_HEAL,ONE_WEAPON,CURSED --levels=10 --bot-time=180"
  "tutorial|--bot --tutorial --bot-time=120"
  "diary_page|--bot --page --extract --levels=20 --bot-time=150"
  "supermarket|--bot --stage=SUPERMARKET --cat=TIGER --bot-time=300"
  "harbor|--bot --stage=HARBOR --cat=TIGER --bot-time=300"
  "late_supermarket|--bot --stage=SUPERMARKET --start-minute=12 --catch-up --bot-time=240"
  "late_harbor|--bot --stage=HARBOR --start-minute=12 --catch-up --bot-time=240"
  "final_rex|--bot --stage=SUPERMARKET --start-minute=19.9 --catch-up --bot-time=60"
  "final_kraken|--bot --stage=HARBOR --start-minute=19.9 --catch-up --bot-time=60"
  "traps_supermarket|--bot --stage=SUPERMARKET --traps --bot-time=60"
  "traps_harbor|--bot --stage=HARBOR --traps --bot-time=60"
  "quest_tucko|--bot --stage=SUPERMARKET --levels=20 --quest=TUCKO --bot-time=150"
  "quest_kapitan|--bot --stage=HARBOR --levels=30 --quest=KAPITAN --bot-time=150"
  "story_ticket|--bot --stage=SUPERMARKET --cat=TIGER --levels=20 --quest=SHIP_TICKET --bot-time=120"
  "story_bottle|--bot --stage=HARBOR --cat=TIGER --levels=20 --quest=BOTTLE_MESSAGE --bot-time=120"
  "midboss_register|--bot --stage=SUPERMARKET --start-minute=12.9 --catch-up --cat=TIGER --bot-time=120"
  "midboss_anchor|--bot --stage=HARBOR --start-minute=12.9 --catch-up --cat=TIGER --bot-time=120"
)

run_one() {
  local entry="$1" name args engine out errors summary
  name="${entry%%|*}"
  args="${entry#*|}"
  engine=""
  if [[ "$args" == *"|"* ]]; then
    engine="${args#*|}"
    args="${args%%|*}"
  fi
  # Own log file, so test runs never push the player's logs out of the rotation.
  out=$(timeout 280 "$GODOT" --headless --log-file "${TMPDIR:-/tmp}/catsurvivors_$name.log" --path . $engine -- $args 2>&1)
  errors=$(echo "$out" | grep -E "SCRIPT ERROR|Parse Error|ERROR: |UI: FAIL" | grep -vE "resources still in use|ObjectDB instances leaked" | sort | uniq -c | head -5)
  summary=$(echo "$out" | grep -E "^(BOT|TEST): (time|weapons after|quests_done|active quest)|^UI: done" | tr '\n' ' ' | cut -c1-200)
  if [ -n "$errors" ]; then
    printf 'FAIL %s: %s\n%s\n' "$name" "$summary" "$(echo "$errors" | sed 's/^/     /')"
  else
    printf 'ok   %s: %s\n' "$name" "$summary"
  fi
}
export -f run_one
export GODOT

# ONLY="name1|name2" runs just those scenarios.
printf '%s\n' "${scenarios[@]}" | grep -E "^(${ONLY:-[^|]+})\|" | xargs -P "$JOBS" -I{} bash -c 'run_one "$@"' _ {} | tee /tmp/catsurvivors_checks.txt
fail=$(grep -c '^FAIL' /tmp/catsurvivors_checks.txt)
# Translations: both languages present, placeholders matching, keys known.
if ! python -I tools/check_strings.py | grep -v " 0 problems"; then :; fi
if ! python -I tools/check_strings.py > /dev/null; then
  echo "FAIL strings: see python tools/check_strings.py"
  fail=$((fail + 1))
fi
echo "failing scenarios: $fail"
exit "$fail"
