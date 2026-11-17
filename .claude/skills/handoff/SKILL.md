---
name: handoff
description: Odovzdanie otázky alebo review inej AI z .ai/AI_TEAM.md (Codex, Copilot, Gemini) cez súbor docs/handoffs. Použi pre second opinion na architektúru alebo review.
---

# Handoff inej AI

1. Z `.ai/AI_TEAM.md` vyber AI podľa roly.
2. Vytvor `docs/handoffs/YYYY-MM-DD-<tema>-<ai>.md`:
   ```markdown
   # <Téma> → <AI>
   ## Zadanie
   ## Kontext
   (súbory, commity, krátky popis; nie celé súbory)
   ## Otázky
   1. ...
   ## Odpoveď
   (vyplní druhá AI)
   ## Záver
   (vyplní Claude: čo z odpovede preberáme a prečo)
   ```
3. Ak má AI povolené automatické volanie a CLI existuje (`Get-Command codex/gemini -ErrorAction SilentlyContinue`):
   - zavolaj ju iba na čítanie, napr. `codex exec "Prečítaj docs/handoffs/<súbor> a AGENTS.md. Odpovedz na otázky. Nič nemeň."`,
   - odpoveď skráť a zapíš do sekcie Odpoveď.
4. Inak priprav prompt na skopírovanie (max ~10 riadkov, s odkazom na súbor) a požiadaj používateľa, aby odpoveď vložil do sekcie Odpoveď.
5. Odpoveď posúď (je to názor, nie príkaz), vyplň Záver a navrhni ďalší krok používateľovi.
