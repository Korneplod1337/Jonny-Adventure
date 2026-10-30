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
var _base_cost: int = 0

func _enter_tree() -> void:
	# Survives subclasses that override _ready without super().
	call_deferred("_start_idle_float")


func _ready() -> void:
	interactable.interact = _on_interact
	_base_cost = cost
	refresh_price_label()
	if not GameState.prices_changed.is_connected(refresh_price_label):
		GameState.prices_changed.connect(refresh_price_label)


func _exit_tree() -> void:
	if GameState.prices_changed.is_connected(refresh_price_label):
		GameState.prices_changed.disconnect(refresh_price_label)


func refresh_price_label() -> void:
	var enchant_text := ""
	if _base_cost < 1:
		interactable.interact_name = 'Take ' + enchant_text + interact_name
	else:
		var shown: int = int(round((_base_cost + GS.cost_plus) * GS.cost_multiplier))
		interactable.interact_name = 'Take ' + enchant_text \
			+ interact_name + ' by %s coins' % shown


func _final_price() -> int:
	return int(round((_base_cost + GS.cost_plus) * GS.cost_multiplier))


func _start_idle_float() -> void:
	PickupIdleFloat.begin(self)

func _on_interact():
	var player = get_player()
	if not player: 
		print('эквип не видит игрока')
		return
	if type == "head" and (GameState.SawMask or player.get("saw_mask_active")):
		return
	var price := _final_price()
	if GS.coins < price:
		return
	GS.add_coins(-price)
	
	var hud = get_tree().get_first_node_in_group("HUD")
	var tooltip := equip_tooltip
	
	var hud_slot
	match type:
		'chest':
			if player.chest_id:
				EquipManager.certain_spawn(player.chest_id, self.global_position)
				#player.global_position
			player.chest_id = equip_id
			player.update_equipment_visuals()
			hud_slot = hud.ChestSlot
		'boots':
			if player.boots_id:
				EquipManager.certain_spawn(player.boots_id, self.global_position)
				#player.global_position
			player.boots_id = equip_id
			player.update_equipment_visuals()
			hud_slot = hud.BootsSlot
		'head':
			if player.head_id:
				EquipManager.certain_spawn(player.head_id, self.global_position)
				#player.global_position
			player.head_id = equip_id
			player.update_equipment_visuals()
			hud_slot = hud.HeadSlot
	
	equip_taken.emit()
	EquipManager.mark_picked(equip_id)
	
	hud_slot.set_icon(equip_icon)
	hud_slot.set_tooltip(tooltip)
	effect_on()
	queue_free()

func _set_equip_icon(new_icon: Texture2D):
	equip_icon = new_icon

func get_player() -> Node:
	var tree: SceneTree
	if is_inside_tree():
		tree = get_tree()
	else:
		tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("player")

func effect_on() -> void:
	print('empty effect on')
	

func effect_off() -> void:
	print('empty effect off')
	
