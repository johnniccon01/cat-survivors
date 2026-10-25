# Plán – Cat Survivors

Živý zoznam toho, čo je hotové, čo robíme teraz a čo príde. Po každom kroku
ho aktualizujeme: hotové odškrtneme `[x]`, nové nápady pridáme do Zásobníka.

Naposledy aktualizované: 25. 10. 2026 (mapy s prekážkami, dev testy, plán inventára)

---

## Kde sme

Hra je hrateľná od menu po koniec noci na 7 mapách:

- **Mapy:** Byt → Pivnica → Záhrada → Strecha → Supermarket → Prístav → Továreň (každá sa odomkne porazením
  finálneho bossa predchádzajúcej), každá s vlastnou podlahou, nábytkom,
  nepriateľmi, bossmi, pascami a hudbou.
- **Mačky:** 11 hrateľných (Mica, Luna, Snehulka, Mrňa, Tiger, Barón,
  Ďatelinka, Bruno, Tučko, Kapitán, Šrubka) + 2 tajné (anjel, diabol).
- **Boj:** 16 zbraní s evolúciami a vetvami, 12 pasív, kritické zásahy a šťastie,
  čísla poškodenia, zásahové efekty, otrasy.
- **Priebeh noci:** rozpočet nepriateľov s krivkou intenzity, oddychy,
  udalosti (kruhy, roje), elity, bossovia, finálny boss, mačacie dvierka na
  útek, série výhier.
- **Questy:** 45 príbehov (3 na každú mapu, 3 cez všetky mapy, 10 samostatných, tajomstvo na každej mape) s voľbami a trvalými zmenami máp, záchrany a súboje mačiek, príbehový quest na každej mape, vedľajšie úlohy.
- **Meta:** zlato, obchod s vylepšeniami, charmy, 29 artefaktov, 40 úspechov, dlhodobé ciele, kniha questov, výzvy, nekonečná noc.
- **Tajomstvo:** anjel ťa na streche po 15. minúte s malou šancou zachráni;
  po dvoch záchranách príde diabol, ktorý zabije isto.
- **Technika:** menu, nastavenia, pauza, SK/EN/CS, gamepad, pixel-art sprity, 147
  automatických testov vrátane celých nocí na každej mape (`tools/run_checks.sh`), spúšťače v `Spustit\`.

## Teraz

- [ ] Zahrať nové príbehy, Továreň a nové zbrane a dať spätnú väzbu (obtiažnosť questov, sila artefaktov)

- [ ] Vyskúšať novú obtiažnosť, anjela a diabla (`Spustit\4 Test anjel a diabol.bat`) a dať spätnú väzbu
- [x] Pushnúť posledné commity na GitHub – odteraz sa pushuje po každom otestovanom kroku

## Fáza 1 – Doladenie podľa hrania

Najprv dotiahnuť to, čo už máme, kým pridáme ďalší obsah.

- [ ] Obtiažnosť: doladiť rast poškodenia a HP nepriateľov podľa tvojich hier (každá mapa zvlášť)
- [x] Okno „Čo je nové“ po aktualizácii, Denná noc (T), príbehy v Denníku podľa máp, príbehy mapy v pauze, tlačidlo „Story step now“ v dev paneli (F1), výber mačky pre 13+ mačiek, artefakty v 3 stĺpcoch
- [x] Testy: `QUICK=1` (30 scenárov, ~1 min) medzi krokmi, celá sada (~9 min) na konci
- [x] Začiatok neskorších máp ľahší: nepriatelia na mapách 2–7 majú na začiatku noci o 30 % menej zdravia a slabšie útoky, do 6. minúty sa to vyrovná
- [ ] Ceny vylepšení v obchode a sila charmov – nie je niečo príliš silné alebo zbytočné?
- [x] Výkon: 114–144 FPS v 17. minúte na Streche, stabilných 144 v nekonečnej noci so šampiónmi (RTX 4070 Ti, 144 Hz) – netreba optimalizovať
- [x] Príbehové questy pre každú mapu: obojok (Byt) → stará mapa (Pivnica) → kľúč pod stromom (Záhrada) → Brunov odkaz (Strecha); quest Cesta nahor
- [x] Hudba: dlhšie skladby máp (2–2,7 min), nočná skladba od polovice noci, vlastná hudba pre každého finálneho bossa a diabla
- [ ] Hudba: tvoja spätná väzba na skladby (ja ich nepočujem)
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
- [ ] Predmety s náhodnými vlastnosťami (výbava ako v Death Must Die) – veľký systém, zatiaľ nie

## Výkon a svätyne (22. 10. 2026)

- [x] Výkon (ako Vampire Survivors / Halls of Torment – všetko v dávkach): podlaha každého chunku (zem, nábytok, svetlo) sa nakreslí raz do textúry; sprity všetkých nepriateľov a mačiek v jednom atlase; tiene, zásahy, strely, granulky, mince, pasce a efekty zbraní cez spoločnú textúru (`Blit`); čísla poškodenia najprv všetky obrysy, potom výplne; granulky bez `_process`; svetlo mačky len v noci; skripty krokov questov sa načítajú na začiatku noci
- [x] Výsledok (RTX 4070 Ti, 17. minúta Strechy, všetkých 16 zbraní): ~60 → ~360 FPS, draw cally ~3300 → ~380; bežná hra v 17. minúte ~380–460 FPS
- [x] Bez zásekov: viewporty podlahy sa recyklujú (nový chunk 0,1 ms namiesto 2–8 ms), atlas spritov a skripty questov sa pripravia pri načítaní; `perf.log` zapisuje aj najdlhšiu snímku (`worst=`) za každých 10 s
- [x] Nové testovacie prepínače: `--seed=N`, `--no-vsync`, `--shot=SEKUNDY` (screenshoty), `--show-choice`
- [x] Svätyne ako v Death Must Die: po prebudení výber z 2–3 darov – prvý vždy bezpečný, ostatné silnejšie s cenou (krvavá prísaha, búrka, smotana, sladké ovocie = 2 levely za 40 % zdravia, chamtivosť, veľká kliatba so šampiónmi a truhlicou bossa); trvalé bonusy do konca noci; voľby aj myšou
- [ ] Zahrať a povedať, či sú dary svätýň vyvážené
- [ ] Výkon na notebooku: zahrať jednu noc a poslať `perf.log` (`%APPDATA%\Godot\app_userdata\Cat Survivors\perf.log`)


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
- [ ] Overiť v hre: vzdialenosti (7000 / 9000 px), sila bossov, či Túlavec do 5. levelu nie je priťažký

## Ľahší Supermarket, sólo bossovia, odmietnutie svätyne (23. 10. 2026)

- [x] Boss z reťazca „bez liečenia“ (Holubí cisár): ostatné mobky zmiznú a nespawnujú sa, kým súboj neskončí (`"solo": true` v chains.json to zapne aj inému bossovi)
- [x] Bossovia z vĺn chodia po jednom: ďalší počká, kým predošlý nepadne (+6–12 s pauza)
- [x] Supermarket: `damage_mult` 0,9, `challenge` 1,6 (bolo 1,7), zdravie vĺn od 7. minúty ~10 % nižšie (na konci 7,6 namiesto 8,5)
- [x] Svätyňa: posledná voľba „Nežiadaj nič a odíď“ (panel volieb až 4 karty)
- [ ] Overiť v hre: či je Supermarket teraz zvládnuteľný; bot v teste Holubieho cisára zbiera srdcia, takže úlohu nesplní (aj pred zmenou)

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
- [ ] Overiť v hre: či sú špeciálne útoky férové/čitateľné a či veľká truhlica nie je príliš silná

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
  - [x] **Továreň (7.) – pohyblivé pásy**: pásy cez halu posúvajú mačku aj nepriateľov do strán, susedné idú opačne a každých 25 s zmenia smer
  - [x] Karta mapy ukazuje, že mapa má prekážky; questy, svätyne, dvierka, pasce aj odmeny sa vždy položia na voľné miesto
- [ ] Zahrať všetky tri a povedať, či je ulička príliš úzka a príliv príliš častý (konštanty hore v `terrain.gd`)
- [ ] Ďalšie varianty: miestnosti v Pivnici (bludisko), lisy v Továrni, padajúce regále, mosty cez vodu
- [x] Dev panel (F1): **Silný build**, **Test bossa** (zoznam všetkých 40 bossov), **Boss rush** (všetci za sebou, 2 s pauza, liečenie), **Test questu** (všetky questy aj každý krok každého príbehu); po prvom teste sa do reštartu nič neukladá
- [x] Testy: `dev_boss_rush`, `dev_quests` (spustí všetkých 91 questov/krokov), `dev_boss_kraken`, 4 nové `secret_*`
- [x] 4 nové príbehy pre mapy s terénom: Stará bylinkárka (Záhrada), Beh po múrikoch (Strecha), Rozliate mlieko (Supermarket), Vrecia s pieskom (Prístav)
- [x] Predmety, zóny, stopy, cieľ červenej bodky aj domovy záchran sa kladú len na voľné miesto (nie do stromu, regálu či steny)
- [x] Ďalšie 3 príbehy: Stratené gombíky (Byt), Lampáš pre moly (Pivnica), Náhradné diely (Továreň); 12 nových charmov (spolu 31)
- [x] Nepriatelia sa pri náraze na stenu či strom šmýkajú popri nej k mačke
- [x] 3 nové vedľajšie questy (boli len 3): **Mesačný lúč** (putujúce mesačné svetlo, treba v ňom vydržať 15 s, lieči) , **Vodcovia svorky** (3 silní nepriatelia s korunou, poraziť do 45 s) a **Zakopaný poklad** (3 miesta na kopanie za sebou, na konci truhla a mince)

## Inventár a výbava (príprava – zatiaľ NEROBIŤ, len plán; podrobný návrh v `INVENTAR.md`)

Cieľ: výbava na úrovni Halls of Torment a Death Must Die, ale s mačkami. Čísla
konkurencie treba ešte overiť (odhad z pamäti: HoT má okolo 10 slotov výbavy a
stovky predmetov, ktoré sa odomykajú studňou; DMD má ~7 slotov, predmety
s raritami a náhodnými vlastnosťami, sety a desiatky unikátov). Chceme mať
viac slotov aj viac základných predmetov než oni.

**Sloty (12):** obojok, zvonček/prívesok, čiapka/mašľa, okuliare/maska, vesta/kožúšok,
predné labky (rukavičky), zadné labky (topánočky), chvost (stuha, krúžok), fúzy (vosk, korálky),
pazúry (návleky), batôžtek (taška na chrbte), 2 talizmany (dnešné charmy sa stanú talizmanmi).

**Predmety:**
- [ ] Rarity: bežný, neobvyklý, vzácny, epický, legendárny, mýtický (6) + unikáty s menom a príbehom
- [ ] Minimálne **15 základných predmetov na slot = 180+** a k tomu **40+ unikátov** a **12+ setov** (napr. „Námornícky set“: obojok s kotvou, vesta, čiapka – bonus za 2/3 kusy)
- [ ] Náhodné vlastnosti (affixy): 1–4 podľa rarity z ~40 vlastností (poškodenie, rýchlosť, oblasť, kritiky, život, brnenie, magnet, šťastie, chamtivosť, cooldown, projektily, trvanie, regenerácia, únik, odraz, jed, oheň, mráz, blesk, poškodenie bossom, poškodenie pri plnom živote, ...)
- [ ] Vlastnosti špecifické pre zbrane („+1 klbko“, „škrabanec zasiahne 2×“) a pre mačky
- [ ] Úroveň predmetu podľa mapy a temnoty; lepšie predmety na neskorších mapách

**Kde predmety padajú a čo s nimi:**
- [ ] Počas noci: z bossov, elít, truhlíc a questov (predmet si odnesieš len cez dvierka alebo výhrou – ako dnes charmy)
- [ ] Úkryt (domček) medzi nocami: **inventár** (mriežka, triedenie, porovnanie s nasadeným, zamknutie), **truhla** na sklad, **kováč/šijacia dielňa** (vylepšenie, prehodenie vlastnosti, rozobratie na materiál), **obchodník** s ponukou, ktorá sa mení
- [ ] Každá mačka má vlastnú nasadenú výbavu; predmety sa dajú presúvať
- [ ] Materiály: chlpy, nite, rybie šupiny, kovové skrutky (z máp podľa témy)
- [ ] Bezpečnosť uloženia: verzia profilu, migrácia charmov na talizmany, záloha

**Technika (keď sa do toho pustíme):**
- [ ] `data/items.json` (základné predmety, sety, unikáty), `data/affixes.json`
- [ ] `scripts/progression/items.gd` (generovanie, hodnoty), `scripts/ui/inventory_panel.gd`, `Profile` – sklad a výbava každej mačky
- [ ] Vzhľad: predmety sa kreslia na mačke (obojok, čiapka, topánočky) – aspoň obojok, čiapka a vesta
- [ ] Testy: generovanie 10 000 predmetov bez chýb, uloženie/načítanie, migrácia starého profilu

## Viac obsahu než konkurencia (cieľ)

- [ ] Mapy: dnes 7 (z toho 5 s terénom: stromy, múriky, ulička, príliv, pásy) → cieľ **12+**: Pivnica-bludisko, Les (stromy hustejšie, rúbanisko), Kanál (úzke chodby, voda), Cintorín (náhrobky, hmla), Vlak (ide len doprava, vagóny), Zasnežené mesto (ľad, kĺzanie)
- [ ] Questy: dnes 91 questov a krokov príbehov → cieľ **150+**; nové typy krokov: únik pred niečím, ochrana pohyblivého cieľa, hádanka (spínače v poradí), preteky na čas, stealth v tme
- [ ] Bossovia: dnes 40 → cieľ 60, každý s aspoň 2 špeciálnymi útokmi (otestovať boss rushom)
- [ ] Zbrane: dnes 16 základných + evolúcie → cieľ 30
- [ ] Mačky: dnes 11 + 2 tajné → cieľ 20

## Fáza 3 – Grafika a zvuk

- [ ] Sprity aj pre nábytok, podlahy, zbrane a projektily (teraz sú kreslené vektorovo)
- [x] Animácia smrti (nepriateľ sa sploští, vyskočí, otočí a zbledne) a hviezdička pri kritickom zásahu
- [x] Obrázok v hlavnom menu (nočné mesto, mesiac, mačky)
- [x] Ikona hry: Micina hlava v pixel-arte (tools/gen_icon.py); .ico pre .exe pri exporte
- [x] Viac zvukov: rev bossov, mňauknutie pri level-upe, pišťanie zlatej myši, trblietanie šampióna, praskanie iskier, hrom, cinkanie mincí

## Fáza 4 – Pred vydaním

- [x] Dev panel (F1), ladiaci riadok a všetky prepínače (`--...`) fungujú len v ladiacej verzii; vydaná verzia ich ignoruje
- [ ] Export: samostatný Windows `.exe`, otestovať na inom počítači
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

## Ako pracujeme

- Každý väčší krok = commit; na GitHub pushujeme, keď povieš.
- Pred commitom vždy prejdú testy: `bash tools/run_checks.sh`.
- Testovacie behy nikdy neukladajú tvoj profil (`--bot`, `--ui-test`, `--no-save`).
- Dev nástroje sú v poriadku počas vývoja, pred vydaním ich odstránime.
