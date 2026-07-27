extends Area2D
class_name BaseShot_equip

@onready var interactable: Area2D = $Interactable
@export var equip_icon: Texture2D: set = _set_equip_icon  # иконка для инвентаря
@export var equip_id: String = 'Jonny_shot'
@export var projectile: PackedScene
signal equip_taken
@export var equip_tooltip: String = "Jonny weapon" # текст для инвентаря
@export var interact_name: String = "Jonny weapon"
var cost: int = 0
var type = 'weapon'

@export var enchantment: EnchantmentResource

@onready var weapon_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var enchant_shader: AnimatedSprite2D = $AnimatedSprite2D/enchant_shader

func _ready() -> void:
	interactable.interact = _on_interact
	_setup_enchant_visual()
	
	var enchant_text := ""
	if enchantment:
		enchant_text = " [" + enchantment.get_title() + "]"
		#enchant_text = enchantment.get_name_text()
	if cost < 1:
		interactable.interact_name = 'Take ' + enchant_text + interact_name
	else:
		interactable.interact_name = 'Take ' + enchant_text \
		+ interact_name + ' by %s coins' %cost


func apply_equip(player) -> void:
	player.shot_scene = projectile
	player.shot_id = equip_id
	player.shot_enchantment = enchantment.duplicate(true) if enchantment else null

	var hud = player.get_tree().get_first_node_in_group("HUD")
	if not hud:
		return
	var tooltip := equip_tooltip
	if enchantment:
		tooltip += enchantment.get_tooltip_text()
	hud.WeaponSlot.set_icon(equip_icon)
	hud.WeaponSlot.set_tooltip(tooltip)

func _on_interact():
	var player = get_tree().get_first_node_in_group("player")
	if not player: 
		print('эквип не видит игрока')
		return
	if GameState.coins < cost:
		return
	GameState.add_coins(-cost)
	
	if player.shot_scene:
		EquipManager.certain_spawn(player.shot_id, self.global_position, player.shot_enchantment) 
		#player.global_position 
	
	apply_equip(player)
	equip_taken.emit()
	# hud.add_equip(equip_icon, equip_tooltip)
	queue_free()

func _set_equip_icon(new_icon: Texture2D):
	equip_icon = new_icon


func _setup_enchant_visual() -> void:
	if not weapon_sprite:
		return
	weapon_sprite.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	if not enchant_shader:
		return
	if not enchantment:
		enchant_shader.visible = false
		return
	var anim_name := enchantment.get_visual_animation()
	if not enchant_shader.sprite_frames.has_animation(anim_name):
		enchant_shader.visible = false
		return
	enchant_shader.visible = true
	enchant_shader.play(anim_name)
