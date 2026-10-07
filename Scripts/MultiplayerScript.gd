extends Node3D

var peer = ENetMultiplayerPeer.new()
var port = 1000

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.on_Host_Pressed.connect(on_Host_Pressed)
	EventBus.on_Host_Pressed.connect(on_Join_Pressed)
	pass # Replace with function body.

func on_Host_Pressed():
	print("Hello Host")
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(peer_added)
	

func on_Join_Pressed():
	print("Hello Client")
	peer.create_client("localhost",port)
	multiplayer.multiplayer_peer = peer
	#multiplayer.peer_connected.connect(peer_added)

func peer_added(pid):
	print("player " + pid +" joined")
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
