extends Node

const SAVE_PATH := "user://game_state.cfg"

var coins: int = 0
signal coins_changed(new_value: int)
signal room_cleared

## Монеты в банке — переносятся между забегами.
var bank_coins: int = 0
signal bank_coins_changed(new_value: int)


func _ready() -> void:
	load_persistent_state()

func add_coins(amount: int) -> void:
	coins += amount
	emit_signal("coins_changed", coins)


func add_bank_coins(amount: int) -> void:
	bank_coins = maxi(0, bank_coins + amount)
	bank_coins_changed.emit(bank_coins)
	save_persistent_state()


func withdraw_bank_coins(amount: int) -> bool:
	if bank_coins < amount:
		return false
	bank_coins -= amount
	bank_coins_changed.emit(bank_coins)
	save_persistent_state()
	return true


func load_persistent_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	bank_coins = int(config.get_value("bank", "coins", 0))


func save_persistent_state() -> void:
	var config := ConfigFile.new()
	config.set_value("bank", "coins", bank_coins)
	config.save(SAVE_PATH)


func notify_room_cleared() -> void:
	room_cleared.emit()

# мир
var cost_multiplier := 1.0
var cost_plus := 0.0
var animated_world_speed := 1.0

signal alchemists_glasses_changed

var _alchemists_glasses := false
var AlchemistsGlasses: bool:
	get:
		return _alchemists_glasses
	set(value):
		_alchemists_glasses = value
		alchemists_glasses_changed.emit()
var Surestrike := false # убирает разброс выстрела, не меняя стат точности
var SpreadShot := false # через 50 дистанции снаряд рассыпается на 6 уменьшенных
var LuckyHead := false # за этаж: +1 luck_level и enemy_hp_multiplier *= 0.97
var extra_chest_loot_chance := 0.0 # шанс доп. лута из сундуков (цветок папоротника и т.п.)
var mimic_chest_chance := 0.0 # шанс, что clear-reward small/big сундук станет мимиком


#уровень
@onready var level_bufs :Array = [
 ["Invasion", 			false, Color.RED],
 ["Deathly", 			false, Color.RED],
 ["Barren", 				false, Color.RED],
 ["Toxic", 				false, Color.YELLOW],
 ["Shopless", 			false, Color.YELLOW],
 ["Confusing space", 	false, Color.LAWN_GREEN],
 ["Ice", 				false, Color.LAWN_GREEN],
 ["Bountiful", 			false, Color.LAWN_GREEN],
 ["Explosive", 			false, Color.LAWN_GREEN],
 ["Midas", 				false, Color.LAWN_GREEN],
]

func random_level_bufs(current_floor) -> void:
	#level_bufs[9][1] = true
	
	if current_floor >= 2:
		if randi() % 100 > 70:
			pass
			##level_bufs[randi() % len(level_bufs)][1] = true

func _clear_level_bufs() -> void:
	for i in level_bufs:
		i[1] = false

func get_level_bufs() -> Array:
	for i in level_bufs:
		if i[1] == true:
			return [i[0], i[2]]
	return ['Nothing', 'Nothing']

func has_level_buf(buf_name: String) -> bool:
	return get_level_bufs()[0] == buf_name


# враги
var enemy_ms_multiplier: float = 1.0
var enemy_hp_multiplier: float = 1.0
var enemy_dmg_multiplier: float = 1.0
var enemy_cooldown_multiplier: float = 1.0
## Iron Maiden: шанс взрыва врага при смерти (стакается)
var iron_maiden_chance: float = 0.0
#босс
## Игрушечный замок и т.п. — множители поверх Boss_*_buff
var boss_hp_multiplier: float = 1.0
var boss_size_multiplier: float = 1.0

@onready var boss_bufs :Array = [
 ["Emaciated", 		false, Color.LAWN_GREEN],
 ["Inhibited", 		false, Color.LAWN_GREEN],
 ["Slothful", 		false, Color.LAWN_GREEN],
 ["Turtleshell", 	false, Color.YELLOW],
 ["Dwarf", 			false, Color.YELLOW],
 ["Frenetic", 		false, Color.YELLOW],
 ["Siamese", 		false, Color.YELLOW],
 ["Thunderer", 		false, Color.YELLOW],
 ["Tempest", 		false, Color.RED],
 ["Twins", 			false, Color.RED],
 ["Vengeful", 		false, Color.RED],
 ["Dreadnought", 	false, Color.RED],
 ["Reaper", 			false, Color.RED],
]

func random_boss_bufs(current_floor) -> void:
	#boss_bufs[12][1] = true
	if current_floor > 1:
		if randi() % 100 > 70:
			pass
			#boss_bufs[randi() % len(boss_bufs)][1] = true

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
	StatsManager.reset_run_stats()
	DamageDealer.clear_modifiers()
	AlchemistsGlasses = false
	Surestrike = false
	SpreadShot = false
	LuckyHead = false
	extra_chest_loot_chance = 0.0
	mimic_chest_chance = 0.0
	enemy_ms_multiplier = 1.0
	enemy_hp_multiplier = 1.0
	enemy_dmg_multiplier = 1.0
	enemy_cooldown_multiplier = 1.0
	iron_maiden_chance = 0.0
	boss_hp_multiplier = 1.0
	boss_size_multiplier = 1.0
	cost_multiplier = 1.0
	cost_plus = 0.0
	animated_world_speed = 1.0
	_clear_boss_bufs()
