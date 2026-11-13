# Plán – Cat Survivors

Živý zoznam toho, čo je hotové, čo je nedorobené a čo sa ešte nerobilo. Po každom kroku ho aktualizujeme.

Naposledy aktualizované: 8. 11. 2026 – celý plán prejdený a **overený s hrou** (počty z `data/*.json`, funkcie v kóde, nástroje v `tools/`).

**Značky:** `[x]` hotové · `[~]` nedorobené (časť je v hre, niečo chýba) · `[ ]` nerobené · `[?]` čaká na tvoje hranie alebo rozhodnutie.

---

## Kde sme (overené 8. 11. 2026)

| Čo | V hre | Pôvodný cieľ |
|---|---|---|
| Štvrte | 4: Mačacie mesto (15 máp), Psie štvrte (16), Divočina (12), Firma (4) | – |
| Mapy | **47**, každá s finálnym bossom | 12+ ✓ |
| Hrateľné postavy | **25** (19 mačiek, pes Ruby, mýval Lotor, Vlk, Medveď, Lev, + tajní Anjel a Diabol) a 6 postáv len do príbehov | 20 ✓ |
| Zbrane | **30** základných + 30 evolúcií, 18 zbraní s vetvami (3 vetvy) | 30 ✓ |
| Pasívky | **20** | 20 ✓ |
| Nepriatelia / bossovia | 93 bežných, **158** bossov (47 finálnych) | 60 bossov ✓ |
| Príbehy | **173** (363 krokov, 42 tajných) + 19 questov mačiek, 7 vedľajších, 7 príbehových | 150+ ✓ |
| Kniha questov | 83 línií | – |
| Meta | 46 úspechov, 33 cieľov, 29 artefaktov, 30 talizmanov, 16 vylepšení v obchode, 8 prekliatí, 6 šampiónov, 22 pascí, 4 psí parťáci | – |
| Výbava | 5 slotov, 4 rarity (bežná, vzácna, legendárna, snová), 40 základov, 48 legendárok, 15 vlastností, 3 snové sety | pozri Výbava nižšie |
| Endgame | Mačacie sny: hĺbka, úlomky, nočné mory, snové body | – |
| Jazyky | 6: EN, SK, CS, ES, RU, ZH | – |
| Testy | ~480 scenárov v `tools/run_checks.sh`, kampaň, kontrola zaseknutí, kontrola textov a rozloženia | – |
| Vývoj | Dev launcher (questy, mapy, bossovia, laboratórium), F1 panel so záložkami | – |
| Export | `builds/CatSurvivors.exe` + testovacie zipy pre testerov (23. 10. – 6. 11.) | – |

---

## Čaká na teba (hranie a spätná väzba)

Toto sa nedá overiť botom – treba zahrať a povedať. Zoradené od najdôležitejšieho.

- [?] **Nové UI** (8. 11.) – HUD, pauza, koniec noci, obchod, denník, level-up, mapa mesta: zahrať a povedať, čo prekáža
- [?] **Dev launcher** (`Spustit\8`) – prejsť questy a bossov, ktoré si ešte nevidel
- [?] **Obtiažnosť** jednotlivých máp a štvrtí (v poslednej kampani bot prehral len Snežný kopec a Garáž strojov, tesne)
- [?] Sily: ceny v obchode, talizmany, artefakty, dary svätýň, veľká truhlica bossa – nie je niečo príliš silné alebo zbytočné?
- [?] Čitateľnosť špeciálnych útokov bossov (férové, vidno varovanie?)
- [?] Terén: šírka uličky v Supermarkete, frekvencia prílivu (konštanty v `scripts/world/terrain.gd`)
- [?] Tajné príbehy: vzdialenosti 7000 / 9000 px, sila ich bossov
- [?] Túlavec: nie je na začiatku priťažký?
- [?] Hudba: spätná väzba na skladby (ja ich nepočujem)
- [?] Výkon na notebooku: zahrať noc a poslať `perf.log`
- [?] Gamepad v nových obrazovkách (tlačidlá sú klikateľné, ovládačom netestované)

## Nedorobené

- [x] **Balans neskorých zbraní** (9. 11.) – 8 najslabších evolúcií posilnených, všetky v pásme 50–75 tis. poškodenia za 2 min v 10. minúte (bot)
- [x] **Finále hry** (9. 11.) – titulky po porážke riaditeľa (epilóg, spojenci, všetky mačky, tvoja cesta, poďakovanie, pochod mačiek), tlačidlo Titulky v menu
- [~] **Grafika** – ikony zbraní a schopností a strely sú od 9. 11. pixel-art (pečie ich `tools/bake_art.gd`); efekty zbraní (vlny, lúče, výbuchy) a rybie kosti ostávajú kreslené kódom. Možný ďalší krok: skúška jednej mapy v Blenderi.
- [~] **Výbava** (9. 11. rozšírená, spoločná pre všetky mačky – tak to ostane; na mačkách sa nekreslí, pozri Pravidlá):
  - [x] 8 slotov (obojok, čiapka, okuliare, vesta, batôžtek, labky, pazúry, chvost), 64 základov, 48 legendárok
  - [x] 6 rarít (bežná, neobvyklá, vzácna, epická, legendárna, snová), 19 vlastností + vlastnosti pre jednu zbraň (+% poškodenie, +1 strela)
  - [x] Úroveň predmetu 1–15 podľa mapy, temnoty a hĺbky snu
  - [x] 9 setov (3 snové, 6 nočných na epických predmetoch)
  - [x] Panel: porovnanie s nasadeným, zamknutie, zoradenie, sklad 60, až 3 legendárky naraz
  - [x] Dielne (9. 11., tlačidlo Dielňa / K na mape mesta), v každej štvrti iná, platí sa stavebným materiálom: Mačacie mesto – šijacia dielňa (prešije jednu vlastnosť), Psie štvrte – kováč (+1 úroveň), Divočina – bylinkárka (+1 vlastnosť, raz na predmet), Firma – laboratórium (+1 vzácnosť); všade rozobratie predmetu na materiál
- [x] **Uloženie hry** (9. 11.) – verzia profilu a migrácia (staré predmety dostanú úroveň 1), kópia starého profilu pred migráciou, bezpečný zápis cez dočasný súbor, denné zálohy (posledných 7)
- [x] **Zvieratá hrajú po svojom** (9. 11.) – pes odolný, vlk so svorkou vlčiatok, medveď zápasník (zbrane zblízka +30 %), lev kráľ (kritiky, strach okolo), mýval zlodej (truhlice); štítok s vysvetlením pri postave
- [x] **Vývojársky spúšťač** (9. 11.) – `Spustit\8` otvára normálne menu so všetkými štvrťami, po dev hre sa ukáže mapa mesta; launcher je tlačidlo DEV v menu
- [~] **Terén** – stromy, múriky, ulička, príliv, pásy, izby so stenami (Byt, Pivnica) a špeciality máp sú hotové; nápady navyše (lisy v Továrni, padajúce regále, mosty cez vodu) nie
- [~] **Mačacie sny** – všetko z časti 6 hotové okrem týždenného snu (nechané na prípravu na Steam)

## Nerobené

- [ ] **Aktívna schopnosť mačky** (jedno tlačidlo, cooldown) – dnes majú mačky len inštinkty, ktoré sa spúšťajú samé
- [ ] **Krotenie** – pôvodný návrh sa nepáčil, treba vymyslieť inak (bez ďalšej postavy na obrazovke)
- [ ] **Kozmetika** pre mačky za zlato
- [ ] **Balík / DLC** – rozdelenie psích a ďalších štvrtí do balíka (`pack`) sa nerobilo

## Pravidlá (rozhodol si ty)

- **Výbava sa na mačkách nikdy nekreslí** (9. 11. 2026). Predmety existujú, fungujú a vidno ich v paneli Výbava, ale na mačke v hre ani v menu sa neukazujú. Meniť to len vtedy, keď to výslovne napíšeš.

## Otvorené otázky (rozhoduješ ty)

- [?] Co-op pre dvoch hráčov – áno alebo nie?
- [?] Vydanie: len pre seba, itch.io alebo Steam? Psie štvrte a ďalšie ako súčasť hry alebo DLC?
- [?] Zlúčiť talizmany, artefakty a výbavu do menej systémov? (otázka z 28. 10.)
- [?] Dev nástroje (launcher, F1) sú len v ladiacej verzii – vo vydanej hre ich nevidno; odstrániť úplne alebo nechať?

## Zrušené alebo nahradené

- Pôvodná „3. štvrť s psami ako hrateľnými postavami“ → nahradená Divočinou a Firmou; psi sú parťáci (Ruby, Barney, Bodka, Generál) a Ruby je hrateľná
- Dobývanie posúvaním hranice → nahradené vlajkami bossa (`dobytie-vlajky`)
- Voľba „Pokojná štvrť“ → vyhodená, obliehanie je zriedkavé
- Ciele „Viac obsahu než konkurencia“ (12 máp, 150 questov, 60 bossov, 30 zbraní, 20 mačiek) → všetky splnené, pozri tabuľku hore

---

# História (čo sa robilo, od najnovšieho)

Staré časti nižšie ostávajú ako záznam. Body, ktoré v nich ostali otvorené, sú presunuté hore do stavu a v histórii sú označené `[→]`.

## 8. 11. 2026: vývojárska konzola (hotové)
- [x] Dev launcher (DEV v menu, `--dev-launcher`, `Spustit\8`): každý quest pod svojou mapou → spustí sa na tej mape v minúte otvorenia s buildom; mapy v ľubovoľnej minúte, finále, nekonečná noc; každý boss na svojej mape; laboratórium; špeciálne udalosti. Nič sa neukladá.
- [x] F1 panel so záložkami: Run (čas, rýchlosť, počasie, svätyne, pasce, level-up, truhla), Build (každá zbraň/pasívka/evolúcia/vetva, level hore-dole, uložiť „môj build“), Enemies (spawn ×1/5/20/100, figuríny, vlny vyp., DPS meter), Bosses, Quests.

## 8. 11. 2026: nové UI (hotové)
- [x] HUD: XP pruh, level, zdravie s číslom, väčšie sloty, pruh noci s bossmi, ikony vpravo, menšie oznámenia
- [x] Pauza: karty zbraní, „Teraz“ a správy s časom, príbehy s pruhmi, klávesy; oznámenia sa počas pauzy skryjú
- [x] Koniec noci: panel s dlaždicami, poškodenie podľa zbraní, klikateľné tlačidlá
- [x] Obchod (karty s ikonami), denník (mapy vľavo, karty príbehov, filter), level-up (pruh vzácnosti, × v rohu, riadok „Máš“)
- [x] Mapa mesta: klávesy ako klávesy, skupiny Mačka / Noc, štatistiky ako štítky, mriežka všetkých mačiek

## Krátkodobý plán – časť 6 (zadané 8. 11. 2026: endgame Mačacie sny, robí sa po časti 5)

Návrh je v `ENDGAME.md`.

1. [x] **Mapa snov a hĺbka** (hotové 8. 11., značka `sny`: tlačidlo Sny pri nočných tlačidlách po výhre nad riaditeľom (`game_won`), panel `DreamPanel` ponúkne 3 sny – náhodná vyhraná mapa z ktorejkoľvek štvrte o hĺbku hlbšie; každá hĺbka +12 % zdravia, +4 % poškodenia nepriateľov a +15 % zlata; `Profile.dream_*`, `--dream=N` pre testy).
2. [x] **Snové úlomky** (hotové 8. 11.: úlomky sú kliatby – sny ich ponúkajú 0/1/2 v sebe, každý vyhraný sen zanechá jeden a hráč ich môže vložiť do ďalšieho snu: ťažšie, viac zlata).
3. [x] **Nočné mory** (hotové 8. 11.: každá 5. hĺbka; Kráľ potkanov z nočnej mory, Tieňový Generál, Nočný vlk, Megastroj – viac zdravia, útoky viacerých bossov a druhá fáza; `data/dreams.json`).
4. [x] **Snová výbava** (hotové 8. 11.: vzácnosť „snová“ – o 2 vlastnosti viac a silnejšie, padá len v snoch, v hlbších častejšie; sety Mesiac, Hviezda, Oblak – bonus za 2 a 3 kusy). Vylepšovanie výbavy materiálmi zatiaľ nie.
5. [x] **Nekonečný rast** (hotové 8. 11.: každý vyhraný sen dá snový bod, za body sa v paneli Snov kupujú malé bonusy bez stropu – sila, zdravie, zlato, rast, šťastie; platia vo všetkých nociach).
6. [x] **Testy a balans** endgamu (hotové 8. 11., značka `testy-sny`: scenáre snov, nočnej mory a snovej výbavy; panel Snov v testoch rozloženia; kontrola zaseknutých nepriateľov na všetkých 48 mapách `tools/stuck_check.sh` (6 máp naraz, ~4 min) – na mapách so stenami sa nepriatelia zasekávali v rohoch, kde sa stretávajú steny susedných políčok; steny teraz končia 44 px pred rohom a k tomu obchádzka rohu v `EnemyManager` → všade 0 zaseknutých). Týždenný sen až pri príprave na Steam.

## Krátkodobý plán – časť 5 (zadané 8. 11. 2026: Divočina a Firma, robí sa po časti 4)

Návrh je v `TRETIA_STVRT.md`. Každý krok s testami, commitom, značkou a pushom; texty vo všetkých jazykoch.

1. [x] **Základ tretej a štvrtej štvrte** (hotové 8. 11., značka `divocina-firma-mapy`: `WildTown` – les, rieka s vodopádom, močiar, hory, zamrznuté jazero, pás výrubu k plotu firmy; `CompanyTown` – areál s bránou, parkoviskom, garážou, laboratóriom s klietkami a vežou; tlačidlo Cestovať ponúkne otvorené štvrte (`DistrictMap.DISTRICTS`, príznaky `train_east`, `wild_road`, `company_gate`); príbeh Divé zvieratá utekajú po Mieri otvorí cestu do Divočiny; `tools/town_shot.gd -- wild`)
2. [x] **Psí parťák** (hotové 8. 11., značka `psi-partak`: `Partner` + `data/partners.json` – Ruby (štekot odhodí a spomalí dav, má ju hráč), Barney bernardín (záchranný súdok lieči, po Nákladnej stanici), Bodka dalmatínka (strieka vodu, po Hasičskej stanici), Generál (rozkaz – výbuch okolo mačky, po Mieri); tlačidlo „Parťák: …“ pri mačke v Divočine a Firme; `--partner=ID` pre testy)
3. [x] **Nepriatelia Divočiny** (hotové 8. 11., značka `divoci-nepriatelia`: zajac, diviača, mladý vlk, diviak, sršeň, losos, havran, medvieďa, losík, biely vlk, motorová píla, malý harvestor, prieskumný dron, robotická stráž; nové tvary v `gen_sprites.py` – medveď, diviak, los, zajac, orol, ryba, píla, harvestor, plemeno vlk)
4. [x] **Divočina mapy 1–4** (hotové 8. 11., značka `divocina-1-4`: Okraj lesa – kmene sa valia výrubom (`logs`), Veľký diviak (kly – tri výpady s brázdou úderov); Hlboký les – vlčia svorka v pruhu (`wolfpack`), Vlčí vodca (lov svorky – vlci z kruhu); Močiar – bahenná vlna (`bog`), Obrí jazvec (podkopanie); Vodopád – prúdy rieky, lososy v pruhu (`salmon`), Kráľovná bobrov (štvorec z kmeňov); 8 malých bossov, korisť, 2 príbehy + tajomstvo na mapu; **Vlk** hrateľný po súboji v Hlbokom lese (Vytie); vzhľad aj pre Medveďa a Leva (druhy `wolf`, `bear`, `lion`))
5. [x] **Divočina mapy 5–8** (hotové 8. 11., značka `divocina-5-8`: Jaskyne – roj netopierov v pruhu, Rys (skoky z tmy); Horská lúka – nárazy vetra, Veľký los (zámachy parohmi); Orlie skaly – kŕdeľ havranov, Zlatý orol (strmhlavé útoky); Zamrznuté jazero – praskajúci ľad, Biely vlk (mráz a črepiny zo štyroch rohov); 8 malých bossov, korisť, 2 príbehy + tajomstvo na mapu)
6. [x] **Divočina mapy 9–12** (hotové 8. 11., značka `divocina-9-12`: Opustený tábor – stádo diviakov, Harvestor (vejáre pílových kotúčov); Výrub – žeriav, Roj dronov (drony okolo mačky a značky na nej); Spálenisko – dym, Starý medveď (medvedie objatie a kruhy úderov), príbeh Medveďova pravda → **Medveď** hrateľný; Plot firmy – robotické hliadky, Strážca strojov (laserové ploty s jedným východom); príbeh Divočiny Stroje (plány, stopy pásov, fotky, Strážca) otvorí cestu do Firmy, príznak `company_gate`)
7. [x] **Firma mapy 1–3** (hotové 8. 11., značka `firma-1-3`: Brána a parkovisko – laserové steny, Šéf ochranky (závory a kamery); Garáž strojov – pásy, stroje v pruhu, Obrí bager (tri lopaty); Laboratórium – poplach a mechanickí psi, Strážca klietok (výboj cez tri body), oslobodenie **Leva**; riaditeľov papagáj uteká a volá stráže, v laboratóriu zmení stranu (príbeh Papagáj, príznak `parrot_friend`); nepriatelia kancelárske stoličky, mechanickí psi, laserové drony, tlačiarne)
8. [x] **Finále** (hotové 8. 11., značka `finale`: Riaditeľova veža – Riaditeľ v obrom buldozéri (dva výpady s radlicou a lopata, pri polovici zdravia plný výkon a ďalšie útoky); každých 9 s príde pomôcť spojenec, ktorého si získal (Ruby, Lotor, Tieň, Iskra, Vlk, Medveď, Lev, Generál, papagáj – `FinaleAllies`); po výhre vtipný koniec v súhrne (papagáj otvorí okno, riaditeľ v blate, polícia, oslava, KONIEC), príznak `game_won`; príbeh Riaditeľ cez všetky mapy Firmy). Záverečná scéna s titulkami zatiaľ len ako text v súhrne.
9. [x] **Testy časti 5** (hotové 8. 11., značka `cast-5`: všetkých 92 scenárov časti 5 – mapy so `--stuck-check`, útoky bossov, nebezpečenstvá, príbehy, súboje, parťáci, finále – bez chyby; rýchla sada obsahuje aj nové štvrte). Kampaň všetkých štvrtí a kontrola zaseknutí na každej mape zostávajú na úplný koniec.

## Krátkodobý plán – časť 4 (zadané 7. 11. 2026: dokončiť Psie štvrte, robí sa po časti 3)

Návrh je v `PSIE_STVRTE.md`. Postup po krokoch, každý s testami, commitom, značkou a pushom; všetko v novom pixel-art štýle, texty vo všetkých jazykoch, nič sa neposúva. Každý boss má vlastný hlavný útok (ako finálni bossovia prvej štvrte).

1. [x] **Základ dvoch štvrtí** (hotové 7. 11., značka `dve-stvrte`: `DogTown` kreslí mesto psov 720×400, `DistrictMap.use_district`, `Profile.district`, tlačidlo Vlak na východ / Vlak domov obnoví obrazovku v druhej štvrti, miesta bez noci ukazujú „čoskoro“ a svoj príbeh; noci majú `district` a môžu mať `requires_flag`): noci majú `"district"` (cats/dogs), `Profile.district`, mapa štvrte kreslí mesto podľa štvrte (mesto psov 720×400 s 16 miestami a hmlou), vlak medzi štvrťami (Vlak na východ / Vlak domov), poradie a čísla miest v rámci štvrte, domov v Psích štvrtiach = Nákladná stanica; `DogDistrictPanel` nahradí skutočná mapa.
2. [x] **Psí nepriatelia** (hotové 7. 11., značka `psi-nepriatelia`: 14 nových – šteňa, blcha, tenisák, pískacia hračka, kosť, frisbee, jazvečík, hydrant, snehuliak, chrt, pudlí pompón, lapač mačiek, pochodový bubon, hliadkový dron; tvar psa má plemená `breed` – šteňa, bernardín, baset, kólia, rotvajler, pudel, jazvečík, chrt, dalmatín, ovčiak, čivava, novofundlanďan, husky, boxer, afgánsky chrt, doga – pre psích bossov; `tools/enemy_shot.gd` berie aj zoznam ID): šteňatá, blchy, tenisky, pískacie hračky, kosti, frisbee, jazvečíky, hydranty, psie drony, snehuliaci, chrty, pudlie pompóny, psí lapači, bubny (+ pár starých); sprity v `gen_sprites.py`.
3. [x] **Mapy 1–4** (hotové 7. 11., značky `ruby-lotor-tien`, `psie-mapy-1-4`: Nákladná stanica – vagóny, posunovanie, Bernardín (útok sudy); Útulok – pletivo, koterce sa otvárajú (`kennels`), Starý baset (vytie), záchrana Tieňa; Psí park – stromy, vystreľovač tenisákov (`ball_launcher`), Kráľ aportu (zoomies), súboj Ruby; Smetisko – múriky z haraburdia, žeriav zhadzuje vraky, rotvajler Kosť (haraburdie), súboj Lotra; 8 malých bossov, korisť, na každej mape 2 príbehy + tajomstvo, príbeh štvrte Generálove rozkazy; grafika `tools/gen_district2.py`)
4. [x] **Mapy 5–8** (hotové 7. 11., značka `psie-mapy-5-8`: Psí salón – pruh horúceho vzduchu z fénov, Pudlová kráľovná (voňavka); Pekáreň piškót – pásy, plechy padajú zhora, Jazvečík pekár (plech úderov); Dostihová dráha – ploty, chrty v dráhe, Blesk (šprint); Hasičská stanica – rady áut, hadice, Veliteľ hasičov (prúd vody dookola), záchrana Iskry (Kropič, Požiarny poplach); 8 malých bossov, korisť, 2 príbehy + tajomstvo na mapu)
5. [x] **Mapy 9–12** (hotové 7. 11., značka `psie-mapy-9-12`: Policajná stanica – pletivo, hliadka dobermanov v dráhe (`patrol`), Inšpektor ovčiak (rady za radom); Veterinárna klinika – žeriav, Čivava sestrička (injekcie); Hrádza – príliv, vlna, Novofundlanďan (veľká vlna); Zasnežený kopec – sneh a ľad, lavína (`avalanche`), Vodca huskyov (fujavica); 8 malých bossov, korisť, 2 príbehy + tajomstvo na mapu; prvé vlny bez nepriateľov na diaľku)
6. [x] **Mapy 13–16** (hotové 7. 11., značka `psie-mapy-13-16`: Výcvikové ihrisko – ploty, psi bežia prekážkovú dráhu v pruhu (`agility`), Inštruktor boxer (prekážky – skrížené tyče); Výstava psov – reflektor prechádza pruhom (`spotlight`), Afgánska diva (mólo cez mačku); Kasárne – pochodujúci šík (`march`), Plukovník mastif (delostrelectvo); Generálova búda – hrad z búd, otvárajúce sa búdy, Generál (tri rozkazy); 8 malých bossov, korisť, 2 príbehy + tajomstvo na mapu; koniec príbehu: Cesta k mieru (Policajná stanica → Zasnežený kopec → Výcvikové ihrisko → Kasárne) a Mier – vrátiš Generálovi jeho obojok, porazíš ho a mačky so psami uzavrú mier, príznak `dog_peace`)
- Obtiažnosť a odomykanie (8. 11., podľa hráča „niečo medzi“): psie mapy rastú plynulo od úrovne Depa (sila nepriateľov ku koncu noci 24) po Generálovu búdu (35); finálni bossovia berú z výzvy mapy menej. Zamknuté za mapy: Chvost (Psí park), Papierové lietadlo (Psí salón), Lovec bossov (Stanica), Bodliakový kožuch (Cintorín), Driemot (Nákladná stanica), Smrtiaci skok (Smetisko); po výhre hlásenie „Nová schopnosť odomknutá“.
- Odložené testy na koniec (8. 11., hráč): kontrola zaseknutých nepriateľov na všetkých 31 mapách (`--stuck-check`, Obývačka 2 z 254) a kampaň oboch štvrtí po úprave obtiažnosti; spúšťať zrýchlene (`--bot-speed`, viac máp naraz).
7. [x] **Testy celej druhej štvrte**: scenáre máp, špecialít, bossov, príbehov; kampaň oboch štvrtí; kontrola textov a rozloženia vo všetkých jazykoch. Hotové 8. 11. 2026: kampaň všetkých 48 máp (bot vyhrá 46, Snežný kopec a Garáž strojov tesne nie), každý krok všetkých príbehov (`tools/chain_test.sh`), zasekávanie nepriateľov na každej mape (`tools/stuck_check.sh`), texty a rozloženie vo všetkých jazykoch bez chýb.

## Krátkodobý plán – časť 3 (zadané 7. 11. 2026, robí sa ako prvé)

Pracuje sa samostatne bod po bode, cez viac sessions (ďalšia pokračuje prvým neodškrtnutým bodom). Po každom kroku testy, commit, značka a push. Všetko nové sa kreslí v novom pixel-art štýle; texty vo všetkých jazykoch, nič sa nesmie posúvať ani orezávať (kontrola `strings_check`, `ui_test`, `text_fit_test`).

1. [x] **Dokončiť grafiku všetkých 11 máp** (hotové 7. 11., značky `grafika-teren-pasce`, `grafika-specialne`, `grafika-questy`; generátory `tools/gen_terrain.py`, `gen_traps.py`, `gen_specials.py`, `gen_looks.py`, náhľady `tools/trap_shot.gd`, `special_shot.gd`, `look_shot.gd`): terén (steny Strechy a Stanice, regály Supermarketu, príliv Prístavu, pásy Továrne, prekážky ostatných máp), pasce, špeciality máp a stavby z questov v pixel-arte; nové mapy už len v tomto štýle.
2. [x] **Dokončiť prvú štvrť: 15 máp** (hotové 7. 11., značky `mapy-12-15`, `questy-12-15`: Stoka – kanály s prúdom, vlna splaškov, Aligátor zo stoky; Lesík – hustý les, svetlušky, Veľká sova; Stavenisko – ploty, žeriav zhadzuje náklad, Bager; Depo – rady vagónov, posunované vagóny, prví psi, Seržant Buldog; Depo sa otvorí po Stoke, Lesíku aj Stavenisku; 25 nových nepriateľov a bossov s korisťou; na každej mape 2 príbehy + tajomstvo; pokračovania Druhý breh, Rodina sa rozrastá a Druhý signál – po dokončení pôvodných príbehov idú cez zvyšok štvrte a vedú k psom) (4 nové, mapy 12–15), každá s vlastnou podlahou, nábytkom, terénom/špecialitou, nepriateľmi, bossmi a finálnym bossom, pascami, hudbou, 3 príbehmi + tajomstvom a miestom na mape štvrte. Príbehy cez všetky mapy (reťazce, ktoré idú cez celú štvrť) rozšíriť aj na nové mapy. Posledná mapa štvrte uzavrie jej príbeh.
3. [x] **Pripraviť druhú štvrť – Psie štvrte** (hotové 7. 11., značka `psie-stvrte`: panel `DogDistrictPanel` s nakreslenou mapou mesta psov a 16 miestami – boss, kto sa pridá, popis, všetko zamknuté; tlačidlo „Vlak na východ“ na mape štvrte; celý návrh v `PSIE_STVRTE.md`) (zatiaľ bez hrateľných nocí): vlastná mapa štvrte s 15+ miestami (zamknuté, s názvami a popisom), cesta tam vlakom zo Stanice, návrh každého miesta (prostredie, špecialita, psí boss), noví nepriatelia (väčšina nových + pár starých, napr. krtkovia), pes ako hrateľná postava odomknutá porazením psieho bossa na 3.–5. mape. Návrh zapísať do `PSIE_STVRTE.md`.
4. [x] **Príbeh, ktorý vedie do druhej štvrte** (hotové 7. 11., `psie-stvrte`: Druhý signál → Rozkazy z východu → Lístok na východ – otvorí sa po výhre v Depe, rozbehne lokomotívu a odomkne vlak; príbehy môžu mať v `requires` aj `stage:ID`): prečo mačky idú k psom a čo tam budú robiť; začína v prvej štvrti (najneskôr na nových mapách), končí odchodom vlakom a pokračuje v druhej štvrti.
5. [x] **Zbrane a pasívky: cieľ 30 zbraní** (hotové 7. 11., značka `zbrane-30`: 12 nových zbraní s evolúciou – Labka, Udica, Krabica, Chvost, Sardinkový dážď, Pradenie, Ihla s niťou, Baterka, Vrchnáky, Mydlové bubliny, Papierové lietadielko, Stelivo – časť sa odomkne výhrou na Parku, Cintoríne, Ostrove, Stanici a nových mapách; 8 nových pasív – Učenlivosť, Blýskavý obojok, Bystré oči, Smrtiaci skok, Lovec bossov, Bodliakový kožuch, Teplé mlieko, Šlofík; spoločný uzol efektov `scripts/weapons/gizmo.gd`; vyvážené botom (`tools/weapons_test.sh`) do rozsahu starých zbraní) — pôvodne (dnes 16 základných, každá nová s evolúciou) **a 20 pasív** (dnes 12; počty sa môžu upraviť, ak sa ukáže iný ideál), vrátane spojení zbraní; vyvážiť botom (`tools/weapons_test.sh`) tak, aby žiadna nebola výrazne slabšia ani silnejšia.
6. [x] **Nové postavy** (hotové 7. 11., značka `macky-4`: Hrdzavka – Stoka, Mydlové bubliny, inštinkt Čas na kúpeľ; Machuľka – Lesík, Chvost, Zberačka; Tehlička – Stavenisko, Krabica, Ako múr; Uhlík – Depo, Vrchnáky, Plná para; každá sa zachráni z klietky na svojej mape a má domov a riadok v Denníku. Pes Ruby, mýval Lotor a mačky Tieň a Iskra sú navrhnuté v `PSIE_STVRTE.md`): ku každej novej mape prvej štvrte jedna nová mačka (4) s inštinktom; pre druhú štvrť pripraviť 1 psa, 1 mývala a 2 mačky (návrh, hrateľné až s druhou štvrťou; pes podľa bodu 3, mýval sa odomkne v druhej štvrti na Smetisku).
7. [x] **Testy celého**: nové scenáre pre mapy, bossov, zbrane, postavy a mapu druhej štvrte; kampaň celej štvrte (`tools/campaign.sh`); kontrola textov a rozloženia vo všetkých jazykoch a rozlíšeniach (nič sa neposúva ani neorezáva). Hotové 8. 11. 2026: kampaň všetkých 48 máp (bot vyhrá 46, Snežný kopec a Garáž strojov tesne nie), každý krok všetkých príbehov (`tools/chain_test.sh`), zasekávanie nepriateľov na každej mape (`tools/stuck_check.sh`), texty a rozloženie vo všetkých jazykoch bez chýb.

## Krátkodobý plán – časť 1 (zadané 31. 10. 2026, robí sa ako prvé)

Pracuje sa samostatne, bez otázok, krok po kroku (commit + značka + push po každom). Keď session skončí, ďalšia pokračuje prvým neodškrtnutým bodom. Potom sa ide ďalej podľa dlhodobého plánu (všetko pod touto sekciou); neskôr môžu prísť časti 2, 3…

1. [x] **Inštinkty mačiek** (hotové 31. 10., značka `instinkty`; schopnosť bez tlačidla, spustí sa sama, nie príliš silná; hodnoty v `Instinct.DATA` v `scripts/player/instinct.gd`, popis pri výbere mačky; testy `instinct_*`):
   Mica – každý 25. zabitý nepriateľ: 4 s rýchlejšie útoky (+15 %). Luna – každých 30 s na 5 s +10 % kritická šanca. Snehulka – každých 20 s chladný dych spomalí blízkych nepriateľov. Mrňa – 12 % šanca vyhnúť sa zásahu. Tiger – pod 35 % zdravia raz za 45 s rev (odhodí nepriateľov, 6 s +25 % sila). Barón – zabitá elita alebo boss: 8 s +20 % sila. Ďatelinka – 3 % šanca, že zabitý nepriateľ pustí mincu navyše. Bruno – každých 15 s štít na jeden zásah. Tučko – pod 40 % zdravia raz za 60 s desiata (+25 % zdravia). Kapitán – voda ho nespomalí, v daždi +10 % plocha. Šrubka – každých 6 s iskra do najbližšieho nepriateľa. Túlavá – po zabití bossa +1 losovanie. Anjel – raz za noc prežije smrteľný zásah, vstane s polovicou zdravia a 3 s nezraniteľnosti. Diabol – zabití nepriatelia s 8 % šancou vybuchnú, výbuch silnie s úrovňou.
2. [x] **Počasie a predpoveď** (hotové 31. 10., značka `pocasie`; `scripts/world/weather.gd`, `weather_screen.gd`, predpoveď v rohu mapy štvrte, `Profile.weather_today/tomorrow`, mokrí nepriatelia a Vodivosť blesku už teraz; testy `weather_*`) (jedno počasie pre celú štvrť na noc, ikona dnes + zajtra na mape štvrte; vnútorné mapy – Byt, Pivnica, Supermarket, Továreň – počasie nemajú; kreslenie lacné: jedna vrstva čiar/bodiek na obrazovke, žiadne tisíce uzlov):
   Jasno – nič. Dážď – nepriatelia sú mokrí (blesk na nich preskakuje), oheň slabší. Búrka – dážď + občas udrie blesk (červený kruh varuje, zraní nepriateľov aj mačku). Vietor – po vetre rýchlejšie, proti vetru pomalšie, lístie. Hmla – menší dohľad, +15 % skúseností. Mráz – pomalší nepriatelia aj mačka, mokrý nepriateľ zamrzne.
3. [x] **Spojenia zbraní** (hotové 31. 10., značka `spojenia`; `scripts/weapons/combos.gd`, účinky vo `Weapon.strike`, zoznam pod zbraňami v HUD, karta pri leveli ukáže nové spojenie; testy `combo_*`) (stavy: mokrý – Kropič, Vlna, Rozliate mlieko, dážď; prechladnutý – Mrazená rybka; ikonka aktívneho spojenia v HUD):
   Vodivosť (Anténa + mokrý: blesk preskočí, +30 %), Námraza (mokrý + Mrazená rybka: zamrzne), Krehký ľad (Pískacie kladivko na prechladnutého: +60 %, črepiny), Rezonancia (Kladivko + Zvonček: úder zazvoní), Naháňačka (Laser + Myška: myšky +40 % na označených laserom), Zamotanie (Klbko + Pavučina: klbko spomalí), Signál (Dronček + Anténa: iskry z dronov), Ťažký chlpáč (Chlpáč + Kropič: mokrý chlpáč silnejší), Šantové opojenie (Šanta + Pierko: +30 % v šantovom oblaku), Riedke mlieko (Mlieko + Kropič: väčšie kaluže).
4. [x] **Prekliatia** (hotové 31. 10., značka `prekliatia`; `data/challenges.json` má `gold`, `loot`, `materials`; Prekliata noc je teraz Horda; nové: Zúriví bossovia, Chudobné granuly, Bez magnetu – Tma už existuje ako tma na mape; test `curses_new`) (výzvy sa premenujú na prekliatia, dajú sa kombinovať; každé pridá násobok zlata, šancu na lepšiu korisť, viac surovín a rýchlejšie nabíjanie Zvončeka duší; nové: Tma, Rýchli bossovia, Menej granúl, Bez magnetu).
5. [x] **Suroviny** (hotové 31. 10., značka `material`; `Profile.materials`, `night_materials`, úrovne domčekov `Profile.buildings` – panel „Domček" pri mieste; výhra 100, útek 3/min (max 45), smrť 2/min (max 30), × prekliatia, +20 % za stupeň tmy; testy `materials_*`) (jedna mena „Stavebný materiál" – klbká a dosky, bez desiatich druhov; za výhru 100, za útek dvierkami a prehru málo podľa minút, výhra sa musí oplatiť; za prekliatia a tmu viac; míňa sa na úrovne domčekov na mape štvrte 1–3: viac zlata na mape, silnejší domáci bonus mačiek, silnejšia služba obyvateľa, úroveň 3 sa ubráni obliehaniu sama).
6. [x] **Deväť životov a hodnosť mačky** (hotové 31. 10., značka `devat-zivotov`; `Profile.careers`, `career_night`, panel `TalentPanel` (C), zbierky príveskov a artefaktov už len ukazujú, čo vlastníš; odkaz = +2 % sila, +3 % zlato za každú mačku na dôchodku, max 10; mačka s prvou kariérou dostane toľko hodností, koľko mala výhier (max 3); výbava sa kreslí na mačke celá – obojok, vesta, labky, chvost, čiapka; panel Výbava má mačku a ikonky; testy `career_*`, nástroj `tools/gear_shot.gd`) (zlúčenie príveskov a artefaktov): každá mačka zbiera hodnosť za noci (výhra viac); za každú hodnosť si vyberie 1 z 3 talentov (talenty = doterajšie prívesky a artefakty, ktoré vlastníš), najviac 9. Smrť zoberie 1 život a posledný talent. Výhra na domácej mape vráti život. 0 životov = mačka odíde do dôchodku, nechá trvalý odkaz pre všetky mačky a vráti sa ako mladá (2. generácia) bez talentov. Obchod za zlato ostáva. Inventár ostáva, lepšie kreslený; čiapka, obojok a ďalšia výbava sa ukážu na mačke v hre.
7. [x] **Zvonček duší** (hotové 31. 10., značka `zvoncek-dusi`; legendárny obojok `SOUL_BELL`, každý ho má vo výbave; porazený 1 duša, elita 10, boss 60, × prekliatia; plný pri 2500 = +30 % sila, +20 % zlato; v HUD pod zbraňami; testy `soul_*`) (predmet do inventára, slot obojok): počas noci pohlcuje silu zabitých (boss viac), dáva rastúci bonus; smrť = spadne na 0; výhra alebo útek dvierkami = náboj sa uloží a ďalšiu noc si ho môžeš (nemusíš) vziať. Prekliatia ho nabíjajú rýchlejšie.
8. [x] **Grafika – skúšobná mapa Byt** (hotové 31. 10., značka `grafika-byt`; `tools/gen_apartment.py` kreslí pixel-art parkiet, dlažby, koberca, 16 kusov nábytku v 5 farbách látky, koberčekov a pascí Pasca na myši a Sporák; `FloorChunk.art()`; všetci nepriatelia a rekvizity majú nové tieňovanie s objemom (`render_volume` v `tools/gen_sprites.py`); nástroje `tools/enemy_shot.gd` a `tools/gear_shot.gd` na kontrolu okom. Ďalej: drobnosti na zemi a bossovia vo väčšom rozlíšení, potom ostatné mapy podľa Bytu) celá v novom štýle (podlaha, nábytok, rekvizity, pasce, nepriatelia, bossovia, špeciality; sprity z `tools/gen_sprites.py`), potom podľa nej ďalšie mapy.

Doplnok (31. 10. 2026, značka `pomniky`): dôchodok už nedáva percentá. Každá mačka na dôchodku má na Cintoríne pomník (meno, generácia, labka vo farbe srsti, sviečka); keď pri ňom v noci chvíľu postojíš, raz ťa vylieči o 30 % zdravia. Na mape štvrte je pri Cintoríne kameň s počtom pomníkov, klik ho otvorí (`MemorialPanel`), tlačidlo je aj v paneli Cintorína. `Profile.retired`, test `memorials`.

## Krátkodobý plán – časť 2 (spätná väzba 1. 11. 2026, robí sa ako prvé)

1. [x] Charmy ostali na hlavnej obrazovke menu – odstrániť (hotové, značka `menu-bez-charmov`).
2. [x] Mapa štvrte je malá oproti výberu mačiek a infu o mape vpravo – zväčšiť (hotové, značka `vacsia-mapa`: užší pravý panel, nižší spodný pruh, menšie kartičky mačiek; riadok prekliatí a dennej noci je na ich tlačidlách – text a tooltip).
3. [x] Čas a počasie vľavo hore zaberajú veľa miesta a zakrývajú lokácie – presunúť nad mapu / mimo nej (hotové, značka `pocasie-hore`: mesiac, počasie a nemesis sú v hornom pruhu namiesto nadpisu).
4. [x] Panel výbavy: pri výbere predmetu s dlhším popisom obrazovka poskakuje – pevné rozmery (hotové, značka `vybava-pevna`: popis má pevnú výšku 4 riadky a zmenší písmo, sloty max. 2 riadky, zoznam 7 riadkov, aby sa panel zmestil aj na 720p; test v `ui_test.gd`).
5. [x] Tlačidlá Upgrades / Talents / Gear / Artifacts / Curses / Daily / Journal – je ich veľa, zlúčiť alebo presunúť (hotové, značka `tlacidla-stvrte`: hore len Vylepšenia, Denník, Späť; Talenty, Výbava, Artefakty pri mačke; Prekliatia a Denná noc nad Hrať; klávesy ostali).
6. [x] Byt v novej grafike: nie je vidno zmenu a hra akoby sekala – overiť, či sa nová grafika naozaj kreslí, a výkon (overené 1. 11., značka `byt-prednacitanie`: nová podlaha a nábytok sa kreslia; na PC john.niccon má Byt rovnaký výkon ako Pivnica (~2000 FPS bez vsync, bez záškubov po štarte). Obrázky Bytu sa načítavali až pri prvom zobrazení – teraz sa načítajú na začiatku noci. Ak to stále seká: poslať `perf.log` z toho PC.)
7. [x] Quest s 3 vlajkami: bez popisu, vlajky naraz na začiatku, obrana = celá noc – prerobiť (hotové, značka `dobytie-vlajky`: vlajky prídu po jednej v 3., 6. a 9. minúte, každá s hláškou a šípkou; v HUD je riadok dobytia (ďalšia vlajka o…, postoj pri vlajke, poraz strážcu); po tretej príde strážca vlajok – boss mapy; keď ho porazíš, mapa je dobytá hneď a ostane tvoja, nech noc skončí akokoľvek; testy `territory_flags`, `territory_won`).
8. [x] „Vzdať sa“ sa počíta ako smrť a berie život – život sa má stratiť len pri skutočnej smrti (hotové, značka `vzdat-bez-zivota`: odmeny ako pri smrti, ale život, hodnosť ani talent sa nestratí; test `career_give_up`).
9. [x] Ukázať starú vs novú grafiku Bytu (1. 11.: rozdiel je naozaj malý – rovnaké farby, len jemnejšia textúra parkiet a dlažby, vzor koberca a kvetináč; ak má byť viditeľný, treba výraznejší štýl).
10. [x] Vysvetliť brániť / dobyť / ako vyhrať (hotové, značka `ako-vyhrat`: v pravom paneli hneď pod obrázkom blok „Ako vyhrať túto noc" – výhra noci alebo podmienky prijatej úlohy a dobytie; tlačidlo Pomoc (H) s vysvetlením všetkých tabuliek na mape, dobytia a splnu).
11. [→] Byt prepracovať, aby nevyzeral prázdny a lacný (zadané 1. 11.; potom vonkajšie mapy s cestičkami). Krok 1 hotový (značka `byt-detaily`): drevené prahy s mosadznými skrutkami a tieň na hranici izieb, rohožky pri prechodoch, 10 druhov pixel-art drobností na zemi (ponožky, klbká, papuče, knihy, noviny, hračková myš, papierová guľa, granule, srsť), 3–6 na kus podlahy, škrabance na parketách, škvrny v kuchyni, vychodená cestička na koberci, mäkšie tiene nábytku, zostavy (gauč + stolík na koberci, posteľ + nočný stolík, stôl v kuchyni), pixel-art nábytok sa už neotáča. Ďalej: steny izieb s dverami (potrebujú kolíziu), lepšie svetlo, väčší a detailnejší nábytok.
    - Krok 2 hotový (značka `byt-steny`): steny izieb s dverami (terén `rooms` – omietka, natretá stena so soklom, tieň, drevené zárubne; kolízia pre mačku aj nepriateľov; pri štarte noci nič), prah a rohožka presne v dverách.
    - Pivnica v štýle Bytu (značka `grafika-pivnica`, `tools/gen_basement.py`): pixel-art betón s prasklinami a škvrnami od oleja, dlaždice práčovne s mlákami, staré dosky skladu s pilinami; kotol, potrubie, bicykel, police so zaváraninami, debny, zakrytý gauč, práčka, sušiak, kopa prádla, plechovky farby; drobnosti skrutka, pohár, handra; betónové steny izieb s dverami. Ďalej: Záhrada (cestičky), Strecha, Supermarket, Prístav, Továreň.
    - Všetky ostatné mapy v pixel-arte (značka `grafika-vsetky-mapy`, `tools/gen_outdoor.py`): podlahy všetkých zón (tráva, záhon, kamenná cestička, lepenka a škridly strechy, terasa, dlažby obchodu, piesok, nábrežie, mólo, betón a plechy továrne, cintorín, hala, nástupište, koľajnice, skaly), 60 kusov nábytku (stromy, kríky, lavičky, klimatizácie, regály, mrazničky, slnečníky, sudy, stroje, náhrobky, krypta, automat, palmy, fontána…), drobnosti na zemi (lístie, kamienky, mušle, hviezdice, bločky…) a veľké stromy a kríky terénu. Ďalej: steny a regály terénu (Strecha, Supermarket, Stanica) a príliv/pásy v novom štýle.
12. [x] Legenda ikon na mape štvrte (hotové, značka `legenda-mapy`: pás dole na mape – „klikni na značku“ a každá ikona s názvom: Obrana, Lov na bossa, Zlatá noc, Záchrana, Nočná túra, Spln, Vlajky bossa).
13. [x] Mačka pri pohybe vyzerá rozmazane – opravené (značka `plynuly-pohyb`): pohyb sa počítal 60× za sekundu, ale kreslil sa na 144 Hz monitore a kamera sa vyhladzovala medzi tým, takže mačka, nepriatelia aj strely išli po skokoch. Zapnutá interpolácia fyziky (`physics/common/physics_interpolation`), kamera ide vo fyzikálnych ťikoch, drony tiež; pri skoku nepriateľa na druhú stranu sa interpolácia resetuje. Overiť okom v hre.
    - Doplnok (značka `byt-nabytok-svetlo`): podlaha sa pri interpolácii kreslila s dierami – opravené; detailnejší nábytok a teplé svetlo stropných lámp.
14. [x] HUD vpravo hore: cieľ prijatej úlohy (hotové, značka `hud-uloha`: riadok pod questom – obrana/záchrana „vydrž do 10:00“, po splnení zelené „✓ – môžeš odísť dvierkami“ s hláškou; lov, túra, zlatá noc, spln; dobytie má vlastný riadok; test `mission_rescue`). Legenda mapy má aj červený „?“ = unesený obyvateľ.
15. [x] Záverečná obrazovka po krokoch (hotové, značka `koniec-noci`: strana 1 „Nastalo ráno!“ + štatistika, strana 2 „Čo si dnes v noci dokázal“ – questy, úloha, dobytie, odomknuté mapy a zbrane, ciele, hodnosť, správy zo štvrte, strana 3 „Čo si si odniesol domov“ – zlato, výbava, materiál, súčet; Enter/Esc listuje, na konci späť do štvrte, R hrá znova; bannery sa už nekreslia cez obrazovku).
16. [x] Zvonček duší (hotové, značka `zvoncek-z-bossa`): nové hry ho nemajú, padne z bossa so 4 % (finálny boss 10 %, × šťastie), domov ho odnesieš výhrou alebo dvierkami; náboj sa stratí len pri skutočnej smrti, nie pri vzdaní. Kto ho už má, ten si ho nechá. Navyše: nepriatelia aj bot sa pri stene izby kĺžu k dverám (inak sa zasekli oproti mačke); testy `soul_drop`, `soul_give_up`.
17. [x] Pomoc (H): skutočné ikony z mapy v odrážkach (hotové, značka `znacky-mapy`).
18. [x] Legenda na mape schovaná za „?“ – rozbalí sa po kliknutí (hotové, `znacky-mapy`).
19. [x] V pravom paneli pri úlohe miesta rovnaká ikona ako na mape – pri názve na obrázku aj pri „Ako vyhrať“ (hotové, `znacky-mapy`; všetky značky kreslí jedna funkcia `DistrictMap.draw_sign`).
20. [x] Minimapu vpravo hore odstrániť, tlačidlo Cesty zmenšiť (hotové, značka `bez-minimapy`: minimapa skrytá, Cesty malé v pravom hornom rohu).
21. [x] Popis mačky dole: väčšie meno a popis, menšie bonusy, nič sa neorezáva (hotové, značka `popis-macky`: zbraň je malá ikonka pri mene s tooltipom, text „bez zbrane“ už nezaberá miesto štítkom).

Do dlhodobého plánu (nerobiť teraz): **Krotenie** – v tejto podobe sa nepáči, vymyslieť inak (bez ďalšej postavy na obrazovke).

## Spätná väzba 28. 10. 2026 (hotové)

- [x] Krvavá stopa: nevracia sa sama cez seba, koniec pulzuje z diaľky, tajomstvo začne hneď (nedokončená vedľajšia úloha ustúpi)
- [x] Prekliata svätyňa: strážcovia silnejú s časom, dávajú málo skúseností, truhlica bossa až od 8. minúty
- [x] Mrazená rybka → Večná zima: lúč na najsilnejšieho (bossov najprv), zmrazí ho, aj Smrť; 3 vetvy
- [x] Charmy: šanca klesá s každým nájdeným, vyzerajú ako amulety so žiarou podľa vzácnosti; srdce, sardinka a magnet so žiarou
- [x] Bossovia, súperi v súbojoch a bossovia z príbehov rastú s levelom mačky oveľa viac (level 100 ≠ level 20)
- [x] Questy: ten istý príbeh nepríde dvakrát po sebe, vedľajšie úlohy sa striedajú, ignorovaná úloha zmizne do 2 min, opustená (ďaleko 12 s) zlyhá
- [x] Vzdať sa v pauze sa pýta ešte raz
- [x] Vyhodiť zbraň/schopnosť v pauze (1× za noc, +2 v obchode „Upratovanie“)
- [x] Vyvinuté zbrane majú 4 ďalšie levely; karta pasívky povie, že zbraň sa už vyvinula
- [x] Magnet ťahá z celej mapy rýchlo a povie, koľko granúl letí
- [x] Rýchlosť: pasívka +6 % za level, nad +40 % sa ráta len polovica
- [x] Najviac 80 striel nepriateľov naraz, privolané skupiny bossov s odstupom 10 s
- [x] Dev (F1): oživenie po smrti (prepínač), +5 min bez levelov, skok na 10./15./20. minútu „ako odohrané“
- [x] Vysávač z Kibble Thief uteká, treba ho chytiť 2×, rastie s levelom
- [x] Príbehy: „časť 2/4“ v názve, po kroku „Ďalej v tomto príbehu: …“, dokončený príbeh s fanfárou
- [x] Svätyne kostí, mesiaca a chaosu (bonusy aj kliatby na celú noc), svätyne častejšie
- [x] Nový obsah: zbraň Pískacie kladivko → Zemetrasné kladivo (úder s omráčením, 3 vetvy), príbehy Zhasnutý maják (Prístav) a Prehriatie (Továreň)
- [x] Anjel: väčší, krídla, lúče, perie, nápis ANJEL!; Smrť: zastaví svet, roztrhne zem, blesky, vstane obrovská s kosou, vlna zabije všetkých nepriateľov, 5 min sa nedá zraniť (odpočet v HUD), potom áno

## Fáza 1 – Doladenie podľa hrania

Najprv dotiahnuť to, čo už máme, kým pridáme ďalší obsah.

- [→] Obtiažnosť: doladiť rast poškodenia a HP nepriateľov podľa tvojich hier (každá mapa zvlášť)
- [x] Okno „Čo je nové“ po aktualizácii, Denná noc (T), príbehy v Denníku podľa máp, príbehy mapy v pauze, tlačidlo „Story step now“ v dev paneli (F1), výber mačky pre 13+ mačiek, artefakty v 3 stĺpcoch
- [x] Testy: `QUICK=1` (30 scenárov, ~1 min) medzi krokmi, celá sada (~9 min) na konci
- [x] Začiatok neskorších máp ľahší: nepriatelia na mapách 2–7 majú na začiatku noci o 30 % menej zdravia a slabšie útoky, do 6. minúty sa to vyrovná
- [→] Ceny vylepšení v obchode a sila charmov – nie je niečo príliš silné alebo zbytočné?
- [x] Výkon: 114–144 FPS v 17. minúte na Streche, stabilných 144 v nekonečnej noci so šampiónmi (RTX 4070 Ti, 144 Hz) – netreba optimalizovať
- [x] Príbehové questy pre každú mapu: obojok (Byt) → stará mapa (Pivnica) → kľúč pod stromom (Záhrada) → Brunov odkaz (Strecha); quest Cesta nahor
- [x] Hudba: dlhšie skladby máp (2–2,7 min), nočná skladba od polovice noci, vlastná hudba pre každého finálneho bossa a diabla
- [→] Hudba: tvoja spätná väzba na skladby (ja ich nepočujem)
- [x] Texty: neutrálne oslovenie namiesto „Prežila si / Porazil si…“, meno mačky na víťaznej obrazovke, automatická kontrola prekladov

## Fáza 2 – Nový obsah

- [x] Kniha questov (štýl Halls of Torment): 17 línií, 57 krokov – mačací život, miesta, tajomstvá (Q vo výbere mačky, tlačidlo v menu)
- [x] Tajomstvá: anjel mačka sa odomkne 4 stránkami denníka (jedna ukrytá na každej mape), diabol mačka questom Diablova zmluva
- [x] Denník: questy, ciele a bestiár na jednom mieste (tlačidlo Denník, pri výbere mačky Q / G / J)
- [x] Nové zbrane: Myška na kľúčik, Pavučina, Kropič, Anténa (každú odomkne prejdenie mapy) + evolúcie, pasívy Dlhý spánok a Rýchly hod
- [x] Nové správanie: prachový mrak sa rozpadá, pľujúci pavúk a žaba strieľajú, útočná čajka sa vrhá; bossovia privolávajú pomocníkov
- [x] Vetvy zbraní (ako Halls of Torment): 3 vetvy pre každú z 13 zbraní, od levelu 3 vyber jednu, od levelu 6 / po evolúcii 2. stupeň; oheň, mráz, iskra, výbuch, popravenie, cicanie zdravia, zosilnenia
- [x] Strední bossovia (12.–13. minúta): Žehlička (horúca para), Kotol (špirála striel), Strašiak (vidly + vrany), Búrkový mrak (blesky); útoky sa vopred ukážu
- [x] Viac charmov a cieľov: 5 nových charmov (štvorlístok, pavúčie vlákno, pierko vetra, polmesiac, zlatý tesák), 6 nových cieľov; zoznam cieľov sa dá posúvať
- [x] Bestiár: mačky, nepriatelia podľa máp (počet porazených, popis), zbrane s evolúciami, pasívky; neobjavené ako ???
- [x] Šampióni: 6 druhov (rýchly, obrnený, obor, delič, regenerujúci, bombér) od 2. minúty, v bestiári aj v questoch
- [x] Zlatá myš: občas pribehne, uteká, po chytení vysype zlato a truhlicu
- [x] Nekonečná noc: po výhre klávesou E pokračuješ, nepriatelia silnejú každou minútou, boss každé 2,5 min, zlato navyše je celé tvoje; quest Nekonečná noc
- [x] Výzvy (X pri výbere mačky): Turbo, Krehká mačka, Bez liečenia, Jediná zbraň, Prekliata noc – každá násobí zlato; quest Odvážlivec
- [x] Mapa 5 – Supermarket (po Streche): uličky, zelenina, mrazáky; plechovky, banány, vozíky, mrazené kurčatá, rozprašovače; bossovia strážny robot, vysokozdvižný vozík, banánový trs, pokladňa (stredný), finálny pes Rex; pasce mrazák a rozbitá žiarivka; mačka Tučko (záchrana z vozíka); príbeh lístok v koši; hudba deň/noc/Rex
- [x] Mapa 6 – Prístav (po Supermarkete): pláž, nábrežie, mólo; kraby, medúzy, úhory, pirátske potkany; bossovia obrovský krab, chobotnica, stará kotva (stredný), finálny Kraken; pasce háčik a prílivová mláka; mačka Kapitán (súboj, kapitánska čiapka); príbeh odkaz vo fľaši; hudba deň/noc/Kraken
- [x] Výber mačky v dvoch riadkoch (12 mačiek), 4 nové ciele, 2 nové kroky questu Cesta nahor, 14 nových testov (`ONLY="harbor|final_kraken" bash tools/run_checks.sh` spustí len vybrané)
- [x] Questy pre každú mačku (kapitola Mačky v knihe questov): vyhraj s ňou, level 40, 25 bossov, 5 výhier
- [x] Artefakty (V pri výbere mačky): 10 trvalých predmetov z knihy questov, 2 sa berú do noci – sklenené oko, presýpacie hodiny (zmrazí čas), magnetické jadro, šťastná minca, vrecúško šantu (liečenie pri leveli), zub bossa, anjelské pierko, tŕňový obojok, krvavý mesiac (riziko za odmenu), hodinový strojček; už splnené kroky ich vydajú dodatočne

## Fáza 2b – Skutočné questy (reťazce)

Dlhé questy s krokmi cez viac nocí, postup sa ukladá. Hrajú sa počas noci
popri vlnách (nepriatelia chodia stále, zbrane strieľajú samé), takže kroky
sú o pohybe po mape: stopy, naháňačka, nosenie vecí, obrana miesta,
zbieranie, státie v zónach, bossovia, voľby. Prekrádanie vynechané.

Mechaniky:
- [x] Systém reťazcov (`data/chains.json`): kroky, ukladanie postupu, plánovanie počas noci, zobrazenie v Denníku
- [x] Kroky – hotové: eskorta (viac mačiek, pomalá), zabitia pascami, tma, šíriaci sa oheň, opakovaná naháňačka, voľba s cenou, krok podmienený mačkou, porazenie finálneho bossa; stopy, naháňačka, nosenie (čas, spomalenie, max. zásahov), zbieranie (kapacita, strážcovia, z nepriateľov), zóny (poradie, čas, blesky), obrana (viac miest), boss (bez liečenia, na čas); voľba (pozastaví hru, vetvenie krokov), pasce na trase, odmena za krok; chýba: eskorta, zabitia pascami, tma. Pôvodne: stopy, naháňačka, nosenie (časový limit, spomalenie, max. zásahov), zbieranie (kapacita, veci zo strážcov alebo z nepriateľov), zóny (poradie, časový limit, blesky), obrana (miesto s HP, viac miest naraz), boss (bez liečenia, na čas), eskorta (viac mačiek, pomalá), voľba, zabitia pascami, tma s lampášom
- [x] Postavy, ktoré hovoria (riadky pri začiatku a konci kroku, otázky pri voľbách)
- [x] Trvalé zmeny máp: teplý kotol (liečenie), strašiak (odháňa vrany), nabitá anténa (strieľa), maják (odháňa medúzy), Bruno a Rex ako spojenci

Byt:
- [x] Zlodej granúl (odmena artefakt Plná miska): 5 stôp → dobehni Roombu → kľúčik do kuchyne do 60 s → ubráň špajzu
- [x] Ponožkový kráľ: 6 ponožiek do koša (nesieš max. 2) → Ponožkový kráľ
- [x] Mesačné okná (anjel potom chodí 2× častejšie): vydrž v 3 mesačných lúčoch → prvá stopa anjela

Pivnica:
- [x] Potkania pevnosť: upchaj 3 diery → chyť posla → tunel s pascami → potkaní generál
- [x] Pavúčia sieť (Hodvábna vesta alebo boj): vysloboď 4 mole → voľba: poraziť kráľovnú alebo jej dať mole
- [x] Oprava kotla: 3 súčiastky od elít → zanes ku kotlu → kotol odteraz lieči

Záhrada:
- [x] Trpasličia vojna: ubráň záhon → tunel krtkov → voľba krtkovia/trpaslíci
- [x] Med pre Ďatelinku (max. 10 zásahov): 3 kvety k úľu (max. 3 zásahy) → sršňa kráľovná
- [x] Strašiak ožíva: klobúk, šál, tekvica z vrán → postav strašiaka → odháňa vrany

Strecha:
- [x] Brunova skúška: 5 komínov za 60 s → holubí cisár bez liečenia → súboj na úsvite → Bruno spojenec
- [x] Búrková anténa: nabi 3 antény počas bleskov → anténa strieľa
- [x] Ukradnutý obojok: prenasleduj mývala → prehľadaj 4 kontajnery

Supermarket:
- [x] Tučkov nákupný zoznam: 5 vecí k pokladni pred zatvorením
- [x] Výpadok prúdu: tma → 3 ističe v správnom poradí, strážny robot bráni
- [x] Rexov rešpekt: 3 noci kosť Rexovi + ochrana pred vozíkmi → Rex sa po boji pridá

Prístav:
- [x] Kapitánova loď: plachta, kormidlo, lano → oprava → ubráň loď 90 s
- [x] Maják: olej z 3 sudov (pomalšie s nákladom) → maják odháňa medúzy
- [x] Pirátsky poklad: 3 kúsky mapy od pirátov → vykopať → chobotnica

Cez všetky mapy:
- [x] Cesta domov: Mica hľadá starú majiteľku; každá mapa kapitola, predmet otvorí ďalšiu, koniec loďou domov
- [x] Mačacia rodina: každá zachránená mačka má prosbu na inej mape → hostina, bonus pre všetky mačky
- [x] Kto za tým stojí?: súčiastka s logom z každého finálneho bossa → Robo-vysávač 3000 (tajná 7. mapa neskôr)

Samostatné questy:
- [x] Nočný kuriér (list cez mapu za 90 s, max. 3 zásahy)
- [x] Stratené mačiatka (3 mačiatka k mame)
- [x] Majster pascí (30 zabití pascami)
- [x] Požiar (zhas šíriace sa ohniská, kým sa nerozšíria)
- [x] Zlatá horúčka (chyť zlatú myš 3×, zakaždým rýchlejšiu)
- [x] Tri misky (ubráň 3 misky naraz)
- [x] Lampáš (v tme dones lampáš k východu)
- [x] Súboj na čas (poraz súpera do časového limitu)
- [x] Túlavý obchodník (zlato alebo 3 rybičky – voľba)
- [x] Posledná prechádzka (stará mačka na obľúbené miesto)

Potom: šablónové questy mačiek a počítadlá presunúť do časti Úspechy.

## Spätná väzba 18. 10. 2026

- [x] Únik dvierkami: čakanie 5 s → 3 s
- [x] Státie na mieste kratšie (miska 40 → 25 s, obrana 45 → 30 s, zóny kratšie); silní bossovia z príbehov až neskôr v noci (`after_minute`)
- [x] Menu: šípky aj W/S, pohyb sa zacyklí; výber mačky s veľkým detailom (zbraň, výhry, level, bossovia) a karty máp s obrázkom a finálnym bossom
- [x] Efekty zbraní: zásahový záblesk vo farbe zbrane, stopy za strelami, väčšie škrabance so švihom (oranžové po evolúcii), žiarivý laser s iskrami, plnšia vlna zvončeka
- [x] Achievementy: 40 úspechov (záložka Úspechy v Denníku, oznámenie v hre, tajné ako ???)
- [x] 3 nové zbrane za nové mapy: Konzerva (Supermarket, výbuch kde dopadne → Kazetová konzerva), Vlna (Prístav, odhodí nepriateľov → Cunami), Dronček (Továreň, drony s lasermi → Roj dronov); každá 3 vetvy
- [x] Mapa 7 – Továreň (po Prístave): sklad, montáž, pásová linka; šrúbikové chrobáky, pružinové roboty, drony, zvárači, mini-vysávače, drviče; bossovia montážna ruka, kováčsky golem, hydraulický lis (stredný), kráľovná dronov, finálny Robo-vysávač 3000; pasce elektrická podlaha a lis; mačka Šrubka (z klietky); príbeh plán stroja; 3 príbehy (zaseknutá linka, núdzové zastavenie v tme, zblúdilé drony); hudba deň/noc/boss
- Ďalšie jazyky zatiaľ nie. Menej testov medzi krokmi, poriadny test na konci.

## Spätná väzba 19. 10. 2026

- [x] Viditeľnosť: tmavšia podlaha, svetlá žiara a tmavší tieň pod nepriateľmi, väčšie strely nepriateľov s obrysom, slabšia aura šanty, menšie a priesvitnejšie čísla poškodenia
- [x] Nepriatelia, ktorí sa objavia na obrazovke (stráže, prepadnutia, kruhy, pomocníci bossov), najprv 0,6 s len ako tieň – nehýbu sa a nezrania
- [x] Rýchlosť: mačka 115 namiesto 100; bežní nepriatelia nikdy rýchlejší ako 85 % mačky (rýchlejší sú len útočníci, strmhlavci a utekajúci); počas noci zrýchlia najviac o 15 %
- [x] Obtiažnosť: poškodenie nepriateľov rastie pomalšie (×2,8 v 20. min namiesto ×3,4), menej HP za level mačky
- [x] Vylepšenia: vlastné zbrane 2,5× častejšie v ponuke, vlastné pasívy 1,5×, v každej ponuke aspoň jedno vylepšenie vlastnej zbrane
- [x] Spoločníci rastú: +1 level zbrane každé 2 tvoje levely, od 12. levelu druhá zbraň od teba, od 25. evolúcia
- [x] Sloty: 6 zbraní a 6 pasív ako vo Vampire Survivors; v obchode nové vylepšenie Slot na zbraň (+1, max 2)
- [x] Výber mačky a panely na myš: rad tlačidiel so skratkami, klikateľné riadky, tlačidlo Späť
- [x] Nastavenia: Vysoký kontrast (ešte tmavšia podlaha, silnejšia žiara nepriateľov)
- [x] `hrat.bat` v repozitári: spustenie na akomkoľvek PC (nájde Godot, pri prvom štarte importuje)
- [x] Navyše: finálni bossovia -25 % HP a -20 % poškodenie, červené šípky na okraji ukazujú bossov mimo obrazovky, pri zdraví pod 30 % pulzuje okraj obrazovky načerveno, okno „Čo je nové“ s dnešnými zmenami
- [x] Nekonečná noc vysvetlená: cieľ je vydržať čo najdlhšie, rekord, oznámenie každej minúty so zlatom

## Spätná väzba 19. 10. 2026 (večer)

- [x] Stiahnutá verzia z druhého PC (questy so stavbou, zlatá šípka, šetrič efektov)
- [x] Nová mačka Túlavec: bez zbrane, +1 slot, rýchlejší, väčší magnet a rast; na začiatku 6 priateľských pascí, prvé levely sú len zbrane
- [x] Truhlice: každá dáva 1 vylepšenie; truhlica po bossovi = výber 1 z 3, 5 % šanca (× šťastie) na všetky tri
- [x] Výzva: každá mapa má faktor obtiažnosti (Obývačka 1,0 … Továreň 2,2), ktorý od 6. do 20. minúty násobí HP nepriateľov a (odmocninou) ich poškodenie aj finálneho bossa
- [x] Hudba: každá mapa má druhú dennú skladbu v inom štýle (valčík, synthwave, reggae, swing, lounge jazz, námornícky valčík, industriálny synth) – `tools/gen_music_alt.py`; každý beh náhodne jednu z dvoch (`--music=alt/main`)
- [x] Výkon: tiene a žiary všetkých nepriateľov kreslí jeden uzol (menej práce na nepriateľa)
- [x] Výkon na notebooku: draw cally výrazne znížené (pozri Výkon a svätyne 22. 10.)

## Nápady z Death Must Die (20. 10. 2026)

- [x] Vzácnosť kariet pri leveli: Vzácna / Epická / Legendárna = +1 / +2 / +3 úrovne naraz (12 % / 4 % / 1,2 % × šťastie), farebný žiariaci rám
- [x] Vyhodenie karty (banish): 2 za noc, Shift + číslo alebo tlačidlo pod kartou; vec sa v tej noci už neponúkne
- [x] Mačacie svätyne: od 70 s, potom každé 1,5–2,5 min; postoj pri nej 2 s. Sila (+30 % poškodenia na 45 s), Vietor (rýchlosť a útoky), Mlieko (liečenie), Šťastie (zlato + všetky granulky), Prekliata (5 strážcov → truhlica). Šípka na okraji obrazovky
- [x] Temnota 1–5 na každej vyhratej mape: na úroveň +18 % HP, +10 % poškodenia, +6 % nepriateľov, +25 % zlata; výhra odomkne ďalšiu úroveň (- / + pri výbere mapy)
- [x] 4 nové úspechy: Pútnik, Do temnoty, Priepasť, Legendárne
- [x] Menu: hviezdy a padajúce hviezdy, žiariaci nadpis, mačky prechádzajú po streche, tip na spodku
- [x] Výber mačky: pozadie s mestom, bonusy mačky ako farebné štítky, zvýraznenie pod myšou, hviezdičky obtiažnosti a dĺžka noci, výraznejšie tlačidlo Hrať
- [x] Kvalita talizmanov ★☆☆☆ až ★★★★ (každá hviezda +35 % účinku); lepší kúsok toho istého talizmanu vylepší tvoj namiesto zlata; šťastie zvyšuje šancu na lepšiu kvalitu
- [→] Predmety s náhodnými vlastnosťami (výbava ako v Death Must Die) – veľký systém, zatiaľ nie

## Výkon a svätyne (22. 10. 2026)

- [x] Výkon (ako Vampire Survivors / Halls of Torment – všetko v dávkach): podlaha každého chunku (zem, nábytok, svetlo) sa nakreslí raz do textúry; sprity všetkých nepriateľov a mačiek v jednom atlase; tiene, zásahy, strely, granulky, mince, pasce a efekty zbraní cez spoločnú textúru (`Blit`); čísla poškodenia najprv všetky obrysy, potom výplne; granulky bez `_process`; svetlo mačky len v noci; skripty krokov questov sa načítajú na začiatku noci
- [x] Výsledok (RTX 4070 Ti, 17. minúta Strechy, všetkých 16 zbraní): ~60 → ~360 FPS, draw cally ~3300 → ~380; bežná hra v 17. minúte ~380–460 FPS
- [x] Bez zásekov: viewporty podlahy sa recyklujú (nový chunk 0,1 ms namiesto 2–8 ms), atlas spritov a skripty questov sa pripravia pri načítaní; `perf.log` zapisuje aj najdlhšiu snímku (`worst=`) za každých 10 s
- [x] Nové testovacie prepínače: `--seed=N`, `--no-vsync`, `--shot=SEKUNDY` (screenshoty), `--show-choice`
- [x] Svätyne ako v Death Must Die: po prebudení výber z 2–3 darov – prvý vždy bezpečný, ostatné silnejšie s cenou (krvavá prísaha, búrka, smotana, sladké ovocie = 2 levely za 40 % zdravia, chamtivosť, veľká kliatba so šampiónmi a truhlicou bossa); trvalé bonusy do konca noci; voľby aj myšou
- [→] Zahrať a povedať, či sú dary svätýň vyvážené
- [→] Výkon na notebooku: zahrať jednu noc a poslať `perf.log` (`%APPDATA%\Godot\app_userdata\Cat Survivors\perf.log`)


## Spätná väzba z hrania (22. 10. 2026)

- [x] Posledná prechádzka ťažšia: cieľ 1100–1400 px namiesto 600–800, Fúzač pomalší (0,45) a krehkejší (40 HP)
- [x] Bannery ostávajú dlhšie podľa dĺžky textu a zalamujú sa; pauza má vľavo „Tvoje zbrane“ (level, popis, vetva, pasívky) a vpravo „Úloha a správy“ (aktuálna úloha + posledných 15 správ)
- [x] Pravý stĺpec HUD (úloha, zlato, požehnania) sa skladá pod seba – dlhý text úlohy už neprekryje požehnanie svätyne
- [x] Ponuka vetvy zbrane menuje vetvy, ktoré sa zavrú
- [x] Robomyška: väčší výbuch (52 px × plocha), oranžový kruh; výbuchy už nekreslia zvonček (len zbraň Zvonček)

## Tajomstvá a ľahšie Strechy (22. 10. 2026)

- [x] Túlavec dostane prvú zbraň až na 5. leveli (predtým 3.) a dovtedy má len 1 život; na 5. leveli plné zdravie ako ostatné mačky (`fragile_until` v cats.json)
- [x] Magnet ťahá z celej mapy aj mince (granuly už ťahal)
- [x] Health bar mačky vo vlastnej vrstve nad nepriateľmi a efektmi, širší s bielym okrajom
- [x] Strechy: nepriatelia dávajú 0,85× damage (`damage_mult` v stages.json); obchod Max zdravie 5 stupňov namiesto 3
- [x] Tajné reťazce (`"secret"` v chains.json, mimo plánovača, v denníku „???“ kým sa nenájdu):
  - Koniec záhrady (Záhrada): odíď 7000 px od štartu hocikam → stopy + Kráľ trpaslíkov
  - Tieňový pes (Pivnica): čím ďalej, tým tmavšie (od 1500 px), pri 9000 px boss pes v tme
  - Červená stopa (Prístav): dlhá krvavá stopa krížom-krážom (12 úsekov, ~5 500 px) → ochráň kocúra + boss Chobotnica
- [→] Overiť v hre: vzdialenosti (7000 / 9000 px), sila bossov, či Túlavec do 5. levelu nie je priťažký

## Ľahší Supermarket, sólo bossovia, odmietnutie svätyne (23. 10. 2026)

- [x] Boss z reťazca „bez liečenia“ (Holubí cisár): ostatné mobky zmiznú a nespawnujú sa, kým súboj neskončí (`"solo": true` v chains.json to zapne aj inému bossovi)
- [x] Bossovia z vĺn chodia po jednom: ďalší počká, kým predošlý nepadne (+6–12 s pauza)
- [x] Supermarket: `damage_mult` 0,9, `challenge` 1,6 (bolo 1,7), zdravie vĺn od 7. minúty ~10 % nižšie (na konci 7,6 namiesto 8,5)
- [x] Svätyňa: posledná voľba „Nežiadaj nič a odíď“ (panel volieb až 4 karty)
- [→] Overiť v hre: či je Supermarket teraz zvládnuteľný; bot v teste Holubieho cisára zbiera srdcia, takže úlohu nesplní (aj pred zmenou)

## Obchodník, truhlice, Bruno, bossovia, strelci (23. 10. 2026)

- [x] Voľby v questoch (Túlavý obchodník) ukazujú aj popis artefaktu, ktorý dostaneš
- [x] Zlatá šípka na okraji obrazovky ku každej truhlici mimo obrazovky
- [x] Silní bossovia (základné HP ≥ 2500) hodia veľkú fialovú truhlicu: vždy všetky 3 vylepšenia + 60 zlata
- [x] Brunova skúška: 3. krok je súboj s Brunom o 20. minúte (žiadny extra Bruno o 14. minúte); Bruno má +~20 % HP (58 000)
- [x] Bruno ako spojenec len pre mačku, ktorá ho porazila, a len na želanie: na začiatku noci otázka; s ním majú nepriatelia +25 % života (staré uloženia: ponuka pre každú mačku)
- [x] Bossovia majú vlastné špeciálne útoky (`specials` v enemies.json): skok, štekot (vejár), sériové výpady, dážď úderov, horiace mláky, stena striel s medzerou, vlny, sanie; pod 30 % HP sa nahnevajú (rýchlejší, častejšie útočia)
- [x] Strážny pes: rýchlosť 80 (bolo 52), útoky skok + štekot + výpady
- [x] Bežní strelci majú spoločný limit: ~1,6 strely/s a najviac 10 ich striel naraz
- [x] Oprava chyby pri uvoľnenom bossovi vo vlnách (filter v spawner.gd)
- [→] Overiť v hre: či sú špeciálne útoky férové/čitateľné a či veľká truhlica nie je príliš silná

## Spätná väzba testerov (25. 10. 2026)

- [x] Truhlica/odmena ukazuje aj čo nový level robí (napr. „Rybie kosti → 3“ + štatistiky)
- [x] Mačacie dvierka sa pred odchodom opýtajú (Áno/Zostať); po „Zostať“ treba vystúpiť a vojsť znova
- [x] Level-up, výber z bossovej truhly aj okno truhly ukazujú „Tvoje zbrane“ (level, popis, vetva, s akou pasívkou sa vyvinie a či ju máš); čoho sa ponuka týka, je označené » a hore
- [x] Popis v obchode s vylepšeniami má miesto na 3 riadky (Prekliatie už neposúva obrazovku)
- [x] Horiace mláky bossa 1 s blikajú ako varovanie, až potom pália (platí pre všetku paru)
- [x] Výpady (boss aj dash nepriatelia): nabitie 0,7 s s blikaním a smer zamknutý na začiatku nabitia; sériové výpady tiež blikajú a zamierajú len na začiatku
- [x] Škrabanec: ďalšie rady striedavo nad aj pod mačkou
- [x] Túlavec dostane zbrane a plné zdravie už na 3. leveli
- [x] Tma v queste na každej mape: pribudla na Obývačke (Mesačné okná), Záhrade (Strašiak), Streche (Búrková anténa), Prístave (Maják); Pivnica, Supermarket a Továreň ju už mali
- [x] Tajný quest „ďaleko od štartu“ / krvavá stopa je na každej mape (pribudli Pod nekonečným gaučom, Posledná strecha, Zadná časť obchodu, Opustená linka + 4 epické charmy)

## Mapy s prekážkami, dev testy (25. 10. 2026, večer)

- [x] Oprava: svätyňa a level-up naraz otvorili obe okná a po výbere svätyne sa hra rozbehla s otvoreným level-upom – teraz idú okná po sebe a čas stojí, kým nie sú zatvorené obe
- [x] Terén na mapách (`scripts/world/terrain.gd`, kľúč `"terrain"` v `data/stages.json`): nikto neprejde, strely letia ponad
  - [x] **Záhrada (3. mapa) – stromy a kríky** rozhádzané po celej nekonečnej mape
  - [x] **Strecha (4.) – múriky s priechodmi** (ako steny vo Vampire Survivors, v každom múriku je medzera)
  - [x] **Supermarket (5.) – úzka ulička**: hore a dole regále, ísť sa dá len doľava a doprava; nepriatelia prichádzajú z bokov
  - [x] **Prístav (6.) – dynamický príliv**: každých ~70 s varovanie, voda príde zhora aj zdola a stlačí všetkých na pás súše okolo mačky, po ~18 s odíde
  - [x] **Továreň (7.) – pohyblivé pásy**: pásy cez halu posúvajú mačku (a nepriateľov polovičnou rýchlosťou) do strán, susedné idú opačne a každých 25 s zmenia smer
  - [x] Karta mapy ukazuje, že mapa má prekážky; questy, svätyne, dvierka, pasce aj odmeny sa vždy položia na voľné miesto
- [→] Zahrať všetky tri a povedať, či je ulička príliš úzka a príliv príliš častý (konštanty hore v `terrain.gd`)
- [→] Ďalšie varianty: miestnosti v Pivnici (bludisko), lisy v Továrni, padajúce regále, mosty cez vodu
- [x] Dev panel (F1): **Silný build**, **Test bossa** (zoznam všetkých 40 bossov), **Boss rush** (všetci za sebou, 2 s pauza, liečenie), **Test questu** (všetky questy aj každý krok každého príbehu), **Terrain** (prepína terén na aktuálnej mape: žiadny → stromy → múriky → ulička → príliv → pásy); po prvom teste sa do reštartu nič neukladá
- [x] Testy: `dev_boss_rush`, `dev_quests` (spustí všetkých 91 questov/krokov), `dev_boss_kraken`, 4 nové `secret_*`
- [x] 4 nové príbehy pre mapy s terénom: Stará bylinkárka (Záhrada), Beh po múrikoch (Strecha), Rozliate mlieko (Supermarket), Vrecia s pieskom (Prístav)
- [x] Predmety, zóny, stopy, cieľ červenej bodky aj domovy záchran sa kladú len na voľné miesto (nie do stromu, regálu či steny)
- [x] Ďalšie 3 príbehy: Stratené gombíky (Byt), Lampáš pre moly (Pivnica), Náhradné diely (Továreň); 12 nových charmov (spolu 31)
- [x] Nepriatelia sa pri náraze na stenu či strom šmýkajú popri nej k mačke
- [x] 4 nové vedľajšie questy (boli len 3): **Mesačný lúč** (putujúce mesačné svetlo, treba v ňom vydržať 15 s, lieči) , **Vodcovia svorky** (3 silní nepriatelia s korunou, poraziť do 45 s) , **Zakopaný poklad** (3 miesta na kopanie za sebou, na konci truhla a mince) a **Mačacie preteky** (5 vlajočiek, každá do 10 s)

## Inventár a výbava (malá verzia hotová 26. 10. 2026; zvyšok plán, podrobný návrh v `INVENTAR.md`)

**Hotové (malá verzia):** 5 slotov (obojok, čiapka, vesta, labky, chvost), 40 základných predmetov, rarity bežný / vzácny (náhodná vlastnosť navyše) / legendárny. Finálny boss dá svoju legendárku so schopnosťou s 30 % šancou (× šťastie, max. 45 %; ak ju už máš, dá vzácny predmet) (pulz magnetu, život navyše, tŕne, ochrana pri nízkom HP, zmrazenie, +1 projektil…), boss z vlny 50 %, elita 6 % (× šťastie). Predmety sa odnesú cez dvierka alebo výhrou; pri smrti studňa zachráni najlepší. Panel **Výbava (I)** na výbere mačky: nasadiť, dať dole, roztaviť na zlato (X dvakrát). Naraz najviac 2 nasadené legendárky. Na mačke sa kreslí len čiapka, každý druh inak. Sklad 40 predmetov, výbava je spoločná pre všetky mačky. Kód: `data/items.json`, `scripts/progression/items.gd`, `scripts/ui/item_panel.gd`, `Profile.items`. Testy: `items_check`, `gear_*`.

Cieľ: výbava na úrovni Halls of Torment a Death Must Die, ale s mačkami. Čísla
konkurencie treba ešte overiť (odhad z pamäti: HoT má okolo 10 slotov výbavy a
stovky predmetov, ktoré sa odomykajú studňou; DMD má ~7 slotov, predmety
s raritami a náhodnými vlastnosťami, sety a desiatky unikátov). Chceme mať
viac slotov aj viac základných predmetov než oni.

**Sloty (12):** obojok, zvonček/prívesok, čiapka/mašľa, okuliare/maska, vesta/kožúšok,
predné labky (rukavičky), zadné labky (topánočky), chvost (stuha, krúžok), fúzy (vosk, korálky),
pazúry (návleky), batôžtek (taška na chrbte), 2 talizmany (dnešné charmy sa stanú talizmanmi).

**Predmety:**
- [→] Rarity: bežný, neobvyklý, vzácny, epický, legendárny, mýtický (6) + unikáty s menom a príbehom
- [→] Minimálne **15 základných predmetov na slot = 180+** a k tomu **40+ unikátov** a **12+ setov** (napr. „Námornícky set“: obojok s kotvou, vesta, čiapka – bonus za 2/3 kusy)
- [→] Náhodné vlastnosti (affixy): 1–4 podľa rarity z ~40 vlastností (poškodenie, rýchlosť, oblasť, kritiky, život, brnenie, magnet, šťastie, chamtivosť, cooldown, projektily, trvanie, regenerácia, únik, odraz, jed, oheň, mráz, blesk, poškodenie bossom, poškodenie pri plnom živote, ...)
- [→] Vlastnosti špecifické pre zbrane („+1 klbko“, „škrabanec zasiahne 2×“) a pre mačky
- [→] Úroveň predmetu podľa mapy a temnoty; lepšie predmety na neskorších mapách

**Kde predmety padajú a čo s nimi:**
- [x] Počas noci: z bossov, elít, truhlíc a questov (predmet si odnesieš len cez dvierka alebo výhrou – ako dnes charmy) *(overené 8. 11.: v hre je)*
- [→] Úkryt (domček) medzi nocami: **inventár** (mriežka, triedenie, porovnanie s nasadeným, zamknutie), **truhla** na sklad, **kováč/šijacia dielňa** (vylepšenie, prehodenie vlastnosti, rozobratie na materiál), **obchodník** s ponukou, ktorá sa mení
- [→] Každá mačka má vlastnú nasadenú výbavu; predmety sa dajú presúvať
- [→] Materiály: chlpy, nite, rybie šupiny, kovové skrutky (z máp podľa témy)
- [→] Bezpečnosť uloženia: verzia profilu, migrácia charmov na talizmany, záloha

**Technika (keď sa do toho pustíme):**
- [→] `data/items.json` (základné predmety, sety, unikáty), `data/affixes.json`
- [→] `scripts/progression/items.gd` (generovanie, hodnoty), `scripts/ui/inventory_panel.gd`, `Profile` – sklad a výbava každej mačky
- [→] Vzhľad: predmety sa kreslia na mačke (obojok, čiapka, topánočky) – aspoň obojok, čiapka a vesta
- [→] Testy: generovanie 10 000 predmetov bez chýb, uloženie/načítanie, migrácia starého profilu

## Viac obsahu než konkurencia (cieľ)

- [→] Mapy: dnes 7 (z toho 5 s terénom: stromy, múriky, ulička, príliv, pásy) → cieľ **12+**: Pivnica-bludisko, Les (stromy hustejšie, rúbanisko), Kanál (úzke chodby, voda), Cintorín (náhrobky, hmla), Vlak (ide len doprava, vagóny), Zasnežené mesto (ľad, kĺzanie)
- [→] Questy: dnes 91 questov a krokov príbehov → cieľ **150+**; nové typy krokov: únik pred niečím, ochrana pohyblivého cieľa, hádanka (spínače v poradí), preteky na čas, stealth v tme
- [→] Bossovia: dnes 40 → cieľ 60, každý s aspoň 2 špeciálnymi útokmi (otestovať boss rushom)
- [→] Zbrane: dnes 16 základných + evolúcie → cieľ 30
- [→] Mačky: dnes 11 + 2 tajné → cieľ 20

## Fáza 3 – Grafika a zvuk

- [→] Sprity aj pre nábytok, podlahy, zbrane a projektily (teraz sú kreslené vektorovo)
- [x] Animácia smrti (nepriateľ sa sploští, vyskočí, otočí a zbledne) a hviezdička pri kritickom zásahu
- [x] Obrázok v hlavnom menu (nočné mesto, mesiac, mačky)
- [x] Ikona hry: Micina hlava v pixel-arte (tools/gen_icon.py); .ico pre .exe pri exporte
- [x] Viac zvukov: rev bossov, mňauknutie pri level-upe, pišťanie zlatej myši, trblietanie šampióna, praskanie iskier, hrom, cinkanie mincí

## Fáza 4 – Pred vydaním

- [x] Dev panel (F1), ladiaci riadok a všetky prepínače (`--...`) fungujú len v ladiacej verzii; vydaná verzia ich ignoruje
- [x] Export: samostatný Windows `.exe`, otestovať na inom počítači *(overené 8. 11.: `builds/CatSurvivors.exe` a testovacie zipy pre testerov)*
- [x] Gamepad: ľavá páčka, Start, šípky, A potvrdí, B späť – overené automatickým testom (opravené: A v menu predtým nefungovalo)
- [x] Zmena kláves pohybu v Nastaveniach (šípky a ovládač fungujú vždy), návrat na WASD
- [x] Čeština ako tretí jazyk (747 textov); ďalšie jazyky = nový stĺpec v translations.csv
- [x] Návod pri prvej hre: tipy počas prvej noci (pohyb, zbrane, granulky, level, quest, dvierka, pauza, šampióni)
- [x] Záloha profilu: pred každým uložením sa odloží predchádzajúca verzia; poškodený profil sa načíta zo zálohy

## Otvorené otázky (rozhoduješ ty)

- Co-op pre dvoch hráčov – áno alebo nie? (pýtal si sa na začiatku)
- Koľko máp chceme celkovo a ako sa skončí príbeh?
- Vydanie: len pre seba, itch.io alebo Steam?

## Zásobník nápadov

Sem píšeme nápady, ktoré zatiaľ nemajú miesto vo fázach.

- ~~Denný beh s pevným seedom~~ hotové: Denná noc (T pri výbere mačky) – mapa, 2 výzvy a seed podľa dátumu, +500 zlata za prvú výhru dňa; týždenný beh zatiaľ nie
- Kozmetika pre mačky (obojky, klobúky) za zlato
- Achievementy

## Október 2026: jazyky

- Pridané jazyky: španielčina, ruština, zjednodušená čínština (všetkých ~1700 textov). Čínske znaky kreslí systémové písmo. Prvé spustenie zvolí jazyk systému.
- `tools/strings_check.gd` nahrádza pythonovú kontrolu: chýbajúce preklady, zástupné znaky aj ich poradie, osamotené %, znaky, ktoré písmo nevie nakresliť.
- `tools/translations_tool.gd` (dump / merge / missing) na ďalšie preklady; `tools/menu_shots.gd` odfotí všetky menu vo všetkých jazykoch.
- Spodný rad tlačidiel na výbere mačky sa zmenší, keď je v jazyku priširoký; názov terénu na mapovej karte má tmavý podklad.
- Tlačidlo jazyka v rohu hlavného menu; text „Čo je nové“ (verzia 9) o bossoch, výbave a jazykoch.
- Testy textov: `text_fit` prejde menu, panely, „Čo je nové“ aj hru (HUD, pauza, level-up, voľby svätyne, súhrn) vo všetkých 6 jazykoch a kontroluje aj nevykresliteľné znaky; medzi číslom a % je nezlomiteľná medzera.

## Október 2026: spätná väzba z hrania

- Menu sa zmestí v EN/SK/CS: mapové karty zmenšia písmo, denník zalamuje odmeny; test `text_fit` (`tools/text_fit_test.gd`) prejde všetky obrazovky a panely v každom jazyku.
- F1 panel: pauza, celá obrazovka, bossovia podľa máp, questy, hľadanie, checklist vyskúšaného.
- Supermarket: široká ulička, ktorá zatáča hore aj dole ako cesta; rozbitné veci a nepriatelia sa objavujú len na priechodnej ploche (všetky terény).
- Anjel a Smrť: šanca rastie so spotrebovanými životmi, Smrť po anjelovi v 50 %.
- Bossovia: 7 podpisových útokov (cross, blink, sweep, meteor, chase, cage, whirl), každý finálny boss má vlastný a otvára ním boj.
- Bossovia: hlavný útok (prvý v `specials`) každé 2,4–3,4 s, každý 4. je zriedkavý iný. Len finálni bossovia majú vlastné pravidlo boja (`fight` v `data/enemies.json`): Vacuum King kruhy mobov, Rat King tŕňová aréna + kruhy mobov + portály (Nekromant z DMD), Lawnmower živé ploty (steny Frost Knighta z HoT), Bruno netopiere + krvavý stĺp a 2. fáza (Drakula z DMD), Guard Dog svorka pri 2/3 a 1/3 HP, Kraken vodná aréna, Robo Vacuum 3000 2. fáza. Menší bossovia nemajú arénu ani portál.

## Október 2026: bossovia a korisť (spätná väzba 2)
- Finálni bossovia: každý má vlastný útok, ktorý nemá nikto iný (Vacuum King `vortex`, Rat King `swarm`, Lawnmower `mow`, Kraken `tentacles`, Robo Vacuum 3000 `grid`, Bruno `bats`, Guard Dog/Rex bez zmeny) a žiadni dvaja finálni sa útokmi neprekrývajú. Mole King už nemá útoky Rat Kinga.
- Zdravie finálneho bossa rastie s levelom mačky ako u bežných nepriateľov (`Spawner.final_hp_multiplier`).
- Pomocníci bossov chodia v 3 vlnách (3× viac na vlnu, o polovicu zriedkavejšie); finálny boss volá 3 vlny po 16 silnejších miniónov.
- `sweep` (Assembly Arm, Lawnmower) kreslí pásy ako ručičku hodín namiesto rozhádzaných kruhov; nový typ varovania `beam`.
- Truhlica vyskočí z bossa, dopadne s odrazom a zvukom; bossova svieti svetelným stĺpom. Legendárny predmet: fanfára + zlatý výbuch.
- Majster pascí: ráta sa každé zabitie, kým mačka stojí v kruhu.
- Dev panel: v teste vždy padne predmet z bossa, tlačidlá „Find an item", „Find this map's legendary", „Unlock angel + devil cats".

## Štvrť – nový výber mapy a živý svet (návrh 29. 10. 2026)

Hotové (29. 10. 2026): krok 1 – výber mapy je kreslená nočná štvrť (`scripts/ui/district_map.gd`): všetkých 7 máp ako miesta, svetlá, voda, vlak, hmla nad zamknutými, budúce mapy Park/Cintorín/Ostrov/Stanica v hmle, ťahanie myšou, šípky na okrajoch, minimapa; panel miesta vpravo (príbeh, boss, náročnosť, dĺžka, príbehy, rekord, tma, hviezdy ★ výhra / ★★ výhra v tme / ★★★ všetky príbehy); pás mačiek dole. Menu panely (prívesky, artefakty, výbava, výzvy, denník, obchod, novinky) sú na rámovanej tabuli (`UiStyle.board`), nové farby v `UiStyle`. Mačky majú nové sprity s objemom.
Hotové (29. 10. 2026): krok 3 – domov mačiek (`home`, `home_bonus` v `data/cats.json`; bonus v noci na domácej mape, +25 % zlata za výhru doma, domček pri mačke a štítok „Doma") a krok 4 – nočné správy (`Profile.reports`): obrana mapy, ktorú si vyhral (vydrž 10 min = +150 zlata, inak ťa okradnú až o 5 % zlata, max 120), lov na bossa (výhra = +250 zlata, čaká 3 noci), zlatá noc (zlato ×2, ráno zmizne); každá s jednou výzvou; značky na mape, panel správy, výsledky v súhrne noci. Testy `report_hunt`, `report_gold`, `home_cat`.
Hotové (29. 10. 2026): krok 6 – nemesis bossovia (`Profile.nemesis`): boss najbližšie k mačke, keď padne, sa stane nemesis (úroveň 1–3: +20 % HP, +10 % poškodenie, +8 % rýchlosť za úroveň, titul „Pamätá si ťa / Lovec mačiek / Postrach štvrte"); s 35 % šancou ťa v inej noci medzi 8. a 12. minútou loví (finálny boss inej mapy len s 30 % zdravia a noc neukončí); pomsta = truhlica bossa + 300 zlata; nemesis hore na obrazovke štvrte a v paneli miesta. Testy `nemesis_new`, `nemesis_revenge`.
Hotové (29. 10. 2026): krok 7 – spln každých 7 nocí (`Profile.moon_*`): mesiac pri Byte a odpočet hore; príprava za zlato – pasce len na nepriateľov (60, max 4) a strážne mačky ako spoločníci (120, max 2); noc splnu v Byte, každé 3 minúty príde finálny boss inej otvorenej mapy (40 % zdravia); výhra +500 zlata, prehra alebo vynechanie = vyplienený domov (10 % zlata, max 200). Test `moon_night`.
Hotové (30. 10. 2026, značka `krok-2-obyvatelia`): krok 2 – obyvatelia (`Profile.RESIDENTS`): odomknuté mačky Old Whiskers, Bolt, Chonk, Captain a Clover bývajú na mape a ponúkajú službu na ďalšiu noc (čaj +30 zdravia, brúsenie +15 % poškodenie, karty +1 losovanie/vyradenie, námornícke labky, štvorlístok); neubránená mapa = unesený obyvateľ (inak krádež zlata), nočná správa Záchrana ho vráti (+120 zlata). Testy `resident_service`, `report_rescue`.
Hotové (30. 10. 2026, značka `mapa-park`): nová mapa Park (téma záhrady, holuby, finálny boss Holubí kráľ `PIGEON_KING`, odomkne sa po Streche, náročnosť 1,55) a približovanie štvrte kolieskom myši. Testy `park`, `final_pigeon`.
Hotové (30. 10. 2026, značka `krok-5-nocna-tura`): krok 5 – nočná túra ako nočná správa (»): v 7. a 14. minúte sa otvorí brána (ľavá/pravá) a noc pokračuje na inej otvorenej mape (podlaha, terén, nepriatelia, hudba aj finálny boss); výhra +200 zlata, cesta poslednej túry sa nakreslí na štvrť azúrovou. Test `night_trip`.
Hotové (30. 10. 2026, značka `krok-8-dobyvanie`): krok 8 – dobývanie: na nedobytej mape stoja 3 vlajky bossa (šípky na okraji obrazovky); 6 s pri vlajke ju obsadí (+20 % zdravia, mince); všetky 3 + výhra noci = mapa dobytá navždy s bonusom v každej noci (`Profile.TERRITORY_BONUS`, napr. Byt +10 zdravie, Záhrada +0,3 regenerácia); dobyté mapy majú na štvrti zlatú vlajku a panel ukazuje bonus. Testy `territory_flags`, `territory_won`.
Hotové (30. 10. 2026, značka `mapa-cintorin`): nová mapa Cintorín s vlastnou témou podlahy (tmavý trávnik, štrk, hroby, náhrobky, kríže, mŕtve stromy, hrobka, sviečky so svetlom), netopiere, pavúky, mole; finálny boss Gróf Netopier `BAT_COUNT`; odomkne sa po Parku. Testy `cemetery`, `final_bat`.
Hotové (30. 10. 2026, značka `mapa-ostrov`): nová mapa Ostrov (téma prístavu s prílivom, kraby, medúzy, čajky; finálny boss Krabí cisár `CRAB_EMPEROR`; odomkne sa po Prístave). Testy `island`, `final_crab_emperor`.
Hotové (30. 10. 2026, značka `mapa-stanica`): nová mapa Stanica (betónové nástupištia v téme strechy, holuby, potkany, mývaly, drony; finálny boss Mýval prednosta `STATIONMASTER`; odomkne sa po Supermarkete). Testy `station`, `final_stationmaster`.
Hotové (30. 10. 2026, značka `tema-stanica`): Stanica má vlastnú tému podlahy (nástupištia so žltou čiarou, koľajisko, hala, návestidlá, zarážadlá, automaty na lístky, kufre, staničné lampy). Legendárne predmety pre 4 nových bossov, okno Čo je nové 11.
Hotové (30. 10. 2026, značka `tema-ostrov`): Ostrov má vlastnú tému podlahy (piesok, palmový háj, skalnaté pobrežie s jazierkami, palmy, skaly, vrak, táborák so svetlom).
Hotové (30. 10. 2026, značka `specialita-stanica`): Stanica má vlastnú špecialitu – vlak (`MapHazard`, stage `hazard: train`): červený pás s varovaním, potom vlak prejde cez riadok mačky, zrazí nepriateľov (bossom zoberie 4 %), mačke 18 zdravia. Nové pasce koľajnica s iskrami a turniket, rekvizity kufre a noviny, nový nepriateľ Stratený kufor, vlastné udalosti, questy Stratená batožina a Posledný vlak, riadok v knihe úloh. Testy `station_train`, `chain_luggage`, `chain_last_train`.
Hotové (30. 10. 2026, značka `specialita-ostrov`): Ostrov – pri odlive (`hazard: low_tide`) zostanú na mokrom piesku 3 trblietavé poklady (mince, 30 % truhla) so šípkou, 25 s. Nové pasce padajúci kokos a ježovka, rekvizity kokosy a naplavené drevo, nový nepriateľ Morská korytnačka (pomalá, nedá sa odtlačiť), vlastné udalosti, questy Stroskotanec a Korytnačie hniezda, riadok v knihe úloh. Testy `island_treasure`, `chain_castaway`, `chain_nests`.
Hotové (30. 10. 2026, značka `specialita-cintorin`): Cintorín – hmla sa plazí ponad hroby a každých 35–50 s sa okolo mačky rozžiaria 3 hroby (`hazard: graves`): keď si na hrob 1,5 s sadneš, zapečatíš ho (XP), z nezapečatených po 8 s vyletia duchovia. Nové pasce kostená ruka a bludička, rekvizity urny a vence, nový nepriateľ Malý duch, vlastné udalosti, questy Nepokojné duše a Hrobárova lopata, riadok v knihe úloh. Testy `cemetery_graves`, `chain_spirits`, `chain_gravedigger`.
Hotové (30. 10. 2026, značka `specialita-park`): Park má vlastnú tému podlahy (lúka, chodníky, jazierko s kačkami a trstinou, fontána, piknikové deky) a špecialitu holub zlodej (`hazard: pigeon_thief`): každých 40–55 s pristane pri mačke tučný holub, uteká a zobe granuly; keď ho chytíš, vráti 1,5× toľko XP aj mince, inak uletí. Nové pasce trávnikový postrekovač a husacie hniezdo, rekvizity piknikový košík a vrecko chleba, nový nepriateľ Veverička, vlastné udalosti, questy Nakŕm kačky a Stratený šarkan, riadok v knihe úloh. Nočné osvetlenie pre Park, Ostrov a Stanicu. Testy `park_thief`, `chain_ducks`, `chain_kite`.

Hotové (30. 10. 2026, značky `mapa-napoveda`, `mapa-cesty`): nápoveda na mape štvrte má krížik a po 5 s sama zmizne; bodkované cesty medzi miestami sa už nestrácajú pri posúvaní mapy (vrstva mala nulovú veľkosť a Godot ju skryl) a dajú sa vypnúť tlačidlom „Cesty" pod minimapou (uloží sa v nastaveniach).

Hotové (30. 10. 2026, značka `obrana-zriedkava`): obrana na mape už nie je daň za každú noc. Príde len raz za 2–3 pokojné noci, len na jednu z dvoch naposledy vyhratých máp (nie na staré), počká 2 noci (číslo na štítku, posledná noc bliká) a dobyté mapy sa nikdy neobliehajú. Test `sieges` (`tools/siege_test.gd`).

Hotové (30. 10. 2026, značka `mapa-jeden-klik`): klik na miesto na mape hneď ukáže aj jeho úlohu (obrana, zlato, lov…), tlačidlo „Vynechať, len hrať tu" ju vypne a „Prijať úlohu" vráti. Obyvatelia majú namiesto „$" cenovku s cenou a po prejdení myšou ukážu, akú službu ponúkajú. Opravené pokazené čísla v 6 textoch (služby obyvateľov, 3 predmety bossov) a kontrola textov teraz hlási riadiace znaky.

Hotové (30. 10. 2026, značka `park-jazierka`): jazierka v Parku už nie sú len kresba. Brodenie spomalí mačku aj nepriateľov na polovicu (lietajúci – holuby, včely, netopiere, duchovia… – letia ponad), okolo labiek sú vlnky. `WorldFloor.in_water()` počíta tvar jazierka rovnako ako kresba (`FloorChunk.pond_shape`).
Ďalej: najprv dokončiť prvú štvrť (~~pravidlo najviac 2 hrozby naraz~~ overené 30. 10. – nemesis už nepríde ani na vynechaný spln, doladenie podľa hrania, grafika a zvuk). Druhá štvrť až potom – pozri „Psie štvrte".

Cieľ: výber mapy vyzerá prémiovo, má význam a dáva dôvod vracať sa na staré miesta. Na mape sa rozhoduje do 15 sekúnd, všetko podstatné sa prejaví priamo v noci.

1. **Obrazovka štvrte.** Celá obrazovka je ručne kreslená štvrť (pixel-art): dom s obývačkou a pivnicou, záhrada, strecha, supermarket, prístav, fabrika; cestičky, dym, vlnky, svetlá v oknách. Vpravo panel vybraného miesta (krátky príbeh, boss, náročnosť, príbehy, rekord, hviezdy, čo prinesie dobytie). Dole menší pás mačiek s popisom a tlačidlom Hrať. Režim „Jedna noc" ako doteraz.
2. **Rast štvrte.** Hviezdy (★ prežiť, ★★ boss, ★★★ všetky príbehy), neprebádané miesta v hmle, odkrývanie ďalších ulíc. Zachránené mačky sa nasťahujú do domov a otvoria služby (kováč, liečiteľka, obchod, mapy).
3. **Domáci terén mačiek.** Každá mačka má domácu mapu (+bonus, zlatá bodka v páse mačiek) a nemilovanú (malý postih); výhra doma = extra truhla.
4. **Nočné správy.** Pred nocou 3 karty z dobytých miest (obrana, nočná túra, príležitosť); vyberieš jednu, ostatné sa vyriešia samy (dobre, zle, alebo zmiznú). Neúspech = unesený obyvateľ a zatvorená služba, kým ho nezachrániš.
5. **Nočná túra.** Jedna noc cez 3 miesta; v 7. a 14. minúte dve brány (vľavo/vpravo). Cesta sa potom nakreslí na mapu štvrte. Nahrádza výpravu na 3 noci.
6. **Nemesis bossovia.** Boss, ktorý ťa zabil, dostane prezývku a novú schopnosť, občas ťa loví v iných nociach; pomsta = legendárna truhla.
7. **Spln každých 7 nocí.** Všetci bossovia útočia naraz; príprava (pasce, hliadky, stráže z mačiek, obyvatelia) je priamo v obrannej noci. Domov sa nedá stratiť úplne.
8. **Dobývanie v noci.** Herná mapa rozdelená na tvoju a nepriateľskú časť, zabíjaním posúvaš hranicu; dobyté územie dá trvalý bonus a otvorí susedné.

Pravidlá: hviezdy, odomknutia a príbehy sa nikdy nestratia; najviac 2 hrozby naraz. Voľba „Pokojná štvrť" vyhodená (30. 10. 2026) – obliehanie je už zriedkavé a mierne. Vyhodené z návrhu: percentá hrozby, produkcia za noc, stráženie ako samostatné menu.

## Nové mechaniky – nápady (30. 10. 2026, zatiaľ nerobíme)

Každá sa dá urobiť malá v 1. štvrti a neskôr rozšíriť (psie štvrte, nové mapy).

- [→] **Aktívna schopnosť mačky** (jedno tlačidlo, cooldown): Mica skok, Tiger rev, Snehulka zamrazenie… Neskôr psy: štekot, čuch, privolanie svorky. Dnes má mačka len pasívny bonus.
- [x] **Počasie v noci:** dážď (pomalší nepriatelia, mláky), vietor (odfúkne projektily a granuly), búrka (blesky do nepriateľov aj do mačky), hmla. Náhodne alebo podľa mapy; každá nová štvrť pridá svoje. *(overené 8. 11.: v hre je)*
- [x] **Spojenia zbraní:** dve konkrétne zbrane naraz dajú bonus navyše (napr. Mrazená rybka + blesk = rozbitie ľadu). Nie evolúcia, len spoločný efekt; ľahko sa pridávajú ďalšie dvojice. *(overené 8. 11.: v hre je)*
- [x] **Deväť životov:** každá mačka má 9 životov na celú hru; smrť jeden zoberie a dá malý trvalý bonus („jazva"), stratené životy sa dajú vrátiť v štvrti. Dáva smrti zmysel a príbeh mačky. *(overené 8. 11.: v hre je)*
- [→] **Krotenie:** oslabeného elitného nepriateľa chytíš (podržíš tlačidlo) a do konca noci bojuje za teba. V psej štvrti hlavná mechanika (získavanie psov do svorky).
- [→] **Dielňa v štvrti:** z nocí nosíš suroviny (klbká, kosti, skrutky), obyvatelia z nich vyrábajú vylepšenia výbavy. Každá štvrť nové suroviny a recepty.
- [x] **Prekliatia za odmenu:** pred nocou si zoberieš 1–3 prekliatia (rýchlejší nepriatelia, menej liečenia…) za viac zlata a lepšiu korisť. Jednoduchý spôsob, ako zvýšiť obtiažnosť pre skúsených. *(overené 8. 11.: v hre je)*

## Psie štvrte (plán 30. 10. 2026, zatiaľ nerobíme – najprv dokončiť prvú štvrť)

Príbeh v troch štvrtiach: psy sú najprv nepriatelia, potom spojenci. 2. a 3. štvrť sa robia ako samostatný balík (v dátach `pack: "dogs"`), aby sa pri vydaní dali dať do hry alebo predať ako DLC.

1. **1. štvrť – Mačky doma (dnešná hra).** Domáce predmety, potkany, holuby… Dokončiť ako prvé.
2. **2. štvrť – Psia štvrť (psy sú nepriatelia).** Prechod cez Stanicu. Mapy napr. Psí útulok, Mäsiareň, Výstavisko, Psí park, Kynologická stanica.
   - [x] Psí nepriatelia s vlastným správaním: svorky, ktoré obkľúčia; štekot privolá ďalších; útočníci, ktorí sa vrhnú; strážcovia územia. Pomocníci: blchy, poštár, psovod s kefou. *(overené 8. 11.: v hre je)*
   - [x] Psí bossovia: buldog, ovčiak, chrt, jazvečík v norách, finále Vodca svorky – neporazíš ho navždy, získaš si ho (most do 3. štvrte). *(overené 8. 11.: v hre je)*
   - [x] Jeden tajný hrateľný pes už v 2. štvrti (zachránené šteniatko), aby sa hráč tešil. *(overené 8. 11.: v hre je)*
3. **3. štvrť – Psy ako hrateľné postavy.**
   - [→] Psy sa hrajú inak ako mačky: viac zdravia, útoky zblízka, štekot (odtlačí), čuch (nájde poklady a questy), svorka (malí psí pomocníci). Mačky ostávajú rýchle, so šťastím, kritmi a uhýbaním.
   - [→] Nová hrozba pre mačky aj psy: psíčkari, pouliční zlodeji, odchytová služba.
4. **Vydanie:** najprv itch.io (zadarmo/demo, spätná väzba), potom Steam so stránkou a wishlistami; psie štvrte ako súčasť hry alebo DLC – rozhodne sa pri vydaní.

## 1. 11. 2026: kompletný test hry od začiatku do konca

- `bash tools/campaign.sh` – jedna mačka (Ginger) hrá všetky mapy v poradí odomykania na vlastnom testovacom profile (`--profile=`), pri smrti sa oživí (`--revive`), po noci nakúpi vylepšenia (`--shop`), dvierka odmieta (`--no-flap`). Výsledok: všetkých 11 máp vyhraných, finálni bossovia porazení, 0 chýb skriptov.
- `bash tools/weapons_test.sh` – každá z 36 zbraní sama (`--no-new-weapons`), bot vypisuje poškodenie podľa zbrane. `EXTRA="--start-minute=10 --catch-up"` pre neskorú hru.
- `--end-shots=NAZOV` uloží všetky strany konečnej obrazovky, `--lang=sk` jazyk na jedno spustenie.
- Opravené: posuvník na krátkej konečnej obrazovke, „bonus série +0 %", Úroveň/úr. v SK/CS, „Cooldown" v obchode, značka ponuky prekrývala „5 · Supermarket", odrezané názvy výbavy v slotoch, riadok dvierok sa prekrýval s questom/požehnaním v HUD, kombo Naháňačka (myšky teraz idú po cieli z lasera), Šantová záhrada a Tsunami silnejšie, testy kombá Signál a Naháňačka už nezávisia od náhody.
- Na zváženie (balans podľa bota, nie hráča): smrti v 10.–19. min – Byt 3, Pivnica 20, Strecha 27, Supermarket 1; bez nákupov v obchode bot Továreň nevyhrá (R3000 má 90k HP). Melee/aura zbrane (Tigrie pazúry, Šantová záhrada, Kostený kolotoč, Monzún) dávajú v neskorej hre zlomok poškodenia ostatných evolúcií.

## 13. 11. 2026: nové UI pred Steamom – štýl „Krabica od topánok“

Vydanie pôjde rovno na Steam (bez itch.io), možno s demom; týždenný sen príde až ako update po vydaní. Pred Steamom sa prerába celé UI, lebo pôsobilo genericky. Z 5 návrhov (krieda, krabica, samolepky, neón, linoryt) hráč vybral **Krabicu**: kartón s odtrhnutými hranami, papierová páska, červená fixka, labky ako pečiatky a značky. Samotná hra (hracie pole, mačky, nepriatelia) sa nemení – len menu, panely, mapa štvrte (ostáva mapou mesta, štýl len na štítkoch a cestách) a HUD.

1. [x] **Hlavné menu** (13. 11.): písma Delicious Handrawn (nadpisy, tlačidlá) a Shantell Sans (texty, cyrilika) v `fonts/` (OFL), fallback na pôvodné písmo pre zh_CN; zdieľané kreslenie `scripts/ui/box_style.gd`, `box_board.gd`, `box_button.gd`; menu má tabuľu s názvom, pásky, kartónové tlačidlá s fixkovým krúžkom pri výbere.
2. [x] **Nastavenia** (13. 11.): list lepenky, nadpis na svetlom kartóne s páskou, dva stĺpce (zvuk + obraz / hra, jazyk + ovládanie oddelené fixkovou čiarou), labky ako odrážky, prepínače s červeným háčikom, posuvníky s labkou, klávesy ako krémové klávesy; ručné písmo dostalo širšiu medzeru. Nadpisy skupín Obraz / Hra / Ovládanie zatiaľ chýbajú (nie sú preklady).
3. [x] **Štvrte** (13. 11.): pixelové mesto bez zmeny; nad ním štítky miest z papierovej pásky s hodnotením labkami, cesty medzi mapami zo stôp labiek, papierové vlajočky, žltý lístok „ĎALEJ“, vybrané miesto obkrúžené červenou fixkou, kartónové tlačidlá a šípky, mapa pripnutá páskou na kartón, bočný panel miesta z kartónu a papierových lístkov (nové `paw_rating.gd`, `tape_tag.gd`). Spodný pás s výberom mačky ostáva na krok 5.
4. [x] **HUD v hre, level-up, truhla** (13. 11.): XP lišta s nerovným koncom, úroveň na krémovom kartóne, nakreslené srdce a lišta zdravia, čas na kartóne, lišta noci, „Porazení“ so labkou, ikony v nerovných rámikoch s červeným odznakom úrovne, banner ako červený kartón, lišta bossa, šípky ako nerovné farebné kruhy; text nad hrou tučné Shantell Sans s hrubým obrysom; ťažké tvary sa prekresľujú len pri zmene. Level-up a truhla: kartónové lístky, vzácnosť farbou fixkového rámika a počtom labiek, výber obkrúžený červenou fixkou (nové `hud_bar.gd`, `hud_card.gd`, `hud_icon.gd`, `level_card.gd`).
   [x] **Pauza a koniec noci** (13. 11.): nadpis na kartóne, kartónové tlačidlá (Vzdať sa s dvojklikom), prepínače L/M/N/K ako lístky, bočné tabule so zbraňami, schopnosťami, správami a príbehmi (labky); koniec noci ako list svetlej lepenky s páskami, pečiatka labky pri výhre, 4 kartónové dlaždice, poškodenie ako čiary červenou fixkou, tlačidlá s klávesom (nový `box_panel.gd`). Staré nepoužité `_over_overlay`, `_win_overlay`, `_extract_overlay` v `hud.gd` ostali na upratanie.
5. [ ] Ostatné panely (výber mačky, obchod, denník, …)

## Ako pracujeme

- Každý väčší krok = commit; na GitHub pushujeme, keď povieš.
- Pred commitom vždy prejdú testy: `bash tools/run_checks.sh`.
- Scenáre môžu overiť, že sa niečo naozaj stalo: `--expect=udalosť` / `--expect-not=udalosť` (udalosti zapisuje `BotLog.event`, porušené pravidlá `BotLog.fail` → `TEST: FAIL`). Boje bossov: scenáre `boss_*`.
- Testovacie behy nikdy neukladajú tvoj profil (`--bot`, `--ui-test`, `--no-save`).
- Dev nástroje sú v poriadku počas vývoja, pred vydaním ich odstránime.
