extends Control
class_name MatrixScreen
## Standalone test harness for the move/stat matrix mechanic.
##
## Not wired into battle or the overworld yet — one monster, one graph,
## click a highlighted neighbor to try to move onto it. There's no leveling
## system built yet either, so a "Level Up" button stands in for whatever
## actually grants points later.
##
## Node references are wired via exported NodePaths and resolved with
## get_node() in _ready(), same pattern battle_manager.gd uses now.

@export var edges_layer_path: NodePath
@export var nodes_layer_path: NodePath
@export var monster_label_path: NodePath
@export var points_label_path: NodePath
@export var stats_label_path: NodePath
@export var moves_label_path: NodePath
@export var message_label_path: NodePath
@export var grant_point_button_path: NodePath

var edges_layer: Node2D
var nodes_layer: Control
var monster_label: Label
var points_label: Label
var stats_label: Label
var moves_label: Label
var message_label: Label
var grant_point_button: Button

var all_nodes: Array[MatrixNode] = []
var monster_state: MonsterMatrixState
var monster_name := "Emberkit"

const NODE_SIZE := Vector2(48, 48)
const COLOR_CURRENT := Color(1.0, 0.85, 0.2)
const COLOR_UNLOCKED := Color(0.4, 0.85, 0.4)
const COLOR_LOCKED := Color(0.55, 0.55, 0.6)

var _node_buttons: Dictionary = {} # MatrixNode -> Button

func _ready() -> void:
	edges_layer = get_node(edges_layer_path)
	nodes_layer = get_node(nodes_layer_path)
	monster_label = get_node(monster_label_path)
	points_label = get_node(points_label_path)
	stats_label = get_node(stats_label_path)
	moves_label = get_node(moves_label_path)
	message_label = get_node(message_label_path)
	grant_point_button = get_node(grant_point_button_path)

	var graph := PlaceholderMatrixData.build()
	all_nodes = graph["nodes"]
	monster_state = MonsterMatrixState.new(graph["start_node"])
	monster_state.grant_points(3)

	grant_point_button.pressed.connect(_on_grant_point_pressed)
	monster_label.text = monster_name
	message_label.text = "Click a neighboring node to move onto it."

	_draw_edges()
	_build_node_buttons()
	_refresh_ui()

func _draw_edges() -> void:
	var drawn := {}
	for node in all_nodes:
		for neighbor in node.neighbors:
			var key := _edge_key(node, neighbor)
			if drawn.has(key):
				continue
			drawn[key] = true
			var line := Line2D.new()
			line.width = 3.0
			line.default_color = Color(0.6, 0.6, 0.65)
			line.add_point(node.position)
			line.add_point(neighbor.position)
			edges_layer.add_child(line)

func _edge_key(a: MatrixNode, b: MatrixNode) -> String:
	var id_a := a.get_instance_id()
	var id_b := b.get_instance_id()
	if id_a < id_b:
		return "%d_%d" % [id_a, id_b]
	return "%d_%d" % [id_b, id_a]

func _build_node_buttons() -> void:
	for node in all_nodes:
		var button := Button.new()
		button.custom_minimum_size = NODE_SIZE
		button.size = NODE_SIZE
		button.position = node.position - NODE_SIZE / 2.0
		button.text = _node_label(node)
		button.tooltip_text = node.display_name
		button.pressed.connect(_on_node_pressed.bind(node))
		nodes_layer.add_child(button)
		_node_buttons[node] = button

func _node_label(node: MatrixNode) -> String:
	match node.effect_type:
		MatrixNode.EffectType.MOVE_UNLOCK:
			return "M"
		MatrixNode.EffectType.START:
			return "S"
		_:
			return "+"

func _on_node_pressed(node: MatrixNode) -> void:
	var result := monster_state.move_to(node)
	if result["success"]:
		if result["newly_unlocked"]:
			message_label.text = "Unlocked %s!" % node.display_name
		else:
			message_label.text = "Moved to %s." % node.display_name
	else:
		match result["reason"]:
			"not_adjacent":
				message_label.text = "%s isn't adjacent to your current spot." % node.display_name
			"no_points":
				message_label.text = "Not enough points to unlock %s." % node.display_name
			_:
				message_label.text = "Can't move there."
	_refresh_ui()

func _on_grant_point_pressed() -> void:
	monster_state.grant_points(1)
	message_label.text = "Gained 1 point. (Stand-in for a real level-up system.)"
	_refresh_ui()

func _refresh_ui() -> void:
	points_label.text = "Points: %d" % monster_state.available_points

	var stat_names := ["attack", "defense", "speed", "max_hp"]
	var stat_lines := PackedStringArray()
	for stat_name in stat_names:
		var bonus := monster_state.total_stat_bonus(stat_name)
		if bonus != 0:
			stat_lines.append("%s +%d" % [stat_name, bonus])
	var stats_text := ", ".join(stat_lines) if stat_lines.size() > 0 else "none yet"
	stats_label.text = "Stat bonuses: %s" % stats_text

	var move_names := PackedStringArray()
	for move in monster_state.learned_moves():
		move_names.append(move.display_name)
	var moves_text := ", ".join(move_names) if move_names.size() > 0 else "none yet"
	moves_label.text = "Moves learned: %s" % moves_text

	for node in all_nodes:
		var button: Button = _node_buttons[node]
		if node == monster_state.current_node:
			button.modulate = COLOR_CURRENT
		elif monster_state.is_unlocked(node):
			button.modulate = COLOR_UNLOCKED
		else:
			button.modulate = COLOR_LOCKED
