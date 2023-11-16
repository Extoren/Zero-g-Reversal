extends StaticBody3D

# Set this to the position where you want the player to respawn
var respawn_point := Vector3(0, 0, 0)

# This function is called when any body enters the collision area
func _on_body_entered(body):
	# Check if the entering object is the player (you may need to adjust the name)
	if body.is_in_group("player"):
		# Respawn the player at the designated point
		body.global_transform.origin = respawn_point
