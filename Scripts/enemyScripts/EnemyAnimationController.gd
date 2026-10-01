extends Node3D

const RUN_ANIMATION = "run_anim/mixamo_com"
const WALK_ANIMATION= "walk_anim/mixamo_com"
const IDLE_ANIMATION = "idle_anim/mixamo_com"

@onready var enemy: = $".."
@onready var enemyAnimationPlayer = $AnimationPlayer2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(!enemy.isPlayerDetected() and !enemy.isEnemyWaiting()):
		enemyAnimationPlayer.play(WALK_ANIMATION)
	elif(!enemy.isPlayerDetected() and enemy.isEnemyWaiting()):
		enemyAnimationPlayer.play(IDLE_ANIMATION)
	elif(enemy.isPlayerDetected()):
		enemyAnimationPlayer.play(RUN_ANIMATION)
