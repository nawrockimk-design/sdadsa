extends RefCounted

const Balance = preload("res://shared/scripts/balance.gd")
const SystemWindow = preload("res://locations/guild/scripts/ui/system_window.gd")
const GOLD := Color(0.95, 0.8, 0.35)


static func draw_hud(
	canvas: CanvasItem,
	font: Font,
	viewport_size: Vector2,
	player_pos: Vector2,
	station_id: String,
	stations: Dictionary,
	city_rooms: Vector2i,
	city_size: Vector2
) -> void:
	var header := Rect2(14, 12, 400, 54)
	canvas.draw_rect(header.grow(4.0), Color(0.05, 0.07, 0.06, 0.45))
	canvas.draw_rect(header, Color(0.08, 0.11, 0.1, 0.94))
	canvas.draw_rect(header, Color(0.71, 0.57, 0.34, 0.85), false, 2.0)
	canvas.draw_string(font, Vector2(28, 36), "VALDORIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, GOLD)
	canvas.draw_string(font, Vector2(28, 55), "MIASTO GILDII", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.76, 0.8, 0.69))
	canvas.draw_string(font, Vector2(143, 43), "I  EKWIPUNEK", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.82, 0.84, 0.76))
	canvas.draw_rect(Rect2(290, 23, 1.5, 31), Color(0.71, 0.57, 0.34, 0.7))
	canvas.draw_string(font, Vector2(307, 44), "ZŁOTO  %d" % GameState.gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.98, 0.87, 0.61))
	var controls := "WASD / STRZAŁKI  RUCH     TAB  SYSTEM"
	var panel_color := Color(0.08, 0.11, 0.1, 0.9)
	if not station_id.is_empty():
		controls = "E / F  WEJDŹ: %s" % str(stations[station_id]["name"]).to_upper()
		panel_color = Color(0.18, 0.14, 0.08, 0.96)
	var control_panel := Rect2(14, 75, 400, 34)
	canvas.draw_rect(control_panel, panel_color)
	canvas.draw_rect(control_panel, Color(0.71, 0.57, 0.34, 0.6), false, 1.0)
	canvas.draw_string(font, control_panel.position + Vector2(12, 23), controls, HORIZONTAL_ALIGNMENT_LEFT, 370, 13, Color(0.98, 0.89, 0.67))
	draw_minimap(canvas, font, viewport_size, player_pos, stations, city_rooms, city_size)
	var status_message := GameState.status_message()
	if not status_message.is_empty():
		var message_panel := Rect2(14, viewport_size.y - 47.0, minf(viewport_size.x - 28.0, 700.0), 33.0)
		canvas.draw_rect(message_panel, Color(0.08, 0.11, 0.1, 0.92))
		canvas.draw_rect(message_panel, Color(0.71, 0.57, 0.34, 0.65), false, 1.0)
		canvas.draw_string(font, message_panel.position + Vector2(10, 22), status_message, HORIZONTAL_ALIGNMENT_LEFT, int(message_panel.size.x - 20.0), 13, Color(0.98, 0.9, 0.72))


static func draw_minimap(
	canvas: CanvasItem,
	font: Font,
	viewport_size: Vector2,
	player_pos: Vector2,
	stations: Dictionary,
	city_rooms: Vector2i,
	city_size: Vector2
) -> void:
	var panel := Rect2(viewport_size.x - 150.0, 14.0, 136.0, 174.0)
	canvas.draw_rect(panel.grow(4.0), Color(0.05, 0.07, 0.06, 0.45))
	canvas.draw_rect(panel, Color(0.08, 0.11, 0.1, 0.94))
	canvas.draw_rect(panel, Color(0.71, 0.57, 0.34, 0.85), false, 2.0)
	canvas.draw_string(font, panel.position + Vector2(12, 22), "PLAN MIASTA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)
	var map_rect := Rect2(panel.position + Vector2(13, 32), Vector2(110, 123))
	canvas.draw_rect(map_rect, Color(0.25, 0.36, 0.24))
	var cell := map_rect.size / Vector2(city_rooms)
	for y in city_rooms.y:
		for x in city_rooms.x:
			var block := Rect2(map_rect.position + Vector2(x, y) * cell, cell - Vector2(1, 1))
			canvas.draw_rect(block, Color(0.29, 0.41, 0.27))
			canvas.draw_rect(block, Color(0.43, 0.49, 0.34), false, 0.7)
	for x in range(1, city_rooms.x):
		var road_x := map_rect.position.x + float(x) * cell.x
		canvas.draw_line(Vector2(road_x, map_rect.position.y), Vector2(road_x, map_rect.end.y), Color(0.68, 0.59, 0.43), 2.0)
	for y in range(1, city_rooms.y):
		var road_y := map_rect.position.y + float(y) * cell.y
		canvas.draw_line(Vector2(map_rect.position.x, road_y), Vector2(map_rect.end.x, road_y), Color(0.68, 0.59, 0.43), 2.0)
	var river_y := map_rect.position.y + map_rect.size.y * 0.75
	canvas.draw_line(Vector2(map_rect.position.x, river_y), Vector2(map_rect.end.x, river_y + 2.0), Color(0.22, 0.48, 0.58), 4.0)
	for id in ["guild", "mayor", "smith", "gate"]:
		var station: Dictionary = stations[id]
		var world_pos: Vector2 = station["position"]
		var marker_pos := map_rect.position + world_pos / city_size * map_rect.size
		canvas.draw_circle(marker_pos, 2.7, GOLD)
	var player_marker := map_rect.position + player_pos / city_size * map_rect.size
	canvas.draw_circle(player_marker, 4.2, Color(1.0, 0.35, 0.23))
	canvas.draw_arc(player_marker, 6.5, 0.0, TAU, 16, Color(1.0, 0.84, 0.55), 1.2)
	canvas.draw_string(font, panel.position + Vector2(12, 168), "Gildia  Ratusz  Kowal  Brama", HORIZONTAL_ALIGNMENT_LEFT, 112, 9, Color(0.82, 0.83, 0.72))


static func draw_system_overlay(canvas: CanvasItem, font: Font, viewport_size: Vector2, cursor: int, tree_mode: bool = false) -> void:
	var panel := Rect2((viewport_size - Vector2(760, 500)) * 0.5, Vector2(760, 500))
	SystemWindow.draw_window(canvas, font, panel, cursor, tree_mode)


static func draw_mayor_overlay(canvas: CanvasItem, font: Font, viewport_size: Vector2, cursor: int, timer: float, choices: Array) -> void:
	var panel := Rect2((viewport_size - Vector2(600, 320)) * 0.5, Vector2(600, 320))
	canvas.draw_rect(panel, Color(0.02, 0.05, 0.1, 0.97))
	canvas.draw_rect(panel, GOLD, false, 2.0)
	canvas.draw_string(font, panel.position + Vector2(24, 40), "RATUSZ VALDORII", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GOLD)
	canvas.draw_string(font, panel.position + Vector2(24, 72), "Relacja: %d / %d   Czas: %.0f s" % [
		GameState.get_relation("burmistrz"), Balance.RELATION_MAX, timer],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var pos := panel.position + Vector2(32, 132 + i * 50)
		var selected := i == cursor
		if selected:
			canvas.draw_rect(Rect2(pos - Vector2(10, 23), Vector2(520, 40)), Color(0.15, 0.2, 0.28))
		canvas.draw_string(font, pos, ("> " if selected else "  ") + str(choice["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GOLD if selected else Color.WHITE)
	canvas.draw_string(font, panel.position + Vector2(24, panel.size.y - 18), "W/S: wybór   Enter: odpowiedź   Esc: zamknij", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.65, 0.7, 0.78))
