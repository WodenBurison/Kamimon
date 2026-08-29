extends RefCounted
class_name PlaceholderBattleData
## Hardcoded stand-in data for the battle prototype only.
##
## Real monster/move content is meant to be authored as MonsterData/MoveData
## .tres resources in the editor Inspector later, probably loaded from a data
## folder at startup. Hand-typing that resource file format without being
## able to run the editor to verify it is a good way to hand you a project
## that silently fails to load, so this factory exists to give the battle
## loop something real to run against without that risk. Delete this file
## once a proper data-loading system exists.

static func _make_move(move_name: String, power: int, accuracy: float) -> MoveData:
	var move := MoveData.new()
	move.display_name = move_name
	move.power = power
	move.accuracy = accuracy
	return move

static func _make_monster(
	monster_name: String,
	hp: int,
	atk: int,
	def: int,
	spd: int,
	sprite_path: String,
	moves: Array[MoveData]
) -> MonsterData:
	var monster := MonsterData.new()
	monster.display_name = monster_name
	monster.max_hp = hp
	monster.attack = atk
	monster.defense = def
	monster.speed = spd
	monster.battler_sprite = load(sprite_path)
	monster.moves = moves
	return monster

## Four mons with deliberately different speed values so the ATB fill-rate
## differences are visible across a full 4-wide party, each with its
## out-of-battle-assigned loadout of three moves (Attack and Guard are the
## universal baseline actions and aren't part of this list).
static func get_player_party() -> Array[MonsterData]:
	var tackle := _make_move("Tackle", 12, 0.95)
	var heavy_slam := _make_move("Heavy Slam", 20, 0.75)
	var guard_bash := _make_move("Guard Bash", 8, 1.0)
	var quick_snap := _make_move("Quick Snap", 6, 1.0)
	var ember_burst := _make_move("Ember Burst", 16, 0.85)
	var root_bind := _make_move("Root Bind", 10, 0.9)
	var gale_slice := _make_move("Gale Slice", 14, 0.9)
	var stone_fist := _make_move("Stone Fist", 18, 0.8)

	var sprite := "res://assets/placeholder_My_mon_back_sprite.png"
	var party: Array[MonsterData] = [
		_make_monster("Emberkit", 90, 14, 8, 16, sprite, [tackle, heavy_slam, ember_burst]),
		_make_monster("Mossback", 120, 10, 14, 8, sprite, [guard_bash, tackle, root_bind]),
		_make_monster("Zephyrun", 75, 12, 6, 20, sprite, [quick_snap, tackle, gale_slice]),
		_make_monster("Graniteye", 105, 13, 16, 6, sprite, [stone_fist, guard_bash, tackle]),
	]
	return party

## Three enemies, not four — deliberately uneven against the player's full
## party of four, so the "up to four, not always symmetric" party-size path
## actually gets exercised instead of assuming both sides always match.
static func get_enemy_party() -> Array[MonsterData]:
	var bite := _make_move("Bite", 14, 0.9)
	var snarl := _make_move("Snarl", 9, 1.0)
	var claw_rake := _make_move("Claw Rake", 17, 0.8)

	var sprite := "res://assets/placeholder_enemy_mon.png"
	var party: Array[MonsterData] = [
		_make_monster("Grimhowl", 100, 13, 9, 12, sprite, [bite, snarl, claw_rake]),
		_make_monster("Grimhowl Pup", 60, 9, 6, 18, sprite, [bite, snarl, claw_rake]),
		_make_monster("Grimhowl Alpha", 130, 16, 12, 10, sprite, [bite, claw_rake, snarl]),
	]
	return party
