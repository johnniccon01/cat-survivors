# Rozhodnutia
Formát: `## YYYY-MM-DD – názov`, potom Rozhodnutie / Prečo / Dôsledky. Neisté veci sú označené „(overiť)“. Vyčítané z kódu, commitov a `PLAN.md` 2026-11-17.

## Engine a renderer
- Godot 4.6, iba GDScript (bez C#), renderer GL Compatibility (`project.godot`).

## Obsah a balans v dátach
- Balans a obsah sú v `data/*.json`, nie v kóde (`README.md`).

## Automatické testy cez bota
- Bot (`--bot`, `--expect=udalosť`) a `tools/run_checks.sh`. Testy nikdy neukladajú profil hráča.
- Každý commit by mal prejsť testami (`PLAN.md` → Ako pracujeme) (overiť, či stačí QUICK).

## Uložené hry
- Profil má verzie a migrácie. Pri migrácii sa kópia uloží do `profile.vN.cfg`, zápis je atomický a 7 denných záloh (commit f5b93d4). Odomknutia, hviezdy ani príbehy sa nesmú stratiť.

## Výbava
- 8 slotov, 6 rarít, sety (commit 083e04d). Návrh v `INVENTAR.md` (12 slotov) je starší a nerealizovaný v tej podobe (overiť).
- Výbava sa na mačkách nekreslí (`PLAN.md` → Pravidlá, 9.11.).

## Vizuál
- Pixel art generujú Python skripty (`tools/gen_*.py`) (overiť, či ich treba pri builde).
- UI v kartónovom štýle „krabica od topánok“. Používateľ ho vybral z 5 návrhov (`PLAN.md`, 13.11.).

## Zrušené
- Voľba „Pokojná štvrť“. Tlačenie územia nahradili vlajky bossov (`PLAN.md` → Zrušené).

## Build pre kamarátov
- Windows exe bez dev nástrojov (`README.md`) (overiť export preset).

## 2026-11-17 – Studio AI proces
- Rozhodnutie: hra používa spoločný proces štúdia `game-studio` (`.ai/STUDIO_PROCESS.md`). Na konci úlohy Claude commitne a pushne (bod F). To nahrádza staré pravidlo „commit a push, keď to hráč povie“.
