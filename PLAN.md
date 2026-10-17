# Plán – Cat Survivors

Živý zoznam toho, čo je hotové, čo robíme teraz a čo príde. Po každom kroku
ho aktualizujeme: hotové odškrtneme `[x]`, nové nápady pridáme do Zásobníka.

Naposledy aktualizované: 17. 10. 2026 (nové mapy Supermarket a Prístav)

---

## Kde sme

Hra je hrateľná od menu po koniec noci na 6 mapách:

- **Mapy:** Byt → Pivnica → Záhrada → Strecha → Supermarket → Prístav (každá sa odomkne porazením
  finálneho bossa predchádzajúcej), každá s vlastnou podlahou, nábytkom,
  nepriateľmi, bossmi, pascami a hudbou.
- **Mačky:** 10 hrateľných (Mica, Luna, Snehulka, Mrňa, Tiger, Barón,
  Ďatelinka, Bruno, Tučko, Kapitán) + 2 tajné (anjel, diabol).
- **Boj:** 9 zbraní s evolúciami, 10 pasív, kritické zásahy a šťastie,
  čísla poškodenia, otrasy.
- **Priebeh noci:** rozpočet nepriateľov s krivkou intenzity, oddychy,
  udalosti (kruhy, roje), elity, bossovia, finálny boss, mačacie dvierka na
  útek, série výhier.
- **Questy:** záchrany a súboje mačiek, vedľajšie úlohy, príbehový quest v byte.
- **Meta:** zlato, obchod s vylepšeniami, charmy, artefakty, dlhodobé ciele, kniha questov.
- **Tajomstvo:** anjel ťa na streche po 15. minúte s malou šancou zachráni;
  po dvoch záchranách príde diabol, ktorý zabije isto.
- **Technika:** menu, nastavenia, pauza, SK/EN, pixel-art sprity, 36
  automatických testov (`tools/run_checks.sh`), spúšťače v `Spustit\`.

## Teraz

- [ ] Vyskúšať novú obtiažnosť, anjela a diabla (`Spustit\4 Test anjel a diabol.bat`) a dať spätnú väzbu
- [x] Pushnúť posledné commity na GitHub – odteraz sa pushuje po každom otestovanom kroku

## Fáza 1 – Doladenie podľa hrania

Najprv dotiahnuť to, čo už máme, kým pridáme ďalší obsah.

- [ ] Obtiažnosť: doladiť rast poškodenia a HP nepriateľov podľa tvojich hier (každá mapa zvlášť)
- [ ] Začiatok neskorších máp: mačka bez vylepšení zomiera pri prvom bossovi (3. min) v Pivnici a Záhrade – zvážiť ľahší štart
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
- [ ] Kroky – hotové: stopy, naháňačka, nosenie (čas, spomalenie, max. zásahov), zbieranie (kapacita, strážcovia, z nepriateľov), zóny (poradie, čas, blesky), obrana (viac miest), boss (bez liečenia, na čas); chýba: eskorta, voľba, pasce, tma. Pôvodne: stopy, naháňačka, nosenie (časový limit, spomalenie, max. zásahov), zbieranie (kapacita, veci zo strážcov alebo z nepriateľov), zóny (poradie, časový limit, blesky), obrana (miesto s HP, viac miest naraz), boss (bez liečenia, na čas), eskorta (viac mačiek, pomalá), voľba, zabitia pascami, tma s lampášom
- [ ] Postavy, ktoré hovoria (riadky pri začiatku a konci kroku)
- [ ] Trvalé zmeny máp: teplý kotol (liečenie), strašiak (odháňa vrany), nabitá anténa (strieľa), maják (odháňa medúzy), Bruno a Rex ako spojenci

Byt:
- [x] Zlodej granúl (odmena artefakt Plná miska): 5 stôp → dobehni Roombu → kľúčik do kuchyne do 60 s → ubráň špajzu
- [x] Ponožkový kráľ: 6 ponožiek do koša (nesieš max. 2) → Ponožkový kráľ
- [x] Mesačné okná (anjel potom chodí 2× častejšie): vydrž v 3 mesačných lúčoch → prvá stopa anjela

Pivnica:
- [ ] Potkania pevnosť: upchaj 3 diery → chyť posla → tunel s pascami → potkaní generál
- [ ] Pavúčia sieť: vysloboď 4 mole → voľba: poraziť kráľovnú alebo jej dať mole
- [ ] Oprava kotla: 3 súčiastky od elít → zanes ku kotlu → kotol odteraz lieči

Záhrada:
- [ ] Trpasličia vojna: ubráň záhon → tunel krtkov → voľba krtkovia/trpaslíci
- [ ] Med pre Ďatelinku: 3 kvety k úľu (max. 3 zásahy) → sršňa kráľovná
- [ ] Strašiak ožíva: klobúk, šál, tekvica z vrán → postav strašiaka → odháňa vrany

Strecha:
- [ ] Brunova skúška: 5 komínov za 60 s → holubí cisár bez liečenia → súboj na úsvite → Bruno spojenec
- [ ] Búrková anténa: nabi 3 antény počas bleskov → anténa strieľa
- [ ] Ukradnutý obojok: prenasleduj mývala → prehľadaj 4 kontajnery

Supermarket:
- [ ] Tučkov nákupný zoznam: 5 vecí k pokladni pred zatvorením
- [ ] Výpadok prúdu: tma → 3 ističe v správnom poradí, strážny robot bráni
- [ ] Rexov rešpekt: 3 noci kosť Rexovi + ochrana pred vozíkmi → Rex sa po boji pridá

Prístav:
- [ ] Kapitánova loď: plachta, kormidlo, lano → oprava → ubráň loď 90 s
- [ ] Maják: olej z 3 sudov (pomalšie s nákladom) → maják odháňa medúzy
- [ ] Pirátsky poklad: 3 kúsky mapy od pirátov → vykopať → chobotnica

Cez všetky mapy:
- [ ] Cesta domov: Mica hľadá starú majiteľku; každá mapa kapitola, predmet otvorí ďalšiu, koniec loďou domov
- [ ] Mačacia rodina: každá zachránená mačka má prosbu na inej mape → hostina, bonus pre všetky mačky
- [ ] Kto za tým stojí?: súčiastka s logom z každého finálneho bossa → tajná 7. mapa

Samostatné questy:
- [ ] Nočný kuriér (list cez mapu za 90 s, max. 3 zásahy)
- [ ] Stratené mačiatka (3 mačiatka k mame)
- [ ] Majster pascí (30 zabití pascami)
- [ ] Požiar (zhas šíriace sa ohniská, kým sa nerozšíria)
- [ ] Zlatá horúčka (chyť zlatú myš 3×, zakaždým rýchlejšiu)
- [ ] Tri misky (ubráň 3 misky naraz)
- [ ] Lampáš (v tme dones lampáš k východu)
- [ ] Súboj na čas (poraz súpera do časového limitu)
- [ ] Túlavý obchodník (zlato alebo 3 rybičky – voľba)
- [ ] Posledná prechádzka (stará mačka na obľúbené miesto)

Potom: šablónové questy mačiek a počítadlá presunúť do časti Úspechy.

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

- Denný/týždenný beh s pevným seedom
- Kozmetika pre mačky (obojky, klobúky) za zlato
- Achievementy

## Ako pracujeme

- Každý väčší krok = commit; na GitHub pushujeme, keď povieš.
- Pred commitom vždy prejdú testy: `bash tools/run_checks.sh`.
- Testovacie behy nikdy neukladajú tvoj profil (`--bot`, `--ui-test`, `--no-save`).
- Dev nástroje sú v poriadku počas vývoja, pred vydaním ich odstránime.
