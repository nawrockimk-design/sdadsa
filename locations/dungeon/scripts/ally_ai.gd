extends RefCounted
# Sojusznicy w lochu: przygotowanie, pościg wrogów, zamach i cios.
# Wzór na enemy_ai.gd, ale cel to wrogowie, nie gracz.

const Balance = preload("res://shared/scripts/balance.gd")
const Members = preload("res://locations/guild/scripts/members.gd")

const SPAWN_OFFSETS := [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
	Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var m   # węzeł main.gd


func _init(main_node) -> void:
	m = main_node


# Sojusznicy z GameState dostają stan do walki na żywo.
func prepare_ally(ally: Dictionary) -> void:
	var room: Dictionary = m.dungeon.current_room()
	var player_tile: Vector2i = m.tile_of(m.player_pos)
	for offset in SPAWN_OFFSETS:
		var candidate: Vector2i = player_tile + offset
		if m.dungeon.is_blocked(room, candidate):
			continue
		var occupied := false
		for other in m.current_allies:
			if other == ally or not other.get("alive", true) or not other.has("p"):
				continue
			if m.tile_of(other["p"]) == candidate:
				occupied = true
				break
		if not occupied:
			ally["p"] = m.tile_center(candidate)
			break
	ally["state"] = "chase"
	ally["t"] = randf_range(0.3, 0.8)
	ally["flash"] = 0.0
	ally["facing"] = Vector2.DOWN
	# Auto-pickup potions on floor
	_pickup_potions(room, ally)


func update(room: Dictionary, delta: float) -> void:
	var player_pos: Vector2 = m.player_pos
	var allies: Array = m.current_allies
	
	for ally in allies:
		if not ally.get("alive", true):
			continue
		ally["flash"] = maxf(0.0, ally["flash"] - delta)
		ally["t"] -= delta
		
		# Auto-use potion if HP low
		_try_use_potion(ally)
		
		# znajdź najbliższego wroga
		var target_enemy := find_nearest_enemy(room, ally["p"])
		if not target_enemy.is_empty():
			var target_direction: Vector2 = target_enemy["p"] - ally["p"]
			if target_direction.length_squared() > 0.0:
				ally["facing"] = target_direction.normalized()

		# Cowardly trait: flee if HP low
		var hp_ratio := float(ally.get("hp", 1)) / float(ally.get("max_hp", 1))
		var is_cowardly := Members.has_trait(ally, "cowardly")
		var is_brave := Members.has_trait(ally, "brave")
		var should_flee := is_cowardly and hp_ratio < 0.4 and not is_brave

		match ally["state"]:
			"chase":
				if ally["t"] > 0.0:
					continue
				if should_flee:
					# uciekaj od najbliższego wroga
					if not target_enemy.is_empty():
						var away_dir := (ally["p"] - target_enemy["p"]).normalized()
						var motion := away_dir * (Balance.ENEMY_BASE_SPEED * 1.2) * delta
						ally["p"] = m.move_circle(room, ally["p"], motion, Balance.ENEMY_RADIUS, false)
					continue
				if not target_enemy.is_empty():
					var to_enemy: Vector2 = target_enemy["p"] - ally["p"]
					if to_enemy.length() <= Balance.ENEMY_ATTACK_RANGE + Balance.ENEMY_RADIUS:
						ally["state"] = "windup"
						ally["t"] = Balance.ENEMY_WINDUP
					else:
						var motion: Vector2 = to_enemy.normalized() * (Balance.ENEMY_BASE_SPEED * 0.8) * delta + separation_allies(allies, ally) * delta
						ally["p"] = m.move_circle(room, ally["p"], motion, Balance.ENEMY_RADIUS, false)
				else:
					# brak wrogów - podążaj za graczem
					var to_player: Vector2 = player_pos - ally["p"]
					if to_player.length() > 60.0:
						var motion: Vector2 = to_player.normalized() * (Balance.ENEMY_BASE_SPEED * 0.5) * delta
						ally["p"] = m.move_circle(room, ally["p"], motion, Balance.ENEMY_RADIUS, false)
			"windup":
				if ally["t"] <= 0.0:
					strike(ally, target_enemy)
					ally["state"] = "recover"
					ally["t"] = Balance.ENEMY_RECOVER
			"recover":
				if ally["t"] <= 0.0:
					ally["state"] = "chase"


func find_nearest_enemy(room: Dictionary, pos: Vector2) -> Dictionary:
	var nearest: Dictionary = {}
	var nearest_dist := 9999.0
	for e in room["enemies"]:
		var d := pos.distance_to(e["p"])
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest


func separation_allies(allies: Array, ally: Dictionary) -> Vector2:
	var push := Vector2.ZERO
	for other in allies:
		if other == ally or not other.get("alive", true):
			continue
		var d: Vector2 = ally["p"] - other["p"]
		var dist := d.length()
		if dist > 0.01 and dist < Balance.ENEMY_RADIUS * 2.5:
			push += d / dist * Balance.ENEMY_SEPARATION
	return push


func strike(ally: Dictionary, enemy: Dictionary) -> void:
	if enemy.is_empty():
		return
	if ally["p"].distance_to(enemy["p"]) > Balance.ENEMY_HIT_RANGE + Balance.ENEMY_RADIUS:
		return
	
	var dmg: int = ally["attack"] + randi_range(1, 2)
	m.damage_enemy(m.dungeon.current_room(), enemy, dmg)
