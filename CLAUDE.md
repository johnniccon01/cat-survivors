# Cat Survivors – pokyny pre Claude

Survivors-like hra v Godot 4.6 (GDScript, renderer Compatibility). Hráč píše po slovensky, odpovedaj po slovensky, stručne.

## Šetri kontext (dôležité)
- Rob **len to, o čo hráč požiada**. Nečítaj celý projekt, nerob prieskum „pre istotu".
- Najprv `git status` + `git log --oneline -5`, potom choď cielene: Grep na konkrétny kľúč/funkciu, Read len potrebných riadkov (offset/limit).
- Neotváraj veľké súbory celé (`scripts/main.gd` ~1100 riadkov, `data/*.json`, `locale/translations.csv`, `scripts/quests/chain_step.gd`). Hľadaj v nich cez Grep.
- Žiadne profilovanie, meranie FPS ani celú sadu testov, ak o to hráč nežiada. Stačí rýchly cielený test (nižšie).
- Nepíš dlhé vysvetľovania; po práci krátko: čo sa zmenilo a čo nie je overené.

## Mapa projektu
- `scripts/main.gd` – beh hry, debug prepínače (zoznam v hlavičke súboru), koniec hry, súhrn.
- `scripts/spawner.gd` – vlny, rozpočet nepriateľov. `scripts/enemies/` – nepriatelia (`enemy_manager.gd` = pohyb, mriežka, dotazy).
- `scripts/player/player.gd`, `scripts/weapons/` (základ `weapon.gd`), `scripts/pickups/`.
- `scripts/quests/` – questy; reťazové kroky v `quests/chain/<typ>_step.gd`, základ `chain_step.gd` (vzhľady `draw_look`). Dáta: `data/chains.json`, `data/quests.json`.
- `scripts/world/` – podlaha, pasce (`trap.gd`), stavby z questov (`map_feature.gd`), svätyne, noc.
- `scripts/ui/` – HUD (`hud.gd`), menu, panely, šípky (`boss_arrows.gd`, `quest_arrow.gd`).
- `scripts/autoload/` – `settings.gd`, `profile.gd` (uložená hra), `game_data.gd`, `audio.gd`.
- `data/*.json` – balans a obsah. `locale/translations.csv` – texty `key,en,sk,cs,es,ru,zh_CN` (po úprave CSV spusti import, aby sa obnovili `.translation`).
- `PLAN.md` – stav a plán, `README.md` – ovládanie a prepínače.

## Godot
Notebook (AndrejNikolaj): `G="/c/Users/AndrejNikolaj/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe"`
Druhé PC (john.niccon): `G="/c/Users/john.niccon/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe"`
Ak cesta neexistuje, nájdi ju rovnako ako `hrat.bat` (Downloads, priečinok `godot\` vedľa hry, Program Files).
- Import po zmene súborov: `"$G" --headless --path . --import`
- Rýchly test jedného scenára: `ONLY="nazov|nazov2" bash tools/run_checks.sh "$G"` (názvy scenárov v `tools/run_checks.sh`).
- Rýchla sada: `QUICK=1 bash tools/run_checks.sh "$G"`. Celá sada (~150 scenárov) len na požiadanie.
- Kontrola textov (všetky jazyky, zástupné znaky, písmo): `"$G" --headless --path . -s res://tools/strings_check.gd` (beží aj na konci `run_checks.sh`). Preklady: `tools/translations_tool.gd` (dump / merge / missing).
- Spustenie hry s logom: `--log-file C:\Users\AndrejNikolaj\cat-survivors-logs\play.log`.

## Git a dva počítače
- Hráč pracuje na dvoch PC cez GitHub (`origin`, vetva `main`). Pred prácou `git pull`, na konci commit + push, keď to hráč povie.
- Commit správy po anglicky, štýl ako v `git log`.
