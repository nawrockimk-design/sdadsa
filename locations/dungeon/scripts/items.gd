extends RefCounted

const Balance = preload("res://shared/scripts/balance.gd")
const ICON_SHEET: Texture2D = preload("res://locations/dungeon/assets/items/ikony_przedmiotow.png")

const WEAPONS := ["Patyk", "Sztylet", "Miecz", "Topór bojowy", "Legendarny miecz"]
const WEAPON_WEIGHTS := [2, 2, 4, 6, 5]
const ARMORS := ["Szmaty", "Skórzana kurtka", "Kolczuga", "Płytowa zbroja", "Zbroja smoka"]
const ARMOR_WEIGHTS := [1, 3, 5, 7, 8]
const MATERIALS := {
	"iron_ore": {"name": "Ruda żelaza", "weight": 1},
	"monster_core": {"name": "Rdzeń potwora", "weight": 1},
	"herb": {"name": "Zioła lecznicze", "weight": 1},
}


static func material(id: String, count: int = 1) -> Dictionary:
	if not MATERIALS.has(id):
		return {}
	var data: Dictionary = MATERIALS[id]
	return {"slot": "material", "id": id, "name": data["name"], "count": count, "weight": data["weight"]}


# Im głębsze piętro, tym lepsze przedmioty (tier 0-4).
static func random_item(floor_num: int) -> Dictionary:
	var tier := clampi(randi_range(0, 1) + floori(floor_num / 3.0), 0, 4)
	if randf() < 0.5:
		return {"slot": "weapon", "name": WEAPONS[tier], "atk": tier + 1, "def": 0, "weight": WEAPON_WEIGHTS[tier]}
	return {"slot": "armor", "name": ARMORS[tier], "atk": 0, "def": 1 + floori(tier / 2.0), "weight": ARMOR_WEIGHTS[tier]}


static func potion() -> Dictionary:
	return {"slot": "potion", "name": "Mikstura leczenia", "heal": Balance.POTION_HEAL, "weight": 1}


static func describe(item: Dictionary) -> String:
	if item.is_empty():
		return "brak"
	if item["slot"] == "weapon":
		return "%s (+%d atak, waga %d)" % [item["name"], item["atk"], item["weight"]]
	if item["slot"] == "armor":
		return "%s (+%d obrona, waga %d)" % [item["name"], item["def"], item["weight"]]
	if item["slot"] == "material":
		return "%s ×%d (waga %d)" % [item["name"], int(item.get("count", 1)), int(item.get("weight", 0)) * int(item.get("count", 1))]
	if item["slot"] == "tool":
		return "%s (waga %d)" % [item["name"], item["weight"]]
	return "%s (+%d HP, waga %d)" % [item["name"], item["heal"], item["weight"]]


static func color_of(item: Dictionary) -> Color:
	if item["slot"] == "weapon":
		return Color(0.95, 0.55, 0.15)
	if item["slot"] == "armor":
		return Color(0.2, 0.8, 0.8)
	if item["slot"] == "material":
		match str(item.get("id", "")):
			"iron_ore":
				return Color(0.68, 0.7, 0.73)
			"monster_core":
				return Color(0.68, 0.42, 0.9)
			"herb":
				return Color(0.45, 0.82, 0.42)
	if item["slot"] == "tool":
		return Color(0.95, 0.52, 0.24)
	return Color(0.3, 0.5, 1.0)


static func icon_index(item: Dictionary) -> int:
	var name := str(item.get("name", "")).to_lower()
	match str(item.get("slot", "")):
		"weapon":
			if "łuk" in name or "strza" in name:
				return 4 if "łuk" in name else 5
			if "kostur" in name or "laska" in name or "patyk" in name:
				return 6
			return 0
		"armor":
			if "hełm" in name or "helm" in name:
				return 3
			if "tarcza" in name:
				return 1
			return 2
		"potion":
			return 9 if "mana" in name else 8
		"gold":
			return 10
		"key":
			return 11
		"material":
			match str(item.get("id", "")):
				"iron_ore":
					return 10
				"monster_core":
					return 11
				"herb":
					return 8
		"tool":
			var tool_type := str(item.get("tool_type", ""))
			if tool_type == "acid":
				return 8
			if tool_type == "bomb":
				return 10
			return 10
	return 0


static func draw_icon(canvas: CanvasItem, item: Dictionary, center: Vector2, size: Vector2) -> void:
	var index := icon_index(item)
	var source := Rect2(Vector2((index % 4) * 48, floori(index / 4.0) * 48), Vector2(48, 48))
	canvas.draw_texture_rect_region(
		ICON_SHEET,
		Rect2(center - size * 0.5, size),
		source,
		Color.WHITE,
		false,
		true
	)
