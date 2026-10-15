# Cat Survivors

Survivors-like hra v Godot 4.6: mačka Mica bráni byt pred hordami ponožiek.

## Spustenie

Otvor `project.godot` v Godot 4.6 a stlač **F5**. Hra začína hlavným menu (Hrať, Vylepšenia, Prívesky, Ciele, Nastavenia, Koniec).

Ovládanie: **WASD / šípky / ľavá páčka**, **Esc** pauza, v pauze **L** jazyk a **M** zvuk, **R / Enter** reštart po smrti.

V pauze: **N** čísla poškodenia, **K** otrasy obrazovky.

**Vývojársky panel (F1)** – len vo vývojovej verzii (vo vydanej hre sa nezobrazí): posun o minútu, nesmrteľnosť, +5 levelov, finálny boss hneď, quest hneď. Pred vydaním ho zmažeme (`scripts/ui/dev_panel.gd`).

Celá sada testov (24 scenárov, hlási chyby v skriptoch):

```
bash tools/run_checks.sh
```

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
- `--quest=ID` – hneď spustí quest (LUNA, SNOWBALL, PIP, TIGER, BARON, DEFEND_BOWL, RED_DOT, FRIDGE)
- `--cat=ID` – hrá za danú mačku bez odomknutia
- `--stage=ID` – hrá danú mapu bez odomknutia (LIVING_ROOM, BASEMENT)
- `--levels=N` – začne s N náhodnými vylepšeniami (test neskorej hry)
- `--test-numbers` – zobrazí ukážku čísel poškodenia; `--pause` – hneď otvorí pauzové menu
- Hlavné menu: `--shop`, `--charms`, `--goals`, `--settings` otvoria daný panel
- `--extract` – hneď otvorí mačacie dvierka; `--drop-charm` – hneď hodí prívesok; `--traps` – položí všetky pasce vedľa mačky

Testovacie behy (`--bot`) nikdy neukladajú profil.

## Štruktúra

- `data/` – obsah hry v JSON-e (zbrane, pasívky, nepriatelia, vlny podľa minút). Balans sa ladí tu, bez zásahu do kódu.
- `scripts/progression/upgrades.gd` – výber ponúk pri level-upe a ich aplikovanie.
- `scripts/pickups/` – XP granule, srdiečka a sardinky (liečenie), magnet.
- `data/cats.json` – mačky (vzhľad, štartová zbraň, bonus). Odomknuté mačky sa ukladajú do `user://profile.cfg`.
- `data/stages.json` – mapy (byt, pivnica): vlny, bossovia, finálny boss, ktoré mačky a príbehový quest tam patria. Pivnica sa odomkne porazením Kráľa vysávačov.
- `data/quests.json` + `scripts/quests/` – questy: záchrany a súboje mačiek, vedľajšie úlohy, poradie počas noci.
- `scripts/ui/character_select.gd` – výber mačky pred hrou.
- `data/powerups.json` – trvalé vylepšenia z obchodu (U vo výbere mačky). Zlato a kúpené stupne sú v profile.
- Výzva: HP nepriateľov rastie s levelom mačky a s Kliatbou; elitní nepriatelia od 4. minúty; udalosti `events` (kruh, roj) v `data/stages.json`.
- Koniec hry: smrť (polovica zlata, prívesky prepadnú, séria padá), útek mačacími dvierkami (`scripts/world/extraction.gd`, otvárajú sa po bossovi alebo queste) alebo víťazstvo. Séria dáva bonus k zlatu.
- `data/charms.json` – prívesky na obojok (C vo výbere mačky, max 3 nasadené). Padajú z elít, bossov a questov; domov sa prinesú len útekom alebo víťazstvom.
- `data/traps.json` + `scripts/world/trap.gd` – pasce (pasca na myši, sporák, iskriaca mláka, parná rúrka) zraňujú nepriateľov aj mačku; ktoré pasce má mapa, je v `data/stages.json`.
- `data/goals.json` + `scripts/progression/goals.gd` – dlhodobé ciele (G vo výbere mačky) s odmenami; štatistiky sa ukladajú v profile.
- `data/props.json` – rozbitné predmety (krabice, kvetináče) a čo z nich padá.
- Evolúcie: v `data/weapons.json` má základná zbraň `"evolve": {"with": PASÍVKA, "into": EVOLÚCIA}`. Zbraň na max leveli + vlastnená pasívka + truhlica z bossa = evolúcia.
- Bossovia sú v `data/enemies.json` (`"boss": true`), do vĺn sa pridávajú cez `"bosses"` v `data/stages.json`.
- `scripts/world/floor.gd` + `floor_chunk.gd` – mapa po kúskoch 320×320: miestnosti (obývačka, kuchyňa, spálňa), nábytok, lampy; každá hra má inú mapu.
- `scripts/world/night.gd` – stmievanie počas hry a ranný úsvit.
- `scripts/enemies/enemy_manager.gd` – pohyb, kolízie a vyhľadávanie všetkých nepriateľov cez priestorovú mriežku.
- `scripts/weapons/weapon.gd` – základ zbraní (cooldown, dávky, levely zo `weapons.json`); konkrétne zbrane ho rozširujú.
- `scripts/spawner.gd` – spawnovanie mimo obrazovky podľa `stages.json`.
- `scripts/player/`, `scripts/fx/`, `scripts/ui/`, `scripts/world/` – mačka, efekty, HUD, podlaha.


## Zvuk

Všetky zvuky a hudba sú syntetizované skriptom `tools/gen_audio.py` (žiadne cudzie súbory ani licencie). Po úprave stačí spustiť `python tools/gen_audio.py` a súbory v `assets/audio/` sa prepíšu. Prehrávanie rieši autoload `scripts/autoload/audio.gd`.

## Preklady

Všetky texty sú v `locale/translations.csv` (stĺpec = jazyk). Nový jazyk:
pridaj stĺpec (napr. `de`), doplň kód do `LANGUAGES` v `scripts/autoload/settings.gd`
a cestu `res://locale/translations.de.translation` do `project.godot`
(sekcia `[internationalization]`). Po otvorení v editore sa súbory vygenerujú.

Grafika je zatiaľ kreslená kódom (placeholder).
