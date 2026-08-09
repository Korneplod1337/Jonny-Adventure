class_name CharacterSkin
extends Resource

## Один визуальный скин персонажа.
## Проще всего: указать textures_folder с теми же именами файлов, что у Jonny_textures.
## Либо задать готовые SpriteFrames вручную (body_frames / shot_frames).

@export var id: String = "default"
@export var display_name: String = "Default"
@export var unlocked_by_default: bool = true
## Папка с кадрами (player_afk1.png, shot_down.png и т.д.).
@export_dir var textures_folder: String = ""
## Если заданы — используются вместо сборки из папки.
@export var body_frames: SpriteFrames
@export var shot_frames: SpriteFrames

var _cached_body: SpriteFrames
var _cached_shot: SpriteFrames


func get_body_frames() -> SpriteFrames:
	# Папка приоритетнее готовых SpriteFrames (надёжнее и без UID-коллизий).
	if not _folder().is_empty():
		if _cached_body == null:
			_cached_body = _build_body_frames()
		return _cached_body
	if body_frames != null:
		return body_frames
	return SpriteFrames.new()


func get_shot_frames() -> SpriteFrames:
	if not _folder().is_empty():
		if _cached_shot == null:
			_cached_shot = _build_shot_frames()
		return _cached_shot
	if shot_frames != null:
		return shot_frames
	return SpriteFrames.new()


func _folder() -> String:
	return textures_folder.trim_suffix("/")


func _tex(file_name: String) -> Texture2D:
	var path := "%s/%s" % [_folder(), file_name]
	if not ResourceLoader.exists(path):
		push_warning("CharacterSkin '%s': missing texture %s" % [id, path])
		return null
	return load(path) as Texture2D


func _add_anim(
	frames: SpriteFrames,
	anim_name: StringName,
	file_names: Array[String],
	speed: float,
	loop: bool
) -> void:
	if not frames.has_animation(anim_name):
		frames.add_animation(anim_name)
	else:
		while frames.get_frame_count(anim_name) > 0:
			frames.remove_frame(anim_name, 0)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, loop)
	for file_name in file_names:
		var texture := _tex(file_name)
		if texture:
			frames.add_frame(anim_name, texture)


func _build_body_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if _folder().is_empty():
		return frames
	_add_anim(frames, &"afk_default", ["player_afk1.png", "player_afk2.png"], 1.0, true)
	_add_anim(frames, &"afk_up", ["back_afk1.png", "back_afk2.png"], 1.0, true)
	_add_anim(frames, &"walk_down", ["down_go1.png", "down_go2.png"], 5.0, true)
	_add_anim(frames, &"walk_h", ["right_go1.png", "right_go2.png", "right_go3.png", "right_go4.png"], 5.0, true)
	_add_anim(frames, &"walk_up", ["top_go1.png", "top_go2.png"], 5.0, true)
	return frames


func _build_shot_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if _folder().is_empty():
		return frames
	_add_anim(frames, &"down", ["shot_down.png"], 5.0, false)
	_add_anim(frames, &"left", ["shot_left.png"], 5.0, false)
	_add_anim(frames, &"right", ["shot_rightt.png"], 5.0, false)
	_add_anim(frames, &"up", ["shot_up.png"], 5.0, false)
	return frames
