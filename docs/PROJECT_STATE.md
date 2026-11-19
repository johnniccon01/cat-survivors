# Stav projektu
Aktualizované: 2026-11-19. Max ~60 riadkov, staré veci presúvaj do `HISTORY.md`. Podrobný plán a história sú v `PLAN.md`.

Vetva: `main` (pushnutá).

## Hotové
- 4 štvrte so 47 mapami, každá s finálnym bossom: Mačacie mesto 15, Psie štvrte 16, Divočina 12, Firma 4.
- 25 hrateľných mačiek (vrátane skrytých Anjela a Diabla), 30 zbraní a 30 evolúcií (18 s vetvami), 20 pasív.
- 158 bossov, 173 príbehov, 6 jazykov, 46 achievementov.
- Výbava (8 slotov), dielne, druhy zvierat, verzie uložených hier, balans neskorej hry.
- Export Windows exe, dev launcher, F1 panel, titulky.
- UI v kartónovom štýle a teplý tón máp (13.11.).
- Spoľahlivejšie bot testy (8d84bc9).
- Kontrola pred vydaním (18.11.): sada 489/489, zbrane 60/60, príbehy 358/359, zaseknuté moby 0–1 na mapu. Doladené: snehuliaci strieľajú 1 dopad / 4 s, Lis v príbehu Prehriatie ×1,2, menšie poškodenie na Policajných psoch, Snežnom kopci a Parkovisku firmy.
- Studio AI proces nasadený (2026-11-17).
- Médiá do obchodu (19.11.): 11 screenshotov (1080p + 4K), capsule obrázky v rozmeroch pre Steam, logo s alfou, trailer v1 47,5 s (`store_media/v1/`) a v2 57,5 s s číslami o obsahu (173 questov, 158 bossov, 251 nepriateľov, 48 legendárnych predmetov, 15+ h kampane = 47 máp × 20 min, Mačacie sny), obe 1080p60, −14 LUFS, plus 15 s verzie na výšku. Sú v `store_media/` (mimo repa). Znovu sa vyrobia skriptami v `tools/media/`, postup je v `docs/plans/2026-11-18-store-media.md`.

## Rozpracované
- Doladenie UI a teplá mapa štvrtí (`PLAN.md` ju vedie ako otvorenú, commit ad17e35 ju možno už rieši, overiť).
- Pixel art: ikony a projektily sú hotové. Efekty zbraní a rybie kosti sa ešte kreslia kódom.
- Mačacie sny: týždenný sen nie je hotový (presunutý až po vydaní na Steam).

## Známe problémy / čaká na hráča
- Pozrieť trailer a médiá do obchodu (`store_media/`). Na level-up screenshote pretekajú texty v strednej karte (Long Nap).
- Playtest nového UI, dev launchera a obtiažnosti máp (`PLAN.md` → Čaká na teba).
- Kampaň s botom: Psie štvrte a Divočina potrebujú veľa oživení (30–100). Policajné psy, Snežný kopec a Parkovisko firmy bot po úprave vyhrá ~2 z 3. Kampaň púšťaj bez iných testov naraz, inak bot pri záťaži prehráva.
- Repo rastie kvôli WAV súborom (~135 MB v pracovnom strome, `.git` ~243 MB).

## Otvorené rozhodnutia
- Co-op pre 2 hráčov? Steam alebo itch.io? Neskoršie štvrte ako DLC alebo v hlavnej hre?
- Zlúčiť talizmany, artefakty a výbavu do menej systémov? Ponechať dev nástroje pri vydaní?

## Ďalšie kroky
1. Spracovať feedback z playtestu.
2. Príprava vydania na Steam.
3. Rozhodnúť o dev nástrojoch a zlúčení systémov.
4. Týždenný sen v Mačacích snoch.
