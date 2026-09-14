extends Jonny
class_name Joker

const START_CARD_EQUIP := preload("res://game/objects/Equipment/Weapon/equip/CardWeapon_equip.tscn")


func _init() -> void:
	player_name = "Joker"
	base_max_hp = 3
	base_move_speed = 260.0
	base_luck = 0.4
	base_magic = 0.4
	base_damage = 25.0
	base_spread = 12.0
	base_range = 160.0
	base_fire_rate = 0.5
	hit_points_level = 1.0
	move_speed_level = 2.0
	luck_level = 1.0
	magic_level = 4.0
	damage_level = 1.0
	spread_level = 1.0
	range_level = 1.0
	fire_rate_level = 2.0


func _ready() -> void:
	hp_list = {
		"red": 0,
		"green": 4,
		"blue": 0,
		"black": 2,
	}
	super()


func _equip_start_weapon() -> void:
	var equip: BaseShot_equip = START_CARD_EQUIP.instantiate()
	equip.apply_equip(self)
