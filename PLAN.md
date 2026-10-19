# Plán – Cat Survivors

Živý zoznam toho, čo je hotové, čo robíme teraz a čo príde. Po každom kroku
ho aktualizujeme: hotové odškrtneme `[x]`, nové nápady pridáme do Zásobníka.

Naposledy aktualizované: 18. 10. 2026 (príbehy, achievementy, Továreň)

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
- **Questy:** 34 príbehov (3 na každú mapu, 3 cez všetky mapy, 10 samostatných) s voľbami a trvalými zmenami máp, záchrany a súboje mačiek, príbehový quest na každej mape, vedľajšie úlohy.
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
