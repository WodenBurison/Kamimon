extends RefCounted
class_name PlaceholderMatrixData
## Hardcoded stand-in graph for the matrix prototype only — same throwaway
## role as placeholder_battle_data.gd. Real matrix content (built per-type,
## then spread out and linked into one giant matrix, per design notes) is
## a content-authoring pass for later. This exists only to prove the
## traversal + point economy on something small enough to see on screen.
##
## Two small clusters ("Fire" and "Water") bridged at one point, so the
## "build small sub-matrices, then link them together" idea is visible
## even at this scale.

static func _make_start(node_name: String, pos: Vector2, tag: String) -> MatrixNode:
	var node := MatrixNode.new()
	node.display_name = node_name
	node.position = pos
	node.element_tag = tag
	node.effect_type = MatrixNode.EffectType.START
	return node

static func _make_stat_node(node_name: String, pos: Vector2, tag: String, stat: String, amount: int) -> MatrixNode:
	var node := MatrixNode.new()
	node.display_name = node_name
	node.position = pos
	node.element_tag = tag
	node.effect_type = MatrixNode.EffectType.STAT_BOOST
	node.stat_name = stat
	node.stat_amount = amount
	return node

static func _make_move_node(node_name: String, pos: Vector2, tag: String, move: MoveData) -> MatrixNode:
	var node := MatrixNode.new()
	node.display_name = node_name
	node.position = pos
	node.element_tag = tag
	node.effect_type = MatrixNode.EffectType.MOVE_UNLOCK
	node.unlocked_move = move
	return node

static func _link(a: MatrixNode, b: MatrixNode) -> void:
	a.neighbors.append(b)
	b.neighbors.append(a)

## Returns {"nodes": Array[MatrixNode], "start_node": MatrixNode}.
static func build() -> Dictionary:
	var ember := MoveData.new()
	ember.display_name = "Ember"
	ember.power = 10
	ember.accuracy = 1.0

	var bubble := MoveData.new()
	bubble.display_name = "Bubble"
	bubble.power = 10
	bubble.accuracy = 1.0

	var fire_start := _make_start("Fire Start", Vector2(150, 400), "Fire")
	var fire_atk1 := _make_stat_node("Ember Claw", Vector2(260, 300), "Fire", "attack", 2)
	var fire_spd1 := _make_stat_node("Hot Foot", Vector2(260, 500), "Fire", "speed", 2)
	var fire_move := _make_move_node("Ember Node", Vector2(380, 220), "Fire", ember)
	var fire_atk2 := _make_stat_node("Cinder Fist", Vector2(400, 400), "Fire", "attack", 3)
	var fire_hp1 := _make_stat_node("Warm Blood", Vector2(380, 580), "Fire", "max_hp", 10)

	var bridge := _make_stat_node("Tempered Core", Vector2(576, 400), "", "max_hp", 15)

	var water_start := _make_start("Water Start", Vector2(1000, 400), "Water")
	var water_def1 := _make_stat_node("Tide Shell", Vector2(890, 300), "Water", "defense", 2)
	var water_spd1 := _make_stat_node("Riptide", Vector2(890, 500), "Water", "speed", 2)
	var water_move := _make_move_node("Bubble Node", Vector2(770, 220), "Water", bubble)
	var water_def2 := _make_stat_node("Deep Scale", Vector2(750, 400), "Water", "defense", 3)
	var water_hp1 := _make_stat_node("Cool Blood", Vector2(770, 580), "Water", "max_hp", 10)

	_link(fire_start, fire_atk1)
	_link(fire_start, fire_spd1)
	_link(fire_atk1, fire_move)
	_link(fire_atk1, fire_atk2)
	_link(fire_spd1, fire_atk2)
	_link(fire_spd1, fire_hp1)
	_link(fire_atk2, bridge)

	_link(water_start, water_def1)
	_link(water_start, water_spd1)
	_link(water_def1, water_move)
	_link(water_def1, water_def2)
	_link(water_spd1, water_def2)
	_link(water_spd1, water_hp1)
	_link(water_def2, bridge)

	var nodes: Array[MatrixNode] = [
		fire_start, fire_atk1, fire_spd1, fire_move, fire_atk2, fire_hp1,
		bridge,
		water_start, water_def1, water_spd1, water_move, water_def2, water_hp1,
	]

	return {"nodes": nodes, "start_node": fire_start}
