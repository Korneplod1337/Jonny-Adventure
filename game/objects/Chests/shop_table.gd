extends StaticBody2D
const COIN_SCENE := preload("res://game/objects/coins/Coin.tscn")
var cost := 0
var tier :Array = [0]
var pool := 'shop'
var room := 'shop'

func _ready() -> void:
	if GameState.has_level_buf("Midas"):
		_replace_with_coin()
		return
	match room:
		'shop':
			ItemManager.spawn(pool, tier, self.global_position + Vector2(0, -20), cost)
		'armory':
			if tier == [0]:
				ItemManager.spawn(pool, tier, self.global_position + Vector2(0, -20), cost)
			else:
				EquipManager.spawn(pool, tier, self.global_position + Vector2(0, -20), cost)


func _replace_with_coin() -> void:
	var parent := get_parent()
	var coin := COIN_SCENE.instantiate()
	if parent:
		coin.position = position + Vector2(0, -20)
		parent.call_deferred("add_child", coin)
	else:
		coin.global_position = global_position + Vector2(0, -20)
		get_tree().current_scene.call_deferred("add_child", coin)
	queue_free()
