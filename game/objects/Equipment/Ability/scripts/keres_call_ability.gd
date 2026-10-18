## Keres Call — призывает духа: волны снарядов во все стороны (15°). CD: этаж.
## Урон пула 25→240 от магии; урон волны 25→40; 1 волна/с; при 0 — исчезает вместо выстрела.
class_name KeresCallAbility
extends BaseAbility

const SPIRIT_SCENE := preload("res://game/objects/Equipment/Ability/effects/KeresSpirit.tscn")
const SPAWN_OFFSET := Vector2(0, -24)


func _init() -> void:
	ability_id = "KeresCall"
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
