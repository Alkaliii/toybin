extends Object
class_name prJoystickController

# Renders a Joystick Controller on screen using Playroom

var javascript_object : Object
var js_property : String

#Anthropic Claude Sonnet 4, July 25 2025 (assigning to window.)
const command := "window.%s = new Playroom.Joystick(%s,%s);"
#https://stackoverflow.com/questions/8668174/indexof-method-in-an-object-array
const getStateCommand := "Playroom.getParticipants()[Playroom.getParticipants().findIndex(i => i.id === \"%s\")]"
static func create_joystick(state : prPlayerState, options : prJoystickOptions) -> prJoystickController:
	#var joystick = JavaScriptBridge.create_object("Playroom.Joystick", state.javascript_object, options.generate())
	
	var jid := str("joy_",state.id).validate_filename().replace("-","_")
	var full_command = command % [jid,getStateCommand % state.id,options.generate_command()]
	#var full_command = command % ["Playroom.me()",options.generate_command()]
	#print(full_command)
	JavaScriptBridge.eval(full_command) #create
	#var joystick = JavaScriptBridge.eval(full_command)
	var joystick = JavaScriptBridge.get_interface(jid)
	var new := prJoystickController.new()
	
	new.javascript_object = joystick
	new.js_property = jid
	state.my_joystick = new
	return state.my_joystick

func isPressed(id : String) -> bool:
	if !javascript_object: return false
	return javascript_object.isPressed(id)

func isJoystickPressed() -> bool:
	if !javascript_object: return false
	return javascript_object.isJoystickPressed()

func angle() -> float:
	if !javascript_object: return 0.0
	return javascript_object.angle()

func vector() -> Vector2:
	#returns angular result as vector2
	var rad := angle()
	return Vector2(sin(rad),cos(rad))

func degree() -> float:
	#returns angular result as 0-360 degree angle
	return ((angle() * 180) / PI) + 90

func dpad() -> Vector2:
	if !javascript_object: 
		return Vector2.ZERO
	var dpad_string = javascript_object.dpad()
	#print(dpad_string.x,"/",dpad_string.y)
	var dir = Vector2.ZERO
	match dpad_string.x:
		"left": dir.x = -1.0
		"right": dir.x = 1.0
	match dpad_string.y:
		"up": dir.y = 1.0
		"down": dir.y = -1.0
	return dir

var destroy_command = "delete window.%s;" #Anthropic Claude Sonnet 4, July 25 2025
func destroy() -> void:
	if !javascript_object: return
	javascript_object.destroy()
	JavaScriptBridge.eval(destroy_command % js_property)
	javascript_object = null
	#self.free()
