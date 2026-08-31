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

@export var display_name: String = ""
@export var power: int = 10
@export var accuracy: float = 1.0
@export var domains: Array[String] = []
