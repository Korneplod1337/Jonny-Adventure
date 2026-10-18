## Maria Call — призывает духа: стрельба по кругу по часовой с верха. CD: этаж.
## Магия 0→4: урон 100→75, интервал 0.5→0.1 с, оборот 4→2 с, жизнь 4→8 с.
class_name MariaCallAbility
extends BaseAbility

const SPIRIT_SCENE := preload("res://game/objects/Equipment/Ability/effects/MariaSpirit.tscn")
const SPAWN_OFFSET := Vector2(0, -24)


func _init() -> void:
	ability_id = "MariaCall"
	cooldown_type = CooldownType.FLOOR


func activate() -> bool:
	var parent: Node = player.get_tree().current_scene
	if parent == null:
		parent = player.get_parent()
	var spirit := SPIRIT_SCENE.instantiate()
	spirit.setup(get_magic())
	parent.add_child(spirit)
	spirit.global_position = player.global_position + SPAWN_OFFSET
	return true
