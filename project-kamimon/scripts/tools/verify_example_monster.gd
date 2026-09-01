extends SceneTree
## One-off check: loads resources/monsters/emberkit.tres back and confirms
## every field matches PlaceholderBattleData's in-code Emberkit exactly, and
## that the moves array really did link out to the shared .tres files
## instead of embedding private copies.

func _initialize() -> void:
	var mon: MonsterData = load("res://resources/monsters/emberkit.tres")
	print("display_name: ", mon.display_name, " (expect Emberkit) -> ", mon.display_name == "Emberkit")
	print("max_hp: ", mon.max_hp, " (expect 90) -> ", mon.max_hp == 90)
	print("attack: ", mon.attack, " (expect 14) -> ", mon.attack == 14)
	print("defense: ", mon.defense, " (expect 8) -> ", mon.defense == 8)
	print("speed: ", mon.speed, " (expect 16) -> ", mon.speed == 16)
	print("domains: ", mon.domains, " (expect [Flame,,,]) -> ", mon.domains == ["Flame", "", "", ""])
	print("level (untouched default): ", mon.level, " (expect 5) -> ", mon.level == 5)
	print("equipped_gear (untouched default): ", mon.equipped_gear, " (expect [0,0,0]) -> ", mon.equipped_gear == [0.0, 0.0, 0.0])
	print("accuracy/evasion/crit_stat (untouched defaults): ", mon.accuracy, " ", mon.evasion, " ", mon.crit_stat)
	print("moves.size(): ", mon.moves.size(), " (expect 3) -> ", mon.moves.size() == 3)
	for m in mon.moves:
		print("  move: ", m.display_name, " power=", m.power, " accuracy=", m.accuracy, " domains=", m.domains, " resource_path=", m.resource_path)
	quit()
