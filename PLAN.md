# Plán – Cat Survivors

Živý zoznam toho, čo je hotové, čo robíme teraz a čo príde. Po každom kroku
ho aktualizujeme: hotové odškrtneme `[x]`, nové nápady pridáme do Zásobníka.

Naposledy aktualizované: 16. 10. 2026 (fáza 2 rozbehnutá)

---

## Kde sme

Hra je hrateľná od menu po koniec noci na 4 mapách:

- **Mapy:** Byt → Pivnica → Záhrada → Strecha (každá sa odomkne porazením
  finálneho bossa predchádzajúcej), každá s vlastnou podlahou, nábytkom,
  nepriateľmi, bossmi, pascami a hudbou.
- **Mačky:** 8 hrateľných (Mica, Luna, Snehulka, Mrňa, Tiger, Barón,
  Ďatelinka, Bruno) + 2 tajné (anjel, diabol).
- **Boj:** 9 zbraní s evolúciami, 10 pasív, kritické zásahy a šťastie,
  čísla poškodenia, otrasy.
- **Priebeh noci:** rozpočet nepriateľov s krivkou intenzity, oddychy,
  udalosti (kruhy, roje), elity, bossovia, finálny boss, mačacie dvierka na
  útek, série výhier.
- **Questy:** záchrany a súboje mačiek, vedľajšie úlohy, príbehový quest v byte.
- **Meta:** zlato, obchod s vylepšeniami, charmy, dlhodobé ciele.
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
- [ ] Výkon: skontrolovať FPS v skutočnej hre pri 300+ nepriateľoch, prípadne optimalizovať
- [ ] Príbehové questy aj pre Pivnicu, Záhradu a Strechu (teraz má príbeh len Byt – obojok)
- [ ] Hudba: tvoja spätná väzba na skladby jednotlivých máp (ja ich nepočujem)
- [ ] Prejsť všetky texty v slovenčine (gramatika, rod mačiek)

## Fáza 2 – Nový obsah

- [x] Kniha questov (štýl Halls of Torment): 17 línií, 57 krokov – mačací život, miesta, tajomstvá (Q vo výbere mačky, tlačidlo v menu)
- [x] Tajomstvá: anjel mačka sa odomkne 4 stránkami denníka (jedna ukrytá na každej mape), diabol mačka questom Diablova zmluva
- [x] Denník: questy, ciele a bestiár na jednom mieste (tlačidlo Denník, pri výbere mačky Q / G / J)
- [x] Nové zbrane: Myška na kľúčik, Pavučina, Kropič, Anténa (každú odomkne prejdenie mapy) + evolúcie, pasívy Dlhý spánok a Rýchly hod
- [x] Nové správanie: prachový mrak sa rozpadá, pľujúci pavúk a žaba strieľajú, útočná čajka sa vrhá; bossovia privolávajú pomocníkov
- [ ] Úplne noví bossovia (napr. jeden stredný boss na mapu s vlastným útokom)
- [x] Viac charmov a cieľov: 5 nových charmov (štvorlístok, pavúčie vlákno, pierko vetra, polmesiac, zlatý tesák), 6 nových cieľov; zoznam cieľov sa dá posúvať
- [x] Bestiár: mačky, nepriatelia podľa máp (počet porazených, popis), zbrane s evolúciami, pasívky; neobjavené ako ???
- [ ] Nové režimy: nekonečná noc po víťazstve, výzvy s obmedzeniami

## Fáza 3 – Grafika a zvuk

- [ ] Sprity aj pre nábytok, podlahy, zbrane a projektily (teraz sú kreslené vektorovo)
- [ ] Animácie smrti nepriateľov a lepšie efekty zásahov
- [ ] Titulná obrazovka a ikona hry
- [ ] Viac zvukov (kroky, mňaukanie pri level-upe, zvuky bossov)

## Fáza 4 – Pred vydaním

- [ ] Odstrániť dev panel (F1) a ladiace prepínače z vydanej verzie
- [ ] Export: samostatný Windows `.exe`, otestovať na inom počítači
- [ ] Ovládanie: otestovať gamepad, umožniť zmenu kláves
- [ ] Viac jazykov (napr. čeština, nemčina)
- [ ] Návod pri prvej hre (ovládanie, čo sú dvierka, charmy, questy)
- [ ] Záloha a bezpečné načítanie profilu pri zmenách verzií

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
