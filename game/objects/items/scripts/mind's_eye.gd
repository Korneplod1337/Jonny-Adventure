extends Item

func apply_item_effect() -> void:
	var cam: Camera2D = player.get_node("Camera2D")
	cam.zoom /= Vector2.ONE * (1.0 + effect_power)
