extends OmniLight3D

var base_energy: float
var time_passed: float = 0.0

func _ready():
	# Remember the energy we set in the inspector (2.0)
	base_energy = light_energy

func _process(delta):
	# Speed of the flicker
	time_passed += delta * 15.0
	
	# Create a random-looking flicker using sine waves
	var flicker = (sin(time_passed) * 0.15) + (sin(time_passed * 2.7) * 0.15)
	
	# Apply the flicker to the light
	light_energy = base_energy + flicker
