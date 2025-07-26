@icon("res://addons/toybin/assets/sm_pra_icn.svg")
extends Object
class_name prPlayerState
## A PlayerState object represents a player in the room.

#actual java script object
var javascript_object : Object
var my_joystick : prJoystickController

var id : String : 
	set(v):
		#you cannot set this.
		pass
	get():
		if !javascript_object: return ""
		return javascript_object.id

static func _convert(obj : Object) -> Object:
	if obj is prPlayerState:
		return obj.javascript_object
	else:
		var new = prPlayerState.new()
		new.javascript_object = obj
		return new

func getProfile() -> Dictionary:
	if !javascript_object: return {}
	# This might be empty if you skipLobby
	var p = javascript_object.getProfile()
	return {
		"name": p.name,
		"color": Color(str(p.color.hexString)),
		"photo": p.photo,
		"avatarIndex": p.avatarIndex
	}

func getState(key : String) -> Variant:
	## Consider using toybinSynchronizer
	if !javascript_object: return null
	if !Ply.connected: 
		Ply._print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "PlayerState.getState()"})
		return null
	
	# WARNING : You can only send Godot Primitives (String, Float, Int, Bool, Null) through Playroom
	# Certain types might need to be split up, eg. Vector2
	
	return javascript_object.getState(key)

func setState(key : String, value : Variant, reliable : bool = false) -> void:
	## Consider using toybinSynchronizer
	if !javascript_object: return
	if !Ply.connected: 
		Ply._print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "PlayerState.setState()"})
		return
	
	#reliable == true : Websocket, Slow but will send - good for things like top level game state
	#reliable == false : WebRTC, Faster but might drop - good for things like player position
	javascript_object.setState(key,value,reliable)

func kick() -> void:
	if !javascript_object: return
	Ply._kickPlayer(javascript_object)

func isBot() -> bool:
	if !javascript_object: return false
	if !Ply.connected:
		Ply._print_error({"not connected!":ToybinUtil.errors.NOT_CONNECTED % "PlayerState.isBot()"})
		return false
	return javascript_object.isBot()
