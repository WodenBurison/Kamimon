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
##
## Every monster below is left at MonsterData's default level (5) on both
## sides deliberately, so levelFactor stays neutral (1.0x) and this
## placeholder battle's balance isn't disturbed by the new level-gap
## mechanic landing (2026-08-31) — nobody has picked real per-species levels
## yet. Same reasoning for equipped_gear: left at the class default (all
## zero), so gearFactor also stays neutral until real gear content exists.

static func _make_move(move_name: String, power: int, accuracy: float, domains: Array[String] = []) -> MoveData:
	var move := MoveData.new()
	move.display_name = move_name
	move.power = power
	move.accuracy = accuracy
	move.domains = domains
	return move

static func _make_monster(
	monster_name: String,
	hp: int,
	atk: int,
	def: int,
	spd: int,
	primary_domain: String,
	sprite_path: String,
	moves: Array[MoveData]
) -> MonsterData:
	var monster := MonsterData.new()
	monster.display_name = monster_name
	monster.max_hp = hp
	monster.attack = atk
	monster.defense = def
	monster.speed = spd
	monster.domains = [primary_domain, "", "", ""]
	monster.battler_sprite = load(sprite_path)
	monster.assigned_moves = moves
	return monster

## Four mons with deliberately different speed values so the ATB fill-rate
## differences are visible across a full 4-wide party, each with its
## out-of-battle-assigned loadout of three moves (Attack and Guard are the
## universal baseline actions and aren't part of this list). Each also gets
## one signature move matching its own Domain (the rest stay untyped/
## neutral) so multi-domain type resolution actually has something to bite
## on in a playtest — Emberkit/Flame is the deliberate foil for the enemy
## Grimhowl pack's Frost domain below (Flame beats Frost per the locked
## graph in Types & Charts.md).
static func get_player_party() -> Array[MonsterData]:
	var tackle := _make_move("Tackle", 12, 0.95)
	var heavy_slam := _make_move("Heavy Slam", 20, 0.75)
	var guard_bash := _make_move("Guard Bash", 8, 1.0)
	var quick_snap := _make_move("Quick Snap", 6, 1.0)
	var ember_burst := _make_move("Ember Burst", 16, 0.85, ["Flame"])
	var root_bind := _make_move("Root Bind", 10, 0.9, ["Verdant"])
	var gale_slice := _make_move("Gale Slice", 14, 0.9, ["Gale"])
	var stone_fist := _make_move("Stone Fist", 18, 0.8, ["Stone"])

	var sprite := "res://assets/placeholder_My_mon_back_sprite.png"
	var party: Array[MonsterData] = [
		_make_monster("Emberkit", 90, 14, 8, 16, "Flame", sprite, [tackle, heavy_slam, ember_burst]),
		_make_monster("Mossback", 120, 10, 14, 8, "Verdant", sprite, [guard_bash, tackle, root_bind]),
		_make_monster("Zephyrun", 75, 12, 6, 20, "Gale", sprite, [quick_snap, tackle, gale_slice]),
		_make_monster("Graniteye", 105, 13, 16, 6, "Stone", sprite, [stone_fist, guard_bash, tackle]),
	]
	return party

## Three enemies, not four — deliberately uneven against the player's full
## party of four, so the "up to four, not always symmetric" party-size path
## actually gets exercised instead of assuming both sides always match. All
## three share the Frost domain (a wolf pack reads as tundra/frost-flavored)
## with Bite as their signature Frost move, specifically so Emberkit's Flame
## domain has a clear super-effective matchup to show off.
static func get_enemy_party() -> Array[MonsterData]:
	var bite := _make_move("Bite", 14, 0.9, ["Frost"])
	var snarl := _make_move("Snarl", 9, 1.0)
	var claw_rake := _make_move("Claw Rake", 17, 0.8)

	var sprite := "res://assets/placeholder_enemy_mon.png"
	var party: Array[MonsterData] = [
		_make_monster("Grimhowl", 100, 13, 9, 12, "Frost", sprite, [bite, snarl, claw_rake]),
		_make_monster("Grimhowl Pup", 60, 9, 6, 18, "Frost", sprite, [bite, snarl, claw_rake]),
		_make_monster("Grimhowl Alpha", 130, 16, 12, 10, "Frost", sprite, [bite, claw_rake, snarl]),
	]
	return party
