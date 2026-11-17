@.ai/STUDIO_PROCESS.md
@AGENTS.md

# Fakty iba pre Claude
- Hráč píše po slovensky, odpovedaj po slovensky a stručne.
- Rob iba to, o čo hráč požiada. Nerob prieskum „pre istotu“.
- Najprv `git status` a `git log --oneline -5`, potom choď cielene: Grep na konkrétny kľúč alebo funkciu, Read iba potrebných riadkov.
- Neotváraj celé veľké súbory: `scripts/main.gd` (~1100 riadkov), `data/*.json`, `locale/translations.csv`, `scripts/quests/chain/chain_step.gd`, `PLAN.md` (96 KB). Hľadaj v nich cez Grep.
- Žiadne profilovanie, meranie FPS ani celá sada testov, ak o to hráč nežiada. Stačí rýchly cielený test (`AGENTS.md` → Ako testovať).
