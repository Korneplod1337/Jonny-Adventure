extends StaticBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable: Area2D = $Interactable
var cost := 0
var tier :Array = [1]
var pool := 'shop'
var equip_tier :Array = [1]
var equip_pool := 'treasure'
var coin = preload("uid://ci05xlan24oqs")
var coinBag = preload("uid://bt02g3ohw7ksf")

func _ready() -> void:
	interactable.interact = _on_interact

func _on_interact() -> void: 
	var player = get_tree().get_first_node_in_group('player')
	var luck = StatManager.get_stat(player, 'luck')
	if interactable.is_interactable:
		var random = randi_range(1, 100)
		if random >= 95:
			EquipManager.spawn(equip_pool, equip_tier, self.global_position + Vector2(00, -80))
		if random >= 75:
			ItemManager.spawn(pool, tier, self.global_position + Vector2(00, -80), cost)
		elif random >= 50:
			spawner(coinBag)
		else:
			spawner(coin)
		animated_sprite_2d.frame = 1
		interactable.is_interactable = false
'''5 20 25 50'''

func spawner(ini) -> void:
	var inst = ini.instantiate()
	inst.position = self.global_position + Vector2(00, -80)
	get_tree().current_scene.add_child(inst)
