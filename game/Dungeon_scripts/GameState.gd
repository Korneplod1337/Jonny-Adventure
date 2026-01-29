extends Node

var coins: int = 0
signal coins_changed(new_value: int)

var enemy_ms_multiplayer: float = 1.0
var enemy_hp_multiplayer: float = 1.0
var enemy_dmg_multiplayer: float = 1.0

func add_coins(amount: int) -> void:
	coins += amount
	emit_signal("coins_changed", coins)

func obnulenie() -> void:
	coins = 0
	"Всё, что обнуляется между играми сюда по идее"
