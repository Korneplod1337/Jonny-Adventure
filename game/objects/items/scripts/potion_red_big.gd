extends Item

func apply_item_effect() -> void:
	player.heal(1 * int(effect_power))

func _ready() -> void:
	cost += 1
	super()
