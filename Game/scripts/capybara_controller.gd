class_name CapybaraController
extends CharacterBody3D

var speed := 4.4
var controls_enabled := false
var walkable_test: Callable
var body_root: Node3D
var left_foot: Node3D
var right_foot: Node3D
var left_arm: Node3D
var right_arm: Node3D
var head: Node3D
var mouth: MeshInstance3D
var left_eye: MeshInstance3D
var right_eye: MeshInstance3D
var carried_prop: Node3D
var action_pose := "normal"
var terrain_pose := "flat"
var walk_time := 0.0
var idle_time := 0.0

func _ready() -> void:
	body_root = Node3D.new()
	body_root.name = "AnimatedBody"
	add_child(body_root)
	build_character()
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.55
	collision.shape = capsule
	collision.position.y = 0.8
	add_child(collision)

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if controls_enabled:
		input.x = float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		input.y = float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	input = input.normalized() if input.length() > 1.0 else input
	var direction := Vector3(input.x, 0.0, input.y)
	var fishing_locked := action_pose.begins_with("fish_") or action_pose in ["cast", "reel"]
	if fishing_locked:
		direction = Vector3.ZERO
	var previous := global_position
	var movement_speed := speed * (0.62 if action_pose == "carry" else (0.84 if terrain_pose == "wetland" else 1.0))
	velocity = direction * movement_speed
	move_and_slide()
	global_position.y = 0.18
	if walkable_test.is_valid() and not walkable_test.call(global_position):
		global_position = previous
	if fishing_locked:
		velocity = Vector3.ZERO
	elif direction.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 11.0))
		animate_walk(delta)
	else:
		animate_idle(delta)

func animate_walk(delta: float) -> void:
	walk_time += delta * (6.2 if action_pose == "carry" else 8.4)
	var normal_swing := 0.38 if terrain_pose == "wetland" else 0.48
	var swing := sin(walk_time) * (0.28 if action_pose == "carry" else normal_swing)
	left_foot.rotation.x = swing
	right_foot.rotation.x = -swing
	left_arm.rotation.x = -swing * 0.55
	right_arm.rotation.x = swing * 0.55
	body_root.position.y = absf(sin(walk_time)) * (0.035 if terrain_pose == "wetland" else 0.065)
	body_root.rotation.x = -0.07 if terrain_pose == "uphill" else (0.04 if terrain_pose == "downhill" else 0.0)
	body_root.rotation.z = sin(walk_time * 0.5) * 0.055
	head.rotation.x = sin(walk_time * 2.0) * 0.035
	head.rotation.z = sin(walk_time * 0.5) * 0.045
	if action_pose == "carry":
		left_arm.rotation.x = -0.72
		right_arm.rotation.x = -0.72
		left_foot.rotation.z = -0.13
		right_foot.rotation.z = 0.13
		body_root.rotation.z *= 0.35
	elif terrain_pose == "wetland":
		left_foot.rotation.z = -0.07
		right_foot.rotation.z = 0.07

func animate_idle(delta: float) -> void:
	idle_time += delta
	left_foot.rotation.x = lerpf(left_foot.rotation.x, 0.0, delta * 8.0)
	right_foot.rotation.x = lerpf(right_foot.rotation.x, 0.0, delta * 8.0)
	left_arm.rotation.x = lerpf(left_arm.rotation.x, 0.0, delta * 8.0)
	right_arm.rotation.x = lerpf(right_arm.rotation.x, 0.0, delta * 8.0)
	body_root.position.y = sin(idle_time * 2.2) * 0.022
	body_root.rotation.x = 0.0
	body_root.rotation.z = sin(idle_time * 0.9) * 0.012
	head.rotation.x = sin(idle_time * 1.4) * 0.022
	head.rotation.z = sin(idle_time * 0.65) * 0.045
	left_arm.rotation.z = sin(idle_time * 1.1) * 0.035
	right_arm.rotation.z = -sin(idle_time * 1.1) * 0.035

func set_expression(expression: String) -> void:
	if not is_instance_valid(mouth):
		return
	match expression:
		"normal":
			mouth.scale = Vector3.ONE
			mouth.rotation.z = 0.03
			left_eye.scale.y = 1.0
			right_eye.scale.y = 1.0
		"effort":
			mouth.scale = Vector3(1.0, 0.55, 1.0)
			mouth.rotation.z = 0.0
		"surprised":
			mouth.scale = Vector3(0.55, 2.5, 1.0)
		"happy":
			mouth.scale = Vector3(1.35, 0.7, 1.0)
			mouth.rotation.z = 0.12
		"focused":
			mouth.scale = Vector3(0.6, 1.5, 1.0)
			left_eye.scale.y = 0.55
			right_eye.scale.y = 0.55
		"sad":
			mouth.scale = Vector3(0.85, 0.7, 1.0)
			mouth.rotation.z = -0.12
			left_eye.scale.y = 0.65
			right_eye.scale.y = 0.65
		_:
			mouth.scale = Vector3.ONE
			mouth.rotation.z = 0.03
			left_eye.scale.y = 1.0
			right_eye.scale.y = 1.0

func set_carrying(prop: Node3D, enabled: bool) -> void:
	if enabled:
		carried_prop = prop
		if is_instance_valid(prop):
			prop.reparent(body_root)
			prop.position = Vector3(0, 0.86, -0.72)
			prop.rotation = Vector3.ZERO
		action_pose = "carry"
		set_expression("effort")
	else:
		carried_prop = null
		action_pose = "normal"
		set_expression("happy")

func set_terrain_pose(pose_name: String) -> void:
	terrain_pose = pose_name

func play_task_pose(pose_name: String) -> void:
	action_pose = pose_name
	set_expression(pose_name)
	match pose_name:
		"scoop":
			left_foot.rotation.x = 0.42
			right_foot.rotation.x = 0.42
			left_arm.rotation.x = -0.88
			right_arm.rotation.x = -0.88
			body_root.rotation.x = 0.10
		"filter_reach":
			left_foot.rotation.x = -0.12
			right_foot.rotation.x = -0.12
			left_arm.rotation.x = -1.45
			right_arm.rotation.x = -1.45
			body_root.position.y = 0.12
		"fish_ready":
			left_foot.rotation.x = -0.18
			right_foot.rotation.x = 0.12
			left_arm.rotation.x = -0.72
			right_arm.rotation.x = -0.82
			body_root.rotation.x = 0.0
		"fish_backcast":
			left_foot.rotation.x = -0.28
			right_foot.rotation.x = 0.34
			left_arm.rotation.x = -1.28
			right_arm.rotation.x = -1.42
			body_root.rotation.y = 0.14
		"cast":
			left_arm.rotation.x = -1.0
			right_arm.rotation.x = -1.15
			left_foot.rotation.x = -0.34
			body_root.rotation.y = 0.0
		"fish_hooked":
			left_foot.rotation.x = -0.22
			right_foot.rotation.x = 0.22
			left_arm.rotation.x = -1.05
			right_arm.rotation.x = -1.05
			body_root.position.y = 0.03
		"reel":
			left_foot.rotation.x = -0.32
			right_foot.rotation.x = 0.32
			left_arm.rotation.x = -0.95
			right_arm.rotation.x = -0.55
		"press":
			left_foot.rotation.x = 0.42
			right_foot.rotation.x = -0.42
		"fish_celebrate":
			left_arm.rotation.x = -1.65
			right_arm.rotation.x = -1.65
			head.rotation.x = -0.12
		"fish_fail":
			left_foot.rotation.x = 0.30
			right_foot.rotation.x = -0.20
			left_arm.rotation.x = -0.20
			right_arm.rotation.x = -0.20
			body_root.position.y = -0.15

func finish_task_pose() -> void:
	action_pose = "normal"
	body_root.position.y = 0.0
	body_root.rotation = Vector3.ZERO
	set_expression("normal")

func build_character() -> void:
	var brown := Color("a8734c")
	var tan := Color("d9a875")
	var muzzle := Color("8b5e43")
	var dark := Color("263a37")
	var cream := Color("f7dfb0")
	# 挺直的圆润水豚：连贯头身、宽长吻部、小耳小眼；不前倾、不做熊式大圆耳。
	add_ellipsoid(body_root, Vector3(0, 0.82, 0.08), Vector3(0.66, 0.79, 0.60), brown)
	add_ellipsoid(body_root, Vector3(0, 0.76, -0.52), Vector3(0.32, 0.36, 0.09), tan)
	head = Node3D.new()
	head.position = Vector3(0, 1.46, -0.14)
	body_root.add_child(head)
	add_ellipsoid(head, Vector3.ZERO, Vector3(0.60, 0.50, 0.52), brown)
	add_ellipsoid(head, Vector3(-0.36, 0.31, 0.06), Vector3(0.095, 0.085, 0.075), brown)
	add_ellipsoid(head, Vector3(0.36, 0.31, 0.06), Vector3(0.095, 0.085, 0.075), brown)
	add_ellipsoid(head, Vector3(-0.36, 0.31, -0.02), Vector3(0.045, 0.040, 0.024), muzzle)
	add_ellipsoid(head, Vector3(0.36, 0.31, -0.02), Vector3(0.045, 0.040, 0.024), muzzle)
	add_ellipsoid(head, Vector3(0, -0.11, -0.48), Vector3(0.41, 0.24, 0.25), muzzle)
	add_ellipsoid(head, Vector3(0, -0.03, -0.69), Vector3(0.115, 0.065, 0.045), dark)
	left_eye = add_ellipsoid(head, Vector3(-0.22, 0.10, -0.47), Vector3(0.043, 0.038, 0.024), dark)
	right_eye = add_ellipsoid(head, Vector3(0.22, 0.10, -0.47), Vector3(0.043, 0.038, 0.024), dark)
	mouth = add_ellipsoid(head, Vector3(0, -0.20, -0.70), Vector3(0.085, 0.016, 0.016), dark)
	mouth.rotation.z = 0.03
	# 原创海岛识别物：胸前的小贝壳吊坠。
	add_ellipsoid(body_root, Vector3(0, 0.75, -0.62), Vector3(0.13, 0.11, 0.045), cream)
	add_ellipsoid(body_root, Vector3(0, 0.77, -0.67), Vector3(0.035, 0.075, 0.018), Color("e9bd69"))
	left_foot = make_limb(Vector3(-0.29, 0.23, 0.10), muzzle, Vector3(0.18, 0.24, 0.23))
	right_foot = make_limb(Vector3(0.29, 0.23, 0.10), muzzle, Vector3(0.18, 0.24, 0.23))
	left_arm = make_limb(Vector3(-0.43, 0.87, -0.34), brown, Vector3(0.13, 0.29, 0.13))
	right_arm = make_limb(Vector3(0.43, 0.87, -0.34), brown, Vector3(0.13, 0.29, 0.13))

func make_limb(position_value: Vector3, color: Color, scale_value: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = position_value
	body_root.add_child(pivot)
	add_ellipsoid(pivot, Vector3(0, -scale_value.y * 0.55, 0), scale_value, color)
	return pivot

func add_ellipsoid(parent: Node3D, position_value: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	node.mesh = mesh
	node.position = position_value
	node.scale = scale_value * 2.0
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	node.material_override = material
	parent.add_child(node)
	return node
