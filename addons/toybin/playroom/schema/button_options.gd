@icon("res://addons/toybin/assets/sm_pra_icn.svg")
extends Resource
class_name prButtonOptions
## Configuration for on screen buttons

@export var id : String
@export var label : String = ""
@export var icon : String

func generate() -> Object:
	var buttonOptions : Object = JavaScriptBridge.create_object("Object")
	buttonOptions.id = id
	buttonOptions.label = label
	if icon: buttonOptions.icon = icon
	
	return buttonOptions


func generate_command() -> String:
	var command := "{"
	
	command += str("id:","\"",id,"\",")
	command += str("label:","\"",label,"\",")
	if icon: command += str("icon:","\"",icon,"\"")
	
	command += "}"
	
	return command
