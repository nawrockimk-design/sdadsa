extends RefCounted
# Okno członków gildii: lista, rekrutacja, wybór do drużyny.

const Balance = preload("res://shared/scripts/balance.gd")
const Members = preload("res://locations/guild/scripts/members.gd")

const GOLD := Color(0.95, 0.8, 0.35)
const GREEN := Color(0.6, 0.85, 0.5)
const RED := Color(0.8, 0.5, 0.5)
const WHITE := Color.WHITE


static func draw_window(canvas: CanvasItem, font: Font, panel: Rect2, cursor: int, page: int = 0) -> void:
	var member_system = Members.new()
	canvas.draw_rect(panel, Color(0.02, 0.05, 0.1, 0.95))
	canvas.draw_rect(panel, GOLD, false, 2.0)
	var x := panel.position.x + 24
	var y := panel.position.y + 40
	
	canvas.draw_string(font, Vector2(x, y), "[ CZŁONKOWIE GILDII ]", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GOLD)
	
	y += 40
	var members := GameState.members
	var alive_count := 0
	var party_count := 0
	for m in members:
		if m.get("alive", true):
			alive_count += 1
		if m.get("in_party", false):
			party_count += 1
	
	canvas.draw_string(font, Vector2(x, y), "Członkowie: %d/%d     W drużynie: %d/%d     Ranga gildii: %s (%s, %d XP)" % [
		alive_count, members.size(), party_count, GameState.max_party_size(),
		GameState.guild_rank, Balance.RANK_NAMES.get(GameState.guild_rank, "?"), GameState.guild_xp],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
	
	y += 34
	if members.is_empty():
		canvas.draw_string(font, Vector2(x, y), "Brak członków. Naciśnij R, aby rekrutować (koszt od 50 zł).",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.6, 0.65))
		return
	
	# lista członków (z pagination)
	var page_size := 6
	var start_idx := page * page_size
	var end_idx := mini(members.size(), start_idx + page_size)
	
	for i in range(start_idx, end_idx):
		var m: Dictionary = members[i]
		var selected: bool = i == cursor
		var row_y: float = y + 30 + (i - start_idx) * 48
		
		if selected:
			canvas.draw_rect(Rect2(Vector2(x - 8, row_y - 20), Vector2(panel.size.x - 32, 44)), Color(0.08, 0.18, 0.3))
		
		var status: String = ""
		var status_color: Color = WHITE
		if not m.get("alive", true):
			status = "[POLEGŁ]"
			status_color = RED
		elif m.get("in_party", false):
			status = "[W DRUŻYNIE]"
			status_color = GREEN
		
		var prefix := "> " if selected else "   "
		canvas.draw_string(font, Vector2(x, row_y), prefix + m["name"] + " " + status,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, GOLD if selected else status_color)
		canvas.draw_string(font, Vector2(x + 20, row_y + 18), "%s (%s) %s   XP: %d   %s" % [
			m["rank"], Balance.RANK_NAMES.get(m["rank"], "?"), m["class"], int(m.get("xp", 0)), member_system.traits_text(m)],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.65, 0.75))
	
	# podpowiedzi
	canvas.draw_string(font, Vector2(x, panel.end.y - 60), "W/S: wybór   PageUp/Down: strona   R: rekrutuj",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.6, 0.7))
	canvas.draw_string(font, Vector2(x, panel.end.y - 40), "P: dodaj/usuń z drużyny   X: zwolnij   Esc: zamknij",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.6, 0.7))
