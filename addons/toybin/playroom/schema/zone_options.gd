extends Resource
class_name prZoneOptions

# ZoneOptions let's you define zones on Joystick that are triggered when player 
# drags Joystick in that zone. This behaves same as buttons above, 
# isPressed method can be used to detect if a zone button is active or not. 

@export var up : prButtonOptions
@export var down : prButtonOptions
@export var left : prButtonOptions
@export var right : prButtonOptions

func generate() -> Object:
	var zoneOptions : Object = JavaScriptBridge.create_object("Object")
	
	if up: zoneOptions.up = up.generate()
	if down: zoneOptions.down = down.generate()
	if left: zoneOptions.left = left.generate()
	if right: zoneOptions.right = right.generate()
	
	return zoneOptions

func generate_command() -> String:
	var command := "{"
	
	if up: command += str("up:",up.generate_command(),",")
	if down: command += str("down:",down.generate_command(),",")
	if left: command += str("left:",left.generate_command(),",")
	if right: command += str("right:",right.generate_command())
	
	command += "}"
	
	return command
