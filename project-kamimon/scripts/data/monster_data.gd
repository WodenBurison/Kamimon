extends Resource
class_name MonsterData
## Static definition of a monster species/build goes here — the numbers that are
## the same for every instance of this monster. Per-battle state (current HP,
## ATB gauge) does not belong here; that lives on Combatant instead.
##
## This is a prototype-stage shape. Type data, move-matrix position, and
## evolution requirements are deliberately left out until those systems are
## designed — adding them later just means adding more @export fields.
##
## `moves` is this monster's out-of-battle-assigned active loadout — up to
## three moves the player picks outside of battle. It is not the monster's
## full learned movepool (no move-matrix/learning system exists yet, so for
## now the assigned loadout and the learned set are the same thing). Attack
## and Guard are separate universal baseline actions every monster has
## regardless of this list, so they aren't included here.

@export var display_name: String = ""
@export var max_hp: int = 100
@export var attack: int = 10
@export var defense: int = 10
@export var speed: int = 10
@export var battler_sprite: Texture2D
@export var moves: Array[MoveData] = []
