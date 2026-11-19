Pracuj podľa `.ai/STUDIO_PROCESS.md` a `.ai/AI_TEAM.md`.

# Cat Survivors

## O hre
- Žáner: survivors-like (štýl Vampire Survivors).
- Popis: mačka (napr. Mica) bojuje s vlnami nepriateľov (ponožky a pod.). Útočí automaticky, hráč uhýba a zbiera. 4 štvrte so 47 mapami, 25 mačiek, 30 zbraní a evolúcií, questy a príbehy, výbava (gear), endgame „Mačacie sny“. Hra má 6 jazykov (vývoj po slovensky).
- Komunikácia po slovensky, commit správy po anglicky (štýl ako v `git log`).

## Engine
- **Godot 4.6.2**, GDScript, renderer GL Compatibility, 1280×720. Hlavná scéna je `scenes/main_menu.tscn`.
- Godot konzolová binárka na tomto PC: `E:\Tools\Godot_v4.6.2-stable_win64\Godot_v4.6.2-stable_win64_console.exe`. Notebook: `C:\Users\AndrejNikolaj\Downloads\Godot_v4.6.2-stable_win64.exe\...`. Ak cesta neexistuje, nájdi ju ako `hrat.bat` (premenná `GODOT`, `godot\` vedľa hry, Downloads, Program Files).

## Štruktúra
- Autoloady (`scripts/autoload/`): `GameData` (dáta), `Settings`, `Profile` (uložená hra, verzie, migrácie, zálohy), `Audio`.
- `scripts/main.gd`: beh hry, debug prepínače (zoznam v hlavičke), koniec noci, súhrn.
- `scripts/spawner.gd`: vlny a rozpočet nepriateľov. `scripts/enemies/` (`enemy_manager.gd` = pohyb, priestorová mriežka).
- `scripts/player/` (hráč, inštinkty, druhy zvierat, partner), `scripts/weapons/` (základ `weapon.gd`, `combos.gd`), `scripts/pickups/`, `scripts/progression/` (upgrady, gear `items.gd`, ciele, achievementy).
- `scripts/quests/`: questy. Reťazové kroky sú v `quests/chain/<typ>_step.gd`, základ je `chain_step.gd`.
- `scripts/world/`: podlaha (chunky), terén, pasce, stavby, svätyne, noc, počasie, boss arény, únik.
- `scripts/ui/`: HUD, menu, panely v kartónovom štýle (`box_*.gd`), mapy štvrtí, F1 dev panel, dev launcher.
- `data/*.json`: balans a obsah (zbrane, nepriatelia, etapy, questy, predmety…). Balans patrí sem, nie do kódu.
- `locale/translations.csv` (`key,en,sk,cs,es,ru,zh_CN`): po úprave spusti import, aby sa obnovili `.translation`.
- `tools/`: testovacie skripty (`run_checks.sh`, `campaign.sh`…), generátory pixel artu (`gen_*.py`), nástroje na preklady.
- `tools/media/`: screenshoty, capsule obrázky a trailer do obchodu (postup v `docs/plans/2026-11-18-store-media.md`).
- Dokumenty: `PLAN.md` (živý plán a história), `ENDGAME.md`, `TRETIA_STVRT.md`, `PSIE_STVRTE.md`, `INVENTAR.md` (dizajnové návrhy), `README.md`.

## Hlavné systémy
Pozri `docs/ARCHITECTURE.md`.

## Nikdy nemeniť bez súhlasu
- Hviezdy, odomknutia a príbehy sa nikdy nesmú stratiť. Migrácia profilu musí zachovať staré uložené hry (`profile.vN.cfg`).
- Testovacie behy (`--bot`, `--ui-test`, `--no-save`) nikdy neukladajú profil hráča. Priečinok `%APPDATA%\Cat Survivors` nemaž.
- Výbava (gear) sa na mačkách nekreslí, ak to hráč výslovne nepovie.
- `project.godot` (autoloady, input), `.import` súbory, export presety.
- Pracuje sa na dvoch PC cez GitHub (`origin/main`). Pred prácou daj `git pull`.

## Ako testovať
- `$G` je cesta ku Godot konzolovej binárke (vyššie). Bash skripty spúšťaj cez Git Bash.
- Import po zmene súborov: `"$G" --headless --path . --import`
- Jeden scenár: `ONLY="nazov|nazov2" bash tools/run_checks.sh "$G"` (názvy sú v `tools/run_checks.sh`)
- Rýchla sada (~1 min): `QUICK=1 bash tools/run_checks.sh "$G"`. Celá sada (~9 min) iba na požiadanie.
- Texty (všetky jazyky): `"$G" --headless --path . -s res://tools/strings_check.gd`
- Celá kampaň (~35 min, iba na požiadanie): `bash tools/campaign.sh "$G"`. Zbrane: `bash tools/weapons_test.sh "$G"`.
- Ručne: `hrat.bat` alebo Godot editor → F5. Bot prepínače: `--bot --god --stage= --cat= --expect=<udalosť>`.
