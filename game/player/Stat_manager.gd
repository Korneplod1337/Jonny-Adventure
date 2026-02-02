extends Node


func get_stat(p: Node, stat: String) -> float :
	match stat:
		"hp": 
			var hp = int(p.base_max_hp + lerp(0.0, 9.0, (p.hit_points_level - 1.0) / 9.0))
			hp += int(clamp((p.hp_bonus * 0.5), -10.0, 10.0))
			return hp
		"move_speed":
			var speed = p.base_move_speed + lerp(0.0, 270.0, (p.move_speed_level - 1.0) / 9.0)
			speed *= clamp((1 + p.speed_bonus * 0.05), 0.4, 1.6)
			return speed
		"luck":
			var luck = p.base_luck + lerp(0.0, 0.63, (p.luck_level - 1.0) / 9.0)
			luck *= clamp((1 + p.luck_bonus * 0.05), 0.1, 4.0)
			return luck
		"magic":
			var magic = p.base_magic + lerp(0.0, 0.9, (p.magic_level - 1.0) / 9.0)
			magic *= clamp((1 + p.magic_bonus * 0.05), 0.1, 4.0)
			return magic
		"damage":
			var damage = p.base_damage + lerp(0.0, 27.0, (p.damage_level - 1.0) / 9.0)
			damage *= clamp((1 + p.damage_bonus * 0.05), 0.1, 4.0)
			return damage
		"spread":
			var spread_deg: float = lerp(36.0, 0.0, (p.spread_level - 1.0) / 9.0)
			spread_deg += p.base_spread 
			spread_deg *= clamp((1 - p.accuracy_bonus * 0.05), 0.1, 4.0)
			return spread_deg
		"range":
			var range_val = p.base_range + lerp(0.0, 360.0, (p.range_level - 1.0) / 9.0)
			range_val *= clamp((1 + p.range_bonus * 0.05), 0.1, 4.0)
			return range_val
		"fire_rate":
			var fire_rate = lerp(0.54, 0.0, (p.fire_rate_level - 1.0) / 9.0)
			fire_rate += p.base_fire_rate
			fire_rate *= clamp((1 - p.fire_rate_bonus * 0.05), 0.1, 4.0)
			return fire_rate
		_:
			push_warning("Unknown stat in getter: %s" % stat)
			return 1


func upgrade_stat(p: Node, stat:String, lvl: int) -> void:
	match stat:
		'hp':
			var hp_list = p.hp_list
			p.hit_points_level = clamp(p.hit_points_level + lvl, 1.0, 10.0)
			p.max_hp = get_stat(p, 'hp')
			if lvl < 0:
				var live_total :int = hp_list["red"] + hp_list["green"]
				if live_total > p.max_hp:
					if hp_list["red"] > 0:
						hp_list["red"] -= 1
					elif hp_list["green"] > 0:
						hp_list["green"] -= 1
		'move_speed':
			p.move_speed_level = clamp(p.move_speed_level + lvl, 1.0, 10.0)
			p.move_speed = get_stat(p, "move_speed")
		'luck':
			p.luck_level = clamp(p.luck_level + lvl, 1.0, 10.0)
			p.luck = get_stat(p, "luck")
		'magic':
			# 
			p.magic_level = clamp(p.magic_level + lvl, 1.0, 10.0)
			p.magic = get_stat(p, "magic")
		'damage':
			p.damage_level = clamp(p.damage_level + lvl, 1.0, 10.0)
			p.damage = get_stat(p, "damage")
		'spread':
			p.spread_level = clamp(p.spread_level + lvl, 1.0, 10.0)
			p.spread = get_stat(p, "spread")
		'range':
			p.range_level = clamp(p.range_level + lvl, 1.0, 10.0)
			p.atk_range =get_stat(p, "range")
		'fire_rate': 
			p.fire_rate_level = clamp(p.fire_rate_level + lvl, 1.0, 10.0)
			p.fire_rate = get_stat(p, "fire_rate")
		_:
			push_warning("Unknown stat in upgrade: %s" %stat)
	p._emit_stats_changed()
