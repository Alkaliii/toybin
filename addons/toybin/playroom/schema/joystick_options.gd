@icon("res://addons/toybin/assets/sm_pra_icn.svg")
extends Resource
class_name prJoystickOptions
## Settings for Joystick Configuration
##
## NOTE: Joystick will not appear when keyboard is set to true

enum JOYTYPE {
	ANGULAR,
	DPAD
}
@export var type : JOYTYPE = JOYTYPE.ANGULAR
@export var buttons : Array[prButtonOptions] = []
@export var zones : prZoneOptions
@export var keyboard : bool = true #Will enable WASD input

func generate() -> Object:
	var joystickOptions : Object = JavaScriptBridge.create_object("Object")
	
	match type:
		JOYTYPE.ANGULAR: joystickOptions.type = "angular"
		JOYTYPE.DPAD: joystickOptions.type = "dpad"
	
	if !buttons.is_empty():
		var buttonArray = JavaScriptBridge.create_object("Array")
		for b : prButtonOptions in buttons:
			buttonArray.push(b.generate())
		
		joystickOptions.buttons = buttonArray
	
	if zones: joystickOptions.zones = zones.generate()
	
	joystickOptions.keyboard = keyboard
	
	return joystickOptions

func generate_command() -> String:
	var command := "{"
	
	var type_value
	match type:
		JOYTYPE.ANGULAR: type_value = "angular"
		JOYTYPE.DPAD: type_value = "dpad"
	command += str("type:","\"",type_value,"\",")
	
	if !buttons.is_empty():
		command += str("buttons: [")
		var idx := -1
		for b : prButtonOptions in buttons:
			idx += 1
			command += b.generate_command()
			if idx < (buttons.size() - 1):
				command += str(",")
			else:
				command += str("],")
	
	if zones: command += str("zones:",zones.generate_command(),",")
	
	command += str("keyboard:",str(keyboard))
	
	command += "}"
	
	return command
