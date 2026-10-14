extends RefCounted

const Items = preload("res://locations/dungeon/scripts/items.gd")
const Balance = preload("res://shared/scripts/balance.gd")

const ROOM_W := 15
const ROOM_H := 9
const CX := 7                      # środek pokoju (x)
const CY := 4                      # środek pokoju (y)
const FLOOR_W := 7
const FLOOR_H := 5
const DIRS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const ENTRIES := [Vector2i(7, 1), Vector2i(7, 7), Vector2i(1, 4), Vector2i(13, 4)]

var layout := {}                   # komórka piętra (Vector2i) -> dane pokoju
var current := Vector2i.ZERO       # w którym pokoju jest gracz
var stairs_cell := Vector2i.ZERO
var start_cell := Vector2i(3, 2)   # tu stoi portal do miasta


func current_room() -> Dictionary:
	return layout[current]


func new_room() -> Dictionary:
	return {"doors": [], "obstacles": [], "enemies": [], "items": [], "visited": false}


func generate(floor_num: int) -> void:
	layout.clear()
	var start := start_cell
	layout[start] = new_room()
	var cells: Array[Vector2i] = [start]
	var target_count := mini(5 + floor_num, 10)
	var guard := 0
	while cells.size() < target_count and guard < 500:
		guard += 1
		var origin_cell: Vector2i = cells.pick_random()
		var dir: Vector2i = DIRS.pick_random()
		var new_cell := origin_cell + dir
		if new_cell.x < 0 or new_cell.y < 0 or new_cell.x >= FLOOR_W or new_cell.y >= FLOOR_H:
			continue
		if layout.has(new_cell):
			continue
		layout[new_cell] = new_room()
		layout[origin_cell]["doors"].append(dir)
		layout[new_cell]["doors"].append(-dir)
		cells.append(new_cell)

	# schody w pokoju najdalszym od startu
	current = start
	stairs_cell = start
	var best := -1
	for c in cells:
		var dist := absi(c.x - start.x) + absi(c.y - start.y)
		if dist > best:
			best = dist
			stairs_cell = c

	for c in cells:
		if c != start:
			populate_room(layout[c], c == stairs_cell, floor_num)
	layout[start]["visited"] = true


func populate_room(room: Dictionary, is_stairs: bool, floor_num: int) -> void:
	# przeszkody (omijają osie środkowe, więc do drzwi zawsze da się dojść)
	for _i in randi_range(0, 6):
		var op := Vector2i(randi_range(2, ROOM_W - 3), randi_range(2, ROOM_H - 3))
		if op.x != CX and op.y != CY and not room["obstacles"].has(op):
			room["obstacles"].append(op)

	# wrogowie (tu tylko pozycja; HP i stan do walki dostają w main.gd -> prepare_room)
	var count := randi_range(1, 2) + floori(floor_num / 3.0)
	if is_stairs:
		count += 2
	var tries := 0
	while room["enemies"].size() < count and tries < 200:
		tries += 1
		var ep := random_free_tile(room)
		if ep == Vector2i(-1, -1):
			break
		if min_entry_distance(ep) < 3 or ep == Vector2i(CX, CY):
			continue
		room["enemies"].append({"pos": ep})

	# mikstura leżąca na podłodze
	if randf() < Balance.FLOOR_POTION_CHANCE:
		var pp := random_free_tile(room)
		if pp != Vector2i(-1, -1) and pp != Vector2i(CX, CY):
			room["items"].append({"pos": pp, "item": Items.potion()})

	# broń lub zbroja leżąca na podłodze
	if randf() < Balance.FLOOR_ITEM_CHANCE:
		var ip := random_free_tile(room)
		if ip != Vector2i(-1, -1) and ip != Vector2i(CX, CY):
			room["items"].append({"pos": ip, "item": Items.random_item(floor_num)})


func random_free_tile(room: Dictionary) -> Vector2i:
	for _i in 100:
		var p := Vector2i(randi_range(1, ROOM_W - 2), randi_range(1, ROOM_H - 2))
		if room["obstacles"].has(p):
			continue
		if enemy_index(room, p) != -1 or item_index(room, p) != -1:
			continue
		return p
	return Vector2i(-1, -1)


func min_entry_distance(p: Vector2i) -> int:
	var best := 999
	for e in ENTRIES:
		var ev: Vector2i = e
		best = mini(best, absi(p.x - ev.x) + absi(p.y - ev.y))
	return best


func enemy_index(room: Dictionary, pos: Vector2i) -> int:
	var list: Array = room["enemies"]
	for i in list.size():
		if list[i]["pos"] == pos:
			return i
	return -1


func item_index(room: Dictionary, pos: Vector2i) -> int:
	var list: Array = room["items"]
	for i in list.size():
		if list[i]["pos"] == pos:
			return i
	return -1


func door_direction(pos: Vector2i) -> Vector2i:
	if pos == Vector2i(CX, 0):
		return Vector2i.UP
	if pos == Vector2i(CX, ROOM_H - 1):
		return Vector2i.DOWN
	if pos == Vector2i(0, CY):
		return Vector2i.LEFT
	if pos == Vector2i(ROOM_W - 1, CY):
		return Vector2i.RIGHT
	return Vector2i.ZERO


func entry_position(dir: Vector2i) -> Vector2i:
	if dir == Vector2i.UP:
		return Vector2i(CX, ROOM_H - 2)
	if dir == Vector2i.DOWN:
		return Vector2i(CX, 1)
	if dir == Vector2i.LEFT:
		return Vector2i(ROOM_W - 2, CY)
	return Vector2i(1, CY)


func is_blocked(room: Dictionary, pos: Vector2i) -> bool:
	if pos.x <= 0 or pos.y <= 0 or pos.x >= ROOM_W - 1 or pos.y >= ROOM_H - 1:
		return true
	return room["obstacles"].has(pos)
