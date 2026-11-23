class_name Bestiary
extends RefCounted
## Bestiary: estadísticas, ataques y apariencia de cada enemigo. Ninguno se repite.
## Para agregar un enemigo basta con sumar su entrada aquí y colocarlo en un nivel.
##   effect: raise_atk, lower_atk, lower_def, heal, drain   ·   anim: cast, raise

const ENEMIES := {
	# ---------- Nivel 1: Bosque de Velmora ----------
	"bandido": {
		"name": "Bandido", "type": "humano", "hp": 22, "atk": 5, "def": 1, "xp": 35, "score": 100, "coins": 5,
		"model": {"file": "Rogue", "height": 1.6, "hide": ["1H_Crossbow", "2H_Crossbow", "Throwable"],
			"hue": 0.02, "sat": 0.55, "light": 0.62},
		"moves": [
			{"name": "Tajo", "power": 4, "weight": 3},
			{"name": "Patada sucia", "power": 2, "weight": 2, "effect": "lower_def"},
		],
	},
	"saqueador": {
		"name": "Saqueador", "type": "humano", "hp": 30, "atk": 6, "def": 2, "xp": 50, "score": 150, "coins": 7,
		"model": {"file": "Barbarian", "height": 1.7, "hide": ["2H_Axe", "Mug", "1H_Axe_Offhand"],
			"hue": -0.03, "sat": 0.5, "light": 0.58},
		"moves": [
			{"name": "Hachazo", "power": 5, "weight": 3},
			{"name": "Grito de guerra", "power": 0, "weight": 1, "effect": "raise_atk"},
		],
	},
	"caballero": {
		"name": "Caballero Caído", "type": "humano", "hp": 60, "atk": 7, "def": 3, "xp": 160, "score": 1000, "coins": 15,
		"boss": true,
		"model": {"file": "Knight", "height": 2.35,
			"hide": ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "2H_Sword"],
			"hue": 0.0, "sat": 0.18, "light": 0.48, "tint": Color("#5a1010"), "tint_amount": 0.25},
		"moves": [
			{"name": "Estocada", "power": 5, "weight": 3},
			{"name": "Embestida con escudo", "power": 8, "weight": 1},
			{"name": "Juramento roto", "power": 0, "weight": 1, "effect": "raise_atk"},
		],
	},
}

const TYPE_LABEL := {"humano": "Humano", "nomuerto": "No-muerto", "arcano": "Arcano"}

const HUNTER_MODEL := {
	"file": "Rogue_Hooded", "height": 1.65, "sword": true,
	"hide": ["1H_Crossbow", "2H_Crossbow", "Throwable", "Knife_Offhand"],
}
## Colores del cazador según la vestimenta equipada.
const HUNTER_PALETTES := [
	{"hue": 0.0, "sat": 0.14, "light": 0.62},
	{"hue": 0.0, "sat": 0.2, "light": 0.95, "tint": Color("#8a9ab4"), "tint_amount": 0.35},
	{"hue": 0.0, "sat": 0.12, "light": 0.62, "tint": Color("#6a0a1a"), "tint_amount": 0.4},
]


static func get_enemy(kind: String) -> Dictionary:
	assert(ENEMIES.has(kind), "El enemigo no existe en el bestiario: " + kind)
	return ENEMIES[kind]


static func hunter_model(armor: int) -> Dictionary:
	var spec := HUNTER_MODEL.duplicate()
	spec.merge(HUNTER_PALETTES[armor])
	return spec
