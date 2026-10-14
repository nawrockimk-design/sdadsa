extends RefCounted
# Wspólna logika systemu (statystyki + talenty) dla gildii, lochu i miasta.
# Używany przez: guild.gd, main.gd, city.gd

const Balance = preload("res://shared/scripts/balance.gd")
const ClassProgression = preload("res://shared/scripts/class_progression.gd")

var system_open := false
var system_cursor := 0
var system_tree_mode := false

func is_open() -> bool:
	return system_open

func open(tree_mode: bool = false) -> void:
	system_open = true
	system_tree_mode = tree_mode
	system_cursor = 0

func close() -> void:
	system_open = false

func toggle_tree_mode() -> void:
	system_tree_mode = not system_tree_mode
	system_cursor = 0

func handle_input(keycode: int) -> bool:
	if not system_open:
		return false
	
	match keycode:
		KEY_ESCAPE, KEY_TAB:
			close()
			return true
		KEY_T:
			toggle_tree_mode()
			return true
		KEY_UP, KEY_W:
			var option_count := ClassProgression.nodes_for_class(GameState.player_class).size() if system_tree_mode else Balance.STATS.size()
			system_cursor = (system_cursor - 1 + option_count) % option_count
			return true
		KEY_DOWN, KEY_S:
			var option_count := ClassProgression.nodes_for_class(GameState.player_class).size() if system_tree_mode else Balance.STATS.size()
			system_cursor = (system_cursor + 1) % option_count
			return true
		KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE:
			if system_tree_mode:
				var nodes := ClassProgression.nodes_for_class(GameState.player_class)
				if system_cursor < nodes.size():
					GameState.unlock_talent(str(nodes[system_cursor]["id"]))
			else:
				var stat: String = Balance.STATS[system_cursor]
				if GameState.spend_point(stat):
					GameState.save_game()
			return true
	return false

func get_cursor() -> int:
	return system_cursor

func is_tree_mode() -> bool:
	return system_tree_mode

func draw(canvas: CanvasItem, font: Font, viewport_size: Vector2) -> void:
	if not system_open:
		return
	var panel_size := Vector2(minf(760.0, viewport_size.x - 24.0), minf(500.0, viewport_size.y - 24.0))
	var panel := Rect2((viewport_size - panel_size) * 0.5, panel_size)
	preload("res://locations/guild/scripts/ui/system_window.gd").draw_window(canvas, font, panel, system_cursor, system_tree_mode)