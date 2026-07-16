extends Node

var coins: int = 0
signal coins_changed(new_value: int)

func add_coins(amount: int) -> void:
	coins += amount
	emit_signal("coins_changed", coins)

# мир
var cost_multiplier := 1.0
var cost_plus := 0.0
var animated_world_speed := 1

signal alchemists_glasses_changed

var _alchemists_glasses := false
var AlchemistsGlasses: bool:
	get:
		return _alchemists_glasses
	set(value):
		_alchemists_glasses = value
		alchemists_glasses_changed.emit()
var Surestrike := false # убирает разброс выстрела, не меняя стат точности
var LuckyHead := false # за этаж: +1 luck_level и enemy_hp_multiplier *= 0.97


#уровень
@onready var level_bufs :Array = [
 ["Invasion", 			false, Color.RED],
 ["Deathly", 			false, Color.RED],
 ["Toxic", 				false, Color.YELLOW],
 ["Ice", 				false, Color.LAWN_GREEN],
 ["Confusing space", 	false, Color.LAWN_GREEN],
]

func random_level_bufs() -> void:
	if randi() % 100 > 70:
		pass
		#level_bufs[0][1] = true
		##level_bufs[randi() % len(level_bufs)][1] = true

func _clear_level_bufs() -> void:
	for i in level_bufs:
		i[1] = false

func get_level_bufs() -> Array:
	for i in level_bufs:
		if i[1] == true:
			return [i[0], i[2]]
	return ['Nothing', 'Nothing']


# враги
var enemy_ms_multiplier: float = 1.0
var enemy_hp_multiplier: float = 1.0
var enemy_dmg_multiplier: float = 1.0
var enemy_cooldown_multiplier: float = 1.0

#босс
@onready var boss_bufs :Array = [
 ["Dreadnought", 	false, Color.RED],
 ["Twins", 			false, Color.RED],
 ["Reaper", 			false, Color.RED],
 ["Turtleshell", 	false, Color.YELLOW],
 ["Dwarf", 			false, Color.YELLOW],
 ["Siamese", 		false, Color.YELLOW],
 ["Frenetic", 		false, Color.YELLOW],
 ["Emaciated", 		false, Color.LAWN_GREEN],
 ["Inhibited", 		false, Color.LAWN_GREEN],
 ["Slothful", 		false, Color.LAWN_GREEN],
]

func random_boss_bufs() -> void:
	boss_bufs[6][1] = true
	if randi() % 100 > 70:
		pass
	#	boss_bufs[randi() % len(boss_bufs)][1] = true

func _clear_boss_bufs() -> void:
	for i in boss_bufs:
		i[1] = false

func get_boss_bufs() -> Array:
	for i in boss_bufs:
		if i[1] == true:
			return [i[0], i[2]]
	return ['Nothing', 'Nothing']

func is_red_boss_buf() -> bool:
	var buf := get_boss_bufs()
	return buf[0] != "Nothing" and buf[1] == Color.RED


#обнуление
func obnulenie() -> void:
	coins = 0
	"Всё, что обнуляется между играми сюда по идее"
	ItemManager.reset_run()
	DamageDealer.clear_modifiers()
	AlchemistsGlasses = false
	Surestrike = false
	LuckyHead = false
	enemy_ms_multiplier = 1.0
	enemy_hp_multiplier = 1.0
	enemy_dmg_multiplier = 1.0
	enemy_cooldown_multiplier = 1.0
	cost_multiplier = 1.0
	cost_plus = 0.0
	_clear_boss_bufs()
