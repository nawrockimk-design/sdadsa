extends RefCounted
# Okno Systemu (jak w Solo Leveling): statystyki i rozdawanie punktów. Działa tylko na gracza.

const Balance = preload("res://shared/scripts/balance.gd")
const ClassProgression = preload("res://shared/scripts/class_progression.gd")

const BLUE := Color(0.4, 0.75, 1.0)


static func draw_window(canvas: CanvasItem, font: Font, panel: Rect2, cursor: int, tree_mode: bool = false) -> void:
	if tree_mode:
		draw_class_tree(canvas, font, panel, cursor)
		return
	canvas.draw_rect(panel, Color(0.02, 0.05, 0.1, 0.95))
	canvas.draw_rect(panel, BLUE, false, 2.0)
	var x := panel.position.x + 24
	var y := panel.position.y + 40
	canvas.draw_string(font, Vector2(x, y), "[ SYSTEM ]", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, BLUE)

	y += 40
	var xp_label := "MAX" if GameState.level >= ClassProgression.MAX_LEVEL else "%d/%d" % [GameState.xp, GameState.xp_to_next()]
	canvas.draw_string(font, Vector2(x, y), "Klasa: %s     Poziom: %d/%d     XP: %s" % [
		GameState.player_class, GameState.level, ClassProgression.MAX_LEVEL, xp_label], HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
	y += 26
	canvas.draw_string(font, Vector2(x, y), "HP: %d/%d     Atak: +%d     Prędkość: %d     Unik co %.2fs" % [
		GameState.hp, GameState.max_hp(), GameState.attack_bonus(), GameState.move_speed(), GameState.dash_cooldown()],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.8, 0.8, 0.85))
	y += 34
	canvas.draw_string(font, Vector2(x, y), "Cechy: %d   Talenty: %d   Każdy poziom: +HP i cecha   Co 5: dodatkowa cecha   Co 6: talent" % [
		GameState.stat_points, GameState.talent_points], HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
		Color(0.95, 0.8, 0.35) if GameState.stat_points > 0 else Color(0.6, 0.6, 0.65))

	y += 20
	for i in Balance.STATS.size():
		var stat: String = Balance.STATS[i]
		var selected := i == cursor
		var row_y := y + 30 + i * 52
		if selected:
			canvas.draw_rect(Rect2(Vector2(x - 8, row_y - 22), Vector2(panel.size.x - 32, 46)), Color(0.08, 0.18, 0.3))
		canvas.draw_string(font, Vector2(x, row_y), ("> " if selected else "   ") + "%s: %d" % [Balance.STAT_NAMES[stat], GameState.stats[stat]],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, BLUE if selected else Color.WHITE)
		canvas.draw_string(font, Vector2(x + 20, row_y + 18), Balance.STAT_INFO[stat], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.65, 0.75))

	canvas.draw_string(font, Vector2(x, panel.end.y - 20), "W/S: wybór   E/Enter: cecha   T: drzewko talentów   Tab/Esc: zamknij",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.6, 0.7))


static func draw_class_tree(canvas: CanvasItem, font: Font, panel: Rect2, cursor: int) -> void:
	var nodes := ClassProgression.nodes_for_class(GameState.player_class)
	canvas.draw_rect(panel, Color(0.02, 0.05, 0.1, 0.97))
	canvas.draw_rect(panel, Color(0.65, 0.78, 1.0), false, 2.0)
	var x := panel.position.x + 24.0
	canvas.draw_string(font, Vector2(x, panel.position.y + 36.0), "DRZEWKO KLASY — %s" % GameState.player_class.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.65, 0.82, 1.0))
	var xp_label := "MAX" if GameState.level >= ClassProgression.MAX_LEVEL else "%d/%d" % [GameState.xp, GameState.xp_to_next()]
	canvas.draw_string(font, Vector2(x, panel.position.y + 64.0), "Poziom %d/%d   XP %s   Punkty talentów: %d" % [
		GameState.level, ClassProgression.MAX_LEVEL, xp_label, GameState.talent_points
	], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.82, 0.85, 0.9))
	var half_width := (panel.size.x - 60.0) * 0.5
	var positions := [
		Rect2(panel.position + Vector2(24.0, 94.0), Vector2(panel.size.x - 48.0, 68.0)),
		Rect2(panel.position + Vector2(24.0, 170.0), Vector2(half_width, 68.0)),
		Rect2(panel.position + Vector2(panel.size.x * 0.5 + 6.0, 170.0), Vector2(half_width, 68.0)),
		Rect2(panel.position + Vector2(24.0, 246.0), Vector2(half_width, 68.0)),
		Rect2(panel.position + Vector2(panel.size.x * 0.5 + 6.0, 246.0), Vector2(half_width, 68.0)),
		Rect2(panel.position + Vector2(24.0, 322.0), Vector2(half_width, 68.0)),
		Rect2(panel.position + Vector2(panel.size.x * 0.5 + 6.0, 322.0), Vector2(half_width, 68.0)),
		Rect2(panel.position + Vector2(24.0, 398.0), Vector2(panel.size.x - 48.0, 68.0)),
	]
	var centers := []
	for rect in positions:
		centers.append(rect.get_center())
	for pair in [[0, 1], [0, 2], [1, 3], [2, 4], [3, 5], [4, 6], [5, 7], [6, 7]]:
		var from_index: int = pair[0]
		var to_index: int = pair[1]
		var from_unlocked := GameState.has_talent(str(nodes[from_index]["id"]))
		var to_unlocked := GameState.has_talent(str(nodes[to_index]["id"]))
		canvas.draw_line(centers[from_index], centers[to_index],
			Color(0.37, 0.76, 0.52, 0.9) if from_unlocked and to_unlocked else Color(0.25, 0.32, 0.42, 0.8), 2.0)
	for i in nodes.size():
		var node: Dictionary = nodes[i]
		var unlocked := GameState.has_talent(str(node["id"]))
		var available := GameState.can_unlock_talent(str(node["id"]))
		var selected := i == cursor
		var rect: Rect2 = positions[i]
		var fill := Color(0.12, 0.3, 0.22, 0.96) if unlocked else (Color(0.13, 0.2, 0.32, 0.98) if available else Color(0.09, 0.1, 0.14, 0.98))
		canvas.draw_rect(rect, fill)
		canvas.draw_rect(rect, Color(0.95, 0.8, 0.35) if selected else (Color(0.42, 0.75, 0.56) if unlocked else Color(0.3, 0.34, 0.42)), false, 2.0 if selected else 1.0)
		var state := "ODBLOKOWANO" if unlocked else ("DOSTĘPNY — Enter: odblokuj" if available else "ZABLOKOWANY")
		canvas.draw_string(font, rect.position + Vector2(12.0, 22.0), "%s%s  •  %s" % [
			"> " if selected else "", str(node["name"]), state
		], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 13, Color(0.95, 0.8, 0.35) if selected or available else Color(0.7, 0.72, 0.76))
		canvas.draw_string(font, rect.position + Vector2(12.0, 46.0), str(node["description"]),
			HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 12, Color(0.82, 0.85, 0.9))
	canvas.draw_string(font, Vector2(x, panel.end.y - 18.0), "W/S: wybór talentu   Enter/E: odblokuj   T: cechy   Tab/Esc: zamknij",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.58, 0.67, 0.78))
