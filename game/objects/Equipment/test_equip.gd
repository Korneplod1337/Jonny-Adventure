extends Area2D

@export var item_id: String
@export var slot_type: int = EquipManager.SlotType.WEAPON
@export var icon: Texture2D
@export var tooltip: String = ""
@export var effect_scene: PackedScene   # shot.tscn и т.п.
@export var drop_scene: PackedScene     # что падает при замене

func _ready() -> void:
	$Interactable.interact = _on_interact

func _on_interact() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		print('net igroka equip')
		return

	var equip = player.get_node("PlayerEquip")
	equip.equip_item(self)
	queue_free() # убираем предмет с пола
