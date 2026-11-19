# Store media: screenshots, capsules, trailer

## Goal
Release-ready media for the store page (Steam sizes, usable for itch.io too):
- 8–10 screenshots 1920×1080 (no debug UI, readable HUD, each shows one selling point).
- Capsules: header 920×430, small 462×174, main 1232×706, vertical 748×896, library 600×900, library hero 3840×1240, logo PNG with alpha.
- Trailer 45–60 s, 1080p60 MP4 (H.264), game music, short EN text cards; plus 15 s vertical cut (9:16) for social.

## Approach
- Footage straight from the game: fixed 60 fps, every frame saved by the game (`--capture-frames`) + existing bot flags (`--bot --god --strong --stage= --cat= --seed=`, `--dev-boss=`).
- Render at 3840×2160 (3× of 1280×720 = clean pixel art), downscale to 1080p.
- New flags only for capture (no effect on normal play, never save profile): `--capture` (no dev labels), `--no-hud`, `--cam-zoom=F`, `--crowd=F`, `--no-numbers`, `--bot-speed=1` for natural pace.
- `tools/media/shots.txt`: list of shots (args + length); `tools/media/capture.sh` records them all.
- Editing via ffmpeg script `tools/media/trailer.sh` (cuts, fades, text cards rendered in-game in cardboard style, music mix). Reproducible: rerun after balance/art changes.
- Capsules: Python (PIL) composition from in-game sprites (upscaled nearest), logo; final hand touch-up optional in Krita.

## Trailer storyboard (draft)
1. 0–3 s hook: Mica in a huge sock horde, screen full of attacks (no logo first).
2. 3–12 s: core loop: walk, auto attacks, level-up pick, gems flying.
3. 12–22 s: weapon evolutions, combos, big screen-clearing moments.
4. 22–32 s: variety: 4 districts, weather/night, traps, 25 cats quick cuts.
5. 32–42 s: bosses (mower, kraken, R3000), boss arena.
6. 42–50 s: meta: district map, gear, quests/stories, Cat Dreams endgame.
7. 50–58 s: climax shot + logo + "Wishlist now" + platform.

## Steps
- [x] Install ffmpeg (winget Gyan.FFmpeg).
- [x] Capture flags + tools/media/shots.txt + capture.sh.
- [x] Record shots, contact sheets of frames for review.
- [x] Pick screenshots (make_screenshots.py).
- [x] Capsules + logo (logo_shot.gd, make_capsules.py).
- [x] Trailer edit + vertical cut (trailer.txt, trailer.sh, make_cards.py).
- [ ] Player review, fixes. Media stay out of the repo (store_media/, regenerable).

## How to rebuild (Git Bash, G = Godot console exe, ffmpeg + Pillow installed)
1. `bash tools/media/capture.sh "$G" store_media/raw` (all shots, ~75 min; regex as 3rd arg for some).
2. `"$G" --path . -s res://tools/media/logo_shot.gd -- --out=$(pwd -W)/store_media/logo.png --lang=en` (and `--no-tagline` -> logo_plain.png).
   `store_media/extra/` by hand: `select_map.png` = frame 140 of `"$G" --path . --fixed-fps 60 --quit-after 150 res://scenes/character_select.tscn -- --no-save --open-all --lang=en --capture --capture-size=3840x2160 --capture-frames=<dir>`; `levelup.png` = a late still of `levelup_rooftop`.
3. `python tools/media/make_cards.py store_media/cards`
4. `python tools/media/make_screenshots.py store_media`
5. `python tools/media/make_capsules.py store_media/raw/stills/key_art_4.png store_media/logo.png store_media/logo_plain.png store_media/capsules 0.51 0.48`
6. `bash tools/media/trailer.sh store_media` (v1). v2 with content numbers: `bash tools/media/trailer.sh store_media assets/audio/music_boss.wav tools/media/trailer_v2.txt trailer_v2`; needs `extra/questbook.png` and `extra/journal.png` (main menu with `--questbook` / `--journal`, same capture flags as select_map) and `extra/districts.png` (2x2 grid of `extra/district_*.png` from `"$G" --path . --fixed-fps 60 res://tools/media/district_shot.tscn -- --no-save --open-all --lang=en --capture --capture-size=3840x2160 --out=<extra dir>`).
   Numbers on the v2 cards come from data/*.json, rounded down (chains 173 -> 150+, 29 chains with 3+ steps, longest 8, bosses 158, enemies 251, legendaries 48, charms 30, artifacts 29, 47 maps x 20 min); update make_cards.py STATS when content changes.

Notes: Godot's own `--write-movie` shrinks to 2/3 of the screen (1280x720 on a
1080p monitor), so the game saves frames itself (`--capture-frames`,
`--capture-size`). Capture flags: `--capture`, `--no-hud`, `--cam-zoom=F`,
`--crowd=F`, `--no-numbers`; menus stay menus with `--capture*` / `--lang=`.

## Risks
- Bot plays "ugly" (corners, random walking) → scripted camera path / bot hints for capture.
- Big hordes at 4K could be slow → Movie Maker is offline, only takes longer.
- Claude cannot watch motion → checks via frame sheets; final judgement by the player.

## Verify
Screenshots and trailer frames checked as contact sheets; trailer watched by the player.
