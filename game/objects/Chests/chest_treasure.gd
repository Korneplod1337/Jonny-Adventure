extends StaticBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable: Area2D = $Interactable
var cost := 0
var tier :Array = [0]
var pool := 'shop'

func _ready() -> void:
	interactable.interact = _on_interact

func _on_interact() -> void:
	if interactable.is_interactable:
		animated_sprite_2d.frame = 1
		ItemManager.spawn(pool, tier, self.global_position + Vector2(00, -80), cost)
		interactable.is_interactable = false
	
