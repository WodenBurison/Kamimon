extends Resource
class_name MoveData
## Static definition of a move goes here.
##
## No type/element field yet — the type chart is still an open design item
## (see Main.md), so damage for the battle prototype is flat power vs.
## defense. A type field goes here once the type chart exists, and the
## damage formula in BattleManager picks it up from there.

@export var display_name: String = ""
@export var power: int = 10
@export var accuracy: float = 1.0
