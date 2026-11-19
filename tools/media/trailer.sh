#!/usr/bin/env bash
# Cuts the trailer from the captured shots (capture.sh), the text cards
# (make_cards.py), the title board (logo_shot.gd) and the game's own music.
#
#   bash tools/media/trailer.sh MEDIA_DIR [MUSIC_WAV] [EDIT_LIST] [NAME] [VERTICAL_START]
#
# MEDIA_DIR holds raw/<clip>.mp4, cards/<card>.png and logo.png; a clip
# without a video but with extra/<clip>.png (menu screens) becomes a slow
# push-in on that picture.
# Output: MEDIA_DIR/NAME.mp4 (1080p60, NAME defaults to "trailer") and
# MEDIA_DIR/NAME_vertical.mp4 (1080x1920, 15 s from VERTICAL_START s).
set -eu
M="$1"
MUSIC="${2:-assets/audio/music_boss.wav}"
LIST="${3:-tools/media/trailer.txt}"
NAME="${4:-trailer}"
VSTART="${5:-0}"
FFMPEG="${FFMPEG:-ffmpeg}"
cd "$(dirname "$0")/../.."
T="$M/_trailer"; rm -rf "$T"; mkdir -p "$T"
FPS=60
calc() { awk "BEGIN { print $1 }"; }
ENC=(-c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p -r $FPS)

# End card: the title board over a dark warm background.
"$FFMPEG" -loglevel error -y -f lavfi -i "color=c=0x1c120c:s=1920x1080:r=$FPS" \
  -i "$M/logo.png" -filter_complex \
  "[1]scale=1500:-1[l];[0][l]overlay=(W-w)/2:(H-h)/2-90" -t 6 "${ENC[@]}" "$T/logo.mp4"

i=0; total=0
: > "$T/list.txt"
while IFS='|' read -r clip start len card; do
  [[ -z "$clip" || "$clip" == \#* ]] && continue
  i=$((i + 1)); seg="$T/$(printf %02d $i).mp4"
  src="$M/raw/$clip.mp4"; [[ "$clip" == logo ]] && src="$T/logo.mp4"
  if [[ ! -f "$src" && -f "$M/extra/$clip.png" ]]; then
    src="$T/still_$i.mp4"; frames=$(calc "int(($start + $len) * $FPS) + 1")
    "$FFMPEG" -loglevel error -y -loop 1 -framerate $FPS -i "$M/extra/$clip.png"       -vf "zoompan=z='1+0.04*on/$frames':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=1920x1080:fps=$FPS"       -frames:v $frames "${ENC[@]}" "$src"
  fi
  if [[ "$card" != "-" ]]; then
    fade_out=$(calc "$len - 0.3")
    "$FFMPEG" -loglevel error -y -ss "$start" -t "$len" -i "$src" -loop 1 -t "$len" -i "$M/cards/$card.png" \
      -filter_complex "[1]format=rgba,fade=in:st=0.1:d=0.25:alpha=1,fade=out:st=$fade_out:d=0.3:alpha=1[c];[0][c]overlay" \
      -t "$len" "${ENC[@]}" -an "$seg"
  else
    "$FFMPEG" -loglevel error -y -ss "$start" -t "$len" -i "$src" -t "$len" "${ENC[@]}" -an "$seg"
  fi
  echo "file '$(basename "$seg")'" >> "$T/list.txt"
  total=$(calc "$total + $len")
done < "$LIST"

fade_at=$(calc "$total - 1.5")
"$FFMPEG" -loglevel error -y -f concat -safe 0 -i "$T/list.txt" -stream_loop -1 -i "$MUSIC" \
  -filter_complex "[0:v]fade=in:st=0:d=0.3,fade=out:st=$(calc "$total - 0.6"):d=0.6[v];[1:a]atrim=0:$total,afade=out:st=$fade_at:d=1.5,loudnorm=I=-14:TP=-1.5[a]" \
  -map "[v]" -map "[a]" "${ENC[@]}" -c:a aac -b:a 192k -movflags +faststart "$M/$NAME.mp4"

# Vertical cut: the first 15 s as a 4:3 centre crop (big enough on a phone,
# the text cards still fit), blurred fill around it, the title board on top.
"$FFMPEG" -loglevel error -y -ss "$VSTART" -t 15 -i "$M/$NAME.mp4" -i "$M/logo.png" -filter_complex \
  "[0:v]split[a][b];[a]scale=-2:1920,crop=1080:1920,boxblur=30:2,eq=brightness=-0.2[bg];[b]crop=1440:1080,scale=1080:810:flags=lanczos[fg];[1]scale=940:-1[l];[bg][fg]overlay=0:560[m];[m][l]overlay=(W-w)/2:90,fade=out:st=14.4:d=0.6[v];[0:a]afade=out:st=13.5:d=1.5[a]" \
  -map "[v]" -map "[a]" "${ENC[@]}" -c:a aac -b:a 192k -movflags +faststart "$M/${NAME}_vertical.mp4"
rm -rf "$T"
echo "$NAME: ${total}s -> $M/$NAME.mp4, $M/${NAME}_vertical.mp4"
