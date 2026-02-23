extends StaticBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable: Area2D = $Interactable
var cost := 0
var tier :Array = [1]
var pool := 'shop'
var coin = preload("uid://ci05xlan24oqs")

func _ready() -> void:
	interactable.interact = _on_interact

func _on_interact() -> void: 
	var player = get_tree().get_first_node_in_group('player')
	var luck = StatManager.get_stat(player, 'luck')
	if interactable.is_interactable:
		var random = randi_range(1, 100)
		if random >= 70:
			ItemManager.spawn(pool, tier, self.global_position + Vector2(00, -80), cost)
		else:
			var inst = coin.instantiate()
			inst.position = self.global_position + Vector2(00, -80)
			get_tree().current_scene.add_child(inst)
		animated_sprite_2d.frame = 1
		interactable.is_interactable = false
