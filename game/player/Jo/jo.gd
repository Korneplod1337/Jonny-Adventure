extends Jonny
class_name Jo

const START_SNIPER_EQUIP := preload("res://game/objects/Equipment/Weapon/equip/Sniper_equip.tscn")

## Сколько «пустых» слотов уже превращено в чёрные щиты.
var _absorbed_empty_hp: int = 0


func _init() -> void:
	player_name = "Jo"
	base_max_hp = 0
	base_move_speed = 250.0
	base_luck = 0.2
	base_magic = 0.2
	base_damage = 32.0
	base_spread = 0.0
	base_range = 180.0
	base_fire_rate = 0.5
	hit_points_level = 1.0
	move_speed_level = 1.0
	luck_level = 1.0
	magic_level = 2.0
	damage_level = 1.0
	spread_level = 1.0
	range_level = 5.0
	fire_rate_level = 1.0


func _ready() -> void:
	hp_list = {
		"red": 0,
		"green": 0,
		"blue": 0,
		"black": 6,
	}
	_absorbed_empty_hp = 0
	super()
	_convert_empty_hearts_to_shields()


func _equip_start_weapon() -> void:
	var equip: BaseShot_equip = START_SNIPER_EQUIP.instantiate()
	equip.apply_equip(self)


func take_damage(phy_damage: int = 0, mag_damage: int = 0, clr_damage: int = 0, attacker: Node = null) -> void:
	var total := phy_damage + mag_damage + clr_damage
	super.take_damage(total, 0, 0, attacker)


func heal(red: int = 0, green: int = 0, blue: int = 0, black: int = 0) -> void:
	# Любые сердца/щиты → только чёрные щиты.
	var to_black := red + green + blue + black
	if to_black <= 0:
		return
	super.heal(0, 0, 0, to_black)
	_strip_non_black_hearts()


func _emit_stats_changed() -> void:
	_convert_empty_hearts_to_shields()
	super._emit_stats_changed()


func _convert_empty_hearts_to_shields() -> void:
	var computed := int(ST.get_stat(self, "hp"))
	var pending := computed - _absorbed_empty_hp
	if pending > 0:
		hp_list["black"] = hp_list.get("black", 0) + pending
		_absorbed_empty_hp = computed
	max_hp = 0
	_strip_non_black_hearts()


func _strip_non_black_hearts() -> void:
	hp_list["red"] = 0
	hp_list["green"] = 0
	hp_list["blue"] = 0
