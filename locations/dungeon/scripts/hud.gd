extends RefCounted
# Interfejs lochu: paski i podpowiedzi, mapa piętra, plecak.
# Dane bierze z węzła main.gd (parametr m), niczego nie zmienia.

const Items = preload("res://locations/dungeon/scripts/items.gd")
const Dungeon = preload("res://locations/dungeon/scripts/dungeon.gd")
const Balance = preload("res://shared/scripts/balance.gd")
const ClassProgression = preload("res://shared/scripts/class_progression.gd")
const RoomView = preload("res://locations/dungeon/scripts/room_view.gd")

const PANEL := Color(0.045, 0.055, 0.05, 0.96)
const INSET := Color(0.09, 0.105, 0.09, 0.98)
const GOLD := Color(0.78, 0.61, 0.34)
const MUTED := Color(0.72, 0.72, 0.65)


static func draw_hud(canvas: CanvasItem, m, font: Font) -> void:
	var origin: Vector2 = RoomView.ORIGIN
	var hud_y: float = origin.y + Dungeon.ROOM_H * RoomView.TILE + 20
	var player_hp: int = m.player_hp
	var floor_num: int = m.floor_num
	var run_gold: int = m.run_gold
	var dash_cd: float = m.dash_cd
	var skill_cd: float = m.skill_cd
	var class_profile := Balance.class_profile(GameState.player_class)
	var log_timer: float = m.log_timer
	var log_text: String = m.log_text
	var inv = m.inv

	var viewport_size := canvas.get_viewport_rect().size
	var panel := Rect2(Vector2(origin.x - 8.0, hud_y - 10.0), Vector2(viewport_size.x - origin.x * 2.0 + 16.0, 124.0))
	canvas.draw_rect(panel.grow(5.0), Color(0.0, 0.0, 0.0, 0.38))
	canvas.draw_rect(panel, PANEL)
	canvas.draw_rect(panel, GOLD.darkened(0.2), false, 2.0)
	canvas.draw_rect(Rect2(panel.position, Vector2(panel.size.x, 3.0)), GOLD)

	var max_hp: int = GameState.max_hp()
	canvas.draw_string(font, Vector2(origin.x + 2.0, hud_y + 13.0), "ZDROWIE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)
	RoomView.draw_bar(canvas, Vector2(origin.x, hud_y + 17.0), Vector2(220, 16), float(player_hp) / max_hp, Color(0.72, 0.22, 0.18))
	canvas.draw_string(font, Vector2(origin.x + 7.0, hud_y + 30.0), "%d / %d HP" % [player_hp, max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	var xp_progress := 1.0 if GameState.xp_to_next() <= 0 else float(GameState.xp) / float(GameState.xp_to_next())
	canvas.draw_string(font, Vector2(origin.x + 2.0, hud_y + 49.0), "DOŚWIADCZENIE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)
	RoomView.draw_bar(canvas, Vector2(origin.x, hud_y + 53.0), Vector2(220, 8), xp_progress, Color(0.42, 0.68, 0.83))

	var level_label := "MAX" if GameState.level >= ClassProgression.MAX_LEVEL else "Poz. %d" % GameState.level
	canvas.draw_string(font, Vector2(origin.x + 242.0, hud_y + 14.0), "WYPRAWA", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)
	canvas.draw_string(font, Vector2(origin.x + 242.0, hud_y + 34.0), "PIĘTRO %d     %s     ŁUP  %d zł" % [
		floor_num, level_label.to_upper(), run_gold], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.96, 0.88, 0.69))
	canvas.draw_rect(Rect2(origin.x + 242.0, hud_y + 44.0, 1.0, 18.0), GOLD.darkened(0.15))
	canvas.draw_string(font, Vector2(origin.x + 254.0, hud_y + 57.0), "UDŹWIG  %d / %d" % [
		inv.total_weight(), inv.max_weight], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)

	var dash_ready := dash_cd <= 0.0
	var skill_ready := skill_cd <= 0.0
	_draw_status_chip(canvas, font, Rect2(origin.x + 470.0, hud_y + 13.0, 150.0, 28.0),
		"UNIK  [SHIFT]", "GOTOWY" if dash_ready else "%.1fs" % dash_cd, Color(0.48, 0.76, 0.48) if dash_ready else MUTED)
	_draw_status_chip(canvas, font, Rect2(origin.x + 628.0, hud_y + 13.0, 220.0, 28.0),
		"%s  [K]" % str(class_profile["skill_name"]).to_upper(),
		"GOTOWA" if skill_ready else "%.1fs" % skill_cd, Color(0.6, 0.78, 0.88) if skill_ready else MUTED)
	
	# info o sojusznikach
	var allies: Array = m.current_allies
	var alive_allies := 0
	for a in allies:
		if a.get("alive", true):
			alive_allies += 1
	if alive_allies > 0:
		canvas.draw_string(font, Vector2(origin.x + 470.0, hud_y + 59.0), "DRUŻYNA  %d ŻYWYCH" % alive_allies,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.63, 0.77, 0.85))
	if m.on_portal():
		_draw_status_chip(canvas, font, Rect2(origin.x + 858.0, hud_y + 13.0, 202.0, 28.0),
			"[F] PORTAL", "DO MIASTA", Color(0.54, 0.77, 0.9))
	elif m.on_stairs():
		_draw_status_chip(canvas, font, Rect2(origin.x + 858.0, hud_y + 13.0, 202.0, 28.0),
			"[F] SCHODY", "NIŻEJ", Color(0.55, 0.82, 0.55))

	if not GameState.storage_error.is_empty():
		canvas.draw_string(font, Vector2(origin.x + 470.0, hud_y + 92.0), GameState.storage_error, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.48, 0.38))
	elif log_timer > 0.0:
		canvas.draw_string(font, Vector2(origin.x + 470.0, hud_y + 92.0), log_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.94, 0.87, 0.72))


static func _draw_status_chip(canvas: CanvasItem, font: Font, rect: Rect2, label: String, status: String, accent: Color) -> void:
	canvas.draw_rect(rect, INSET)
	canvas.draw_rect(rect, GOLD.darkened(0.48), false, 1.0)
	canvas.draw_rect(Rect2(rect.position, Vector2(3.0, rect.size.y)), accent)
	canvas.draw_string(font, rect.position + Vector2(10.0, 12.0), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 9, MUTED)
	canvas.draw_string(font, rect.position + Vector2(10.0, 24.0), status, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 11, accent)


static func draw_minimap(canvas: CanvasItem, m, font: Font) -> void:
	var dungeon = m.dungeon
	var inv = m.inv
	var mini_origin: Vector2 = RoomView.MINI_ORIGIN
	var panel := Rect2(mini_origin - Vector2(14.0, 30.0), Vector2(344.0, 418.0))
	canvas.draw_rect(panel.grow(5.0), Color(0.0, 0.0, 0.0, 0.38))
	canvas.draw_rect(panel, PANEL)
	canvas.draw_rect(panel, GOLD.darkened(0.2), false, 2.0)
	canvas.draw_rect(Rect2(panel.position, Vector2(panel.size.x, 3.0)), GOLD)
	canvas.draw_string(font, mini_origin + Vector2(0.0, -10.0), "DZIENNIK WYPRAWY", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.96, 0.86, 0.64))
	canvas.draw_string(font, mini_origin + Vector2(0.0, 14.0), "MAPA PIĘTRA", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, MUTED)

	var map_rect := Rect2(mini_origin - Vector2(7.0, 4.0), Vector2(252.0, 144.0))
	canvas.draw_rect(map_rect, INSET)
	canvas.draw_rect(map_rect, GOLD.darkened(0.45), false, 1.0)
	for cell in dungeon.layout:
		var r: Dictionary = dungeon.layout[cell]
		var seen: bool = r["visited"]
		if not seen:
			for dd2 in r["doors"]:
				var nb: Vector2i = cell + dd2
				if dungeon.layout.has(nb) and dungeon.layout[nb]["visited"]:
					seen = true
		if not seen:
			continue
		var col := Color(0.3, 0.3, 0.35) if r["visited"] else Color(0.15, 0.15, 0.18)
		if cell == dungeon.start_cell:
			col = Color(0.25, 0.4, 0.75)
		if cell == dungeon.stairs_cell and r["visited"]:
			col = Color(0.2, 0.6, 0.3)
		if cell == dungeon.current:
			col = Color(0.9, 0.8, 0.2)
		var room_rect := Rect2(mini_origin + Vector2(cell.x * 34, cell.y * 26), Vector2(30, 22))
		canvas.draw_rect(room_rect, col)
		canvas.draw_rect(room_rect, Color(0.8, 0.73, 0.55, 0.45), false, 1.0)

	canvas.draw_line(mini_origin + Vector2(0.0, 153.0), mini_origin + Vector2(316.0, 153.0), GOLD.darkened(0.4), 1.0)
	_draw_legend_row(canvas, font, mini_origin + Vector2(2.0, 174.0), Color(0.9, 0.8, 0.2), "Twoja pozycja")
	_draw_legend_row(canvas, font, mini_origin + Vector2(162.0, 174.0), Color(0.2, 0.6, 0.3), "Schody")
	_draw_legend_row(canvas, font, mini_origin + Vector2(2.0, 195.0), Color(0.25, 0.4, 0.75), "Portal do miasta")
	canvas.draw_string(font, mini_origin + Vector2(162.0, 195.0), "Pokonaj wrogów, by otworzyć drzwi", HORIZONTAL_ALIGNMENT_LEFT, 166.0, 10, MUTED)

	canvas.draw_string(font, mini_origin + Vector2(0.0, 226.0), "WYPOSAŻENIE  ·  I: PLECAK", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)
	var gear_panel := Rect2(mini_origin - Vector2(7.0, -233.0), Vector2(316.0, 76.0))
	canvas.draw_rect(gear_panel, INSET)
	canvas.draw_rect(gear_panel, GOLD.darkened(0.48), false, 1.0)
	Items.draw_icon(canvas, inv.weapon if not inv.weapon.is_empty() else {"slot": "weapon", "name": "Miecz"}, mini_origin + Vector2(13.0, 253.0), Vector2(24.0, 24.0))
	canvas.draw_string(font, mini_origin + Vector2(32.0, 258.0), Items.describe(inv.weapon) if not inv.weapon.is_empty() else "Brak broni",
		HORIZONTAL_ALIGNMENT_LEFT, 266.0, 12, Items.color_of(inv.weapon) if not inv.weapon.is_empty() else MUTED)
	Items.draw_icon(canvas, inv.armor if not inv.armor.is_empty() else {"slot": "armor", "name": "Skórzana kurtka"}, mini_origin + Vector2(13.0, 280.0), Vector2(24.0, 24.0))
	canvas.draw_string(font, mini_origin + Vector2(32.0, 285.0), Items.describe(inv.armor) if not inv.armor.is_empty() else "Brak zbroi",
		HORIZONTAL_ALIGNMENT_LEFT, 266.0, 12, Items.color_of(inv.armor) if not inv.armor.is_empty() else MUTED)
	canvas.draw_string(font, mini_origin + Vector2(0.0, 331.0), "PLECAK  %d szt.   ·   UDŹWIG %d/%d" % [
		inv.pack.size(), inv.total_weight(), inv.max_weight], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.92, 0.86, 0.7))
	canvas.draw_string(font, mini_origin + Vector2(0.0, 367.0), "Śmierć oznacza utratę złota i łupów.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.82, 0.58, 0.52))


static func _draw_legend_row(canvas: CanvasItem, font: Font, pos: Vector2, color: Color, label: String) -> void:
	canvas.draw_rect(Rect2(pos, Vector2(10.0, 10.0)), color)
	canvas.draw_rect(Rect2(pos, Vector2(10.0, 10.0)), Color(0.9, 0.84, 0.7), false, 1.0)
	canvas.draw_string(font, pos + Vector2(16.0, 10.0), label, HORIZONTAL_ALIGNMENT_LEFT, 140.0, 10, MUTED)



