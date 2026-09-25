extends Node3D

const RUN_ANIMATION = "run_anim/mixamo_com"
const JUMP_ANIMATION = "jump_anim/mixamo_com"
const IDLE_ANIMATION = "idle_anim/mixamo_com"
#const RUN_ANIMATION = "run_anim"

@export var playerAnimationPlayer:AnimationPlayer

var isAnyKeyPressed=false
var isForwardPressed=false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print("Available animations:", playerAnimationPlayer.get_animation_list())
	#InputManager.leftKeyPressed.connect(_onLeftKeyPressed)
	#InputManager.leftKeyPressed.connect(_onRightKeyPressed)
	InputManager.jumpKeyPressed.connect(_onJumpKeyPressed)
	InputManager.forwardKeyPressed.connect(_onForwardKeyPressed)
	InputManager.backwardKeyPressed.connect(_onBackwardKeyPressed)
	
	#InputManager.leftKeyReleased.connect(_onJumpKeyReleased)
	InputManager.forwardKeyReleased.connect(_onForwardKeyReleased)
	InputManager.backwardKeyReleased.connect(_onBackwardKeyReleased)
	

func _onForwardKeyPressed():
	isForwardPressed=true
	playerAnimationPlayer.play(RUN_ANIMATION, 0 ,.8)
	isAnyKeyPressed=true
func _onForwardKeyReleased():
	isAnyKeyPressed=false
	isForwardPressed=false
	#playerAnimationPlayer.stop()

func _onBackwardKeyPressed():
	isAnyKeyPressed=true
	pass
func _onBackwardKeyReleased():
	isAnyKeyPressed=false
	#playerAnimationPlayer.stop()
	
func _onJumpKeyPressed():
	isAnyKeyPressed=true
	playerAnimationPlayer.play(JUMP_ANIMATION,-1,1.5)
	await playerAnimationPlayer.animation_finished
	#isAnyKeyPressed=false
	if(isForwardPressed):_onForwardKeyPressed()




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(!isAnyKeyPressed):
		playerAnimationPlayer.play(IDLE_ANIMATION)
	pass
