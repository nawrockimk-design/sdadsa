extends RefCounted
# Okno zleceń gildii: lista, przyjmowanie, informacje o postępie.

const Balance = preload("res://shared/scripts/balance.gd")
const Members = preload("res://locations/guild/scripts/members.gd")
const Quests = preload("res://locations/guild/scripts/quests.gd")

const GOLD := Color(0.95, 0.8, 0.35)
const GREEN := Color(0.6, 0.85, 0.5)


static func draw_window(canvas: CanvasItem, font: Font, panel: Rect2, cursor: int) -> void:
	var quest_system = Quests.new()
	canvas.draw_rect(panel, Color(0.02, 0.05, 0.1, 0.95))
	canvas.draw_rect(panel, GOLD, false, 2.0)
	var x := panel.position.x + 24
	var y := panel.position.y + 40
	
	canvas.draw_string(font, Vector2(x, y), "[ TABLICA ZLECEŃ ]", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GOLD)
	
	y += 40
	var active := GameState.active_quest
	if not active.is_empty():
		canvas.draw_string(font, Vector2(x, y), "Aktywne zlecenie:", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, GREEN)
		y += 26
		canvas.draw_string(font, Vector2(x, y), quest_system.describe(active), HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		y += 30
		canvas.draw_string(font, Vector2(x, y), "Postęp: %d/%d" % [active["progress"], active["target"]],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.75))
		y += 34
	else:
		canvas.draw_string(font, Vector2(x, y), "Brak aktywnego zlecenia.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.6, 0.65))
		y += 30
	
	y += 20
	canvas.draw_string(font, Vector2(x, y), "Dostępne zlecenia:", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, GOLD)
	
	var quests := GameState.quests
	if quests.is_empty():
		y += 30
		canvas.draw_string(font, Vector2(x, y), "Brak dostępnych zleceń. Sprawdź później.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.6, 0.6, 0.65))
	else:
		y += 30
		for i in quests.size():
			var q: Dictionary = quests[i]
			var selected := i == cursor
			var row_y := y + i * 42
			
			if selected:
				canvas.draw_rect(Rect2(Vector2(x - 8, row_y - 18), Vector2(panel.size.x - 32, 38)), Color(0.08, 0.18, 0.3))
			
			var prefix := "> " if selected else "   "
			canvas.draw_string(font, Vector2(x, row_y), prefix + quest_system.describe(q),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, GOLD if selected else Color(0.85, 0.85, 0.85))
	
	# podpowiedzi
	canvas.draw_string(font, Vector2(x, panel.end.y - 40), "W/S: wybór   E: przyjmij   Esc: zamknij",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.6, 0.7))
