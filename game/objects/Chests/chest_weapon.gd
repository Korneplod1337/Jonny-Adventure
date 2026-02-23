extends StaticBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable: Area2D = $Interactable
var cost := 0
var equip_tier :Array = [1]
var equip_pool := 'weapon'
var coin = preload("uid://ci05xlan24oqs")

func _ready() -> void:
	interactable.interact = _on_interact

func _on_interact() -> void: 
	var player = get_tree().get_first_node_in_group('player')
	var luck = StatManager.get_stat(player, 'luck')
	if interactable.is_interactable:
		EquipManager.spawn(equip_pool, equip_tier, self.global_position + Vector2(00, -80))
		animated_sprite_2d.frame = 1
		interactable.is_interactable = false


'''Мелкий сундук- монетка или предмет

Основной- 
Большой сундук- монетка, пару монет, предмет, мелкий на эквип

Оч редкий-
Оружейный кейс- оружие, мелкий на предмет хай тира

Трежерный кейс- эквип или предмет'''
