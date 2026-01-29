extends Node2D

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.add_coins(1)
		queue_free()
	
func _ready() -> void:
	$AnimatedSprite2D.play()
