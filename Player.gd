extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var grev = true
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor() and grev == true:
		velocity.y -= gravity * delta
		rotation_degrees.z = 0
		
	if not is_on_floor() and grev == false:
		velocity.y -= -gravity * delta
		rotation_degrees.z = 180
		
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		grev = false
		velocity.y -= -JUMP_VELOCITY

	if Input.is_action_just_pressed("ui_accept") and is_on_ceiling():
		grev = true
		velocity.y -= JUMP_VELOCITY
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
