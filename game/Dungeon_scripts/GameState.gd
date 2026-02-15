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

# игрок
var AlchemistsGlasses := false

# мир
var cost_multiplier: float = 1.0
