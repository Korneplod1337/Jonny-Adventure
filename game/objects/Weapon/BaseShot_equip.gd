extends Area2D
@onready var interactable: Area2D = $Interactable
@export var equip_icon: Texture2D: set = _set_equip_icon  # иконка для инвентаря
@export var equip_tooltip: String = "Test weapon" # текст для инвентаря
@export var equip_id: String = 'Jonny_shot'
@export var projectile: PackedScene

func _ready() -> void:
	interactable.interact = _on_interact
	
func _on_interact():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print('эквип не видит игрока')
	
	player.shot_scene = projectile
	
	#Эффект
	# StatManager.upgrade_stat(player, 'hp', 1) 
	
	
	var hud = get_tree().get_first_node_in_group("HUD")
	# hud.add_equip(equip_icon, equip_tooltip)
	queue_free()

func _set_equip_icon(new_icon: Texture2D):
	equip_icon = new_icon
