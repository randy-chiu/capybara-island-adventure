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

var player: CapybaraController
var camera: Camera3D
var objective_label: Label
var progress_label: Label
var inventory_label: Label
var toast_label: Label
var action_button: Button
var puzzle_panel: PanelContainer
var completion_panel: PanelContainer
var start_panel: PanelContainer
var start_shade: ColorRect
var puzzle_feedback: Label
var bait_nodes: Array[Node3D] = []
var swaying_trees: Array[Node3D] = []
var bridge_barrier: Node3D
var bridge_beacon: Node3D
var chest_beacon: Node3D
var chest_lid: Node3D
var elapsed := 0.0
var stage := 0
var bait_count := 0
var fishing_state := 0
var near_pier := false
var near_bridge := false
var near_chest := false
var bridge_open := false
var chest_open := false
var game_started := false
var toast_token := 0
var tree_obstacles := [Vector2(-5.7, -3.6), Vector2(4.1, -3.5), Vector2(-4.7, 3.1), Vector2(5.0, 2.2)]

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
	if "--preview-puzzle" in user_args:
		preview_puzzle()
	elif "--preview-chest" in user_args:
		preview_chest()
	elif "--preview-complete" in user_args:
		preview_complete()

func _process(delta: float) -> void:
	elapsed += delta
	update_camera(delta)
	animate_world(delta)
	check_interactions()
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
	var water := add_box(self, Vector3(0, -0.75, 0), Vector3(60, 0.35, 60), OCEAN)
	water.material_override = make_water_material()
	var sand_ground := add_cylinder(self, Vector3(0, -0.38, 0), 0.75, 10.5, SAND)
	sand_ground.material_override = make_terrain_material(SAND, SAND.darkened(0.06), 0.85)
	var grass_ground := add_cylinder(self, Vector3(-0.3, -0.05, -0.2), 0.42, 8.9, PALM)
	grass_ground.material_override = make_terrain_material(PALM, PALM.darkened(0.12), 1.15)
	for data in [[Vector3(-5.7, 0.0, -3.6), 0.1], [Vector3(4.1, 0.0, -3.5), -0.12], [Vector3(-4.7, 0.0, 3.1), 0.18], [Vector3(5.0, 0.0, 2.2), -0.08]]:
		add_tree(data[0], data[1])
	for position_value in [Vector3(-2.8, 0.45, -1.7), Vector3(2.3, 0.45, 0.5), Vector3(-1.4, 0.45, 3.2)]:
		var bait := add_sphere(self, position_value, Vector3.ONE * 0.24, Color("ffd447"), true)
		bait_nodes.append(bait)
	for z in range(0, 6):
		add_box(self, Vector3(2.6, 0.08, 5.7 + z * 0.72), Vector3(2.4, 0.18, 0.58), WOOD)
	add_box(self, Vector3(1.5, 0.35, 7.5), Vector3(0.16, 0.65, 4.5), WOOD.darkened(0.28))
	add_box(self, Vector3(3.7, 0.35, 7.5), Vector3(0.16, 0.65, 4.5), WOOD.darkened(0.28))
	add_sphere(self, Vector3(2.6, -0.48, 9.8), Vector3(0.75, 0.08, 0.32), Color(0.05, 0.25, 0.30, 0.72))
	add_box(self, Vector3(6.7, 0.02, -4.2), Vector3(2.8, 0.26, 2.4), SAND.darkened(0.06))
	bridge_barrier = add_box(self, Vector3(5.2, 0.75, -4.2), Vector3(0.30, 1.55, 2.8), CORAL.darkened(0.2))
	bridge_beacon = add_beacon(Vector3(5.0, 2.0, -4.2), CORAL)
	bridge_beacon.visible = false
	var chest := add_box(self, Vector3(7.0, 0.48, -4.2), Vector3(1.15, 0.75, 0.82), Color("e89224"))
	chest_lid = add_box(chest, Vector3(0, 0.48, 0), Vector3(1.23, 0.14, 0.88), Color("ffd24c"))
	chest_beacon = add_beacon(Vector3(7.0, 2.2, -4.2), Color("ffd447"))
	chest_beacon.visible = false
	for x in [-7.0, -3.5, 1.0, 5.5]:
		add_sphere(self, Vector3(x, 0.2, -6.2 + fmod(absf(x), 2.0)), Vector3(0.65, 0.32, 0.55), Color("5ea94f"))
	add_decorations()

func build_player_and_camera() -> void:
	player = PlayerClass.new()
	player.position = Vector3(0, 0.18, 2.2)
	player.walkable_test = is_walkable
	add_child(player)
	camera = Camera3D.new()
	camera.fov = 46
	add_child(camera)
	camera.position = player.position + Vector3(0, 8.2, 10.4)
	camera.look_at(player.position + Vector3(0, 0.9, 0))

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
	var title := Label.new()
	title.text = "小巴的第一个海岛日"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", INK)
	text_box.add_child(title)
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
	puzzle_panel.visible = true
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
	perform_action()
	assert(stage == 3 and fishing_state == 3, "钓鱼流程失败")
	near_bridge = true
	solve_bridge(6)
	assert(stage == 4 and bridge_open, "修桥流程失败")
	near_chest = true
	await open_chest()
	assert(stage == 5 and chest_open and completion_panel.visible, "开箱结算流程失败")
	print("QA_FLOW_OK: collect -> fish -> math -> bridge -> chest -> reward")
	get_tree().quit()

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
	var heading := Label.new()
	heading.text = "断桥只差最后一段"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 31)
	heading.add_theme_color_override("font_color", INK)
	box.add_child(heading)
	var question := Label.new()
	question.text = "缺口长 12 米，每块木板能铺 2 米。\n需要几块木板才能刚好铺满？"
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question.add_theme_font_size_override("font_size", 23)
	question.add_theme_color_override("font_color", INK)
	box.add_child(question)
	puzzle_feedback = Label.new()
	puzzle_feedback.text = "这不是考试，我们是真的需要把桥修好。"
	puzzle_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	puzzle_feedback.add_theme_font_size_override("font_size", 17)
	puzzle_feedback.add_theme_color_override("font_color", DEEP_OCEAN)
	box.add_child(puzzle_feedback)
	var answers := HBoxContainer.new()
	answers.alignment = BoxContainer.ALIGNMENT_CENTER
	answers.add_theme_constant_override("separation", 16)
	box.add_child(answers)
	for value in [4, 6, 8]:
		var answer := Button.new()
		answer.text = "%d 块" % value
		answer.custom_minimum_size = Vector2(130, 58)
		answer.add_theme_font_size_override("font_size", 20)
		style_button(answer, DEEP_OCEAN)
		answer.pressed.connect(func(): solve_bridge(value))
		answers.add_child(answer)
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
	for text in ["✨ 海岛任务完成！", "小巴钓到了鱼，还用数学修好了断桥。", "获得：星光贝壳 × 1"]:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28 if text.begins_with("✨") else 21)
		label.add_theme_color_override("font_color", INK)
		box.add_child(label)
	var close := Button.new()
	close.text = "继续在岛上逛逛"
	close.custom_minimum_size = Vector2(220, 58)
	style_button(close, LEAF)
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
	near_pier = player.position.distance_to(Vector3(2.6, 0.18, 7.5)) < 2.1
	near_bridge = player.position.distance_to(Vector3(5.0, 0.18, -4.2)) < 1.7
	near_chest = bridge_open and player.position.distance_to(Vector3(7.0, 0.18, -4.2)) < 1.45
	update_action_button()

func update_action_button() -> void:
	action_button.visible = false
	if puzzle_panel.visible or completion_panel.visible:
		return
	if near_chest and not chest_open:
		action_button.text = "打开宝箱"
		action_button.visible = true
	elif near_bridge and stage >= 3 and not bridge_open:
		action_button.text = "检查断桥"
		action_button.visible = true
	elif near_pier and bait_count > 0 and stage < 3:
		action_button.text = "收线！" if fishing_state == 2 else ("等待鱼咬钩…" if fishing_state == 1 else "抛竿钓鱼")
		action_button.visible = true
		action_button.disabled = fishing_state == 1

func perform_action() -> void:
	if near_chest and bridge_open and not chest_open:
		open_chest()
	elif near_bridge and stage >= 3 and not bridge_open:
		player.controls_enabled = false
		puzzle_panel.visible = true
		action_button.visible = false
	elif near_pier and bait_count > 0 and stage < 3:
		if fishing_state == 0:
			fishing_state = 1
			show_toast("浮标落水了……注意水面的动静。", 2.0)
			await get_tree().create_timer(randf_range(1.4, 2.2)).timeout
			if fishing_state != 1:
				return
			fishing_state = 2
			show_toast("扑通！鱼上钩了，快按空格或点击收线！", 2.0)
			await get_tree().create_timer(2.2).timeout
			if fishing_state == 2:
				fishing_state = 0
				show_toast("鱼儿挣脱了！没关系，调整一下再试。")
		elif fishing_state == 2:
			fishing_state = 3
			bait_count -= 1
			stage = 3
			bridge_beacon.visible = true
			show_toast("钓到银鳞鱼！新的红色目标光柱出现了。")
			update_quest()

func solve_bridge(answer: int) -> void:
	if answer != 6:
		puzzle_feedback.text = "还差一点。可以数一数：2、4、6、8、10、12。"
		puzzle_feedback.add_theme_color_override("font_color", CORAL.darkened(0.18))
		return
	puzzle_panel.visible = false
	player.controls_enabled = true
	bridge_open = true
	stage = 4
	bridge_beacon.visible = false
	chest_beacon.visible = true
	bridge_barrier.queue_free()
	for x in range(5):
		add_box(self, Vector3(5.45 + x * 0.55, 0.18, -4.2), Vector3(0.48, 0.16, 2.25), WOOD)
	show_toast("正好 6 块！断桥修好了，金色宝箱光柱出现！")
	update_quest()

func close_puzzle() -> void:
	puzzle_panel.visible = false
	player.controls_enabled = true
	puzzle_feedback.text = "这不是考试，我们是真的需要把桥修好。"
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
	completion_panel.visible = true
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
			progress_label.text = "任务 2/3 · 前往断桥"
			objective_label.text = "钓到银鳞鱼！前往红色光柱标记的断桥。"
		4:
			progress_label.text = "任务 3/3 · 寻找宝箱"
			objective_label.text = "穿过新修好的桥，寻找金色光柱。"
		5:
			progress_label.text = "任务完成 · 星光宝藏"
			objective_label.text = "今天的探险完成了！下一座岛正在准备中。"
	if is_instance_valid(inventory_label):
		inventory_label.text = "鱼饵 %d   银鳞鱼 %d   贝壳 %d" % [bait_count, 1 if stage >= 3 else 0, 1 if chest_open else 0]

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

func animate_world(_delta: float) -> void:
	for index in swaying_trees.size():
		var tree := swaying_trees[index]
		tree.rotation.z = sin(elapsed * 0.9 + index * 1.4) * 0.025
	if bridge_beacon.visible:
		bridge_beacon.scale = Vector3.ONE * (0.9 + sin(elapsed * 4.0) * 0.16)
	if chest_beacon.visible:
		chest_beacon.scale = Vector3.ONE * (0.9 + sin(elapsed * 4.8) * 0.18)

func is_walkable(position_value: Vector3) -> bool:
	var island := pow((position_value.x + 0.3) / 8.7, 2) + pow((position_value.z + 0.2) / 8.7, 2) <= 1.0
	var pier := position_value.x >= 1.72 and position_value.x <= 3.48 and position_value.z >= 4.8 and position_value.z <= 9.4
	var bridge_lane := position_value.z >= -5.55 and position_value.z <= -2.85
	var bridge := bridge_open and bridge_lane and position_value.x >= 4.7 and position_value.x <= 8.3
	if not bridge_open and bridge_lane and position_value.x > 5.0:
		return false
	for obstacle in tree_obstacles:
		if Vector2(position_value.x, position_value.z).distance_to(obstacle) < 0.72:
			return false
	return island or pier or bridge

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
