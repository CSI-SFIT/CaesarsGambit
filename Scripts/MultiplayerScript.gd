extends Node3D

var peer = ENetMultiplayerPeer.new()
var port = 1000
#@onready var gm = $GameManager

var player_scene = preload("res://Scenes/player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#EventBus.on_Host_Pressed.connect(on_Host_Pressed_main)
	#EventBus.on_Join_Pressed.connect(on_Join_Pressed_main)
	
	match EventBus.selected_role:
		EventBus.Role.HOST:
			start_host()
		EventBus.Role.CLIENT:
			start_client()
		_:
			print("No multiplayer role selected")
			
	#print("Events connected in main Scene")
	pass # Replace with function body.
func start_host():
	print("Hello Host")
	var error = peer.create_server(port)
	if error != OK:
		print("Failed to host: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(peer_added)
	
	GameManager.refreshSpawnPoints()
	
	peer_added(multiplayer.get_unique_id())
	
func start_client():
	print("Hello Client")
	var error = peer.create_client("localhost", port)
	if error != OK:
		print("Failed to connect: ", error)
		return
	multiplayer.multiplayer_peer = peer
	#multiplayer.peer_connected.connect(peer_added)

func peer_added(pid):
	#await get_tree().process_frame
	print("player " + str(pid) +" joined")
	var p = player_scene.instantiate()
	p.name = str(pid)
	
	add_child(p)
	p.global_position = GameManager.getSpawnPointPosition(GameManager.SpawnPointNames.Church)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
