extends Item

@export var hp_delta: int = 0
@export var speed_delta: int = 0
@export var luck_delta: int = 0
@export var magic_delta: int = 0
@export var damage_delta: int = 0
@export var accuracy_delta: int = 0
@export var range_delta: int = 0
@export var fire_rate_delta: int = 0

func apply_item_effect() -> void:
	player.hp_bonus += hp_delta
	player.speed_bonus += speed_delta
	player.luck_bonus += luck_delta
	player.magic_bonus += magic_delta
	player.damage_bonus += damage_delta
	player.accuracy_bonus += accuracy_delta
	player.range_bonus += range_delta
	player.fire_rate_bonus += fire_rate_delta

	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player.luck = StatManager.get_stat(player, "luck")
	player.magic = StatManager.get_stat(player, "magic")
	player.damage = StatManager.get_stat(player, "damage")
	player.spread = StatManager.get_stat(player, "spread")
	player.atk_range = StatManager.get_stat(player, "range")
	player.fire_rate = StatManager.get_stat(player, "fire_rate")
	player._emit_stats_changed()
