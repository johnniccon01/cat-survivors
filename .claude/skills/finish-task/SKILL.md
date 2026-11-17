---
name: finish-task
description: Ukončenie úlohy - overenie (kompilácia/testy), commit, aktualizácia docs/PROJECT_STATE.md a DECISIONS.md, push na GitHub a krátky záver.
---

# Koniec úlohy

1. **Overenie** podľa sekcie „Ako testovať“ v `AGENTS.md`:
   - Unity: ak Unity nebeží (`Get-Process Unity -ErrorAction SilentlyContinue`), spusti batchmode kompiláciu:
     `& "<Unity.exe>" -batchmode -quit -projectPath <unity projekt> -logFile "$env:TEMP\unity-build.log"`.
     Log nech zhrnie `explorer` (iba chyby a výsledok).
   - Godot: headless kontrola alebo testy podľa `AGENTS.md`.
   - Ak sa to nedá: napíš presný postup testu v editore (max 5 krokov).
2. **Commit:** `git add` iba súvisiace súbory a správa v štýle conventional commits (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`). Ak hook pri štarte aktualizoval proces (`.ai/`, `.claude/`…), pridaj aj tie súbory.
3. **Docs:**
   - `docs/PROJECT_STATE.md`: hotové, rozpracované, známe problémy, ďalšie kroky (max ~60 riadkov, staré veci presuň do `docs/HISTORY.md`),
   - `docs/DECISIONS.md`, ak padlo rozhodnutie,
   - plán v `docs/plans/`, ak išlo o L úlohu.
   Commitni ich (`docs: update project state`), alebo ich zahrň do predošlého commitu pred pushom.
4. **Push:** `git push` (nikdy nie force). Ak vetva nemá upstream, `git push -u origin <vetva>`.
5. **Záver** v 2–3 riadkoch: čo je hotové, čo treba otestovať a odporúčanie `/clear`.
