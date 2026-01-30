extends Node2D

@onready var interactable: Area2D = $Interactable
@onready var Shrn_animation: AnimatedSprite2D = $AnimatedSprite2D
enum ShrineType {
	hp, move_speed, luck, magic,
	damage, spread, range, fire_rate
}

@export var shrine_type: int = -1
@export var flip := false
var selected_type: ShrineType

func _ready() -> void:
	Shrn_animation.flip_h = flip
	interactable.interact = _on_interact
	if shrine_type == -1: 
		selected_type = ShrineType.values()[randi() % ShrineType.size()] 
	else: selected_type = ShrineType.values()[shrine_type]
	Shrn_animation.animation = ShrineType.keys()[selected_type]
	Shrn_animation.frame = 0
	print("Шрайн: ", ShrineType.keys()[selected_type])

func _on_interact():
	var player = get_tree().get_first_node_in_group("player")
	if GameState.coins > 0:
		Shrn_animation.animation = ShrineType.keys()[selected_type] + '_active'
		Shrn_animation.play()
		interactable.is_interactable = false
		GameState.add_coins(-1)
		var stat_name: String
		match selected_type:
			ShrineType.hp:          stat_name = "hp"
			ShrineType.move_speed:  stat_name = "move_speed"
			ShrineType.luck:        stat_name = "luck"
			ShrineType.magic:       stat_name = "magic"
			ShrineType.damage:      stat_name = "damage"
			ShrineType.spread:      stat_name = "spread"
			ShrineType.range:       stat_name = "range"
			ShrineType.fire_rate:   stat_name = "fire_rate"
		
		StatManager.upgrade_stat(player, stat_name, 1)
