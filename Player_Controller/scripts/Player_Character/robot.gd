extends CharacterBody3D

var Health = 10
var MaxHealth = 10
var HealthBar3D: ProgressBar

var player = null
var state_machine

const SPEED = 2.0
const ATTACK_RANGE = 10.0
const DETECTION_RANGE = 15.0

@export var player_path : NodePath 

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree

func _ready():
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")
	
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity = Vector3.ZERO
	
	if global_position.distance_to(player.global_position) < DETECTION_RANGE:
		match state_machine.get_current_node():
			"Run":
				# Navigation
				nav_agent.set_target_position(player.global_transform.origin)
				var next_nav_point = nav_agent.get_next_path_position()
				velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
				rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
			"Attack":
				look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	
	# Conditions
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/run", !_target_in_range())
	
	
	move_and_slide()

func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE


func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)
