@icon("res://addons/toybin/assets/sm_tb_icn.svg")
extends Node
class_name toybinNetworkManager
## Semi Simplified Playroom RPC
## 
## Register custom RPCs using [method register_rpc].
## This node will handle packing and reception when you use [method send_rpc].
## It will automatically be configured when toybin! starts up. Some toybin! functionality relies on this node.
## NOTE: Required for automatic room size enforcement on [member initOptions.skipLobby] = [code]true[/code]
# ?add project setting to disable automatic start up

enum builtin_rpc {
	MESSAGE = 0, #sends a message from one client to another using player_id to specify recipient
	KICKED = 1, #special message that will emit a signal
	ROOM_FULL = 2, #special message that will emit a signal
	TOYRPC = 3, #sends data through RPC using toybin! formatting
}

const DEBUG_CRPC = -999
const NULL_CONTEXT = -9999

static var custom_rpcs : Dictionary[int,Callable] = {
	NULL_CONTEXT:Callable(),
	DEBUG_CRPC:Callable(_onDebug)
} #int? callable

## This function will send an rpc using toybin! standards
static func send_rpc(custom_rpc_id : int, data : Variant, recipient : String = "", mode := ToybinUtil.rpcMode.OTHERS) -> bool:
	if !custom_rpcs.has(custom_rpc_id):
		#unregistered rpc
		Ply._print_error({"unregistered rpc!":ToybinUtil.errors.UNREGISTERED_TOYRPC % str(custom_rpc_id)})
		return false
	if !mode in [0,1,2]:
		#bad mode
		Ply._print_error({"bad mode!":ToybinUtil.errors.BAD_RPC_MODE})
		return false
	
	var head = pnm_header.new(builtin_rpc.TOYRPC,custom_rpc_id,recipient)
	var payload = toybinSynchronizer.pack_data([pnm_header.convert_header(head),data])
	
	Ply.rm.RPC.call("toybin_network_manager_rpc",payload,mode)
	return true

const register_success = "RPC_ID <%s> has been registered to <%s>."
## This function helps toybin! organize your callbacks
static func register_rpc(id : int,action : Callable) -> bool:
	if id in [NULL_CONTEXT,DEBUG_CRPC]:
		#reserved id
		Ply._print_error({"reserved!":ToybinUtil.errors.RESERVED_RPC % str(id)})
		return false
	if custom_rpcs.has(id):
		#warn overwrite?
		var info = [str(id),str(custom_rpcs[id]),str(action)]
		Ply._print_error({"overwrite!":ToybinUtil.errors.WARN_RPC_OVERWRITE % info})
	
	custom_rpcs[id] == action
	Ply._print_output([register_success % [str(id),str(action)]])
	return true

class pnm_header:
	var type : builtin_rpc
	var context : int
	var recipient : String
	func _init(_type,_context,_recipient):
		type = _type
		context = _context
		_recipient = recipient
	
	static func convert_header(source : Variant):
		if source is pnm_header:
			return {
				"type":source.type,
				"context":source.context,
				"recipient":source.recipient
			}
		elif source is Dictionary: 
			return pnm_header.new(source.type,source.context,source.recipient)

func _onTNM_RPC(data) -> void:
	var unpacked_data = toybinSynchronizer.unpack_data(data[0])
	if typeof(unpacked_data) != TYPE_ARRAY:
		Ply._print_error({"bad data!":ToybinUtil.errors.BAD_DATA_ON_NETWORK,"?":str(unpacked_data)})
		return
	if !unpacked_data.size() > 0:
		Ply._print_error({"no data!":ToybinUtil.errors.NO_DATA_ON_NETWORK})
		return
	if not pnm_header.convert_header(unpacked_data[0]) is pnm_header:
		Ply._print_error({"bad data!":ToybinUtil.errors.BAD_DATA_ON_NETWORK,"?":str(unpacked_data[0])})
		return
	
	var RPC_DATA : Array = unpacked_data as Array
	var HEADER : pnm_header = pnm_header.convert_header(RPC_DATA[0]) as pnm_header
	
	if HEADER.recipient != "" and HEADER.recipient != Ply.who_am_i.id: 
		#print("ignored rpc")
		return
	
	#pnm_header.new(RPC_type (builtin_rpc),Custom_RPC_context,recipient_id)
	match HEADER.type:
		builtin_rpc.MESSAGE, builtin_rpc.KICKED, builtin_rpc.ROOM_FULL:
			#var_to_bytes([(PlayroomNetworkManager.builtin_rpc.MESSAGE,NULL_CONTEXT),Array[String]])
			if RPC_DATA.size() > 1:
				#print(RPC_DATA[1])
				if typeof(RPC_DATA[1]) == TYPE_ARRAY:
					for m in RPC_DATA[1]:
						Ply._print_output([str(m)])
				else: Ply._print_output([str(RPC_DATA[1])])
				var message_data = RPC_DATA.duplicate()
				message_data.remove_at(0)
				match HEADER.type:
					builtin_rpc.MESSAGE:
						Ply.MESSAGE.emit(message_data)
					builtin_rpc.KICKED:
						Ply.KICKED.emit(message_data)
					builtin_rpc.ROOM_FULL:
						Ply.ROOM_FULL.emit(message_data)
		builtin_rpc.TOYRPC:
			#var_to_bytes([(PlayroomNetworkManager.builtin_rpc.TOYRPC,custom_rpc_id),data (Variant)])
			if custom_rpcs.has(HEADER.context) and HEADER.context != NULL_CONTEXT:
				custom_rpcs[int(HEADER.context)].call(RPC_DATA[1])
			else:
				Ply._print_error({"unregistered rpc!":ToybinUtil.errors.UNREGISTERED_TOYRPC % str(HEADER.context)})

func _setup_network() -> void:
	Ply.rm.RPC.register("toybin_network_manager_rpc",Ply.bridgeToJS(_onTNM_RPC))
	
	#await Ply.INSERT_COIN
	#await get_tree().create_timer(1.0).timeout
	#is network running?
	#_network_status()

func _network_status() -> void:
	if Ply.connected:
		send_rpc(DEBUG_CRPC,"setup playroom network manager on %s" % Ply.who_am_i.id,Ply.who_am_i.id,ToybinUtil.rpcMode.ALL) #debug
		_send_internal_rpc(builtin_rpc.MESSAGE,["playroom network manager is running!"],Ply.who_am_i.id,ToybinUtil.rpcMode.ALL) #message up and running!
	else:
		Ply._print_output(["playroom network manager is NOT running."])

static func _onDebug(data) -> void:
	Ply._print_output(["An RPC was sent to a debug function through playroom.",str(data)])

static func _send_internal_rpc(id : builtin_rpc, data : Variant, recipient : String = "", mode := ToybinUtil.rpcMode.OTHERS):
	#this is for toybin! use at your own risk
	
	var head = pnm_header.new(id,NULL_CONTEXT,recipient)
	var payload = toybinSynchronizer.pack_data([pnm_header.convert_header(head),data])
	Ply.rm.RPC.call("toybin_network_manager_rpc",payload,mode)
