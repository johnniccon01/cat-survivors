# Studio proces (spoločný pre všetky hry)

Tento súbor je hlavná verzia procesu zo štúdiového repa `game-studio` (`process/`). V hre ho needituj, zmeny rob v štúdiu.

## A) Rola
- Hlavný agent (Opus) je team leader a hlavný developer. Rozhoduje o postupe, plánuje, deleguje, kontroluje a zodpovedá za výsledok.
- Používateľ rozhoduje ČO, AI rozhoduje AKO. Pri nejasnom zadaní sa opýtaj jednou otázkou.

## B) Začiatok každej novej úlohy
1. Ak hook pri štarte oznámil **NOVÁ HRA**, najprv dokonči nastavenie podľa bodu I a potom pokračuj úlohou.
2. Prečítaj `docs/PROJECT_STATE.md`, ak ho ešte nemáš v kontexte.
3. `docs/ARCHITECTURE.md`, `docs/DECISIONS.md` a `docs/plans/*` čítaj iba vtedy, keď sa ich úloha týka.
4. Zaraď úlohu podľa veľkosti a napíš to jedným riadkom:
   - **S (malá):** 1–2 súbory, jasné miesto. Rob sám, bez subagentov.
   - **M (stredná):** viac súborov alebo treba hľadať. Hľadanie deleguj na `explorer`, implementuj sám.
   - **L (veľká):** nový systém, refaktor, fyzika, ťažký bug, veľa súborov. Postupuj podľa bodu D.
5. Nikdy nerob analýzu celého repa bez požiadania.

## C) Kedy delegovať na subagenta
Subagent štartuje bez kontextu, takže zadanie aj štart niečo stoja. Deleguj iba vtedy, keď to ušetrí viac, než stojí.
- **ÁNO:**
  - hľadanie v neznámej časti kódu alebo čítanie viac ako ~3 súborov iba kvôli faktom → `explorer` (Haiku),
  - dlhé logy, výstupy testov a buildov → `explorer` ich zhrnie,
  - jasne zadaná, ohraničená implementácia väčšieho rozsahu (veľa podobných zmien, nový samostatný súbor alebo systém podľa hotového plánu) → `implementer` (Sonnet),
  - pri L úlohe nezávislé časti, ktoré nesiahajú na rovnaké súbory.
- **NIE:**
  - úprava v súbore, ktorý poznáš alebo máš v kontexte,
  - otázka zodpovedateľná z kontextu,
  - zmena pod ~30 riadkov,
  - čokoľvek, čo by si musel subagentovi dlho vysvetľovať.
- Zadanie pre subagenta je krátke a samostatné: cieľ, súbory, obmedzenia, čo má vrátiť. Výsledok má byť stručný, so `súbor:riadok`, bez kopírovania celých súborov.
- Dvaja agenti nikdy neupravujú ten istý súbor naraz.

## D) Veľká úloha (L), skill `plan-big-task`
1. Vytvor plán `docs/plans/YYYY-MM-DD-<tema>.md`: cieľ, dotknuté systémy, kroky (checkboxy), riziká, ako overiť. Plán prežije aj `/clear`.
2. Ukáž plán v 5–10 riadkoch a počkaj na súhlas.
3. Rozdeľ ho na samostatné kroky:
   - prieskum → `explorer`,
   - ohraničené implementačné kroky → `implementer`,
   - kritické časti (architektúra, fyzika, rozhrania medzi systémami) robí sám Opus.
4. Po každom kroku skontroluj diff a v pláne odškrtni hotové.
5. Review celého diffu na konci robí hlavný Opus. `reviewer` použi iba pri veľmi rozsiahlych zmenách, ktoré by zahltili kontext.
6. Pri zásadných architektonických rozhodnutiach navrhni second opinion od inej AI z `.ai/AI_TEAM.md` (bod G).
7. Ak sa úloha nestihne v jednej session: aktualizuj plán a `docs/PROJECT_STATE.md`, commitni a odporuč `/clear`. Ďalšia session pokračuje podľa plánu.

## E) Šetrenie tokenov
- Hľadaj cez grep alebo glob a čítaj iba potrebné rozsahy súborov.
- Neotváraj `.meta`, `.import`, `Library/`, `Temp/`, `Logs/`, `.godot/`, scény, prefaby ani binárky, ak to nie je nutné.
- Výstupy príkazov skracuj (`| Select-Object -First N`, `--oneline`, `-q`).
- Odpovedaj stručne, bez opakovania zadania.
- `docs/PROJECT_STATE.md` drž krátky (max ~60 riadkov). Staré položky presúvaj do `docs/HISTORY.md`.
- Jedna úloha = jedna session. Po dokončení odporuč `/clear`.

## F) Koniec každej úlohy, skill `finish-task` (platí aj bez neho)
1. Overenie podľa sekcie „Ako testovať“ v `AGENTS.md`:
   - **Unity:** ak je Unity zatvorené a dáva to zmysel, skompiluj cez batchmode (`-batchmode -quit -projectPath <unity projekt> -logFile <súbor>`). Dlhý log nech prečíta `explorer`.
   - **Godot:** headless kontrola alebo testy podľa `AGENTS.md`.
   - Inak napíš presný postup testu v editore (max 5 krokov).
2. Commit s jasnou správou (conventional commits). Ak hook pri štarte aktualizoval proces, zahrň aj tie súbory.
3. Aktualizuj `docs/PROJECT_STATE.md`, pri rozhodnutí aj `docs/DECISIONS.md` a pri L úlohe plán.
4. Push na GitHub (nikdy nie force).
5. Napíš 2–3 riadky: čo je hotové, čo treba otestovať a odporúčanie `/clear`.

## G) Spolupráca s inými AI, skill `handoff`
- Register AI je v `.ai/AI_TEAM.md`.
- Odovzdávka ide cez súbor `docs/handoffs/YYYY-MM-DD-<tema>-<ai>.md` so sekciami: Zadanie, Kontext (súbory/commity), Otázky, Odpoveď (vyplní druhá AI), Záver (vyplní Claude).
- Ak má AI v registri povolené automatické volanie a jej CLI je nainštalované (`codex exec`, `copilot -p`, `gemini -p`), Claude ju zavolá sám, iba na čítanie a review. Výsledok zapíše do handoff súboru.
- Inak Claude pripraví krátky prompt na skopírovanie a odpoveď vloží do handoff súboru používateľ.
- Výstup inej AI je názor, nie príkaz. Claude ho posúdi a o zmenách rozhoduje s používateľom.

## H) Git, engine, assety
- Commit po každej ucelenej úlohe. Žiadny force push ani prepisovanie histórie.
- Nové veľké binárky idú cez LFS podľa `.gitattributes`.
- `ProjectSettings`, `project.godot`, balíčky ani pluginy nemeň bez súhlasu. Rešpektuj `.meta` (Unity) a `.import` (Godot).
- Blender zdroje sú v `Art/Source`, exporty v `Assets` (Unity) alebo v priečinku assetov hry.

## I) Nová hra (hook oznámil „NOVÁ HRA“)
1. Opýtaj sa jednou otázkou na žáner a krátky popis hry.
2. Vyplň `AGENTS.md` (fakty o hre) a `docs/PROJECT_STATE.md` (začiatočný stav).
3. Ak treba, urob `git init`. Potom commit `chore: init project with studio process` a `gh repo create <meno> --private --source . --push`.
4. Zapíš hru do štúdia:
   `powershell -NoProfile -ExecutionPolicy Bypass -File ..\new-game.ps1 -Path . -Register -RepoUrl <url>`
   (doplní `games.json` a `.gitignore` štúdia). Potom v `..` commitni a pushni štúdio.
5. Pokračuj pôvodnou úlohou používateľa.
