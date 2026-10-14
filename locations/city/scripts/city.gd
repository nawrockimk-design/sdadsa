extends Node2D
# Valdoria is a continuous 5-by-7 grid of dungeon-room-sized city blocks.

const Balance = preload("res://shared/scripts/balance.gd")
const ClassProgression = preload("res://shared/scripts/class_progression.gd")
const CityUI = preload("res://locations/city/scripts/city_ui.gd")
const Smith = preload("res://locations/city/places/smith/smith.gd")
const SystemController = preload("res://shared/scripts/system_controller.gd")
const InventoryController = preload("res://shared/scripts/inventory_controller.gd")
const PLAYER_SPRITESHEET: Texture2D = preload("res://shared/assets/characters/bohater_spritesheet.png")
const CITIZEN_SPRITESHEET: Texture2D = preload("res://locations/city/assets/characters/Sześć pikselowych arkuszy postaci RPG.png")
const HOUSE_SPRITESHEET: Texture2D = preload("res://locations/city/assets/buildings/Trzy pikselowe domki fantasy.png")
const GUILD_SPRITE: Texture2D = preload("res://locations/guild/assets/Izometryczna Twierdza Złamanego Herbu.png")
const MAYOR_SPRITE: Texture2D = preload("res://locations/city/places/mayor/assets/ratusz_bez_tla.png")
const SMITH_SPRITE: Texture2D = preload("res://locations/city/places/smith/assets/Izometryczna kuźnia fantasy w pikselach.png")
const TAVERN_SPRITE: Texture2D = preload("res://locations/city/places/tavern/assets/Pikselowa karczma pod złotym szyldem.png")
const CHAPEL_SPRITE: Texture2D = preload("res://locations/city/places/chapel/assets/Pikselowa kaplica ze złotym krzyżem.png")
const STABLE_SPRITE: Texture2D = preload("res://locations/city/places/stable/assets/Średniowieczna stajnia z otwartą zagrodą.png")
const CITY_TILESET: Texture2D = preload("res://locations/city/assets/tilesets/Pikselowy zestaw kafelków średniowiecznego miasta.png")

const TILE_SIZE := 48.0
const ROOM_TILES := Vector2(15.0, 9.0)
const ROOM_SIZE := ROOM_TILES * TILE_SIZE
const CITY_ROOMS := Vector2i(5, 7)
const CITY_SIZE := Vector2(ROOM_SIZE.x * CITY_ROOMS.x, ROOM_SIZE.y * CITY_ROOMS.y)
const PLAYER_SPEED := 210.0
const PLAYER_RADIUS := 14.0
const INTERACTION_RADIUS := 54.0
const GOLD := Color(0.95, 0.8, 0.35)
const GRASS := Color(0.31, 0.43, 0.24)
const STONE := Color(0.66, 0.59, 0.45)
const INK := Color(0.12, 0.15, 0.14)

const CITIZENS := [
	{"center": Vector2(1740, 1430), "radius": 42.0, "speed": 0.24, "phase": 0.0, "sprite": 5},
	{"center": Vector2(1870, 1570), "radius": 52.0, "speed": 0.19, "phase": 1.8, "sprite": 1},
	{"center": Vector2(2490, 1530), "radius": 66.0, "speed": 0.22, "phase": 3.2, "sprite": 2},
	{"center": Vector2(1780, 850), "radius": 64.0, "speed": 0.17, "phase": 2.5, "sprite": 3},
	{"center": Vector2(970, 1500), "radius": 48.0, "speed": 0.21, "phase": 4.1, "sprite": 4},
	{"center": Vector2(2600, 2050), "radius": 54.0, "speed": 0.18, "phase": 5.3, "sprite": 0},
	{"center": Vector2(1440, 1040), "radius": 40.0, "speed": 0.23, "phase": 0.8, "sprite": 5},
]
const LAMPS := [
	Vector2(1640, 1270), Vector2(1960, 1270), Vector2(1640, 1730), Vector2(1960, 1730),
	Vector2(1450, 1020), Vector2(2150, 1020), Vector2(1450, 1920), Vector2(2150, 1920),
	Vector2(1760, 2650), Vector2(1840, 2650), Vector2(730, 730), Vector2(2870, 1870)
]
const PLANTERS := [
	Vector2(1625, 1390), Vector2(1975, 1390), Vector2(1625, 1610), Vector2(1975, 1610)
]
const STALL_RECTS := [
	Rect2(1610, 1495, 100, 52), Rect2(1890, 1495, 100, 52)
]
const BENCH_RECTS := [
	Rect2(1507, 1478, 56, 24), Rect2(2032, 1478, 56, 24)
]

const STATIONS := {
	"guild": {"name": "Gildia Odrzuceni", "position": Vector2(1450, 1305)},
	"mayor": {"name": "Ratusz", "position": Vector2(1780, 815)},
	"smith": {"name": "Warsztat miejskiego kowala", "position": Vector2(2500, 1480)},
	"gate": {"name": "Główna Brama — droga do lochu", "position": Vector2(1800, 2910)},
}

const BUILDINGS := [
	{"rect": Rect2(1360, 1160, 180, 125), "type": "guild"},
	{"rect": Rect2(1690, 675, 190, 125), "type": "mayor"},
	{"rect": Rect2(2410, 1340, 175, 125), "type": "smith"},
	{"rect": Rect2(930, 390, 170, 120), "type": "ordinary"},
	{"rect": Rect2(1150, 330, 145, 110), "type": "ordinary"},
	{"rect": Rect2(2020, 340, 155, 115), "type": "ordinary"},
	{"rect": Rect2(2250, 420, 170, 125), "type": "ordinary"},
	{"rect": Rect2(300, 850, 170, 120), "type": "ordinary"},
	{"rect": Rect2(470, 1030, 205, 145), "type": "tavern"},
	{"rect": Rect2(900, 930, 190, 140), "type": "chapel"},
	{"rect": Rect2(1160, 1010, 160, 125), "type": "ordinary"},
	{"rect": Rect2(2040, 1050, 170, 120), "type": "ordinary"},
	{"rect": Rect2(2270, 980, 145, 115), "type": "ordinary"},
	{"rect": Rect2(2900, 890, 180, 130), "type": "ordinary"},
	{"rect": Rect2(3160, 1030, 170, 120), "type": "ordinary"},
	{"rect": Rect2(310, 1510, 190, 130), "type": "stable"},
	{"rect": Rect2(520, 1740, 165, 120), "type": "ordinary"},
	{"rect": Rect2(900, 1650, 180, 130), "type": "ordinary"},
	{"rect": Rect2(1130, 1840, 160, 120), "type": "ordinary"},
	{"rect": Rect2(2020, 1740, 170, 120), "type": "ordinary"},
	{"rect": Rect2(2280, 1830, 180, 125), "type": "ordinary"},
	{"rect": Rect2(2860, 1570, 180, 130), "type": "ordinary"},
	{"rect": Rect2(3150, 1790, 165, 120), "type": "ordinary"},
	{"rect": Rect2(360, 2560, 175, 125), "type": "ordinary"},
	{"rect": Rect2(590, 2700, 180, 125), "type": "ordinary"},
	{"rect": Rect2(1010, 2560, 160, 120), "type": "ordinary"},
	{"rect": Rect2(1200, 2700, 175, 125), "type": "ordinary"},
	{"rect": Rect2(2040, 2560, 180, 125), "type": "ordinary"},
	{"rect": Rect2(2300, 2700, 165, 120), "type": "ordinary"},
	{"rect": Rect2(2900, 2560, 180, 130), "type": "ordinary"},
	{"rect": Rect2(3170, 2700, 170, 120), "type": "ordinary"},
]

const TREES := [
	Vector2(230, 250), Vector2(430, 280), Vector2(1540, 255), Vector2(1930, 250),
	Vector2(2670, 280), Vector2(3320, 330), Vector2(790, 760), Vector2(1320, 920),
	Vector2(2630, 890), Vector2(3440, 1240), Vector2(230, 1320), Vector2(790, 1470),
	Vector2(1320, 1550), Vector2(2760, 1580), Vector2(3420, 1710), Vector2(800, 2020),
	Vector2(1510, 2540), Vector2(1940, 2040), Vector2(2700, 2540), Vector2(3390, 2040),
	Vector2(250, 2650), Vector2(880, 2780), Vector2(1430, 2710), Vector2(2250, 2760),
	Vector2(2800, 2670), Vector2(3370, 2750),
]

var player_pos := Vector2(1450, 1370)
var system_ctrl = SystemController.new()
var inv_ctrl = InventoryController.new()
var smith_open := false
var smith_cursor := 0
var mayor_open := false
var mayor_cursor := 0
var mayor_timer := 0.0
var confirm_reset := false
var city_time := 0.0
var facing := Vector2.DOWN
var player_animation_time := 0.0
var player_moving := false
var river_polygon := PackedVector2Array([
	Vector2(0, 2140), Vector2(430, 2080), Vector2(760, 2170), Vector2(1100, 2140),
	Vector2(1450, 2230), Vector2(1740, 2180), Vector2(2100, 2290), Vector2(2440, 2220),
	Vector2(2780, 2310), Vector2(3140, 2240), Vector2(3600, 2300), Vector2(3600, 2480),
	Vector2(3180, 2410), Vector2(2800, 2490), Vector2(2420, 2400), Vector2(2080, 2470),
	Vector2(1720, 2370), Vector2(1410, 2430), Vector2(1080, 2350), Vector2(740, 2400),
	Vector2(420, 2320), Vector2(0, 2380)
])


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func _process(delta: float) -> void:
	city_time += delta
	if mayor_open:
		mayor_timer -= delta
		if mayor_timer <= 0.0:
			mayor_open = false
			adjust_mayor_relation(-10)
			GameState.message = "Burmistrz kończy rozmowę. Relacja: %d." % GameState.get_relation("burmistrz")
			append_mutiny_notice()
			GameState.save_game()

	if not system_ctrl.is_open() and not smith_open and not mayor_open and not inv_ctrl.is_open():
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
			facing = direction.normalized()
			var previous_position := player_pos
			player_pos = move_player(facing * PLAYER_SPEED * delta)
			player_moving = not player_pos.is_equal_approx(previous_position)
			if player_moving:
				player_animation_time += delta
		else:
			player_moving = false
	else:
		player_moving = false
	queue_redraw()


func move_player(motion: Vector2) -> Vector2:
	var next := player_pos
	var x_candidate := Vector2(next.x + motion.x, next.y)
	if not is_blocked(x_candidate):
		next = x_candidate
	var y_candidate := Vector2(next.x, next.y + motion.y)
	if not is_blocked(y_candidate):
		next = y_candidate
	return next


func is_blocked(pos: Vector2) -> bool:
	if pos.x < PLAYER_RADIUS or pos.x > CITY_SIZE.x - PLAYER_RADIUS:
		return true
	if pos.y < PLAYER_RADIUS or pos.y > CITY_SIZE.y - PLAYER_RADIUS:
		return true
	var bridge_area := Rect2(1722.0, 2138.0, 156.0, 362.0)
	if Geometry2D.is_point_in_polygon(pos, river_polygon) and not bridge_area.has_point(pos):
		return true
	if pos.distance_to(Vector2(1800, 1500)) < 100.0:
		return true
	for tree in TREES:
		if pos.distance_to(tree) < PLAYER_RADIUS + 12.0:
			return true
	for lamp in LAMPS:
		if pos.distance_to(lamp) < PLAYER_RADIUS + 7.0:
			return true
	for planter in PLANTERS:
		if Rect2(planter - Vector2(29, 20), Vector2(58, 40)).grow(PLAYER_RADIUS).has_point(pos):
			return true
	for stall in STALL_RECTS:
		if stall.grow(PLAYER_RADIUS).has_point(pos):
			return true
	for bench in BENCH_RECTS:
		if bench.grow(PLAYER_RADIUS).has_point(pos):
			return true
	for building: Dictionary in BUILDINGS:
		var building_rect: Rect2 = building["rect"]
		var door := Rect2(
			Vector2(building_rect.position.x + building_rect.size.x * 0.4, building_rect.end.y - 4.0),
			Vector2(building_rect.size.x * 0.2, 26.0)
		)
		if door.grow(PLAYER_RADIUS).has_point(pos):
			continue
		if building_rect.grow(PLAYER_RADIUS).has_point(pos):
			return true
	if pos.y < 2880.0 or pos.x < 1650.0 or pos.x > 1950.0:
		for wall in city_walls():
			if wall.grow(PLAYER_RADIUS).has_point(pos):
				return true
	return false


func city_walls() -> Array[Rect2]:
	return [
		Rect2(60, 60, CITY_SIZE.x - 120.0, 36.0),
		Rect2(60, 60, 36.0, CITY_SIZE.y - 120.0),
		Rect2(CITY_SIZE.x - 96.0, 60, 36.0, CITY_SIZE.y - 120.0),
		Rect2(60, CITY_SIZE.y - 96.0, 1590.0, 36.0),
		Rect2(1950, CITY_SIZE.y - 96.0, CITY_SIZE.x - 2010.0, 36.0),
	]


func nearest_station() -> String:
	var nearest := ""
	var nearest_distance := INTERACTION_RADIUS
	for station_id in STATIONS:
		var station: Dictionary = STATIONS[station_id]
		var distance: float = player_pos.distance_to(station["position"])
		if distance < nearest_distance:
			nearest = station_id
			nearest_distance = distance
	return nearest


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

	if mayor_open:
		mayor_input(event.keycode)
	elif smith_open:
		smith_input(event.keycode)
	elif event.keycode == KEY_ESCAPE:
		if system_ctrl.is_open() or smith_open or mayor_open or inv_ctrl.is_open():
			system_ctrl.close()
			smith_open = false
			mayor_open = false
			inv_ctrl.close()
			queue_redraw()
		return
	else:
		match event.keycode:
			KEY_F, KEY_E:
				interact()
			KEY_I:
				inv_ctrl.open()
			KEY_TAB:
				system_ctrl.open()
			KEY_BACKSPACE:
				if confirm_reset:
					GameState.delete_save()
					confirm_reset = false
					get_tree().change_scene_to_file("res://locations/guild/scenes/guild.tscn")
				else:
					confirm_reset = true
					GameState.message = "Naciśnij Backspace ponownie, aby skasować zapis."
	queue_redraw()


func interact() -> void:
	match nearest_station():
		"guild":
			get_tree().change_scene_to_file("res://locations/guild/scenes/guild.tscn")
		"mayor":
			mayor_open = true
			mayor_timer = 18.0
			mayor_cursor = 0
		"smith":
			smith_open = true
			smith_cursor = 0
		"gate":
			if GameState.begin_run():
				get_tree().change_scene_to_file("res://locations/dungeon/scenes/dungeon.tscn")
			elif not GameState.message.begins_with("Błąd zapisu:"):
				GameState.message = "Nie można rozpocząć kolejnej wyprawy."
		_:
			GameState.message = "Podejdź do gildii, ratusza, warsztatu albo głównej bramy."


func smith_input(keycode: int) -> void:
	var recipes := Smith.recipes_for_class(GameState.player_class)
	var option_count := recipes.size() if not recipes.is_empty() else Smith.STOCK.size()
	match keycode:
		KEY_ESCAPE:
			smith_open = false
		KEY_UP, KEY_W:
			smith_cursor = (smith_cursor - 1 + option_count) % option_count
		KEY_DOWN, KEY_S:
			smith_cursor = (smith_cursor + 1) % option_count
		KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE:
			if recipes.is_empty():
				Smith.buy_item(smith_cursor)
			else:
				Smith.craft(smith_cursor)


func mayor_choices() -> Array:
	return [
		{"label": "Zaoferuj pomoc miastu.", "delta": 12},
		{"label": "Porozmawiaj rzeczowo o gildii.", "delta": 4},
		{"label": "Zlekceważ prośbę o spotkanie.", "delta": -12},
	]


func mayor_input(keycode: int) -> void:
	match keycode:
		KEY_ESCAPE:
			mayor_open = false
		KEY_UP, KEY_W:
			mayor_cursor = (mayor_cursor - 1 + mayor_choices().size()) % mayor_choices().size()
		KEY_DOWN, KEY_S:
			mayor_cursor = (mayor_cursor + 1) % mayor_choices().size()
		KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE:
			var choice: Dictionary = mayor_choices()[mayor_cursor]
			var before := GameState.get_relation("burmistrz")
			var after := adjust_mayor_relation(int(choice["delta"]))
			mayor_open = false
			mayor_timer = 0.0
			GameState.message = "Burmistrz: %s Relacja %d → %d." % [choice["label"], before, after]
			append_mutiny_notice()
			GameState.save_game()


func adjust_mayor_relation(delta: int) -> int:
	return GameState.modify_relation("burmistrz", delta)


func append_mutiny_notice() -> void:
	var mutiny := GameState.member_system.check_mutiny(
		GameState.members, GameState.get_relation("burmistrz"))
	if not mutiny.is_empty():
		GameState.message += " Członkowie z ego buntują się: %s." % ", ".join(PackedStringArray(mutiny))


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var viewport_size := get_viewport_rect().size
	var camera_origin := camera_top_left(viewport_size)
	draw_set_transform(-camera_origin)
	draw_city(font)
	draw_interaction_marker(font)
	draw_player_sprite()
	draw_set_transform(Vector2.ZERO)

	CityUI.draw_hud(self, font, viewport_size, player_pos, nearest_station(), STATIONS, CITY_ROOMS, CITY_SIZE)
	if system_ctrl.is_open():
		system_ctrl.draw(self, font, viewport_size)
	if smith_open:
		Smith.draw_overlay(self, font, viewport_size, smith_cursor)
	if mayor_open:
		CityUI.draw_mayor_overlay(self, font, viewport_size, mayor_cursor, mayor_timer, mayor_choices())
	if inv_ctrl.is_open():
		inv_ctrl.draw(self, font, viewport_size)


func camera_top_left(viewport_size: Vector2) -> Vector2:
	return Vector2(
		clampf(player_pos.x - viewport_size.x * 0.5, 0.0, maxf(0.0, CITY_SIZE.x - viewport_size.x)),
		clampf(player_pos.y - viewport_size.y * 0.5, 0.0, maxf(0.0, CITY_SIZE.y - viewport_size.y))
	)


func draw_city(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, CITY_SIZE), GRASS)
	draw_ground_detail()
	draw_river(font)
	draw_roads()
	draw_city_walls()
	draw_plaza(font)
	draw_trees()
	for building: Dictionary in BUILDINGS:
		var rect: Rect2 = building["rect"]
		match building["type"]:
			"guild":
				draw_building_sprite(font, rect, GUILD_SPRITE, Vector2(330, 270), "GILDIA")
			"mayor":
				draw_building_sprite(font, rect, MAYOR_SPRITE, Vector2(340, 264), "RATUSZ")
			"smith":
				draw_building_sprite(font, rect, SMITH_SPRITE, Vector2(320, 252), "KOWAL")
			"tavern":
				draw_building_sprite(font, rect, TAVERN_SPRITE, Vector2(320, 256), "KARCZMA")
			"chapel":
				draw_building_sprite(font, rect, CHAPEL_SPRITE, Vector2(290, 268), "KAPLICA")
			"stable":
				draw_building_sprite(font, rect, STABLE_SPRITE, Vector2(340, 249), "STAJNIA")
			_:
				draw_house_sprite(rect)
	draw_street_life(font)
	draw_gate(font)
	draw_city_sign(font)
	draw_citizens()


func draw_ground_detail() -> void:
	const TILE_SIZE := 128.0
	const ATLAS_TILE_SIZE := 181.0
	for tile_x in ceili(CITY_SIZE.x / TILE_SIZE):
		for tile_y in ceili(CITY_SIZE.y / TILE_SIZE):
			var cell := Vector2i(tile_x, tile_y)
			var seed := hash(cell)
			var atlas_x := 0.0
			if posmod(seed, 17) == 0:
				atlas_x = ATLAS_TILE_SIZE
			elif posmod(seed, 11) == 0:
				atlas_x = ATLAS_TILE_SIZE * 2.0
			var destination := Rect2(Vector2(tile_x, tile_y) * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE))
			var source := Rect2(Vector2(atlas_x, 0.0), Vector2(ATLAS_TILE_SIZE, ATLAS_TILE_SIZE))
			draw_texture_rect_region(CITY_TILESET, destination, source)


func draw_river(font: Font) -> void:
	draw_colored_polygon(river_polygon, Color(0.09, 0.27, 0.34))
	var water := river_polygon.duplicate()
	for i in water.size():
		water[i] += Vector2(0, -12)
	draw_colored_polygon(water, Color(0.16, 0.42, 0.5))
	for x in range(120, int(CITY_SIZE.x), 210):
		var y := 2190.0 + sin(float(x) * 0.01) * 46.0
		draw_line(Vector2(x, y), Vector2(x + 58, y - 8), Color(0.63, 0.78, 0.73, 0.55), 3.0)
		draw_line(Vector2(x + 28, y + 18), Vector2(x + 72, y + 14), Color(0.63, 0.78, 0.73, 0.35), 2.0)
	draw_string(font, Vector2(2060, 2375), "RZEKA VAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.83, 0.89, 0.79))


func draw_roads() -> void:
	var road := Color(0.58, 0.52, 0.42)
	var road_edge := Color(0.36, 0.34, 0.29)
	for column in range(1, CITY_ROOMS.x):
		var x := float(column) * ROOM_SIZE.x
		draw_street(Rect2(x - 46.0, 96.0, 92.0, CITY_SIZE.y - 192.0), road, road_edge, true)
	for row in range(1, CITY_ROOMS.y):
		var y := float(row) * ROOM_SIZE.y
		if y > 2080.0 and y < 2500.0:
			continue
		draw_street(Rect2(96.0, y - 42.0, CITY_SIZE.x - 192.0, 84.0), road, road_edge, false)
	draw_street(Rect2(1750.0, 96.0, 100.0, CITY_SIZE.y - 192.0), road.lightened(0.04), road_edge, true)
	draw_street(Rect2(96.0, 1458.0, CITY_SIZE.x - 192.0, 84.0), road.lightened(0.04), road_edge, false)
	draw_rect(Rect2(1690.0, 1400.0, 220.0, 200.0), Color(0.63, 0.56, 0.43))


func draw_street(rect: Rect2, road: Color, edge: Color, vertical: bool) -> void:
	draw_rect(rect.grow(8.0), edge)
	draw_rect(rect, road)
	if vertical:
		for y in range(int(rect.position.y) + 16, int(rect.end.y), 48):
			draw_line(Vector2(rect.position.x + 6.0, y), Vector2(rect.end.x - 6.0, y + 22.0), road.darkened(0.09), 2.0)
			draw_line(Vector2(rect.position.x + 9.0, y + 4.0), Vector2(rect.position.x + 40.0, y + 18.0), road.lightened(0.12), 1.0)
	else:
		for x in range(int(rect.position.x) + 16, int(rect.end.x), 48):
			draw_line(Vector2(x, rect.position.y + 5.0), Vector2(x + 22.0, rect.end.y - 5.0), road.darkened(0.09), 2.0)
			draw_line(Vector2(x + 4.0, rect.position.y + 9.0), Vector2(x + 18.0, rect.position.y + 36.0), road.lightened(0.12), 1.0)
	for offset in range(12, int(rect.size.x if vertical else rect.size.y), 48):
		if vertical:
			draw_line(Vector2(rect.position.x + 2.0, rect.position.y + offset), Vector2(rect.position.x + 10.0, rect.position.y + offset), edge.lightened(0.22), 2.0)
			draw_line(Vector2(rect.end.x - 10.0, rect.position.y + offset), Vector2(rect.end.x - 2.0, rect.position.y + offset), edge.lightened(0.22), 2.0)
		else:
			draw_line(Vector2(rect.position.x + offset, rect.position.y + 2.0), Vector2(rect.position.x + offset, rect.position.y + 10.0), edge.lightened(0.22), 2.0)
			draw_line(Vector2(rect.position.x + offset, rect.end.y - 10.0), Vector2(rect.position.x + offset, rect.end.y - 2.0), edge.lightened(0.22), 2.0)


func draw_city_walls() -> void:
	var wall_color := Color(0.43, 0.46, 0.41)
	var outline := Color(0.22, 0.27, 0.24)
	var walls := city_walls()
	for wall: Rect2 in walls:
		draw_rect(wall, wall_color)
		draw_rect(wall, outline, false, 4.0)
		if wall.size.x > wall.size.y:
			for x in range(int(wall.position.x) + 42, int(wall.end.x), 72):
				draw_line(Vector2(x, wall.position.y + 5), Vector2(x + 28, wall.position.y + 31), wall_color.lightened(0.15), 2.0)
		else:
			for y in range(int(wall.position.y) + 42, int(wall.end.y), 72):
				draw_line(Vector2(wall.position.x + 5, y), Vector2(wall.position.x + 31, y + 28), wall_color.lightened(0.15), 2.0)
	for x in range(120, int(CITY_SIZE.x) - 120, 180):
		draw_rect(Rect2(x, 48, 42, 48), wall_color.lightened(0.12))
		if x < 1650 or x > 1950:
			draw_rect(Rect2(x, CITY_SIZE.y - 96.0, 42, 48), wall_color.lightened(0.12))
	for y in range(120, int(CITY_SIZE.y) - 120, 180):
		draw_rect(Rect2(48, y, 48, 42), wall_color.lightened(0.12))
		draw_rect(Rect2(CITY_SIZE.x - 96.0, y, 48, 42), wall_color.lightened(0.12))


func draw_plaza(font: Font) -> void:
	var center := Vector2(1800, 1500)
	var plaza := Rect2(center - Vector2(190, 174), Vector2(380, 348))
	draw_rect(plaza.grow(12), Color(0.35, 0.33, 0.27))
	draw_rect(plaza, Color(0.68, 0.61, 0.48))
	for x in range(int(plaza.position.x) + 24, int(plaza.end.x), 48):
		for y in range(int(plaza.position.y) + 24, int(plaza.end.y), 48):
			draw_rect(Rect2(x, y, 44, 44), Color(0.73, 0.66, 0.52, 0.35), false, 1.0)
	draw_circle(center + Vector2(5, 8), 91, Color(0.35, 0.33, 0.27))
	draw_circle(center, 87, Color(0.49, 0.46, 0.37))
	draw_circle(center, 72, Color(0.76, 0.68, 0.52))
	draw_circle(center, 54, Color(0.18, 0.36, 0.39))
	draw_circle(center, 43, Color(0.28, 0.58, 0.61))
	draw_arc(center, 43, city_time * 0.2, city_time * 0.2 + TAU * 0.72, 40, Color(0.69, 0.86, 0.75), 3.0)
	draw_circle(center + Vector2(0, -7), 8, Color(0.86, 0.93, 0.75))
	draw_string(font, center + Vector2(-35, -112), "RYNEK", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.98, 0.88, 0.62))
	for point in PLANTERS:
		draw_planter(point)
	draw_market_stall(Vector2(1660, 1510), Color(0.69, 0.24, 0.18), "JARZYNY")
	draw_market_stall(Vector2(1940, 1510), Color(0.22, 0.38, 0.55), "TOWARY")


func draw_planter(center: Vector2) -> void:
	draw_rect(Rect2(center - Vector2(29, 20), Vector2(58, 40)), Color(0.37, 0.3, 0.23))
	draw_rect(Rect2(center - Vector2(24, 15), Vector2(48, 30)), Color(0.27, 0.4, 0.24))
	draw_circle(center, 10, Color(0.39, 0.55, 0.3))
	draw_circle(center + Vector2(-9, 3), 6, Color(0.54, 0.63, 0.34))
	draw_circle(center + Vector2(8, -4), 7, Color(0.48, 0.6, 0.32))


func draw_market_stall(center: Vector2, canopy: Color, label: String) -> void:
	draw_rect(Rect2(center + Vector2(-44, 14), Vector2(88, 39)), Color(0.31, 0.23, 0.16))
	draw_rect(Rect2(center + Vector2(-50, -15), Vector2(100, 37)), canopy)
	draw_rect(Rect2(center + Vector2(-50, -15), Vector2(100, 37)), Color(0.16, 0.17, 0.14), false, 3.0)
	for x in [-42.0, -20.0, 2.0, 24.0]:
		draw_rect(Rect2(center + Vector2(x, -15), Vector2(11, 37)), canopy.lightened(0.18))
	draw_rect(Rect2(center + Vector2(-43, 20), Vector2(86, 7)), Color(0.72, 0.58, 0.36))
	draw_string(ThemeDB.fallback_font, center + Vector2(-34, 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)


func draw_building(font: Font, rect: Rect2, body: Color, roof: Color, label: String, icon: String) -> void:
	draw_rect(rect.grow(14.0).abs(), Color(0.12, 0.17, 0.11, 0.5))
	var facade := Rect2(rect.position.x + 10.0, rect.position.y + rect.size.y * 0.42, rect.size.x - 20.0, rect.size.y * 0.52)
	draw_rect(facade, body.darkened(0.18))
	draw_rect(Rect2(facade.position.x, facade.position.y + 9.0, facade.size.x, facade.size.y - 9.0), body)
	draw_rect(Rect2(facade.position.x, rect.end.y - 24.0, facade.size.x, 13.0), body.lightened(0.16))
	draw_line(Vector2(facade.position.x, rect.end.y - 10.0), Vector2(facade.end.x, rect.end.y - 10.0), body.darkened(0.28), 3.0)
	var roof_points := PackedVector2Array([
		Vector2(rect.position.x - 7.0, rect.position.y + rect.size.y * 0.43),
		Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y - 8.0),
		Vector2(rect.end.x + 7.0, rect.position.y + rect.size.y * 0.43),
		Vector2(rect.end.x - 5.0, rect.position.y + rect.size.y * 0.68),
		Vector2(rect.position.x + 5.0, rect.position.y + rect.size.y * 0.68),
	])
	draw_colored_polygon(roof_points, roof.darkened(0.12))
	var roof_highlight := PackedVector2Array([
		roof_points[0], roof_points[1], Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.6),
		Vector2(rect.position.x + 5.0, rect.position.y + rect.size.y * 0.68),
	])
	draw_colored_polygon(roof_highlight, roof.lightened(0.1))
	draw_line(roof_points[1], Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.68), roof.darkened(0.3), 3.0)
	for row in range(1, 5):
		var y := rect.position.y + float(row) * 13.0
		var inset := float(row) * 8.0
		draw_line(Vector2(rect.position.x + inset, y), Vector2(rect.end.x - inset, y), roof.darkened(0.24), 2.0)
		for x in range(int(rect.position.x + inset + 18.0), int(rect.end.x - inset), 34):
			draw_line(Vector2(x, y), Vector2(x + 12.0, y + 9.0), roof.lightened(0.12), 1.5)
	if icon == "K":
		draw_rect(Rect2(rect.position.x + rect.size.x * 0.68, rect.position.y + 8.0, 18.0, 34.0), Color(0.32, 0.29, 0.27))
		draw_rect(Rect2(rect.position.x + rect.size.x * 0.68 - 4.0, rect.position.y + 5.0, 26.0, 8.0), Color(0.55, 0.48, 0.37))
	if icon == "T":
		var awning := Rect2(rect.position.x + 24.0, rect.end.y - 58.0, rect.size.x - 48.0, 12.0)
		draw_rect(awning, Color(0.79, 0.61, 0.36))
		for x in range(int(awning.position.x), int(awning.end.x), 20):
			draw_rect(Rect2(x, awning.position.y, 9.0, awning.size.y), Color(0.61, 0.22, 0.16))
	if icon == "S":
		var steeple := PackedVector2Array([
			Vector2(rect.position.x + rect.size.x * 0.5 - 14.0, rect.position.y + 31.0),
			Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y - 30.0),
			Vector2(rect.position.x + rect.size.x * 0.5 + 14.0, rect.position.y + 31.0),
		])
		draw_colored_polygon(steeple, Color(0.6, 0.48, 0.3))
		draw_rect(Rect2(rect.position.x + rect.size.x * 0.5 - 8.0, rect.position.y + 25.0, 16.0, 32.0), Color(0.56, 0.47, 0.34))
		draw_line(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y - 26.0), Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y - 43.0), GOLD, 2.0)
		draw_line(Vector2(rect.position.x + rect.size.x * 0.5 - 6.0, rect.position.y - 36.0), Vector2(rect.position.x + rect.size.x * 0.5 + 6.0, rect.position.y - 36.0), GOLD, 2.0)
	if icon == "H":
		draw_rect(Rect2(rect.position.x + rect.size.x * 0.5 - 28.0, rect.end.y - 52.0, 56.0, 48.0), Color(0.29, 0.21, 0.14))
		draw_line(Vector2(rect.position.x + rect.size.x * 0.5, rect.end.y - 51.0), Vector2(rect.position.x + rect.size.x * 0.5, rect.end.y - 5.0), Color(0.65, 0.49, 0.31), 3.0)
		draw_line(Vector2(rect.position.x + rect.size.x * 0.5 - 28.0, rect.end.y - 28.0), Vector2(rect.position.x + rect.size.x * 0.5 + 28.0, rect.end.y - 28.0), Color(0.65, 0.49, 0.31), 2.0)
	draw_windows(font, rect)
	var door := Rect2(Vector2(rect.position.x + rect.size.x * 0.5 - 12.0, rect.end.y - 43.0), Vector2(24.0, 41.0))
	draw_rect(door.grow(4.0), Color(0.26, 0.2, 0.14))
	draw_rect(door, Color(0.2, 0.12, 0.08))
	draw_rect(Rect2(door.position + Vector2(4.0, 5.0), Vector2(door.size.x - 8.0, door.size.y - 8.0)), Color(0.35, 0.23, 0.14))
	draw_circle(door.position + Vector2(18.0, 23.0), 2.0, GOLD)
	draw_rect(Rect2(rect.position.x + rect.size.x * 0.5 - 24.0, rect.end.y - 3.0, 48.0, 11.0), STONE.darkened(0.12))
	if not label.is_empty():
		var sign_rect := Rect2(rect.position.x + rect.size.x * 0.5 - 42.0, rect.position.y - 26.0, 84.0, 24.0)
		draw_rect(sign_rect.grow(3.0), Color(0.17, 0.13, 0.1))
		draw_rect(sign_rect, Color(0.23, 0.19, 0.14))
		draw_rect(sign_rect, GOLD.darkened(0.35), false, 1.5)
		draw_string(font, sign_rect.position + Vector2(8.0, 17.0), label, HORIZONTAL_ALIGNMENT_CENTER, 68, 13, Color(0.99, 0.88, 0.65))
		draw_circle(rect.position + rect.size * Vector2(0.5, 0.48), 16.0, Color(0.12, 0.15, 0.14))
		draw_string(font, rect.position + rect.size * Vector2(0.5, 0.48) + Vector2(-5.0, 6.0), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, GOLD)


func draw_building_sprite(font: Font, rect: Rect2, texture: Texture2D, size: Vector2, label: String) -> void:
	var destination := Rect2(Vector2(rect.get_center().x - size.x * 0.5, rect.end.y - size.y), size)
	draw_texture_rect(texture, destination, false)
	draw_string(font, Vector2(rect.get_center().x - 54.0, destination.position.y - 9.0), label, HORIZONTAL_ALIGNMENT_CENTER, 108.0, 15, GOLD)


func draw_house_sprite(rect: Rect2) -> void:
	var variant := posmod(int(rect.position.x / 24.0 + rect.position.y / 16.0), 3)
	var source_regions: Array[Rect2] = [
		Rect2(25, 225, 430, 705),
		Rect2(465, 225, 455, 705),
		Rect2(895, 220, 475, 720),
	]
	var source := source_regions[variant]
	var width := rect.size.x * 1.08
	var size := Vector2(width, width * source.size.y / source.size.x)
	var destination := Rect2(Vector2(rect.get_center().x - size.x * 0.5, rect.end.y - size.y), size)
	draw_texture_rect_region(HOUSE_SPRITESHEET, destination, source)


func draw_windows(font: Font, rect: Rect2) -> void:
	for x in [rect.position.x + 28.0, rect.end.x - 48.0]:
		var window := Rect2(x, rect.position.y + rect.size.y * 0.69, 20.0, 24.0)
		draw_rect(window.grow(4.0), Color(0.23, 0.2, 0.15))
		draw_rect(window, Color(0.77, 0.72, 0.52))
		draw_rect(Rect2(window.position + Vector2(3.0, 3.0), window.size - Vector2(6.0, 6.0)), Color(0.45, 0.62, 0.61))
		draw_line(Vector2(x + 10.0, window.position.y), Vector2(x + 10.0, window.end.y), Color(0.22, 0.2, 0.16), 2.0)
		draw_line(Vector2(x, window.position.y + 12.0), Vector2(x + 20.0, window.position.y + 12.0), Color(0.22, 0.2, 0.16), 2.0)
		draw_line(Vector2(x - 4.0, window.position.y - 3.0), Vector2(x + 24.0, window.position.y - 3.0), Color(0.73, 0.53, 0.32), 3.0)


func draw_trees() -> void:
	for tree in TREES:
		draw_circle(tree + Vector2(6, 12), 28, Color(0.12, 0.19, 0.12, 0.42))
		draw_rect(Rect2(tree.x - 5, tree.y + 7, 10, 24), Color(0.32, 0.23, 0.14))
		draw_circle(tree + Vector2(-10, 1), 22, Color(0.18, 0.35, 0.19))
		draw_circle(tree + Vector2(10, -7), 23, Color(0.2, 0.39, 0.21))
		draw_circle(tree + Vector2(0, -16), 22, Color(0.25, 0.44, 0.23))
		draw_circle(tree + Vector2(-7, -22), 9, Color(0.37, 0.53, 0.27))
		draw_circle(tree + Vector2(12, -5), 8, Color(0.34, 0.5, 0.25))


func draw_gate(font: Font) -> void:
	var gate_y := CITY_SIZE.y - 178.0
	for x in [1660.0, 1940.0]:
		var tower := Rect2(x - 34.0, gate_y - 6.0, 68.0, 132.0)
		draw_rect(tower.grow(7.0), Color(0.19, 0.23, 0.2))
		draw_rect(tower, Color(0.48, 0.49, 0.41))
		draw_rect(Rect2(tower.position.x + 8.0, tower.position.y + 14.0, tower.size.x - 16.0, 18.0), Color(0.65, 0.61, 0.48))
		draw_rect(tower, Color(0.22, 0.25, 0.21), false, 3.0)
		for y in range(int(tower.position.y + 42.0), int(tower.end.y - 12.0), 28):
			draw_line(Vector2(tower.position.x + 4.0, y), Vector2(tower.end.x - 4.0, y), Color(0.31, 0.34, 0.3), 2.0)
	draw_rect(Rect2(1694.0, gate_y + 40.0, 212.0, 82.0), Color(0.25, 0.17, 0.11))
	draw_rect(Rect2(1703.0, gate_y + 45.0, 194.0, 69.0), Color(0.46, 0.34, 0.22))
	draw_line(Vector2(1800.0, gate_y + 46.0), Vector2(1800.0, gate_y + 112.0), Color(0.22, 0.17, 0.12), 4.0)
	draw_string(font, Vector2(1705, gate_y - 22.0), "VALDORIA  •  GŁÓWNA BRAMA", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, GOLD)


func draw_street_life(font: Font) -> void:
	for lamp in LAMPS:
		draw_lamppost(lamp)
	draw_bridge()
	draw_bench(Vector2(1535, 1490), -0.15)
	draw_bench(Vector2(2060, 1490), 0.15)
	draw_signpost(Vector2(1568, 1325), "GILDIA")
	draw_signpost(Vector2(1885, 835), "RATUSZ")
	draw_signpost(Vector2(2585, 1500), "KOWAL")


func draw_lamppost(pos: Vector2) -> void:
	var glow := 0.15 + (sin(city_time * 2.0 + pos.x) + 1.0) * 0.06
	draw_circle(pos, 25.0, Color(1.0, 0.72, 0.34, glow))
	draw_circle(pos + Vector2(3, 8), 10.0, Color(0.11, 0.15, 0.13, 0.5))
	draw_rect(Rect2(pos.x - 3.0, pos.y - 26.0, 6.0, 35.0), Color(0.22, 0.2, 0.16))
	draw_rect(Rect2(pos.x - 10.0, pos.y - 32.0, 20.0, 10.0), Color(0.28, 0.25, 0.19))
	draw_circle(pos + Vector2(0, -27), 6.0, Color(1.0, 0.82, 0.48))
	draw_line(pos + Vector2(-11, 10), pos + Vector2(11, 10), Color(0.18, 0.19, 0.15), 3.0)


func draw_bridge() -> void:
	var bridge := Rect2(1736.0, 2152.0, 128.0, 334.0)
	draw_rect(bridge.grow(16.0), Color(0.24, 0.25, 0.22))
	draw_rect(bridge, Color(0.51, 0.46, 0.36))
	draw_rect(Rect2(bridge.position.x + 13.0, bridge.position.y, 10.0, bridge.size.y), Color(0.66, 0.59, 0.46))
	draw_rect(Rect2(bridge.end.x - 23.0, bridge.position.y, 10.0, bridge.size.y), Color(0.66, 0.59, 0.46))
	for y in range(int(bridge.position.y + 15.0), int(bridge.end.y), 28):
		draw_line(Vector2(bridge.position.x + 25.0, y), Vector2(bridge.end.x - 25.0, y), Color(0.35, 0.33, 0.28), 2.0)
	for y in range(int(bridge.position.y + 24.0), int(bridge.end.y - 12.0), 48):
		draw_rect(Rect2(bridge.position.x - 3.0, y, 16.0, 18.0), Color(0.55, 0.53, 0.46))
		draw_rect(Rect2(bridge.end.x - 13.0, y, 16.0, 18.0), Color(0.55, 0.53, 0.46))


func draw_bench(pos: Vector2, angle: float) -> void:
	var plank := PackedVector2Array([
		pos + Vector2(-26, -8).rotated(angle), pos + Vector2(26, -8).rotated(angle),
		pos + Vector2(26, 8).rotated(angle), pos + Vector2(-26, 8).rotated(angle),
	])
	draw_colored_polygon(plank, Color(0.42, 0.27, 0.15))
	draw_line(pos + Vector2(-17, -7).rotated(angle), pos + Vector2(-17, 9).rotated(angle), Color(0.22, 0.19, 0.14), 4.0)
	draw_line(pos + Vector2(17, -7).rotated(angle), pos + Vector2(17, 9).rotated(angle), Color(0.22, 0.19, 0.14), 4.0)


func draw_signpost(pos: Vector2, label: String) -> void:
	draw_rect(Rect2(pos.x - 2.0, pos.y - 9.0, 4.0, 34.0), Color(0.3, 0.22, 0.14))
	draw_rect(Rect2(pos.x - 26.0, pos.y - 21.0, 52.0, 19.0), Color(0.41, 0.29, 0.18))
	draw_rect(Rect2(pos.x - 26.0, pos.y - 21.0, 52.0, 19.0), Color(0.81, 0.65, 0.39), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(pos.x - 22.0, pos.y - 8.0), label, HORIZONTAL_ALIGNMENT_LEFT, 46, 9, Color(0.98, 0.89, 0.66))


func draw_citizens() -> void:
	for citizen: Dictionary in CITIZENS:
		var center: Vector2 = citizen["center"]
		var phase: float = citizen["phase"]
		var angle := city_time * float(citizen["speed"]) + phase
		var pos := center + Vector2(cos(angle) * float(citizen["radius"]), sin(angle) * float(citizen["radius"]) * 0.55)
		var direction := Vector2(-sin(angle), cos(angle)).normalized()
		var sprite_group: int = citizen["sprite"]
		var frame := int(floor(city_time * 6.0 + phase)) % 4
		draw_character_sprite(pos, direction, frame, sprite_group)


func draw_player_sprite() -> void:
	var row := direction_row(facing)
	var frame := int(player_animation_time * 9.0) % 4 if player_moving else 0
	var source := Rect2(Vector2(frame * 48, row * 48), Vector2(48, 48))
	var destination := Rect2(player_pos + Vector2(-32, -60), Vector2(64, 64))
	draw_circle(player_pos + Vector2(0, 4), 14.0, Color(0.1, 0.13, 0.11, 0.42))
	draw_texture_rect_region(PLAYER_SPRITESHEET, destination, source)


func draw_character_sprite(pos: Vector2, direction: Vector2, frame: int, sprite_group: int) -> void:
	var column_offset := (sprite_group % 3) * 512
	var row_offset := floori(float(sprite_group) / 3.0) * 512
	var source := Rect2(Vector2(column_offset + frame * 128, row_offset + direction_row(direction) * 128), Vector2(128, 128))
	var destination := Rect2(pos + Vector2(-34, -72), Vector2(68, 76))
	draw_circle(pos + Vector2(0, 5), 13.0, Color(0.1, 0.13, 0.11, 0.38))
	draw_texture_rect_region(CITIZEN_SPRITESHEET, destination, source)


func direction_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 1 if direction.x < 0.0 else 2
	return 3 if direction.y < 0.0 else 0


func draw_city_sign(font: Font) -> void:
	var sign := Rect2(1130, 170, 410, 78)
	draw_rect(sign.grow(9.0), Color(0.1, 0.13, 0.12, 0.72))
	draw_rect(sign, Color(0.17, 0.2, 0.18))
	draw_rect(sign, GOLD.darkened(0.3), false, 3.0)
	draw_rect(sign.grow(-8.0), Color(0.2, 0.23, 0.2), false, 1.0)
	draw_string(font, Vector2(1160, 211), "VALDORIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 31, GOLD)
	draw_string(font, Vector2(1162, 235), "MIASTO GILDII  •  ZAŁOŻONE 742 LATA TEMU", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.91, 0.87, 0.75))


func draw_interaction_marker(font: Font) -> void:
	var station_id := nearest_station()
	if station_id.is_empty():
		return
	var station: Dictionary = STATIONS[station_id]
	var pos: Vector2 = station["position"]
	var pulse := 1.0 + sin(city_time * 3.2) * 0.08
	draw_circle(pos, 26.0 * pulse, Color(0.98, 0.76, 0.29, 0.12))
	draw_arc(pos, 23.0 * pulse, 0.0, TAU, 32, GOLD, 2.0)
	draw_circle(pos + Vector2(0, -38), 13.0, Color(0.1, 0.13, 0.12, 0.92))
	draw_circle(pos + Vector2(0, -38), 13.0, GOLD, false, 2.0)
	draw_string(font, pos + Vector2(-5, -33), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, GOLD)
