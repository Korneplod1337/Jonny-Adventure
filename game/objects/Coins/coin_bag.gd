extends Node2D

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var coins := randi_range(2, 5)
		GameState.add_coins(coins)
		SoundManager.play_coins(coins)
		queue_free()

func _ready() -> void:
	$AnimatedSprite2D.play()
