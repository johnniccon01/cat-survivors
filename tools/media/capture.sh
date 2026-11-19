#!/usr/bin/env bash
# Records the store-media shots from tools/media/shots.txt: fixed 60 fps and
# every frame saved by the game itself at 4K (--capture-frames; Godot's own
# movie writer shrinks to 2/3 of the screen). The bot plays and never saves
# the profile. English texts (--lang=en).
#
#   bash tools/media/capture.sh GODOT OUT_DIR [ONLY_REGEX] [JOBS]
#
# Per shot: OUT_DIR/<name>.mp4 (1080p60, downscaled from a 4K render, first
# second cut) and OUT_DIR/stills/<name>_N.png
# (4K frames every 0.5 s, screenshot candidates).
set -u
GODOT="$1"; OUT="$2"; ONLY="${3:-.}"; JOBS="${4:-2}"
RES="${RES:-3840x2160}"
FFMPEG="${FFMPEG:-ffmpeg}"
cd "$(dirname "$0")/../.."
mkdir -p "$OUT/stills"

shot() {
  local name="$1" secs="$2" flags="$3" hud="--no-hud"
  if [[ " $flags " == *" --hud "* ]]; then hud=""; flags="${flags/--hud/}"; fi
  local tmp="$OUT/_$name"
  rm -rf "$tmp"; mkdir -p "$tmp"
  local bot_time=$((secs + 2))
  local dir; dir="$(cygpath -m "$(realpath "$tmp")" 2>/dev/null || realpath "$tmp")"
  timeout $((secs * 60 + 300)) "$GODOT" --path . --fixed-fps 60 -- --bot --capture $hud \
    --capture-size=$RES --capture-frames="$dir" --lang=en --bot-speed=1 \
    --seed=7 --bot-time=$bot_time $flags > "$OUT/$name.log" 2>&1
  "$FFMPEG" -loglevel error -y -framerate 60 -start_number 60 -i "$tmp/f%08d.png" \
    -vf "scale=1920:1080:flags=lanczos,format=yuv420p" -frames:v $((secs * 60)) \
    -c:v libx264 -preset slow -crf 14 "$OUT/$name.mp4"
  local n=0
  for f in $(ls "$tmp"/f*.png | awk 'NR>60 && NR%30==0'); do
    n=$((n + 1)); mv "$f" "$OUT/stills/${name}_$n.png"
  done
  rm -rf "$tmp"
  echo "done $name ($n stills)"
}

running=0
while IFS='|' read -r name secs flags; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  [[ "$name" =~ $ONLY ]] || continue
  shot "$name" "$secs" "$flags" &
  running=$((running + 1))
  if (( running >= JOBS )); then wait -n; running=$((running - 1)); fi
done < tools/media/shots.txt
wait
