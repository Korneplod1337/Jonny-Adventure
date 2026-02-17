extends StaticBody2D
var cost := 0
var tier :Array[int] = [1]
var pool := 'shop'

func _ready() -> void:
	ItemManager.spawn(pool, tier, self.global_position + Vector2(0, -20), cost)
