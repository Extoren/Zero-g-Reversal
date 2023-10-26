extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.004

const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

var grev = true
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if grev == true:
			camera.rotation.x = clamp(camera.rotation.x - event.relative.y * SENSITIVITY, deg_to_rad(-40), deg_to_rad(60))
			head.rotate_y(-event.relative.x * SENSITIVITY) 
		else:
			camera.rotation.x = clamp(camera.rotation.x - -event.relative.y * SENSITIVITY, deg_to_rad(-70), deg_to_rad(30))
			camera.rotation.y += event.relative.x * SENSITIVITY



func _physics_process(delta):
	if not is_on_floor() and grev == true:
		velocity.y -= gravity * delta

	if not is_on_floor() and grev == false:
		velocity.y += gravity * delta  # Changed the negative sign
		

	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or is_on_ceiling()):  # Allow jumping on floor and ceiling
		grev = !grev
		velocity.y = -velocity.y  # Invert the vertical velocity

		if grev:
			velocity.y = -JUMP_VELOCITY
			camera.rotation_degrees.z = -180 + camera.rotation_degrees.z  # Flip camera 180 degrees
		else:
			velocity.y = JUMP_VELOCITY
			camera.rotation_degrees.z = 180 - camera.rotation_degrees.z  # Flip camera 180 degrees

	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	var input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	if is_on_ceiling():
		input_dir.x *= -1
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor() or is_on_ceiling():  # Allow movement on floor and ceiling
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	t_bob += delta * velocity.length() * float(is_on_floor() or is_on_ceiling())
	camera.transform.origin = _headbob(t_bob)

	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
