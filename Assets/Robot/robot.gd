extends Node

var Health = 10
var MaxHealth = 10
var HealthBar3D: ProgressBar # Make sure to reference your ProgressBar here

func _ready():
	# Initialize HealthBar3D reference in _ready function
	HealthBar3D = $SubViewport/HealthBar3D
	HealthBar3D.max_value = MaxHealth  # Set max_value to the initial maximum health

func take_damage(damage):
	if Health < damage:
		damage = Health
		Health -= damage
		# Add any additional logic you may need here
	else:
		Health -= damage

	# Update the HealthBar3D value whenever take_damage is called
	HealthBar3D.value = Health

func Hit_Successful(Damage, _Direction: Vector3 = Vector3.ZERO, _Position: Vector3 = Vector3.ZERO):
	take_damage(Damage)

	# Check if the health is less than or equal to 0
	if Health <= 0:
		queue_free()

# Note: This assumes that the script is attached to a Node or Control that can be queued for freeing.
