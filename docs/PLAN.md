# 🗡️ PLAN GRY

> **Wersja 2** · 12.10.2026 · Pomysły i lore mają pierwszeństwo przed starym planem.
> Plan zmieniamy tylko świadomie. Każdy nowy pomysł trafia do `POMYSLY.md`.
> Nazwy własne pochodzą z dokumentu lore i są propozycjami. Zmieniamy je wyłącznie na polecenie autora.

---

## 🎯 W jednym zdaniu

Wyrzucony z drużyny poszukiwacz przygód, wyszkolony przez emerytowanego mistrza gildii, dostaje od zmarłego mentora wiedzę o bogach i **System**. Schodzi sam do lochów, rozwija gildię i buduje swoją pozycję w świecie, który żyje także bez niego.

---

## 🧱 Fundamenty

| Element | Ustalenie |
|---|---|
| Gatunek | Roguelike i budowanie gildii, w fabularnym świecie RPG |
| Walka | W czasie rzeczywistym, bez tur |
| Silnik | Godot 4.7, GDScript |
| Rdzeń gry | Pętla: gildia ↔ miasto → loch → powrót do miasta → wydarzenia |
| Miasto | Ciągły obszar 5 × 7 rozmiarów pokoju lochu; kamera pokazuje fragment i podąża za graczem |
| Zakres na teraz | Startowa część Valdorii i gildia gracza, nie całe królestwo ani imperium |
| Zasada pracy | Etapami. Następną fazę zaczynamy dopiero, gdy poprzednia działa i jest grywalna |

---

## 📜 Fabuła

| Wiek | Wydarzenie |
|---|---|
| 12 | Bohater zostaje poszukiwaczem przygód |
| 12–15 | Przechodzi od drużyny do drużyny, nigdzie nie chcą go na stałe |
| 16 | Dołącza do znanej drużyny, której przywódcą jest **Cedric Vane**. Traktują go jak maskotkę |
| po sławie | Drużyna zastępuje go silniejszym członkiem, wyrzuca go i obraża |
| ok. 16–18 | W **Valdorii** poznaje **Edriana Vossa**, emerytowanego mistrza gildii. Przez około półtora roku uczy się walki i przetrwania |
| dzień przed 18. urodzinami | Mentor umiera. We śnie bohater trafia do **Aetherionu**, gdzie dusza Edriana opowiada o swojej przeszłości, o bogach i o **Systemie** |
| 18+ | Zaczyna się właściwa rozgrywka |

Edrian kiedyś służył jednemu z bogów. Któremu, ustala autor (patrz „Decyzje do podjęcia”).

---

## 🌍 Świat: Eryndor

| Miejsce | Opis |
|---|---|
| **Eryndor** | Główny kontynent |
| **Aetherion** | Kraina pomiędzy światem żywych a domenami bogów |
| **Valdoria** | Miasto startowe i siedziba Wielkiej Gildii |
| **Góry Grzmiącego Szczytu** | Region górniczy, kopalnie i podziemne miasta |
| **Szmaragdowa Knieja** | Pradawny las pełen magii i niebezpiecznych stworzeń |
| **Ruiny Ashenfall** | Pozostałości po upadłym imperium |
| **Merovia** | Republika kupiecka |
| **Ziemie Wyklętych** | Niebezpieczny region poza kontrolą królestw |

Na początku gra pokazuje tylko okolicę startową. Reszta świata dochodzi etapami (patrz „Fazy”).

---

## ⚡ Bogowie

| Bóg | Domena |
|---|---|
| **Avaros** | Wojna i siła |
| **Elyra** | Wiedza i magia |
| **Nyxara** | Cień i podstęp |
| **Sylvara** | Życie i natura |
| **Morveth** | Śmierć i dusze |
| **Solther** | Porządek i przysięgi |
| **Vael** | Chaos i zmiany |

**Zasady:**
- Każdy bóg ma osobowość, cele, wyznawców i własny stosunek do śmiertelników.
- Relacje z bogami wpływają na rozgrywkę: błogosławieństwa, umiejętności i zadania albo klątwy, utrata bonusów i dodatkowi przeciwnicy.
- Bogowie **nie są tylko systemem bonusów**: pamiętają decyzje gracza, reagują na nie i mają własne interesy.
- Ich cele mogą ze sobą kolidować, więc pomoc jednemu może zepsuć relację z innym.

---

## 🔁 Główna pętla

1. **Gildia**: zlecenia, rekrutacja, kupowanie pokoi i budynków za złoto
2. **Loch**: sam albo z drużyną, walka na żywo, łup
3. **Powrót**: doświadczenie idzie w System, materiały w rzemiosło i wielkie dzieła
4. **Wydarzenia**: rozmowy z NPC, ataki na wioskę, zmiany w świecie

---

## ⚙️ Systemy

### Walka i wybór klasy
Walka w czasie rzeczywistym: ruch, atak, unik (dash), 1 lub 2 umiejętności z cooldownem. Wrogowie mają czytelne zapowiedzi ataku.
Na początku gry gracz wybiera klasę: Wojownik, Rycerz, Mag, Kapłan, Łowca, Inżynier, Kowal albo Alchemik. W tej wersji wybór zapisuje i pokazuje klasę; unikalne umiejętności klasowe nie są jeszcze dodane.

### System (rozwój postaci)
Statystyki, umiejętności i drzewko w jednym oknie. Działa tylko na gracza.
Kierunek docelowy to duże drzewko w stylu Path of Exile: wiele ścieżek, wybory wymagające poświęceń, synergie z ekwipunkiem i błogosławieństwami, rzadkie potężne węzły. Błędy w rozwoju mają konsekwencje, ale nie niszczą postaci bezpowrotnie.
Na start: Siła, Wytrzymałość, Zręczność.

### Gildia, rangi i członkowie
- Pokoje gildii kupowane za złoto (tabela niżej).
- Członkowie: AI pomaga w walce, każdy ma 1 lub 2 cechy charakteru. **Kto zginie, znika na zawsze.**
- Rangi odblokowują trudniejsze lochy i lepsze zlecenia (system rang czeka na decyzję, patrz niżej).

### Relacje z NPC (punkty od -100 do 100)

| Kto | Dobra relacja | Zła relacja |
|---|---|---|
| Burmistrz | zniżki, zlecenia, zgody na budynki | podatki, blokada rozbudowy |
| Członkowie z ego | lojalność, bonusy | odchodzą, kradną, stają się wrogami |
| Losowi przybysze | rzadkie przedmioty, rekruci | zemsta, gorsza reputacja |

NPC pamiętają działania gracza, mogą odmówić współpracy z powodu reputacji i zmieniać cele oraz miejsce pobytu.

### Rozmowy z ukrytym czasem
Każda rozmowa ma limit czasu na odpowiedź, którego gracz nie widzi. Gdy minie, NPC uznaje, że go olewasz, i relacja spada. Czas zależy od charakteru: duże ego to krócej, spokojny to dłużej. Gra nie pauzuje w trakcie rozmowy.

### Wielkie dzieła
Posągi i ołtarze z bonusem dla każdego, kto ich użyje (np. +2% HP po modlitwie). Bardzo drogie, może je robić tylko gracz. Powiązanie z bogami to pomysł do potwierdzenia.

### Ataki na wioskę
Duża arena z falami wrogów, co kilka dni. Gildia broni wioski.

### Ekwipunek i rzemiosło
Broń, zbroje i akcesoria mają wytrzymałość i wymagają napraw. Jakość zależy od materiałów, umiejętności i wykonania. Profesje (kowalstwo, alchemia i inne) mają własne ścieżki, a minigry wpływają na jakość przedmiotów.
W kodzie już działa udźwig i plecak z wagą przedmiotów.

### Dynamiczny świat
Małe wydarzenia (napady, zaginięcia, konflikty handlowe) pojawiają się często. Duże wydarzenia (przebudzenie smoka, wojny, upadek królestwa) mniej więcej co pięć lat czasu gry i mają trwałe skutki. Świat nie stoi w miejscu, gdy gracz nie bierze udziału.

---

## 🏠 Pokoje gildii (ceny przykładowe)

| Pokój | Koszt | Odblokowuje | W kodzie |
|---|---|---|---|
| Sala główna | 0 | tablica zleceń, rekrutacja | ✅ |
| Kuźnia | 150 | rzemiosło | – |
| Magazyn | 200 | +10 udźwigu | ✅ |
| Koszary | 250 | więcej członków | – |
| Lecznica | 300 | pełne leczenie po dniu | ✅ |
| Kaplica | 800 | wielkie dzieła | – |

---

## 🗺️ Fazy

Status „mechanika zrobiona” oznacza, że dana funkcja działa już w kodzie; nie oznacza ukończenia całej fazy.

- [x] **Faza 1 (MVP)**: loch z walką na żywo, chodzona sala gildii, złoto i zapis gry, proste okno Systemu, 1 klasa
  - Zrobione: `game_state.gd` (autoload i zapis), `balance.gd`, `guild.tscn`/`guild.gd`, `system_window.gd`, walka na żywo w `main.gd` (atak, unik, Cięcie wirowe, zapowiedzi ataku), portal powrotny, plecak z wagą.
  - [x] **Mechanika zrobiona:** poprawki po teście: plecak odświeża się po otwarciu, schody i portal działają na **F**, nocleg jest płatny, zamknięcie gry podczas wyprawy jest traktowane jak śmierć.
  - [x] **Mechanika zrobiona:** sala gildii jest chodzona; tablica, członkowie, nocleg, rozbudowa, burmistrz i wyjście do lochu są stanowiskami interakcji.
- [x] **Faza 1.5 (Świat i klasa)**: intro z lore (18. urodziny, Aetherion), wybór klasy początkowej, rozbicie `main.gd` na kilka skryptów
  - [x] **Mechanika zrobiona:** rozbicie `main.gd` na skrypty `enemy_ai.gd`, `room_view.gd` i `hud.gd`.
  - [x] **Mechanika zrobiona:** unik (dash) z kierunkiem, czasem trwania i cooldownem.
  - [x] **Mechanika zrobiona:** intro przedstawia wyrzucenie z drużyny, szkolenie przez Edriana, Aetherion i rozpoczęcie gry w wieku 18 lat.
  - [x] **Mechanika zrobiona:** wybór i zapis klasy początkowej; unikalne umiejętności klasowe pozostają na później.
- [x] **Faza 2 (Członkowie)**: AI w lochu, permadeath, cechy, rangi, tablica zleceń
  - [x] **Mechanika zrobiona:** rekrutowanie członków z losowymi statystykami, rangą początkową i 1–2 cechami.
  - [x] **Mechanika zrobiona:** wybór członków do drużyny, sojusznicze AI w lochu i walka z wrogami.
  - [x] **Mechanika zrobiona:** śmierć członka usuwa go z drużyny i uniemożliwia ponowne użycie; poległy pozostaje widoczny na liście.
  - [x] **Mechanika zrobiona:** tablica zleceń, przyjmowanie zlecenia, śledzenie postępu i odbieranie nagrody.
  - [x] **Mechanika zrobiona:** doświadczenie członków za ukończone piętra lochu; awans zwiększa ich atak i maksymalne HP.
  - [x] **Mechanika zrobiona:** doświadczenie gildii za odebrane zlecenia, progi rang oraz ograniczenie rangi dostępnych zleceń rangą gildii.
- [ ] **Faza 3 (Relacje)**: burmistrz, rozmowy z wyborami i ukrytym czasem, bunt członków z ego
- [ ] **Faza 4 (Obrona i dzieła)**: ataki na wioskę, wielkie dzieła, kaplica, rzemiosło w kuźni
- [ ] **Faza 5 (Bogowie i rozwój)**: błogosławieństwa i klątwy, pełne drzewko, kolejne klasy, dawna drużyna jako rywal
- [ ] **Później**: kolejne miasta i krainy, polityka, ukryte organizacje, ekonomia, wielkie wydarzenia co pięć lat, rozgałęziona fabuła i zakończenia, relacje romantyczne, własne imperium (nieruchomości, pracownicy, wpływy)

Kolejność faz od 1.5 wzwyż to propozycja do zatwierdzenia.

---

## 🚫 Na razie nie

- Własne imperium i zarządzanie biznesami
- Cały otwarty świat naraz
- Realistyczna ekonomia i handel
- Wiele klas naraz
- Walka turowa
- Wszystkie miasta i krainy jednocześnie

---

## ❓ Decyzje do podjęcia

1. **Własna gildia a Wielka Gildia.** Jak się mają do siebie?
   - **A.** Dwie osobne rzeczy: własna gildia gracza rośnie w Dębowej Dolinie, a rangi to jego osobista ranga w Wielkiej Gildii.
   - **B.** Rangi dotyczą własnej gildii gracza, a Wielka Gildia jest tłem i konkurentem.
   - **C.** Gracz zaczyna jako członek Wielkiej Gildii, a własną zakłada później.
2. **Rangi.** Zostają litery F–S z obecnymi nazwami wyświetlanymi w grze.
3. **Któremu bogu służył Edrian Voss?**
4. **Imię bohatera i nazwa jego gildii.** W kodzie tymczasowo jest nazwa „Odrzuceni”.
5. **Umiejętności klasowe.** Na razie nie dodajemy osobnych umiejętności dla klas; wrócimy do nich później.
6. **Czy wielkie dzieła są ołtarzami konkretnych bogów?**

---

## 🧭 Zasady pracy

- Nie wymyślamy nazw własnych bez zgody autora. Brakujące nazwy zapisujemy jako pytania.
- Przy ważnej decyzji projektowej Claude przedstawia opcje i czeka na wybór.
- Każdy nowy pomysł trafia do `POMYSLY.md`. Po zakończonej fazie wybieramy stamtąd 1 lub 2 rzeczy.
- Wszystkie ceny i liczby żyją w `balance.gd`.

---

## 🧩 Architektura

| Plik | Rola |
|---|---|
| `game_state.gd` | Autoload: złoto, statystyki, pokoje, dzień, ekwipunek. Zapis w `user://save.json` |
| `balance.gd` | Wszystkie ceny i liczby w jednym miejscu |
| `guild.tscn`, `guild.gd` | Chodzona sala gildii: ruch, stanowiska interakcji, rozbudowa i nocleg; drzwi prowadzą do miasta |
| `city.tscn`, `city.gd` | Duży, chodzony obszar Valdorii (5 × 7 pokoi lochu) z kamerą śledzącą gracza, dzielnicami, rynkiem, karczmą, kaplicą, stajnią, ratuszem, kowalem, gildią, rzeką i przechodnim mostem |
| `system_window.gd` | Okno Systemu (statystyki) |
| `main.tscn`, `main.gd` | Loch: pętla gry, walka gracza, pokoje i piętra |
| `dungeon.gd` | Generator pięter i pokoi |
| `inventory.gd`, `items.gd` | Plecak z wagą i przedmioty |

Planowane po rozbiciu `main.gd` w Fazie 1.5: `enemy_ai.gd` (wrogowie), `room_view.gd` (rysowanie pokoju), `hud.gd` (interfejs). W Fazie 2 do tego dołączy skrypt sojuszników w tym samym stylu.

---

## 🔄 Zmiany względem wersji 1

- Bohater: wiek startu 18 lat (wcześniej 25), nowa historia z mentorem i Aetherionem.
- Klasa głównego bohatera: wybierana na początku gry spośród Wojownika, Rycerza, Maga, Kapłana, Łowcy, Inżyniera, Kowala i Alchemika.
- Dodane: świat Eryndor, siedmiu bogów, dynamiczny świat, drzewko w stylu Path of Exile, rzemiosło z wytrzymałością, plan późniejszego imperium.
- Zachowane: pętla gildia → loch, walka na żywo, permadeath członków, rozmowy z ukrytym czasem, wielkie dzieła, ataki na wioskę.
