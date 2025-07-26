extends Node
class_name toybinTestingSuite

# tests encapsulations on Ply
# maybe does more?

const test_success := "Method %s performed as expected."
const test_failure := "Method %s did not perform as expected."

func test_insert_coin() -> bool:
	var method := "Ply.insertCoin()"
	
	Ply.insertCoin()
	await get_tree().create_timer(0.25).timeout
	
	# insertCoin should set Ply.connected in the given timeframe
	
	if Ply.connected: return good(method)
	else: return bad(method)

func test_state() -> bool:
	var method := "Ply.setState() & Ply.getState()"
	var state_key := "testState"
	
	Ply.setState(state_key,true)
	await get_tree().create_timer(0.25).timeout
	
	# getState and setState should properly set and get in the given timeframe
	
	if Ply.getState(state_key): return good(method)
	else: return bad(method)

func test_reset_state() -> bool:
	var method := "Ply.resetStates()"
	var state_key_a := "testState"
	var state_key_b := "testStateB"
	
	Ply.setState(state_key_a,8)
	Ply.setState(state_key_b,true)
	await get_tree().create_timer(0.125).timeout
	Ply.resetStates([state_key_b])
	await get_tree().create_timer(0.125).timeout
	
	# resetStates should properly reset all states except excluded in the given timeframe
	
	if Ply.getState(state_key_a) == null and Ply.getState(state_key_b): return good(method)
	else: return bad(method)

func test_reset_players_state() -> bool:
	var method := "Ply.resetPlayersStates()"
	var state_key_a := "testPlayerState"
	var state_key_b := "testPlayerStateB"
	var player := Ply.who_am_i
	
	player.setState(state_key_a,8)
	player.setState(state_key_b,true)
	await get_tree().create_timer(0.125).timeout
	Ply.resetPlayersStates([state_key_b])
	await get_tree().create_timer(0.125).timeout
	
	# resetPlayersStates should properly reset all states except excluded in the given timeframe
	
	if player.getState(state_key_a) == null and player.getState(state_key_b): return good(method)
	else: return bad(method)

func test_host_methods() -> bool:
	# This test requires two players in room and must be performed on host
	var method_a := "isHost()"
	var method_b := "transferHost()"
	var method_both := "isHost() & transferHost()"
	
	var player_a := Ply.who_am_i
	var player_b : prPlayerState
	for p in Ply.connected_players:
		if Ply.connected_players[p].id != player_a.id:
			player_b = Ply.connected_players[p]
	
	if Ply.isHost():
		Ply.transferHost(player_b.id)
	else: return bad(method_a) #test expects player_a (who_am_i) to be host originally
	await get_tree().create_timer(0.25).timeout
	
	# isHost should report host in the given timeframe
	# transferHost should transfer host from player_a to player_b in the given timeframe
	
	if !Ply.isHost(): return good(method_both)
	else: return bad(method_b) #host didn't transfer

static func good(method : String) -> bool:
		Ply._print_output([test_success % method])
		return true

static func bad(method : String) -> bool:
	Ply._print_error({"test failed":test_failure % method})
	return false
