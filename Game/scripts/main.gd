extends Node3D

const PlayerClass = preload("res://scripts/capybara_controller.gd")
const OCEAN := Color("63c4d1")
const DEEP_OCEAN := Color("1f788f")
const SAND := Color("fae3ab")
const PALM := Color("63ab6e")
const LEAF := Color("408c61")
const WOOD := Color("a67047")
const SHELL := Color("fffaf0")
const INK := Color("334745")
const CORAL := Color("f39475")
const SKY := Color("d9f4f2")
const BRIDGE_PLANKS_REQUIRED := 6
const WATER_BUCKETS_REQUIRED := 3
const CAMP_MATS_REQUIRED := 10

var player: CapybaraController
var camera: Camera3D
var objective_label: Label
var progress_label: Label
var title_label: Label
var inventory_label: Label
var toast_label: Label
var action_button: Button
var puzzle_panel: PanelContainer
var completion_panel: PanelContainer
var start_panel: PanelContainer
var start_shade: ColorRect
var puzzle_feedback: Label
var puzzle_heading: Label
var puzzle_question: Label
var puzzle_answer_buttons: Array[Button] = []
var puzzle_answer_values: Array[int] = []
var current_puzzle := ""
var completion_heading: Label
var completion_summary: Label
var completion_reward: Label
var completion_next_button: Button
var bait_nodes: Array[Node3D] = []
var swaying_trees: Array[Node3D] = []
var bridge_barrier: Node3D
var bridge_beacon: Node3D
var bridge_plank_supply: Array[MeshInstance3D] = []
var bridge_planks_laid := 0
var bridge_plan_ready := false
var carrying_bridge_plank := false
var near_bridge_supply := false
var chest_beacon: Node3D
var chest_lid: Node3D
var chest_shell_visual: Node3D
var fish_visual: Node3D
var fish_caught := false
var fishing_rod: Node3D
var fishing_line: Node3D
var fishing_float: Node3D
var fishing_rig: Node3D
var fish_basket: Node3D
var fish_basket_catch: Node3D
var collection_fish_model: Node3D
var fishing_attempt_token := 0
var fishing_last_result := "idle"
var bridge_slot_centers := [7.0, 9.0, 11.0, 13.0, 15.0, 17.0]
var bridge_laid_nodes: Array[MeshInstance3D] = []
var bridge_inspection_nodes: Array[Node3D] = []
var bridge_inspected := [false, false, false]
var bridge_inspect_count := 0
var active_bridge_inspection := -1
var bridge_shortfall_preview: Array[Node3D] = []
var guardrail_highlight: Node3D
var level_two_root: Node3D
var lake_beacon: Node3D
var water_clues: Array[Node3D] = []
var water_buckets: Array[MeshInstance3D] = []
var bucket_water_nodes: Array[MeshInstance3D] = []
var bucket_lids: Array[MeshInstance3D] = []
var water_wrong_preview: Node3D
var water_overflow_preview: Node3D
var water_pour_stream: Node3D
var water_stamps: Array[Node3D] = []
var water_plan_ready := false
var water_buckets_filled := 0
var water_buckets_loaded := 0
var water_buckets_poured := 0
var carrying_bucket := false
var carrying_empty_bucket := false
var near_empty_bucket := false
var pouring_water := false
var water_cart: Node3D
var water_tank_fill: MeshInstance3D
var near_water_cart := false
var near_water_tank := false
var cart_pushing := false
var water_observations := [false, false, false]
var water_observation_count := 0
var water_tank_marks: Array[Node3D] = []
var water_cart_wheels: Array[MeshInstance3D] = []
var filter_cloth: Node3D
var filter_fixed := false
var filter_activity_step := 0
var filter_clamp: Node3D
var filter_bubbles: Array[Node3D] = []
var near_filter := false
var frog_stones: Array[Node3D] = []
var frog_guide: Node3D
var frog_fog: Node3D
var frog_audio: AudioStreamPlayer3D
var frog_activity_step := 0
var near_frog_stone := false
var water_windmill: Node3D
var water_otter_arm: Node3D
var water_dragonflies: Array[Node3D] = []
var level_three_root: Node3D
var camp_beacon: Node3D
var camp_markers: Array[Dictionary] = []
var camp_mats: Array[MeshInstance3D] = []
var camp_target_positions: Array[Vector3] = []
var camp_plan_ready := false
var camp_mats_laid := 0
var carrying_camp_mat := false
var tent_root: Node3D
var tent_steps := 0
var safety_checks := 0
var safety_nodes: Array[Node3D] = []
var near_tent := false
var near_safety := false
var active_safety_node: Node3D
var carried_task_prop: Node3D
var mat_target_beacon: Node3D
var elapsed := 0.0
var stage := 0
var bait_count := 0
var fishing_state := 0
var near_pier := false
var near_bridge := false
var near_chest := false
var bridge_open := false
var chest_open := false
var near_lake := false
var clue_count := 0
var water_liters := 3
var near_camp_supply := false
var near_camp_target := false
var camp_measure_count := 0
var unlocked_level := 1
var travel_target := 0
var game_started := false
var toast_token := 0
var tree_obstacles := [Vector2(-6.0, 7.0), Vector2(-12.0, 3.0), Vector2(-2.0, 6.0)]

func _ready() -> void:
	RenderingServer.set_default_clear_color(SKY)
	build_environment()
	build_world()
	build_player_and_camera()
	build_ui()
	update_quest()
	var user_args := OS.get_cmdline_user_args()
	if "--auto-start" in user_args:
		begin_game()
	if "--qa-flow" in user_args:
		await run_qa_flow()
	if "--qa-level1" in user_args:
		await run_qa_level_one()
	if "--qa-level2" in user_args:
		await run_qa_level_two()
	if "--preview-puzzle" in user_args:
		preview_puzzle()
	elif "--preview-chest" in user_args:
		preview_chest()
	elif "--preview-complete" in user_args:
		preview_complete()

func _process(delta: float) -> void:
	elapsed += delta
	if is_instance_valid(player):
		player.set_terrain_pose("wetland" if player.position.x >= 10.0 and player.position.x <= 26.0 else "flat")
	update_camera(delta)
	animate_world(delta)
	check_interactions()
	if cart_pushing and is_instance_valid(water_cart):
		var old_cart_position := water_cart.position
		water_cart.position = water_cart.position.lerp(player.position + Vector3(0, 0, 1.15), minf(1.0, delta * 7.0))
		var wheel_turn := old_cart_position.distance_to(water_cart.position) * 4.0
		for wheel in water_cart_wheels:
			wheel.rotation.x += wheel_turn
		for loaded_index in range(water_buckets_loaded):
			water_buckets[loaded_index].rotation.z = sin(elapsed * 7.0 + loaded_index) * 0.055
			bucket_water_nodes[loaded_index].rotation.z = water_buckets[loaded_index].rotation.z
		if player.position.distance_to(Vector3(14.0, 0.18, 0.8)) < 1.7:
			cart_pushing = false
			player.set_expression("happy")
			show_toast("推车已到水箱旁。现在逐桶倒水。")
	elif is_instance_valid(water_cart):
		for loaded_index in range(water_buckets_loaded):
			water_buckets[loaded_index].rotation.z = lerpf(water_buckets[loaded_index].rotation.z, 0.0, delta * 8.0)
			bucket_water_nodes[loaded_index].rotation.z = water_buckets[loaded_index].rotation.z
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_E):
		if not action_button.disabled and action_button.visible:
			action_button.emit_signal("pressed")
			action_button.disabled = true
			get_tree().create_timer(0.3).timeout.connect(func(): action_button.disabled = false)

func build_environment() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = SKY
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("f2fffd")
	settings.ambient_light_energy = 0.30
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	settings.adjustment_enabled = true
	settings.adjustment_brightness = 0.82
	settings.adjustment_contrast = 1.12
	settings.adjustment_saturation = 1.18
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 0.72
	sun.shadow_enabled = true
	add_child(sun)

func build_world() -> void:
	var water := add_box(self, Vector3(8, -0.75, 0), Vector3(76, 0.35, 48), OCEAN)
	water.material_override = make_water_material()
	# 海马形风铃湾：北部头冠、收腰沙径与南侧弯尾钓鱼湾共同组成非圆轮廓。
	for data in [[Vector3(-6, -0.38, 2), Vector3(1.25, 1.0, 0.92)], [Vector3(-11, -0.38, 2), Vector3(0.72, 1.0, 0.68)], [Vector3(-4, -0.38, -4), Vector3(0.65, 1.0, 0.48)]]:
		var sand_piece := add_cylinder(self, data[0], 0.75, 8.0, SAND)
		sand_piece.scale = data[1]
	var grass_main := add_cylinder(self, Vector3(-6, -0.05, 2), 0.42, 7.1, PALM)
	grass_main.scale = Vector3(1.28, 1.0, 0.90)
	var north_slope := add_cylinder(self, Vector3(-6, 0.23, 6.2), 0.56, 4.5, PALM.darkened(0.03))
	north_slope.scale = Vector3(1.45, 1.0, 0.56)
	var east_tide_sand := add_cylinder(self, Vector3(23, -0.38, 2), 0.75, 4.8, SAND)
	east_tide_sand.scale = Vector3(1.25, 1.0, 0.78)
	var east_tide := add_cylinder(self, Vector3(23, -0.05, 2), 0.42, 4.0, PALM)
	east_tide.scale = Vector3(1.22, 1.0, 0.74)
	for data in [[Vector3(-6, 0, 7), 0.05], [Vector3(-12, 0, 3), -0.08], [Vector3(-2, 0, 6), 0.12]]:
		add_tree(data[0], data[1])
	for position_value in [Vector3(-9, 0.45, 3), Vector3(-3, 0.45, 5), Vector3(-1, 0.45, 6)]:
		var bait := add_sphere(self, position_value, Vector3.ONE * 0.24, Color("ffd447"), true)
		bait_nodes.append(bait)
	# 南湾栈桥、完整钓具和湿鱼篓。
	for z in range(5):
		add_box(self, Vector3(-5, 0.08, -4.8 - z * 0.68), Vector3(1.8, 0.18, 0.58), WOOD)
	add_box(self, Vector3(-5.82, 0.34, -6.2), Vector3(0.12, 0.65, 3.6), WOOD.darkened(0.28))
	add_box(self, Vector3(-4.18, 0.34, -6.2), Vector3(0.12, 0.65, 3.6), WOOD.darkened(0.28))
	add_fishing_gear(self, Vector3(-4.2, 0.28, -7.0))
	add_fish_basket(Vector3(-6.25, 0.25, -6.3))
	fish_visual = add_fish(self, Vector3(-5, -0.12, -8.2))
	fish_visual.visible = false
	add_crab(self, Vector3(-10.5, 0.24, -2.1), -0.2)
	add_crab(self, Vector3(-1.6, 0.24, -3.0), 0.3)
	# 海龟工棚及数据检查点：总长、两端、材料分工都由实体和牌面给出。
	add_turtle_workshop(Vector3(-7, 0.0, 2))
	add_world_label(self, Vector3(-7, 1.55, 2), "木匠海龟：9块板\n3块要做护栏", INK)
	for index in range(6):
		bridge_plank_supply.append(add_box(self, Vector3(1.2 + (index % 3) * 0.72, 0.18 + (index / 3) * 0.18, 2.0), Vector3(2.0, 0.14, 0.42), WOOD))
	guardrail_highlight = Node3D.new()
	guardrail_highlight.position = Vector3.ZERO
	add_child(guardrail_highlight)
	for index in range(3):
		add_box(guardrail_highlight, Vector3(1.0 + index * 0.65, 0.65, 3.0), Vector3(0.14, 1.2, 0.14), CORAL.darkened(0.18))
	guardrail_highlight.set_meta("highlighted", false)
	# 16m整桥：两端各2m，中间6个严格2m槽。
	add_box(self, Vector3(5, 0.18, 2), Vector3(2.0, 0.22, 2.0), WOOD.darkened(0.08))
	add_box(self, Vector3(19, 0.18, 2), Vector3(2.0, 0.22, 2.0), WOOD.darkened(0.08))
	for slot_x in bridge_slot_centers:
		var outline := add_box(self, Vector3(slot_x, 0.06, 2), Vector3(1.92, 0.05, 1.92), Color(1, 0.78, 0.38, 0.22))
		outline.set_meta("bridge_slot", true)
	for slot_x in [15.0, 17.0]:
		var shortfall := add_box(self, Vector3(slot_x, 0.24, 2), Vector3(1.90, 0.12, 1.90), Color("ef5b5b"), 1.2)
		shortfall.visible = false
		bridge_shortfall_preview.append(shortfall)
	# 三处必须由玩家主动检查，检查完才允许规划。
	for checkpoint in [Vector3(5.0, 0.48, 3.55), Vector3(2.0, 0.48, 2.0), Vector3(2.0, 0.48, 3.5)]:
		var inspect_node := add_sphere(self, checkpoint, Vector3.ONE * 0.16, Color("ffdc5e"), true)
		inspect_node.set_meta("inspected", false)
		bridge_inspection_nodes.append(inspect_node)
	bridge_barrier = add_box(self, Vector3(6.05, 0.72, 2), Vector3(0.22, 1.45, 2.5), CORAL.darkened(0.2))
	bridge_beacon = add_beacon(Vector3(5.2, 2.0, 2), CORAL)
	bridge_beacon.visible = false
	add_world_label(self, Vector3(4.5, 1.45, 4.0), "整桥16米 · 两端各2米\n中央缺口12米＝6个2米槽", INK)
	var chest := add_box(self, Vector3(23.0, 0.48, 2), Vector3(1.15, 0.75, 0.82), Color("e89224"))
	chest_lid = add_box(chest, Vector3(0, 0.48, 0), Vector3(1.23, 0.14, 0.88), Color("ffd24c"))
	chest_shell_visual = Node3D.new()
	chest_shell_visual.position = Vector3(23.0, 0.70, 2)
	add_child(chest_shell_visual)
	add_sphere(chest_shell_visual, Vector3.ZERO, Vector3(0.22, 0.16, 0.08), Color("fff0b5"), true)
	for x in [-0.11, 0.0, 0.11]:
		add_box(chest_shell_visual, Vector3(x, 0, -0.09), Vector3(0.025, 0.22, 0.025), Color("e7bd68"))
	chest_shell_visual.visible = false
	chest_beacon = add_beacon(Vector3(23.0, 2.2, 2), Color("ffd447"))
	chest_beacon.visible = false
	for position_value in [Vector3(-11, 0.2, 6), Vector3(-8, 0.2, -2), Vector3(-2, 0.2, 7.5)]:
		add_sphere(self, position_value, Vector3(0.65, 0.32, 0.55), Color("5ea94f"))
	add_travel_dock(self, Vector3(6.0, 0.12, 7.0), "渡船码头 · 前往淡水岛")
	build_level_two_world()
	build_level_three_world()

func build_level_two_world() -> void:
	level_two_root = Node3D.new()
	level_two_root.name = "LevelTwoFreshwaterIsland"
	level_two_root.visible = false
	add_child(level_two_root)
	# 三片低湿地而非圆岛：西叶到达、北叶观景、东南叶取水。
	for lobe in [
		[Vector3(14.8, -0.34, 0.4), Vector3(1.20, 1.0, 0.72)],
		[Vector3(18.2, -0.34, 3.8), Vector3(0.78, 1.0, 1.08)],
		[Vector3(21.5, -0.34, -1.8), Vector3(1.20, 1.0, 0.76)]
	]:
		var sand_lobe := add_cylinder(level_two_root, lobe[0], 0.70, 5.8, SAND.darkened(0.04))
		sand_lobe.scale = lobe[1]
		var grass_lobe := add_cylinder(level_two_root, lobe[0] + Vector3(0, 0.31, 0), 0.34, 5.15, Color("73b879"))
		grass_lobe.scale = lobe[1] * Vector3(0.94, 1.0, 0.90)
	# 豆形湖用相交的两个不等椭圆组成，岸边卵石让边界可读。
	for lake_part in [[Vector3(19.5, 0.05, -0.9), Vector3(1.45, 1.0, 0.74)], [Vector3(21.1, 0.05, -1.7), Vector3(1.08, 1.0, 0.86)]]:
		var lake_mesh := add_cylinder(level_two_root, lake_part[0], 0.10, 2.35, DEEP_OCEAN.lightened(0.28))
		lake_mesh.scale = lake_part[1]
	for shore_angle in range(0, 360, 30):
		var radians := deg_to_rad(float(shore_angle))
		add_sphere(level_two_root, Vector3(20.2 + cos(radians) * 3.3, 0.22, -1.25 + sin(radians) * 2.0), Vector3(0.18, 0.10, 0.14), Color("b8aa8d"))
	# 三条叶脉浅渠都实际连向湖。
	for channel in [[Vector3(16.2, 0.17, 0.2), 0.28], [Vector3(18.4, 0.17, 2.1), -0.04], [Vector3(21.4, 0.17, 0.5), -0.42]]:
		var water_channel := add_box(level_two_root, channel[0], Vector3(4.1, 0.055, 0.34), Color("68cbd4"))
		water_channel.rotation.y = channel[1]
	# 北侧1m观景土脊、深泥裂纹和木桩共同表示不可越界区域。
	var ridge := add_cylinder(level_two_root, Vector3(18.0, 0.35, 5.3), 1.0, 2.8, Color("789f62"))
	ridge.scale = Vector3(1.8, 1.0, 0.65)
	for boundary_pos in [Vector3(12.0, 0.22, -1.8), Vector3(13.0, 0.22, -3.4), Vector3(23.4, 0.22, 1.8), Vector3(24.0, 0.22, -3.3)]:
		add_cylinder(level_two_root, boundary_pos, 0.65, 0.08, WOOD.darkened(0.25))
	for position_value in [Vector3(18.8, 0.32, -3.8), Vector3(21.8, 0.32, -3.7), Vector3(22.5, 0.32, -1.2)]:
		add_reeds(level_two_root, position_value)
	for position_value in [Vector3(19.7, 0.28, -2.8), Vector3(20.9, 0.28, -1.7), Vector3(21.3, 0.28, -2.9)]:
		add_lily_pad(level_two_root, position_value)
	add_frog(level_two_root, Vector3(18.9, 0.34, -1.9))
	add_frog(level_two_root, Vector3(22.0, 0.34, -2.8))
	# 三类数据观察门：水箱目标/已有量、桶容量、推车槽数。
	for position_value in [Vector3(14.0, 0.46, 1.8), Vector3(20.0, 0.46, -0.1), Vector3(22.4, 0.46, -0.2)]:
		var clue := add_sphere(level_two_root, position_value, Vector3(0.18, 0.28, 0.18), Color("8ce9ff"), true)
		clue.set_meta("observation_index", water_clues.size())
		water_clues.append(clue)
	for position_value in [Vector3(14.2, 0, -2.8), Vector3(21.8, 0, 2.4), Vector3(17.0, 0, -4.2)]:
		add_simple_tree(level_two_root, position_value)
	add_world_label(level_two_root, Vector3(14.0, 1.55, 1.7), "水箱目标 18 L\n现有水线 3 L", DEEP_OCEAN)
	add_world_label(level_two_root, Vector3(20.4, 1.15, -0.2), "木桶内壁：5 L", DEEP_OCEAN)
	for x in range(3):
		var bucket := add_cylinder(level_two_root, Vector3(19.4 + x, 0.34, -0.4), 0.62, 0.28, Color("d9c69b"))
		water_buckets.append(bucket)
		var bucket_water := add_cylinder(level_two_root, Vector3(19.4 + x, 0.58, -0.4), 0.08, 0.23, Color("4bbfe5"))
		bucket_water.visible = false
		bucket_water_nodes.append(bucket_water)
		var lid := add_cylinder(level_two_root, Vector3(19.4 + x, 0.65, -0.4), 0.05, 0.29, WOOD.darkened(0.08))
		lid.visible = false
		bucket_lids.append(lid)
	water_cart = Node3D.new()
	water_cart.position = Vector3(22.4, 0.18, -0.2)
	level_two_root.add_child(water_cart)
	add_box(water_cart, Vector3.ZERO, Vector3(2.5, 0.28, 1.2), Color("699568"))
	for x in [-0.85, 0.85]:
		var wheel := add_cylinder(water_cart, Vector3(x, -0.08, 0.68), 0.18, 0.34, Color("473d37"))
		wheel.rotation.x = PI * 0.5
		water_cart_wheels.append(wheel)
	for slot_x in [-0.65, 0.0, 0.65]:
		add_box(water_cart, Vector3(slot_x, 0.23, 0), Vector3(0.53, 0.08, 0.62), Color("d5e1b8"))
	add_world_label(level_two_root, Vector3(22.4, 1.0, 0.7), "三槽运水车", DEEP_OCEAN)
	add_world_label(level_two_root, Vector3(14.0, 1.1, 1.5), "水箱刻度 3 / 8 / 13 / 18 L", DEEP_OCEAN)
	add_box(level_two_root, Vector3(14.0, 0.75, 0.8), Vector3(1.45, 1.55, 0.95), Color(0.75, 0.88, 0.90, 0.55))
	water_tank_fill = add_box(level_two_root, Vector3(14.0, 0.22, 0.8), Vector3(1.20, 0.25, 0.75), Color("4bbfe5"))
	var tank_fill_mesh := water_tank_fill.mesh as BoxMesh
	tank_fill_mesh.size.y = 1.2
	set_water_tank_level(3)
	water_wrong_preview = add_box(level_two_root, Vector3(14.0, 0.15 + 0.6 * 13.0 / 18.0, 0.28), Vector3(1.35, 0.045, 0.08), Color("ef5b5b"), 1.0)
	water_wrong_preview.visible = false
	water_overflow_preview = add_cylinder(level_two_root, Vector3(23.15, 0.48, -0.2), 0.62, 0.28, CORAL)
	water_overflow_preview.visible = false
	water_pour_stream = add_box(level_two_root, Vector3(14.65, 1.02, 0.8), Vector3(0.10, 1.0, 0.10), Color("73d9f0"), 1.0)
	water_pour_stream.visible = false
	for stamp_index in range(3):
		var stamp := add_sphere(level_two_root, Vector3(13.45 + stamp_index * 0.28, 1.45, 0.28), Vector3.ONE * 0.09, CORAL, true)
		stamp.visible = false
		water_stamps.append(stamp)
	for mark_index in range(4):
		var mark := add_box(level_two_root, Vector3(14.78, 0.26 + mark_index * 0.34, 0.30), Vector3(0.16, 0.035, 0.06), INK)
		water_tank_marks.append(mark)
	# 可选活动实体：松脱滤布可扶正；三块浅色蛙石依次亮起。
	filter_cloth = add_box(level_two_root, Vector3(14.0, 1.75, 0.8), Vector3(1.15, 0.07, 0.75), SHELL)
	filter_cloth.rotation.z = 0.22
	filter_clamp = add_box(level_two_root, Vector3(13.15, 0.30, 1.05), Vector3(0.28, 0.12, 0.10), WOOD.darkened(0.15))
	for bubble_y in [0.38, 0.58, 0.78]:
		var bubble := add_sphere(level_two_root, Vector3(14.0, bubble_y, 0.28), Vector3.ONE * 0.07, Color("b9f4ff"), true)
		bubble.visible = false
		filter_bubbles.append(bubble)
	for stone_pos in [Vector3(17.0, 0.23, -3.8), Vector3(18.1, 0.23, -4.2), Vector3(19.1, 0.23, -3.9)]:
		var frog_stone := add_sphere(level_two_root, stone_pos, Vector3(0.42, 0.11, 0.34), Color("d8d2b5"))
		frog_stones.append(frog_stone)
	frog_guide = Node3D.new()
	frog_guide.position = frog_stones[0].position + Vector3(0, 0.24, 0)
	level_two_root.add_child(frog_guide)
	add_sphere(frog_guide, Vector3.ZERO, Vector3(0.18, 0.10, 0.16), Color("72b85e"))
	frog_fog = add_box(level_two_root, Vector3(18.1, 0.55, -3.45), Vector3(3.2, 0.85, 0.18), Color(0.86, 0.94, 0.91, 0.58))
	frog_audio = AudioStreamPlayer3D.new()
	frog_audio.stream = make_frog_audio()
	frog_audio.position = frog_stones[0].position
	level_two_root.add_child(frog_audio)
	# 四叶滤布风车。
	water_windmill = Node3D.new()
	water_windmill.position = Vector3(14.0, 2.35, 0.8)
	level_two_root.add_child(water_windmill)
	for blade_angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var blade := add_box(water_windmill, Vector3(cos(blade_angle) * 0.48, sin(blade_angle) * 0.48, 0), Vector3(0.72, 0.18, 0.06), SHELL)
		blade.rotation.z = blade_angle
	# 水獭管理员：身体、蓝围巾、夹板和可动印章臂。
	var otter := Node3D.new()
	otter.position = Vector3(12.9, 0.35, 0.5)
	level_two_root.add_child(otter)
	add_sphere(otter, Vector3(0, 0.48, 0), Vector3(0.34, 0.52, 0.28), Color("875b42"))
	add_box(otter, Vector3(0, 0.65, -0.28), Vector3(0.62, 0.12, 0.08), Color("4b8fc7"))
	add_box(otter, Vector3(0.30, 0.55, -0.20), Vector3(0.32, 0.44, 0.08), Color("d7c493"))
	water_otter_arm = Node3D.new()
	water_otter_arm.position = Vector3(-0.28, 0.62, -0.18)
	otter.add_child(water_otter_arm)
	add_cylinder(water_otter_arm, Vector3(0, -0.16, 0), 0.34, 0.06, CORAL)
	for fly_pos in [Vector3(18.8, 0.75, -1.0), Vector3(20.5, 0.82, -2.0), Vector3(21.8, 0.72, -0.8)]:
		var fly := Node3D.new()
		fly.position = fly_pos
		fly.set_meta("base_position", fly_pos)
		level_two_root.add_child(fly)
		add_box(fly, Vector3(-0.09, 0, 0), Vector3(0.16, 0.025, 0.08), Color("9eeaff"))
		add_box(fly, Vector3(0.09, 0, 0), Vector3(0.16, 0.025, 0.08), Color("9eeaff"))
		add_cylinder(fly, Vector3(0, 0, 0), 0.22, 0.025, Color("397a91"))
		water_dragonflies.append(fly)
	add_travel_dock(level_two_root, Vector3(11.3, 0.12, 3.7), "渡船 · 返回第一岛")
	add_travel_dock(level_two_root, Vector3(24.7, 0.12, 3.7), "渡船 · 前往营地岛")
	lake_beacon = add_box(level_two_root, Vector3(20.4, 2.1, -2.4), Vector3(0.18, 3.4, 0.18), Color("74dcff"), 1.0)
	lake_beacon.visible = false

func build_level_three_world() -> void:
	level_three_root = Node3D.new()
	level_three_root.name = "LevelThreeCampIsland"
	level_three_root.visible = false
	add_child(level_three_root)
	var sand := add_cylinder(level_three_root, Vector3(36, -0.38, 0), 0.75, 10.0, SAND)
	sand.scale = Vector3(0.92, 1.0, 1.02)
	sand.material_override = make_terrain_material(SAND, SAND.darkened(0.06), 0.9)
	var grass := add_cylinder(level_three_root, Vector3(36, -0.05, 0), 0.42, 8.4, PALM)
	grass.scale = Vector3(0.88, 1.0, 0.96)
	grass.material_override = make_terrain_material(PALM, PALM.darkened(0.12), 1.1)
	# 西北岩坡形成挡风面，帐篷落在坡脚的平坦区。
	for data in [
		[Vector3(31.5, 0.40, 1.4), Vector3(1.55, 0.80, 1.20)],
		[Vector3(32.0, 0.72, 2.4), Vector3(1.25, 1.20, 1.05)],
		[Vector3(33.0, 0.34, 3.1), Vector3(1.10, 0.68, 0.95)],
		[Vector3(30.8, 0.28, 2.9), Vector3(0.90, 0.55, 0.85)]
	]:
		add_sphere(level_three_root, data[0], data[1], Color("7d8279"))
	tent_root = add_tent(level_three_root, Vector3(34.0, 0.26, 3.5))
	tent_root.visible = false
	add_bird(level_three_root, Vector3(31.3, 1.55, 2.2))
	add_bird(level_three_root, Vector3(32.7, 1.38, 3.2))
	add_box(level_three_root, Vector3(36, 0.08, -1), Vector3(6, 0.10, 4), Color("d9bd79"))
	add_cylinder(level_three_root, Vector3(36, 0.20, -1), 0.18, 1.0, Color("6b5141"))
	for data in [
		[Vector3(33.2, 0.42, 1.0), "量到长边：6 米"],
		[Vector3(39.0, 0.42, -3.0), "量到短边：4 米"],
		[Vector3(36.0, 0.42, -1.0), "火塘：2 米 × 2 米"]
	]:
		var marker := add_sphere(level_three_root, data[0], Vector3.ONE * 0.20, Color("ffd447"), true)
		camp_markers.append({"node": marker, "message": data[1]})
	add_world_label(level_three_root, Vector3(36, 1.15, -1), "营地 6 米 × 4 米\n火塘 2 米 × 2 米", INK)
	add_world_label(level_three_root, Vector3(40.0, 1.10, 2.0), "每块草垫铺 2 平方米", LEAF)
	for position_value in [Vector3(32.8, 0, -3.2), Vector3(40.7, 0, -2.8), Vector3(40.8, 0, 3.0)]:
		add_simple_tree(level_three_root, position_value)
	camp_beacon = add_box(level_three_root, Vector3(40.0, 2.0, 2.0), Vector3(0.18, 3.4, 0.18), Color("ffd447"), 1.0)
	camp_beacon.visible = false
	for x in range(4):
		add_box(level_three_root, Vector3(39.3 + x * 0.46, 0.22, 2.0), Vector3(0.38, 0.18, 0.75), Color("b9df72"))
	for z in [-2.5, -1.5, -0.5, 0.5]:
		for x in [34.0, 36.0, 38.0]:
			if x == 36.0 and (z == -1.5 or z == -0.5):
				continue
			camp_target_positions.append(Vector3(x, 0.18, z))
	mat_target_beacon = add_box(level_three_root, Vector3.ZERO, Vector3(0.12, 2.2, 0.12), Color("fff173"), 1.2)
	mat_target_beacon.visible = false
	for safety_position in [Vector3(32.8, 0.35, 1.0), Vector3(36.0, 0.35, -1.0), Vector3(34.0, 0.35, 3.0)]:
		var safety := add_sphere(level_three_root, safety_position, Vector3.ONE * 0.18, Color("82f0c4"), true)
		safety.visible = false
		safety_nodes.append(safety)
	add_travel_dock(level_three_root, Vector3(29.3, 0.12, 3.7), "渡船 · 返回淡水岛")

func build_player_and_camera() -> void:
	player = PlayerClass.new()
	player.position = Vector3(-12, 0.18, 2)
	player.walkable_test = is_walkable
	add_child(player)
	camera = Camera3D.new()
	camera.fov = 46
	add_child(camera)
	camera.position = player.position + Vector3(0, 8.2, 10.4)
	camera.look_at(player.position + Vector3(0, 0.9, 0))
	collection_fish_model = add_fish(camera, Vector3(3.8, 2.0, -7.0))
	collection_fish_model.scale = Vector3.ONE * 0.42
	collection_fish_model.visible = false

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	layer.add_child(margin)
	var layout := VBoxContainer.new()
	margin.add_child(layout)
	var top_row := HBoxContainer.new()
	layout.add_child(top_row)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(520, 112)
	card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	card.add_theme_stylebox_override("panel", make_panel_style(Color(SHELL, 0.96), 24, DEEP_OCEAN, 1))
	top_row.add_child(card)
	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 5)
	card.add_child(text_box)
	title_label = Label.new()
	title_label.text = "小巴的第一个海岛日"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", INK)
	text_box.add_child(title_label)
	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", DEEP_OCEAN)
	text_box.add_child(progress_label)
	objective_label = Label.new()
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.add_theme_color_override("font_color", INK)
	text_box.add_child(objective_label)
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)
	var inventory_card := PanelContainer.new()
	inventory_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inventory_card.add_theme_stylebox_override("panel", make_panel_style(Color(SHELL, 0.94), 20, Color.TRANSPARENT, 0))
	inventory_label = Label.new()
	inventory_label.add_theme_font_size_override("font_size", 16)
	inventory_label.add_theme_color_override("font_color", INK)
	inventory_card.add_child(inventory_label)
	top_row.add_child(inventory_card)
	var reset := Button.new()
	reset.text = "重新开始"
	reset.custom_minimum_size = Vector2(126, 48)
	reset.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	style_button(reset, DEEP_OCEAN)
	reset.pressed.connect(func(): get_tree().reload_current_scene())
	top_row.add_child(reset)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)
	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	toast_label.add_theme_font_size_override("font_size", 19)
	toast_label.add_theme_color_override("font_color", INK)
	toast_label.add_theme_stylebox_override("normal", make_panel_style(SHELL, 20, CORAL, 1))
	toast_label.visible = false
	layout.add_child(toast_label)
	var bottom := HBoxContainer.new()
	layout.add_child(bottom)
	var help := Label.new()
	help.text = "方向键 / WASD 移动    空格 / E 互动"
	help.add_theme_font_size_override("font_size", 18)
	help.add_theme_color_override("font_color", INK)
	help.add_theme_stylebox_override("normal", make_panel_style(Color(SHELL, 0.86), 18, Color.TRANSPARENT, 0))
	bottom.add_child(help)
	var flexible := Control.new()
	flexible.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(flexible)
	action_button = Button.new()
	action_button.custom_minimum_size = Vector2(190, 62)
	action_button.add_theme_font_size_override("font_size", 21)
	style_button(action_button, LEAF)
	action_button.visible = false
	action_button.pressed.connect(perform_action)
	bottom.add_child(action_button)
	puzzle_panel = build_puzzle_panel(layer)
	completion_panel = build_completion_panel(layer)
	start_panel = build_start_panel(layer)

func build_start_panel(layer: CanvasLayer) -> PanelContainer:
	start_shade = ColorRect.new()
	start_shade.color = Color(0.08, 0.31, 0.34, 0.32)
	start_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(start_shade)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-340, -220)
	panel.custom_minimum_size = Vector2(680, 440)
	panel.add_theme_stylebox_override("panel", make_panel_style(SHELL, 32, DEEP_OCEAN, 2))
	start_shade.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 17)
	panel.add_child(box)
	var icon := Label.new()
	icon.text = "🏝️  🐹  🎣"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 44)
	box.add_child(icon)
	var heading := Label.new()
	heading.text = "卡皮巴拉海岛探险"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 38)
	heading.add_theme_color_override("font_color", INK)
	box.add_child(heading)
	var intro := Label.new()
	intro.text = "先去岛上自由探索、收集鱼饵和钓鱼。\n只有遇到真正的难题时，数学才会来帮忙。"
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_font_size_override("font_size", 21)
	intro.add_theme_color_override("font_color", INK)
	box.add_child(intro)
	var controls := Label.new()
	controls.text = "方向键 / WASD 移动    空格 / E 互动"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 17)
	controls.add_theme_color_override("font_color", DEEP_OCEAN)
	box.add_child(controls)
	var start := Button.new()
	start.text = "开始今天的探险"
	start.custom_minimum_size = Vector2(260, 64)
	start.add_theme_font_size_override("font_size", 22)
	style_button(start, LEAF)
	start.pressed.connect(begin_game)
	box.add_child(start)
	return panel

func begin_game() -> void:
	game_started = true
	player.controls_enabled = true
	if is_instance_valid(start_shade):
		start_shade.queue_free()

func preview_puzzle() -> void:
	begin_game()
	stage = 3
	bait_count = 0
	player.position = Vector3(4.7, 0.18, -4.2)
	bridge_beacon.visible = true
	open_puzzle("bridge")
	update_quest()

func preview_chest() -> void:
	begin_game()
	stage = 3
	solve_bridge(6)
	player.position = Vector3(6.0, 0.18, -4.2)
	update_quest()

func preview_complete() -> void:
	preview_chest()
	player.position = Vector3(7.0, 0.18, -4.2)
	near_chest = true
	open_chest()

func run_qa_flow() -> void:
	begin_game()
	player.position = Vector3(-2.8, 0.18, -1.7)
	check_interactions()
	assert(stage == 1 and bait_count == 1, "鱼饵收集流程失败")
	near_pier = true
	fishing_state = 2
	await perform_action()
	assert(stage == 3 and fishing_state == 3 and fish_caught and inventory_label.text.contains("银鳞鱼✓"), "钓鱼实体与收藏流程失败")
	near_bridge = true
	solve_bridge(4)
	solve_bridge(8)
	assert(not bridge_plan_ready and bridge_planks_laid == 0, "修桥错误答案不应解锁施工")
	solve_bridge(6)
	assert(bridge_plan_ready and not bridge_open, "修桥答案不应自动完成施工")
	for index in range(BRIDGE_PLANKS_REQUIRED):
		pick_bridge_plank()
		assert(carrying_bridge_plank, "桥板必须先成为手中可见负重")
		lay_bridge_plank()
	assert(stage == 4 and bridge_open, "修桥流程失败")
	near_chest = true
	await open_chest()
	assert(stage == 5 and chest_open and chest_shell_visual.visible and completion_panel.visible, "开箱实体与结算流程失败")
	start_level_two()
	assert(stage == 6 and level_two_root.visible, "进入第二关流程失败")
	stage = 7
	water_observation_count = 3
	solve_water(2)
	assert(water_wrong_preview.visible and not water_overflow_preview.visible, "L02 2桶错项缺少13L世界预览")
	solve_water(4)
	assert(water_overflow_preview.visible and not water_wrong_preview.visible, "L02 4桶错项缺少车外第4桶")
	assert(stage == 7, "第二关错误答案不应推进流程")
	solve_water(3)
	assert(water_plan_ready and water_buckets_filled == 0, "取水答案不应自动装桶")
	for index in range(WATER_BUCKETS_REQUIRED):
		pick_empty_water_bucket()
		await fill_water_bucket()
		assert(carrying_bucket, "满桶必须由玩家负重搬运")
		load_water_bucket()
	assert(water_buckets_loaded == 3 and water_liters == 3, "推车三槽或初始水量状态失败")
	cart_pushing = true
	water_cart.position = Vector3(14.0, 0.18, 1.6)
	cart_pushing = false
	assert(water_cart.position.distance_to(Vector3(14.0, 0.18, 0.8)) < 2.3, "装满后的推车必须抵达水箱才能倒水")
	for index in range(WATER_BUCKETS_REQUIRED):
		await pour_water_bucket()
		assert(water_liters == 3 + (index + 1) * 5, "水箱刻度未按3/8/13/18递增")
	assert(stage == 8 and water_liters == 18 and completion_panel.visible, "淡水补给流程失败")
	start_level_three()
	assert(stage == 9 and level_three_root.visible, "进入第三关流程失败")
	stage = 10
	solve_camp(8)
	solve_camp(12)
	assert(stage == 10, "第三关错误答案不应推进流程")
	solve_camp(10)
	assert(camp_plan_ready and camp_mats_laid == 0, "草垫答案不应自动完成铺设")
	for index in range(CAMP_MATS_REQUIRED):
		pick_camp_mat()
		assert(carrying_camp_mat, "草垫必须从料棚逐卷搬运")
		player.position = camp_target_positions[index]
		lay_camp_mat()
	assert(stage == 11 and camp_mats.size() == 10 and not completion_panel.visible, "营地铺设流程失败")
	for index in range(4):
		build_tent_step()
	assert(stage == 12 and tent_steps == 4 and tent_root.visible, "合作搭帐篷流程失败")
	for safety in safety_nodes:
		active_safety_node = safety
		perform_safety_check()
	assert(stage == 13 and safety_checks == 3 and completion_panel.visible, "三点安全巡检流程失败")
	player.position = Vector3(29.3, 0.18, 3.7)
	check_interactions()
	assert(travel_target == 2, "第三岛返回码头识别失败")
	travel_to_level(travel_target)
	player.position = Vector3(11.3, 0.18, 3.7)
	check_interactions()
	assert(travel_target == 1, "第二岛返回码头识别失败")
	travel_to_level(travel_target)
	assert(player.position.x < 10.0 and bridge_open and chest_shell_visual.visible, "返回第一关或状态保留失败")
	travel_to_level(3)
	assert(player.position.x > 28.0 and camp_mats.size() == 10, "返回第三关或状态保留失败")
	print("QA_FLOW_OK: carry 6 planks -> fill/load/pour 3 buckets -> carry 10 mats -> tent 4 -> safety 3")
	get_tree().quit()

func run_qa_level_one() -> void:
	begin_game()
	# 第一关真实坐标：鱼饵、南湾栈桥、鱼篓和钓具均属于同一世界。
	player.position = Vector3(-9, 0.18, 3)
	check_interactions()
	assert(bait_count == 1, "L01 鱼饵收集失败")
	assert(is_instance_valid(fishing_rod) and is_instance_valid(fishing_line) and is_instance_valid(fishing_float) and is_instance_valid(fish_basket), "L01 钓具实体链缺失")
	# 确定性失败：咬钩后超时，恢复空闲且海龟返饵。
	var bait_before_fail := bait_count
	fishing_state = 4
	fish_visual.visible = true
	await resolve_fishing_attempt(false)
	assert(fishing_last_result == "failed" and fishing_state == 0, "L01 钓鱼失败状态未恢复")
	assert(bait_count == bait_before_fail and not fish_caught, "L01 失败后应返饵且不能入收藏")
	# 确定性成功：收线、鱼跃、落篓后才进入收藏。
	fishing_state = 4
	fish_visual.position = Vector3(-5, -0.12, -8.2)
	fish_visual.visible = true
	await resolve_fishing_attempt(true)
	assert(fishing_last_result == "caught" and fishing_state == 7 and fish_caught, "L01 钓鱼成功链失败")
	assert(inventory_label.text.contains("银鳞鱼✓"), "L01 银鳞鱼未进入收藏")
	# 错项不能解锁，正确答案只解锁逐次施工。
	solve_bridge(4)
	solve_bridge(8)
	assert(not bridge_plan_ready and bridge_planks_laid == 0, "L01 错误答案不应解锁")
	solve_bridge(6)
	assert(bridge_plan_ready and not bridge_open, "L01 答对不应自动铺桥")
	assert(bridge_slot_centers == [7.0, 9.0, 11.0, 13.0, 15.0, 17.0], "L01 六槽中心错误")
	assert(not is_walkable(Vector3(7, 0.18, 2)), "L01 未铺第一槽不可通行")
	for index in range(BRIDGE_PLANKS_REQUIRED):
		pick_bridge_plank()
		assert(carrying_bridge_plank, "L01 必须先拾板再铺")
		lay_bridge_plank()
		assert(bridge_laid_nodes[index].get_meta("bridge_slot_index") == index, "L01 桥板槽序错误")
		var board_mesh := bridge_laid_nodes[index].mesh as BoxMesh
		assert(absf(board_mesh.size.x - 1.96) < 0.05, "L01 桥板必须约2米")
		assert(is_walkable(Vector3(bridge_slot_centers[index], 0.18, 2)), "L01 已铺槽应可通行")
		if index < BRIDGE_PLANKS_REQUIRED - 1:
			assert(not bridge_open, "L01 未铺满六块不可开放整桥")
			assert(not is_walkable(Vector3(bridge_slot_centers[index + 1], 0.18, 2)), "L01 下一空槽不可通行")
	assert(bridge_open and bridge_planks_laid == 6, "L01 六块完成后整桥未开放")
	assert(is_walkable(Vector3(5, 0.18, 2)) and is_walkable(Vector3(17, 0.18, 2)) and is_walkable(Vector3(19, 0.18, 2)), "L01 x[4,20]桥面不连续")
	player.position = Vector3(23, 0.18, 2)
	check_interactions()
	assert(near_chest, "L01 东潮池宝箱坐标错误")
	await open_chest()
	assert(chest_open and chest_shell_visual.visible, "L01 开箱状态失败")
	# 解锁渡船后往返，第一关施工和收藏永久保留。
	unlocked_level = 2
	travel_to_level(2)
	travel_to_level(1)
	assert(bridge_open and bridge_laid_nodes.size() == 6 and fish_caught and chest_open, "L01 回访状态未保留")
	print("QA_LEVEL1_PASS: fishing fail/rebait + catch/basket/collection; bridge slots 7..17; six 2m boards; chest (23,2); revisit preserved")
	get_tree().quit()

func run_qa_level_two() -> void:
	begin_game()
	start_level_two()
	assert(stage == 6 and level_two_root.visible, "L02 未进入湿地")
	# 两条可选支线独立完成，不能推进观察/答题主线。
	for frog_step in range(3):
		player.position = frog_stones[frog_step].global_position
		check_interactions()
		assert(near_frog_stone, "L02 蛙石未按顺序激活")
		advance_frog_activity()
	assert(frog_activity_step == 3 and not frog_fog.visible, "L02 听蛙找石完成结果失败")
	advance_filter_activity()
	assert(filter_activity_step == 1 and filter_clamp.get_parent() == player.body_root, "L02 木夹拾取失败")
	await advance_filter_activity()
	assert(filter_fixed and filter_activity_step == 2 and absf(filter_cloth.rotation.z) < 0.01, "L02 滤布未扶正")
	assert(filter_bubbles.all(func(bubble: Node3D): return bubble.visible), "L02 净水气泡反馈缺失")
	assert(stage == 6 and water_observation_count == 0 and not water_plan_ready, "L02 可选支线不得推进主线")
	# 三类实体数据必须分别近看；未观察完不能规划。
	for observation_position in [Vector3(14.0, 0.18, 1.8), Vector3(20.0, 0.18, -0.1), Vector3(22.4, 0.18, -0.2)]:
		player.position = observation_position
		check_interactions()
	assert(water_observation_count == 3 and stage == 7, "L02 三类数据观察门失败")
	# 两个错项不解锁，正确答案只解锁逐桶操作。
	solve_water(2)
	assert(water_wrong_preview.visible and not water_overflow_preview.visible, "L02 2桶错项缺少13L世界预览")
	solve_water(4)
	assert(water_overflow_preview.visible and not water_wrong_preview.visible, "L02 4桶错项缺少车外第4桶")
	assert(not water_plan_ready and water_buckets_filled == 0, "L02 错项不应解锁水桶")
	solve_water(3)
	assert(water_plan_ready and water_buckets_filled == 0 and water_liters == 3, "L02 正确答案不应自动装水")
	for bucket_index in range(WATER_BUCKETS_REQUIRED):
		pick_empty_water_bucket()
		assert(carrying_empty_bucket and is_instance_valid(carried_task_prop), "L02 必须先从桶架拾空桶")
		if bucket_index == 0:
			travel_to_level(1)
			travel_to_level(2)
			assert(carrying_empty_bucket and carried_task_prop.get_parent() == player.body_root, "L02 携空桶回访状态丢失")
		await fill_water_bucket()
		assert(carrying_bucket and water_buckets_filled == bucket_index + 1, "L02 空桶→满桶负重状态失败")
		assert(is_instance_valid(carried_task_prop) and carried_task_prop.visible, "L02 满桶必须是可见手持实体")
		assert(carried_task_prop.get_parent() == player.body_root and player.action_pose == "carry", "L02 满桶未进入双手负重步态")
		assert(carried_task_prop.get_child_count() >= 3, "L02 满桶缺少水面或桶盖实体")
		load_water_bucket()
		assert(not carrying_bucket and water_buckets_loaded == bucket_index + 1, "L02 满桶→三槽车状态失败")
		assert(water_buckets[bucket_index].get_parent() == water_cart and water_buckets[bucket_index].visible, "L02 满桶未落入对应车槽")
		assert(bucket_water_nodes[bucket_index].get_parent() == water_cart and bucket_water_nodes[bucket_index].visible, "L02 车槽中的桶水面不可见")
		assert(bucket_lids[bucket_index].get_parent() == water_cart and bucket_lids[bucket_index].visible, "L02 满桶盖未进入车槽")
		assert(player.action_pose == "normal", "L02 入车后未恢复放松步态")
		if bucket_index == 0 or bucket_index == 1:
			travel_to_level(1)
			travel_to_level(2)
			assert(water_buckets_loaded == bucket_index + 1 and water_buckets[bucket_index].get_parent() == water_cart, "L02 已装/车载中间态回访丢失")
	assert(water_buckets_loaded == 3 and water_liters == 3, "L02 入车前水箱不得变化")
	# 未到水箱不能倒；推到箱旁后逐桶验证3/8/13/18。
	water_cart.position = Vector3(22.4, 0.18, -0.2)
	await pour_water_bucket()
	assert(water_buckets_poured == 0 and water_liters == 3, "L02 远离水箱时不得倒水")
	var push_start := water_cart.position - Vector3(0, 0, 1.15)
	var push_end := Vector3(14.0, 0.18, 0.8)
	player.position = push_start
	var wheel_rotation_before := water_cart_wheels[0].rotation.x
	cart_pushing = true
	for push_step in range(1, 41):
		player.position = push_start.lerp(push_end, float(push_step) / 40.0)
		_process(0.1)
	assert(water_cart.position.distance_to(Vector3(14.0, 0.18, 0.8)) < 2.3 and water_cart_wheels[0].rotation.x != wheel_rotation_before, "L02 实际推车或轮转失败")
	cart_pushing = false
	var previous_fill_height := water_tank_fill.scale.y
	for expected_liters in [8, 13, 18]:
		await pour_water_bucket()
		assert(water_liters == expected_liters, "L02 水箱实体刻度未按3/8/13/18推进")
		assert(water_tank_fill.scale.y > previous_fill_height, "L02 水箱水位高度未单调上涨")
		assert(water_buckets[water_buckets_poured - 1].visible and not bucket_water_nodes[water_buckets_poured - 1].visible, "L02 倒水后空桶未放回车槽")
		assert(water_stamps[water_buckets_poured - 1].visible and not water_pour_stream.visible, "L02 倒水水流/印章阶段未收束")
		previous_fill_height = water_tank_fill.scale.y
		if expected_liters == 8:
			travel_to_level(1)
			travel_to_level(2)
			assert(water_buckets_poured == 1 and water_liters == 8 and water_stamps[0].visible, "L02 已倒1桶回访状态丢失")
	assert(stage == 8 and water_buckets_poured == 3, "L02 补水未完成")
	var saved_cart_position := water_cart.position
	travel_to_level(1)
	travel_to_level(2)
	assert(water_liters == 18 and water_buckets_poured == 3 and water_cart.position == saved_cart_position, "L02 回访未保留中间/完成状态")
	assert(frog_activity_step == 3 and not frog_fog.visible and filter_fixed, "L02 回访未保留支线状态")
	print("QA_LEVEL2_PASS: observations 3/3; wrong 2/4; fill-carry-load x3; cart; tank 3/8/13/18; revisit preserved")
	get_tree().quit()

func open_puzzle(kind: String) -> void:
	if kind == "bridge" and bridge_inspect_count < 3:
		show_toast("先检查桥西端、木料堆和护栏架三处数据。")
		return
	current_puzzle = kind
	match kind:
		"bridge":
			puzzle_heading.text = "先制订真正能施工的修桥方案"
			puzzle_question.text = "桥全长 16 米，两端各有 2 米桥面完好。\n9 块木板中有 3 块必须加固护栏，其余每块能铺 2 米。\n缺口能否刚好铺满？桥面应该铺几块？"
			puzzle_feedback.text = "要同时核对缺口长度和分配后剩余的木板。"
			puzzle_answer_values = [4, 6, 8]
		"water":
			puzzle_heading.text = "规划一次刚好的淡水补给"
			puzzle_question.text = "营地需要 18 升水，水壶里已有 3 升。\n每个水桶能装 5 升。还需要装满几个水桶？"
			puzzle_feedback.text = "先算还缺多少升，再看每桶能装多少升。"
			puzzle_answer_values = [2, 3, 4]
		"camp":
			puzzle_heading.text = "给营地铺上草垫"
			puzzle_question.text = "营地长 6 米、宽 4 米，中间的火塘是 2 米 × 2 米。\n每块草垫能铺 2 平方米，需要多少块？"
			puzzle_feedback.text = "先扣除不能铺的火塘面积，再换算成草垫数量。"
			puzzle_answer_values = [8, 10, 12]
	for index in range(puzzle_answer_buttons.size()):
		puzzle_answer_buttons[index].text = "%d 块" % puzzle_answer_values[index]
	puzzle_feedback.add_theme_color_override("font_color", DEEP_OCEAN)
	player.controls_enabled = false
	puzzle_panel.visible = true
	action_button.visible = false

func submit_puzzle_answer(index: int) -> void:
	var answer := puzzle_answer_values[index]
	match current_puzzle:
		"bridge": solve_bridge(answer)
		"water": solve_water(answer)
		"camp": solve_camp(answer)

func build_puzzle_panel(layer: CanvasLayer) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-310, -185)
	panel.custom_minimum_size = Vector2(620, 370)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", make_panel_style(SHELL, 28, DEEP_OCEAN, 2))
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	puzzle_heading = Label.new()
	puzzle_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	puzzle_heading.add_theme_font_size_override("font_size", 31)
	puzzle_heading.add_theme_color_override("font_color", INK)
	box.add_child(puzzle_heading)
	puzzle_question = Label.new()
	puzzle_question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	puzzle_question.add_theme_font_size_override("font_size", 23)
	puzzle_question.add_theme_color_override("font_color", INK)
	box.add_child(puzzle_question)
	puzzle_feedback = Label.new()
	puzzle_feedback.text = "要同时核对缺口长度和分配后剩余的木板。"
	puzzle_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	puzzle_feedback.add_theme_font_size_override("font_size", 17)
	puzzle_feedback.add_theme_color_override("font_color", DEEP_OCEAN)
	box.add_child(puzzle_feedback)
	var answers := HBoxContainer.new()
	answers.alignment = BoxContainer.ALIGNMENT_CENTER
	answers.add_theme_constant_override("separation", 16)
	box.add_child(answers)
	for index in range(3):
		var answer := Button.new()
		answer.custom_minimum_size = Vector2(130, 58)
		answer.add_theme_font_size_override("font_size", 20)
		style_button(answer, DEEP_OCEAN)
		answer.pressed.connect(func(): submit_puzzle_answer(index))
		answers.add_child(answer)
		puzzle_answer_buttons.append(answer)
	var cancel := Button.new()
	cancel.text = "再观察一下"
	cancel.custom_minimum_size = Vector2(160, 44)
	style_button(cancel, WOOD)
	cancel.pressed.connect(close_puzzle)
	box.add_child(cancel)
	return panel

func build_completion_panel(layer: CanvasLayer) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-300, -170)
	panel.custom_minimum_size = Vector2(600, 340)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", make_panel_style(SHELL, 28, CORAL, 2))
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	completion_heading = Label.new()
	completion_summary = Label.new()
	completion_reward = Label.new()
	for label in [completion_heading, completion_summary, completion_reward]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28 if label == completion_heading else 21)
		label.add_theme_color_override("font_color", INK)
		box.add_child(label)
	completion_next_button = Button.new()
	completion_next_button.custom_minimum_size = Vector2(310, 60)
	style_button(completion_next_button, LEAF)
	completion_next_button.pressed.connect(advance_level)
	box.add_child(completion_next_button)
	var close := Button.new()
	close.text = "留在当前岛继续看看"
	close.custom_minimum_size = Vector2(220, 48)
	style_button(close, WOOD)
	close.pressed.connect(func():
		panel.visible = false
		player.controls_enabled = true
	)
	box.add_child(close)
	var replay := Button.new()
	replay.text = "重新玩一次"
	replay.custom_minimum_size = Vector2(220, 52)
	style_button(replay, DEEP_OCEAN)
	replay.pressed.connect(func(): get_tree().reload_current_scene())
	box.add_child(replay)
	return panel

func check_interactions() -> void:
	if not game_started:
		return
	for bait in bait_nodes.duplicate():
		if is_instance_valid(bait):
			bait.position.y = 0.45 + sin(elapsed * 3.2 + bait.position.x) * 0.12
			bait.rotation.y += 0.03
			if player.global_position.distance_to(bait.global_position) < 0.85:
				bait.queue_free()
				bait_nodes.erase(bait)
				bait_count += 1
				stage = maxi(stage, 1)
				show_toast("找到闪光鱼饵！码头附近好像有鱼影。")
				update_quest()
	near_pier = player.position.distance_to(Vector3(-5, 0.18, -6.2)) < 2.1
	near_bridge = player.position.distance_to(Vector3(6.0 + bridge_planks_laid * 2.0, 0.18, 2)) < 2.0
	near_bridge_supply = bridge_plan_ready and not carrying_bridge_plank and player.position.distance_to(Vector3(2.0, 0.18, 2.0)) < 1.8
	near_chest = bridge_open and player.position.distance_to(Vector3(23.0, 0.18, 2)) < 1.6
	active_bridge_inspection = -1
	for inspect_index in range(bridge_inspection_nodes.size()):
		if not bridge_inspected[inspect_index] and player.global_position.distance_to(bridge_inspection_nodes[inspect_index].global_position) < 1.05:
			active_bridge_inspection = inspect_index
			break
	if stage >= 6:
		for clue in water_clues.duplicate():
			if is_instance_valid(clue):
				clue.position.y = 0.46 + sin(elapsed * 3.4 + clue.position.x) * 0.10
				clue.rotation.y += 0.035
				if player.global_position.distance_to(clue.global_position) < 0.85:
					var observation_index := int(clue.get_meta("observation_index", -1))
					if observation_index >= 0:
						water_observations[observation_index] = true
					clue.queue_free()
					water_clues.erase(clue)
					clue_count += 1
					water_observation_count = clue_count
					if clue_count >= 3:
						stage = 7
						lake_beacon.visible = true
						show_toast("三处水滴都指向同一个方向，淡水湖光柱出现了！")
					else:
						show_toast("找到水滴线索 %d/3，继续沿着湿润的草叶寻找。" % clue_count)
					update_quest()
	near_empty_bucket = water_plan_ready and not carrying_bucket and not carrying_empty_bucket and water_buckets_filled < 3 and player.position.distance_to(Vector3(20.4, 0.18, -0.4)) < 1.7
	near_lake = stage >= 7 and player.position.distance_to(Vector3(20.4, 0.18, -2.4)) < 2.0
	near_water_cart = water_buckets_filled > water_buckets_loaded and player.position.distance_to(Vector3(22.4, 0.18, -0.2)) < 1.8
	near_water_tank = water_buckets_loaded == 3 and not cart_pushing and water_cart.position.distance_to(Vector3(14.0, 0.18, 0.8)) < 2.3 and water_buckets_poured < 3 and player.position.distance_to(Vector3(14.0, 0.18, 0.8)) < 1.8
	near_frog_stone = stage >= 6 and frog_activity_step < 3 and player.global_position.distance_to(frog_stones[frog_activity_step].global_position) < 1.05
	near_filter = stage >= 6 and not filter_fixed and player.position.distance_to(Vector3(13.15, 0.18, 1.05) if filter_activity_step == 0 else Vector3(14.0, 0.18, 0.8)) < 1.25
	if stage >= 9:
		for marker_data in camp_markers.duplicate():
			var marker: Node3D = marker_data["node"]
			if is_instance_valid(marker):
				marker.position.y = 0.42 + sin(elapsed * 3.2 + marker.position.x) * 0.10
				marker.rotation.y += 0.035
				if player.global_position.distance_to(marker.global_position) < 0.85:
					marker.queue_free()
					camp_markers.erase(marker_data)
					camp_measure_count += 1
					show_toast("%s（%d/3）" % [marker_data["message"], camp_measure_count])
					if camp_measure_count >= 3:
						stage = 10
						camp_beacon.visible = true
					update_quest()
	near_camp_supply = camp_plan_ready and not carrying_camp_mat and camp_mats_laid < CAMP_MATS_REQUIRED and player.position.distance_to(Vector3(40.0, 0.18, 2.0)) < 2.0
	near_camp_target = carrying_camp_mat and camp_mats_laid < CAMP_MATS_REQUIRED and player.position.distance_to(camp_target_positions[camp_mats_laid]) < 1.15
	near_tent = stage == 11 and player.position.distance_to(Vector3(34.0, 0.18, 3.5)) < 1.8
	near_safety = false
	active_safety_node = null
	if stage == 12:
		for safety in safety_nodes:
			if safety.visible and player.global_position.distance_to(safety.global_position) < 1.0:
				near_safety = true
				active_safety_node = safety
				break
	travel_target = 0
	if unlocked_level >= 2 and player.position.distance_to(Vector3(6.0, 0.18, 7.0)) < 1.6:
		travel_target = 2
	elif player.position.distance_to(Vector3(11.3, 0.18, 3.7)) < 1.6:
		travel_target = 1
	elif unlocked_level >= 3 and player.position.distance_to(Vector3(24.7, 0.18, 3.7)) < 1.6:
		travel_target = 3
	elif player.position.distance_to(Vector3(29.3, 0.18, 3.7)) < 1.6:
		travel_target = 2
	update_action_button()

func update_action_button() -> void:
	action_button.visible = false
	action_button.disabled = false
	if puzzle_panel.visible or completion_panel.visible:
		return
	if near_chest and not chest_open:
		action_button.text = "打开宝箱"
		action_button.visible = true
	elif active_bridge_inspection >= 0:
		action_button.text = ["检查桥的长度与两端", "清点桥面木板", "检查护栏预留板"][active_bridge_inspection]
		action_button.visible = true
	elif near_bridge_supply:
		action_button.text = "抱起第 %d 块桥板" % [bridge_planks_laid + 1]
		action_button.visible = true
	elif near_bridge and carrying_bridge_plank:
		action_button.text = "把桥板放入第 %d 个槽" % [bridge_planks_laid + 1]
		action_button.visible = true
	elif near_bridge and not bridge_open and bridge_inspect_count >= 3:
		action_button.text = "检查断桥"
		action_button.visible = true
	elif near_pier and bait_count > 0 and not fish_caught:
		action_button.text = "收线！" if fishing_state == 4 else ("观察浮标…" if fishing_state in [1, 2, 3] else "抛竿钓鱼")
		action_button.visible = true
		action_button.disabled = fishing_state in [1, 2, 3]
	elif near_water_tank:
		action_button.text = "倒入第 %d 桶水" % [water_buckets_poured + 1]
		action_button.visible = true
	elif near_water_cart:
		action_button.text = "把满桶放入推车 %d/3" % [water_buckets_loaded + 1]
		action_button.visible = true
	elif near_empty_bucket:
		action_button.text = "从桶架提起空桶 %d/3" % [water_buckets_filled + 1]
		action_button.visible = true
	elif water_buckets_loaded == 3 and not cart_pushing and player.position.distance_to(water_cart.position) < 1.8 and water_cart.position.distance_to(Vector3(14.0, 0.18, 0.8)) >= 2.3:
		action_button.text = "握住车把，推回水箱"
		action_button.visible = true
	elif near_lake:
		action_button.text = "蹲下浸水并加盖" if carrying_empty_bucket else ("规划取水" if not water_plan_ready else "先去桶架提空桶")
		action_button.visible = true
	elif near_frog_stone:
		action_button.text = "循蛙声踏上安全石 %d/3" % [frog_activity_step + 1]
		action_button.visible = true
	elif near_filter:
		action_button.text = "拾起木夹" if filter_activity_step == 0 else "踮脚扶正滤布"
		action_button.visible = true
	elif near_camp_supply:
		action_button.text = "抱起第 %d 卷草垫" % [camp_mats_laid + 1]
		action_button.visible = true
	elif stage == 10 and not camp_plan_ready and player.position.distance_to(Vector3(40.0, 0.18, 2.0)) < 2.0:
		action_button.text = "计算草垫数量"
		action_button.visible = true
	elif near_camp_target:
		action_button.text = "展开并压平草垫 %d/%d" % [camp_mats_laid + 1, CAMP_MATS_REQUIRED]
		action_button.visible = true
	elif near_tent:
		action_button.text = "与刺猬合作搭帐篷 %d/4" % [tent_steps + 1]
		action_button.visible = true
	elif near_safety:
		action_button.text = "检查营地安全 %d/3" % [safety_checks + 1]
		action_button.visible = true
	elif travel_target > 0:
		action_button.text = "乘渡船前往第 %d 岛" % travel_target
		action_button.visible = true

func perform_action() -> void:
	if near_chest and bridge_open and not chest_open:
		open_chest()
	elif active_bridge_inspection >= 0:
		inspect_bridge_checkpoint(active_bridge_inspection)
	elif near_bridge_supply:
		pick_bridge_plank()
	elif near_bridge and carrying_bridge_plank:
		lay_bridge_plank()
	elif near_camp_target:
		lay_camp_mat()
	elif near_camp_supply:
		pick_camp_mat()
	elif near_tent:
		build_tent_step()
	elif near_safety:
		perform_safety_check()
	elif stage == 10 and not camp_plan_ready and player.position.distance_to(Vector3(40.0, 0.18, 2.0)) < 2.0:
		open_puzzle("camp")
	elif near_water_tank:
		await pour_water_bucket()
	elif near_water_cart:
		load_water_bucket()
	elif near_empty_bucket:
		pick_empty_water_bucket()
	elif water_buckets_loaded == 3 and not cart_pushing and player.position.distance_to(water_cart.position) < 1.8:
		cart_pushing = true
		player.set_expression("effort")
		show_toast("双手推车，三只满桶会随车移动。把车推到西侧水箱。")
	elif near_lake:
		if carrying_empty_bucket:
			await fill_water_bucket()
		elif not water_plan_ready:
			open_puzzle("water")
	elif near_frog_stone:
		advance_frog_activity()
	elif near_filter:
		await advance_filter_activity()
	elif near_bridge and not bridge_open and bridge_inspect_count >= 3:
		open_puzzle("bridge")
	elif near_pier and bait_count > 0 and not fish_caught:
		if fishing_state == 0:
			await start_fishing_attempt()
		elif fishing_state == 4:
			await resolve_fishing_attempt(true)
	elif travel_target > 0:
		travel_to_level(travel_target)

func inspect_bridge_checkpoint(index: int) -> void:
	if index < 0 or index >= 3 or bridge_inspected[index]:
		return
	bridge_inspected[index] = true
	bridge_inspect_count += 1
	bridge_inspection_nodes[index].set_meta("inspected", true)
	bridge_inspection_nodes[index].visible = false
	show_toast(["整桥16米，两端各有2米完好。", "木料堆共有9块，每块覆盖2米。", "护栏架必须预留3块，不能拿去铺桥面。"][index])
	if bridge_inspect_count == 3:
		stage = maxi(stage, 3)
		bridge_beacon.visible = true
	update_quest()

func start_fishing_attempt(hook_delay := 2.2, reaction_window := 1.8) -> void:
	fishing_attempt_token += 1
	var token := fishing_attempt_token
	fishing_last_result = "casting"
	if fishing_rig.get_parent() != player.body_root:
		fishing_rig.reparent(player.body_root)
	fishing_rig.position = Vector3(0.34, 0.82, -0.38)
	fishing_rig.rotation = Vector3.ZERO
	# 1 就位：站宽、挺背、专注看浮标。
	fishing_state = 1
	player.play_task_pose("fish_ready")
	player.set_expression("focused")
	sync_fishing_rig("ready")
	await get_tree().create_timer(0.35).timeout
	if token != fishing_attempt_token: return
	# 2 蓄力：后脚压地，竿向肩后弯。
	fishing_state = 2
	player.play_task_pose("fish_backcast")
	sync_fishing_rig("backcast")
	await get_tree().create_timer(0.28).timeout
	if token != fishing_attempt_token: return
	# 3 抛出与等待：竿前送，线展开，浮标落水并有呼吸表演。
	fishing_state = 3
	player.play_task_pose("cast")
	player.set_expression("happy")
	sync_fishing_rig("cast")
	show_toast("浮标落水了……看着它，沉下时立即收线。", hook_delay)
	await get_tree().create_timer(hook_delay).timeout
	if token != fishing_attempt_token: return
	# 4 咬钩：浮标先沉、线绷直、竿尖下弯，进入反应窗。
	fishing_state = 4
	fish_visual.position = Vector3(-5, -0.12, -8.2)
	fish_visual.visible = true
	sync_fishing_rig("hooked")
	player.play_task_pose("fish_hooked")
	player.set_expression("surprised")
	show_toast("啵！浮标沉下了，快收线！", reaction_window)
	await get_tree().create_timer(reaction_window).timeout
	if token == fishing_attempt_token and fishing_state == 4:
		await resolve_fishing_attempt(false)

func resolve_fishing_attempt(success: bool) -> void:
	fishing_attempt_token += 1
	if success:
		# 5 收线、6 鱼跃、7 落篓与收藏。
		fishing_state = 5
		fishing_last_result = "reeling"
		player.play_task_pose("reel")
		player.set_expression("effort")
		sync_fishing_rig("reel")
		var fish_tween := create_tween()
		fish_tween.tween_property(fish_visual, "position", Vector3(-5.4, 1.15, -7.15), 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await fish_tween.finished
		fishing_state = 6
		player.set_expression("surprised")
		var basket_tween := create_tween()
		basket_tween.tween_property(fish_visual, "position", fish_basket.position + Vector3(0, 0.32, 0), 0.28).set_trans(Tween.TRANS_QUAD)
		await basket_tween.finished
		fishing_state = 7
		bait_count = maxi(0, bait_count - 1)
		fish_caught = true
		fishing_last_result = "caught"
		fish_visual.visible = false
		fish_basket_catch.visible = true
		collection_fish_model.visible = true
		stage = maxi(stage, 3)
		bridge_beacon.visible = true
		player.play_task_pose("fish_celebrate")
		player.set_expression("happy")
		show_toast("银鳞飞鱼跃出水面，落进湿鱼篓后才加入收藏箱！")
		await get_tree().create_timer(0.45).timeout
		player.finish_task_pose()
	else:
		fishing_state = 6
		fishing_last_result = "failed"
		bait_count = maxi(0, bait_count - 1)
		fish_visual.visible = false
		sync_fishing_rig("fail")
		player.play_task_pose("fish_fail")
		player.set_expression("sad")
		show_toast("鱼挣脱了。海龟递来新饵：浮标沉下时再收线。")
		bait_count += 1
		await get_tree().create_timer(0.65).timeout
		fishing_state = 0
		player.finish_task_pose()
	update_quest()

func sync_fishing_rig(phase: String) -> void:
	var poses := {
		"ready": [0.0, 1.0, Vector3(-0.25, -0.15, -1.15), "float"],
		"backcast": [0.28, 0.82, Vector3(0.10, 0.25, 0.42), "float"],
		"cast": [-0.48, 1.18, Vector3(-0.35, -0.68, -2.10), "float"],
		"hooked": [-0.68, 1.30, Vector3(-0.35, -0.92, -2.10), "fish_mouth"],
		"reel": [-0.58, 0.72, Vector3(-0.25, -0.30, -1.10), "fish_mouth"],
		"fail": [-0.22, 0.88, Vector3(-0.28, -0.45, -1.60), "float"]
	}
	var pose: Array = poses[phase]
	fishing_rod.rotation.z = pose[0]
	fishing_line.scale.y = pose[1]
	fishing_float.position = pose[2]
	fishing_line.set_meta("endpoint", pose[3])
	fishing_rig.set_meta("phase", phase)

func solve_bridge(answer: int) -> void:
	if answer != BRIDGE_PLANKS_REQUIRED:
		if answer == 4:
			puzzle_feedback.text = "4块只覆盖8米：世界中两个红色槽仍没有桥板。"
			for preview in bridge_shortfall_preview:
				preview.visible = true
			guardrail_highlight.scale = Vector3.ONE
			guardrail_highlight.set_meta("highlighted", false)
		else:
			puzzle_feedback.text = "8块挪用了护栏材料：看，海龟正在敲亮必须预留的3块护栏板。"
			for preview in bridge_shortfall_preview:
				preview.visible = false
			guardrail_highlight.scale = Vector3.ONE * 1.28
			guardrail_highlight.set_meta("highlighted", true)
		puzzle_feedback.add_theme_color_override("font_color", CORAL.darkened(0.18))
		return
	for preview in bridge_shortfall_preview:
		preview.visible = false
	guardrail_highlight.scale = Vector3.ONE
	guardrail_highlight.set_meta("highlighted", false)
	puzzle_panel.visible = false
	player.controls_enabled = true
	bridge_plan_ready = true
	stage = maxi(stage, 3)
	show_toast("计算正确。现在回到桥边，亲手铺下 6 块桥板。")
	update_quest()

func lay_bridge_plank() -> void:
	if not bridge_plan_ready or bridge_open or not carrying_bridge_plank:
		return
	if is_instance_valid(carried_task_prop):
		carried_task_prop.queue_free()
	carried_task_prop = null
	carrying_bridge_plank = false
	player.set_carrying(null, false)
	var board := add_box(self, Vector3(bridge_slot_centers[bridge_planks_laid], 0.75, 2), Vector3(1.96, 0.16, 1.96), WOOD)
	board.set_meta("bridge_slot_index", bridge_planks_laid)
	bridge_laid_nodes.append(board)
	create_tween().tween_property(board, "position:y", 0.18, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	bridge_planks_laid += 1
	show_toast("咚！桥板已固定 %d/%d。" % [bridge_planks_laid, BRIDGE_PLANKS_REQUIRED], 1.2)
	if bridge_planks_laid >= BRIDGE_PLANKS_REQUIRED:
		bridge_open = true
		bridge_plan_ready = false
		stage = 4
		bridge_beacon.visible = false
		chest_beacon.visible = true
		bridge_barrier.queue_free()
		show_toast("6 块桥板都由你铺好了！现在可以亲自走到对岸。")
	update_quest()

func pick_bridge_plank() -> void:
	if not bridge_plan_ready or carrying_bridge_plank or bridge_planks_laid >= BRIDGE_PLANKS_REQUIRED:
		return
	bridge_plank_supply[bridge_planks_laid].visible = false
	carried_task_prop = add_box(self, player.position, Vector3(2.0, 0.14, 0.42), WOOD)
	player.set_carrying(carried_task_prop, true)
	carrying_bridge_plank = true
	show_toast("双手抱稳桥板，脚步会变短。把它送到断桥槽位。")

func close_puzzle() -> void:
	puzzle_panel.visible = false
	player.controls_enabled = true
	puzzle_feedback.add_theme_color_override("font_color", DEEP_OCEAN)

func open_chest() -> void:
	chest_open = true
	stage = 5
	player.controls_enabled = false
	chest_beacon.visible = false
	var tween := create_tween().set_parallel(true)
	tween.tween_property(chest_lid, "position:y", 0.82, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(chest_lid, "rotation:x", -0.72, 0.55)
	await tween.finished
	chest_shell_visual.visible = true
	var shell_tween := create_tween()
	shell_tween.tween_property(chest_shell_visual, "position:y", 1.35, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await shell_tween.finished
	show_completion("bridge")
	update_quest()

func solve_water(answer: int) -> void:
	if water_observation_count < 3:
		puzzle_feedback.text = "先近看水箱、5L木桶和三槽车三类实体数据。"
		return
	if answer != WATER_BUCKETS_REQUIRED:
		puzzle_feedback.text = "2 桶还差 5 升。" if answer == 2 else "4 桶把已有的 3 升也重复计算了。"
		puzzle_feedback.add_theme_color_override("font_color", CORAL.darkened(0.18))
		water_wrong_preview.visible = answer == 2
		water_overflow_preview.visible = answer == 4
		return
	water_wrong_preview.visible = false
	water_overflow_preview.visible = false
	puzzle_panel.visible = false
	player.controls_enabled = true
	water_plan_ready = true
	show_toast("计算正确。现在在湖边亲手装满 3 个水桶。")
	update_quest()

func pick_empty_water_bucket() -> void:
	if not water_plan_ready or carrying_bucket or carrying_empty_bucket or water_buckets_filled >= WATER_BUCKETS_REQUIRED:
		return
	var bucket_index := water_buckets_filled
	water_buckets[bucket_index].visible = false
	carried_task_prop = Node3D.new()
	carried_task_prop.name = "CarriedEmptyWaterBucket%d" % (bucket_index + 1)
	add_child(carried_task_prop)
	add_cylinder(carried_task_prop, Vector3.ZERO, 0.58, 0.28, Color("d9c69b"))
	player.set_carrying(carried_task_prop, true)
	carrying_empty_bucket = true
	show_toast("空桶已提起。走到豆形湖砾石岸边再浸水。")

func advance_frog_activity() -> void:
	if frog_activity_step >= 3:
		return
	frog_stones[frog_activity_step].scale = Vector3.ONE * 1.18
	frog_audio.position = frog_stones[frog_activity_step].position
	frog_audio.play()
	frog_activity_step += 1
	if frog_activity_step < 3:
		var jump_tween := create_tween()
		jump_tween.tween_property(frog_guide, "position", frog_stones[frog_activity_step].position + Vector3(0, 0.55, 0), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		jump_tween.tween_property(frog_guide, "position:y", frog_stones[frog_activity_step].position.y + 0.24, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		show_toast("青蛙跳向下一块浅色安全石。%d/3" % frog_activity_step)
	else:
		frog_fog.visible = false
		show_toast("三块安全石已找到，南岸薄雾散开了。")

func advance_filter_activity() -> void:
	if filter_fixed:
		return
	if filter_activity_step == 0:
		filter_activity_step = 1
		filter_clamp.reparent(player.body_root)
		filter_clamp.position = Vector3(0.34, 1.05, -0.58)
		player.set_expression("focused")
		show_toast("拾起木夹。到滤布前把松脱的一角夹紧。")
		return
	player.controls_enabled = false
	player.play_task_pose("filter_reach")
	player.set_expression("focused")
	var fix_tween := create_tween().set_parallel(true)
	fix_tween.tween_property(filter_cloth, "rotation:z", 0.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	fix_tween.tween_property(player.body_root, "position:y", 0.12, 0.25)
	await fix_tween.finished
	filter_clamp.reparent(level_two_root)
	filter_clamp.position = Vector3(14.48, 1.78, 0.8)
	for bubble in filter_bubbles:
		bubble.visible = true
	filter_fixed = true
	filter_activity_step = 2
	player.finish_task_pose()
	player.set_expression("happy")
	player.controls_enabled = true
	show_toast("滤布已扶正，水箱出现连续净水气泡。")

func fill_water_bucket() -> void:
	if not water_plan_ready or water_buckets_filled >= WATER_BUCKETS_REQUIRED or carrying_bucket or not carrying_empty_bucket:
		return
	var bucket_index := water_buckets_filled
	var shore_bucket := water_buckets[bucket_index]
	var shore_water := bucket_water_nodes[bucket_index]
	player.controls_enabled = false
	player.play_task_pose("scoop")
	player.set_expression("focused")
	# 空桶被提到岸边并蹲身浸入湖水。
	var dip_start_y := shore_bucket.position.y
	var dip_tween := create_tween().set_parallel(true)
	dip_tween.tween_property(shore_bucket, "position:y", dip_start_y - 0.22, 0.25).set_trans(Tween.TRANS_SINE)
	dip_tween.tween_property(player.body_root, "position:y", -0.10, 0.25)
	await dip_tween.finished
	# 桶内五格水线以五个可见节拍涨满，总计约0.5秒。
	shore_water.visible = true
	shore_water.scale.y = 0.04
	for water_step in range(1, 6):
		var fill_tween := create_tween()
		fill_tween.tween_property(shore_water, "scale:y", float(water_step) / 5.0, 0.10)
		await fill_tween.finished
	# 满桶离水，随后成为角色双手持有的可见实体。
	var lift_tween := create_tween().set_parallel(true)
	lift_tween.tween_property(shore_bucket, "position:y", dip_start_y, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lift_tween.tween_property(player.body_root, "position:y", 0.0, 0.25)
	await lift_tween.finished
	if is_instance_valid(carried_task_prop):
		carried_task_prop.queue_free()
	carried_task_prop = null
	carrying_empty_bucket = false
	shore_bucket.visible = false
	shore_water.visible = false
	shore_water.scale.y = 1.0
	water_buckets_filled += 1
	carried_task_prop = Node3D.new()
	carried_task_prop.name = "CarriedFullWaterBucket%d" % water_buckets_filled
	add_child(carried_task_prop)
	add_cylinder(carried_task_prop, Vector3.ZERO, 0.58, 0.28, Color("d9c69b"))
	add_cylinder(carried_task_prop, Vector3(0, 0.30, 0), 0.08, 0.23, Color("4bbfe5"))
	add_cylinder(carried_task_prop, Vector3(0, 0.36, 0), 0.05, 0.29, WOOD.darkened(0.08))
	player.set_carrying(carried_task_prop, true)
	carrying_bucket = true
	player.controls_enabled = true
	show_toast("5 格水线依次涨满。现在双手把满桶搬到三槽推车。", 1.5)
	update_quest()

func load_water_bucket() -> void:
	if not carrying_bucket or water_buckets_loaded >= water_buckets_filled:
		return
	if is_instance_valid(carried_task_prop):
		carried_task_prop.queue_free()
	carried_task_prop = null
	player.set_carrying(null, false)
	carrying_bucket = false
	var slot := water_buckets_loaded
	water_buckets[slot].visible = true
	bucket_water_nodes[slot].visible = true
	bucket_lids[slot].visible = true
	water_buckets[slot].reparent(water_cart)
	bucket_water_nodes[slot].reparent(water_cart)
	bucket_lids[slot].reparent(water_cart)
	water_buckets[slot].position = Vector3(-0.65 + slot * 0.65, 0.45, 0)
	bucket_water_nodes[slot].position = Vector3(-0.65 + slot * 0.65, 0.73, 0)
	bucket_lids[slot].position = Vector3(-0.65 + slot * 0.65, 0.80, 0)
	water_buckets_loaded += 1
	show_toast("满桶已落入推车槽 %d/3。" % water_buckets_loaded)
	if water_buckets_loaded == 3:
		water_plan_ready = false
		show_toast("三槽已满。推着车走回西侧水箱，再逐桶倒入。")
	update_quest()

func set_water_tank_level(liters: int) -> void:
	water_liters = liters
	var ratio := float(liters) / 18.0
	water_tank_fill.scale.y = ratio
	water_tank_fill.position.y = 0.15 + 0.60 * ratio

func pour_water_bucket() -> void:
	if pouring_water or water_buckets_loaded < 3 or water_buckets_poured >= 3 or water_cart.position.distance_to(Vector3(14.0, 0.18, 0.8)) >= 2.3:
		return
	pouring_water = true
	player.controls_enabled = false
	player.set_expression("effort")
	var poured_index := water_buckets_poured
	var pour_tween := create_tween().set_parallel(true)
	pour_tween.tween_property(water_buckets[poured_index], "rotation:z", -1.05, 0.30)
	pour_tween.tween_property(bucket_water_nodes[poured_index], "rotation:z", -1.05, 0.30)
	pour_tween.tween_property(bucket_lids[poured_index], "position:y", 1.02, 0.22)
	await pour_tween.finished
	water_pour_stream.visible = true
	await get_tree().create_timer(0.32).timeout
	bucket_water_nodes[poured_index].visible = false
	bucket_lids[poured_index].visible = false
	water_buckets_poured += 1
	set_water_tank_level(3 + water_buckets_poured * 5)
	water_pour_stream.visible = false
	water_buckets[poured_index].rotation.z = 0.0
	water_buckets[poured_index].visible = true
	water_stamps[poured_index].visible = true
	var stamp_tween := create_tween()
	stamp_tween.tween_property(water_otter_arm, "rotation:z", -0.65, 0.12)
	stamp_tween.tween_property(water_otter_arm, "rotation:z", 0.0, 0.14)
	await stamp_tween.finished
	pouring_water = false
	player.controls_enabled = true
	player.set_expression("happy")
	show_toast("水箱刻度升到 %d L（%d/3 桶）。" % [water_liters, water_buckets_poured])
	if water_buckets_poured == 3:
		stage = 8
		lake_beacon.visible = false
		show_completion("water")
		player.controls_enabled = false
	update_quest()

func solve_camp(answer: int) -> void:
	if answer != CAMP_MATS_REQUIRED:
		puzzle_feedback.text = "8 块只铺了 16 平方米。" if answer == 8 else "12 块没有扣除火塘的 4 平方米。"
		puzzle_feedback.add_theme_color_override("font_color", CORAL.darkened(0.18))
		return
	puzzle_panel.visible = false
	player.controls_enabled = true
	camp_beacon.visible = false
	camp_plan_ready = true
	mat_target_beacon.position = camp_target_positions[0] + Vector3(0, 1.0, 0)
	mat_target_beacon.visible = true
	show_toast("计算正确。跟随黄色标记，亲手铺下 10 块草垫。")
	update_quest()

func lay_camp_mat() -> void:
	if not camp_plan_ready or camp_mats_laid >= CAMP_MATS_REQUIRED or not carrying_camp_mat:
		return
	if is_instance_valid(carried_task_prop):
		carried_task_prop.queue_free()
	carried_task_prop = null
	carrying_camp_mat = false
	player.set_carrying(null, false)
	player.play_task_pose("press")
	var target := camp_target_positions[camp_mats_laid]
	var mat := add_box(level_three_root, target + Vector3(0, 0.55, 0), Vector3(1.90, 0.12, 0.88), Color("b9df72"))
	create_tween().tween_property(mat, "position:y", target.y, 0.20).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	camp_mats.append(mat)
	camp_mats_laid += 1
	show_toast("草垫已铺好 %d/%d。" % [camp_mats_laid, CAMP_MATS_REQUIRED], 1.1)
	if camp_mats_laid >= CAMP_MATS_REQUIRED:
		camp_plan_ready = false
		mat_target_beacon.visible = false
		stage = 11
		show_toast("10 块草垫全部铺好，中央 4 平方米火塘保持留空。")
	else:
		mat_target_beacon.position = camp_target_positions[camp_mats_laid] + Vector3(0, 1.0, 0)
	update_quest()

func pick_camp_mat() -> void:
	if not camp_plan_ready or carrying_camp_mat or camp_mats_laid >= CAMP_MATS_REQUIRED:
		return
	carried_task_prop = add_cylinder(self, player.position, 1.75, 0.24, Color("b9df72"))
	carried_task_prop.rotation.z = PI * 0.5
	player.set_carrying(carried_task_prop, true)
	carrying_camp_mat = true
	show_toast("抱起一卷2×1米草垫，送到黄色轮廓后展开压平。")

func build_tent_step() -> void:
	if stage != 11 or tent_steps >= 4:
		return
	tent_steps += 1
	tent_root.visible = true
	tent_root.scale = Vector3.ONE * (0.45 + tent_steps * 0.1375)
	player.set_expression("effort" if tent_steps < 4 else "happy")
	show_toast(["和刺猬各扶住一根帐篷杆。", "第一根帐篷杆已经立起。", "拉紧两枚绳钉，刺猬固定另外两枚。", "帐篷完全撑起，门灯亮了。 "][tent_steps - 1])
	if tent_steps == 4:
		stage = 12
		for safety in safety_nodes:
			safety.visible = true
	update_quest()

func perform_safety_check() -> void:
	if stage != 12 or not is_instance_valid(active_safety_node):
		return
	active_safety_node.visible = false
	safety_checks += 1
	show_toast(["排水沟通向南坡，没有积水。", "火塘四周没有草垫，净空安全。", "帐篷绳已拉紧，岩壁缓冲带未被占用。 "][safety_checks - 1])
	if safety_checks == 3:
		stage = 13
		player.set_expression("happy")
		show_completion("camp")
		player.controls_enabled = false
	update_quest()

func show_completion(kind: String) -> void:
	match kind:
		"bridge":
			completion_heading.text = "✨ 第一关完成！"
			completion_summary.text = "小巴修好断桥，并亲自走到了对岸。"
			completion_reward.text = "获得：星光贝壳 × 1"
			completion_next_button.text = "进入下一关：寻找淡水湖"
		"water":
			completion_heading.text = "💧 第二关完成！"
			completion_summary.text = "3 个水桶装满后，营地正好有 18 升水。"
			completion_reward.text = "解锁：远处的营地岛"
			completion_next_button.text = "进入下一关：铺设营地"
		"camp":
			completion_heading.text = "⛺ 第三关完成！"
			completion_summary.text = "10 块草垫铺满可用区域，火塘保持畅通。"
			completion_reward.text = "三关纵向切片完成"
			completion_next_button.text = "留在营地继续看看"
	completion_panel.visible = true

func advance_level() -> void:
	if stage == 5:
		start_level_two()
	elif stage == 8:
		start_level_three()
	else:
		completion_panel.visible = false
		player.controls_enabled = true

func start_level_two() -> void:
	completion_panel.visible = false
	level_two_root.visible = true
	stage = 6
	unlocked_level = maxi(unlocked_level, 2)
	clue_count = 0
	title_label.text = "第 2 关 · 寻找淡水湖"
	player.position = Vector3(13.3, 0.18, 3.2)
	player.controls_enabled = true
	show_toast("已到达下一座岛！先寻找 3 处发光的水滴线索。")
	update_quest()

func start_level_three() -> void:
	completion_panel.visible = false
	level_three_root.visible = true
	stage = 9
	unlocked_level = maxi(unlocked_level, 3)
	camp_measure_count = 0
	title_label.text = "第 3 关 · 铺设安全营地"
	player.position = Vector3(32.2, 0.18, 2.8)
	player.controls_enabled = true
	show_toast("先到营地的 3 个标记点，量清尺寸和火塘范围。")
	update_quest()

func travel_to_level(level: int) -> void:
	if level < 1 or level > unlocked_level:
		return
	completion_panel.visible = false
	match level:
		1:
			player.position = Vector3(6.0, 0.18, 6.2)
			title_label.text = "第 1 关 · 断桥修复"
		2:
			player.position = Vector3(12.1, 0.18, 3.5)
			title_label.text = "第 2 关 · 淡水补给"
		3:
			player.position = Vector3(30.1, 0.18, 3.5)
			title_label.text = "第 3 关 · 铺设安全营地"
	player.controls_enabled = true
	travel_target = 0
	show_toast("渡船抵达第 %d 岛，已完成的建设和收藏都保留着。" % level)
	update_quest()

func update_quest() -> void:
	match stage:
		0:
			progress_label.text = "任务 1/3 · 自由探索"
			objective_label.text = "先在草地上寻找闪光的鱼饵，不用急着做题。"
		1, 2:
			progress_label.text = "任务 1/3 · 去码头钓鱼"
			objective_label.text = "鱼饵准备好了，沿木栈道去海边。"
		3:
			progress_label.text = "任务 2/3 · 铺桥板 %d/%d" % [bridge_planks_laid, BRIDGE_PLANKS_REQUIRED] if bridge_plan_ready else "任务 2/3 · 前往断桥"
			objective_label.text = "在断桥边亲手铺板。" if bridge_plan_ready else "钓到银鳞鱼！前往红色光柱标记的断桥。"
		4:
			progress_label.text = "任务 3/3 · 寻找宝箱"
			objective_label.text = "穿过新修好的桥，寻找金色光柱。"
		5:
			progress_label.text = "第一关完成 · 已到达对岸"
			objective_label.text = "打开结算面板，选择进入下一关：寻找淡水湖。"
		6:
			progress_label.text = "第 2 关 · 水滴线索 %d/3" % clue_count
			objective_label.text = "在新岛的草地上寻找 3 处发光水滴，它们会指向淡水湖。"
		7:
			progress_label.text = "第 2 关 · 装水 %d/%d 桶" % [water_buckets_filled, WATER_BUCKETS_REQUIRED] if water_plan_ready else "第 2 关 · 前往淡水湖"
			objective_label.text = "在湖边亲手装满每个桶。" if water_plan_ready else "跟随蓝色光柱到湖边，规划刚好够用的取水量。"
		8:
			progress_label.text = "第 2 关完成 · 找到淡水"
			objective_label.text = "淡水已经装好，选择进入下一关铺设营地。"
		9:
			progress_label.text = "第 3 关 · 测量营地 %d/3" % camp_measure_count
			objective_label.text = "走到 3 个黄色标记点，确认长、宽和火塘尺寸。"
		10:
			progress_label.text = "第 3 关 · 铺草垫 %d/%d" % [camp_mats_laid, CAMP_MATS_REQUIRED] if camp_plan_ready else "第 3 关 · 计算草垫"
			objective_label.text = "走到当前黄色标记处，亲手铺下一块草垫。" if camp_plan_ready else "前往黄色光柱旁的草垫堆，计算实际可铺面积。"
		11:
			progress_label.text = "第 3 关 · 走进新营地"
			objective_label.text = "草垫已经铺好，亲自走进营地区域完成验收。"
		12:
			progress_label.text = "第 3 关完成 · 营地通过验收"
			objective_label.text = "草垫围绕火塘铺好，营地可以安全使用了。"
	if is_instance_valid(inventory_label):
		inventory_label.text = "收藏箱  🟡鱼饵×%d   🐟银鳞鱼%s   🐚星光贝壳%s   💧淡水 %dL" % [bait_count, "✓" if fish_caught else "—", "✓" if chest_open else "—", water_liters]

func show_toast(message: String, duration := 2.6) -> void:
	toast_token += 1
	var current_token := toast_token
	toast_label.text = message
	toast_label.visible = true
	await get_tree().create_timer(duration).timeout
	if current_token == toast_token:
		toast_label.visible = false

func update_camera(delta: float) -> void:
	var desired := player.position + Vector3(0, 8.2, 10.4)
	camera.position = camera.position.lerp(desired, minf(1.0, delta * 5.0))
	camera.look_at(player.position + Vector3(0, 0.9, 0))

func animate_world(delta: float) -> void:
	for index in swaying_trees.size():
		var tree := swaying_trees[index]
		tree.rotation.z = sin(elapsed * 0.9 + index * 1.4) * 0.025
	if bridge_beacon.visible:
		bridge_beacon.scale = Vector3.ONE * (0.9 + sin(elapsed * 4.0) * 0.16)
	if chest_beacon.visible:
		chest_beacon.scale = Vector3.ONE * (0.9 + sin(elapsed * 4.8) * 0.18)
	if is_instance_valid(lake_beacon) and lake_beacon.visible:
		lake_beacon.scale = Vector3.ONE * (0.9 + sin(elapsed * 4.4) * 0.18)
	if is_instance_valid(filter_cloth) and not filter_fixed:
		filter_cloth.rotation.z = 0.22 + sin(elapsed * 7.0) * 0.055
	if is_instance_valid(water_windmill):
		water_windmill.rotation.z += delta * (1.8 if filter_fixed else 0.55)
	for fly_index in range(water_dragonflies.size()):
		var fly := water_dragonflies[fly_index]
		var base: Vector3 = fly.get_meta("base_position")
		fly.position = base + Vector3(cos(elapsed * 2.2 + fly_index) * 0.28, sin(elapsed * 3.0 + fly_index) * 0.10, sin(elapsed * 2.2 + fly_index) * 0.22)
	if is_instance_valid(camp_beacon) and camp_beacon.visible:
		camp_beacon.scale = Vector3.ONE * (0.9 + sin(elapsed * 4.6) * 0.18)
	if is_instance_valid(mat_target_beacon) and mat_target_beacon.visible:
		mat_target_beacon.scale = Vector3.ONE * (0.9 + sin(elapsed * 5.0) * 0.20)
	if is_instance_valid(fish_visual) and fish_visual.visible and fishing_state == 2:
		fish_visual.position.y = -0.05 + sin(elapsed * 7.0) * 0.18
		fish_visual.rotation.z = sin(elapsed * 8.0) * 0.18
	for crab in get_tree().get_nodes_in_group("ambient_crabs"):
		crab.rotation.y += delta * 0.25
		crab.position.x = crab.get_meta("base_x") + sin(elapsed * 0.75 + crab.get_instance_id() * 0.01) * 0.32
	for frog in get_tree().get_nodes_in_group("ambient_frogs"):
		frog.scale.y = 1.0 + maxf(0.0, sin(elapsed * 1.7 + frog.get_instance_id() * 0.02)) * 0.10
	for bird in get_tree().get_nodes_in_group("ambient_birds"):
		bird.position.y = bird.get_meta("base_y") + sin(elapsed * 1.3 + bird.get_instance_id() * 0.02) * 0.12

func is_walkable(position_value: Vector3) -> bool:
	var west_head := pow((position_value.x + 6.0) / 10.0, 2) + pow((position_value.z - 2.0) / 7.0, 2) <= 1.0
	var west_bay := pow((position_value.x + 4.0) / 5.0, 2) + pow((position_value.z + 4.0) / 4.0, 2) <= 1.0
	var island := west_head or west_bay
	var pier := position_value.x >= -5.9 and position_value.x <= -4.1 and position_value.z >= -8.0 and position_value.z <= -4.4
	var east_tide_pool := pow((position_value.x - 23.0) / 5.0, 2) + pow((position_value.z - 2.0) / 3.2, 2) <= 1.0
	var bridge_lane := position_value.z >= 1.0 and position_value.z <= 3.0
	var bridge_end := bridge_lane and ((position_value.x >= 4.0 and position_value.x <= 6.0) or (position_value.x >= 18.0 and position_value.x <= 20.0))
	var laid_bridge := false
	if bridge_lane and position_value.x >= 6.0 and position_value.x <= 18.0:
		var slot_index := clampi(int(floor((position_value.x - 6.0) / 2.0)), 0, 5)
		laid_bridge = slot_index < bridge_planks_laid
	var level_two_west := pow((position_value.x - 15.5) / 6.8, 2) + pow(position_value.z / 5.8, 2) <= 1.0
	var level_two_east := pow((position_value.x - 21.5) / 6.4, 2) + pow((position_value.z + 0.8) / 5.3, 2) <= 1.0
	var level_two_island := stage >= 6 and (level_two_west or level_two_east)
	var level_three_main := pow((position_value.x - 36.2) / 7.3, 2) + pow(position_value.z / 7.8, 2) <= 1.0
	var level_three_rocky_lobe := pow((position_value.x - 32.0) / 4.2, 2) + pow((position_value.z - 2.0) / 4.8, 2) <= 1.0
	var level_three_island := stage >= 9 and (level_three_main or level_three_rocky_lobe)
	for obstacle in tree_obstacles:
		if Vector2(position_value.x, position_value.z).distance_to(obstacle) < 0.72:
			return false
	return island or pier or east_tide_pool or bridge_end or laid_bridge or level_two_island or level_three_island

func add_fish(parent: Node3D, position_value: Vector3) -> Node3D:
	var fish := Node3D.new()
	fish.position = position_value
	parent.add_child(fish)
	add_sphere(fish, Vector3.ZERO, Vector3(0.42, 0.18, 0.16), Color("8de4f2"), true)
	var tail := add_box(fish, Vector3(0.48, 0, 0), Vector3(0.30, 0.34, 0.08), Color("54b9d1"))
	tail.rotation.z = PI / 4.0
	add_sphere(fish, Vector3(-0.24, 0.07, -0.15), Vector3.ONE * 0.035, Color("243b3b"))
	return fish

func add_travel_dock(parent: Node3D, position_value: Vector3, label_text: String) -> void:
	add_box(parent, position_value, Vector3(1.8, 0.16, 1.3), WOOD)
	var boat := add_box(parent, position_value + Vector3(0, 0.20, -0.62), Vector3(1.25, 0.28, 0.58), Color("e47f5f"))
	boat.rotation.z = 0.04
	add_box(parent, position_value + Vector3(0, 0.42, -0.62), Vector3(0.70, 0.08, 0.48), SHELL)
	add_world_label(parent, position_value + Vector3(0, 1.25, 0), label_text, DEEP_OCEAN)

func add_fishing_gear(parent: Node3D, position_value: Vector3) -> void:
	fishing_rig = Node3D.new()
	fishing_rig.position = position_value
	parent.add_child(fishing_rig)
	fishing_rod = add_cylinder(fishing_rig, Vector3(0, 0.95, 0), 2.15, 0.045, WOOD.darkened(0.22))
	fishing_rod.rotation.z = -0.34
	fishing_line = add_cylinder(fishing_rig, Vector3(-0.36, 0.30, -0.25), 1.55, 0.010, SHELL.darkened(0.08))
	fishing_line.rotation.x = 0.18
	fishing_float = add_sphere(fishing_rig, Vector3(-0.36, -0.44, -0.39), Vector3(0.07, 0.10, 0.07), CORAL, true)
	fishing_line.set_meta("endpoint", "float")

func add_fish_basket(position_value: Vector3) -> void:
	fish_basket = Node3D.new()
	fish_basket.position = position_value
	add_child(fish_basket)
	add_cylinder(fish_basket, Vector3.ZERO, 0.38, 0.42, Color("b7864f"))
	add_cylinder(fish_basket, Vector3(0, 0.28, 0), 0.06, 0.34, Color("6b4a35"))
	fish_basket_catch = add_fish(fish_basket, Vector3(0, 0.32, 0))
	fish_basket_catch.scale = Vector3.ONE * 0.38
	fish_basket_catch.visible = false

func add_turtle_workshop(position_value: Vector3) -> void:
	var workshop := Node3D.new()
	workshop.position = position_value
	add_child(workshop)
	add_box(workshop, Vector3(0, 0.9, 0.45), Vector3(3.0, 1.8, 1.3), Color("e6c37b"))
	add_box(workshop, Vector3(0, 1.9, 0.45), Vector3(3.5, 0.20, 1.7), CORAL)
	var turtle := Node3D.new()
	turtle.position = Vector3(0, 0.55, -0.55)
	workshop.add_child(turtle)
	add_sphere(turtle, Vector3.ZERO, Vector3(0.45, 0.28, 0.34), Color("579b78"))
	add_sphere(turtle, Vector3(0, 0.16, -0.36), Vector3(0.26, 0.22, 0.22), Color("85bc82"))
	add_sphere(turtle, Vector3(0, 0.02, 0.20), Vector3(0.37, 0.25, 0.16), Color("8c6b43"))
	add_box(turtle, Vector3(0.35, 0.20, -0.48), Vector3(0.07, 0.55, 0.07), WOOD.darkened(0.3))

func add_crab(parent: Node3D, position_value: Vector3, angle: float) -> void:
	var crab := Node3D.new()
	crab.position = position_value
	crab.rotation.y = angle
	crab.set_meta("base_x", position_value.x)
	crab.add_to_group("ambient_crabs")
	parent.add_child(crab)
	add_sphere(crab, Vector3.ZERO, Vector3(0.22, 0.10, 0.17), CORAL)
	for x in [-0.25, 0.25]:
		add_sphere(crab, Vector3(x, 0.05, -0.05), Vector3(0.10, 0.045, 0.045), CORAL.darkened(0.08))
		add_sphere(crab, Vector3(x * 1.18, 0.12, -0.10), Vector3.ONE * 0.035, INK)

func add_reeds(parent: Node3D, position_value: Vector3) -> void:
	for index in range(5):
		var offset := Vector3((index % 3) * 0.14 - 0.14, 0, (index / 3) * 0.13)
		add_cylinder(parent, position_value + offset + Vector3(0, 0.30, 0), 0.62 + index * 0.025, 0.025, Color("5f985c"))

func add_lily_pad(parent: Node3D, position_value: Vector3) -> void:
	var pad := add_cylinder(parent, position_value, 0.025, 0.24, Color("62a86c"))
	pad.scale.z = 0.72
	add_sphere(parent, position_value + Vector3(0.05, 0.05, 0), Vector3(0.06, 0.035, 0.06), Color("f7b8d1"))

func add_frog(parent: Node3D, position_value: Vector3) -> void:
	var frog := Node3D.new()
	frog.position = position_value
	frog.add_to_group("ambient_frogs")
	parent.add_child(frog)
	add_sphere(frog, Vector3.ZERO, Vector3(0.18, 0.10, 0.16), Color("72b85e"))
	for x in [-0.10, 0.10]:
		add_sphere(frog, Vector3(x, 0.10, -0.08), Vector3.ONE * 0.055, Color("91cf70"))
		add_sphere(frog, Vector3(x, 0.12, -0.125), Vector3.ONE * 0.022, INK)

func add_tent(parent: Node3D, position_value: Vector3) -> Node3D:
	var tent := Node3D.new()
	tent.position = position_value
	parent.add_child(tent)
	var left_panel := add_box(tent, Vector3(-0.45, 0.58, 0), Vector3(1.35, 0.10, 1.85), Color("e98a55"))
	left_panel.rotation.z = 0.64
	var right_panel := add_box(tent, Vector3(0.45, 0.58, 0), Vector3(1.35, 0.10, 1.85), Color("f1a061"))
	right_panel.rotation.z = -0.64
	add_box(tent, Vector3(0, 0.38, -0.92), Vector3(0.62, 0.72, 0.05), Color("4d4039"))
	for x in [-0.92, 0.92]:
		add_cylinder(tent, Vector3(x, 0.12, 0), 0.24, 0.035, WOOD.darkened(0.2))
	return tent

func add_bird(parent: Node3D, position_value: Vector3) -> void:
	var bird := Node3D.new()
	bird.position = position_value
	bird.set_meta("base_y", position_value.y)
	bird.add_to_group("ambient_birds")
	parent.add_child(bird)
	add_sphere(bird, Vector3.ZERO, Vector3(0.18, 0.11, 0.12), SHELL)
	add_sphere(bird, Vector3(0, 0.05, -0.15), Vector3(0.09, 0.08, 0.09), SHELL)
	add_box(bird, Vector3(0, 0.04, -0.25), Vector3(0.05, 0.04, 0.12), Color("e5ad4f"))

func add_world_label(parent: Node3D, position_value: Vector3, text_value: String, color: Color) -> Label3D:
	var label := Label3D.new()
	label.position = position_value
	label.text = text_value
	label.font_size = 44
	label.pixel_size = 0.008
	label.modulate = color
	label.outline_size = 10
	label.outline_modulate = Color.WHITE
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	return label

func add_simple_tree(parent: Node3D, position_value: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = position_value
	parent.add_child(tree)
	add_cylinder(tree, Vector3(0, 1.2, 0), 2.4, 0.23, WOOD.darkened(0.3))
	for offset in [Vector3(0.45, 2.4, 0), Vector3(-0.45, 2.4, 0), Vector3(0, 2.4, 0.45), Vector3(0, 2.4, -0.45)]:
		add_sphere(tree, offset, Vector3(0.78, 0.30, 0.52), LEAF)

func add_tree(position_value: Vector3, phase: float) -> void:
	var tree := Node3D.new()
	tree.position = position_value
	tree.rotation.y = phase
	add_child(tree)
	add_cylinder(tree, Vector3(0, 1.35, 0), 2.7, 0.25, WOOD.darkened(0.3))
	for offset in [Vector3(0.5, 2.7, 0), Vector3(-0.5, 2.7, 0), Vector3(0, 2.7, 0.5), Vector3(0, 2.7, -0.5)]:
		add_sphere(tree, offset, Vector3(0.9, 0.32, 0.58), LEAF)
	swaying_trees.append(tree)

func add_decorations() -> void:
	for data in [
		[Vector3(-3.8, 0.22, -0.8), CORAL], [Vector3(3.3, 0.22, -1.1), Color("ffd166")],
		[Vector3(-4.0, 0.22, 1.7), Color("fff0a8")], [Vector3(4.4, 0.22, 0.4), CORAL],
		[Vector3(0.6, 0.22, -3.5), Color("f8b4c8")]
	]:
		var flower := Node3D.new()
		flower.position = data[0]
		add_child(flower)
		add_cylinder(flower, Vector3(0, 0.17, 0), 0.34, 0.035, LEAF)
		for offset in [Vector3(0.10, 0.37, 0), Vector3(-0.10, 0.37, 0), Vector3(0, 0.37, 0.10), Vector3(0, 0.37, -0.10)]:
			add_sphere(flower, offset, Vector3.ONE * 0.10, data[1])
		add_sphere(flower, Vector3(0, 0.37, 0), Vector3.ONE * 0.07, Color("ffd447"))
	for data in [[Vector3(-6.2, 0.18, 0.4), Vector3(0.55, 0.28, 0.42)], [Vector3(5.8, 0.16, 3.2), Vector3(0.42, 0.22, 0.36)], [Vector3(-1.0, 0.13, -5.4), Vector3(0.34, 0.17, 0.28)]]:
		add_sphere(self, data[0], data[1], Color("a9b8ae"))

func add_beacon(position_value: Vector3, color: Color) -> MeshInstance3D:
	return add_box(self, position_value, Vector3(0.18, 3.4, 0.18), color, 1.0)

func add_box(parent: Node3D, position_value: Vector3, size_value: Vector3, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = make_material(color, emission)
	parent.add_child(node)
	return node

func add_sphere(parent: Node3D, position_value: Vector3, scale_value: Vector3, color: Color, metallic := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	node.mesh = mesh
	node.position = position_value
	node.scale = scale_value * 2.0
	node.material_override = make_material(color, 0.35 if metallic else 0.0, metallic)
	parent.add_child(node)
	return node

func add_cylinder(parent: Node3D, position_value: Vector3, height: float, radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.height = height
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.02
	node.mesh = mesh
	node.position = position_value
	node.material_override = make_material(color)
	parent.add_child(node)
	return node

func make_frog_audio() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var sample_count := 3307
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var time := float(sample_index) / 22050.0
		var envelope := 1.0 - float(sample_index) / sample_count
		var value := int(sin(TAU * (190.0 - time * 430.0) * time) * envelope * 9000.0)
		pcm.encode_s16(sample_index * 2, value)
	stream.data = pcm
	return stream

func make_water_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec3 shallow_color : source_color = vec3(0.34, 0.75, 0.82);
uniform vec3 deep_color : source_color = vec3(0.20, 0.59, 0.66);
void fragment() {
	float ripple = sin(VERTEX.x * 1.8 + TIME * 1.2) * 0.5 + sin(VERTEX.z * 2.4 - TIME * 0.8) * 0.5;
	float band = smoothstep(-0.8, 0.8, ripple);
	ALBEDO = mix(deep_color, shallow_color, 0.60 + band * 0.10);
	ROUGHNESS = 0.28;
	METALLIC = 0.05;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func make_terrain_material(base_color: Color, patch_color: Color, scale_value: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley;
uniform vec3 base_color : source_color;
uniform vec3 patch_color : source_color;
uniform float pattern_scale = 1.0;
void fragment() {
	float pattern = sin(VERTEX.x * pattern_scale) * sin(VERTEX.z * pattern_scale * 0.83);
	pattern += sin((VERTEX.x + VERTEX.z) * pattern_scale * 0.47) * 0.55;
	float blend = smoothstep(-0.5, 0.75, pattern) * 0.24;
	ALBEDO = mix(base_color, patch_color, blend);
	ROUGHNESS = 0.88;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_color", Vector3(base_color.r, base_color.g, base_color.b))
	material.set_shader_parameter("patch_color", Vector3(patch_color.r, patch_color.g, patch_color.b))
	material.set_shader_parameter("pattern_scale", scale_value)
	return material

func make_material(color: Color, emission: float = 0.0, metallic := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78 if not metallic else 0.26
	material.metallic = 0.85 if metallic else 0.0
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material

func make_panel_style(color: Color, radius: int, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.shadow_color = Color(0.12, 0.47, 0.58, 0.13)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	return style

func style_button(button: Button, base_color: Color) -> void:
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", make_panel_style(base_color, 22, Color.TRANSPARENT, 0))
	button.add_theme_stylebox_override("hover", make_panel_style(base_color.lightened(0.08), 22, Color.WHITE, 2))
	button.add_theme_stylebox_override("pressed", make_panel_style(base_color.darkened(0.10), 22, Color.TRANSPARENT, 0))
	button.add_theme_stylebox_override("disabled", make_panel_style(base_color.darkened(0.03), 22, Color.TRANSPARENT, 0))
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.72))
