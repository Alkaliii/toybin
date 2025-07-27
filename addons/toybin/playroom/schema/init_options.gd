@icon("res://addons/toybin/assets/sm_pra_icn.svg")
extends Resource
class_name prInitOptions
## Configuration for how Playroom should operate
##
## [url]https://docs.joinplayroom.com/apidocs[/url]

var gameId : String
@export var override_game_id : String ## Not Recommended
@export var streamMode : bool = false
@export var liveMode : String
@export var allowGamepads : bool = false
@export var baseUrl : String
@export var avatars : Array[String]
@export var enableBots : bool = false
#@export var botOptions #idk
@export var roomCode : String
@export var skipLobby : bool = false
@export var reconnectGracePeriod : float = 0
@export var maxPlayersPerRoom : float
@export var defaultStates : Dictionary
@export var defaultPlayerStates : Dictionary
@export var matchmaking : prMatchmakingOptions
@export var discord : bool = false

func generate() -> Object:
	var initOptions : Object = JavaScriptBridge.create_object("Object")
	if !override_game_id:
		initOptions.gameId = ToybinUtil.get_game_id()
	else: initOptions.gameId = override_game_id
	initOptions.streamMode = streamMode
	if liveMode: initOptions.liveMode = liveMode
	initOptions.allowGamepads = allowGamepads
	if baseUrl: initOptions.baseUrl = baseUrl
	if avatars: initOptions.avatars = avatars
	initOptions.enableBots = enableBots
	if roomCode: initOptions.roomCode = roomCode
	initOptions.skipLobby = skipLobby
	initOptions.reconnectGracePeriod = reconnectGracePeriod
	if maxPlayersPerRoom and !skipLobby: initOptions.maxPlayersPerRoom = maxPlayersPerRoom
	
	if defaultStates:
		var dS : Object = JavaScriptBridge.create_object("Object")
		for s in defaultStates:
			dS[s] = defaultStates[s]
		initOptions.defaultStates = dS
	
	if defaultPlayerStates:
		var dPS : Object = JavaScriptBridge.create_object("Object")
		for s in defaultPlayerStates:
			dPS[s] = defaultPlayerStates[s]
		initOptions.defaultPlayerStates = dPS
	
	if matchmaking: initOptions.matchmaking = matchmaking.generate()
	initOptions.discord = discord
	
	return initOptions
