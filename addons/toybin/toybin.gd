@icon("res://addons/toybin/assets/sm_tb_icn.svg")
@tool
extends EditorPlugin
class_name toybinPlugin

func _enable_plugin() -> void:
	add_autoload_singleton("Ply","playroom/playroom.gd")
	add_settings()
	set_web_header()

func _get_plugin_icon():
	var p := _get_class_dir("toybinPlugin")
	return load("%s/assets/sm_tb_icn.svg" % p)

func _disable_plugin() -> void:
	remove_autoload_singleton("Ply")
	remove_settings()

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	
	# add_custom_type("Achievement", "Resource", achievements_resource, load("uid://d186rx7mxnthd"))
	add_settings()
	pass

# https://forum.godotengine.org/t/plugins-and-custom-paths/84489/6
static func _get_class_dir(classname:StringName)->String:
	var a = ProjectSettings.get_global_class_list()
	var find = a.filter(func(d): return classname == d["class"])
	var ret : String = ""
	if not find.is_empty():
		ret = find[0]["path"].get_base_dir()
	return ret

const EXPORT_PRESET_PATH = "res://export_presets.cfg"
const EXPORT_PRESET_TEMPLATE = "%s/plugin/export_preset_template.txt"
const SECTION_KEY_PRESET = "preset.%s"
const SECTION_KEY_PRESET_OPTIONS = "preset.%s.options"
const HEAD_INCLUDE_KEY = "html/head_include"
const PLYRM_HEADER = "<script src=\"https://unpkg.com/playroomkit/multiplayer.full.umd.js\" crossorigin=\"anonymous\"></script>"
const UP_TITLE = "toybin!"
const UP_MODIFY_TEXT = "Allow toybin! to modify <%s>? \ntoybin! will %s."
const UP_RESTART_TEXT = "toybin! requires the editor to restart. Your work will be saved. \nRestart editor now?"
func set_web_header() -> void:
	#attempt to create or set header in the top level web preset
	var file := FileAccess
	var config := ConfigFile.new()
	if file.file_exists(EXPORT_PRESET_PATH) and file.get_file_as_string(EXPORT_PRESET_PATH) != "":
		#file exists, add header to file
		var err = config.load(EXPORT_PRESET_PATH)
		
		if err != OK: 
			ToybinUtil._print_error({"load failed":ToybinUtil.errors.FAIL_LOAD % EXPORT_PRESET_PATH})
			return
		
		#get top level web preset
		var tl_idx : int = -1
		for i in 50:
			if config.has_section(SECTION_KEY_PRESET % str(i)):
				if config.get_value(SECTION_KEY_PRESET % str(i),"platform") == "Web":
					tl_idx = i
				else: continue
			else: break
		
		if tl_idx != -1: #found top level web preset
			insert_into_top_level_web_preset(tl_idx, config)
		else: #top level web preset does not exist
			#need to create preset
			add_preset_into_config(config)
	else:
		#ask to create?
		create_new_export_config()

func create_new_export_config():
	var rm := await request_modify("create a new <%s>" % EXPORT_PRESET_PATH)
	if !rm: return
	
	# write config using template
	var file = FileAccess
	var tpath = EXPORT_PRESET_TEMPLATE % _get_class_dir("toybinPlugin")
	if !file.file_exists(tpath):
		return
	var template := file.get_file_as_string(tpath)
	if template == "":
		ToybinUtil._print_error({"open template fail":error_string(file.get_open_error())})
		return
	
	template = template.replace("$preset_number$",str(0))
	
	# write file
	var overwrite := file.open(EXPORT_PRESET_PATH,FileAccess.WRITE)
	if overwrite == null:
		ToybinUtil._print_error({"open template fail":error_string(file.get_open_error())})
		return
	
	overwrite.store_string(template)
	overwrite.close()
	
	#requires restart
	attempt_restart()

func add_preset_into_config(config : ConfigFile):
	var rm := await request_modify("overwrite to add a preset")
	if !rm: return
	
	# turn current config into text
	var txt = config.encode_to_text()
	var file = FileAccess
	
	# append template in (as text)
	var tpath = EXPORT_PRESET_TEMPLATE % _get_class_dir("toybinPlugin")
	if !file.file_exists(tpath):
		return
	var template := file.get_file_as_string(tpath)
	if template == "":
		ToybinUtil._print_error({"open template fail":error_string(file.get_open_error())})
		return
	
	var new_preset_index : int = -1
	for i in 50:
		if config.has_section(SECTION_KEY_PRESET % str(i)):
			continue
		else: 
			new_preset_index = i
			break
	
	if new_preset_index == -1:
		#can't add lol
		ToybinUtil._print_error({"can't add preset":"You have too many presets."})
		return
	
	template = template.replace("$preset_number$",str(new_preset_index))
	txt += "\n"
	txt += template
	
	# overwrite
	var overwrite := file.open(EXPORT_PRESET_PATH,FileAccess.WRITE)
	if overwrite == null:
		ToybinUtil._print_error({"open template fail":error_string(file.get_open_error())})
		return
	
	overwrite.store_string(txt)
	overwrite.close()
	
	#requires restart
	attempt_restart()

func request_modify(modification : String) -> bool:
	request_user_permission(UP_TITLE,UP_MODIFY_TEXT % [EXPORT_PRESET_PATH,modification])
	var result : bool = await USER_PERMISSION
	if !result:
		ToybinUtil._print_output(["User denied preset modification."])
		return false
	return true

func attempt_restart() -> void:
	request_user_permission(UP_TITLE,UP_RESTART_TEXT)
	var restart_result : bool = await USER_PERMISSION
	if !restart_result: 
		ToybinUtil._print_output(["User denied editor restart."])
		return
	get_editor_interface().restart_editor(true)
	return

func insert_into_top_level_web_preset(tl_idx : int, config : ConfigFile):
	var original_head_include_value := config.get_value(SECTION_KEY_PRESET_OPTIONS % str(tl_idx),HEAD_INCLUDE_KEY)
	
	if original_head_include_value:
		if str(original_head_include_value).containsn(PLYRM_HEADER): 
			ToybinUtil._print_output(["Web Export already has header."])
			return
		var rm := await request_modify("append %s" % HEAD_INCLUDE_KEY)
		if !rm: return
		original_head_include_value += PLYRM_HEADER
		config.set_value(SECTION_KEY_PRESET_OPTIONS % str(tl_idx),HEAD_INCLUDE_KEY,original_head_include_value)
		config.save(EXPORT_PRESET_PATH)
		
		#requires restart
		attempt_restart()
	else:
		var rm := await request_modify("set %s" % HEAD_INCLUDE_KEY)
		if !rm: return
		config.set_value(SECTION_KEY_PRESET_OPTIONS % str(tl_idx),HEAD_INCLUDE_KEY,PLYRM_HEADER)
		config.save(EXPORT_PRESET_PATH)
		
		#requires restart
		attempt_restart()

signal USER_PERMISSION
func request_user_permission(request_title : String,request_text : String) -> void:
	# create dialogue
	var dialog := ConfirmationDialog.new()
	#dialog.exclusive = false
	dialog.title = request_title
	dialog.dialog_text = request_text
	
	# signals
	dialog.canceled.connect(dialog_canceled)
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog_confirmed)
	dialog.confirmed.connect(dialog.queue_free)
	
	# show
	get_last_exclusive_window().add_child(dialog)
	dialog.popup_centered()
	dialog.show()

func dialog_canceled(): USER_PERMISSION.emit(false)
func dialog_confirmed(): USER_PERMISSION.emit(true)

func _exit_tree() -> void:
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
