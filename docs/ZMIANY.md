# Rozbicie main.gd na kilka skryptów

Zachowanie gry ma zostać **identyczne**. Zmienia się tylko podział kodu.
Zakładam, że masz już wdrożone pliki z folderu `poprawki-faza1` (schody na F, nocleg itd.).

## Co gdzie leży
| Plik | Odpowiada za |
|---|---|
| `main.gd` (podmień) | pętla gry, sterowanie, walka gracza, pokoje i piętra, plecak (logika) |
| `enemy_ai.gd` (nowy) | wrogowie: przygotowanie, pościg, zamach, cios |
| `room_view.gd` (nowy) | rysowanie pokoju: ściany, przedmioty, wrogowie, gracz, wymiary kratki |
| `hud.gd` (nowy) | paski, mapa piętra, panel plecaka |

Nowa metoda `hurt_player(dmg)` w `main.gd`: wrogowie wywołują ją przy trafieniu zamiast zmieniać stan gracza bezpośrednio.

## Wdrożenie
1. Wrzuć `enemy_ai.gd`, `room_view.gd` i `hud.gd` do folderu projektu (obok `main.gd`).
2. Podmień `main.gd`.
3. Otwórz projekt w Godot. Jeśli w panelu Output pojawi się błąd parsowania, wklej mi go.

## Lista kontrolna
- [ ] Gra startuje, pokój i HUD wyglądają jak wcześniej.
- [ ] Wróg dostaje obrażenia i ginie, spadają złoto i mikstury.
- [ ] Wróg się zamachuje (pomarańczowy), trafia (-HP) lub pudłuje przy uniku.
- [ ] Plecak (I), mapa piętra i napis po prawej działają.
- [ ] Śmierć wraca do gildii, F na portalu też.

## Po co to
W Fazie 2 sojusznicy AI dostaną własny skrypt w tym samym stylu co `enemy_ai.gd` i będą używać wspólnego `move_circle` i walki, bez dopisywania kolejnych setek linii do `main.gd`.
