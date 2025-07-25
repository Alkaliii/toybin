extends Resource
class_name pr_matchmaking_options 

@export var waitBeforeCreatingNewRoom : float = 5000

func generate() -> Object:
	var matchMakingOptions = JavaScriptBridge.create_object("Object")
	matchMakingOptions.waitBeforeCreatingNewRoom = waitBeforeCreatingNewRoom
	
	return matchMakingOptions
