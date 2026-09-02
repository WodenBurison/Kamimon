extends MoveEffect
class_name MultiTargetEffect
## Marks a move as hitting every living target on the defending side at
## once, instead of the one target normally picked.
##
## WIRED (2026-09-02): BattleManager.resolve_multi_target_attack(attacker,
## targets, move) loops the move (including its own hit_count() from a
## MultiHitEffect, if it has one) across every living entry in `targets`,
## skipping downed ones. MoveData.targets_all_enemies() is the pure-data
## check both call sites use to detect this: BattleActionMenu skips the
## single-target picker entirely for a move like this and emits
## move_selected_all_enemies instead of move_selected, and
## BattleManager._start_enemy_turn routes an AI-picked move the same way
## instead of attacking the one randomly-chosen target. A player/enemy
## picking this move today really does hit every living target on the
## other side, no picker involved.

func target_mode() -> String:
	return "all_enemies"
