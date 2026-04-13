extends Base_equip

func effect_on() -> void:
	GS.equip_update('test_chest')

func effect_off() -> void:
	GS.equip_update('test_chest')
