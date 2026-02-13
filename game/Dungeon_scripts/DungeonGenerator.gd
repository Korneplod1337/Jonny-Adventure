extends Resource
class_name DungeonGenerator

const Room = preload("res://game/Dungeon_scripts/Room.gd")
enum RoomType { START, STANDARD, SHOP, ARMORY, BLOOD_TRIBUTE,
				TREASURE, BANK, GAMBLING, BOSS, SECRET}

# либо как поле класса / ресурса
const directions := [
	Vector2(1, 0),
	Vector2(-1, 0),
	Vector2(0, 1),
	Vector2(0, -1),
]


func generate(total_rooms: int, shop_rooms: int) -> Dictionary:
	var rooms := {}
	var start = Room.new()
	start.pos = Vector2(0,0)
	start.type = RoomType.START
	rooms[start.pos] = start

	# Генерируем остальные комнаты, случайно расширяя от уже существующих
	var pending = [start]
	while rooms.size() < total_rooms:
		if pending.is_empty():
			pending = rooms.values().duplicate()
			pending.shuffle()

		var current = pending[randi() % pending.size()]
		var dir = directions[randi() % directions.size()]
		var new_pos = current.pos + dir

		# если комната уже есть — пропускаем
		if rooms.has(new_pos):
			continue

		# создаём новую стандартную комнату
		var new_room = Room.new()
		new_room.pos = new_pos
		new_room.type = RoomType.STANDARD
		rooms[new_pos] = new_room

		# записываем выходы в обе стороны
		current.exits[dir] = new_pos
		new_room.exits[-dir] = current.pos
		pending.append(new_room)
	
	
	# Ищем самую далёкую комнату от старта — под босса
	var farthest: Room = rooms.values()[0]
	if farthest.type != RoomType.STANDARD:# Ищем самую далёкую среди стандартных
		var others := rooms.values().filter(func(r): return r.type == RoomType.STANDARD)
		if others.size() > 0:
			farthest = others.reduce(func(a, b):
				return a if a.pos.distance_to(Vector2(0,0)) > b.pos.distance_to(Vector2(0,0)) else b)
	farthest.type = RoomType.BOSS
	
	# Выбираем несколько стандартных комнат как магазины
	var placed := 0
	var candidates := rooms.values().filter(func(r): return r.type == RoomType.STANDARD)
	while placed < shop_rooms and candidates.size() > 0:
		var r = candidates[randi() % candidates.size()]
		r.type = RoomType.SHOP
		candidates.erase(r)
		placed += 1
	
	return rooms
