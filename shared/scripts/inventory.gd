extends RefCounted

var weapon: Dictionary = {}
var armor: Dictionary = {}
var pack: Array = []           # plecak: lista przedmiotów
var max_weight := 20           # tu zmienisz limit udźwigu


func reset() -> void:
	weapon = {}
	armor = {}
	pack = []


func attack_bonus() -> int:
	return weapon.get("atk", 0)


func defense() -> int:
	return armor.get("def", 0)


# Waga wszystkiego, co masz przy sobie (założone + plecak).
func total_weight() -> int:
	var w: int = 0
	if not weapon.is_empty():
		w += item_weight(weapon)
	if not armor.is_empty():
		w += item_weight(armor)
	for item in pack:
		if typeof(item) == TYPE_DICTIONARY:
			w += item_weight(item)
	return w


func can_carry(item: Dictionary) -> bool:
	if not is_valid_item(item):
		return false
	return total_weight() + item_weight(item) <= max_weight


# Dodaje do plecaka, jeśli się mieści. Zwraca true, gdy się udało.
func add(item: Dictionary) -> bool:
	if not is_valid_item(item):
		return false
	if not can_carry(item):
		return false
	if item["slot"] == "material":
		for existing in pack:
			if existing.get("slot", "") == "material" and existing.get("id", "") == item.get("id", ""):
				existing["count"] = int(existing.get("count", 1)) + int(item.get("count", 1))
				return true
	pack.append(item.duplicate(true))
	return true


# Zakłada przedmiot z plecaka. Poprzednio założony wraca do plecaka.
func equip_from_pack(index: int) -> bool:
	if index < 0 or index >= pack.size():
		return false
	if typeof(pack[index]) != TYPE_DICTIONARY:
		return false
	var item: Dictionary = pack[index]
	if not is_valid_item(item):
		return false
	if item.get("slot", "") not in ["weapon", "armor"]:
		return false
	pack.remove_at(index)
	var old: Dictionary = {}
	if item["slot"] == "weapon":
		old = weapon
		weapon = item
	else:
		old = armor
		armor = item
	if not old.is_empty():
		pack.append(old)
	return true


func unequip_to_pack(slot: String) -> bool:
	if slot not in ["weapon", "armor"]:
		return false
	var item: Dictionary = weapon if slot == "weapon" else armor
	if item.is_empty():
		return false
	if not is_valid_item(item):
		return false
	pack.append(item.duplicate(true))
	if slot == "weapon":
		weapon = {}
	else:
		armor = {}
	return true


func is_valid_item(item: Dictionary) -> bool:
	var slot := str(item.get("slot", ""))
	if slot not in ["weapon", "armor", "potion", "tool", "material"]:
		return false
	var weight = item.get("weight", 0)
	var count = item.get("count", 1)
	if typeof(weight) not in [TYPE_INT, TYPE_FLOAT] or float(weight) < 0.0 or float(weight) > 2147483647.0:
		return false
	if typeof(count) not in [TYPE_INT, TYPE_FLOAT] or float(count) < 1.0 or float(count) > 1000000.0:
		return false
	if float(weight) != float(int(weight)) or float(count) != float(int(count)):
		return false
	for field in ["atk", "def", "heal", "damage"]:
		if item.has(field):
			var value = item[field]
			if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or float(value) < 0.0 or float(value) > 2147483647.0:
				return false
	for field in ["name", "tool_type", "id"]:
		if item.has(field) and typeof(item[field]) != TYPE_STRING:
			return false
	if slot == "weapon" and not item.has("atk"):
		return false
	if slot == "armor" and not item.has("def"):
		return false
	if slot == "potion" and not item.has("heal"):
		return false
	if slot == "tool" and (not item.has("damage") or not item.has("tool_type")):
		return false
	if slot == "material" and str(item.get("id", "")).is_empty():
		return false
	return true


func item_weight(item: Dictionary) -> int:
	if not is_valid_item(item):
		return 0
	return int(item.get("weight", 0)) * int(item.get("count", 1))
