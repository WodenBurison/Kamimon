extends RefCounted
class_name MonsterMatrixState
## Tracks one individual monster's progress through the (shared) matrix
## graph: where it currently sits, which nodes it has personally unlocked,
## and how many movement points it has banked.
##
## Monsters never share this state or see each other on the graph — two
## individuals of the same species can be in completely different places
## on the same MatrixNode graph at once.

var current_node: MatrixNode
var unlocked_nodes: Array[MatrixNode] = []
var available_points: int = 0

## Called from: matrix_screen.gd's _ready(), via
## MonsterMatrixState.new(graph["start_node"]).
## Purpose: starts a monster on its graph's start node, already unlocked.
func _init(start_node: MatrixNode) -> void:
	current_node = start_node
	unlocked_nodes = [start_node]

## Called from: internal only -- move_to(). Also called directly by
## matrix_screen.gd's _refresh_ui() to color each node button.
## Purpose: true if this monster has already unlocked the given node.
func is_unlocked(node: MatrixNode) -> bool:
	return unlocked_nodes.has(node)

## Called from: matrix_screen.gd's _ready() (initial grant) and
## _on_grant_point_pressed() (the "Level Up" stand-in button).
## Purpose: adds to this monster's banked movement points.
func grant_points(amount: int) -> void:
	available_points += amount

## Attempts to move onto an adjacent node.
## - Moving onto a node this monster has already unlocked is free.
## - Moving onto a brand-new node spends 1 point and permanently unlocks
##   it for this monster (if a point is available).
## Returns a result dict for the caller to turn into UI feedback rather
## than raising errors, since "can't afford it" is an expected outcome
## here, not a bug.
## Called from: matrix_screen.gd's _on_node_pressed(), when the player
## clicks a node button.
## Purpose: tries to move this monster onto `node`, unlocking it first if
## it's new and affordable.
func move_to(node: MatrixNode) -> Dictionary:
	if not current_node.neighbors.has(node):
		return {"success": false, "reason": "not_adjacent"}
	var newly_unlocked := false
	if not is_unlocked(node):
		if available_points <= 0:
			return {"success": false, "reason": "no_points"}
		available_points -= 1
		unlocked_nodes.append(node)
		newly_unlocked = true
	current_node = node
	return {"success": true, "newly_unlocked": newly_unlocked}

## Called from: matrix_screen.gd's _refresh_ui(), once per tracked stat
## name, to build the stat-bonus readout.
## Purpose: sums the stat bonus this monster has earned from every
## STAT_BOOST node it has unlocked matching `stat_name`.
func total_stat_bonus(stat_name: String) -> int:
	var total := 0
	for n in unlocked_nodes:
		if n.effect_type == MatrixNode.EffectType.STAT_BOOST and n.stat_name == stat_name:
			total += n.stat_amount
	return total

## Called from: matrix_screen.gd's _refresh_ui(), to build the
## moves-learned readout.
## Purpose: returns every move this monster has learned via a MOVE_UNLOCK
## node it has unlocked.
func learned_moves() -> Array[MoveData]:
	var moves: Array[MoveData] = []
	for n in unlocked_nodes:
		if n.effect_type == MatrixNode.EffectType.MOVE_UNLOCK and n.unlocked_move != null:
			moves.append(n.unlocked_move)
	return moves
