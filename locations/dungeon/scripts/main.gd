extends Node2D
# Loch z walką w czasie rzeczywistym: pętla gry, sterowanie, walka gracza, pokoje i piętra.
# Wrogowie: enemy_ai.gd. Rysowanie: room_view.gd (pokój) i hud.gd (interfejs).

const Items = preload("res://locations/dungeon/scripts/items.gd")
const Dungeon = preload("res://locations/dungeon/scripts/dungeon.gd")
const Balance = preload("res://shared/scripts/balance.gd")
const ClassProgression = preload("res://shared/scripts/class_progression.gd")
const RoomView = preload("res://locations/dungeon/scripts/room_view.gd")
const Hud = preload("res://locations/dungeon/scripts/hud.gd")
const EnemyAI = preload("res://locations/dungeon/scripts/enemy_ai.gd")
const AllyAI = preload("res://locations/dungeon/scripts/ally_ai.gd")
const SystemController = preload("res://shared/scripts/system_controller.gd")
const InventoryController = preload("res://shared/scripts/inventory_controller.gd")

var dungeon = Dungeon.new()
var enemy_ai                         # tworzony w _ready (potrzebuje self)
var ally_ai                           # sojusznicy
var inv = GameState.inv
var floor_num := 1
var run_gold := 0
var log_text := ""
var log_timer := 0.0
var game_over := false
var system_ctrl = SystemController.new()
var inv_ctrl = InventoryController.new()
var current_allies: Array = []       # kopia członków z drużyny dla aktualnego lochu

# gracz (współrzędne w pikselach wewnątrz pokoju)
var player_pos := Vector2.ZERO
var facing := Vector2.RIGHT
var player_hp := 10
var attack_cd := 0.0
var swing_timer := 0.0
var dash_cd := 0.0
var dash_timer := 0.0
var dash_dir := Vector2.ZERO
var skill_cd := 0.0
var skill_fx := 0.0
var skill_fx_color := Color(0.5, 0.8, 1.0)
var skill_fx_type := ""
var skill_fx_target := Vector2.ZERO
var skill_fx_radius := Balance.SKILL_RADIUS
var guard_timer := 0.0
var forge_timer := 0.0
var invuln := 0.0
var hurt_flash := 0.0
var death_timer := 0.0
var floats: Array = []               # latające napisy: {"pos", "text", "color", "t"}
var visual_time := 0.0
var player_moving := false


func _ready() -> void:
	randomize()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	enemy_ai = EnemyAI.new(self)
	ally_ai = AllyAI.new(self)
	floor_num = 1
	run_gold = 0
	player_hp = GameState.hp
	load_party()
	start_floor()
	say("WASD = ruch, J/Spacja = atak, Shift = unik, K = umiejętność, E = podnieś, I = ekwipunek, Tab = rozwój, F = portal/schody.", 8.0)


func start_floor() -> void:
	dungeon.generate(floor_num)
	player_pos = tile_center(Vector2i(Dungeon.CX, Dungeon.CY))
	enemy_ai.prepare_room(dungeon.current_room())
	for ally in current_allies:
		ally_ai.prepare_ally(ally)
	queue_redraw()


func say(text: String, duration: float = 3.0) -> void:
	log_text = text
	log_timer = duration


func load_party() -> void:
	current_allies = []
	var party := GameState.get_party_members()
	for m in party:
		var ally = m.duplicate()
		current_allies.append(ally)


func tile_center(t: Vector2i) -> Vector2:
	return RoomView.tile_center(t)


func tile_of(p: Vector2) -> Vector2i:
	return RoomView.tile_of(p)


# ---------- sterowanie ----------

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
	if game_over:
		return

	match event.keycode:
		KEY_I:
			inv_ctrl.open()
			queue_redraw()
		KEY_TAB:
			system_ctrl.open()
			queue_redraw()
		KEY_E:
			take_item()
		KEY_F:
			interact()
		KEY_J, KEY_SPACE:
			basic_attack()
		KEY_K:
			use_skill()
		KEY_SHIFT:
			start_dash()


func input_direction() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		d.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		d.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		d.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		d.x += 1
	return d.normalized()


# ---------- pętla gry ----------

func _process(delta: float) -> void:
	visual_time += delta
	update_floats(delta)
	if log_timer > 0.0:
		log_timer -= delta
	if game_over:
		death_timer -= delta
		if death_timer <= 0.0:
			if GameState.die_in_dungeon(run_gold, floor_num):
				get_tree().change_scene_to_file("res://locations/city/scenes/city.tscn")
			else:
				death_timer = 1.0
				say(GameState.message, 3.0)
		queue_redraw()
		return
	if inv_ctrl.is_open() or system_ctrl.is_open():
		return  # plecak pauzuje walkę

	attack_cd = maxf(0.0, attack_cd - delta)
	swing_timer = maxf(0.0, swing_timer - delta)
	dash_cd = maxf(0.0, dash_cd - delta)
	skill_cd = maxf(0.0, skill_cd - delta)
	skill_fx = maxf(0.0, skill_fx - delta)
	guard_timer = maxf(0.0, guard_timer - delta)
	forge_timer = maxf(0.0, forge_timer - delta)
	invuln = maxf(0.0, invuln - delta)
	hurt_flash = maxf(0.0, hurt_flash - delta)

	var room: Dictionary = dungeon.current_room()
	update_enemy_effects(room, delta)
	update_player(room, delta)
	enemy_ai.update(room, delta)
	ally_ai.update(room, delta)
	check_transitions(room)
	queue_redraw()


func update_player(room: Dictionary, delta: float) -> void:
	var dir := input_direction()
	if dir != Vector2.ZERO:
		facing = dir
	var velocity := dir * GameState.move_speed()
	if dash_timer > 0.0:
		dash_timer -= delta
		velocity = dash_dir * Balance.DASH_SPEED
	var previous_position := player_pos
	player_pos = move_circle(room, player_pos, velocity * delta, Balance.PLAYER_RADIUS, true)
	player_moving = not player_pos.is_equal_approx(previous_position)
	auto_pickup(room)


# Przejście przez drzwi dzieje się samo. Schody i portal wymagają klawisza F (patrz interact).
func check_transitions(room: Dictionary) -> void:
	var t := tile_of(player_pos)
	var door_dir: Vector2i = dungeon.door_direction(t)
	if door_dir != Vector2i.ZERO and room["doors"].has(door_dir) and room["enemies"].is_empty():
		enter_room(dungeon.current + door_dir, door_dir)


# Ruch kółka po siatce: najpierw oś X, potem Y, dzięki temu postać ślizga się po ścianach.
# Używany przez gracza i wrogów (enemy_ai.gd).
func move_circle(room: Dictionary, pos: Vector2, motion: Vector2, radius: float, can_use_doors: bool) -> Vector2:
	var next := Vector2(pos.x + motion.x, pos.y)
	if not circle_blocked(room, next, radius, can_use_doors):
		pos = next
	next = Vector2(pos.x, pos.y + motion.y)
	if not circle_blocked(room, next, radius, can_use_doors):
		pos = next
	return pos


func circle_blocked(room: Dictionary, p: Vector2, r: float, can_use_doors: bool) -> bool:
	for corner in [Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
		if tile_blocked(room, tile_of(p + corner), can_use_doors):
			return true
	return false


func tile_blocked(room: Dictionary, t: Vector2i, can_use_doors: bool) -> bool:
	if can_use_doors:
		var dd: Vector2i = dungeon.door_direction(t)
		if dd != Vector2i.ZERO and room["doors"].has(dd) and room["enemies"].is_empty():
			return false
	return dungeon.is_blocked(room, t)


# ---------- walka gracza ----------

func basic_attack() -> void:
	if attack_cd > 0.0 or dash_timer > 0.0:
		return
	attack_cd = GameState.attack_cooldown()
	swing_timer = 0.12
	var room: Dictionary = dungeon.current_room()
	for e in room["enemies"].duplicate():
		var to_enemy: Vector2 = e["p"] - player_pos
		var attack_range := Balance.ATTACK_RANGE + float(Balance.class_profile(GameState.player_class).get("passive_attack_range", 0.0))
		if to_enemy.length() > attack_range + Balance.ENEMY_RADIUS:
			continue
		if to_enemy.length() > 4.0 and to_enemy.normalized().dot(facing) < Balance.ATTACK_ARC_DOT:
			continue
		var forge_bonus: int = int(Balance.class_profile(GameState.player_class).get("skill_power", 0)) if forge_timer > 0.0 else 0
		if forge_timer > 0.0 and GameState.has_talent("smith_advanced_b"):
			forge_bonus += 2
		var dmg := randi_range(Balance.ATTACK_MIN_DMG, Balance.ATTACK_MAX_DMG) + GameState.attack_bonus() + forge_bonus
		damage_enemy(room, e, dmg)


func use_skill() -> void:
	var profile := Balance.class_profile(GameState.player_class)
	var skill_name: String = str(profile.get("skill_name", Balance.SKILL_NAME))
	if skill_cd > 0.0:
		say("%s się ładuje (%.1fs)." % [skill_name, skill_cd], 1.5)
		return
	var skill_type: String = str(profile.get("skill_type", "spin"))
	var room: Dictionary = dungeon.current_room()
	if skill_type == "heal" and player_hp >= GameState.max_hp():
		var ally_needs_healing := false
		var heal_radius := modified_skill_radius(float(profile.get("skill_radius", 0.0)), skill_type)
		for ally in current_allies:
			if ally.get("alive", true) and ally["p"].distance_to(player_pos) <= heal_radius and int(ally["hp"]) < int(ally["max_hp"]):
				ally_needs_healing = true
				break
		if not ally_needs_healing:
			say("Drużyna jest w pełni sił — %s nie jest teraz potrzebne." % skill_name, 1.5)
			return
	var skill_range := float(profile.get("skill_range", 0.0))
	if skill_type == "shot" and GameState.has_talent("hunter_branch_a"):
		skill_range *= 1.3
	if skill_type == "shot":
		for distance in range(12, floori(skill_range), 12):
			if dungeon.is_blocked(room, tile_of(player_pos + facing * float(distance))):
				skill_range = maxf(0.0, float(distance - 12))
				break
	skill_cd = float(profile.get("skill_cooldown", Balance.SKILL_COOLDOWN)) * GameState.skill_cooldown_multiplier()
	skill_fx = 0.25
	skill_fx_type = skill_type
	skill_fx_target = player_pos + facing * skill_range
	skill_fx_radius = modified_skill_radius(float(profile.get("skill_radius", Balance.SKILL_RADIUS)), skill_type)
	skill_fx_color = Color(0.5, 0.8, 1.0)
	match skill_type:
		"guard":
			guard_timer = float(profile.get("skill_duration", 3.5))
			if GameState.has_talent("knight_branch_b"):
				guard_timer += 2.0
			if GameState.has_talent("knight_master_b"):
				guard_timer += 2.0
			skill_fx_color = Color(0.45, 0.8, 1.0)
			say("%s! Otrzymujesz mniej obrażeń." % skill_name)
		"heal":
			var heal_power := int(profile.get("skill_power", 5))
			if GameState.has_talent("priest_root"):
				heal_power += 2
			if GameState.has_talent("priest_master_a"):
				heal_power += 2
			if GameState.has_talent("priest_advanced_a"):
				heal_power += 3
			if GameState.has_talent("priest_capstone"):
				heal_power += 3
			var healed: int = mini(heal_power, GameState.max_hp() - player_hp)
			player_hp += healed
			var allies_healed := 0
			for ally in current_allies:
				if not ally.get("alive", true) or ally["p"].distance_to(player_pos) > skill_fx_radius:
					continue
				var ally_heal: int = mini(heal_power, int(ally["max_hp"]) - int(ally["hp"]))
				ally["hp"] = int(ally["hp"]) + ally_heal
				allies_healed += ally_heal
				if ally_heal > 0:
					add_float(ally["p"] + Vector2(0, -20), "+%d" % ally_heal, Color(0.45, 1.0, 0.62))
			skill_fx_color = Color(0.45, 1.0, 0.62)
			say("%s: ty +%d HP, sojusznicy +%d HP." % [skill_name, healed, allies_healed])
		"forge":
			forge_timer = float(profile.get("skill_duration", 6.0))
			if GameState.has_talent("smith_branch_b"):
				forge_timer += 3.0
			if GameState.has_talent("smith_master_b"):
				forge_timer += 3.0
			skill_fx_color = Color(1.0, 0.72, 0.3)
			say("%s! Atak i obrona są wzmocnione." % skill_name)
		_:
			skill_fx_color = Color(0.65, 0.72, 1.0) if skill_type == "nova" else Color(1.0, 0.68, 0.3) if skill_type == "bomb" else Color(0.5, 0.9, 0.45) if skill_type == "poison" else Color(1.0, 0.85, 0.4)
			for e in room["enemies"].duplicate():
				var to_enemy: Vector2 = e["p"] - player_pos
				var hit := false
				match skill_type:
					"shot":
						var projected_distance := to_enemy.dot(facing)
						var side_distance := absf(to_enemy.cross(facing))
						hit = projected_distance >= 0.0 and projected_distance <= skill_range and side_distance <= float(profile.get("skill_width", 34.0))
					"bomb", "poison":
						var target := player_pos + facing * float(profile.get("skill_range", 90.0))
						hit = e["p"].distance_to(target) <= skill_fx_radius + Balance.ENEMY_RADIUS
					_:
						hit = to_enemy.length() <= skill_fx_radius + Balance.ENEMY_RADIUS
				if not hit:
					continue
				var base_damage := randi_range(Balance.ATTACK_MIN_DMG, Balance.ATTACK_MAX_DMG) + GameState.attack_bonus()
				var multiplier := float(profile.get("skill_multiplier", Balance.SKILL_DMG_MULT)) * float(profile.get("passive_skill_multiplier", 1.0))
				if skill_type == "spin" and GameState.has_talent("warrior_advanced_a"):
					multiplier *= 1.25
				if skill_type == "spin" and GameState.has_talent("warrior_capstone"):
					multiplier *= 1.5
				elif skill_type == "nova":
					if GameState.has_talent("mage_master_b"):
						multiplier *= 1.2
					if GameState.has_talent("mage_advanced_b"):
						multiplier *= 1.25
					if GameState.has_talent("mage_capstone"):
						multiplier *= 1.4
				elif skill_type == "shot":
					if GameState.has_talent("hunter_master_b"):
						multiplier *= 1.2
					if GameState.has_talent("hunter_advanced_b"):
						multiplier *= 1.2
					if GameState.has_talent("hunter_capstone"):
						multiplier *= 1.5
				elif skill_type == "bomb":
					if GameState.has_talent("engineer_advanced_b"):
						multiplier *= 1.25
					if GameState.has_talent("engineer_capstone"):
						multiplier *= 1.5
				damage_enemy(room, e, maxi(1, roundi(float(base_damage) * multiplier)))
				if not room["enemies"].has(e):
					continue
				if skill_type == "poison":
					e["poison_time"] = float(profile.get("skill_duration", 4.0))
					if GameState.has_talent("alchemist_branch_b"):
						e["poison_time"] += 2.0
					if GameState.has_talent("alchemist_master_b"):
						e["poison_time"] += 2.0
					e["poison_interval"] = float(profile.get("skill_dot_interval", 0.6))
					e["poison_tick"] = e["poison_interval"]
					var poison_damage := int(profile.get("skill_dot_damage", 1)) + int(GameState.has_talent("alchemist_advanced_b"))
					e["poison_damage"] = poison_damage * (2 if GameState.has_talent("alchemist_capstone") else 1)
				elif skill_type == "nova":
					e["burn_time"] = float(profile.get("skill_dot_duration", 3.0))
					e["burn_time"] += int(GameState.has_talent("mage_root"))
					if GameState.has_talent("mage_branch_b"):
						e["burn_time"] += 2.0
					if GameState.has_talent("mage_master_a"):
						e["burn_time"] += 2.0
					e["burn_interval"] = float(profile.get("skill_dot_interval", 0.75))
					e["burn_tick"] = e["burn_interval"]
					e["burn_damage"] = int(profile.get("skill_dot_damage", 1)) + int(GameState.has_talent("mage_advanced_a"))
				elif skill_type == "shot":
					e["marked_time"] = float(profile.get("skill_mark_duration", 4.0))
					if GameState.has_talent("hunter_branch_b"):
						e["marked_time"] += 3.0
					if GameState.has_talent("hunter_master_a"):
						e["marked_time"] += 3.0
					e["mark_bonus"] = int(profile.get("skill_mark_bonus", 1))
					e["mark_bonus"] += int(GameState.has_talent("hunter_root"))
					e["mark_bonus"] += int(GameState.has_talent("hunter_advanced_a"))
				elif skill_type == "bomb":
					e["slow_time"] = float(profile.get("skill_slow_duration", 2.5))
					e["slow_time"] += int(GameState.has_talent("engineer_root"))
			if skill_type == "poison":
				say("%s! Kwas będzie dalej ranił trafionych wrogów." % skill_name)
			elif skill_type == "shot":
				say("%s!" % skill_name)
			elif skill_type == "bomb":
				say("%s!" % skill_name)
			else:
				say("%s!" % skill_name)


func modified_skill_radius(base_radius: float, skill_type: String) -> float:
	var radius := base_radius
	if skill_type == "spin":
		if GameState.has_talent("warrior_branch_b"):
			radius *= 1.3
		if GameState.has_talent("warrior_master_b"):
			radius *= 1.2
		if GameState.has_talent("warrior_advanced_b"):
			radius *= 1.2
	elif skill_type == "nova" and GameState.has_talent("mage_branch_a"):
		radius *= 1.25
	elif skill_type == "heal" and GameState.has_talent("priest_branch_a"):
		radius *= 1.5
	elif skill_type == "bomb":
		if GameState.has_talent("engineer_branch_a"):
			radius *= 1.25
		if GameState.has_talent("engineer_master_b"):
			radius *= 1.2
	return radius


func update_enemy_effects(room: Dictionary, delta: float) -> void:
	for enemy in room["enemies"].duplicate():
		update_damage_over_time(room, enemy, delta, "poison")
		if room["enemies"].has(enemy):
			update_damage_over_time(room, enemy, delta, "burn")
		if room["enemies"].has(enemy) and enemy.has("marked_time"):
			enemy["marked_time"] = maxf(0.0, float(enemy["marked_time"]) - delta)
			if enemy["marked_time"] <= 0.0:
				enemy.erase("marked_time")
				enemy.erase("mark_bonus")


func update_damage_over_time(room: Dictionary, enemy: Dictionary, delta: float, effect: String) -> void:
	var time_key := effect + "_time"
	var tick_key := effect + "_tick"
	var damage_key := effect + "_damage"
	var interval_key := effect + "_interval"
	if not enemy.has(time_key):
		return
	enemy[time_key] = maxf(0.0, float(enemy[time_key]) - delta)
	enemy[tick_key] = float(enemy.get(tick_key, 1.0)) - delta
	while float(enemy[tick_key]) <= 0.0 and float(enemy[time_key]) > 0.0:
		enemy[tick_key] = float(enemy[tick_key]) + float(enemy.get(interval_key, 1.0))
		damage_enemy(room, enemy, int(enemy.get(damage_key, 1)))
		if not room["enemies"].has(enemy):
			return
	if float(enemy[time_key]) <= 0.0:
		enemy.erase(time_key)
		enemy.erase(tick_key)
		enemy.erase(damage_key)
		enemy.erase(interval_key)


func start_dash() -> void:
	if dash_cd > 0.0:
		return
	var dir := input_direction()
	dash_dir = dir if dir != Vector2.ZERO else facing
	dash_timer = Balance.DASH_TIME
	dash_cd = GameState.dash_cooldown()
	invuln = maxf(invuln, Balance.DASH_TIME + 0.05)


func damage_enemy(room: Dictionary, e: Dictionary, dmg: int) -> void:
	if float(e.get("marked_time", 0.0)) > 0.0:
		dmg += int(e.get("mark_bonus", 1))
	e["hp"] -= dmg
	e["flash"] = 0.12
	add_float(e["p"], str(dmg), Color(1, 0.9, 0.4))
	var push: Vector2 = (e["p"] - player_pos).normalized() * Balance.KNOCKBACK
	e["p"] = move_circle(room, e["p"], push, Balance.ENEMY_RADIUS, false)
	if e["hp"] <= 0:
		kill_enemy(room, e)


func kill_enemy(room: Dictionary, e: Dictionary) -> void:
	var dead_tile := tile_of(e["p"])
	room["enemies"].erase(e)
	var profile := Balance.class_profile(GameState.player_class)
	var cooldown_refund := float(profile.get("passive_kill_cooldown", 0.0))
	if GameState.player_class == "Wojownik" and GameState.has_talent("warrior_branch_a"):
		cooldown_refund += 1.5
	if GameState.player_class == "Wojownik" and GameState.has_talent("warrior_master_a"):
		cooldown_refund += 2.0
	skill_cd = maxf(0.0, skill_cd - cooldown_refund)
	var gold := randi_range(Balance.GOLD_MIN, Balance.GOLD_MAX) + floor_num * Balance.GOLD_PER_FLOOR
	run_gold += gold
	add_float(e["p"] + Vector2(0, -16), "+%d zł" % gold, Color(0.95, 0.8, 0.35))
	var previous_level := GameState.level
	var levels: int = GameState.add_xp(Balance.XP_BASE + floor_num * Balance.XP_PER_FLOOR)
	if levels > 0:
		var milestones_gained := floori(float(GameState.level) / 5.0) - floori(float(previous_level) / 5.0)
		var talents_gained := floori(float(GameState.level) / ClassProgression.TALENT_LEVEL_INTERVAL) - floori(float(previous_level) / ClassProgression.TALENT_LEVEL_INTERVAL)
		player_hp = mini(GameState.max_hp(), player_hp + levels * Balance.HP_PER_LEVEL + milestones_gained)
		say("[SYSTEM] Poziom %d! +%d cech%s, +%d talent%s. Rozwój w mieście lub gildii (Tab → T)." % [
			GameState.level, levels * Balance.POINTS_PER_LEVEL + milestones_gained,
			"" if levels * Balance.POINTS_PER_LEVEL + milestones_gained == 1 else "y",
			talents_gained, "" if talents_gained == 1 else "ów"
		], 5.0)
		add_float(player_pos + Vector2(0, -28), "POZIOM!", Color(0.4, 0.75, 1.0))
	if randf() < Balance.DROP_POTION_CHANCE:
		room["items"].append({"pos": dead_tile, "item": Items.potion()})
	if randf() < Balance.DROP_ITEM_CHANCE:
		room["items"].append({"pos": dead_tile, "item": Items.random_item(floor_num)})
	if profile.has("crafting_name") and randf() < 0.65:
		var material_pool: Array[String]
		match GameState.player_class:
			"Alchemik":
				material_pool = ["herb", "herb", "monster_core"]
			"Kowal", "Inżynier":
				material_pool = ["iron_ore", "iron_ore", "monster_core"]
			_:
				material_pool = ["monster_core"]
		var material := Items.material(material_pool[randi_range(0, material_pool.size() - 1)])
		if not material.is_empty():
			room["items"].append({"pos": dead_tile, "item": material})
	
	# aktualizuj postęp zlecenia "hunt"
	var active := GameState.active_quest
	if not active.is_empty() and active["type"] == "hunt":
		GameState.update_quest_progress(1)
		if active["completed"]:
			say("[ZLECENIE] Ukończone! Odbierz nagrodę w gildii.", 4.0)
	
	# aktualizuj postęp zlecenia "gather"
	if not active.is_empty() and active["type"] == "gather":
		GameState.update_quest_progress(gold)
		if active["completed"]:
			say("[ZLECENIE] Ukończone! Odbierz nagrodę w gildii.", 4.0)
	
	if room["enemies"].is_empty():
		if dungeon.current == dungeon.stairs_cell:
			say("Pokój oczyszczony - drzwi otwarte! Stań na schodach (>) i naciśnij F, by zejść niżej.", 5.0)
		else:
			say("Pokój oczyszczony - drzwi otwarte!")


# Wywoływane przez wrogów (enemy_ai.gd) przy trafieniu gracza.
func hurt_player(dmg: int) -> void:
	var profile := Balance.class_profile(GameState.player_class)
	if guard_timer > 0.0:
		var guard_power := int(profile.get("skill_power", 0))
		if GameState.has_talent("knight_branch_a"):
			guard_power += 1
		if GameState.has_talent("knight_master_a"):
			guard_power += 1
		dmg = maxi(1, dmg - guard_power)
	player_hp -= dmg
	invuln = Balance.HIT_INVULN
	hurt_flash = 0.2
	add_float(player_pos + Vector2(0, -20), "-%d" % dmg, Color(1, 0.3, 0.3))
	if player_hp <= 0:
		player_hp = 0
		game_over = true
		player_moving = false
		inv_ctrl.close()
		death_timer = 2.5
		say("Padasz na piętrze %d..." % floor_num, 3.0)


func hurt_ally(ally: Dictionary, dmg: int) -> void:
	var profile := Balance.class_profile(GameState.player_class)
	if guard_timer > 0.0 and GameState.has_talent("knight_capstone") and ally["p"].distance_to(player_pos) <= float(profile.get("skill_radius", 0.0)):
		var guard_power := int(profile.get("skill_power", 0))
		if GameState.has_talent("knight_branch_a"):
			guard_power += 1
		if GameState.has_talent("knight_master_a"):
			guard_power += 1
		if GameState.has_talent("knight_capstone"):
			guard_power += 1
		dmg = maxi(1, dmg - guard_power)
	ally["hp"] -= dmg
	ally["flash"] = 0.12
	add_float(ally["p"] + Vector2(0, -20), "-%d" % dmg, Color(1, 0.3, 0.3))
	if ally["hp"] <= 0:
		ally["hp"] = 0
		ally["alive"] = false
		add_float(ally["p"] + Vector2(0, -32), "POLEGŁ!", Color(0.8, 0.5, 0.5))
		GameState.kill_member(ally["id"])


# ---------- przedmioty na podłodze ----------

# Mikstury wchodzą do plecaka same, jeśli starczy udźwigu.
func auto_pickup(room: Dictionary) -> void:
	var t := tile_of(player_pos)
	var list: Array = room["items"]
	var i := list.size() - 1
	while i >= 0:
		var entry: Dictionary = list[i]
		if entry["pos"] == t and entry["item"]["slot"] == "potion" and not entry.get("dropped", false):
			if inv.add(entry["item"]):
				say("Zbierasz: %s." % Items.describe(entry["item"]))
				list.remove_at(i)
			else:
				entry["dropped"] = true
				say("Za ciężko! Mikstura zostaje na podłodze (udźwig %d/%d)." % [inv.total_weight(), inv.max_weight])
		i -= 1


func take_item() -> void:
	var room: Dictionary = dungeon.current_room()
	var idx: int = dungeon.item_index(room, tile_of(player_pos))
	if idx == -1:
		say("Nie ma tu nic do podniesienia.")
		return
	var found: Dictionary = room["items"][idx]["item"]
	if not inv.add(found):
		say("Za ciężkie! Udźwig %d/%d - wyrzuć coś w plecaku (I)." % [inv.total_weight(), inv.max_weight])
		return
	room["items"].remove_at(idx)
	say("Podnosisz: %s." % Items.describe(found))


# ---------- plecak (pauzuje grę) ----------

func use_pack_item(idx: int) -> void:
	var item: Dictionary = inv.pack[idx]
	match str(item.get("slot", "")):
		"potion":
			if player_hp >= GameState.max_hp():
				say("Masz pełne HP - mikstura nie jest teraz potrzebna.")
				return
			inv.pack.remove_at(idx)
			var healed: int = mini(GameState.potion_heal_amount(int(item["heal"])), GameState.max_hp() - player_hp)
			player_hp += healed
			say("Pijesz miksturę (+%d HP)." % healed)
		"weapon", "armor":
			inv.equip_from_pack(idx)
			say("Zakładasz: %s." % Items.describe(item))
		"tool":
			use_crafted_tool(idx, item)
		"material":
			say("Materiały wykorzystasz w warsztacie rzemieślniczym.")
	# Cursor sync is handled by InventoryController


func use_crafted_tool(index: int, item: Dictionary) -> void:
	var room: Dictionary = dungeon.current_room()
	var center := player_pos + facing * 90.0
	var radius := float(item.get("radius", 100.0))
	if str(item.get("tool_type", "")) == "bomb":
		if GameState.has_talent("engineer_branch_a"):
			radius *= 1.25
		if GameState.has_talent("engineer_master_b"):
			radius *= 1.2
	var targets: Array[Dictionary] = []
	for enemy in room["enemies"]:
		if enemy["p"].distance_to(center) <= radius + Balance.ENEMY_RADIUS:
			targets.append(enemy)
	if targets.is_empty():
		say("Nie ma wrogów w zasięgu narzędzia.")
		return
	var tool_type := str(item.get("tool_type", "bomb"))
	var tool_damage := int(item.get("damage", 1))
	if tool_type == "bomb" and GameState.has_talent("engineer_advanced_b"):
		tool_damage = roundi(float(tool_damage) * 1.25)
	if tool_type == "bomb" and GameState.has_talent("engineer_capstone"):
		tool_damage = roundi(float(tool_damage) * 1.5)
	inv.pack.remove_at(index)
	skill_fx_type = "poison" if tool_type == "acid" else "bomb"
	skill_fx = 0.35
	skill_fx_target = center
	skill_fx_radius = radius
	skill_fx_color = Color(0.5, 0.9, 0.45) if tool_type == "acid" else Color(1.0, 0.55, 0.25)
	for enemy in targets:
		if not room["enemies"].has(enemy):
			continue
		damage_enemy(room, enemy, tool_damage)
		if tool_type == "acid" and room["enemies"].has(enemy):
			enemy["poison_time"] = float(item.get("duration", 4.0))
			enemy["poison_time"] += 2.0 * int(GameState.has_talent("alchemist_branch_b"))
			enemy["poison_time"] += 2.0 * int(GameState.has_talent("alchemist_master_b"))
			enemy["poison_interval"] = float(item.get("tick_interval", 0.6))
			enemy["poison_tick"] = enemy["poison_interval"]
			var poison_damage := 1 + int(GameState.has_talent("alchemist_advanced_b"))
			enemy["poison_damage"] = poison_damage * (2 if GameState.has_talent("alchemist_capstone") else 1)
	say("%s: trafiono wrogów (%d)." % [str(item.get("name", "Narzędzie")), targets.size()])


func drop_pack_item(room: Dictionary, idx: int) -> void:
	var item: Dictionary = inv.pack[idx]
	inv.pack.remove_at(idx)
	room["items"].append({"pos": tile_of(player_pos), "item": item, "dropped": true})
	say("Wyrzucasz: %s." % Items.describe(item))
	# Cursor sync is handled by InventoryController


# ---------- pokoje, piętra, powrót ----------

func on_portal() -> bool:
	return dungeon.current == dungeon.start_cell and tile_of(player_pos) == Vector2i(Dungeon.CX, Dungeon.CY)


# Schody działają dopiero po oczyszczeniu pokoju i tylko na środkowej kratce.
func on_stairs() -> bool:
	if dungeon.current != dungeon.stairs_cell or tile_of(player_pos) != Vector2i(Dungeon.CX, Dungeon.CY):
		return false
	return dungeon.current_room()["enemies"].is_empty()


# F: schody w dół albo portal do miasta, zależnie od tego, gdzie stoisz.
func interact() -> void:
	if on_stairs():
		next_floor()
		return
	if on_portal():
		if GameState.return_from_dungeon(run_gold, floor_num, player_hp):
			get_tree().change_scene_to_file("res://locations/city/scenes/city.tscn")
		else:
			say(GameState.message, 4.0)
		return
	say("F działa na środku pierwszego pokoju (portal do miasta) i na schodach po oczyszczeniu pokoju.", 4.0)


func enter_room(cell: Vector2i, dir: Vector2i) -> void:
	dungeon.current = cell
	var room: Dictionary = dungeon.current_room()
	room["visited"] = true
	enemy_ai.prepare_room(room)
	player_pos = tile_center(dungeon.entry_position(dir))
	for ally in current_allies:
		if ally.get("alive", true):
			ally_ai.prepare_ally(ally)
	if room["enemies"].is_empty():
		say("Pusty pokój.")
	else:
		say("Drzwi się zatrzaskują! Pokonaj wrogów.")
	floats.clear()


func next_floor() -> void:
	var next_floor_number := floor_num + 1
	if not GameState.update_run_floor(next_floor_number):
		say(GameState.message if GameState.message.begins_with("Błąd zapisu:") else "Nie można zapisać postępu wyprawy.")
		return
	floor_num = next_floor_number
	player_hp = mini(player_hp + Balance.NEXT_FLOOR_HEAL, GameState.max_hp())
	start_floor()
	floats.clear()
	say("Piętro %d. Leczysz się o %d. Portal (F) na środku tego pokoju." % [floor_num, Balance.NEXT_FLOOR_HEAL], 4.0)


# ---------- efekty ----------

func add_float(pos: Vector2, text: String, color: Color) -> void:
	floats.append({"pos": pos, "text": text, "color": color, "t": 0.8})


func update_floats(delta: float) -> void:
	var i := floats.size() - 1
	while i >= 0:
		floats[i]["t"] -= delta
		floats[i]["pos"] += Vector2(0, -30 * delta)
		if floats[i]["t"] <= 0.0:
			floats.remove_at(i)
		i -= 1


# ---------- rysowanie (szczegóły w room_view.gd i hud.gd) ----------

func _draw() -> void:
	if dungeon.layout.is_empty():
		return
	var font := ThemeDB.fallback_font
	RoomView.draw_room(self, self, font)
	Hud.draw_hud(self, self, font)
	Hud.draw_minimap(self, self, font)
	if inv_ctrl.is_open():
		inv_ctrl.draw(self, font, get_viewport_rect().size, player_hp)
	if system_ctrl.is_open():
		system_ctrl.draw(self, font, get_viewport_rect().size)
