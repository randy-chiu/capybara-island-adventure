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
	var previous := global_position
	velocity = direction * speed
	move_and_slide()
	global_position.y = 0.18
	if walkable_test.is_valid() and not walkable_test.call(global_position):
		global_position = previous
	if direction.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 11.0))
		animate_walk(delta)
	else:
		animate_idle(delta)

func animate_walk(delta: float) -> void:
	walk_time += delta * 9.5
	var swing := sin(walk_time) * 0.62
	left_foot.rotation.x = swing
	right_foot.rotation.x = -swing
	left_arm.rotation.x = -swing * 0.55
	right_arm.rotation.x = swing * 0.55
	body_root.position.y = absf(sin(walk_time)) * 0.075
	body_root.rotation.z = sin(walk_time * 0.5) * 0.035
	head.rotation.x = sin(walk_time * 2.0) * 0.025

func animate_idle(delta: float) -> void:
	idle_time += delta
	left_foot.rotation.x = lerpf(left_foot.rotation.x, 0.0, delta * 8.0)
	right_foot.rotation.x = lerpf(right_foot.rotation.x, 0.0, delta * 8.0)
	left_arm.rotation.x = lerpf(left_arm.rotation.x, 0.0, delta * 8.0)
	right_arm.rotation.x = lerpf(right_arm.rotation.x, 0.0, delta * 8.0)
	body_root.position.y = sin(idle_time * 2.2) * 0.022
	body_root.rotation.z = lerpf(body_root.rotation.z, 0.0, delta * 5.0)
	head.rotation.x = sin(idle_time * 1.4) * 0.018

func build_character() -> void:
	var brown := Color("9b6541")
	var tan := Color("d39a61")
	var dark := Color("263a37")
	add_ellipsoid(body_root, Vector3(0, 0.82, 0.08), Vector3(0.62, 0.82, 0.55), brown)
	head = Node3D.new()
	head.position = Vector3(0, 1.55, -0.12)
	body_root.add_child(head)
	add_ellipsoid(head, Vector3.ZERO, Vector3(0.52, 0.48, 0.46), brown)
	add_ellipsoid(head, Vector3(-0.33, 0.32, 0.02), Vector3.ONE * 0.17, brown)
	add_ellipsoid(head, Vector3(0.33, 0.32, 0.02), Vector3.ONE * 0.17, brown)
	add_ellipsoid(head, Vector3(0, -0.12, -0.40), Vector3(0.33, 0.22, 0.17), tan)
	add_ellipsoid(head, Vector3(0, -0.06, -0.56), Vector3(0.10, 0.07, 0.055), dark)
	add_ellipsoid(head, Vector3(-0.18, 0.08, -0.43), Vector3.ONE * 0.055, dark)
	add_ellipsoid(head, Vector3(0.18, 0.08, -0.43), Vector3.ONE * 0.055, dark)
	left_foot = make_limb(Vector3(-0.28, 0.24, 0.05), dark, Vector3(0.20, 0.30, 0.25))
	right_foot = make_limb(Vector3(0.28, 0.24, 0.05), dark, Vector3(0.20, 0.30, 0.25))
	left_arm = make_limb(Vector3(-0.48, 0.86, -0.10), brown, Vector3(0.16, 0.42, 0.17))
	right_arm = make_limb(Vector3(0.48, 0.86, -0.10), brown, Vector3(0.16, 0.42, 0.17))

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
