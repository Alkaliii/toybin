class_name ToybinUtil

const errors : Dictionary = {
	MISSING_PROJECT_SETTING = "toybin! can't operate, Please ensure all project settings were initialized. (disable and re-enable toybin!)",
	NO_WEB_NO_PLAYROOM = "Playroom is unavalible. Note, Playroom only works in Web Export.",
	NO_PLAYROOM_HEADER = "Playroom is unavalible. Note, Check [ Project > Export > 'Your Web Export Template' > HTML > Head Include ]",
	NO_GAME_ID = "toybin! is not configured properly. Please set your game id in project settings, [ Project > Project Settings > Toybin > General > Game ID ]",
	NO_GAME_ID_PATH = "toybin! is not configured properly. Please set a path in project settings, [ Project > Project Settings > Toybin > General > Game ID Env Path ]",
	FAIL_LOAD = "toybin! couldn't load <%s>",
	NO_ENV_SECTION = "toybin! couldn't find <%s> in your .env file.",
	NO_ENV_KEY = "toybin! couldn't find <%s>,<%s> in your .env file.",
	NO_GAME_ID_IN_ENV = "toybin! doesn't like the value in your .env file.",
	BAD_DATA_ON_NETWORK = "bad data was sent to PlayroomNetworkManager, please follow format.",
	NO_DATA_ON_NETWORK = "an empty payload was received in PlayroomNetworkManager!",
	UNREGISTERED_TOYRPC = "toybin! rpc <%s> is not registered. This RPC call will not do anything.",
	WARN_RPC_OVERWRITE = "RPC_ID <%s> was overwritten from <%s> to <%s>.",
	RESERVED_RPC = "RPC_ID <%s> is reserved by toybin! and can't be used.",
	BAD_RPC_MODE = "Passed invalid rpc mode. Check your RPC calls.",
	HOST_TRANSFER_FAIL = "Failure to transfer host to unavalible target (not in room).",
	NOT_CONNECTED = "toybin! cannot process this request (%s) when not connected to a session."
}

const suggestions : Dictionary = {
	SET_HEAD_INCLUDE = "Make sure this is set in <Head Include>: <script src=\"https://unpkg.com/playroomkit/multiplayer.full.umd.js\" crossorigin=\"anonymous\"></script>",
	SET_EXPORT_FILTER = "Make sure you include the file type for your enviroment variables in the non-resource export filter.",
}

const rpcMode : Dictionary = {
	ALL = 0, #Will send to all clients including host and caller
	OTHERS = 1, #Will send to all clients except caller
	HOST = 2 #Will send to the host
}

const env_section := "playroom/enviroment_variables"
const env_key := "gameId"
static func get_game_id() -> String:
	var env_path : String = ProjectSettings.get_setting("toybin/general/game_id_env_path")
	var id : String = ProjectSettings.get_setting("toybin/general/game_id")
	
	if env_path != "":
		#get game id from config file
		var config = ConfigFile.new()
		var err = config.load(env_path)
		
		#NOTE ensure you have .env in the non-resource export filter
		if err != OK:
			Ply._print_error({"Bad Env Path":errors.FAIL_LOAD % env_path,
			"No export filter?":suggestions.SET_EXPORT_FILTER})
			return ""
		
		#config env file exists
		if !config.has_section(env_section):
			Ply._print_error({"Bad Env Section":errors.NO_ENV_SECTION % env_section})
			return ""
		
		if !config.has_section_key(env_section,env_key):
			Ply._print_error({"Bad Env Key":errors.NO_ENV_KEY % [env_section,env_key]})
			return ""
		
		#config value exists
		var v = config.get_value(env_section,env_key)
		if v == null:
			Ply._print_error({"Bad Env Value":errors.NO_GAME_ID_IN_ENV})
			return ""
		
		return str(v)
	else:
		#get game id from project settings
		if id == null or id == "0":
			Ply._print_error({"No game id":ToybinUtil.errors.NO_GAME_ID})
			return ""
		
		return id
