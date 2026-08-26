extends Resource
class_name MatrixNode
## A single slot on the move/stat matrix goes here.
##
## This is the static, shared definition of what a node does — every
## monster that ever passes through this spot on the graph reads the same
## MatrixNode. Whether a *particular* monster has personally unlocked it
## lives on MonsterMatrixState instead, not here.

enum EffectType { START, STAT_BOOST, MOVE_UNLOCK }

@export var display_name: String = ""
@export var position: Vector2 = Vector2.ZERO
@export var element_tag: String = ""
@export var effect_type: EffectType = EffectType.STAT_BOOST

## Used when effect_type == STAT_BOOST. stat_name matches a MonsterData
## field name ("attack", "defense", "speed", "max_hp") so bonuses can be
## totaled generically instead of needing one property per stat here.
@export var stat_name: String = ""
@export var stat_amount: int = 0

## Used when effect_type == MOVE_UNLOCK.
@export var unlocked_move: MoveData

@export var neighbors: Array[MatrixNode] = []
