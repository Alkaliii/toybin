@icon("res://addons/toybin/assets/sm_pra_icn.svg")
extends Resource
class_name prMatchmakingOptions 
## The MatchmakingOptions object is used to specify configurations for matchmaking in the game.

@export var waitBeforeCreatingNewRoom : float = 5000

func generate() -> Object:
	var matchMakingOptions = JavaScriptBridge.create_object("Object")
	matchMakingOptions.waitBeforeCreatingNewRoom = waitBeforeCreatingNewRoom
	
	return matchMakingOptions
