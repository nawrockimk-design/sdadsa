extends Node2D
# Chodzona sala gildii z interaktywnymi stanowiskami.

const Balance = preload("res://shared/scripts/balance.gd")
const ClassProgression = preload("res://shared/scripts/class_progression.gd")
const MembersWindow = preload("res://locations/guild/scripts/ui/members_window.gd")
const QuestsWindow = preload("res://locations/guild/scripts/ui/quests_window.gd")
const Members = preload("res://locations/guild/scripts/members.gd")
const SystemController = preload("res://shared/scripts/system_controller.gd")
const InventoryController = preload("res://shared/scripts/inventory_controller.gd")
const GUILD_FURNITURE: Texture2D = preload("res://locations/guild/assets/guild_furniture.png")
const GUILD_INTERIOR: Texture2D = preload("res://locations/guild/assets/guild_interior.png")
const PLAYER_SPRITESHEET: Texture2D = preload("res://shared/assets/characters/bohater_spritesheet.png")
const CITIZEN_SPRITESHEET: Texture2D = preload("res://locations/city/assets/characters/Sześć pikselowych arkuszy postaci RPG.png")

var member_system = Members.new()
var system_ctrl = SystemController.new()
var inv_ctrl = InventoryController.new()

const INTRO_PAGES := [
	[
		"Od dwunastego roku życia próbujesz znaleźć miejsce w drużynie.",
		"Znana drużyna Cedrica Vane'a przyjmuje Cię jako maskotkę,",
		"lecz po zdobyciu sławy zastępuje Cię silniejszym członkiem."
	],
	[
		"Po wyrzuceniu z drużyny trafiasz do Valdorii.",
		"Emerytowany mistrz gildii Edrian Voss uczy Cię walki",
		"i przetrwania przez około półtora roku."
	],
	[
		"Dzień przed Twoimi osiemnastymi urodzinami Edrian umiera.",
		"We śnie spotykasz jego duszę w Aetherionie. Opowiada Ci",
		"o bogach i Systemie. W dniu osiemnastych urodzin",
		"zaczyna się właściwa rozgrywka."
	]
]


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var size := get_viewport_rect().size
	player_pos = Vector2(size.x * 0.5, size.y * 0.72)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Inventory controller handles its own input (key + mouse)
	if inv_ctrl.is_open():
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			inv_ctrl.handle_mouse_input(event, get_viewport_rect().size)
			queue_redraw()
			return
		if event is InputEventKey and event.pressed and not event.echo:
			inv_ctrl.handle_key_input(event.keycode)
			queue_redraw()
			return
		return

	# System controller handles its own input
	if system_ctrl.is_open() and event is InputEventKey and event.pressed and not event.echo:
		if system_ctrl.handle_input(event.keycode):
			queue_redraw()
			return

	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if GameState.player_class.is_empty():
		onboarding_input(event.keycode)
		return

	if event.keycode == KEY_ESCAPE:
		if system_ctrl.is_open() or members_open or quests_open or buildings_open or relations_open or inv_ctrl.is_open():
			system_ctrl.close()
			members_open = false
			quests_open = false
			buildings_open = false
			relations_open = false
			inv_ctrl.close()
			queue_redraw()
		return

	if members_open:
		members_input(event.keycode)
		return
	if quests_open:
		quests_input(event.keycode)
		return
	if buildings_open:
		buildings_input(event.keycode)
		return
	if relations_open:
		relations_input(event.keycode)
		return

	match event.keycode:
		KEY_F, KEY_E:
			interact_nearby()
		KEY_I:
			inv_ctrl.open()
		KEY_TAB:
			system_ctrl.open()
		KEY_M:
			members_open = true
			members_cursor = 0
			members_page = 0
		KEY_Q:
			quests_open = true
			quests_cursor = 0
		KEY_B:
			buildings_open = true
			buildings_cursor = 0
		KEY_R:
			open_relations()
		KEY_BACKSPACE:
			choose({"type": "reset"})
	queue_redraw()


func onboarding_input(keycode: int) -> void:
	if not GameState.intro_complete:
		if keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE]:
			intro_page += 1
			if intro_page >= INTRO_PAGES.size():
				GameState.intro_complete = true
	else:
		match keycode:
			KEY_UP, KEY_W:
				class_cursor = (class_cursor - 1 + Balance.PLAYER_CLASSES.size()) % Balance.PLAYER_CLASSES.size()
			KEY_DOWN, KEY_S:
				class_cursor = (class_cursor + 1) % Balance.PLAYER_CLASSES.size()
			KEY_LEFT, KEY_A:
				class_cursor = (class_cursor - 4 + Balance.PLAYER_CLASSES.size()) % Balance.PLAYER_CLASSES.size()
			KEY_RIGHT, KEY_D:
				class_cursor = (class_cursor + 4) % Balance.PLAYER_CLASSES.size()
			KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE:
				GameState.player_class = Balance.PLAYER_CLASSES[class_cursor]
				GameState.hp = GameState.max_hp()
				var profile := Balance.class_profile(GameState.player_class)
				GameState.message = "Klasa: %s. Umiejętność: %s." % [GameState.player_class, profile["skill_name"]]
				GameState.save_game()
	queue_redraw()


func _process(delta: float) -> void:
	if relations_open and relation_timer > 0.0:
		relation_timer -= delta
		if relation_timer <= 0.0:
			relations_open = false
			GameState.modify_relation("burmistrz", -10)
			GameState.message = "Rozmowa z burmistrzem się urwała. Relacja spada do %d." % GameState.get_relation("burmistrz")
			var mutiny := GameState.member_system.check_mutiny(GameState.members, GameState.get_relation("burmistrz"))
			if not mutiny.is_empty():
				GameState.message += " Członkowie z ego buntują się: %s." % ", ".join(PackedStringArray(mutiny))
			GameState.save_game()
	if not GameState.player_class.is_empty() and not system_ctrl.is_open() and not members_open and not quests_open and not buildings_open and not relations_open and not inv_ctrl.is_open():
		var direction := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			direction.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			direction.y += 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			direction.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			direction.x += 1.0
		if direction != Vector2.ZERO:
			direction = direction.normalized()
			facing = direction
			var size := get_viewport_rect().size
			var next_pos := player_pos + direction * PLAYER_SPEED * delta
			next_pos.x = clampf(next_pos.x, ROOM_MARGIN + PLAYER_RADIUS, size.x - ROOM_MARGIN - PLAYER_RADIUS)
			next_pos.y = clampf(next_pos.y, TOP_MARGIN + PLAYER_RADIUS, size.y - ROOM_MARGIN - PLAYER_RADIUS)
			if not hits_furniture(next_pos, size):
				player_pos = next_pos
				player_moving = true
				player_animation_time += delta
			else:
				player_moving = false
		else:
			player_moving = false
	else:
		player_moving = false
	queue_redraw()


func station_position(station: String, size: Vector2) -> Vector2:
	match station:
		"board":
			return Vector2(size.x * 0.2, size.y * 0.3)
		"members":
			return Vector2(size.x * 0.2, size.y * 0.61)
		"bed":
			return Vector2(size.x * 0.8, size.y * 0.3)
		"plan":
			return Vector2(size.x * 0.5, size.y * 0.43)
		"mayor":
			return Vector2(size.x * 0.8, size.y * 0.61)
		"exit":
			return Vector2(size.x * 0.5, size.y * 0.79)
	return Vector2.ZERO


func hits_furniture(pos: Vector2, size: Vector2) -> bool:
	for station in ["board", "members", "bed", "plan", "mayor"]:
		if pos.distance_to(station_position(station, size)) < PLAYER_RADIUS + 56.0:
			return true
	return false


func nearest_station() -> String:
	var size := get_viewport_rect().size
	var nearest := ""
	var nearest_distance := INTERACTION_RADIUS
	for station in ["board", "members", "bed", "plan", "mayor", "exit"]:
		var distance := player_pos.distance_to(station_position(station, size))
		if distance < nearest_distance:
			nearest = station
			nearest_distance = distance
	return nearest


func interact_nearby() -> void:
	match nearest_station():
		"board":
			if not GameState.active_quest.is_empty() and GameState.active_quest.get("completed", false):
				choose({"type": "claim"})
			else:
				quests_open = true
				quests_cursor = 0
		"members":
			members_open = true
			members_cursor = 0
			members_page = 0
		"bed":
			choose({"type": "rest"})
		"plan":
			buildings_open = true
			buildings_cursor = 0
		"mayor":
			open_relations()
		"exit":
			get_tree().change_scene_to_file("res://locations/city/scenes/city.tscn")


func open_relations() -> void:
	relations_open = true
	relation_timer = 18.0
	relations_cursor = 0


func building_options() -> Array:
	var available: Array = []
	for room in Balance.ROOMS:
		if room["id"] != "hall" and not GameState.has_room(room["id"]):
			available.append(room)
	return available


func buildings_input(keycode: int) -> void:
	var available := building_options()
	if not available.is_empty():
		buildings_cursor = clampi(buildings_cursor, 0, available.size() - 1)
	match keycode:
		KEY_UP, KEY_W:
			if not available.is_empty():
				buildings_cursor = (buildings_cursor - 1 + available.size()) % available.size()
		KEY_DOWN, KEY_S:
			if not available.is_empty():
				buildings_cursor = (buildings_cursor + 1) % available.size()
		KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE:
			if available.is_empty():
				GameState.message = "Nie ma już dostępnych pomieszczeń do kupienia."
			else:
				choose({"type": "buy", "room": available[buildings_cursor]})
	queue_redraw()


func relations_options() -> Array:
	return [
		{"label": "Służba przy budynkach i dla miasta.", "delta": 12},
		{"label": "Najpierw dopilnuję własnej gildii.", "delta": 4},
		{"label": "Nie mam dziś czasu na politykę.", "delta": -12},
	]


func relations_input(keycode: int) -> void:
	match keycode:
		KEY_ESCAPE:
			relations_open = false
		KEY_UP, KEY_W:
			relations_cursor = (relations_cursor - 1 + relations_options().size()) % relations_options().size()
		KEY_DOWN, KEY_S:
			relations_cursor = (relations_cursor + 1) % relations_options().size()
		KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE:
			var choice: Dictionary = relations_options()[relations_cursor]
			var before := GameState.get_relation("burmistrz")
			var after := GameState.modify_relation("burmistrz", int(choice["delta"]))
			relations_open = false
			GameState.message = "Rozmowa z burmistrzem: %s Relacja %d → %d." % [choice["label"], before, after]
			var mutiny := GameState.member_system.check_mutiny(GameState.members, GameState.get_relation("burmistrz"))
			if not mutiny.is_empty():
				GameState.message += " Członkowie z ego buntują się: %s." % ", ".join(PackedStringArray(mutiny))
			GameState.save_game()
	queue_redraw()


func choose(opt: Dictionary) -> void:
	match opt["type"]:
		"dungeon":
			# Od teraz do powrotu portalem lub śmierci trwa wyprawa. Zamknięcie gry w jej trakcie = śmierć.
			if GameState.begin_run():
				get_tree().change_scene_to_file("res://locations/dungeon/scenes/dungeon.tscn")
			elif not GameState.message.begins_with("Błąd zapisu:"):
				GameState.message = "Nie można rozpocząć kolejnej wyprawy."
		"buy":
			var room: Dictionary = opt["room"]
			if GameState.buy_room(room):
				GameState.message = "Kupujesz pokój: %s!" % room["name"]
				buildings_open = false
			else:
				GameState.message = "Brakuje Ci %d zł na: %s." % [room["cost"] - GameState.gold, room["name"]]
		"rest":
			if GameState.hp >= GameState.max_hp():
				GameState.message = "Jesteś w pełni sił - nocleg nie jest potrzebny."
			elif GameState.rest():
				GameState.save_game()
				GameState.message = "Odpoczywasz za %d zł. Dzień %d, HP %d/%d." % [
					Balance.REST_COST, GameState.day, GameState.hp, GameState.max_hp()]
			else:
				GameState.message = "Nocleg kosztuje %d zł, a masz %d zł." % [Balance.REST_COST, GameState.gold]
		"system":
			system_ctrl.open()
		"members":
			members_open = true
			members_cursor = 0
			members_page = 0
		"quests":
			quests_open = true
			quests_cursor = 0
		"relations":
			relations_open = true
			relation_timer = 18.0
			relations_cursor = 0
		"claim":
			var old_rank: String = GameState.guild_rank
			var reward := GameState.complete_quest()
			GameState.message = "Odbierasz nagrodę: %d zł!" % reward
			if GameState.guild_rank != old_rank:
				GameState.message += " Ranga gildii wzrasta: %s → %s." % [
					old_rank, GameState.guild_rank]
		"reset":
			if confirm_reset:
				GameState.delete_save()
				confirm_reset = false
			else:
				confirm_reset = true
				GameState.message = "Na pewno? Wybierz jeszcze raz, aby skasować zapis."


func members_input(keycode: int) -> void:
	var members_list: Array = GameState.members
	match keycode:
		KEY_ESCAPE:
			members_open = false
		KEY_UP, KEY_W:
			members_cursor = maxi(members_cursor - 1, 0)
		KEY_DOWN, KEY_S:
			if not members_list.is_empty():
				members_cursor = mini(members_cursor + 1, members_list.size() - 1)
		KEY_PAGEUP:
			members_cursor = maxi(members_cursor - 6, 0)
		KEY_PAGEDOWN:
			if not members_list.is_empty():
				members_cursor = mini(members_cursor + 6, members_list.size() - 1)
		KEY_R:
			# rekrutacja
			var new_member: Dictionary = member_system.generate_member(GameState.best_floor + 1)
			if GameState.recruit_member(new_member):
				GameState.message = "Rekrutujesz: %s!" % new_member["name"]
			else:
				GameState.message = "Brakuje %d zł na rekrutację." % (new_member["cost"] - GameState.gold)
		KEY_P:
			# dodaj/usuń z drużyny
			if members_cursor < members_list.size():
				var m: Dictionary = members_list[members_cursor]
				if not m.get("alive", true):
					GameState.message = "Nie możesz dodać poległego członka do drużyny."
				elif m.get("in_party", false):
					m["in_party"] = false
					GameState.message = "%s opuszcza drużynę." % m["name"]
					GameState.save_game()
				else:
					var current_party := GameState.get_party_members()
					if current_party.size() >= GameState.max_party_size():
						GameState.message = "Drużyna pełna! Maksimum: %d." % GameState.max_party_size()
					else:
						m["in_party"] = true
						GameState.message = "%s dołącza do drużyny." % m["name"]
						GameState.save_game()
		KEY_X:
			# zwolnij
			if members_cursor < members_list.size():
				var m: Dictionary = members_list[members_cursor]
				if m.get("in_party", false):
					GameState.message = "Najpierw usuń %s z drużyny (P)." % m["name"]
				else:
					var member_name: String = m["name"]
					GameState.remove_member(m["id"])
					GameState.message = "Zwalniasz: %s." % member_name
					members_cursor = clampi(members_cursor, 0, maxi(members_list.size() - 1, 0))
	members_cursor = clampi(members_cursor, 0, maxi(members_list.size() - 1, 0))
	members_page = floori(members_cursor / 6.0)
	queue_redraw()


func quests_input(keycode: int) -> void:
	var quests := GameState.quests
	match keycode:
		KEY_ESCAPE:
			quests_open = false
		KEY_UP, KEY_W:
			if quests_cursor > 0:
				quests_cursor -= 1
		KEY_DOWN, KEY_S:
			if quests_cursor < quests.size() - 1:
				quests_cursor += 1
		KEY_ENTER, KEY_KP_ENTER, KEY_E:
			if quests_cursor < quests.size():
				var q: Dictionary = quests[quests_cursor]
				if GameState.accept_quest(q["id"]):
					GameState.message = "Przyjmujesz zlecenie."
				else:
					GameState.message = "Masz już aktywne zlecenie. Ukończ je najpierw."
	queue_redraw()


# ---------- rysowanie ----------

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var size := get_viewport_rect().size
	if GameState.player_class.is_empty():
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.09, 0.08, 0.1))
		draw_onboarding(font, size)
		return

	draw_guild_room(font, size)
	if system_ctrl.is_open():
		system_ctrl.draw(self, font, get_viewport_rect().size)
	if members_open:
		MembersWindow.draw_window(self, font, Rect2(Vector2(160, 70), Vector2(620, 450)), members_cursor, members_page)
	if quests_open:
		QuestsWindow.draw_window(self, font, Rect2(Vector2(160, 70), Vector2(620, 400)), quests_cursor)
	if buildings_open:
		draw_buildings_window(font, size)
	if relations_open:
		var panel := Rect2(Vector2(180, 120), Vector2(620, 300))
		draw_rect(panel, Color(0.04, 0.06, 0.12, 0.96))
		draw_rect(panel, GOLD, false, 2.0)
		var px := panel.position.x + 24
		var py := panel.position.y + 36
		draw_string(font, Vector2(px, py), "RELACJE Z BURMISTRZEM", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GOLD)
		draw_string(font, Vector2(px, py + 30), "Relacja: %d / %d   Czas do decyzji: %.0f s" % [GameState.get_relation("burmistrz"), Balance.RELATION_MAX, relation_timer], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.8, 0.9))
		for i in relations_options().size():
			var choice: Dictionary = relations_options()[i]
			var y_line := py + 80 + i * 54
			if i == relations_cursor:
				draw_rect(Rect2(Vector2(px - 8, y_line - 22), Vector2(panel.size.x - 30, 40)), Color(0.2, 0.2, 0.1))
			draw_string(font, Vector2(px, y_line), ("> " if i == relations_cursor else "   ") + choice["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.95, 0.8, 0.35) if i == relations_cursor else Color.WHITE)
		draw_string(font, Vector2(px + 20, panel.end.y - 28), "W/S: wybór   Enter: podejmij   Esc: zamknij", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.65, 0.72))
	if inv_ctrl.is_open():
		inv_ctrl.draw(self, font, get_viewport_rect().size)


func draw_guild_room(font: Font, size: Vector2) -> void:
	var floor_rect := Rect2(Vector2(ROOM_MARGIN, TOP_MARGIN), size - Vector2(ROOM_MARGIN * 2.0, TOP_MARGIN + ROOM_MARGIN))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.075, 0.07))
	draw_rect(Rect2(Vector2(ROOM_MARGIN - 12.0, TOP_MARGIN - 12.0), floor_rect.size + Vector2(24.0, 24.0)), Color(0.3, 0.27, 0.23))
	var wood_tile := Rect2(Vector2(4.0, 4.0), Vector2(173.0, 173.0))
	for x in range(int(floor_rect.position.x), int(floor_rect.end.x), 112):
		for y in range(int(floor_rect.position.y), int(floor_rect.end.y), 112):
			var tile_destination := Rect2(Vector2(x, y), Vector2(112.0, 112.0))
			draw_texture_rect_region(GUILD_INTERIOR, tile_destination, wood_tile)
	for x in range(int(ROOM_MARGIN - 12.0), int(floor_rect.end.x + 12.0), 112):
		draw_texture_rect_region(
			GUILD_INTERIOR,
			Rect2(Vector2(x, TOP_MARGIN - 12.0), Vector2(112.0, 52.0)),
			Rect2(Vector2(4.0, 4.0), Vector2(173.0, 80.0))
		)
	draw_rect(Rect2(Vector2(ROOM_MARGIN - 12.0, TOP_MARGIN - 12.0), Vector2(floor_rect.size.x + 24.0, 9.0)), Color(0.52, 0.39, 0.27))
	draw_rect(Rect2(Vector2(ROOM_MARGIN - 12.0, floor_rect.end.y + 3.0), Vector2(floor_rect.size.x + 24.0, 9.0)), Color(0.52, 0.39, 0.27))
	draw_rect(Rect2(Vector2(ROOM_MARGIN - 12.0, TOP_MARGIN - 12.0), Vector2(9.0, floor_rect.size.y + 24.0)), Color(0.52, 0.39, 0.27))
	draw_rect(Rect2(Vector2(floor_rect.end.x + 3.0, TOP_MARGIN - 12.0), Vector2(9.0, floor_rect.size.y + 24.0)), Color(0.52, 0.39, 0.27))
	draw_guild_wall_details(size)

	draw_rect(Rect2(Vector2(ROOM_MARGIN, 18.0), Vector2(size.x - ROOM_MARGIN * 2.0, 64.0)), Color(0.03, 0.04, 0.06, 0.9))
	draw_rect(Rect2(Vector2(ROOM_MARGIN, 18.0), Vector2(5.0, 64.0)), Color(0.75, 0.52, 0.25))
	draw_string(font, Vector2(ROOM_MARGIN + 16.0, 43.0), "GILDIA \"Odrzuceni\"", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GOLD)
	draw_string(font, Vector2(ROOM_MARGIN + 16.0, 68.0), "Dzień %d   Złoto: %d   HP: %d/%d   Poziom %d (%s)   Ranga %s" % [
		GameState.day, GameState.gold, GameState.hp, GameState.max_hp(), GameState.level,
		GameState.player_class, GameState.guild_rank], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.86, 0.86, 0.9))

	draw_room_station(font, size, "board", "TABLICA ZLECEŃ", "Zlecenia")
	draw_room_station(font, size, "bed", "ŁÓŻKO / NOCLEG", "Odpoczynek")
	draw_room_station(font, size, "plan", "PLAN ROZBUDOWY", "Pomieszczenia")
	draw_room_station(font, size, "mayor", "BURMISTRZ", "Relacja %d" % GameState.get_relation("burmistrz"))
	draw_room_station(font, size, "members", "STÓŁ GILDII", "Członkowie")

	var exit_pos := station_position("exit", size)
	draw_atlas_sprite(
		Rect2(Vector2(0.0, 724.0), Vector2(362.0, 362.0)),
		Rect2(exit_pos - Vector2(39.0, 47.0), Vector2(78.0, 94.0))
	)
	draw_rect(Rect2(exit_pos + Vector2(-21.0, -9.0), Vector2(42.0, 6.0)), Color(0.59, 0.43, 0.29))
	draw_string(font, exit_pos + Vector2(-38.0, 53.0), "DRZWI DO MIASTA", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.8, 0.62))

	draw_player_sprite()

	var station := nearest_station()
	var footer := "WASD / strzałki: ruch   F / E: interakcja   I: ekwipunek   Tab: System   Backspace x2: nowa gra"
	if not station.is_empty():
		footer = "F / E: " + station_action_label(station) + "   |   " + footer
	draw_rect(Rect2(Vector2(ROOM_MARGIN, size.y - 34.0), Vector2(size.x - ROOM_MARGIN * 2.0, 26.0)), Color(0.03, 0.04, 0.06, 0.88))
	draw_string(font, Vector2(ROOM_MARGIN + 10.0, size.y - 15.0), footer, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD if not station.is_empty() else Color(0.72, 0.75, 0.8))
	var status_message := GameState.status_message()
	if not status_message.is_empty():
		draw_string(font, Vector2(ROOM_MARGIN + 10.0, size.y - 48.0), status_message, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.94, 0.88, 0.62))


func draw_guild_wall_details(size: Vector2) -> void:
	var rug_center := Vector2(size.x * 0.5, size.y * 0.57)
	draw_atlas_sprite(Rect2(Vector2(1086.0, 724.0), Vector2(362.0, 362.0)),
		Rect2(rug_center - Vector2(86.0, 62.0), Vector2(172.0, 124.0)))
	var fire_center := Vector2(size.x * 0.5, TOP_MARGIN + 36.0)
	draw_atlas_sprite(Rect2(Vector2(1086.0, 362.0), Vector2(362.0, 362.0)),
		Rect2(fire_center - Vector2(43.0, 43.0), Vector2(86.0, 86.0)))
	var lantern_center := Vector2(ROOM_MARGIN + 36.0, TOP_MARGIN + 36.0)
	draw_atlas_sprite(Rect2(Vector2(724.0, 724.0), Vector2(362.0, 362.0)),
		Rect2(lantern_center - Vector2(21.0, 26.0), Vector2(42.0, 52.0)))
	lantern_center.x = size.x - ROOM_MARGIN - 36.0
	draw_atlas_sprite(Rect2(Vector2(724.0, 724.0), Vector2(362.0, 362.0)),
		Rect2(lantern_center - Vector2(21.0, 26.0), Vector2(42.0, 52.0)))


func draw_room_station(font: Font, size: Vector2, station: String, label: String, detail: String) -> void:
	var center := station_position(station, size)
	var selected := station == nearest_station()
	var sprite_source: Rect2
	var sprite_destination: Rect2
	match station:
		"board":
			sprite_source = Rect2(Vector2(0.0, 0.0), Vector2(362.0, 362.0))
			sprite_destination = Rect2(center + Vector2(-70.0, -74.0), Vector2(140.0, 140.0))
		"members":
			sprite_source = Rect2(Vector2(362.0, 0.0), Vector2(362.0, 362.0))
			sprite_destination = Rect2(center + Vector2(-78.0, -72.0), Vector2(156.0, 140.0))
		"bed":
			sprite_source = Rect2(Vector2(724.0, 0.0), Vector2(362.0, 362.0))
			sprite_destination = Rect2(center + Vector2(-68.0, -80.0), Vector2(136.0, 150.0))
		"plan":
			sprite_source = Rect2(Vector2(1086.0, 0.0), Vector2(362.0, 362.0))
			sprite_destination = Rect2(center + Vector2(-78.0, -72.0), Vector2(156.0, 140.0))
		"mayor":
			sprite_source = Rect2(Vector2(0.0, 362.0), Vector2(362.0, 362.0))
			sprite_destination = Rect2(center + Vector2(-78.0, -64.0), Vector2(156.0, 130.0))
			var citizen_source := Rect2(Vector2(1024.0, 512.0), Vector2(128.0, 128.0))
			draw_texture_rect_region(CITIZEN_SPRITESHEET,
				Rect2(center + Vector2(-36.0, -138.0), Vector2(72.0, 78.0)), citizen_source)
	draw_atlas_sprite(sprite_source, sprite_destination)

	var plate_y := center.y + 76.0
	var label_panel := Rect2(center.x - 92.0, plate_y - 14.0, 184.0, 35.0)
	draw_rect(label_panel.grow(3.0), Color(0.02, 0.025, 0.025, 0.35))
	draw_rect(label_panel, Color(0.055, 0.06, 0.055, 0.88))
	draw_rect(label_panel, GOLD.darkened(0.35) if selected else Color(0.42, 0.39, 0.32, 0.7), false, 1.0)
	if selected:
		draw_string(font, Vector2(center.x, plate_y), "▼ " + label, HORIZONTAL_ALIGNMENT_CENTER, 174.0, 13, GOLD)
	else:
		draw_string(font, Vector2(center.x, plate_y), label, HORIZONTAL_ALIGNMENT_CENTER, 174.0, 12, Color(0.92, 0.88, 0.8))
	draw_string(font, Vector2(center.x, plate_y + 16.0), detail, HORIZONTAL_ALIGNMENT_CENTER, 174.0, 10, Color(0.76, 0.7, 0.58))


func draw_atlas_sprite(source: Rect2, destination: Rect2) -> void:
	draw_texture_rect_region(GUILD_FURNITURE, destination, source)


func draw_player_sprite() -> void:
	var row := 0
	if absf(facing.x) > absf(facing.y):
		row = 1 if facing.x < 0.0 else 2
	elif facing.y < 0.0:
		row = 3
	var frame := int(player_animation_time * 9.0) % 4 if player_moving else 0
	var source := Rect2(Vector2(frame * 48, row * 48), Vector2(48, 48))
	var destination := Rect2(player_pos + Vector2(-32.0, -60.0), Vector2(64.0, 64.0))
	draw_texture_rect_region(PLAYER_SPRITESHEET, destination, source)


func station_action_label(station: String) -> String:
	match station:
		"board":
			return "odbierz nagrodę" if not GameState.active_quest.is_empty() and GameState.active_quest.get("completed", false) else "tablica zleceń"
		"members":
			return "zarządzaj członkami"
		"bed":
			return "odpocznij za %d zł" % Balance.REST_COST
		"plan":
			return "rozbuduj gildię"
		"mayor":
			return "porozmawiaj z burmistrzem"
		"exit":
			return "wyjdź do miasta"
	return "interakcja"


func draw_buildings_window(font: Font, size: Vector2) -> void:
	var panel_size := Vector2(minf(620.0, size.x - 32.0), minf(360.0, size.y - 32.0))
	var panel := Rect2((size - panel_size) * 0.5, panel_size)
	var available := building_options()
	draw_rect(panel, Color(0.02, 0.05, 0.1, 0.97))
	draw_rect(panel, GOLD, false, 2.0)
	var x := panel.position.x + 24.0
	var y := panel.position.y + 42.0
	draw_string(font, Vector2(x, y), "ROZBUDOWA GILDII", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GOLD)
	if available.is_empty():
		draw_string(font, Vector2(x, y + 48.0), "Wszystkie dostępne pomieszczenia są już kupione.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	else:
		for i in available.size():
			var room: Dictionary = available[i]
			var row_y := y + 52.0 + i * 48.0
			if i == buildings_cursor:
				draw_rect(Rect2(Vector2(x - 8.0, row_y - 22.0), Vector2(panel.size.x - 40.0, 40.0)), Color(0.2, 0.18, 0.1))
			var text := "%s — %d zł: %s" % [room["name"], room["cost"], room["info"]]
			draw_string(font, Vector2(x, row_y), ("> " if i == buildings_cursor else "  ") + text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, GOLD if i == buildings_cursor else Color.WHITE)
	draw_string(font, Vector2(x, panel.end.y - 24.0), "W/S: wybór   Enter/E: kup   Esc: zamknij", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.65, 0.7, 0.78))


func draw_onboarding(font: Font, size: Vector2) -> void:
	var panel_size := Vector2(minf(760.0, size.x - 32.0), minf(500.0, size.y - 32.0))
	var panel := Rect2((size - panel_size) * 0.5, panel_size)
	draw_rect(panel, Color(0.02, 0.05, 0.1, 0.98))
	draw_rect(panel, Color(0.95, 0.8, 0.35), false, 2.0)
	var x := panel.position.x + 28.0
	var y := panel.position.y + 48.0

	if not GameState.intro_complete:
		draw_string(font, Vector2(x, y), "WPROWADZENIE", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color(0.95, 0.8, 0.35))
		y += 62.0
		for line in INTRO_PAGES[intro_page]:
			draw_string(font, Vector2(x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.9, 0.92))
			y += 34.0
		draw_string(font, Vector2(x, panel.end.y - 28.0), "Enter/E/Spacja: dalej (%d/%d)" % [
			intro_page + 1, INTRO_PAGES.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.6, 0.65, 0.72))
		return

	draw_string(font, Vector2(x, y), "WYBIERZ KLASĘ", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color(0.95, 0.8, 0.35))
	y += 34.0
	draw_string(font, Vector2(x, y), "Każda klasa ma własną pasywkę i umiejętność pod K.",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.65, 0.7, 0.78))
	y += 36.0
	for i in Balance.PLAYER_CLASSES.size():
		var column := floori(i / 4.0)
		var row := i % 4
		var item_pos := Vector2(x + column * 300.0, y + row * 42.0)
		if i == class_cursor:
			draw_rect(Rect2(item_pos - Vector2(10.0, 22.0), Vector2(270.0, 34.0)), Color(0.25, 0.2, 0.1))
		draw_string(font, item_pos, ("> " if i == class_cursor else "  ") + Balance.PLAYER_CLASSES[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.95, 0.8, 0.35) if i == class_cursor else Color.WHITE)
	var selected_profile := Balance.class_profile(Balance.PLAYER_CLASSES[class_cursor])
	var detail_y := panel.end.y - 164.0
	var role_line := "%s  |  %s" % [
		str(selected_profile.get("role", "Wędrowiec")),
		str(selected_profile.get("playstyle", ""))
	]
	draw_string(font, Vector2(x, detail_y - 28.0), role_line,
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 56.0, 13, Color(0.65, 0.8, 0.95))
	if selected_profile.has("crafting_name"):
		draw_string(font, Vector2(x, detail_y - 9.0), "RZEMIOSŁO: %s — %s" % [
			str(selected_profile["crafting_name"]), str(selected_profile["crafting_description"])
		], HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 56.0, 12, Color(0.95, 0.68, 0.35))
		detail_y += 12.0
	draw_string(font, Vector2(x, detail_y), "PASYWKA: %s" % str(selected_profile["passive_name"]),
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 56.0, 13, Color(0.8, 0.85, 0.9))
	draw_string(font, Vector2(x, detail_y + 18.0), str(selected_profile["passive_description"]),
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 56.0, 12, Color(0.65, 0.7, 0.78))
	draw_string(font, Vector2(x, detail_y + 46.0), "UMIEJĘTNOŚĆ [K]: %s" % str(selected_profile["skill_name"]),
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 56.0, 13, Color(0.95, 0.8, 0.35))
	draw_string(font, Vector2(x, detail_y + 64.0), str(selected_profile["skill_description"]),
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 56.0, 12, Color(0.8, 0.85, 0.9))
	draw_string(font, Vector2(x, panel.end.y - 28.0), "W/S lub strzałki: wybór   Enter/E: zatwierdź",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.6, 0.65, 0.72))
