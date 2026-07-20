extends StaticBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable: Area2D = $Interactable
var cost := 0
var tier :Array = [1]
var pool := 'chest'
var coin = preload("uid://ci05xlan24oqs")

func _ready() -> void:
	interactable.interact = _on_interact

func _on_interact() -> void: 
	var player = get_tree().get_first_node_in_group('player')
	var luck = StatManager.get_stat(player, 'luck')
	if interactable.is_interactable:
		_spawn_loot(Vector2(0, -80))
		if GameState.extra_chest_loot_chance > 0.0 and randf() < GameState.extra_chest_loot_chance:
			_spawn_loot(Vector2(40, -80))
		animated_sprite_2d.frame = 1
		interactable.is_interactable = false

func _spawn_loot(offset: Vector2) -> void:
	var random = randi_range(1, 100)
	if random >= 70:
		ItemManager.spawn(pool, tier, self.global_position + offset, cost)
	else:
		var inst = coin.instantiate()
		inst.position = self.global_position + offset
		get_tree().current_scene.add_child(inst)
