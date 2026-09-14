extends Jonny
class_name Jovita

const START_SCATTERHAND_EQUIP := preload("res://game/objects/Equipment/Weapon/equip/Scatterhand_equip.tscn")


func _init() -> void:
	player_name = "Jovita"
	base_max_hp = 2
	base_move_speed = 300.0
	base_luck = 0.4
	base_magic = 0.0
	base_damage = 25.0
	base_spread = 14.0
	base_range = 140.0
	base_fire_rate = 0.5
	hit_points_level = 2.0
	move_speed_level = 5.0
	luck_level = 4.0
	magic_level = 1.0
	damage_level = 1.0
	spread_level = 1.0
	range_level = 1.0
	fire_rate_level = 1.0


func _ready() -> void:
	hp_list = {
		"red": 1,
		"green": 2,
		"blue": 0,
		"black": 1,
	}
	super()


func _equip_start_weapon() -> void:
	var equip: BaseShot_equip = START_SCATTERHAND_EQUIP.instantiate()
	equip.apply_equip(self)
