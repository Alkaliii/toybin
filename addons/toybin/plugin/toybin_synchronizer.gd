extends Object
class_name toybinSynchronizer
## Call me to pack or unpack data sent using toybin!
##
## You can also call me with an identifier to synchronize data on a node

## Packs most variant types into a format playroom will transmit.
## Will not pack objects, since that isn't safe.
static func pack_data(data : Variant) -> String:
	#will not pack objects.
	if data is Object:
		ToybinUtil._print_output(["WARNING: toybin will not pack objects correctly by default. <%s>" % str(data)])
	
	var dat := var_to_bytes(data).hex_encode()
	return dat

## Unpacks data back into variants that was originally packed by this node
## Objects will be unpacked into junk.
static func unpack_data(data : String) -> Variant:
	var dat := bytes_to_var(data.hex_decode())
	return dat

## Creates state for [method pull_sync] to pull from.
static func push_sync(
	identifier : String, 
	variables : Dictionary, 
	source : Object, 
	reliable : bool = true, 
	on_player : Object = null) -> void:
	#calls set state
	#NOTE ensure identifier is unique, or you will override your data
	
	#create data
	var dat : Dictionary = {}
	for v in variables:
		if str(v) in source:
			var sdat = source[str(v)]
			#check for objects?
			if sdat is Object:
				ToybinUtil._print_output(["WARNING: toybin will not pack objects correctly by default. <%s>.<%s>" % [str(source),v]])
			dat[v] = sdat
	
	#pack data
	var packdat := pack_data(dat)
	
	if on_player: 
		#Ply.setStateOnPlayer(on_player,identifier,packdat,reliable)
		if on_player is prPlayerState:
			on_player.setState(identifier,packdat,reliable)
		else:
			var converted_player : prPlayerState = prPlayerState._convert(on_player)
			converted_player.setState(identifier,packdat,reliable)
	else: Ply.setState(identifier,packdat,reliable)

## Pulls state and assign the values automatically on source
static func pull_sync( #make another function that pulls without setting
	identifier : String,
	source : Object,
	on_player : Object = null) -> void:
	#calls get state
	#sets the variables on source
	
	#get data
	var packdat : String
	if on_player: packdat = Ply.getStateOnPlayer(on_player,identifier)
	else: packdat = Ply.getState(identifier)
	
	#unpack data
	var dat = unpack_data(packdat)
	
	for v in dat:
		if str(v) in source:
			source[str(v)] = dat[v]
