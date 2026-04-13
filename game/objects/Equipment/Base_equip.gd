class_name Base_equip
extends Area2D
var GS = GameState

@onready var interactable: Area2D = $Interactable

@export_enum('chest', 'boots', 'head') var type: String
@export var equip_icon: Texture2D: set = _set_equip_icon  # иконка для инвентаря
@export var equip_id: String = 'test_chest'

signal equip_taken
@export var equip_tooltip: String = "test_chest1" # текст для инвентаря
@export var interact_name: String = "test_chest2"
var cost: int = 0

func _ready() -> void:
	interactable.interact = _on_interact
	var enchant_text := ""
	if cost < 1:
		interactable.interact_name = 'Take ' + enchant_text + interact_name
	else:
		interactable.interact_name = 'Take ' + enchant_text \
		+ interact_name + ' by %s coins' % ((cost - GS.cost_plus) * GS.cost_multiplier)

func _on_interact():
	var player = get_tree().get_first_node_in_group("player")
	if not player: 
		print('эквип не видит игрока')
		return
	if GS.coins < (cost - GS.cost_plus) * GS.cost_multiplier:
		return
	GS.add_coins((-cost - GS.cost_plus) * GS.cost_multiplier)
	
	var hud = get_tree().get_first_node_in_group("HUD")
	var tooltip := equip_tooltip
	
	var hud_slot
	match type:
		'chest':
			if player.chest_id:
				EquipManager.certain_spawn(player.chest_id, self.global_position)
				#player.global_position
			player.chest_id = equip_id
			hud_slot = hud.ChestSlot
		'boots':
			if player.boots_id:
				EquipManager.certain_spawn(player.boots_id, self.global_position)
				#player.global_position
			player.boots_id = equip_id
			hud_slot = hud.BootsSlot
		'head':
			if player.head_id:
				EquipManager.certain_spawn(player.head_id, self.global_position)
				#player.global_position
			player.head_id = equip_id
			hud_slot = hud.HeadSlot
	
	equip_taken.emit()
	
	hud_slot.set_icon(equip_icon)
	hud_slot.set_tooltip(tooltip)
	effect_on()
	queue_free()

func _set_equip_icon(new_icon: Texture2D):
	equip_icon = new_icon


func effect_on() -> void:
	print('empty effect on')
	pass


func effect_off() -> void:
	print('empty effect off')
	pass
