# TODO – Naprawa gry (bez dodawania nowych funkcji)

> Cel: **stabilna, czytelna, spójna wersja** obecnego zakresu (Faza 1–2).
> Nie dodajemy nowych systemów – tylko naprawiamy to, co jest złe/duplikowane/niedokończone.

---

## 🔴 KRYTYCZNE (bugi blokujące / crashy)

- [x] **#1 `items.gd`: obsługa `tool_type: "acid"`** – receptura Alchemika tworzy kwas, ale `icon_index` i `use_crafted_tool` go nie obsługują
- [x] **#2 `quests.gd`: implementacja typu `"boss"`** – zdefiniowany w `balance.gd` (`QUEST_TYPES`), nieobsługiwany w generowaniu/opisie/postępie
- [x] **#3 `smith.gd`: `buy_item` automatycznie zakłada przedmiot** – może przekroczyć udźwig, stary ekwipunek ląduje w plecaku bez checka
- [x] **#4 `GameState.load_game()`: nadpisuje `message` po `abandon_run()`** – traci info o odzyskaniu z backupu
- [x] **#5 `GameState.die_in_dungeon()` / `abandon_run()`: nie czyści `active_quest`** – zlecenie zostaje „w trakcie” po śmierci

---

## 🟠 DUPILIKACJA KODU (refaktoryzacja → mniej błędów, łatwiejsze utrzymanie)

- [x] **#6 Wyciągnij `SystemController.gd` (autoload lub RefCounted)**
  - `system_input(keycode)` – identyczny w `guild.gd`, `main.gd`, `city.gd`
  - `system_tree_mode`, `system_cursor`, `draw` deleguje do `SystemWindow`
  - Usuń 3 kopie, zostaw 1 wywołanie

- [x] **#7 Wyciągnij `InventoryController.gd`**
  - `inventory_input`, `inventory_mouse_input`, `use_inventory_item` – 3 kopie (guild, dungeon, city)
  - `equip_from_pack`, `unequip_to_pack`, `add`, `can_carry` już są w `Inventory` – kontroler tylko UI/logika użycia

- [x] **#8 Usuń martwy kod**
  - `hud.gd` → `draw_inventory()` (23 linie, nieużywane)
  - `guild.gd` → `draw_onboarding` duplikuje logikę intro (OK, ale spójność)

---

## 🟡 LOGIKA / BALANS / EDGE-CASE'Y

- [ ] **#9 Cechy członków (`traits`) – tylko `ego` działa**
  - `brave`, `cowardly`, `loyal`, `greedy`, `calm`, `aggressive`, `intelligent`, `stupid` → dead data
  - Dodaj efekty: np. `greedy` = wyższy koszt rekrutacji, `loyal` = immunitet na bunt, `aggressive` = +atak, `cowardly` = ucieka przy niskim HP

- [ ] **#10 `AllyAI`: sojusznicy nie używają mikstur, nie leczą się, nie unikają**
  - Dodaj: autopickup mikstur, uzycie przy HP < 30%, prosty dash od wroga

- [ ] **#11 `EnemyAI`: wrogowie nie omijają przeszkód przy pościgu**
  - `move_circle(room, ..., false)` – `can_use_doors=false` blokuje też przeszkody
  - Rozdziel: `can_pass_doors` vs `can_pass_obstacles` lub A* na siatce 15×9

- [ ] **#12 `smith.gd` `has_crafting_capacity()` – błędne liczenie wagi**
  - Odejmuje wagę zużytych materiałów od *obecnego* udźwigu, ale nie uwzględnia, że materiały są w plecaku (waga już policzona w `total_weight()`)
  - Popraw: `GameState.inv.total_weight() - consumed_weight + output_weight` → `GameState.inv.total_weight() - consumed_weight + output_weight` (OK, ale `consumed_weight` liczy wagę *usuwanych* materiałów – to poprawne, sprawdź testowo)

- [ ] **#13 `GameState.crafting_gold_cost()` – zniżki tylko dla Kowala**
  - `smith_branch_a` + `smith_master_a` = -50% kosztu – OK, ale czy Inżynier/Alchemik mają swoje talenty na zniżki? (sprawdź `class_progression.gd` – nie mają)

---

## 🟢 UI / WIZUALNE / CZYTELNOŚĆ (magic numbers → config)

- [ ] **#14 Przenieś stale UI do `ui_constants.gd` (nowy plik)**
  - Rozmiary paneli, marginesy, czcionki, kolory, `SLOT_SIZE`, `GRID_ORIGIN`, `PANEL_SIZE`
  - Wszystkie `_draw` funkcje używają `UI_CONST.panel_width` itp.

- [ ] **#15 `room_view.gd`: atlas tileset lochu – weryfikacja `ATLAS_COLUMN_START`, `ATLAS_COLUMN_STEP`, `ATLAS_ROW_STARTS`**
  - Porównaj z `Pikselowy zestaw kafelków lochu fantasy.png` (180×180 per kafelek?)
  - Jeśli nie pasują – popraw indeksy w `draw_dungeon_tile`

- [ ] **#16 `city_ui.gd`: minimapa – skalowanie markerów**
  - `world_pos / city_size * map_rect.size` – sprawdź czy `CITY_SIZE` = `ROOM_SIZE * CITY_ROOMS` (720×3024?)
  - Brama (gate) na dole – czy marker widoczny?

- [ ] **#17 `system_window.gd`: drzewo talentów – ucina opisy**
  - `rect.size.x - 24` – dla wąskich paneli (mobile) tekst wykracza
  - Dodaj `wrap` / `autowrap` lub `clip` z tooltipem

- [ ] **#18 `inventory_window.gd`: plecak – scroll / paginacja**
  - `visible_start(cursor, item_count)` – OK, ale brak wskaźnika scrollbara
  - Dodaj pionowy scrollbar po prawej stronie gridu

- [ ] **#19 `hud.gd`: status chips (unik, umiejętność) – kolory dla daltonistów**
  - Tylko zielony/czerwony – dodaj ikony/tekst „GOTOWY” / „CD”

- [ ] **#20 `guild.gd`: kolizje z meblami – `hits_furniture()` promień `+56.0`**
  - Sprawdź czy postać nie wisi w ścianie / meblach
  - Dostosuj do rozmiarów spritów w `guild_furniture.png`

---

## 🔵 BRAKUJĄCE PLIKI (stuby by nie crashowały)

- [ ] **#21 `locations/city/places/tavern/tavern.gd`** – stub: `draw_overlay` z „W budowie”, `interact` → wiadomość
- [ ] **#22 `locations/city/places/chapel/chapel.gd`** – stub: modlitwa (leczenie HP za złoto/relację)
- [ ] **#23 `locations/city/places/stable/stable.gd`** – stub: szybka podróż / montowanie (flavor)

---

## ⚪ TESTY / WERYFIKACJA (manualne, po każdej sekcji)

- [ ] **T1** Nowa gra → intro → wybór klasy → zapis → wczytaj → sprawdź stan
- [ ] **T2** Gildia: kup pokój, zrekruta członka, dodaj do drużyny, weź zlecenie, idź do lochu
- [ ] **T3** Loch: walka, unik, umiejętność, podnoszenie, schody, portal, śmierć, powrót
- [ ] **T4** Miasto: kowal (kupno + crafting), ratusz (relacja), brama (wyprawa)
- [ ] **T5** Ekwipunek: klawiatura + mysz, zakładanie, wyrzucanie, mikstury, narzędzia
- [ ] **T6** System: statystyki (W/S/E), talenty (T → W/S/E), zapisy
- [ ] **T7** Zapisy: zamknij grę w lochu (`QUIT_IN_RUN_IS_DEATH`), wczytaj – sprawdź karę
- [ ] **T8** Wczytaj stary zapis (jeśli masz) – migracja wersji

---

## 📦 KOLEJNOŚĆ WYKONANIA (zależności)

```
#1 → #2 → #3 → #4 → #5          (krytyczne, niezależne)
      ↓
#6 → #7 → #8                    (refaktoryzacja – robić razem, testować T1–T6)
      ↓
#9 → #10 → #11 → #12 → #13      (logika AI / craft – testować T2, T3)
      ↓
#14 → #15 → #16 → #17 → #18 → #19 → #20  (UI – testować T1–T6 wizualnie)
      ↓
#21 → #22 → #23                 (stuby – testować T4)
      ↓
T1–T8 pełny przebieg
```

---

## 📝 NOTATKI DO WYKONAWCY (mnie)

- **Jeden commit / edycja na zadanie** – łatwiej cofnąć
- **Po każdym #X uruchom grę (F5)** – sprawdź czy nie zepsułem istniejącego
- **Nie zmieniaj `balance.gd`** chyba że to typowy bug (np. brak typu w QUEST_TYPES)
- **Nie ruszaj `class_progression.gd`** – drzewka są OK, tylko UI ich pokazuje
- **Zapisz do `TODO.md` co zrobione / co napotkano** – aktualizuj status `[x]` / `[~]` / `[!]`

---

**Start:** #1 (już zrobione `items.gd` `icon_index`), teraz `#2` `quests.gd` + `#3` `smith.gd` `buy_item`.