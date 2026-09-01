extends MoveEffect
class_name MultiTargetEffect
## Marks a move as hitting every living target on the defending side at
## once, instead of the one target normally picked.
##
## IMPORTANT GAP (2026-09-01): the resolution logic is complete and tested
## -- BattleManager.resolve_multi_target_attack(attacker, targets, move)
## correctly loops the move (including its own hit_count() from a
## MultiHitEffect, if it has one) across every living entry in `targets`,
## skipping downed ones. What's NOT done: the player action menu doesn't
## check target_mode() at all yet, so a real player picking this move in
## the actual battle UI still gets the normal single-target picker, and
## whichever target they pick only hits that one target -- the "hit
## everyone automatically, skip the picker" UI wiring in
## BattleManager._on_move_selected/_on_attack_selected is deliberately not
## built yet (it touches the action-menu flow that's already covered by
## passing UI tests, and wasn't asked for). Safe to author moves with this
## today; just know the UI doesn't honor it yet.

func target_mode() -> String:
	return "all_enemies"
