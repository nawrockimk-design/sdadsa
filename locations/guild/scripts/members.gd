extends RefCounted
# System guild members: data, recruitment, traits, ranks.

const Balance = preload("res://shared/scripts/balance.gd")

const CLASSES := ["Knight", "Hunter", "Mage"]
const TRAITS := ["brave", "cowardly", "loyal", "greedy", "calm", "aggressive", "intelligent", "stupid", "ego"]

# Trait effects: multipliers and flat bonuses applied to member stats/behavior
const TRAIT_EFFECTS := {
	"greedy": {"recruit_cost_mult": 1.5},
	"loyal": {"mutiny_immune": true},
	"aggressive": {"attack_bonus": 1, "defense_penalty": 1},
	"brave": {"defense_bonus": 1, "flee_threshold": 0.0},
	"cowardly": {"flee_threshold": 0.4},  # ucieka przy HP < 40%
	"calm": {"xp_mult": 1.1},
	"intelligent": {"skill_attack_bonus": 1},
	"stupid": {"attack_penalty": 1, "hp_bonus": 2},
	"ego": {},  # handled separately in check_mutiny
}

const NAMES_MALE := ["Kael", "Thorn", "Bran", "Gareth", "Darius", "Roran", "Edric", "Torin", "Varen", "Eldrin"]
const NAMES_FEMALE := ["Lyra", "Mara", "Elara", "Kira", "Sera", "Nyla", "Vera", "Tara", "Rina", "Eira"]


# Recruitment cost depends on rank and traits.
func recruit_cost(rank_idx: int, traits: Array = []) -> int:
	var base_cost := 50 + rank_idx * 50
	for trait in traits:
		if TRAIT_EFFECTS.has(trait) and TRAIT_EFFECTS[trait].has("recruit_cost_mult"):
			base_cost = ceilf(base_cost * TRAIT_EFFECTS[trait]["recruit_cost_mult"])
	return base_cost


# Apply trait effects to member stats (attack, defense, max_hp, etc.)
func apply_trait_effects(member: Dictionary) -> void:
	for trait in member.get("traits", []):
		if not TRAIT_EFFECTS.has(trait):
			continue
		var effects: Dictionary = TRAIT_EFFECTS[trait]
		if effects.has("attack_bonus"):
			member["attack"] = int(member.get("attack", 0)) + effects["attack_bonus"]
		if effects.has("attack_penalty"):
			member["attack"] = maxi(1, int(member.get("attack", 0)) - effects["attack_penalty"])
		if effects.has("defense_bonus"):
			member["defense"] = int(member.get("defense", 0)) + effects["defense_bonus"]
		if effects.has("defense_penalty"):
			member["defense"] = maxi(0, int(member.get("defense", 0)) - effects["defense_penalty"])
		if effects.has("hp_bonus"):
			member["max_hp"] = int(member.get("max_hp", 1)) + effects["hp_bonus"]
			member["hp"] = mini(member["hp"], member["max_hp"])
		# flee_threshold, mutiny_immune, xp_mult, skill_attack_bonus used elsewhere


# Generate new member with random stats.
func generate_member(floor_requirement: int = 1) -> Dictionary:
	var is_male: bool = randf() < 0.5
	var name: String = NAMES_MALE.pick_random() if is_male else NAMES_FEMALE.pick_random()
	var class_type: String = CLASSES.pick_random()
	var rank_idx: int = randi_range(0, 1)
	var rank: String = Balance.RANKS[rank_idx]
	
	var hp: int = Balance.BASE_HP + randi_range(0, 5)
	var attack: int = randi_range(1, 3)
	var defense: int = randi_range(0, 2)
	
	var traits_count: int = randi_range(1, 2)
	var traits: Array = []
	var pool: Array = TRAITS.duplicate()
	for _i in traits_count:
		if pool.is_empty():
			break
		var t: String = pool.pick_random()
		traits.append(t)
		pool.erase(t)
	
	var member := {
		"id": str(randi()),
		"name": name,
		"class": class_type,
		"rank": rank,
		"hp": hp,
		"max_hp": hp,
		"xp": Balance.MEMBER_RANK_XP[rank_idx],
		"attack": attack,
		"defense": defense,
		"traits": traits,
		"floor_req": floor_requirement,
		"cost": recruit_cost(rank_idx, traits),
		"alive": true,
		"in_party": false,
	}
	apply_trait_effects(member)
	return member


# Return member description.
func describe(member: Dictionary) -> String:
	if not member.get("alive", true):
		return "%s (dead)" % member["name"]
	var rank_name: String = Balance.RANK_NAMES.get(member["rank"], "Unknown")
	var state := ""
	if member.get("mutinous", false):
		state = " [BUNT]"
	return "%s - %s %s (Atk: %d, Def: %d)%s" % [member["name"], rank_name, member["class"], member["attack"], member["defense"], state]


# Return traits text comma-separated.
func traits_text(member: Dictionary) -> String:
	var traits: Array = member.get("traits", [])
	if traits.is_empty():
		return "none"
	return ", ".join(PackedStringArray(traits))


# Check if member has given trait.
func has_trait(member: Dictionary, trait_name: String) -> bool:
	return trait_name in member.get("traits", [])


func check_mutiny(member_list: Array, rep_score: int) -> Array:
	var mutinous: Array = []
	for member in member_list:
		if not member.get("alive", true):
			continue
		if member.get("mutinous", false):
			continue
		if has_trait(member, "ego") and rep_score <= -25:
			if has_trait(member, "loyal") and TRAIT_EFFECTS["loyal"]["mutiny_immune"]:
				continue  # loyal members never mutiny
			member["mutinous"] = true
			member["in_party"] = false
			mutinous.append(member["name"])
	return mutinous


# Promote rank if conditions met. Returns true if promoted.
func promote_member(member: Dictionary, xp_gained: int) -> bool:
	if not member.get("alive", true) or xp_gained <= 0:
		return false
	
	# Apply calm trait XP multiplier
	if has_trait(member, "calm") and TRAIT_EFFECTS.has("calm") and TRAIT_EFFECTS["calm"].has("xp_mult"):
		xp_gained = ceilf(xp_gained * TRAIT_EFFECTS["calm"]["xp_mult"])
	
	var current_idx := Balance.RANKS.find(member["rank"])
	if current_idx == -1 or current_idx >= Balance.RANKS.size() - 1:
		return false
	var member_xp: int = int(member.get("xp", Balance.MEMBER_RANK_XP[current_idx])) + xp_gained
	member["xp"] = member_xp
	var promoted := false
	while current_idx < Balance.RANKS.size() - 1 and member_xp >= Balance.MEMBER_RANK_XP[current_idx + 1]:
		current_idx += 1
		member["rank"] = Balance.RANKS[current_idx]
		member["attack"] = int(member.get("attack", 0)) + Balance.MEMBER_ATTACK_PER_RANK
		member["max_hp"] = int(member.get("max_hp", member.get("hp", 1))) + Balance.MEMBER_HP_PER_RANK
		member["hp"] = mini(int(member.get("max_hp", 1)), int(member.get("hp", 1)) + Balance.MEMBER_HP_PER_RANK)
		promoted = true
	return promoted
