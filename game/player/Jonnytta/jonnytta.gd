extends Jonny
class_name Jonnytta

const START_SWORD_EQUIP := preload("res://game/objects/Equipment/Weapon/equip/Sword_equip.tscn")

## Базы нужно ставить в _init: @onready-статы (spread, damage, …)
## считаются ДО _ready() и иначе остаются с дефолтами Jonny.
func _init() -> void:
	player_name = "Jonnytta"
	base_max_hp = 5
	base_move_speed = 250.0
	base_luck = 0.2
	base_magic = 0.0
	base_damage = 32.0
	base_spread = 42.0
	base_range = 160.0
	base_fire_rate = 0.5
	spread_level = 3.0
	range_level = 2.0


func _ready() -> void:
	# hp_list — @onready у Jonny, поэтому сброс щитов только здесь (после @onready, до super).
	hp_list = {
		"red": max(0, StatManager.get_stat(self, "hp")),
		"green": 0,
		"blue": 0,
		"black": 0,
	}
	super()


func _equip_start_weapon() -> void:
	var equip: BaseShot_equip = START_SWORD_EQUIP.instantiate()
	equip.apply_equip(self)
