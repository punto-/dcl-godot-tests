extends Spatial

var mouse_sensitivity : float = ProjectSettings.get("input_devices/gameplay/mouse_sensitivity")
var speed : float = ProjectSettings.get("input_devices/gameplay/camera_speed")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	var dir = Vector3()
	var cam_xform = $Camera.get_global_transform()
	var input_movement_vector = Vector2()
	
	if Input.is_action_pressed("ui_up"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("ui_down"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("ui_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_movement_vector.x += 1

	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x
	dir.y = 0
	dir = dir.normalized()
	global_translate(dir.normalized() * speed)
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		$Camera.rotate_x(deg2rad(event.relative.y * mouse_sensitivity))
		rotate_y(deg2rad(event.relative.x * mouse_sensitivity * -1))

		var camera_rot = $Camera.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		$Camera.rotation_degrees = camera_rot
