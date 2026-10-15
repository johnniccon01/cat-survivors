# Cat Survivors

Survivors-like hra v Godot 4.6: mačka Mica bráni byt pred hordami ponožiek.

## Spustenie

Otvor `project.godot` v Godot 4.6 a stlač **F5**.

Ovládanie: **WASD / šípky / ľavá páčka**, **Esc** pauza, **L** (v pauze) zmena jazyka, **R / Enter** reštart po smrti.

Automatický test (bot hrá sám 4× rýchlejšie a vypíše výsledok):

```
Godot_v4.6.2-stable_win64_console.exe --headless --path . -- --bot
```

Ďalšie testovacie prepínače (za `--`):

- `--bot-time=SEKUNDY` – ako dlho hrá bot (predvolene 300)
- `--start-minute=N` – začne hru v N-tej minúte (napr. kvôli bossom)
- `--all-weapons` – začne so všetkými základnými zbraňami
- `--show-levelup` – bot nechá level-up okno otvorené
- `--test-evolution` – overí evolúciu Škrabanca a skončí

## Štruktúra

- `data/` – obsah hry v JSON-e (zbrane, pasívky, nepriatelia, vlny podľa minút). Balans sa ladí tu, bez zásahu do kódu.
- `scripts/progression/upgrades.gd` – výber ponúk pri level-upe a ich aplikovanie.
- `scripts/pickups/` – XP granule, srdiečka a sardinky (liečenie), magnet.
- `data/props.json` – rozbitné predmety (krabice, kvetináče) a čo z nich padá.
- Evolúcie: v `data/weapons.json` má základná zbraň `"evolve": {"with": PASÍVKA, "into": EVOLÚCIA}`. Zbraň na max leveli + vlastnená pasívka + truhlica z bossa = evolúcia.
- Bossovia sú v `data/enemies.json` (`"boss": true`), do vĺn sa pridávajú cez `"bosses"` v `data/stages.json`.
- `scripts/world/floor.gd` + `floor_chunk.gd` – mapa po kúskoch 320×320: miestnosti (obývačka, kuchyňa, spálňa), nábytok, lampy; každá hra má inú mapu.
- `scripts/world/night.gd` – stmievanie počas hry a ranný úsvit.
- `scripts/enemies/enemy_manager.gd` – pohyb, kolízie a vyhľadávanie všetkých nepriateľov cez priestorovú mriežku.
- `scripts/weapons/weapon.gd` – základ zbraní (cooldown, dávky, levely zo `weapons.json`); konkrétne zbrane ho rozširujú.
- `scripts/spawner.gd` – spawnovanie mimo obrazovky podľa `stages.json`.
- `scripts/player/`, `scripts/fx/`, `scripts/ui/`, `scripts/world/` – mačka, efekty, HUD, podlaha.


## Preklady

Všetky texty sú v `locale/translations.csv` (stĺpec = jazyk). Nový jazyk:
pridaj stĺpec (napr. `de`), doplň kód do `LANGUAGES` v `scripts/autoload/settings.gd`
a cestu `res://locale/translations.de.translation` do `project.godot`
(sekcia `[internationalization]`). Po otvorení v editore sa súbory vygenerujú.

Grafika je zatiaľ kreslená kódom (placeholder).
