extends Jonny
class_name Joab

const START_SPECIAL_FLASK_EQUIP := preload("res://game/objects/Equipment/Weapon/equip/Special_weapon_equip.tscn")


func _init() -> void:
	player_name = "Joab"
	base_max_hp = 6
	base_move_speed = 280.0
	base_luck = 0.0
	base_magic = 0.4
	base_damage = 20.0
	base_spread = 10.0
	base_range = 130.0
	base_fire_rate = 0.4
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
		"red": 4,
		"green": 0,
		"blue": 2,
		"black": 0,
	}
	super()


func _equip_start_weapon() -> void:
	var equip: BaseShot_equip = START_SPECIAL_FLASK_EQUIP.instantiate()
	equip.apply_equip(self)


func _heart_type_to_int(t: String) -> int:
	match t:
		"red":
			return 5  # special (тёмные сердца в HUD)
		"green":
			return 2
		"blue":
			return 3
		"black":
			return 4
		_:
			return 0


## Красные зелья наносят урон; вызывается из Poison Red / potion_red_big.
func apply_red_potion(amount: int = 1) -> void:
	take_damage(amount, 0, 0)


## Чёрные зелья хилят (вместо магического урона).
func apply_black_potion(amount: int = 1) -> void:
	heal(amount, 0, 0, 0)
