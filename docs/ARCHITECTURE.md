# Architektúra
Iba to, čo v kóde naozaj existuje. Pri zmene systémov aktualizuj.

## Hlavné systémy
| Systém | Hlavné súbory | Zodpovednosť |
|---|---|---|
| Dáta | `scripts/autoload/game_data.gd`, `data/*.json` | načítanie obsahu a balansu |
| Profil | `scripts/autoload/profile.gd` | `user://profile.cfg`, verzie, migrácie, denné zálohy |
| Nastavenia, audio | `scripts/autoload/settings.gd`, `audio.gd` | nastavenia, hudba a zvuky |
| Beh hry | `scripts/main.gd` (`scenes/main.tscn`) | herná slučka, koniec noci, súhrn, debug prepínače |
| Vlny | `scripts/spawner.gd`, `data/stages.json` | vlny podľa minúty, bossovia, udalosti |
| Nepriatelia | `scripts/enemies/enemy_manager.gd`, `enemy*.gd`, `data/enemies.json` | pohyb, priestorová mriežka, strely, hazardy |
| Hráč | `scripts/player/player.gd`, `instinct.gd`, `species.gd`, `partner.gd`, `data/cats.json` | mačky, inštinkty, druhy zvierat, partner |
| Zbrane | `scripts/weapons/weapon.gd` + ~30 zbraní, `combos.gd`, `data/weapons.json`, `branches.json` | auto útoky, evolúcie, vetvy, kombá |
| Progres | `scripts/progression/upgrades.gd`, `items.gd`, `goals.gd`, `achievements.gd` | level-up, gear (8 slotov, 6 rarít, sety), ciele, achievementy |
| Questy | `scripts/quests/quest_director.gd`, `*_quest.gd`, `quests/chain/*_step.gd`, `data/quests.json`, `chains.json` | príbehy a reťazové úlohy na mapách |
| Svet | `scripts/world/floor.gd` (chunky 320×320), `terrain.gd`, `trap.gd`, `night.gd`, `weather.gd`, `boss_arena.gd`, `extraction.gd` | mapa, pasce, deň a noc, počasie, únik |
| UI | `scripts/ui/hud*.gd`, `box_*.gd`, `district_map.gd`, panely, `dev_panel.gd`, `dev_launcher.gd` | HUD, menu, kartónový štýl, dev nástroje |
| FX a art | `scripts/fx/*`, `scripts/util/sprites.gd`, `cat_art.gd`, `tools/gen_*.py` | efekty, generovaný pixel art |
| Lokalizácia | `locale/translations.csv`, `tools/translations_tool.gd`, `strings_check.gd` | 6 jazykov |

## Vzťahy a tok dát
- Autoloady sú dostupné všade. `GameData` číta `data/*.json`, `Profile` drží trvalý progres hráča.
- `main.gd` riadi beh. `spawner.gd` podľa `stages.json` posiela nepriateľov do `enemy_manager.gd`. Zbrane hráča útočia na nepriateľov cez priestorovú mriežku manažéra.
- `quest_director.gd` spúšťa questy a reťazové kroky na mape a odmeny zapisuje do profilu.
- Testovací bot (`--bot`, `--expect=`) zapisuje udalosti do logu (BotLog). `tools/run_checks.sh` vyhodnocuje „TEST: FAIL“.
