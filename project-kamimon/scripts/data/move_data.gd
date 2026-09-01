extends Resource
class_name MoveData
## Static definition of a move goes here.
##
## `domains` is the move's own set of elemental Domain tags — independent of
## whichever monster is using it (a monster can learn moves outside its
## native Domain via the move matrix, same as Pokemon letting a Fire-type
## learn Earthquake). Unlike a monster's `domains` (MonsterData), a move's
## domains are UNRANKED — just a flat set of tags, any number of them
## (including zero). An empty array means the move is untyped — it always
## resolves neutral in TypeResolution, which is why Attack and Guard
## (universal baseline actions, not real MoveData resources) don't need any
## set. Replaces the old single `domain: String` placeholder field.

## `effects` holds this move's secondary/structural effects -- everything
## beyond raw power/accuracy/domains (a stat debuff, hitting multiple
## times, hitting every enemy at once, etc.). See MoveEffect's own doc
## comment (scripts/data/move_effect.gd) for the three hooks an effect can
## implement and why there are three instead of one. Empty by default --
## the common case, and every hook is a safe no-op when this is empty, so
## adding the system didn't change any existing move's behavior.
##
## (2026-09-01, superseded same day: this replaces an earlier, narrower
## version of this idea that put flat effect_stat/effect_stages/
## effect_chance/effect_duration/effect_target fields directly on MoveData,
## before it was clear multi-hit/multi-target moves would also be common
## and wouldn't fit that shape.)

@export var display_name: String = ""
@export var power: int = 10
@export var accuracy: float = 1.0
@export var domains: Array[String] = []
@export var effects: Array[MoveEffect] = []
