extends RefCounted
# System zleceń gildii: generowanie, przyjmowanie, ukończenie.

const Balance = preload("res://shared/scripts/balance.gd")

const TYPE_NAMES := {
	"hunt": "Zabij %d wrogów",
	"gather": "Zbierz %d złota",
	"boss": "Pokonaj bossa na piętrze %d+",
}


func generate_quest(floor_req: int, max_rank_idx: int = Balance.RANKS.size() - 1) -> Dictionary:
	var q_type: String = Balance.QUEST_TYPES.pick_random()
	var highest_rank_idx: int = mini(
		mini(Balance.RANKS.size() - 1, floori(floor_req / 3.0)),
		clampi(max_rank_idx, 0, Balance.RANKS.size() - 1)
	)
	var rank_idx: int = randi_range(0, highest_rank_idx)
	var rank: String = Balance.RANKS[rank_idx]
	
	var target: int = 0
	var target_str: String = ""
	match q_type:
		"hunt":
			target = randi_range(3 + rank_idx * 2, 5 + rank_idx * 3)
			target_str = str(target)
		"gather":
			target = Balance.QUEST_REWARDS[rank_idx]
			target_str = str(target) + " zł"
		"boss":
			target = maxi(1, floor_req + rank_idx)
			target_str = "Piętro " + str(target)
	
	return {
		"id": str(randi()),
		"type": q_type,
		"rank": rank,
		"target": target,
		"target_str": target_str,
		"floor_req": floor_req,
		"reward": Balance.QUEST_REWARDS[rank_idx],
		"active": false,
		"completed": false,
		"progress": 0,
	}


func describe(quest: Dictionary) -> String:
	var rank_name: String = Balance.RANK_NAMES.get(quest["rank"], "?")
	var type_desc: String = TYPE_NAMES.get(quest["type"], "Nieznane")
	var desc: String = type_desc % quest["target"]
	
	var status: String = ""
	if quest["completed"]:
		status = "[UKOŃCZONE]"
	elif quest["active"]:
		status = "[W TRAKCIE]"
	else:
		status = "[DOSTĘPNE]"
	
	return "%s %s: %s   Nagroda: %d zł" % [rank_name, status, desc, quest["reward"]]


func start_quest(quest: Dictionary) -> void:
	quest["active"] = true
	quest["progress"] = 0


func update_progress(quest: Dictionary, amount: int = 1) -> void:
	if not quest["active"] or quest["completed"]:
		return
	quest["progress"] += amount
	if quest["progress"] >= quest["target"]:
		quest["completed"] = true
