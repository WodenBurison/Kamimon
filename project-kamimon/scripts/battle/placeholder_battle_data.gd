extends RefCounted
class_name PlaceholderBattleData
## Curated demo-battle data. Despite the "Placeholder" name, this sources
## real content: every monster it hands out is load()ed from a .tres
## Resource file under resources/monsters. The name stays "Placeholder"
## because the curation itself still is: there's no walkable overworld yet
## to drive real encounters from, so this is still standing in for that.
##
## Each monster is handed back as an independent .duplicate() of the loaded
## resource, never the loaded resource itself. load() returns the SAME
## cached object on every call with the same path -- without duplicating,
## two Combatants built from one file (or the same monster reused across
## two battles) would silently share one MonsterData instance, so e.g. a
## level-up or a gear change on one would leak onto the other. The default
## shallow duplicate() is enough: it copies this resource's own
## scalar/array fields (level, equipped_gear, accuracy, etc.) into a new
## independent object, while still sharing the MoveData/Texture2D
## sub-resources it references (assigned_moves, battler_sprite) -- which is
## correct, since nothing in the engine mutates a move or a sprite at
## runtime, only a monster's own stats.

const MONSTERS_DIR := "res://resources/monsters"

## Called from: battle_manager.gd's _build_parties(). Also called directly
## by battle_smoke_test.gd.
## Purpose: returns the player's 4 starting monsters -- Emberkit, Mossback,
## Zephyrun, Graniteye -- each a fresh duplicate.
static func get_player_party() -> Array[MonsterData]:
	var party: Array[MonsterData] = [
		_load_monster("emberkit"),
		_load_monster("mossback"),
		_load_monster("zephyrun"),
		_load_monster("graniteye"),
	]
	return party

## Called from: battle_manager.gd's _build_parties().
## Purpose: returns 3 enemies -- deliberately fewer than the player's 4, for
## an uneven demo fight -- each a fresh duplicate.
static func get_enemy_party() -> Array[MonsterData]:
	var party: Array[MonsterData] = [
		_load_monster("grimhowl"),
		_load_monster("grimhowl_pup"),
		_load_monster("grimhowl_alpha"),
	]
	return party

## Called from: internal only -- get_player_party(), get_enemy_party().
## Purpose: loads one monster's .tres by file stem and hands back an
## independent duplicate rather than the shared cached resource.
static func _load_monster(file_stem: String) -> MonsterData:
	var mon: MonsterData = load("%s/%s.tres" % [MONSTERS_DIR, file_stem])
	return mon.duplicate() as MonsterData
