# Cat Survivors

Survivors-like hra v Godot 4.6: mačka Mica bráni byt pred hordami ponožiek.

## Spustenie

Otvor `project.godot` v Godot 4.6 a stlač **F5**.

Ovládanie: **WASD / šípky / ľavá páčka**, **Esc** pauza, **R / Enter** reštart po smrti.

Automatický test (bot hrá sám 4× rýchlejšie a vypíše výsledok):

```
Godot_v4.6.2-stable_win64_console.exe --headless --path . -- --bot
```

## Štruktúra

- `data/` – obsah hry v JSON-e (zbrane, nepriatelia, vlny podľa minút). Balans sa ladí tu, bez zásahu do kódu.
- `scripts/enemies/enemy_manager.gd` – pohyb, kolízie a vyhľadávanie všetkých nepriateľov cez priestorovú mriežku.
- `scripts/weapons/weapon.gd` – základ zbraní (cooldown, dávky, levely zo `weapons.json`); konkrétne zbrane ho rozširujú.
- `scripts/spawner.gd` – spawnovanie mimo obrazovky podľa `stages.json`.
- `scripts/player/`, `scripts/fx/`, `scripts/ui/`, `scripts/world/` – mačka, efekty, HUD, podlaha.

Grafika je zatiaľ kreslená kódom (placeholder).
