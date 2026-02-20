extends Node2D

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.add_coins(randi_range(2,5))
		queue_free()
	
func _ready() -> void:
	$AnimatedSprite2D.play()
