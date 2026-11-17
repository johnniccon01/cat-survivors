---
name: plan-big-task
description: Postup pre veľkú úlohu (L) - nový systém, refaktor, fyzika, ťažký bug, veľa súborov. Vytvorí plán v docs/plans, počká na súhlas a rozdelí prácu medzi explorer/implementer.
---

# Veľká úloha (L)

1. Ak treba fakty z neznámeho kódu, pošli krátke zadanie `explorer`ovi (Haiku). Nečítaj celé repo.
2. Vytvor `docs/plans/YYYY-MM-DD-<tema>.md`:
   ```markdown
   # <Téma>
   Stav: návrh | schválený | hotový
   ## Cieľ
   ## Dotknuté systémy a súbory
   ## Kroky
   - [ ] 1. ... (kto: Opus / implementer / explorer)
   ## Riziká
   ## Ako overiť
   ```
3. Ukáž používateľovi plán v 5–10 riadkoch a počkaj na súhlas.
4. Vykonávaj kroky:
   - prieskum → `explorer`,
   - ohraničené implementačné kroky → `implementer` (cieľ, súbory, obmedzenia, čo vrátiť),
   - architektúra, fyzika a rozhrania medzi systémami → sám,
   - nezávislé kroky, ktoré nesiahajú na rovnaké súbory, môžu bežať paralelne.
5. Po každom kroku skontroluj diff (`git diff --stat`, potom potrebné časti) a odškrtni krok v pláne.
6. Na konci urob review celého diffu sám. `reviewer` použi iba pri veľmi rozsiahlom diffe.
7. Pri zásadnom architektonickom rozhodnutí navrhni second opinion (skill `handoff`).
8. Ak sa úloha nestihne: aktualizuj plán a `docs/PROJECT_STATE.md`, commitni, odporuč `/clear`.
9. Ukonči skillom `finish-task`.
