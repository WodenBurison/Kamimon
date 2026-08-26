extends Resource
class_name MonsterData
## Static definition of a monster species/build goes here — the numbers that are
## the same for every instance of this monster. Per-battle state (current HP,
## ATB gauge) does not belong here; that lives on Combatant instead.
##
## This is a prototype-stage shape. Type data, move-matrix position, and
## evolution requirements are deliberately left out until those systems are
## designed — adding them later just means adding more @export fields.

@export var display_name: String = ""
@export var max_hp: int = 100
@export var attack: int = 10
@export var defense: int = 10
@export var speed: int = 10
@export var battler_sprite: Texture2D
@export var moves: Array[MoveData] = []
