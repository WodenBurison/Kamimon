extends Resource
class_name MoveData
## Static definition of a move.
##
## domains: the move's own Domain tags, independent of the monster using
## it (a monster can learn off-domain moves via the move matrix).
## Unranked -- a flat set, any number including zero. Empty means
## untyped, always resolves neutral in TypeResolution.
##
## effects: this move's secondary per-hit effects (e.g. a chance to lower
## a stat via StatModifierEffect). Does NOT control hit count or
## targeting -- see targets/attempts/random_target/target_all below for
## that. Empty by default, safe no-op when empty.

@export var display_name: String = ""
@export var power: int = 10
@export var accuracy: float = 1.0
## How many enemies this move should hit. Not implemented anywhere yet --
## only target_all and random_target below are actually wired in; a
## value here above 1 currently does nothing.
@export var targets: int = 1
## How many times this move repeats against its target. Read directly by
## BattleManager._hit_count().
@export var attempts: int = 1
## Skips the target picker and hits one randomly-chosen living enemy.
## Read by BattleActionMenu._on_move_button_pressed().
@export var random_target: bool = false
## Skips the target picker and hits every living enemy. Read by
## BattleActionMenu._on_move_button_pressed() and
## BattleManager._start_enemy_turn().
@export var target_all: bool = false
@export var domains: Array[String] = []
@export var effects: Array[MoveEffect] = []
