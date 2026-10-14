extends RefCounted

const Items = preload("res://locations/dungeon/scripts/items.gd")
const Balance = preload("res://shared/scripts/balance.gd")

const COLUMNS := 5
const ROWS := 4
const SLOT_SIZE := 52.0
const SLOT_GAP := 9.0
const GRID_ORIGIN := Vector2(26.0, 145.0)
const PANEL_SIZE := Vector2(900.0, 560.0)

const PANEL := Color(0.055, 0.065, 0.075, 0.98)
const INSET := Color(0.10, 0.115, 0.125, 0.98)
const SLOT := Color(0.035, 0.043, 0.052, 0.98)
const GOLD := Color(0.94, 0.74, 0.36)
const MUTED := Color(0.62, 0.66, 0.69)


static func panel_rect(viewport_size: Vector2) -> Rect2:
	var panel_size := Vector2(
		minf(PANEL_SIZE.x, viewport_size.x - 28.0),
		minf(PANEL_SIZE.y, viewport_size.y - 28.0)
	)
	return Rect2((viewport_size - panel_size) * 0.5, panel_size)


static func visible_start(cursor: int, item_count: int) -> int:
	return clampi(cursor - 9, 0, maxi(item_count - COLUMNS * ROWS, 0))


static func pack_item_at(position: Vector2, viewport_size: Vector2, item_count: int, cursor: int) -> int:
	var panel := panel_rect(viewport_size)
	var grid_position := panel.position + GRID_ORIGIN
	var local := position - grid_position
	var pitch := SLOT_SIZE + SLOT_GAP
	var column := floori(local.x / pitch)
	var row := floori(local.y / pitch)
	if column < 0 or column >= COLUMNS or row < 0 or row >= ROWS:
		return -1
	if fposmod(local.x, pitch) >= SLOT_SIZE or fposmod(local.y, pitch) >= SLOT_SIZE:
		return -1
	var index := visible_start(cursor, item_count) + row * COLUMNS + column
	return index if index < item_count else -1


static func equipment_slot_at(position: Vector2, viewport_size: Vector2) -> String:
	var panel := panel_rect(viewport_size)
	var weapon_rect := Rect2(panel.position + Vector2(382.0, 145.0), Vector2(226.0, 100.0))
	var armor_rect := Rect2(panel.position + Vector2(620.0, 145.0), Vector2(226.0, 100.0))
	if weapon_rect.has_point(position):
		return "weapon"
	if armor_rect.has_point(position):
		return "armor"
	return ""


static func draw_window(canvas: CanvasItem, font: Font, viewport_size: Vector2, inv, cursor: int, current_hp: int = -1) -> void:
	var panel := panel_rect(viewport_size)
	var grid_origin := panel.position + GRID_ORIGIN
	var item_count: int = inv.pack.size()
	var first_index := visible_start(cursor, item_count)

	canvas.draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.008, 0.012, 0.018, 0.72))
	canvas.draw_rect(panel.grow(5.0), Color(0.0, 0.0, 0.0, 0.40))
	canvas.draw_rect(panel, PANEL)
	canvas.draw_rect(panel, Color(0.35, 0.39, 0.40), false, 2.0)
	canvas.draw_rect(Rect2(panel.position, Vector2(panel.size.x, 5.0)), GOLD)

	var title_pos := panel.position + Vector2(26.0, 43.0)
	canvas.draw_string(font, title_pos, "EKWIPUNEK", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, GOLD)
	canvas.draw_string(font, title_pos + Vector2(0.0, 25.0), "WYPOSAŻENIE I ŁUPY", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MUTED)

	var weight: int = inv.total_weight()
	var weight_ratio := 0.0 if inv.max_weight <= 0 else clampf(float(weight) / float(inv.max_weight), 0.0, 1.0)
	var weight_rect := Rect2(panel.position + Vector2(625.0, 26.0), Vector2(245.0, 13.0))
	canvas.draw_rect(weight_rect, SLOT)
	canvas.draw_rect(Rect2(weight_rect.position, Vector2(weight_rect.size.x * weight_ratio, weight_rect.size.y)),
		Color(0.82, 0.34, 0.26) if weight_ratio >= 0.9 else Color(0.43, 0.65, 0.43))
	canvas.draw_string(font, weight_rect.position + Vector2(0.0, -6.0),
		"UDŹWIG  %d / %d" % [weight, inv.max_weight], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

	canvas.draw_string(font, panel.position + Vector2(27.0, 123.0), "PLECAK", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MUTED)
	canvas.draw_string(font, panel.position + Vector2(382.0, 123.0), "ZAŁOŻONE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MUTED)

	for row in ROWS:
		for column in COLUMNS:
			var index := first_index + row * COLUMNS + column
			var slot_rect := Rect2(
				grid_origin + Vector2(column, row) * (SLOT_SIZE + SLOT_GAP),
				Vector2(SLOT_SIZE, SLOT_SIZE)
			)
			canvas.draw_rect(slot_rect, SLOT)
			canvas.draw_rect(slot_rect, Color(0.24, 0.27, 0.29), false, 1.0)
			if index >= item_count:
				continue
			var item: Dictionary = inv.pack[index]
			if index == cursor:
				canvas.draw_rect(slot_rect, Color(0.29, 0.24, 0.13), false, 2.0)
				canvas.draw_rect(Rect2(slot_rect.position, Vector2(3.0, slot_rect.size.y)), GOLD)
			else:
				canvas.draw_rect(slot_rect.grow(-2.0), Color(Items.color_of(item).r, Items.color_of(item).g, Items.color_of(item).b, 0.14))
			Items.draw_icon(canvas, item, slot_rect.get_center(), Vector2(35.0, 35.0))
			canvas.draw_string(font, slot_rect.position + Vector2(5.0, slot_rect.size.y - 4.0),
				("×%d" % int(item.get("count", 1))) if int(item.get("count", 1)) > 1 else str(item.get("weight", 0)),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)

	if item_count == 0:
		canvas.draw_string(font, grid_origin + Vector2(0.0, 4.0), "Pusto — łupy z wyprawy trafią tutaj.",
			HORIZONTAL_ALIGNMENT_LEFT, 315.0, 13, MUTED)
	elif item_count > COLUMNS * ROWS:
		canvas.draw_string(font, panel.position + Vector2(26.0, 402.0),
			"%d–%d z %d przedmiotów" % [first_index + 1, mini(first_index + COLUMNS * ROWS, item_count), item_count],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MUTED)

	draw_equipment_slot(canvas, font, panel, "weapon", "BROŃ", inv.weapon)
	draw_equipment_slot(canvas, font, panel, "armor", "ZBROJA", inv.armor)
	draw_character_panel(canvas, font, panel, inv, current_hp)
	draw_selected_item(canvas, font, panel, inv, cursor)

	var footer_y := panel.end.y - 17.0
	canvas.draw_line(panel.position + Vector2(22.0, panel.size.y - 39.0),
		panel.position + Vector2(panel.size.x - 22.0, panel.size.y - 39.0), Color(0.24, 0.27, 0.29), 1.0)
	canvas.draw_string(font, panel.position + Vector2(26.0, footer_y),
		"Klik: wybór  •  Dwuklik: załóż / użyj  •  Klik slot: zdejmij  •  WASD / strzałki: wybór  •  I / Esc: zamknij",
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 52.0, 12, MUTED)


static func draw_equipment_slot(canvas: CanvasItem, font: Font, panel: Rect2, slot: String, label: String, item: Dictionary) -> void:
	var offset := Vector2(382.0, 145.0) if slot == "weapon" else Vector2(620.0, 145.0)
	var slot_rect := Rect2(panel.position + offset, Vector2(226.0, 100.0))
	canvas.draw_rect(slot_rect, INSET)
	canvas.draw_rect(slot_rect, Color(0.36, 0.32, 0.23), false, 1.0)
	canvas.draw_string(font, slot_rect.position + Vector2(12.0, 20.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MUTED)
	if item.is_empty():
		canvas.draw_rect(Rect2(slot_rect.position + Vector2(13.0, 31.0), Vector2(42.0, 42.0)), SLOT)
		canvas.draw_string(font, slot_rect.position + Vector2(64.0, 58.0), "Puste", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, MUTED)
		return
	Items.draw_icon(canvas, item, slot_rect.position + Vector2(34.0, 57.0), Vector2(38.0, 38.0))
	var stat := "+%d ataku" % int(item.get("atk", 0)) if slot == "weapon" else "+%d obrony" % int(item.get("def", 0))
	canvas.draw_string(font, slot_rect.position + Vector2(63.0, 52.0), str(item.get("name", "Przedmiot")),
		HORIZONTAL_ALIGNMENT_LEFT, 151.0, 13, Color.WHITE)
	canvas.draw_string(font, slot_rect.position + Vector2(63.0, 74.0), stat, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)


static func draw_character_panel(canvas: CanvasItem, font: Font, panel: Rect2, inv, current_hp: int) -> void:
	var rect := Rect2(panel.position + Vector2(382.0, 260.0), Vector2(464.0, 140.0))
	canvas.draw_rect(rect, INSET)
	canvas.draw_rect(rect, Color(0.24, 0.27, 0.29), false, 1.0)
	var profile := Balance.class_profile(GameState.player_class)
	canvas.draw_string(font, rect.position + Vector2(14.0, 23.0), "%s  |  %s  |  POZIOM %d" % [
		GameState.player_class, str(profile.get("role", "Wędrowiec")), GameState.level
	],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD)
	var shown_hp := GameState.hp if current_hp < 0 else current_hp
	canvas.draw_string(font, rect.position + Vector2(14.0, 51.0),
		"HP  %d / %d" % [shown_hp, GameState.max_hp()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	canvas.draw_string(font, rect.position + Vector2(14.0, 76.0),
		"ATAK  %d     OBRONA  %d     ZŁOTO  %d" % [
			GameState.attack_bonus(), GameState.defense_bonus(), GameState.gold
		], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.83, 0.85, 0.84))
	canvas.draw_string(font, rect.position + Vector2(14.0, 99.0),
		"SIŁA %d     WYTRZYMAŁOŚĆ %d     ZRĘCZNOŚĆ %d" % [
			GameState.stats["str"], GameState.stats["vit"], GameState.stats["agi"]
		], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MUTED)
	canvas.draw_string(font, rect.position + Vector2(14.0, 124.0),
		"PASYWKA: %s" % str(profile.get("passive_name", "")),
		HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, 11, GOLD)


static func draw_selected_item(canvas: CanvasItem, font: Font, panel: Rect2, inv, cursor: int) -> void:
	var detail_rect := Rect2(panel.position + Vector2(26.0, 414.0), Vector2(326.0, 90.0))
	canvas.draw_rect(detail_rect, INSET)
	canvas.draw_rect(detail_rect, Color(0.24, 0.27, 0.29), false, 1.0)
	if cursor < 0 or cursor >= inv.pack.size():
		canvas.draw_string(font, detail_rect.position + Vector2(12.0, 28.0), "Wybierz przedmiot, aby zobaczyć szczegóły.",
			HORIZONTAL_ALIGNMENT_LEFT, 300.0, 12, MUTED)
		return
	var item: Dictionary = inv.pack[cursor]
	Items.draw_icon(canvas, item, detail_rect.position + Vector2(31.0, 45.0), Vector2(36.0, 36.0))
	canvas.draw_string(font, detail_rect.position + Vector2(59.0, 27.0), str(item.get("name", "Przedmiot")),
		HORIZONTAL_ALIGNMENT_LEFT, 252.0, 13, Items.color_of(item))
	canvas.draw_string(font, detail_rect.position + Vector2(59.0, 51.0), Items.describe(item),
		HORIZONTAL_ALIGNMENT_LEFT, 252.0, 11, Color(0.84, 0.86, 0.85))
	canvas.draw_string(font, detail_rect.position + Vector2(59.0, 72.0),
		"Załóż" if item.get("slot", "") != "potion" else "Użyj, aby odzyskać zdrowie",
		HORIZONTAL_ALIGNMENT_LEFT, 252.0, 10, GOLD)
