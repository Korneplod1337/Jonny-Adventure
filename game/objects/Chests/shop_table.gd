extends StaticBody2D
var cost := 0
var tier :Array = [0]
var pool := 'shop'
var room := 'shop'

func _ready() -> void:
	match room:
		'shop':
			ItemManager.spawn(pool, tier, self.global_position + Vector2(0, -20), cost)
		'armory':
			EquipManager.spawn(pool, tier, self.global_position + Vector2(0, -20), cost)
