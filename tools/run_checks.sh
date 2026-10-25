#!/usr/bin/env bash
# Runs every automated scenario headless (12 at a time) and reports script
# errors.
#   bash tools/run_checks.sh [path-to-godot-console-exe]
#   ONLY="harbor|final_kraken" bash tools/run_checks.sh   (just those)
#   QUICK=1 bash tools/run_checks.sh   (a quick round between steps: a set of
#   scenarios covering every map and system, each at most 90 s of game time)
# Exit code is the number of failing scenarios.
GODOT="${1:-/c/Users/john.niccon/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe}"
JOBS="${JOBS:-12}"
cd "$(dirname "$0")/.." || exit 1

# "name|args after --" or "name|args after --|engine args" (e.g. a -s script).
scenarios=(
  "menus|--ui-test|-s res://tools/ui_test.gd"
  "text_fit|--ui-test|-s res://tools/text_fit_test.gd"
  "dev_boss_rush|--bot --strong --god --boss-rush --bot-time=1500 --bot-speed=8"
  "dev_quests|--bot --strong --god --dev-quest-all --bot-time=900 --bot-speed=8"
  "dev_boss_kraken|--bot --stage=HARBOR --strong --dev-boss=KRAKEN --bot-time=120"
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
  "stray|--bot --cat=STRAY --bot-time=200"
  "stray_grows|--bot --cat=STRAY --god --bot-time=400"
  "music_alt|--bot --stage=GARDEN --music=alt --bot-time=40"
  "shrine_cursed|--bot --shrine=CURSED --choice=2 --start-minute=8 --catch-up --bot-time=120"
  "shrine_cursed_small|--bot --shrine=CURSED --choice=1 --start-minute=4 --catch-up --bot-time=100"
  "shrine_fortune|--bot --shrine=FORTUNE --choice=1 --bot-time=60"
  "shrine_haste|--bot --shrine=HASTE --choice=1 --bot-time=70"
  "shrine_milk|--bot --shrine=MILK --choice=1 --bot-time=60"
  "quest_moonbeam|--bot --stage=SUPERMARKET --levels=15 --god --quest=MOONBEAM --bot-time=90"
  "quest_pack|--bot --levels=15 --quest=PACK_LEADERS --bot-time=90"
  "quest_dig|--bot --stage=GARDEN --levels=15 --god --quest=BURIED_TREASURE --bot-time=90"
  "quest_race|--bot --levels=15 --god --quest=CAT_RACE --bot-time=90"
  "shrine_might|--bot --shrine=MIGHT --choice=2 --bot-time=70"
  "banish_grade|--bot --banish --grade=2 --bot-time=60"
  "darkness|--bot --darkness=3 --bot-time=90"
  "charm_quality|--bot --drop-charm --extract --charm-quality=3 --bot-time=60"
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
  "evolution_can|--test-evolution --start-weapon=TIN_CAN_TOSS"
  "evolution_wave|--test-evolution --start-weapon=WAVE"
  "evolution_drone|--test-evolution --start-weapon=DRONE_BUDDY"
  "new_weapons_2|--bot --god --start-minute=5 --catch-up --start-weapon=TIN_CAN_TOSS,WAVE,DRONE_BUDDY --branch=TIN_CAN_TOSS:HOT_CAN:2,WAVE:UNDERTOW:2,DRONE_BUDDY:MORE_DRONES:2 --bot-time=200"
  "evolved_new|--bot --god --start-minute=5 --catch-up --start-weapon=CLUSTER_CAN,TSUNAMI,DRONE_SWARM --bot-time=120"
  "branches_fx|--bot --start-weapon=SCRATCH,LASER,MILK,HAIRBALL,BELL,ANTENNA --branch=SCRATCH:FLAME_CLAWS:2,LASER:OVERLOAD:2,MILK:ICY_MILK:2,HAIRBALL:EXPLOSIVE:2,BELL:THUNDER_RING:1,ANTENNA:SHORT_CIRCUIT:2 --levels=10 --bot-time=120"
  "branches_misc|--bot --start-minute=6 --catch-up --start-weapon=FISHBONES,SCRATCH,YARN,COBWEB,SPRINKLER,MOUSE_TOY --branch=FISHBONES:SHARP_BONES:2,SCRATCH:BLOODTHIRST:2,YARN:RICOCHET:2,COBWEB:VENOM:1,SPRINKLER:BOILING:2,MOUSE_TOY:FIRECRACKER:2 --bot-time=500"
  "new_weapons|--bot --start-minute=8 --catch-up --start-weapon=ANTENNA --all-weapons --bot-time=600"
  "quest_clover|--bot --stage=GARDEN --levels=20 --quest=CLOVER --bot-time=150"
  "angel_devil|--bot --stage=ROOFTOP --start-minute=16 --catch-up --angel-chance=1 --death-chance=1 --kill-cat-every=8 --bot-time=90"
  "devil_kills|--bot --stage=ROOFTOP --start-minute=16 --catch-up --angel-chance=1 --devil --bot-time=60"
  "devil_mortal|--bot --stage=ROOFTOP --start-minute=29.9 --catch-up --devil --bot-time=30"
  "companion_grows|--bot --god --levels=30 --quest=SNOWBALL --bot-time=200"
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
  "daily|--bot --daily --challenges= --start-minute=19.9 --catch-up --god --levels=40 --bot-time=250"
  "tutorial|--bot --tutorial --bot-time=120"
  "diary_page|--bot --page --extract --levels=20 --bot-time=150"
  # Whole nights on every map: quests and stories come on their own.
  "night_living_room|--bot --stage=LIVING_ROOM --god --bot-time=1300"
  "night_basement|--bot --stage=BASEMENT --god --bot-time=1300"
  "night_garden|--bot --stage=GARDEN --god --bot-time=1300"
  "night_rooftop|--bot --stage=ROOFTOP --god --bot-time=1300"
  "night_supermarket|--bot --stage=SUPERMARKET --god --bot-time=1300"
  "night_harbor|--bot --stage=HARBOR --god --bot-time=1300"
  "night_factory|--bot --stage=FACTORY --god --bot-time=1300"
  "supermarket|--bot --stage=SUPERMARKET --cat=TIGER --bot-time=300"
  "factory|--bot --stage=FACTORY --cat=TIGER --bot-time=300"
  "late_factory|--bot --stage=FACTORY --start-minute=12 --catch-up --bot-time=240"
  "final_r3000|--bot --stage=FACTORY --god --start-minute=19.9 --catch-up --bot-time=90"
  "traps_factory|--bot --stage=FACTORY --traps --bot-time=60"
  "quest_bolt|--bot --stage=FACTORY --god --levels=20 --quest=BOLT --bot-time=150"
  "story_blueprint|--bot --stage=FACTORY --god --levels=20 --quest=BLUEPRINT --bot-time=120"
  "chain_conveyor|--bot --stage=FACTORY --god --levels=20 --quest=CONVEYOR_JAM --bot-time=240"
  "chain_shutdown|--bot --stage=FACTORY --god --start-minute=3 --catch-up --quest=SHUTDOWN --bot-time=150"
  "chain_drones|--bot --stage=FACTORY --god --levels=20 --quest=ROGUE_DRONES --bot-time=200"
  "secret_far|--bot --stage=GARDEN --cat=TIGER --god --levels=20 --teleport=7200,0 --bot-time=150"
  "secret_dark|--bot --stage=BASEMENT --cat=TIGER --god --levels=20 --teleport=0,9100 --bot-time=150"
  "secret_trail|--bot --stage=HARBOR --cat=TIGER --god --levels=20 --teleport=trail --bot-time=200"
  "secret_sofa|--bot --cat=TIGER --god --levels=20 --teleport=0,6700 --bot-time=150"
  "secret_rooftop|--bot --stage=ROOFTOP --cat=TIGER --god --levels=20 --teleport=trail --bot-time=200"
  "secret_store|--bot --stage=SUPERMARKET --cat=TIGER --god --levels=20 --teleport=8200,0 --bot-time=150"
  "secret_factory|--bot --stage=FACTORY --cat=TIGER --god --levels=20 --teleport=trail --bot-time=200"
  "chain_trail|--bot --cat=TIGER --levels=20 --quest=KIBBLE_THIEF --bot-time=120"
  "chain_chase|--bot --cat=TIGER --levels=20 --chain-step=KIBBLE_THIEF:1 --quest=KIBBLE_THIEF --bot-time=120"
  "chain_carry|--bot --cat=TIGER --levels=20 --chain-step=KIBBLE_THIEF:2 --quest=KIBBLE_THIEF --bot-time=120"
  "chain_defend|--bot --cat=TIGER --levels=20 --chain-step=KIBBLE_THIEF:3 --quest=KIBBLE_THIEF --bot-time=120"
  "chain_collect|--bot --cat=TIGER --levels=20 --quest=SOCK_KING --bot-time=200"
  "chain_boss|--bot --cat=TIGER --levels=20 --chain-step=SOCK_KING:1 --quest=SOCK_KING --bot-time=120"
  "chain_zones|--bot --cat=TIGER --levels=20 --quest=MOON_WINDOWS --bot-time=150"
  "chain_rats|--bot --stage=BASEMENT --cat=TIGER --levels=20 --quest=RAT_FORTRESS --bot-time=240"
  "chain_tunnel|--bot --stage=BASEMENT --cat=TIGER --levels=20 --chain-step=RAT_FORTRESS:2 --quest=RAT_FORTRESS --bot-time=200"
  "chain_fight|--bot --stage=BASEMENT --cat=TIGER --levels=20 --chain-step=SPIDER_WEB:1 --quest=SPIDER_WEB --bot-time=150"
  "chain_gift|--bot --stage=BASEMENT --cat=TIGER --levels=20 --chain-step=SPIDER_WEB:1 --choice=1 --quest=SPIDER_WEB --bot-time=60"
  "chain_boiler|--bot --stage=BASEMENT --cat=TIGER --god --levels=20 --quest=BOILER --bot-time=240"
  "chain_queen|--bot --stage=BASEMENT --cat=TIGER --levels=20 --chain-step=SPIDER_WEB:2 --quest=SPIDER_WEB --bot-time=150"
  "chain_gnomes|--bot --stage=GARDEN --cat=TIGER --levels=20 --quest=GNOME_WAR --bot-time=240"
  "chain_moles|--bot --stage=GARDEN --cat=TIGER --levels=20 --chain-step=GNOME_WAR:2 --quest=GNOME_WAR --bot-time=180"
  "chain_gnome_side|--bot --stage=GARDEN --cat=TIGER --levels=20 --chain-step=GNOME_WAR:2 --choice=1 --quest=GNOME_WAR --bot-time=180"
  "chain_honey|--bot --stage=GARDEN --cat=TIGER --god --levels=20 --quest=HONEY --bot-time=240"
  "chain_scarecrow|--bot --stage=GARDEN --cat=TIGER --levels=20 --quest=SCARECROW --bot-time=240"
  "scarecrow_hits|--bot --stage=GARDEN --cat=TIGER --chain-step=SCARECROW:1 --start-minute=5 --catch-up --bot-time=60"
  "chain_chimneys|--bot --stage=ROOFTOP --cat=TIGER --god --levels=20 --quest=BRUNO_TRIAL --bot-time=120"
  "chain_emperor|--bot --god --stage=ROOFTOP --cat=TIGER --start-minute=8 --catch-up --chain-step=BRUNO_TRIAL:1 --quest=BRUNO_TRIAL --bot-time=200"
  "chain_bruno|--bot --god --stage=ROOFTOP --cat=TIGER --start-minute=19.9 --catch-up --chain-step=BRUNO_TRIAL:2 --quest=BRUNO_TRIAL --bot-time=150"
  "bruno_ally|--bot --chain-step=BRUNO_TRIAL:3 --bot-time=30"
  "chain_antenna|--bot --stage=ROOFTOP --cat=TIGER --levels=20 --quest=STORM_ANTENNA --bot-time=150"
  "antenna_zaps|--bot --stage=ROOFTOP --cat=TIGER --chain-step=STORM_ANTENNA:1 --start-minute=5 --catch-up --bot-time=60"
  "chain_collar|--bot --stage=ROOFTOP --cat=TIGER --levels=20 --quest=STOLEN_COLLAR --bot-time=200"
  "chain_shopping|--bot --stage=SUPERMARKET --cat=TIGER --god --levels=20 --quest=SHOPPING_LIST --bot-time=200"
  "chain_blackout|--bot --stage=SUPERMARKET --cat=TIGER --god --start-minute=4 --catch-up --quest=BLACKOUT --bot-time=120"
  "chain_rex|--bot --stage=SUPERMARKET --cat=TIGER --god --levels=20 --quest=REX_RESPECT --bot-time=200"
  "rex_gives_up|--bot --god --stage=SUPERMARKET --chain-step=REX_RESPECT:3 --start-minute=19.9 --catch-up --bot-time=90"
  "chain_ship|--bot --stage=HARBOR --cat=TIGER --god --levels=20 --quest=CAPTAINS_SHIP --bot-time=240"
  "chain_lighthouse|--bot --stage=HARBOR --cat=TIGER --god --levels=20 --quest=LIGHTHOUSE --bot-time=200"
  "lighthouse_burns|--bot --stage=HARBOR --chain-step=LIGHTHOUSE:1 --bot-time=60"
  "chain_dig|--bot --stage=HARBOR --cat=TIGER --god --chain-step=PIRATE_TREASURE:1 --start-minute=5 --catch-up --quest=PIRATE_TREASURE --bot-time=200"
  "chain_pirates|--bot --stage=HARBOR --cat=TIGER --god --start-minute=5 --catch-up --quest=PIRATE_TREASURE --bot-time=300"
  "chain_home|--bot --cat=TIGER --god --levels=20 --quest=WAY_HOME --bot-time=120"
  "chain_family|--bot --stage=HARBOR --cat=TIGER --god --levels=20 --chain-step=CAT_FAMILY:3 --quest=CAT_FAMILY --bot-time=150"
  "chain_final|--bot --chain-step=WHO_IS_BEHIND:0 --start-minute=19.9 --catch-up --god --bot-time=90"
  "chain_robo|--bot --god --chain-step=WHO_IS_BEHIND:6 --start-minute=10 --catch-up --quest=WHO_IS_BEHIND --bot-time=200"
  "chain_courier|--bot --cat=TIGER --god --levels=20 --quest=NIGHT_COURIER --bot-time=120"
  "chain_kittens|--bot --cat=TIGER --god --levels=20 --quest=LOST_KITTENS --bot-time=200"
  "chain_traps|--bot --cat=TIGER --god --levels=5 --quest=TRAPPER --bot-time=200"
  "chain_fire|--bot --cat=TIGER --god --levels=20 --quest=FIRE --bot-time=150"
  "chain_goldrush|--bot --cat=TIGER --god --levels=20 --quest=GOLD_RUSH --bot-time=200"
  "chain_bowls|--bot --cat=TIGER --god --levels=20 --quest=THREE_BOWLS --bot-time=120"
  "chain_lantern|--bot --cat=TIGER --god --levels=20 --quest=LANTERN --bot-time=150"
  "chain_duel|--bot --cat=TIGER --god --start-minute=5 --catch-up --quest=TIMED_DUEL --bot-time=120"
  "chain_merchant|--bot --cat=TIGER --god --levels=20 --choice=1 --quest=MERCHANT --bot-time=150"
  "chain_walk|--bot --stage=ROOFTOP --cat=TIGER --god --levels=20 --quest=LAST_WALK --bot-time=200"
  "boiler_heals|--bot --stage=BASEMENT --cat=TIGER --chain-step=BOILER:1 --bot-time=40"
  "artifacts_time|--bot --artifacts=HOURGLASS,MAGNET_CORE --start-minute=5 --catch-up --bot-time=150"
  "artifacts_hurt|--bot --artifacts=THORN_COLLAR,ANGEL_FEATHER --start-minute=6 --catch-up --bot-time=150"
  "artifacts_boss|--bot --artifacts=BOSS_TOOTH,CATNIP_POUCH --start-minute=2.9 --catch-up --bot-time=150"
  "artifacts_stats|--bot --artifacts=GLASS_EYE,LUCKY_COIN,BLOOD_MOON,CLOCKWORK --bot-time=120"
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
  if [ -n "$QUICK" ]; then
    # Quick round: no scenario runs longer than 90 s of game time.
    args=$(echo "$args" | sed -E 's/--bot-time=([0-9]+)/--bot-time=\1@/; s/--bot-time=([0-9]{3,}|9[1-9])@/--bot-time=90/; s/@//')
  fi
  # Whole nights (night_*) need longer than the rest.
  local limit=280
  [[ "$name" == night_* ]] && limit=600
  out=$(timeout "$limit" "$GODOT" --headless --log-file "${TMPDIR:-/tmp}/catsurvivors_$name.log" --path . $engine -- $args 2>&1)
  errors=$(echo "$out" | grep -E "SCRIPT ERROR|Parse Error|ERROR: |UI: FAIL|TEXT: FAIL" | grep -vE "resources still in use|ObjectDB instances leaked" | sort | uniq -c | head -5)
  summary=$(echo "$out" | grep -E "^(BOT|TEST): (time|weapons after|quests_done|active quest)|^(UI|TEXT): done" | tr '\n' ' ' | cut -c1-200)
  if [ -n "$errors" ]; then
    printf 'FAIL %s: %s\n%s\n' "$name" "$summary" "$(echo "$errors" | sed 's/^/     /')"
  else
    printf 'ok   %s: %s\n' "$name" "$summary"
  fi
}
export -f run_one
export GODOT QUICK

if [ -n "$QUICK" ] && [ -z "$ONLY" ]; then
  ONLY="menus|apartment|basement|garden|rooftop|supermarket|harbor|factory|final_vacuum|final_kraken|final_r3000|all_weapons|new_weapons_2|evolution_mica|evolution_drone|branches_fx|quest_luna|quest_baron|story_note|chain_trail|chain_carry|chain_zones|chain_gift|chain_kittens|chain_fire|artifacts_hurt|challenges|traps|endless|champions"
fi
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
