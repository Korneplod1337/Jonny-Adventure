extends Jonny
class_name Joaquin

const START_BASE_GUN_EQUIP := preload("res://game/objects/Equipment/Weapon/equip/Pistol_equip.tscn")


func _init() -> void:
	player_name = "Joaquin"
	base_max_hp = 0
	base_move_speed = 253.0
	base_luck = 0.3
	base_magic = 0.3
	base_damage = 25.3
	base_spread = 14.3
	base_range = 153.0
	base_fire_rate = 0.53
	hit_points_level = 1.0
	move_speed_level = 1.0
	luck_level = 1.0
	magic_level = 1.0
	damage_level = 1.0
	spread_level = 1.0
	range_level = 1.0
	fire_rate_level = 1.0


func _ready() -> void:
	hp_list = {
		"red": 0,
		"green": 0,
		"blue": 0,
		"black": 0,
	}
	super()


func _equip_start_weapon() -> void:
	var equip: BaseShot_equip = START_BASE_GUN_EQUIP.instantiate()
	equip.apply_equip(self)


func heal(_red: int = 0, _green: int = 0, _blue: int = 0, _black: int = 0) -> void:
	# Не может получать HP или армор.
	return


func _emit_stats_changed() -> void:
	# Не даём накапливать пустые слоты / live HP.
	max_hp = 0
	hp_list["red"] = 0
	hp_list["green"] = 0
	hp_list["blue"] = 0
	hp_list["black"] = 0
	super._emit_stats_changed()
