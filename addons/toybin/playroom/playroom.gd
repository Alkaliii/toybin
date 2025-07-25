extends Node

# I provide simple functions for working with Playroom

# ATTENTION, please copy and paste the following line into your web export preset:
# <script src="https://unpkg.com/playroomkit/multiplayer.full.umd.js" crossorigin="anonymous"></script>

# Call Ply.rm from any script to talk to playroom directly!
static var rm : Object = JavaScriptBridge.get_interface("Playroom") : 
	set(value):
		rm = value
		if rm == null or !rm: 
			if !OS.has_feature("web"):
				_print_error({"Can't set() rm":ToybinUtil.errors.NO_WEB_NO_PLAYROOM})
			else:
				_print_error({"Can't set() rm":ToybinUtil.errors.NO_PLAYROOM_HEADER,
				"No head include?":ToybinUtil.suggestions.SET_HEAD_INCLUDE})
	get():
		if rm == null or !rm: 
			if !OS.has_feature("web"):
				_print_error({"Can't get() rm":ToybinUtil.errors.NO_WEB_NO_PLAYROOM})
			else:
				_print_error({"Can't get() rm":ToybinUtil.errors.NO_PLAYROOM_HEADER,
				"No head include?":ToybinUtil.suggestions.SET_HEAD_INCLUDE})
		return rm

#class pr_player:
	#var id : String
	#var state
	#func _init(_id : String, _state):
		#id = _id
		#state = state

static var who_am_i : prPlayerState
static var current_init_options : prInitOptions
static var connected_players : Dictionary[String,prPlayerState] = {}
static var connected : bool = false
static var network_manager : toybinNetworkManager

signal INSERT_COIN
signal SESSION_END
signal DISCONNECTED
signal PLAYER_JOIN
signal PLAYER_QUIT
signal ROOM_FULL
signal KICKED
signal MESSAGE
signal TIKTOK_EVENT

const ic_sucess = "Client initialized, %s. Access with <Ply.who_am_i>"
func insertCoin(initOptions : prInitOptions = null) -> void:
	JavaScriptBridge.eval("")
	if !initOptions or initOptions == null:
		initOptions = prInitOptions.new()
	
	current_init_options = initOptions
	rm.insertCoin(initOptions.generate(), bridgeToJS(_onInsertCoin))
	await Ply.PLAYER_JOIN
	
	var player := myPlayer()
	who_am_i = player
	
	_print_output([ic_sucess % who_am_i.id])
	network_manager._network_status()

func getState(key : String) -> Variant:
	## Consider using PlayroomSynchronizer
	if !connected:
		_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "getState()"})
		return null
	return rm.getState(key)

func setState(key : String, value : Variant, reliable : bool = true) -> void:
	## Consider using PlayroomSynchronizer
	if !connected: 
		_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "setState()"})
		return
	
	# WARNING : You can only send Godot Primitives (String, Float, Int, Bool, Null) through Playroom
	# Certain types might need to be split up, eg. Vector2
	
	#reliable == true : Websocket, Slow but will send - good for things like top level game state
	#reliable == false : WebRTC, Faster but might drop - good for things like player position
	rm.setState(key,value,reliable)

## TODO Write Test
func resetStates(exclude : Array[String]) -> void:
	if !connected: 
		_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "resetStates()"})
		return
	
	if exclude: rm.resetStates(exclude)
	else: rm.resetStates()

func isHost() -> bool:
	if !connected: 
		_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "isHost()"})
		return false
	return rm.isHost()

const th_success = "Host privileges transfered to %s"
func transferHost(new_host_id : String) -> void:
	if !isHost(): return
	if !connected_players.has(new_host_id): 
		_print_error({"transfer fail!":ToybinUtil.errors.HOST_TRANSFER_FAIL})
		return
	
	rm.transferHost(new_host_id)
	_print_output([th_success % new_host_id])

func isStreamScreen() -> bool:
	if !connected: 
		_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "isStreamScreen()"})
		return false
	return rm.isStreamScreen()

func getRoomCode() -> String:
	if !connected: 
		_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "getRoomCode()"})
		return ""
	return rm.getRoomCode()

func startMatchmaking() -> void:
	if !connected:
		_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "startMatchmaking()"})
		return
	rm.startMatchmaking()

#func addBot() -> void:
	#idk how this works sorry.

func myPlayer() -> prPlayerState:
	if !connected:
		_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "myPlayer()"})
		return null
	return prPlayerState._convert(rm.myPlayer())

func me() -> prPlayerState:
	return myPlayer()

func waitForState(key : String, callback : Callable = dummy_callback, timeout := 1000.0) -> Variant:
	if !connected:
		_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "waitForState()"})
		return null
	
	# completes after state is set to a truthy value
	# Custom implementation, since you can't await for JS stuff?
	var delta := 0.0
	var s : Variant
	while delta < timeout:
		s = getState(key)
		if s and bool(s):
			if callback != dummy_callback:
				callback.call(s)
			print(s)
			return s
		
		delta += get_process_delta_time()
		await get_tree().process_frame
	return null
	#if callback != dummy_callback:
		#return await rm.waitForState(key,bridgeToJS(callback))
	#return await rm.waitForState(key)

func waitForPlayerState(player : Object, key : String, callback : Callable = dummy_callback, timeout := 1000.0) -> Variant:
	if !connected:
		_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "waitForPlayerState()"})
		return null
	
	# completes after state is set to a truthy value
	# Custom implementation, since you can't await for JS stuff?
	var delta := 0.0
	var s : Variant
	while delta < timeout:
		s = player.getState(key)
		if s and bool(s):
			if callback != dummy_callback:
				callback.call(s)
			return s
		
		delta += get_process_delta_time()
		await get_tree().process_frame
	return null
	
	#if callback != dummy_callback:
		#return await rm.waitForState(player,key,bridgeToJS(callback))
	#return await rm.waitForState(player,key)

#region RPC METHODS
static func RPCregister(rpc_name : String, callback : Callable) -> void:
	# NOTE use this if you don't like toybin's system
	## toybin offers a similar system that functions through a single callback.
	## -> link to doc?
	if !connected:
		_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "RPC.register()"})
		return
	
	rm.RPC.register(rpc_name,bridgeToJS(callback))

static func RPCcall(rpc_name : String, data : Variant, mode := ToybinUtil.rpcMode.OTHERS, response_callback : Callable = dummy_callback) -> void:
	# NOTE use this if you don't like toybin's system
	## toybin offers a similar system that functions through a single callback.
	## it can specifiy a specific recipient, and will pack you data for you.
	## -> link to doc?
	if !connected:
		_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "RPC.call()"})
		return
	
	# WARNING : You can only send Godot Primitives (String, Float, Int, Bool, Null) through Playroom RPC
	# Certain types might need to be split up, eg. Vector2
	
	if response_callback != dummy_callback:
		rm.RPC.call(rpc_name,data,mode,bridgeToJS(response_callback))
	else: rm.RPC.call(rpc_name,data,mode)

#endregion

#region PLAYERSTATE METHODS
#func getProfileOnPlayer(player : Object) -> Dictionary:
	## This might be empty if you skipLobby
	#var p = player.getProfile()
	#return {
		#"name": p.name,
		#"color": Color(str(p.color.hexString)),
		#"photo": p.photo,
		#"avatarIndex": p.avatarIndex
	#}

#func getStateOnPlayer(player : Object, key : String) -> Variant:
	### Consider using PlayroomSynchronizer
	#if !connected: 
		#_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "PlayerState.getState()"})
		#return null
	#
	#return player.getState(key)

#func setStateOnPlayer(player : Object, key : String, value : Variant, reliable : bool = false) -> void:
	### Consider using PlayroomSynchronizer
	#if !connected: 
		#_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "PlayerState.setState()"})
		#return
	#
	##reliable == true : Websocket, Slow but will send - good for things like top level game state
	##reliable == false : WebRTC, Faster but might drop - good for things like player position
	#player.setState(key,value,reliable)

#func isPlayerBot(player : Object) -> bool:
	#if !connected:
		#_print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "PlayerState.isBot()"})
		#return false
	#return player.isBot()
#endregion

func openDiscordInviteDialog() -> void:
	#only avalible inside discord, as a discord activity?
	rm.openDiscordInviteDialog()

#func getDiscordClient():
	#yea idk bro

func getDiscordAccessToken() -> String:
	return rm.getDiscordAccessToken()

func getCurrentURL() -> String:
	var url : String = JavaScriptBridge.eval("window.location.href")
	return url

# Keep a reference to the callback so it doesn't get garbage collected
static var jsBridgeReferences : Array[JavaScriptObject] = []
static func bridgeToJS(cb : Callable) -> JavaScriptObject:
	var jsCallback := JavaScriptBridge.create_callback(cb)
	jsBridgeReferences.push_back(jsCallback)
	return jsCallback

const kp_success = "Kicking player, %s."
func kick(player_id : String, reason : String = "") -> void:
	#ability to send message to kicked client (kick reason)
	if !isHost(): return
	var kicked_player = connected_players[player_id]
	#
	#_print_output([kp_success % player_id])
	#
	#var message : Array[String] = ["You have been kicked."]
	#if reason and reason != "": message.append(str("Reason: ",reason))
	#PlayroomNetworkManager._send_internal_rpc(PlayroomNetworkManager.builtin_rpc.KICKED,message,player_id)
	#
	kicked_player.kick()

#region INTERNAL METHODS
func _kickPlayer(player_state, reason : String = "", room_full : bool = false) -> void:
	#ability to send message to kicked client (kick reason)
	if !isHost(): return
	
	var type = toybinNetworkManager.builtin_rpc.KICKED
	if room_full: type = toybinNetworkManager.builtin_rpc.ROOM_FULL
	
	var message : Array[String] = ["You have been kicked."]
	if reason and reason != "": message.append(str("		Reason: ",reason))
	toybinNetworkManager._send_internal_rpc(type,message,player_state.id)
	
	_print_output([kp_success % player_state.id])
	player_state.kick()

func _onInsertCoin(_args) -> void:
	connected = true
	rm.onPlayerJoin(bridgeToJS(_onPlayerJoin))
	rm.onDisconnect(bridgeToJS(_onDisconnect))
	rm.onTikTokLiveEvent(bridgeToJS(_onTikTokLiveEvent))
	Ply.INSERT_COIN.emit(_args)
	_print_output([str("Coin Inserted! room code : ",rm.getRoomCode())])

func _onPlayerJoin(args):
	var state = args[0]
	if _roomFull(state):
		if isHost(): 
			_kickPlayer(state,"Room is full!",true)
		return
	
	var recon : String = ""
	if !connected_players.has(state.id):
		Ply.PLAYER_JOIN.emit(args)
	else: recon = "(Reconnect)"
	_print_output([str("Player Joined! ",recon," pid : ",state.id)])
	
	connected_players[state.id] = prPlayerState._convert(state)
	state.onQuit(bridgeToJS(_onPlayerQuit))

func _roomFull(new_player) -> bool:
	if !current_init_options.skipLobby: return false
	if !current_init_options.maxPlayersPerRoom: return false
	if new_player.id in connected_players.keys(): 
		#reconnect
		return false
	if connected_players.size() == current_init_options.maxPlayersPerRoom:
		#room full
		_print_output(["This room is full!"])
		#if new_player.id == myPlayer().id:
			#Ply.ROOM_FULL.emit()
		return true
	return false

func _onPlayerQuit(args):
	var state = args[0]
	connected_players.erase(state.id)
	
	_print_output([str("Player Quit! pid : ",state.id)])
	Ply.PLAYER_QUIT.emit(args)

const dc_success = "You have disconnected from the room <%s>."
func _onDisconnect(args):
	#JavaScriptBridge.get_interface("console").log(args.code)
	connected = false
	connected_players.clear()
	_print_output([dc_success % current_init_options.roomCode]) #% [str(args.code),str(args.reason)]
	Ply.DISCONNECTED.emit(args)

func _onTikTokLiveEvent(args):
	_print_output(["recevied tiktokEvent"])
	Ply.TIKTOK_EVENT.emit(args)

func _setup_network_manager():
	if network_manager:
		remove_child(network_manager)
		network_manager.queue_free()
	
	var n = toybinNetworkManager.new()
	add_child(n)
	network_manager = n
	n._setup_network()

var d : float
func _process(delta):
	d += delta
	if d > 1.0:
		d = 0.0
	if Input.is_action_just_pressed("ui_left"):
		setState("testState",true)
	if Input.is_action_just_pressed("ui_right"):
		setState("testState",false)

var j : prJoystickController
func _ready():
	var s := _status(false)
	_print_output([str("is running? : ",s)])
	
	if s:
		await get_tree().create_timer(1.5)
		var t := prInitOptions.new()
		t.roomCode = "9999"
		t.maxPlayersPerRoom = 2
		t.skipLobby = true
		await insertCoin(t)
		var jo := prJoystickOptions.new()
		jo.keyboard = false
		j = prJoystickController.create_joystick(who_am_i,jo)

# NOTE for debugging plugin
const ignore_bad_game_id := false
const ignore_bad_game_id_path := false
func _status(with_output : bool = true) -> bool:
	# ensure playroom is working
	var t = get("rm")
	if !t or t == null:
		return false
	
	_print_output(["Playroom <Ply.rm> is avalible."])
	
	if ProjectSettings.has_setting("toybin/general/game_id"):
		if ProjectSettings.get_setting("toybin/general/game_id_env_path") == "":
			# check setting
			var tgid : String = ProjectSettings.get_setting("toybin/general/game_id")
			if !tgid or (tgid == null) or (tgid == "0" and !ignore_bad_game_id):
				_print_error({"No game id":ToybinUtil.errors.NO_GAME_ID})
				return false
		elif !ignore_bad_game_id_path:
			#check path
			var tgidep : String = ProjectSettings.get_setting("toybin/general/game_id_env_path")
			if !str(tgidep).is_absolute_path():
				_print_error({"No game id env path":ToybinUtil.errors.NO_GAME_ID_PATH})
				return false
	else:
		#settings didn't init? crit fail
		_print_error({"Failure!":ToybinUtil.errors.MISSING_PROJECT_SETTING})
		return false
	
	if !network_manager: _setup_network_manager()
	if with_output: _print_output(["Success!"])
	
	return true

static func dummy_callback() -> void:
	return

const error_format = "[toybin/ %s] %s"
static func _print_error(error_messages : Dictionary[String,String]) -> void:
	# [ERROR: <dic_key>] <dic_value>
	if !ProjectSettings.get_setting("toybin/debug/print_errors"): return
	for e in error_messages:
		var short = e
		var long = error_messages[e]
		printerr(error_format % [short,long])

static func _print_output(output_messages : Array[String]) -> void:
	if !ProjectSettings.get_setting("toybin/debug/print_output"): return
	for o in output_messages:
		print("[toybin!] ",o)
#endregion
