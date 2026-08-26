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

func _init(start_node: MatrixNode) -> void:
	current_node = start_node
	unlocked_nodes = [start_node]

func is_unlocked(node: MatrixNode) -> bool:
	return unlocked_nodes.has(node)

func grant_points(amount: int) -> void:
	available_points += amount

## Attempts to move onto an adjacent node.
## - Moving onto a node this monster has already unlocked is free.
## - Moving onto a brand-new node spends 1 point and permanently unlocks
##   it for this monster (if a point is available).
## Returns a result dict for the caller to turn into UI feedback rather
## than raising errors, since "can't afford it" is an expected outcome
## here, not a bug.
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

func total_stat_bonus(stat_name: String) -> int:
	var total := 0
	for n in unlocked_nodes:
		if n.effect_type == MatrixNode.EffectType.STAT_BOOST and n.stat_name == stat_name:
			total += n.stat_amount
	return total

func learned_moves() -> Array[MoveData]:
	var moves: Array[MoveData] = []
	for n in unlocked_nodes:
		if n.effect_type == MatrixNode.EffectType.MOVE_UNLOCK and n.unlocked_move != null:
			moves.append(n.unlocked_move)
	return moves
