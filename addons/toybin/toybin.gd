@tool
extends EditorPlugin

func _enable_plugin() -> void:
	add_autoload_singleton("Ply","playroom/playroom.gd")
	add_settings()

func _get_plugin_icon():
	return preload("res://addons/toybin/assets/sm_tb_icn.svg")

func _disable_plugin() -> void:
	remove_autoload_singleton("Ply")
	remove_settings()

func _enter_tree():
	# Initialization of the plugin goes here.
	
	# add_custom_type("Achievement", "Resource", achievements_resource, load("uid://d186rx7mxnthd"))
	add_settings()
	pass

func _exit_tree():
	# Clean-up of the plugin goes here.
	
	# remove_custom_type("Achievement")
	pass

func add_settings() -> void:
	if not ProjectSettings.has_setting("toybin/debug/print_errors"):
		ProjectSettings.set_setting("toybin/debug/print_errors", true)
	if not ProjectSettings.has_setting("toybin/debug/print_output"):
		ProjectSettings.set_setting("toybin/debug/print_output", true)
	if not ProjectSettings.has_setting("toybin/general/game_id"):
		ProjectSettings.set_setting("toybin/general/game_id", "0")
	if not ProjectSettings.has_setting("toybin/general/game_id_env_path"):
		ProjectSettings.set_setting("toybin/general/game_id_env_path", "")
	#if not ProjectSettings.has_setting("milestone/general/save_as_json"):
		#ProjectSettings.set_setting("milestone/general/save_as_json", true)

	ProjectSettings.save()

func remove_settings() -> void:
	if ProjectSettings.has_setting("toybin/debug/print_errors"):
		ProjectSettings.set_setting("toybin/debug/print_errors", null)
	if ProjectSettings.has_setting("toybin/debug/print_output"):
		ProjectSettings.set_setting("toybin/debug/print_output", null)
	if ProjectSettings.has_setting("toybin/general/game_id"):
		ProjectSettings.set_setting("toybin/general/game_id", null)
	if ProjectSettings.has_setting("toybin/general/game_id_env_path"):
		ProjectSettings.set_setting("toybin/general/game_id_env_path", null)
	
	ProjectSettings.save()
