class_name CharacterSelectEntry
extends Resource

## ID для DungeonManager.selected_character (например "Jonny").
@export var id: String = ""
## Текст имени, если name_texture не задан.
@export var display_name: String = ""
## Портрет в боковых слотах и у заблокированных.
@export var portrait: Texture2D
## Портрет выбранного персонажа в центре.
@export var portrait_selected: Texture2D
## Своя иконка замка; если пусто — берётся lock_portrait из меню.
@export var portrait_locked: Texture2D
## Картинка имени вместо Label (char_select_name_*.png).
@export var name_texture: Texture2D
## Можно ли выбрать персонажа и начать игру.
@export var unlocked: bool = true
## Визуальные скины персонажа (первый обычно default).
@export var skins: Array[CharacterSkin] = []


func get_skin_by_id(skin_id: String) -> CharacterSkin:
	if skins.is_empty():
		return null
	for skin in skins:
		if skin != null and skin.id == skin_id:
			return skin
	return skins[0]


func get_unlocked_skins() -> Array[CharacterSkin]:
	var result: Array[CharacterSkin] = []
	for skin in skins:
		if skin == null or skin.id.is_empty():
			continue
		if CharacterMedalsManager.is_skin_unlocked(id, skin.id, skin.unlocked_by_default):
			result.append(skin)
	return result


func get_selected_skin() -> CharacterSkin:
	var selected_id := CharacterMedalsManager.get_selected_skin(id)
	var unlocked := get_unlocked_skins()
	if unlocked.is_empty():
		return get_skin_by_id(selected_id)
	for skin in unlocked:
		if skin.id == selected_id:
			return skin
	return unlocked[0]


func cycle_next_skin() -> CharacterSkin:
	var unlocked := get_unlocked_skins()
	if unlocked.is_empty():
		return null
	var current := get_selected_skin()
	var index := 0
	for i in unlocked.size():
		if unlocked[i] == current or (current and unlocked[i].id == current.id):
			index = i
			break
	var next: CharacterSkin = unlocked[(index + 1) % unlocked.size()]
	CharacterMedalsManager.set_selected_skin(id, next.id)
	return next
