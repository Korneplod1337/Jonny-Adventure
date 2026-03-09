extends Area2D
@onready var interactable: Area2D = $Interactable
@export var equip_icon: Texture2D: set = _set_equip_icon  # иконка для инвентаря
@export var equip_id: String = 'Jonny_shot'
@export var projectile: PackedScene
signal equip_taken
var equip_tooltip: String = "Test weapon" # текст для инвентаря
var cost: int = 0

@export var enchantment: EnchantmentResource

func _ready() -> void:
	interactable.interact = _on_interact
	
	var enchant_text := ""
	if enchantment:
		enchant_text = " [" + enchantment.get_title() + "]"
		#enchant_text = enchantment.get_name_text()
	
	if cost < 1:
		interactable.interact_name = 'Take ' + enchant_text + 'test weapon'
	else:
		interactable.interact_name = 'Take ' + enchant_text + 'test weapon by %s coins' %cost
		


func _on_interact():
	var player = get_tree().get_first_node_in_group("player")
	if not player: 
		print('эквип не видит игрока')
		return
	if GameState.coins < cost:
		return

	GameState.add_coins(-cost)
	# Оружие менятся у игрока, нужно бы переместить в менеджер
	if player.shot_scene:
		EquipManager.certain_spawn(player.shot_id, self.global_position, player.shot_enchantment) #player.global_position
		
		#Эффект
		# StatManager.upgrade_stat(player, 'hp', 1) 
	
	player.shot_scene = projectile
	player.shot_id = equip_id
	player.shot_enchantment = enchantment.duplicate(true) if enchantment else null
	
	
	equip_taken.emit() # сигнал
	
	var hud = get_tree().get_first_node_in_group("HUD")
	hud.WeaponSlot.set_icon(equip_icon)
	var tooltip := equip_tooltip
	if enchantment:
		tooltip += enchantment.get_tooltip_text()
	hud.WeaponSlot.set_tooltip(tooltip)
	
	# hud.add_equip(equip_icon, equip_tooltip)
	queue_free()

func _set_equip_icon(new_icon: Texture2D):
	equip_icon = new_icon
