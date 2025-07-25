extends Resource
class_name pr_init_options

# https://docs.joinplayroom.com/apidocs

var gameId : String
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
#@export var defaultStates : Object #idk needs to be set differently?
#@export var defaultPlayerStates : Object #idk needs to be set differently?
@export var matchmaking : pr_matchmaking_options
@export var discord : bool = false

func generate() -> Variant:
	var initOptions = JavaScriptBridge.create_object("Object")
	initOptions.gameId = ToybinUtil.get_game_id()
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
	if matchmaking: initOptions.matchmaking = matchmaking.generate()
	initOptions.discord = discord
	
	return initOptions
