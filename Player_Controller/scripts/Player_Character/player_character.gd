extends CharacterBody3D

# Parent: MainNode
# Children: ChildNode1, ChildNode2

var speed = 4
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.002

var walking : AudioStreamPlayer3D
var jump : AudioStreamPlayer3D
var run : AudioStreamPlayer3D

var sprint_pressed = false
var is_walking = false

const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Define a variable to keep track of audio state
var is_audio_playing = false

var grev = true
var target_rotation = 0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $Head
@onready var camera = $Head/MainCamera

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	walking = $Pick_Up_Detection/Walking
	jump = $Pick_Up_Detection/Jump
	run = $Pick_Up_Detection/Run

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if grev == true:
			camera.rotation.x = clamp(camera.rotation.x - event.relative.y * SENSITIVITY, deg_to_rad(-40), deg_to_rad(60))
			head.rotate_y(-event.relative.x * SENSITIVITY) 
		else:
			camera.rotation.x = clamp(camera.rotation.x - -event.relative.y * SENSITIVITY, deg_to_rad(-70), deg_to_rad(30))
			head.rotation.y += event.relative.x * SENSITIVITY

func is_moving() -> bool:
	var input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	return input_dir != Vector2.ZERO

func is_in_air() -> bool:
	return not (is_on_floor() or is_on_ceiling())


func _physics_process(delta):
	if not is_on_floor() and grev == true:
		velocity.y -= gravity * delta

	if not is_on_floor() and grev == false:
		velocity.y += gravity * delta  # Changed the negative sign
		
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or is_on_ceiling()):
		if is_on_ceiling():
			velocity.y = -JUMP_VELOCITY  # Invert the jump when on the ceiling
		else:
			velocity.y = JUMP_VELOCITY  # Normal jump behavior when on the floor
		jump.play()
		walking.stop()

	if is_in_air():
		walking.stop()
		run.stop()
		is_walking = false
		is_audio_playing = false
	else:
		if is_moving() and (Input.is_action_pressed("Left") or Input.is_action_pressed("Right") or Input.is_action_pressed("Up") or Input.is_action_pressed("Down")):
			if not is_audio_playing:
				walking.play()
				is_audio_playing = true
		else:
			if is_audio_playing:
				walking.stop()
				is_audio_playing = false
				
			


func _process(delta):
	if Input.is_action_just_pressed("Ability"):  # Allow jumping on floor and ceiling
		grev = !grev
		velocity.y = -velocity.y  # Invert the vertical velocity

		if grev:
			velocity.y = -JUMP_VELOCITY
			camera.rotation_degrees.z = -180 + camera.rotation_degrees.z  # Flip camera 180 degrees
		else:
			velocity.y = JUMP_VELOCITY
			camera.rotation_degrees.z = 180 - camera.rotation_degrees.z  # Flip camera 180 degrees
	
	# Smoothly rotate the camera
	if camera.rotation_degrees.z != target_rotation:
		var rotation_step = 10  # Change this value to control the speed of rotation
		camera.rotation_degrees.z += rotation_step if camera.rotation_degrees.z < target_rotation else -rotation_step

		# Ensure the rotation does not exceed the target
		if grev and camera.rotation_degrees.z > target_rotation:
			camera.rotation_degrees.z = target_rotation	
		elif not grev and camera.rotation_degrees.z < target_rotation:
			camera.rotation_degrees.z = target_rotation
			camera.rotation_degrees.z = 180
		
		
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

func _input(event):
	if event.is_action_pressed("Sprint") and (is_on_floor() or is_on_ceiling()):
		sprint_pressed = true
		speed = SPRINT_SPEED
		run.play()
		walking.stop()
		if is_in_air():
			run.stop() 
		if not is_in_air():
			run.play()
	elif event.is_action_released("Sprint") and (is_on_floor() or is_on_ceiling()):
		sprint_pressed = false
		speed = WALK_SPEED
		run.stop()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
