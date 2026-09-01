extends MoveEffect
class_name MultiHitEffect
## Repeats the move's normal single-hit resolution (its own independent
## hit-chance roll, damage roll, crit roll -- every hit rolls separately,
## nothing is guaranteed just because an earlier hit connected) against the
## same target min_hits..max_hits times, rolled once per use of the move
## (classic "hits 2-5 times" pattern). A target that goes down partway
## through stops the remaining hits early -- checked in
## BattleManager._resolve_attack, since there's nothing left to hit.
##
## min/max default to Claude's placeholder pick (2-5, the common video-game
## convention) -- not reviewed by Woden yet.

@export var min_hits: int = 2
@export var max_hits: int = 5

func hit_count() -> int:
	return randi_range(min_hits, max_hits)
