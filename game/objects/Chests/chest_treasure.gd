extends StaticBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable: Area2D = $Interactable
var cost := 0
var item_tier :Array = [1] # add check floor
var item_pool := 'treasure'
var equip_tier :Array = [1] #add check floor
var equip_pool := 'armory'


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
	if random >= 75:
		EquipManager.spawn(equip_pool, equip_tier, self.global_position + offset)
	else:
		ItemManager.spawn(item_pool, item_tier, self.global_position + offset, cost)
