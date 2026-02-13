extends StaticBody2D

func _ready() -> void:
	ItemManager.spawn('shop', [1], self.global_position + Vector2(0, -20), 0)
