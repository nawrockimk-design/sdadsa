extends RefCounted
# Wszystkie ceny i liczby gry w jednym miejscu. Tu się balansuje.

# ---------- wybór klasy gracza ----------
const PLAYER_CLASSES := ["Wojownik", "Rycerz", "Mag", "Kapłan", "Łowca", "Inżynier", "Kowal", "Alchemik"]
const CLASS_PROFILES := {
	"Wojownik": {
		"role": "Natarcie",
		"playstyle": "Agresywny wojownik, który błyskawicznie kończy walki.",
		"passive_name": "Rozpęd",
		"passive_description": "+1 do ataku. Zabicie wroga skraca odnowienie umiejętności o 1,5 s.",
		"passive_attack": 1,
		"passive_kill_cooldown": 1.5,
		"skill_name": "Wirujące cięcie",
		"skill_description": "Potężne cięcie trafia wszystkich wrogów wokół ciebie.",
		"skill_type": "spin",
		"skill_cooldown": 5.0,
		"skill_radius": 85.0,
		"skill_multiplier": 2.0,
	},
	"Rycerz": {
		"role": "Obrońca",
		"playstyle": "Wytrzymały frontowiec, który przeczekuje najgroźniejsze ataki.",
		"passive_name": "Żelazna wola",
		"passive_description": "+1 obrony i +3 maks. HP.",
		"passive_defense": 1,
		"passive_max_hp": 3,
		"skill_name": "Postawa obronna",
		"skill_description": "Przez 4 s zmniejsza obrażenia o 3 i osłania pobliskich sojuszników.",
		"skill_type": "guard",
		"skill_cooldown": 7.0,
		"skill_duration": 4.0,
		"skill_power": 3,
		"skill_radius": 110.0,
	},
	"Mag": {
		"role": "Obrażenia obszarowe",
		"playstyle": "Raź grupy wrogów falą mocy i dopalaj ich magią ognia.",
		"passive_name": "Spalająca magia",
		"passive_description": "Umiejętności zadają o 25% większe obrażenia i podpalają trafionych wrogów.",
		"passive_skill_multiplier": 1.25,
		"skill_dot_damage": 1,
		"skill_dot_duration": 3.0,
		"skill_dot_interval": 0.75,
		"skill_name": "Fala mocy",
		"skill_description": "Rażąca fala uderza wrogów w dużym promieniu.",
		"skill_type": "nova",
		"skill_cooldown": 5.5,
		"skill_radius": 145.0,
		"skill_multiplier": 2.0,
	},
	"Kapłan": {
		"role": "Wsparcie",
		"playstyle": "Utrzymuje siebie i drużynę przy życiu podczas długiej wyprawy.",
		"passive_name": "Błogosławieństwo",
		"passive_description": "Mikstury leczą o 1 HP więcej; +2 maks. HP. Umiejętność leczy też pobliskich sojuszników.",
		"passive_potion_heal": 1,
		"passive_max_hp": 2,
		"skill_name": "Uzdrowienie",
		"skill_description": "Leczy ciebie i pobliskich sojuszników nawet o 5 HP.",
		"skill_type": "heal",
		"skill_cooldown": 8.0,
		"skill_power": 5,
		"skill_radius": 150.0,
	},
	"Łowca": {
		"role": "Precyzyjny dystans",
		"playstyle": "Kontroluj linię walki i oznaczaj cele do szybkiego dobicia.",
		"passive_name": "Łowiecki instynkt",
		"passive_description": "Zasięg ataku podstawowego większy o 20. Trafieni strzałą wrogowie są oznaczeni na 4 s i otrzymują +1 obrażeń.",
		"passive_attack_range": 20.0,
		"skill_name": "Przebijająca strzała",
		"skill_description": "Strzela przed siebie i trafia wrogów na linii.",
		"skill_type": "shot",
		"skill_cooldown": 3.5,
		"skill_range": 270.0,
		"skill_width": 34.0,
		"skill_multiplier": 1.8,
		"skill_mark_duration": 4.0,
		"skill_mark_bonus": 1,
	},
	"Inżynier": {
		"role": "Kontrola tłumu",
		"playstyle": "Rozbijaj skupiska wrogów bombami i spowalniaj ich, by zyskać przestrzeń.",
		"crafting_name": "Inżynieria",
		"crafting_description": "Wytwarza bomby i ładunki odłamkowe.",
		"passive_name": "Szybki montaż",
		"passive_description": "Umiejętność odnawia się o 15% szybciej. Bomba spowalnia trafionych wrogów.",
		"passive_skill_cooldown_multiplier": 0.85,
		"skill_name": "Bomba odłamkowa",
		"skill_description": "Eksplozja przed tobą rani wrogów w pobliżu.",
		"skill_type": "bomb",
		"skill_cooldown": 7.0,
		"skill_radius": 105.0,
		"skill_range": 100.0,
		"skill_multiplier": 2.4,
		"skill_slow_duration": 2.5,
	},
	"Kowal": {
		"role": "Wojownik wyposażenia",
		"playstyle": "Im lepszy ekwipunek, tym mocniej walczy; wzmacnia się przed starciem.",
		"crafting_name": "Kowalstwo",
		"crafting_description": "Wytwarza mocniejszą broń i zbroje.",
		"passive_name": "Mistrz wyposażenia",
		"passive_description": "Założona broń i zbroja dają po +1 do ataku i obrony.",
		"passive_equipment_bonus": 1,
		"skill_name": "Wzmocnienie",
		"skill_description": "Na 6 s dodaje +3 do ataku i +2 do obrony.",
		"skill_type": "forge",
		"skill_cooldown": 8.0,
		"skill_duration": 6.0,
		"skill_power": 3,
		"skill_defense_bonus": 2,
	},
	"Alchemik": {
		"role": "Obrażenia w czasie",
		"playstyle": "Rozlewaj kwas na grupy i wygrywaj dłuższe starcia dzięki truciznom.",
		"crafting_name": "Alchemia",
		"crafting_description": "Warzy mocniejsze mikstury i kwas.",
		"passive_name": "Mistrz mikstur",
		"passive_description": "Mikstury leczą o 2 HP więcej. Kwas zadaje obrażenia przez 4 s.",
		"passive_potion_heal": 2,
		"skill_name": "Fiolka żrącego kwasu",
		"skill_description": "Rozprysk kwasu rani wrogów przed tobą i zatruwa ich na 4 s.",
		"skill_type": "poison",
		"skill_cooldown": 7.0,
		"skill_radius": 95.0,
		"skill_range": 90.0,
		"skill_multiplier": 1.2,
		"skill_duration": 4.0,
		"skill_dot_damage": 1,
		"skill_dot_interval": 0.6,
	},
}
const BASE_HP := 10
const HP_PER_VIT := 3
const HP_PER_LEVEL := 2
const BASE_SPEED := 210.0
const SPEED_PER_AGI := 10.0
const PLAYER_RADIUS := 14.0
const HIT_INVULN := 0.5             # nietykalność po otrzymaniu ciosu (s)

# atak podstawowy
const ATTACK_RANGE := 50.0
const ATTACK_ARC_DOT := 0.25         # im mniej, tym szerszy łuk ciosu
const ATTACK_COOLDOWN := 0.35
const ATTACK_MIN_DMG := 1
const ATTACK_MAX_DMG := 3
const KNOCKBACK := 22.0

# unik (dash)
const DASH_SPEED := 640.0
const DASH_TIME := 0.15
const DASH_COOLDOWN := 0.9
const DASH_CD_PER_AGI := 0.05
const DASH_MIN_COOLDOWN := 0.4

# umiejętność: Cięcie wirowe
const SKILL_NAME := "Cięcie wirowe"
const SKILL_COOLDOWN := 5.0
const SKILL_RADIUS := 85.0
const SKILL_DMG_MULT := 2


static func class_profile(class_id: String) -> Dictionary:
	if class_id.is_empty():
		return {}
	return CLASS_PROFILES.get(class_id, CLASS_PROFILES["Rycerz"])

# ---------- System (rozwój) ----------
const POINTS_PER_LEVEL := 1
const STATS := ["str", "vit", "agi"]
const STAT_NAMES := {"str": "Siła", "vit": "Wytrzymałość", "agi": "Zręczność"}
const STAT_INFO := {
	"str": "+1 obrażeń każdego ciosu",
	"vit": "+3 maks. HP",
	"agi": "szybszy ruch, szybsze ataki i krótszy cooldown uniku",
}

# ---------- wrogowie ----------
const ENEMY_RADIUS := 14.0
const ENEMY_BASE_SPEED := 85.0
const ENEMY_SPEED_PER_FLOOR := 6.0
const ENEMY_BASE_HP := 3
const ENEMY_HP_PER_FLOOR := 2
const ENEMY_ATTACK_RANGE := 38.0     # z jakiej odległości zaczyna zamach
const ENEMY_HIT_RANGE := 50.0        # zasięg ciosu po zamachu
const ENEMY_WINDUP := 0.6            # czytelna zapowiedź ataku (s)
const ENEMY_RECOVER := 0.7
const ENEMY_BASE_DMG := 2

# ---------- nagrody ----------
const GOLD_MIN := 3
const GOLD_MAX := 6
const GOLD_PER_FLOOR := 2
const XP_BASE := 4
const XP_PER_FLOOR := 2

# ---------- gildia ----------
const BASE_WEIGHT := 20
const REST_HEAL_PCT := 0.3           # leczenie za dzień bez lecznicy (nocleg i powrót z lochu)
const REST_COST := 10                # cena noclegu w gildii (zł); powrót z lochu jest darmowy
const DEATH_HP_PCT := 0.3
const STORAGE_WEIGHT_BONUS := 10

# ---------- loch: leczenie i dropy ----------
const NEXT_FLOOR_HEAL := 3           # leczenie przy zejściu piętro niżej
const POTION_HEAL := 4
const DROP_POTION_CHANCE := 0.25     # z zabitego wroga
const DROP_ITEM_CHANCE := 0.15       # z zabitego wroga
const FLOOR_POTION_CHANCE := 0.4     # mikstura leżąca w pokoju
const FLOOR_ITEM_CHANCE := 0.35      # broń lub zbroja leżąca w pokoju
const ENEMY_SEPARATION := 60.0       # odpychanie wrogów od siebie (px/s)

const SAVE_VERSION := 4

# ---------- relacje i NPC ----------
const RELATION_MIN := -100
const RELATION_MAX := 100
const RELATION_DEFAULTS := {
	"burmistrz": 10,
	"edrian": 30,
	"mieszkańcy": 0,
	"czlonkowie": 0,
}

# true: zamknięcie gry w trakcie wyprawy liczy się jak śmierć (utrata plecaka).
# Na czas testów w edytorze Godot (F8 zatrzymuje grę) ustaw false.
const QUIT_IN_RUN_IS_DEATH := true

const ROOMS := [
	{"id": "hall", "name": "Sala główna", "cost": 0, "info": "Serce gildii. Tablica zleceń i rekrutacja."},
	{"id": "storage", "name": "Magazyn", "cost": 200, "info": "+10 udźwigu w lochu."},
	{"id": "infirmary", "name": "Lecznica", "cost": 300, "info": "Pełne leczenie po każdym dniu."},
	{"id": "barracks", "name": "Koszary", "cost": 250, "info": "Możesz zabrać do lochu do 3 członków gildii."},
]

# ---------- członkowie gildii ----------
const GUILD_RANK_XP := [0, 500, 1500, 3500, 7000, 12000, 20000]  # próg XP dla rang F-S
const GUILD_XP_PER_QUEST := 100
const MEMBER_RANK_XP := [0, 20, 60, 120, 200, 320, 500]
const MEMBER_XP_PER_FLOOR := 10
const MEMBER_ATTACK_PER_RANK := 1
const MEMBER_HP_PER_RANK := 2
const MAX_PARTY_SIZE := 3  # maksymalna liczba członków gildii w drużynie z Koszarami

# ---------- zlecenia ----------
const QUEST_TYPES := ["hunt", "gather"]
const QUEST_REWARDS := [30, 50, 80, 120, 200]  # złoto za zlecenia różnych rang

# ---------- rangi (używane przez członków i zlecenia) ----------
const RANKS := ["F", "E", "D", "C", "B", "A", "S"]
const RANK_NAMES := {
	"F": "Nowicjusz",
	"E": "Początkujący",
	"D": "Średni",
	"C": "Zaawansowany",
	"B": "Ekspert",
	"A": "Mistrz",
	"S": "Legenda"
}
