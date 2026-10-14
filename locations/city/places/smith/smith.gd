extends RefCounted

const Items = preload("res://locations/dungeon/scripts/items.gd")

const STOCK := [
	{"id": "iron_sword", "name": "Miecz", "cost": 70, "item": {"slot": "weapon", "name": "Miecz", "atk": 2, "def": 0, "weight": 4}},
	{"id": "leather_armor", "name": "Skórzana kurtka", "cost": 60, "item": {"slot": "armor", "name": "Skórzana kurtka", "atk": 0, "def": 1, "weight": 3}},
]

const RECIPES := {
	"Kowal": [
		{"name": "Miecz z rdzeniem", "description": "Broń: +4 ataku", "cost": 25, "materials": {"iron_ore": 3, "monster_core": 1}, "output": {"slot": "weapon", "name": "Miecz z rdzeniem", "atk": 4, "def": 0, "weight": 5}},
		{"name": "Pancerz hartowany", "description": "Zbroja: +3 obrony", "cost": 30, "materials": {"iron_ore": 2, "monster_core": 2}, "output": {"slot": "armor", "name": "Pancerz hartowany", "atk": 0, "def": 3, "weight": 6}},
	],
	"Inżynier": [
		{"name": "Bomba odłamkowa", "description": "Narzędzie: 8 obrażeń obszarowych", "cost": 12, "materials": {"iron_ore": 1, "monster_core": 1}, "output": {"slot": "tool", "tool_type": "bomb", "name": "Bomba odłamkowa", "damage": 8, "radius": 105.0, "weight": 2}},
		{"name": "Ładunek burzący", "description": "Narzędzie: 12 obrażeń obszarowych", "cost": 24, "materials": {"iron_ore": 2, "monster_core": 2}, "output": {"slot": "tool", "tool_type": "bomb", "name": "Ładunek burzący", "damage": 12, "radius": 135.0, "weight": 3}},
	],
	"Alchemik": [
		{"name": "Mikstura mistrzowska", "description": "Mikstura: przywraca 9 HP", "cost": 10, "materials": {"herb": 2, "monster_core": 1}, "output": {"slot": "potion", "name": "Mikstura mistrzowska", "heal": 9, "weight": 1}},
		{"name": "Fiolka żrącego kwasu", "description": "Narzędzie: trucizna obszarowa", "cost": 14, "materials": {"herb": 1, "monster_core": 2}, "output": {"slot": "tool", "tool_type": "acid", "name": "Fiolka żrącego kwasu", "damage": 3, "duration": 4.0, "tick_interval": 0.6, "radius": 95.0, "weight": 1}},
	],
}


static func recipes_for_class(class_id: String) -> Array:
	return RECIPES.get(class_id, [])


static func material_count(material_id: String) -> int:
	var count := 0
	for item in GameState.inv.pack:
		if item.get("slot", "") == "material" and item.get("id", "") == material_id:
			count += int(item.get("count", 1))
	return count


static func can_craft(index: int) -> bool:
	var recipes := recipes_for_class(GameState.player_class)
	if index < 0 or index >= recipes.size():
		return false
	var recipe: Dictionary = recipes[index]
	if GameState.gold < GameState.crafting_gold_cost(int(recipe["cost"])):
		return false
	for material_id in recipe["materials"]:
		if material_count(str(material_id)) < int(recipe["materials"][material_id]):
			return false
	return has_crafting_capacity(recipe)


static func has_crafting_capacity(recipe: Dictionary) -> bool:
	var consumed_weight := 0
	for material_id in recipe["materials"]:
		var remaining := int(recipe["materials"][material_id])
		for item in GameState.inv.pack:
			if item.get("slot", "") != "material" or item.get("id", "") != material_id:
				continue
			var consumed := mini(remaining, int(item.get("count", 1)))
			consumed_weight += consumed * int(item.get("weight", 0))
			remaining -= consumed
			if remaining <= 0:
				break
	var output: Dictionary = recipe["output"]
	var output_weight := int(output.get("weight", 0)) * int(output.get("count", 1))
	return GameState.inv.total_weight() - consumed_weight + output_weight <= GameState.inv.max_weight


static func craft(index: int) -> void:
	var recipes := recipes_for_class(GameState.player_class)
	if index < 0 or index >= recipes.size():
		return
	var recipe: Dictionary = recipes[index]
	var gold_cost := GameState.crafting_gold_cost(int(recipe["cost"]))
	if GameState.gold < gold_cost:
		GameState.message = "Brakuje %d zł do wytworzenia: %s." % [gold_cost - GameState.gold, recipe["name"]]
		return
	for material_id in recipe["materials"]:
		var required := int(recipe["materials"][material_id])
		if material_count(str(material_id)) < required:
			GameState.message = "Brakuje materiałów do wytworzenia: %s." % recipe["name"]
			return
	if not has_crafting_capacity(recipe):
		GameState.message = "Brakuje udźwigu na: %s." % recipe["name"]
		return
	var output: Dictionary = recipe["output"].duplicate(true)
	GameState.gold -= gold_cost
	if output["slot"] in ["weapon", "armor"]:
		var crafted_bonus := GameState.crafted_item_bonus()
		if output["slot"] == "weapon":
			output["atk"] = int(output.get("atk", 0)) + crafted_bonus
		else:
			output["def"] = int(output.get("def", 0)) + crafted_bonus
	elif output["slot"] == "potion":
		output["heal"] = int(output.get("heal", 0)) + GameState.crafted_potion_bonus()
	for material_id in recipe["materials"]:
		consume_material(str(material_id), int(recipe["materials"][material_id]))
	GameState.inv.add(output)
	GameState.message = "Wytworzono: %s." % recipe["name"]
	GameState.save_game()


static func consume_material(material_id: String, amount: int) -> void:
	for index in range(GameState.inv.pack.size() - 1, -1, -1):
		var item: Dictionary = GameState.inv.pack[index]
		if item.get("slot", "") != "material" or item.get("id", "") != material_id:
			continue
		var stack := int(item.get("count", 1))
		var consumed := mini(stack, amount)
		amount -= consumed
		stack -= consumed
		if stack <= 0:
			GameState.inv.pack.remove_at(index)
		else:
			item["count"] = stack
		if amount <= 0:
			return


static func buy_item(index: int) -> void:
	var stock: Dictionary = STOCK[index]
	var item: Dictionary = stock["item"]
	var cost: int = stock["cost"]
	if GameState.gold < cost:
		GameState.message = "Brakuje %d zł na: %s." % [cost - GameState.gold, stock["name"]]
		return
	if not GameState.inv.can_carry(item):
		GameState.message = "Nie masz miejsca w ekwipunku na ten przedmiot."
		return
	GameState.gold -= cost
	# Dodaj do plecaka (nie zakładaj automatycznie) – gracz zdecyduje w ekwipunku
	if GameState.inv.add(item.duplicate()):
		GameState.message = "Kupiono: %s (w plecaku)." % stock["name"]
	else:
		# Nie powinno się zdarzyć bo can_carry sprawdził, ale fallback
		GameState.message = "Błąd: przedmiot zniknął! Zgłoś to."
	GameState.save_game()


static func draw_overlay(canvas: CanvasItem, font: Font, viewport_size: Vector2, cursor: int) -> void:
	var recipes := recipes_for_class(GameState.player_class)
	if not recipes.is_empty():
		draw_crafting_overlay(canvas, font, viewport_size, cursor, recipes)
		return
	var panel := Rect2((viewport_size - Vector2(600, 300)) * 0.5, Vector2(600, 300))
	canvas.draw_rect(panel, Color(0.02, 0.05, 0.1, 0.97))
	canvas.draw_rect(panel, Color(0.95, 0.8, 0.35), false, 2.0)
	canvas.draw_string(font, panel.position + Vector2(24, 40), "MIEJSKI KOWAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.95, 0.8, 0.35))
	canvas.draw_string(font, panel.position + Vector2(24, 68), "Złoto: %d" % GameState.gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	for i in STOCK.size():
		var stock: Dictionary = STOCK[i]
		var item: Dictionary = stock["item"]
		var bonus := "+%d ataku" % item["atk"] if item["slot"] == "weapon" else "+%d obrony" % item["def"]
		var pos := panel.position + Vector2(34, 124 + i * 54)
		var selected := i == cursor
		if selected:
			canvas.draw_rect(Rect2(pos - Vector2(12, 24), Vector2(510, 42)), Color(0.15, 0.2, 0.28))
		canvas.draw_string(font, pos, ("> " if selected else "  ") + "%s (%s) — %d zł" % [
			stock["name"], bonus, stock["cost"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 17,
			Color(0.95, 0.8, 0.35) if selected else Color.WHITE)
	canvas.draw_string(font, panel.position + Vector2(24, panel.size.y - 20), "W/S: wybór   Enter: kup i załóż   Esc: wyjdź", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.65, 0.7, 0.78))


static func draw_crafting_overlay(canvas: CanvasItem, font: Font, viewport_size: Vector2, cursor: int, recipes: Array) -> void:
	var panel := Rect2((viewport_size - Vector2(680, 420)) * 0.5, Vector2(680, 420))
	canvas.draw_rect(panel, Color(0.02, 0.05, 0.1, 0.97))
	canvas.draw_rect(panel, Color(0.95, 0.8, 0.35), false, 2.0)
	canvas.draw_string(font, panel.position + Vector2(24, 40), "WARSZTAT RZEMIEŚLNICZY — %s" % GameState.player_class.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(0.95, 0.8, 0.35))
	canvas.draw_string(font, panel.position + Vector2(24, 70), "Złoto: %d   Ruda: %d   Rdzenie: %d   Zioła: %d   Udźwig: %d/%d" % [
		GameState.gold, material_count("iron_ore"), material_count("monster_core"),
		material_count("herb"), GameState.inv.total_weight(), GameState.inv.max_weight
	], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.82, 0.85, 0.88))
	for i in recipes.size():
		var recipe: Dictionary = recipes[i]
		var y := 128.0 + float(i) * 112.0
		var selected := i == cursor
		var affordable := can_craft(i)
		if selected:
			canvas.draw_rect(Rect2(panel.position + Vector2(16, y - 24), Vector2(panel.size.x - 32, 94)), Color(0.15, 0.2, 0.28))
		var color := Color(0.95, 0.8, 0.35) if selected else (Color.WHITE if affordable else Color(0.55, 0.55, 0.58))
		canvas.draw_string(font, panel.position + Vector2(30, y), ("> " if selected else "  ") + str(recipe["name"]) + " — %d zł" % GameState.crafting_gold_cost(int(recipe["cost"])),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, color)
		canvas.draw_string(font, panel.position + Vector2(52, y + 25), str(recipe["description"]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.84, 0.88))
		canvas.draw_string(font, panel.position + Vector2(52, y + 49), "Wymagane: " + format_materials(recipe["materials"]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.65, 0.72, 0.78))
	canvas.draw_string(font, panel.position + Vector2(24, panel.size.y - 20), "W/S: wybór   Enter/E: wytwórz   Esc: wyjdź",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.65, 0.7, 0.78))


static func format_materials(materials: Dictionary) -> String:
	var names := {"iron_ore": "ruda", "monster_core": "rdzenie", "herb": "zioła"}
	var parts := PackedStringArray()
	for material_id in materials:
		parts.append("%s ×%d (masz %d)" % [names.get(material_id, str(material_id)), int(materials[material_id]), material_count(str(material_id))])
	return ", ".join(parts)
