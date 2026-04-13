extends Node

var coins: int = 0
signal coins_changed(new_value: int)

func add_coins(amount: int) -> void:
	coins += amount
	emit_signal("coins_changed", coins)

func obnulenie() -> void:
	coins = 0
	"Всё, что обнуляется между играми сюда по идее"

# враги
var enemy_ms_multiplier: float = 1.0
var enemy_hp_multiplier: float = 1.0
var enemy_dmg_multiplier: float = 1.0
var enemy_cooldown_multiplier: float = 1.0

# игрок
func  equip_update(equip: String) -> void:
	match equip:
		"test_chest":
			test_chest = not test_chest
			if test_chest:
				damage_multiplayer *= 2
			else:
				damage_multiplayer /= 2
		_:
			print('equip_update fail!')


var damage_multiplayer := 1.0
var AlchemistsGlasses := false #больше инфы
var test_chest := false

# мир
var cost_multiplier := 1.0
var cost_plus := 0.0


#уровень
@onready var level_bufs :Array = [
 ["Confusing space", 	false, Color.LAWN_GREEN],
 ["Invasion", 			false, Color.RED],
 ["Deathly", 			false, Color.RED],
 ["Toxic", 				false, Color.YELLOW],
 ["Ice", 				false, Color.LAWN_GREEN]
]

func random_level_bufs() -> void:
	if randi() % 100 > 50:
		level_bufs[1][1] = true
		#level_bufs[randi() % len(level_bufs)][1] = true

func _clear_level_bufs() -> void:
	for i in level_bufs:
		i[1] = false

func get_level_bufs() -> Array:
	for i in level_bufs:
		if i[1] == true:
			return [i[0], i[2]]
	return ['Nothing', 'Nothing']

#босс
