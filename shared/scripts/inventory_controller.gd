extends RefCounted
# Wspólna logika ekwipunku (UI + użycie) dla gildii, lochu i miasta.
# Używany przez: guild.gd, main.gd, city.gd

const InventoryWindow = preload("res://shared/scripts/inventory_window.gd")

var inventory_open := false
var inventory_cursor := 0

func is_open() -> bool:
	return inventory_open

func open() -> void:
	inventory_open = true
	inventory_cursor = 0

func close() -> void:
	inventory_open = false

func handle_key_input(keycode: int) -> bool:
	if not inventory_open:
		return false
	
	var item_count: int = GameState.inv.pack.size()
	match keycode:
		KEY_ESCAPE, KEY_I:
			close()
			return true
		KEY_LEFT, KEY_A:
			if item_count > 0:
				inventory_cursor = maxi(inventory_cursor - 1, 0)
			return true
		KEY_RIGHT, KEY_D:
			if item_count > 0:
				inventory_cursor = mini(inventory_cursor + 1, item_count - 1)
			return true
		KEY_UP, KEY_W:
			if item_count > 0:
				inventory_cursor = maxi(inventory_cursor - 5, 0)
			return true
		KEY_DOWN, KEY_S:
			if item_count > 0:
				inventory_cursor = mini(inventory_cursor + 5, item_count - 1)
			return true
		KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE:
			if item_count > 0:
				_use_selected_item()
			return true
		KEY_X:
			if item_count > 0:
				_drop_selected_item()
			return true
	return false

func handle_mouse_input(event: InputEventMouseButton, viewport_size: Vector2) -> bool:
	if not inventory_open or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return false
	
	var clicked_slot := InventoryWindow.equipment_slot_at(event.position, viewport_size)
	if not clicked_slot.is_empty():
		if GameState.inv.unequip_to_pack(clicked_slot):
			GameState.save_game()
		inventory_cursor = clampi(inventory_cursor, 0, maxi(GameState.inv.pack.size() - 1, 0))
		return true
	
	var clicked_item := InventoryWindow.pack_item_at(event.position, viewport_size, GameState.inv.pack.size(), inventory_cursor)
	if clicked_item < 0:
		return false
	if clicked_item == inventory_cursor and event.double_click:
		_use_selected_item()
	else:
		inventory_cursor = clicked_item
	return true

func _use_selected_item() -> void:
	if inventory_cursor < 0 or inventory_cursor >= GameState.inv.pack.size():
		return
	var item: Dictionary = GameState.inv.pack[inventory_cursor]
	match str(item.get("slot", "")):
		"potion":
			if GameState.hp >= GameState.max_hp():
				GameState.message = "Masz pełne HP — mikstura nie jest teraz potrzebna."
			else:
				var healed: int = mini(GameState.potion_heal_amount(int(item.get("heal", 0))), GameState.max_hp() - GameState.hp)
				GameState.hp += healed
				GameState.inv.pack.remove_at(inventory_cursor)
				GameState.message = "Pijesz miksturę (+%d HP)." % healed
				GameState.save_game()
		"weapon", "armor":
			GameState.inv.equip_from_pack(inventory_cursor)
			GameState.message = "Zakładasz: %s." % str(item.get("name", "przedmiot"))
			GameState.save_game()
		"material":
			GameState.message = "Materiały wykorzystasz w warsztacie rzemieślniczym."
		"tool":
			GameState.message = "Narzędzia rzemieślnicze możesz wykorzystać podczas wyprawy."
	inventory_cursor = clampi(inventory_cursor, 0, maxi(GameState.inv.pack.size() - 1, 0))

func _drop_selected_item() -> void:
	if inventory_cursor < 0 or inventory_cursor >= GameState.inv.pack.size():
		return
	# W lochu: wyrzuć na podłogę (main.gd ma swoją wersję)
	# W mieście/gildii: po prostu usuń
	var item: Dictionary = GameState.inv.pack[inventory_cursor]
	GameState.inv.pack.remove_at(inventory_cursor)
	GameState.message = "Wyrzucono: %s." % str(item.get("name", "przedmiot"))
	GameState.save_game()
	inventory_cursor = clampi(inventory_cursor, 0, maxi(GameState.inv.pack.size() - 1, 0))

func get_cursor() -> int:
	return inventory_cursor

func draw(canvas: CanvasItem, font: Font, viewport_size: Vector2, current_hp: int = -1) -> void:
	if not inventory_open:
		return
	InventoryWindow.draw_window(canvas, font, viewport_size, GameState.inv, inventory_cursor, current_hp)