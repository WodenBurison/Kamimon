extends RefCounted
class_name PlaceholderBattleData
## Curated demo-battle data. Despite the historical "Placeholder" name, this
## now sources REAL content: every monster it hands out is load()ed from a
## .tres Resource file under resources/monsters (see project-context.md's
## Implementation principle section for the full migration history --
## every monster and move used to be built here directly in GDScript via
## MonsterData.new()/MoveData.new(), which meant nothing was reachable in
## the Inspector). The name stays "Placeholder" because the curation itself
## still is: there's no walkable overworld yet to drive real encounters
## from, so this is still standing in for that -- it just no longer builds
## its content by hand.
##
## Rewired 2026-09-02, the same day the full 7-monster/11-move roster
## finished converting to .tres. Nothing about the actual battle changed --
## every monster here has the exact same stats/moves as the in-code
## version it replaces (verified when each .tres was generated), so this
## is a data-source swap, not a balance change.
##
## Each monster is handed back as an independent .duplicate() of the
## loaded resource, never the loaded resource itself. load() returns the
## SAME cached object on every call with the same path -- without
## duplicating, two Combatants built from one file (or the same monster
## reused across two battles) would silently share one MonsterData
## instance, so e.g. a level-up or a gear change on one would leak onto
## the other. The default shallow duplicate() is enough: it copies this
## resource's own scalar/array fields (level, equipped_gear, accuracy,
## etc.) into a new independent object, while still sharing the MoveData/
## Texture2D sub-resources it references (assigned_moves, battler_sprite)
## -- which is correct, since nothing in the engine mutates a move or a
## sprite at runtime, only a monster's own stats.

const MONSTERS_DIR := "res://resources/monsters"

## The player's 4 starting monsters, same species/order as before this
## rewire: Emberkit, Mossback, Zephyrun, Graniteye.
static func get_player_party() -> Array[MonsterData]:
	var party: Array[MonsterData] = [
		_load_monster("emberkit"),
		_load_monster("mossback"),
		_load_monster("zephyrun"),
		_load_monster("graniteye"),
	]
	return party

## Three enemies, not four -- deliberately uneven against the player's full
## party of four, see the design note this line used to carry in the old
## in-code version (still true, just no longer duplicated here as a
## comment -- see Battle structure section of project-context.md).
static func get_enemy_party() -> Array[MonsterData]:
	var party: Array[MonsterData] = [
		_load_monster("grimhowl"),
		_load_monster("grimhowl_pup"),
		_load_monster("grimhowl_alpha"),
	]
	return party

static func _load_monster(file_stem: String) -> MonsterData:
	var mon: MonsterData = load("%s/%s.tres" % [MONSTERS_DIR, file_stem])
	return mon.duplicate() as MonsterData
