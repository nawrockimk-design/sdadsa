extends Node
# Autoload "GameState": wszystko, co przetrwa między gildią a lochem. Zapis w user://save.json.

const Balance = preload("res://shared/scripts/balance.gd")
const Inventory = preload("res://shared/scripts/inventory.gd")
const Quests = preload("res://locations/guild/scripts/quests.gd")
const Members = preload("res://locations/guild/scripts/members.gd")
const ClassProgression = preload("res://shared/scripts/class_progression.gd")

var quest_system = Quests.new()
var member_system = Members.new()

const RANKS := ["F", "E", "D", "C", "B", "A", "S"]

const SAVE_PATH := "user://save.json"
const SAVE_TMP := "user://save.json.tmp"
const SAVE_BACKUP := "user://save.json.bak"
const SAVE_CORRUPT := "user://save.json.corrupt"

var loaded_from_backup := false

var gold := 0
var day := 1
var player_class := ""
var intro_complete := false
var level := 1
var xp := 0
var stat_points := 0
var talent_points := 0
var talents: Dictionary = {}
var stats := {"str": 0, "vit": 0, "agi": 0}
var hp := Balance.BASE_HP
var rooms: Array = ["hall"]
var best_floor := 0
var inv = Inventory.new()
var members: Array = []             # lista członków gildii
var relations: Dictionary = {}       # relacje z NPC i samą gildią
var guild_rank := "F"              # ranga gildii
var guild_xp := 0
var quests: Array = []             # dostępne zlecenia
var active_quest: Dictionary = {}  # aktualnie aktywne zlecenie
var message := ""                   # komunikat do pokazania w gildii
var storage_error := ""
var in_run := false                 # true od wejścia do lochu do powrotu portalem lub śmierci
var run_floor := 0


func _ready() -> void:
	if not load_game():
		var save_exists := FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_BACKUP)
		var load_error := message
		var storage_load_error := storage_error
		reset()
		if save_exists:
			message = load_error
			storage_error = storage_load_error
	else:
		if quests.is_empty():
			generate_quests()


func reset_relations() -> void:
	relations = {}
	for npc in Balance.RELATION_DEFAULTS.keys():
		relations[npc] = int(Balance.RELATION_DEFAULTS[npc])


func reset() -> void:
	gold = 0
	day = 1
	player_class = ""
	intro_complete = false
	level = 1
	xp = 0
	stat_points = 0
	talent_points = 0
	talents = {}
	stats = {"str": 0, "vit": 0, "agi": 0}
	rooms = ["hall"]
	best_floor = 0
	in_run = false
	run_floor = 0
	inv.reset()
	refresh_inventory()
	members = []
	reset_relations()
	guild_rank = "F"
	guild_xp = 0
	quests = []
	active_quest = {}
	storage_error = ""
	hp = max_hp()
	generate_quests()
	message = "Dziś kończysz 18 lat. Coś w Twojej głowie mówi: [SYSTEM AKTYWNY]."


# ---------- statystyki ----------

func max_hp() -> int:
	var profile := Balance.class_profile(player_class)
	var talent_hp := 3 * int(has_talent("knight_root"))
	talent_hp += 3 * int(has_talent("priest_branch_b"))
	talent_hp += 3 * int(has_talent("priest_master_b"))
	var level_milestones := floori(float(maxi(level - 1, 0)) / 5.0)
	return Balance.BASE_HP + stats["vit"] * Balance.HP_PER_VIT + (level - 1) * Balance.HP_PER_LEVEL + level_milestones + int(profile.get("passive_max_hp", 0)) + talent_hp


func attack_bonus() -> int:
	var profile := Balance.class_profile(player_class)
	var equipment_bonus: int = int(profile.get("passive_equipment_bonus", 0)) if not inv.weapon.is_empty() else 0
	var talent_attack := int(has_talent("warrior_root"))
	var smith_bonus := crafted_item_bonus()
	if player_class == "Kowal" and not inv.weapon.is_empty():
		equipment_bonus += smith_bonus
	return stats["str"] + inv.attack_bonus() + int(profile.get("passive_attack", 0)) + equipment_bonus + talent_attack


func move_speed() -> float:
	return Balance.BASE_SPEED + stats["agi"] * Balance.SPEED_PER_AGI


func attack_cooldown() -> float:
	return maxf(0.2, Balance.ATTACK_COOLDOWN - float(stats["agi"]) * 0.005)


func defense_bonus() -> int:
	var profile := Balance.class_profile(player_class)
	var equipment_bonus: int = int(profile.get("passive_equipment_bonus", 0)) if not inv.armor.is_empty() else 0
	if player_class == "Kowal" and not inv.armor.is_empty():
		equipment_bonus += int(has_talent("smith_root")) + int(has_talent("smith_capstone"))
	var talent_defense := int(has_talent("knight_root")) + int(has_talent("knight_advanced_a"))
	return inv.defense() + int(profile.get("passive_defense", 0)) + equipment_bonus + talent_defense


func potion_heal_amount(base_heal: int) -> int:
	var profile := Balance.class_profile(player_class)
	return base_heal + int(profile.get("passive_potion_heal", 0)) + 2 * int(has_talent("alchemist_root"))


func dash_cooldown() -> float:
	return maxf(Balance.DASH_MIN_COOLDOWN, Balance.DASH_COOLDOWN - stats["agi"] * Balance.DASH_CD_PER_AGI)


func xp_to_next() -> int:
	if level >= ClassProgression.MAX_LEVEL:
		return 0
	return ClassProgression.xp_required(level)


# Zwraca liczbę zdobytych poziomów. HP w lochu śledzi main.gd (player_hp),
# więc tu tylko poziom i punkty; HP wraca do GameState przy powrocie lub śmierci.
func add_xp(amount: int) -> int:
	if amount <= 0 or level >= ClassProgression.MAX_LEVEL:
		return 0
	xp += amount
	var gained := 0
	while level < ClassProgression.MAX_LEVEL and xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		stat_points += Balance.POINTS_PER_LEVEL
		if level % 5 == 0:
			stat_points += 1
		if level % ClassProgression.TALENT_LEVEL_INTERVAL == 0:
			talent_points += 1
		gained += 1
	if level >= ClassProgression.MAX_LEVEL:
		xp = 0
	return gained


func spend_point(stat: String) -> bool:
	if stat_points <= 0 or not stats.has(stat) or int(stats[stat]) >= 25:
		return false
	stat_points -= 1
	stats[stat] += 1
	if stat == "vit":
		hp += Balance.HP_PER_VIT
	return true


func has_talent(talent_id: String) -> bool:
	return bool(talents.get(talent_id, false))


func can_unlock_talent(talent_id: String) -> bool:
	for node in ClassProgression.nodes_for_class(player_class):
		if str(node["id"]) != talent_id:
			continue
		if has_talent(talent_id) or talent_points <= 0:
			return false
		for prerequisite in node["requires"]:
			if not has_talent(str(prerequisite)):
				return false
		return true
	return false


func unlock_talent(talent_id: String) -> bool:
	if not can_unlock_talent(talent_id):
		return false
	talents[talent_id] = true
	talent_points -= 1
	save_game()
	return true


func crafting_gold_cost(base_cost: int) -> int:
	var discount := 0.25 * int(has_talent("smith_branch_a")) + 0.25 * int(has_talent("smith_master_a"))
	return maxi(1, ceili(float(base_cost) * (1.0 - discount)))


func crafted_item_bonus() -> int:
	return int(has_talent("smith_root")) + int(has_talent("smith_advanced_a")) + int(has_talent("smith_capstone"))


func crafted_potion_bonus() -> int:
	return 3 * int(has_talent("alchemist_branch_a")) + 2 * int(has_talent("alchemist_master_a")) + 3 * int(has_talent("alchemist_advanced_a"))


func skill_cooldown_multiplier() -> float:
	var multiplier := float(Balance.class_profile(player_class).get("passive_skill_cooldown_multiplier", 1.0))
	if player_class == "Inżynier" and has_talent("engineer_branch_b"):
		multiplier *= 0.9
	if player_class == "Inżynier" and has_talent("engineer_master_a"):
		multiplier *= 0.9
	if player_class == "Inżynier" and has_talent("engineer_advanced_a"):
		multiplier *= 0.85
	if player_class == "Rycerz" and has_talent("knight_advanced_b"):
		multiplier *= 0.85
	if player_class == "Kapłan" and has_talent("priest_advanced_b"):
		multiplier *= 0.8
	return multiplier


# ---------- gildia ----------

func has_room(id: String) -> bool:
	return rooms.has(id)


func buy_room(room: Dictionary) -> bool:
	if has_room(room["id"]) or gold < room["cost"]:
		return false
	gold -= room["cost"]
	rooms.append(room["id"])
	refresh_inventory()
	save_game()
	return true


func refresh_inventory() -> void:
	inv.max_weight = Balance.BASE_WEIGHT
	if has_room("storage"):
		inv.max_weight += Balance.STORAGE_WEIGHT_BONUS


# ---------- członkowie gildii ----------

func recruit_member(member: Dictionary) -> bool:
	if gold < member["cost"]:
		return false
	gold -= member["cost"]
	members.append(member)
	save_game()
	return true


func remove_member(member_id: String) -> void:
	for i: int in members.size():
		if members[i]["id"] == member_id:
			members.remove_at(i)
			break
	save_game()


func kill_member(member_id: String) -> void:
	for m in members:
		if m["id"] == member_id:
			m["alive"] = false
			m["in_party"] = false
			break
	save_game()


func get_party_members() -> Array:
	var party := []
	for m in members:
		if m.get("alive", true) and m.get("in_party", false):
			party.append(m)
	return party


func clear_party() -> void:
	for m: Dictionary in members:
		m["in_party"] = false


func max_party_size() -> int:
	return Balance.MAX_PARTY_SIZE if has_room("barracks") else 0


func guild_xp_to_next() -> int:
	var idx: int = Balance.RANKS.find(guild_rank)
	if idx == -1 or idx >= Balance.RANKS.size() - 1:
		return 999999
	return Balance.GUILD_RANK_XP[idx + 1]


func add_guild_xp(amount: int) -> bool:
	if amount <= 0:
		return false
	guild_xp += amount
	var current_idx := Balance.RANKS.find(guild_rank)
	if current_idx == -1:
		current_idx = 0
	var original_rank := guild_rank
	while current_idx < Balance.RANKS.size() - 1 and guild_xp >= Balance.GUILD_RANK_XP[current_idx + 1]:
		current_idx += 1
		guild_rank = Balance.RANKS[current_idx]
	return guild_rank != original_rank


func get_relation(npc: String) -> int:
	if not relations.has(npc):
		relations[npc] = 0
	return int(relations[npc])


func modify_relation(npc: String, delta: int) -> int:
	var current := get_relation(npc)
	var next := clampi(current + delta, Balance.RELATION_MIN, Balance.RELATION_MAX)
	relations[npc] = next
	return next


func award_party_member_xp(amount: int) -> Array[String]:
	var promoted_names: Array[String] = []
	if amount <= 0:
		return promoted_names
	for member in members:
		if not member.get("alive", true) or not member.get("in_party", false):
			continue
		if member_system.promote_member(member, amount):
			promoted_names.append(str(member.get("name", "Członek gildii")))
	return promoted_names


# ---------- zlecenia ----------

func generate_quests() -> void:
	quests = []
	var count := 3 + floori(best_floor / 2.0)
	var guild_rank_idx := maxi(0, Balance.RANKS.find(guild_rank))
	for _i in count:
		var q: Dictionary = quest_system.generate_quest(best_floor + 1, guild_rank_idx)
		quests.append(q)


func accept_quest(quest_id: String) -> bool:
	if not active_quest.is_empty():
		return false
	for i in quests.size():
		var q: Dictionary = quests[i]
		if q["id"] == quest_id:
			active_quest = q.duplicate()
			quest_system.start_quest(active_quest)
			quests.remove_at(i)
			save_game()
			return true
	return false


func complete_quest() -> int:
	if active_quest.is_empty() or not active_quest.get("completed", false):
		return 0
	var quest_id: String = str(active_quest.get("id", ""))
	var reward: int = int(active_quest.get("reward", 0))
	gold += reward
	add_guild_xp(Balance.GUILD_XP_PER_QUEST)
	active_quest = {}
	
	# Czyść również stare zapisy, w których przyjęte zlecenie zostało na tablicy.
	for i in quests.size():
		if quests[i].get("id", "") == quest_id:
			quests.remove_at(i)
			break
	
	save_game()
	return reward


func update_quest_progress(amount: int = 1) -> void:
	if not active_quest.is_empty():
		quest_system.update_progress(active_quest, amount)


# Nowy dzień z leczeniem: z Lecznicą pełne, bez niej część HP.
func next_day() -> void:
	day += 1
	if has_room("infirmary"):
		hp = max_hp()
	else:
		hp = mini(max_hp(), hp + ceili(max_hp() * Balance.REST_HEAL_PCT))
	
	# generuj nowe zlecenia co kilka dni
	if day % 3 == 1:
		generate_quests()


# Płatny nocleg w gildii. Zwraca false, gdy brakuje złota.
func rest() -> bool:
	if gold < Balance.REST_COST:
		return false
	gold -= Balance.REST_COST
	next_day()
	return true


# Bezpieczny powrót z lochu: złoto do skarbca, nowy dzień (darmowy).
func begin_run() -> bool:
	if in_run or player_class.is_empty():
		return false
	in_run = true
	run_floor = 1
	if save_game():
		return true
	in_run = false
	run_floor = 0
	return false


func update_run_floor(floor_reached: int) -> bool:
	if not in_run or floor_reached < 1:
		return false
	var previous_floor := run_floor
	run_floor = maxi(run_floor, floor_reached)
	if save_game():
		return true
	run_floor = previous_floor
	return false


func return_from_dungeon(run_gold: int, floor_reached: int, player_hp: int) -> bool:
	if not in_run:
		message = "Nie można wrócić z lochu, ponieważ żadna wyprawa nie jest aktywna."
		return false
	var previous_gold := gold
	var previous_day := day
	var previous_best_floor := best_floor
	var previous_hp := hp
	var previous_in_run := in_run
	var previous_run_floor := run_floor
	var previous_quests := quests.duplicate(true)
	var previous_members := members.duplicate(true)
	in_run = false
	run_floor = 0
	gold += run_gold
	best_floor = maxi(best_floor, floor_reached)
	hp = player_hp
	# Wyjście od razu po wejściu (bez łupu i bez zejścia niżej) nie daje darmowego dnia ani leczenia.
	if run_gold > 0 or floor_reached > 1:
		next_day()
		var promotions := award_party_member_xp(maxi(0, floor_reached - 1) * Balance.MEMBER_XP_PER_FLOOR)
		message = "Wracasz z piętra %d z %d zł. Nowy dzień: %d." % [floor_reached, run_gold, day]
		if not promotions.is_empty():
			message += " Awans: %s." % ", ".join(PackedStringArray(promotions))
	else:
		message = "Wracasz do miasta bez wyprawy. Dzień się nie zmienił."
	if save_game():
		return true
	var save_error := message
	gold = previous_gold
	day = previous_day
	best_floor = previous_best_floor
	hp = previous_hp
	in_run = previous_in_run
	run_floor = previous_run_floor
	quests = previous_quests
	members = previous_members
	message = save_error
	return false


# Śmierć: tracisz złoto z wyprawy i plecak, założony sprzęt zostaje.
func die_in_dungeon(run_gold: int, floor_reached: int) -> bool:
	if not in_run:
		return false
	var previous_best_floor := best_floor
	var previous_day := day
	var previous_hp := hp
	var previous_in_run := in_run
	var previous_run_floor := run_floor
	var previous_pack: Array = inv.pack.duplicate(true)
	var previous_active_quest: Dictionary = active_quest.duplicate(true)
	in_run = false
	run_floor = 0
	best_floor = maxi(best_floor, floor_reached)
	inv.pack = []
	active_quest = {}
	day += 1
	hp = maxi(1, ceili(max_hp() * Balance.DEATH_HP_PCT))
	message = "Ledwo żywego wynieśli Cię z piętra %d. Przepadło %d zł i plecak." % [floor_reached, run_gold]
	if save_game():
		return true
	var save_error := message
	best_floor = previous_best_floor
	day = previous_day
	hp = previous_hp
	in_run = previous_in_run
	run_floor = previous_run_floor
	inv.pack = previous_pack
	active_quest = previous_active_quest
	message = save_error
	return false


# Gra zamknięta w trakcie wyprawy liczy się jak śmierć, żeby nie dało się uciec przed karą.
func abandon_run() -> bool:
	if not in_run:
		return false
	var previous_best_floor := best_floor
	var previous_day := day
	var previous_hp := hp
	var previous_in_run := in_run
	var previous_run_floor := run_floor
	var previous_pack: Array = inv.pack.duplicate(true)
	var previous_active_quest: Dictionary = active_quest.duplicate(true)
	in_run = false
	best_floor = maxi(best_floor, run_floor)
	run_floor = 0
	inv.pack = []
	active_quest = {}
	day += 1
	hp = maxi(1, ceili(max_hp() * Balance.DEATH_HP_PCT))
	message = "Wyprawa urwała się na piętrze %d. Przepadło złoto z wyprawy i plecak. Dzień %d." % [previous_run_floor, day]
	if save_game():
		return true
	var save_error := message
	best_floor = previous_best_floor
	day = previous_day
	hp = previous_hp
	in_run = previous_in_run
	run_floor = previous_run_floor
	inv.pack = previous_pack
	active_quest = previous_active_quest
	message = save_error
	return false


# ---------- zapis ----------

func save_game() -> bool:
	var data := {
		"version": Balance.SAVE_VERSION,
		"gold": gold, "day": day, "player_class": player_class, "intro_complete": intro_complete,
		"level": level, "xp": xp, "stat_points": stat_points,
		"talent_points": talent_points, "talents": talents,
		"stats": stats, "hp": hp, "rooms": rooms, "best_floor": best_floor,
		"weapon": inv.weapon, "armor": inv.armor, "pack": inv.pack,
		"in_run": in_run, "run_floor": run_floor,
		"members": members, "relations": relations, "guild_rank": guild_rank, "guild_xp": guild_xp,
		"quests": quests, "active_quest": active_quest,
	}
	if not _is_valid_save_data(data):
		return _save_failed("Stan gry zawiera nieprawidłowe dane i nie został zapisany.")
	var f := FileAccess.open(SAVE_TMP, FileAccess.WRITE)
	if f == null:
		return _save_failed("Nie można utworzyć pliku tymczasowego zapisu.")
	f.store_string(JSON.stringify(data))
	f.flush()
	var write_error := f.get_error()
	f.close()
	if write_error != OK:
		_remove_save_file(SAVE_TMP)
		return _save_failed("Nie udało się zapisać danych na dysku.")

	var save_absolute := ProjectSettings.globalize_path(SAVE_PATH)
	var backup_absolute := ProjectSettings.globalize_path(SAVE_BACKUP)
	var temp_absolute := ProjectSettings.globalize_path(SAVE_TMP)
	if loaded_from_backup and FileAccess.file_exists(SAVE_PATH):
		if not _remove_save_file(SAVE_CORRUPT):
			_remove_save_file(SAVE_TMP)
			return _save_failed("Nie można przygotować miejsca na uszkodzony zapis.")
		var archive_error: Error = DirAccess.rename_absolute(save_absolute, ProjectSettings.globalize_path(SAVE_CORRUPT))
		if archive_error != OK:
			_remove_save_file(SAVE_TMP)
			return _save_failed("Odzyskano kopię zapasową, ale nie można odłożyć uszkodzonego pliku.")
		loaded_from_backup = false

	if FileAccess.file_exists(SAVE_PATH):
		if not _remove_save_file(SAVE_BACKUP):
			_remove_save_file(SAVE_TMP)
			return _save_failed("Nie można przygotować kopii zapasowej.")
		var backup_error: Error = DirAccess.rename_absolute(save_absolute, backup_absolute)
		if backup_error != OK:
			_remove_save_file(SAVE_TMP)
			return _save_failed("Nie można zabezpieczyć poprzedniego zapisu.")

	var replace_error: Error = DirAccess.rename_absolute(temp_absolute, save_absolute)
	if replace_error != OK:
		if FileAccess.file_exists(SAVE_BACKUP) and not FileAccess.file_exists(SAVE_PATH):
			DirAccess.rename_absolute(backup_absolute, save_absolute)
		_remove_save_file(SAVE_TMP)
		return _save_failed("Nie można zatwierdzić nowego zapisu.")
	storage_error = ""
	return true


func load_game() -> bool:
	loaded_from_backup = false
	storage_error = ""
	var data := _read_save_data(SAVE_PATH)
	if data.is_empty():
		var primary_error := message
		data = _read_save_data(SAVE_BACKUP)
		if data.is_empty():
			if FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_BACKUP):
				message = "%s Nie znaleziono poprawnego zapisu ani kopii zapasowej." % primary_error
				push_warning(message)
			return false
		loaded_from_backup = true
		message = "Odzyskano zapis z kopii zapasowej. Głównego pliku nie udało się odczytać."
		storage_error = message
		push_warning(message)
	elif not FileAccess.file_exists(SAVE_PATH):
		loaded_from_backup = true
		message = "Odzyskano zapis z kopii zapasowej."
		storage_error = message

	# JSON zwraca liczby jako float, więc wszystko rzutujemy na int.
	gold = maxi(0, int(data.get("gold", 0)))
	day = maxi(1, int(data.get("day", 1)))
	player_class = str(data.get("player_class", ""))
	intro_complete = bool(data.get("intro_complete", true))
	level = int(data.get("level", 1))
	level = clampi(level, 1, ClassProgression.MAX_LEVEL)
	xp = maxi(0, int(data.get("xp", 0)))
	stat_points = maxi(0, int(data.get("stat_points", 0)))
	talents = {}
	var saved_talents: Dictionary = data.get("talents", {})
	for node in ClassProgression.nodes_for_class(player_class):
		var talent_id := str(node["id"])
		if bool(saved_talents.get(talent_id, false)):
			talents[talent_id] = true
	talent_points = maxi(0, int(data.get("talent_points", maxi(floori(float(level) / ClassProgression.TALENT_LEVEL_INTERVAL) - talents.size(), 0))))
	if level >= ClassProgression.MAX_LEVEL:
		xp = 0
	else:
		xp = maxi(xp, 0)
		while level < ClassProgression.MAX_LEVEL and xp >= ClassProgression.xp_required(level):
			xp -= ClassProgression.xp_required(level)
			level += 1
			stat_points += Balance.POINTS_PER_LEVEL
			if level % 5 == 0:
				stat_points += 1
			if level % ClassProgression.TALENT_LEVEL_INTERVAL == 0:
				talent_points += 1
	if level >= ClassProgression.MAX_LEVEL:
		xp = 0
	var s: Dictionary = data.get("stats", {})
	stats = {
		"str": clampi(int(s.get("str", 0)), 0, 25),
		"vit": clampi(int(s.get("vit", 0)), 0, 25),
		"agi": clampi(int(s.get("agi", 0)), 0, 25),
	}
	rooms = []
	for r in data.get("rooms", ["hall"]):
		rooms.append(str(r))
	best_floor = maxi(0, int(data.get("best_floor", 0)))
	inv.weapon = clean_item(data.get("weapon", {}))
	inv.armor = clean_item(data.get("armor", {}))
	inv.pack = []
	for it in data.get("pack", []):
		inv.pack.append(clean_item(it))
	refresh_inventory()
	hp = clampi(int(data.get("hp", max_hp())), 1, max_hp())
	in_run = bool(data.get("in_run", false))
	run_floor = maxi(0, int(data.get("run_floor", 1 if in_run else 0)))
	
	# członkowie gildii
	members = data.get("members", [])
	relations = data.get("relations", {})
	if relations.is_empty():
		reset_relations()
	else:
		for npc in Balance.RELATION_DEFAULTS.keys():
			if not relations.has(npc):
				relations[npc] = int(Balance.RELATION_DEFAULTS[npc])
	guild_rank = data.get("guild_rank", "F")
	if not Balance.RANKS.has(guild_rank):
		guild_rank = "F"
	var saved_rank_idx: int = Balance.RANKS.find(guild_rank)
	guild_xp = maxi(0, int(data.get("guild_xp", Balance.GUILD_RANK_XP[maxi(0, saved_rank_idx)])))
	for member in members:
		var member_rank_idx: int = Balance.RANKS.find(member.get("rank", "F"))
		if member_rank_idx < 0:
			member_rank_idx = 0
			member["rank"] = "F"
		member["xp"] = int(member.get("xp", Balance.MEMBER_RANK_XP[member_rank_idx]))
	if not has_room("barracks"):
		clear_party()
	
	# zlecenia
	quests = data.get("quests", [])
	active_quest = data.get("active_quest", {})
	
	if not loaded_from_backup:
		message = "Wczytano zapis. Dzień %d." % day
	if in_run:
		if Balance.QUIT_IN_RUN_IS_DEATH:
			abandon_run()
			# abandon_run() ustawia własny message – nie nadpisuj go
		else:
			in_run = false
			run_floor = 0
	return true


func _read_save_data(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		message = "Nie można otworzyć pliku zapisu: %s." % path
		storage_error = message
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not _is_valid_save_data(parsed):
		message = "Plik zapisu jest uszkodzony lub ma nieobsługiwany format: %s." % path
		storage_error = message
		return {}
	return parsed


func _is_valid_save_data(data: Dictionary) -> bool:
	var version_value = data.get("version", 1)
	if not _is_save_number(version_value):
		return false
	var version := int(version_value)
	if version < 1 or version > Balance.SAVE_VERSION:
		return false

	var numeric_fields := [
		"gold", "day", "level", "xp", "stat_points", "talent_points", "hp",
		"best_floor", "guild_xp", "run_floor",
	]
	for field in numeric_fields:
		if data.has(field) and not _is_save_number(data[field]):
			return false
	for field in ["player_class", "guild_rank"]:
		if data.has(field) and typeof(data[field]) != TYPE_STRING:
			return false
	for field in ["intro_complete", "in_run"]:
		if data.has(field) and typeof(data[field]) != TYPE_BOOL:
			return false
	for field in ["stats", "talents", "relations", "weapon", "armor", "active_quest"]:
		if data.has(field) and typeof(data[field]) != TYPE_DICTIONARY:
			return false
	for field in ["rooms", "pack", "members", "quests"]:
		if data.has(field) and typeof(data[field]) != TYPE_ARRAY:
			return false

	var stats: Dictionary = data.get("stats", {})
	for stat in ["str", "vit", "agi"]:
		if stats.has(stat) and not _is_save_number(stats[stat]):
			return false
	if not str(data.get("player_class", "")).is_empty() and str(data["player_class"]) not in Balance.PLAYER_CLASSES:
		return false
	if str(data.get("guild_rank", "F")) not in Balance.RANKS:
		return false
	var relations_data: Dictionary = data.get("relations", {})
	for relation in relations_data.values():
		if not _is_save_number(relation):
			return false
	var talents_data: Dictionary = data.get("talents", {})
	for unlocked in talents_data.values():
		if typeof(unlocked) != TYPE_BOOL:
			return false
	for room in data.get("rooms", []):
		if typeof(room) != TYPE_STRING:
			return false
	for collection_name in ["pack", "members", "quests"]:
		for entry in data.get(collection_name, []):
			if typeof(entry) != TYPE_DICTIONARY:
				return false
	var weapon_data: Dictionary = data.get("weapon", {})
	var armor_data: Dictionary = data.get("armor", {})
	if not weapon_data.is_empty():
		if not inv.is_valid_item(weapon_data) or weapon_data.get("slot", "") != "weapon":
			return false
	if not armor_data.is_empty():
		if not inv.is_valid_item(armor_data) or armor_data.get("slot", "") != "armor":
			return false
	for item in data.get("pack", []):
		if not inv.is_valid_item(item):
			return false
	for member in data.get("members", []):
		for field in ["id", "name", "class", "rank", "hp", "max_hp", "xp", "attack", "defense", "traits", "alive", "in_party"]:
			if not member.has(field):
				return false
		for field in ["hp", "max_hp", "xp", "attack", "defense", "cost", "floor_req"]:
			if member.has(field) and not _is_save_number(member[field]):
				return false
		for field in ["id", "name", "class", "rank"]:
			if member.has(field) and typeof(member[field]) != TYPE_STRING:
				return false
		if member.has("traits") and typeof(member["traits"]) != TYPE_ARRAY:
			return false
		for trait_name in member.get("traits", []):
			if typeof(trait_name) != TYPE_STRING:
				return false
		for field in ["alive", "in_party", "mutinous"]:
				if member.has(field) and typeof(member[field]) != TYPE_BOOL:
					return false
		for quest in data.get("quests", []):
			if not _is_valid_quest(quest):
				return false
		var saved_active_quest: Dictionary = data.get("active_quest", {})
		if not saved_active_quest.is_empty() and not _is_valid_quest(saved_active_quest):
			return false
	return true


func _is_valid_quest(quest: Dictionary) -> bool:
	for field in ["id", "type", "rank", "target", "target_str", "floor_req", "reward", "active", "completed", "progress"]:
		if not quest.has(field):
			return false
	for field in ["target", "floor_req", "reward", "progress"]:
		if not _is_save_number(quest[field]):
			return false
	for field in ["id", "type", "rank", "target_str"]:
		if typeof(quest[field]) != TYPE_STRING:
			return false
	if str(quest["type"]) not in Balance.QUEST_TYPES or str(quest["rank"]) not in Balance.RANKS:
		return false
	for field in ["active", "completed"]:
		if typeof(quest[field]) != TYPE_BOOL:
			return false
	return true


func _is_save_number(value: Variant) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	return absf(float(value)) <= 2147483647.0


func _save_failed(reason: String) -> bool:
	message = "Błąd zapisu: %s" % reason
	storage_error = message
	push_error(message)
	return false


func status_message() -> String:
	return storage_error if not storage_error.is_empty() else message


func _remove_save_file(path: String) -> bool:
	if FileAccess.file_exists(path):
		var remove_error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if remove_error != OK:
			push_warning("Nie można usunąć pliku pomocniczego zapisu: %s." % path)
			return false
	return true


func clean_item(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or raw.is_empty():
		return {}
	var item := {}
	for key in raw:
		var v = raw[key]
		item[key] = int(v) if typeof(v) == TYPE_FLOAT else v
	return item


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	reset()
