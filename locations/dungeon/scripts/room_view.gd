extends RefCounted
# Rysowanie pokoju w lochu: podłoga, ściany, przedmioty, wrogowie, gracz.
# Dane bierze z węzła main.gd (parametr m), niczego nie zmienia.

const Items = preload("res://locations/dungeon/scripts/items.gd")
const Dungeon = preload("res://locations/dungeon/scripts/dungeon.gd")
const Balance = preload("res://shared/scripts/balance.gd")
const TILESET: Texture2D = preload("res://locations/dungeon/assets/tilesets/Pikselowy zestaw kafelków lochu fantasy.png")
const ENEMY_SPRITESHEET: Texture2D = preload("res://locations/dungeon/assets/enemies/Potworzy atlas pikselowych sprite’ów.png")
const PLAYER_SPRITESHEET: Texture2D = preload("res://shared/assets/characters/bohater_spritesheet.png")
const ALLY_SPRITESHEET: Texture2D = preload("res://locations/city/assets/characters/Sześć pikselowych arkuszy postaci RPG.png")

const TILE := 48
const ORIGIN := Vector2(24, 24)
const MINI_ORIGIN := Vector2(800, 40)
const ATLAS_SPRITE_SIZE := 180.0
const ATLAS_COLUMN_START := 80.0
const ATLAS_COLUMN_STEP := 210.0
const ATLAS_ROW_STARTS := [15.0, 195.0, 372.0, 540.0, 716.0, 895.0]


static func tile_center(t: Vector2i) -> Vector2:
	return Vector2(t * TILE) + Vector2(TILE, TILE) * 0.5


static func tile_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


static func cell_rect(pos: Vector2i, margin: float = 0.0) -> Rect2:
	return Rect2(
		ORIGIN + Vector2(pos * TILE) + Vector2(margin, margin),
		Vector2(TILE - margin * 2, TILE - margin * 2))


static func draw_bar(canvas: CanvasItem, pos: Vector2, size: Vector2, ratio: float, color: Color) -> void:
	var outer := Rect2(pos, size)
	canvas.draw_rect(outer, Color(0.015, 0.02, 0.02, 0.96))
	var inner := outer.grow(-1.0) if size.y > 4.0 else outer
	canvas.draw_rect(Rect2(inner.position, Vector2(inner.size.x * clampf(ratio, 0.0, 1.0), inner.size.y)), color)
	canvas.draw_rect(outer, Color(0.69, 0.63, 0.5, 0.8), false, 1.0)


static func draw_room(canvas: CanvasItem, m, font: Font) -> void:
	var dungeon = m.dungeon
	var rw: int = Dungeon.ROOM_W
	var rh: int = Dungeon.ROOM_H
	var cx: int = Dungeon.CX
	var cy: int = Dungeon.CY
	var room: Dictionary = dungeon.current_room()
	var cleared: bool = room["enemies"].is_empty()

	var player_pos: Vector2 = m.player_pos
	var facing: Vector2 = m.facing
	var skill_fx: float = m.skill_fx
	var skill_fx_color: Color = m.skill_fx_color
	var skill_fx_type: String = m.skill_fx_type
	var skill_fx_target: Vector2 = m.skill_fx_target
	var skill_fx_radius: float = m.skill_fx_radius
	var guard_timer: float = m.guard_timer
	var forge_timer: float = m.forge_timer
	var swing_timer: float = m.swing_timer
	var hurt_flash: float = m.hurt_flash
	var dash_timer: float = m.dash_timer
	var invuln: float = m.invuln
	var game_over: bool = m.game_over
	var floats: Array = m.floats
	var allies: Array = m.current_allies

	# kafelkowa podłoga i obudowa pokoju
	canvas.draw_rect(Rect2(ORIGIN, Vector2(rw * TILE, rh * TILE)), Color(0.07, 0.075, 0.08))
	for x in rw:
		for y in rh:
			var cell := Vector2i(x, y)
			var edge := x == 0 or y == 0 or x == rw - 1 or y == rh - 1
			var door_dir: Vector2i = dungeon.door_direction(cell) if edge else Vector2i.ZERO
			var has_open_door: bool = door_dir != Vector2i.ZERO and room["doors"].has(door_dir)
			if edge and has_open_door:
				draw_dungeon_tile(canvas, Vector2i(0 if door_dir.x == 0 else 2, 3), cell_rect(cell))
			elif edge:
				draw_dungeon_tile(canvas, Vector2i(0, 2), cell_rect(cell))
			else:
				var floor_variant := 0 if m.floor_num % 3 != 0 else 3
				draw_dungeon_tile(canvas, Vector2i(floor_variant, 0), cell_rect(cell))

	# przeszkody skalne
	for op in room["obstacles"]:
		draw_dungeon_tile(canvas, Vector2i(4, 3), cell_rect(op))

	# portal do miasta
	if dungeon.current == dungeon.start_cell:
		var portal_rect := cell_rect(Vector2i(cx, cy))
		draw_dungeon_tile(canvas, Vector2i(2, 4), portal_rect)

	# schody
	if dungeon.current == dungeon.stairs_cell:
		var stairs_rect := cell_rect(Vector2i(cx, cy))
		draw_dungeon_tile(canvas, Vector2i(1, 4), stairs_rect)
		if not cleared:
			canvas.draw_rect(stairs_rect, Color(0.08, 0.07, 0.06, 0.5))

	# przedmioty na podłodze
	for it in room["items"]:
		Items.draw_icon(canvas, it["item"], ORIGIN + tile_center(it["pos"]), Vector2(32, 32))

	# wrogowie: zapowiedź ataku rośnie aż do ciosu
	for e in room["enemies"]:
		var ep: Vector2 = ORIGIN + e["p"]
		if float(e.get("marked_time", 0.0)) > 0.0:
			canvas.draw_arc(ep, Balance.ENEMY_RADIUS + 7.0, 0, TAU, 24, Color(1.0, 0.82, 0.25, 0.9), 2.0)
		elif float(e.get("slow_time", 0.0)) > 0.0:
			canvas.draw_arc(ep, Balance.ENEMY_RADIUS + 6.0, 0, TAU, 24, Color(0.4, 0.75, 1.0, 0.85), 2.0)
		elif float(e.get("poison_time", 0.0)) > 0.0:
			canvas.draw_arc(ep, Balance.ENEMY_RADIUS + 6.0, 0, TAU, 24, Color(0.5, 0.95, 0.4, 0.85), 2.0)
		elif float(e.get("burn_time", 0.0)) > 0.0:
			canvas.draw_arc(ep, Balance.ENEMY_RADIUS + 6.0, 0, TAU, 24, Color(1.0, 0.45, 0.2, 0.85), 2.0)
		if e["state"] == "windup":
			var progress: float = 1.0 - e["t"] / Balance.ENEMY_WINDUP
			var reach := Balance.ENEMY_HIT_RANGE + Balance.PLAYER_RADIUS
			canvas.draw_circle(ep, reach * progress, Color(1, 0.2, 0.1, 0.18))
			canvas.draw_arc(ep, reach, 0, TAU, 32, Color(1, 0.3, 0.2, 0.7), 2.0)
		draw_enemy_sprite(canvas, m, e, ep)
		if e["hp"] < e["max_hp"]:
			draw_bar(canvas, ep + Vector2(-16, -30), Vector2(32, 4), float(e["hp"]) / e["max_hp"], Color(0.9, 0.25, 0.25))

	# gracz
	var pp := ORIGIN + player_pos
	if skill_fx > 0.0:
		if skill_fx_type == "heal":
			canvas.draw_circle(pp, skill_fx_radius, Color(skill_fx_color.r, skill_fx_color.g, skill_fx_color.b, 0.16))
			canvas.draw_arc(pp, skill_fx_radius, 0, TAU, 48, skill_fx_color, 3.0)
		elif skill_fx_type == "shot":
			canvas.draw_line(pp, ORIGIN + skill_fx_target, skill_fx_color, 5.0)
		elif skill_fx_type in ["bomb", "poison"]:
			var fx_center := ORIGIN + skill_fx_target
			canvas.draw_circle(fx_center, skill_fx_radius, Color(skill_fx_color.r, skill_fx_color.g, skill_fx_color.b, 0.24))
			canvas.draw_arc(fx_center, skill_fx_radius, 0, TAU, 48, skill_fx_color, 3.0)
		elif skill_fx_type in ["spin", "nova"]:
			canvas.draw_circle(pp, skill_fx_radius, Color(skill_fx_color.r, skill_fx_color.g, skill_fx_color.b, 0.25))
			canvas.draw_arc(pp, skill_fx_radius, 0, TAU, 48, skill_fx_color, 3.0)
		else:
			canvas.draw_circle(pp, 25.0, Color(skill_fx_color.r, skill_fx_color.g, skill_fx_color.b, 0.25))
			canvas.draw_arc(pp, 25.0, 0, TAU, 48, skill_fx_color, 3.0)
	if guard_timer > 0.0:
		var guard_radius := float(Balance.class_profile(GameState.player_class).get("skill_radius", 29.0))
		canvas.draw_circle(pp, guard_radius, Color(0.45, 0.8, 1.0, 0.06))
		canvas.draw_arc(pp, guard_radius, 0, TAU, 48, Color(0.45, 0.8, 1.0, 0.7), 2.0)
	if forge_timer > 0.0:
		canvas.draw_arc(pp, 25.0, 0, TAU, 48, Color(1.0, 0.72, 0.3, 0.85), 2.0)
	if swing_timer > 0.0:
		var a := facing.angle()
		var attack_range := Balance.ATTACK_RANGE + float(Balance.class_profile(GameState.player_class).get("passive_attack_range", 0.0))
		canvas.draw_arc(pp, attack_range, a - 1.1, a + 1.1, 16, Color(1, 1, 0.8), 4.0)
	var player_color := Color.WHITE
	if game_over:
		player_color = Color(0.45, 0.45, 0.45)
	elif hurt_flash > 0.0:
		player_color = Color(1.0, 0.35, 0.35)
	elif dash_timer > 0.0:
		player_color = Color(1.0, 1.0, 0.7, 0.65)
	elif invuln > 0.0 and int(invuln * 20) % 2 == 0:
		player_color = Color(1.0, 1.0, 1.0, 0.5)
	draw_player_sprite(canvas, m, pp, player_color)

	# sojusznicy
	for ally in allies:
		if not ally.get("alive", true):
			continue
		var ap: Vector2 = ORIGIN + ally["p"]
		var ally_tint := Color.WHITE if ally["flash"] <= 0.0 else Color(1.0, 0.45, 0.45)
		draw_ally_sprite(canvas, m, ally, ap, ally_tint)
		if ally["hp"] < ally["max_hp"]:
			draw_bar(canvas, ap + Vector2(-16, -30), Vector2(32, 4), float(ally["hp"]) / ally["max_hp"], Color(0.4, 0.6, 1.0))

	# latające napisy
	for f in floats:
		var c: Color = f["color"]
		c.a = clampf(f["t"] / 0.4, 0.0, 1.0)
		canvas.draw_string(font, ORIGIN + f["pos"] + Vector2(-12, 0), f["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, c)


static func draw_dungeon_tile(canvas: CanvasItem, atlas_cell: Vector2i, destination: Rect2) -> void:
	var source := Rect2(
		Vector2(ATLAS_COLUMN_START + atlas_cell.x * ATLAS_COLUMN_STEP, ATLAS_ROW_STARTS[atlas_cell.y]),
		Vector2(ATLAS_SPRITE_SIZE, ATLAS_SPRITE_SIZE))
	canvas.draw_texture_rect_region(TILESET, destination, source)


static func sprite_direction_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 1 if direction.x < 0.0 else 2
	return 3 if direction.y < 0.0 else 0


static func draw_player_sprite(canvas: CanvasItem, m, pos: Vector2, tint: Color) -> void:
	var direction_row := sprite_direction_row(m.facing)
	var frame := int(m.visual_time * 9.0) % 4 if m.player_moving and not m.game_over else 0
	var source := Rect2(Vector2(frame * 48, direction_row * 48), Vector2(48, 48))
	var destination := Rect2(pos + Vector2(-24.0, -48.0), Vector2(48.0, 52.0))
	canvas.draw_circle(pos + Vector2(0.0, 3.0), 13.0, Color(0.02, 0.025, 0.03, 0.55))
	canvas.draw_texture_rect_region(PLAYER_SPRITESHEET, destination, source, tint)


static func draw_enemy_sprite(canvas: CanvasItem, m, enemy: Dictionary, pos: Vector2) -> void:
	var sprite_type: int = int(enemy.get("sprite", 0))
	var atlas_origin := Vector2(256.0, 0.0)
	match sprite_type:
		1:
			atlas_origin = Vector2(896.0, 0.0)
		2:
			atlas_origin = Vector2(256.0, 512.0)
		3:
			atlas_origin = Vector2(896.0, 512.0)
	var facing: Vector2 = enemy.get("facing", Vector2.DOWN)
	var frame := int(m.visual_time * 7.0) % 4
	var source := Rect2(atlas_origin + Vector2(frame * 128, sprite_direction_row(facing) * 128), Vector2(128, 128))
	var tint := Color.WHITE
	if enemy["flash"] > 0.0:
		tint = Color(1.0, 0.65, 0.65)
	elif enemy["state"] == "windup":
		tint = Color(1.0, 0.82, 0.65)
	elif enemy["state"] == "recover":
		tint = Color(0.68, 0.68, 0.72)
	var destination := Rect2(pos + Vector2(-23.0, -47.0), Vector2(46.0, 50.0))
	canvas.draw_circle(pos + Vector2(0.0, 3.0), 14.0, Color(0.02, 0.025, 0.03, 0.55))
	canvas.draw_texture_rect_region(ENEMY_SPRITESHEET, destination, source, tint)


static func draw_ally_sprite(canvas: CanvasItem, m, ally: Dictionary, pos: Vector2, tint: Color) -> void:
	var sprite_group := 0
	match ally.get("class", ""):
		"Hunter":
			sprite_group = 1
		"Mage":
			sprite_group = 2
		_:
			sprite_group = posmod(hash(ally.get("name", "")), 3)
	var direction: Vector2 = ally.get("facing", Vector2.DOWN)
	var frame := int(m.visual_time * 7.0) % 4
	var source := Rect2(
		Vector2((sprite_group % 3) * 512 + frame * 128, floori(float(sprite_group) / 3.0) * 512 + sprite_direction_row(direction) * 128),
		Vector2(128, 128))
	var destination := Rect2(pos + Vector2(-21.0, -44.0), Vector2(42.0, 46.0))
	canvas.draw_circle(pos + Vector2(0.0, 3.0), 13.0, Color(0.02, 0.025, 0.03, 0.5))
	canvas.draw_texture_rect_region(ALLY_SPRITESHEET, destination, source, tint)
