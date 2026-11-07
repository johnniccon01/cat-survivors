# Psie štvrte – návrh druhej štvrte

Stav: **pripravené, nehrateľné** (7. 11. 2026). Hotová je mapa štvrte (panel `DogDistrictPanel`, tlačidlo „Vlak na východ“ na mape prvej štvrte), texty všetkých miest vo všetkých jazykoch a príbeh, ktorý tam vedie. Noci, nepriatelia a bossovia tejto štvrte sa robia v ďalšej časti.

## Prečo tam mačky idú (príbeh)

1. V prvej štvrti nosí každý finálny boss čip R-3000 (príbeh **Kto za tým stojí?**). Po porazení Robo-vysávača ovládač pípa ďalej.
2. **Druhý signál** (`WHO_IS_BEHIND_2`, po dokončení prvého): čipy ostatných bossov štvrte majú odtlačok psej labky. Seržant Buldog v Depe vyhodí lístok „Psie štvrte, jednosmerný“. Všetkých bossov a stroje poslal **Generál** – nemecká doga z Psích štvrtí. Chce vyhnať mačky z každého mesta („Operácia Čisté mesto“).
3. **Rozkazy z východu** (Depo): dobermani nosia Generálove rozkazy „Mačky musia z mesta preč“.
4. **Lístok na východ** (`TICKET_EAST`, otvorí sa po výhre v Depe): rozbehnúť starú parnú lokomotívu (Depo), prepnúť návestidlá na Stanici, ubrániť lokomotívu, poraziť Seržanta Buldoga. Odmena: príznak `train_east` → na mape štvrte sa objaví tlačidlo **Vlak na východ**.
5. **Rodina sa rozrastá** končí Barónovou pozvánkou: v Psích štvrtiach žijú mačky, ktoré potrebujú pomoc (Tieň v útulku, Iskra na hasičskej stanici).
6. V Psích štvrtiach: mačky nechcú vojnu – chcú Generála zastaviť a uzavrieť mier. Postupne získajú na svoju stranu psov (Ruby), mývala (Lotor) a dve mačky. Na konci Generálova búda: Generál nie je zlý, len sa bojí, že mu mačky zoberú mesto. Mier = koniec druhej štvrte.

## Cesta tam

- Vlak z Depa (lokomotíva stojí v depe na mape prvej štvrte). Prvá noc druhej štvrte začína na **Nákladnej stanici**.
- Mapa druhej štvrte je samostatná (rovnaký systém ako prvá: miesta, cesty, hmla, značky úloh). Medzi štvrťami sa prepína vlakom; v prvej štvrti sa dá hrať ďalej.
- Domovom v druhej štvrti je Nákladná stanica (domáce bonusy, úschovňa výbavy ako v Byte).

## 16 miest (poradie odomykania)

| # | Miesto | Prostredie a špecialita | Psí boss (finálny) | Kto sa pridá |
|---|--------|------------------------|--------------------|--------------|
| 1 | Nákladná stanica | debny, žeriavy; posunované vagóny | Bernardín, prednosta stanice | – |
| 2 | Útulok | rady kotercov; zatvárajúce sa dvierka kotercov (pasce) | Starý baset, správca | **Tieň** (čierna mačka) – oslobodíš ju v queste |
| 3 | Psí park | lietajúce frisbee a tenisky (strely naprieč mapou) | Labrador, Kráľ aportu | **Ruby** – prvý hrateľný pes, po súboji v parku |
| 4 | Smetisko | kopy haraburdia, žeriav s magnetom zhadzuje vraky | Kosť, rotvajler | **Lotor** (mýval) – po súboji na Smetisku |
| 5 | Psí salón | fény (fúkajú hráča), bublinky, oblaky voňaviek (spomaľujú) | Pudlová kráľovná | – |
| 6 | Pekáreň piškót | horúce pece, pásy s piškótami | Jazvečík pekár | – |
| 7 | Dostihová dráha | dráhy chrtov (ako vlak, ale v kruhu) | Blesk, chrt | – |
| 8 | Hasičská stanica | striekajúce hadice (odhadzujú), sirény | Dalmatín, veliteľ hasičov | **Iskra** (hasičská mačka) |
| 9 | Policajná stanica | svetlomety (kto je v svetle, toho prenasledujú), klietky | Inšpektor ovčiak | – |
| 10 | Veterinárna klinika | injekcie (krátko omráčia), golier hanby | Čivava sestrička | – |
| 11 | Hrádza | prúd rieky, plávajúce klády | Novofundlanďan, hrádzny | – |
| 12 | Zasnežený kopec | ľad (kĺzanie), sane, snehové gule | Vodca huskyov | – |
| 13 | Výcvikové ihrisko | prekážky a tunely, píšťalka zrýchli psov | Inštruktor boxer | – |
| 14 | Výstava psov | reflektory, porotcovia dávajú bonus za kombá | Afgánska diva | – |
| 15 | Kasárne | pochodujúce šíky psov, tank tenisiek | Plukovník mastif | – |
| 16 | Generálova búda | všetko naraz, hrad z búd | **Generál** (nemecká doga) | – (mier) |

Kód a texty: `scripts/ui/dog_district_panel.gd` (`PLACES`), texty `DOGS_<ID>_NAME/_DESC/_BOSS/_FRIEND`.

## Nepriatelia

Hlavne noví (psí svet), niekoľko starých na začiatok:

- **Starí**: krtkovia, potkany, holuby, vrany, mývaly (na Smetisku), túlavé psy a dobermani z Depa.
- **Noví**: šteňatá (rýchle, slabé, vo svorkách), blchy (malé roje, skáču), tenisky (odrážajú sa), pískacie hračky (pri zásahu zvolajú okolie), kosti na žuvanie (kotúľajú sa), frisbee (letia rovno), jazvečíky (dlhé, pomalé, veľa zdravia), hydranty (striekajú), drony psej polície, snehuliaci, chrty (bleskové výpady), pudlie pompóny, psí lapači (sieť spomalí), bubny kasární (zrýchlia okolie).
- **Bossovia uprostred noci** (2 na mapu, ako v prvej štvrti) + **finálny psí boss** každého miesta (tabuľka vyššie), každý aspoň s 2 špeciálnymi útokmi; noví bossovia môžu dostať nové útoky: „aport“ (hodí loptu a beží po ňu), „vytie“ (privolá svorku), „hrabanie“ (jamy v zemi).

## Nové postavy (druhá štvrť)

| Postava | Druh | Ako sa odomkne | Zbraň / inštinkt (návrh) |
|---------|------|----------------|--------------------------|
| Ruby | pes (border kólia) | poraz ju v Psom parku (3. mapa) | Frisbee (bumerang) · inštinkt: každých 20 s zoženie nepriateľov do kopy |
| Lotor | mýval | poraz Kosť na Smetisku (4. mapa) | Hádzanie haraburdia · inštinkt: zabití nepriatelia občas pustia predmet |
| Tieň | čierna mačka | osloboď ju v Útulku (2. mapa, quest) | Tieňové pazúry · inštinkt: v tme silnejšia |
| Iskra | hasičská mačka | quest na Hasičskej stanici (8. mapa) | Vodná striekačka · inštinkt: pri nízkom zdraví ju ochladí (štít) |

Pes a mýval sa kreslia ako mačky s `"species": "dog"` / `"raccoon"` v `data/cats.json` (`cat_frame` v `tools/gen_sprites.py`: ovisnuté uši a ňufák, resp. maska a pruhovaný chvost). Hotové: Ruby (Pierková hračka, inštinkt Zaháňanie), Lotor (Hádzanie plechoviek, Hrabáč), Tieň (Ihla s niťou, Do tmy); Ruby a Lotor sa získajú súbojom, Tieň záchranou.

## Technika (na ďalšiu časť)

- `data/stages.json`: 16 nových nocí s kľúčom `"district": "dogs"`; mapa štvrte rozlíši štvrte podľa tohto kľúča (dnes je mapa jedna).
- `DistrictMap` dostane druhé mesto (`_build_dog_town`), `DogDistrictPanel.town()` je náčrt jeho rozloženia.
- Prepínanie štvrtí: tlačidlo „Vlak na východ / Vlak domov“, `Profile.district`.
- Domáci bonus, úschovňa a cintorín sú v každej štvrti zvlášť; zlato, výbava a talenty spoločné.
