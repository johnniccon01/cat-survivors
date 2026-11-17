# AI tím

Spoločné pravidlá pre všetky AI sú v `AGENTS.md` a `.ai/STUDIO_PROCESS.md`. Odovzdávanie práce ide cez `docs/handoffs/` (bod G procesu).

| Meno | Rola | Kedy použiť | Prístup | Auto volanie | Číta pokyny |
|---|---|---|---|---|---|
| Claude Code (Opus) | team leader, hlavný developer | vždy, riadi prácu | `claude` (Claude Code) | – | `CLAUDE.md` → `.ai/STUDIO_PROCESS.md`, `AGENTS.md` |
| ChatGPT / Codex | second opinion: architektúra, review | zásadné rozhodnutia, veľké diffy | `codex exec "<prompt>"` alebo ručne cez prompt | áno, iba ak je nainštalované `codex` CLI, iba čítanie | `AGENTS.md` |
| GitHub Copilot | rýchle úpravy v editore, voliteľne review | drobnosti počas písania kódu v editore | VS Code; `copilot -p "<prompt>"` | nie | `.github/copilot-instructions.md` → `AGENTS.md` |
| Gemini | voliteľný druhý názor | podľa potreby | `gemini -p "<prompt>"` alebo ručne | áno, iba ak je nainštalované `gemini` CLI, iba čítanie | `GEMINI.md` → `AGENTS.md` |

## Pravidlá
- Automaticky volaná AI dostane iba úlohu na čítanie alebo review. Nič neupravuje a necommituje.
- Pred volaním Claude overí, či CLI existuje (`Get-Command codex`). Ak neexistuje, pripraví prompt na skopírovanie.
- Výstup inej AI je názor. Rozhoduje Claude s používateľom.

## Ako pridať novú AI
1. Pridaj riadok do tabuľky vyššie v štúdiu (`process/.ai/AI_TEAM.md`): rola, kedy, prístup, auto volanie, pokyny.
2. Ak AI číta vlastný súbor s pokynmi, pridaj ho do `process/` (napr. `process/XYZ.md`). Súbor má byť krátky a odkazovať na `AGENTS.md` a `.ai/STUDIO_PROCESS.md`.
3. Zvýš `process/VERSION`, commitni a pushni štúdio. Potom spusti `sync-process.ps1`, alebo sa hry aktualizujú samy pri ďalšom otvorení.
