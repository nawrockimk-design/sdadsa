extends RefCounted
# Wrogowie w lochu: przygotowanie do walki, pościg, zamach i cios.
# Korzysta ze stanu gracza i ruchu z węzła main.gd (m). W Fazie 2 ten sam wzorzec posłuży sojusznikom.

const Balance = preload("res://shared/scripts/balance.gd")

var m   # węzeł main.gd


func _init(main_node) -> void:
	m = main_node


# Wrogowie z generatora mają tylko pozycję na kratce - tu dostają stan do walki na żywo.
func prepare_room(room: Dictionary) -> void:
	var floor_num: int = m.floor_num
	for e in room["enemies"]:
		if e.has("p"):
			continue
		e["p"] = m.tile_center(e["pos"])
		e["hp"] = Balance.ENEMY_BASE_HP + floor_num * Balance.ENEMY_HP_PER_FLOOR
		e["max_hp"] = e["hp"]
		e["state"] = "chase"
		e["t"] = randf_range(0.3, 0.8)  # krótka chwila na reakcję po wejściu
		e["flash"] = 0.0
		e["sprite"] = randi_range(0, 3)
		e["facing"] = Vector2.DOWN


func update(room: Dictionary, delta: float) -> void:
	var floor_num: int = m.floor_num
	var player_pos: Vector2 = m.player_pos
	var speed: float = Balance.ENEMY_BASE_SPEED + floor_num * Balance.ENEMY_SPEED_PER_FLOOR
	for e in room["enemies"]:
		e["flash"] = maxf(0.0, e["flash"] - delta)
		e["t"] -= delta
		if e.has("slow_time"):
			e["slow_time"] = maxf(0.0, float(e["slow_time"]) - delta)
			if e["slow_time"] <= 0.0:
				e.erase("slow_time")
		var to_player: Vector2 = player_pos - e["p"]
		if to_player.length_squared() > 0.0:
			e["facing"] = to_player.normalized()
		match e["state"]:
			"chase":
				if e["t"] > 0.0:
					continue
				if to_player.length() <= Balance.ENEMY_ATTACK_RANGE + Balance.PLAYER_RADIUS:
					e["state"] = "windup"
					e["t"] = Balance.ENEMY_WINDUP
				else:
					var enemy_speed := speed * (0.45 if e.has("slow_time") else 1.0)
					var motion: Vector2 = to_player.normalized() * enemy_speed * delta + separation(room, e) * delta
					e["p"] = m.move_circle(room, e["p"], motion, Balance.ENEMY_RADIUS, false)
			"windup":
				if e["t"] <= 0.0:
					strike(e)
					e["state"] = "recover"
					e["t"] = Balance.ENEMY_RECOVER
			"recover":
				if e["t"] <= 0.0:
					e["state"] = "chase"
		if m.game_over:
			return


# Lekkie odpychanie wrogów od siebie, żeby nie stali w jednym miejscu.
func separation(room: Dictionary, e: Dictionary) -> Vector2:
	var push := Vector2.ZERO
	for other in room["enemies"]:
		if other == e:
			continue
		var d: Vector2 = e["p"] - other["p"]
		var dist := d.length()
		if dist > 0.01 and dist < Balance.ENEMY_RADIUS * 2.5:
			push += d / dist * Balance.ENEMY_SEPARATION
	return push


func strike(e: Dictionary) -> void:
	var player_pos: Vector2 = m.player_pos
	var allies: Array = m.current_allies
	
	# znajdź najbliższą cel (gracz lub sojusznik)
	var target_pos := player_pos
	var target_defense: int = GameState.defense_bonus()
	if m.forge_timer > 0.0:
		target_defense += int(Balance.class_profile(GameState.player_class).get("skill_defense_bonus", 0))
	var target_is_player := true
	var target_ally: Dictionary = {}
	
	var nearest_dist: float = e["p"].distance_to(player_pos)
	for ally in allies:
		if not ally.get("alive", true):
			continue
		var d: float = e["p"].distance_to(ally["p"])
		if d < nearest_dist:
			nearest_dist = d
			target_pos = ally["p"]
			target_defense = ally["defense"]
			target_is_player = false
			target_ally = ally
	
	if e["p"].distance_to(target_pos) > Balance.ENEMY_HIT_RANGE + Balance.PLAYER_RADIUS:
		return
	
	if target_is_player:
		var invuln: float = m.invuln
		if invuln > 0.0:
			m.add_float(player_pos + Vector2(0, -20), "unik!", Color(0.6, 0.9, 1.0))
			return
	
	var floor_num: int = m.floor_num
	var max_dmg: int = Balance.ENEMY_BASE_DMG + floori(floor_num / 3.0)
	var dmg: int = maxi(1, randi_range(1, max_dmg) - target_defense)
	
	if target_is_player:
		m.hurt_player(dmg)
	else:
		m.hurt_ally(target_ally, dmg)
