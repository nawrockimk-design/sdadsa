extends RefCounted

const MAX_LEVEL := 50
const TALENT_LEVEL_INTERVAL := 6
const CLASS_TREES := {
	"Wojownik": [
		{"id": "warrior_root", "name": "Rozpęd", "description": "Atak podstawowy zadaje +1 obrażenie.", "requires": []},
		{"id": "warrior_branch_a", "name": "Egzekutor", "description": "Zabójstwo skraca odnowienie umiejętności o dodatkowe 1,5 s.", "requires": ["warrior_root"]},
		{"id": "warrior_branch_b", "name": "Szerokie cięcie", "description": "Wirujące cięcie ma promień większy o 30%.", "requires": ["warrior_root"]},
		{"id": "warrior_master_a", "name": "Łańcuch zabójstw", "description": "Zabójstwo skraca odnowienie umiejętności o dodatkowe 2 s.", "requires": ["warrior_branch_a"]},
		{"id": "warrior_master_b", "name": "Mistrz ostrza", "description": "Wirujące cięcie ma promień większy o kolejne 20%.", "requires": ["warrior_branch_b"]},
		{"id": "warrior_advanced_a", "name": "Krwawe ostrze", "description": "Wirujące cięcie zadaje dodatkowe 25% obrażeń.", "requires": ["warrior_master_a"]},
		{"id": "warrior_advanced_b", "name": "Rozmach", "description": "Wirujące cięcie ma promień większy o kolejne 20%.", "requires": ["warrior_master_b"]},
		{"id": "warrior_capstone", "name": "Niepowstrzymany", "description": "Wirujące cięcie zadaje +50% obrażeń.", "requires": ["warrior_advanced_a", "warrior_advanced_b"]},
	],
	"Rycerz": [
		{"id": "knight_root", "name": "Hart ducha", "description": "Maksymalne HP wzrasta o 3.", "requires": []},
		{"id": "knight_branch_a", "name": "Tarcza bastionu", "description": "Postawa zmniejsza obrażenia o dodatkowe 1.", "requires": ["knight_root"]},
		{"id": "knight_branch_b", "name": "Niezłomność", "description": "Postawa obronna trwa o 2 s dłużej.", "requires": ["knight_root"]},
		{"id": "knight_master_a", "name": "Mur tarcz", "description": "Postawa zmniejsza obrażenia o dodatkowe 1.", "requires": ["knight_branch_a"]},
		{"id": "knight_master_b", "name": "Długa straż", "description": "Postawa obronna trwa o kolejne 2 s dłużej.", "requires": ["knight_branch_b"]},
		{"id": "knight_advanced_a", "name": "Stalowa skóra", "description": "Zyskujesz +1 obrony na stałe.", "requires": ["knight_master_a"]},
		{"id": "knight_advanced_b", "name": "Strażniczy oddech", "description": "Umiejętność odnawia się o 15% szybciej.", "requires": ["knight_master_b"]},
		{"id": "knight_capstone", "name": "Strażnik drużyny", "description": "Postawa osłania pobliskich sojuszników.", "requires": ["knight_advanced_a", "knight_advanced_b"]},
	],
	"Mag": [
		{"id": "mage_root", "name": "Żar", "description": "Podpalenie trwa o 1 s dłużej.", "requires": []},
		{"id": "mage_branch_a", "name": "Rozbłysk", "description": "Fala mocy ma promień większy o 25%.", "requires": ["mage_root"]},
		{"id": "mage_branch_b", "name": "Dłuższe spalenie", "description": "Podpalenie zadaje obrażenia przez dodatkowe 2 s.", "requires": ["mage_root"]},
		{"id": "mage_master_a", "name": "Głębokie spalenie", "description": "Podpalenie zadaje obrażenia przez kolejne 2 s.", "requires": ["mage_branch_b"]},
		{"id": "mage_master_b", "name": "Przeciążenie", "description": "Fala mocy zadaje +20% obrażeń.", "requires": ["mage_branch_a"]},
		{"id": "mage_advanced_a", "name": "Płomień", "description": "Podpalenie zadaje +1 obrażenie na każde trafienie.", "requires": ["mage_master_a"]},
		{"id": "mage_advanced_b", "name": "Runiczny impuls", "description": "Fala mocy zadaje +25% obrażeń.", "requires": ["mage_master_b"]},
		{"id": "mage_capstone", "name": "Arcymag", "description": "Obrażenia fali mocy wzrastają o kolejne 40%.", "requires": ["mage_advanced_a", "mage_advanced_b"]},
	],
	"Kapłan": [
		{"id": "priest_root", "name": "Błogosławieństwo", "description": "Uzdrowienie przywraca dodatkowe 2 HP.", "requires": []},
		{"id": "priest_branch_a", "name": "Krąg odnowy", "description": "Zasięg leczenia sojuszników wzrasta o 50%.", "requires": ["priest_root"]},
		{"id": "priest_branch_b", "name": "Opatrzność", "description": "Maksymalne HP wzrasta o 3.", "requires": ["priest_root"]},
		{"id": "priest_master_a", "name": "Promień łaski", "description": "Uzdrowienie przywraca dodatkowe 2 HP.", "requires": ["priest_branch_a"]},
		{"id": "priest_master_b", "name": "Żelazna wiara", "description": "Maksymalne HP wzrasta o dodatkowe 3.", "requires": ["priest_branch_b"]},
		{"id": "priest_advanced_a", "name": "Moc modlitwy", "description": "Uzdrowienie przywraca dodatkowe 3 HP.", "requires": ["priest_master_a"]},
		{"id": "priest_advanced_b", "name": "Łaska", "description": "Umiejętność odnawia się o 20% szybciej.", "requires": ["priest_master_b"]},
		{"id": "priest_capstone", "name": "Światło nadziei", "description": "Uzdrowienie leczy pobliską drużynę o dodatkowe 3 HP.", "requires": ["priest_advanced_a", "priest_advanced_b"]},
	],
	"Łowca": [
		{"id": "hunter_root", "name": "Oznaczony cel", "description": "Oznaczeni wrogowie otrzymują +1 obrażenie.", "requires": []},
		{"id": "hunter_branch_a", "name": "Długi strzał", "description": "Przebijająca strzała leci o 30% dalej.", "requires": ["hunter_root"]},
		{"id": "hunter_branch_b", "name": "Celownik", "description": "Oznaczenie celu trwa o 3 s dłużej.", "requires": ["hunter_root"]},
		{"id": "hunter_master_a", "name": "Drapieżne oko", "description": "Oznaczenie celu trwa o kolejne 3 s dłużej.", "requires": ["hunter_branch_b"]},
		{"id": "hunter_master_b", "name": "Przebicie", "description": "Przebijająca strzała zadaje +20% obrażeń.", "requires": ["hunter_branch_a"]},
		{"id": "hunter_advanced_a", "name": "Łowcza precyzja", "description": "Oznaczony cel otrzymuje +1 obrażenie.", "requires": ["hunter_master_a"]},
		{"id": "hunter_advanced_b", "name": "Śmiercionośny lot", "description": "Przebijająca strzała zadaje +20% obrażeń.", "requires": ["hunter_master_b"]},
		{"id": "hunter_capstone", "name": "Łowca potworów", "description": "Strzała zadaje +50% obrażeń.", "requires": ["hunter_advanced_a", "hunter_advanced_b"]},
	],
	"Inżynier": [
		{"id": "engineer_root", "name": "Odłamek", "description": "Spowolnienie po bombie trwa o 1 s dłużej.", "requires": []},
		{"id": "engineer_branch_a", "name": "Większa komora", "description": "Promień bomby wzrasta o 25%.", "requires": ["engineer_root"]},
		{"id": "engineer_branch_b", "name": "Szybki zapłon", "description": "Umiejętność odnawia się o dodatkowe 10% szybciej.", "requires": ["engineer_root"]},
		{"id": "engineer_master_a", "name": "Szybszy zapłon", "description": "Umiejętność odnawia się o dodatkowe 10% szybciej.", "requires": ["engineer_branch_b"]},
		{"id": "engineer_master_b", "name": "Rozrzut odłamków", "description": "Promień bomby wzrasta o kolejne 20%.", "requires": ["engineer_branch_a"]},
		{"id": "engineer_advanced_a", "name": "Usprawniony zapłon", "description": "Umiejętność odnawia się o kolejne 15% szybciej.", "requires": ["engineer_master_a"]},
		{"id": "engineer_advanced_b", "name": "Wybuch rdzenia", "description": "Bomba zadaje +25% obrażeń.", "requires": ["engineer_master_b"]},
		{"id": "engineer_capstone", "name": "Mistrz oblężeń", "description": "Bomby zadają +50% obrażeń.", "requires": ["engineer_advanced_a", "engineer_advanced_b"]},
	],
	"Kowal": [
		{"id": "smith_root", "name": "Rzemieślnik", "description": "Wytwarzane uzbrojenie zyskuje +1 do ataku lub obrony.", "requires": []},
		{"id": "smith_branch_a", "name": "Oszczędny warsztat", "description": "Receptury kosztują o 25% mniej złota.", "requires": ["smith_root"]},
		{"id": "smith_branch_b", "name": "Mistrzowski kunszt", "description": "Wzmocnienie bojowe trwa o 3 s dłużej.", "requires": ["smith_root"]},
		{"id": "smith_master_a", "name": "Tańsze stopy", "description": "Receptury kosztują o kolejne 25% mniej złota.", "requires": ["smith_branch_a"]},
		{"id": "smith_master_b", "name": "Żar kuźni", "description": "Wzmocnienie bojowe trwa o kolejne 3 s dłużej.", "requires": ["smith_branch_b"]},
		{"id": "smith_advanced_a", "name": "Solidne ostrze", "description": "Wytwarzana broń i zbroja zyskują dodatkowe +1.", "requires": ["smith_master_a"]},
		{"id": "smith_advanced_b", "name": "Runiczne wzmocnienie", "description": "Wzmocnienie daje dodatkowe +2 do ataku.", "requires": ["smith_master_b"]},
		{"id": "smith_capstone", "name": "Arcymistrz kuźni", "description": "Wytwarzane uzbrojenie zyskuje kolejne +1 do ataku lub obrony.", "requires": ["smith_advanced_a", "smith_advanced_b"]},
	],
	"Alchemik": [
		{"id": "alchemist_root", "name": "Wydajny ekstrakt", "description": "Mikstury leczą o dodatkowe 2 HP.", "requires": []},
		{"id": "alchemist_branch_a", "name": "Eliksir zdrowia", "description": "Mikstury wytwarzane przez ciebie leczą o dodatkowe 3 HP.", "requires": ["alchemist_root"]},
		{"id": "alchemist_branch_b", "name": "Trwały kwas", "description": "Trucizna zadaje obrażenia przez dodatkowe 2 s.", "requires": ["alchemist_root"]},
		{"id": "alchemist_master_a", "name": "Czysty ekstrakt", "description": "Mikstury wytwarzane przez ciebie leczą o dodatkowe 2 HP.", "requires": ["alchemist_branch_a"]},
		{"id": "alchemist_master_b", "name": "Długie żrące działanie", "description": "Trucizna zadaje obrażenia przez kolejne 2 s.", "requires": ["alchemist_branch_b"]},
		{"id": "alchemist_advanced_a", "name": "Podwójny destylat", "description": "Mikstury wytwarzane przez ciebie leczą o dodatkowe 3 HP.", "requires": ["alchemist_master_a"]},
		{"id": "alchemist_advanced_b", "name": "Mocniejszy kwas", "description": "Kwas zadaje +1 obrażenie okresowe.", "requires": ["alchemist_master_b"]},
		{"id": "alchemist_capstone", "name": "Wielki alchemik", "description": "Kwas zadaje dwukrotnie większe obrażenia okresowe.", "requires": ["alchemist_advanced_a", "alchemist_advanced_b"]},
	],
}


static func xp_required(level: int) -> int:
	var safe_level := maxi(level, 1)
	return 12 + safe_level * 6 + floori(float(safe_level * safe_level) * 0.2)


static func nodes_for_class(class_id: String) -> Array:
	return CLASS_TREES.get(class_id, [])
