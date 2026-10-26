extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const PortalScript = preload("res://scripts/portal.gd")

const TALENTS := {
	"Predator": "+25% rifle and ability damage",
	"Swiftstep": "+17% movement speed",
	"Bloodroot": "Heal 16 HP after each elimination",
	"Deep Magazine": "+9 rounds per magazine",
	"Rift Battery": "Instantly refresh both abilities",
	"Reinforced Vest": "+30 maximum armor",
	"Regrowth": "Regenerate 1.2 armor per second",
	"Vital Roots": "+30 maximum health"
}
var rng := RandomNumberGenerator.new()
var player
var bots_left := 0
var elapsed := 0.0
var storm_radius := 55.0
var storm_draw_timer := 0.0
var game_finished := false
var hud: CanvasLayer
var hud_text: Label
var center_text: Label
var notice: Label
var talent_panel: PanelContainer
var talent_buttons: Array[Button] = []
var offered_talents: Array[String] = []
var end_panel: PanelContainer
var end_title: Label
var storm_mesh: MeshInstance3D
var ring_material: StandardMaterial3D
var notice_timer := 0.0

func _ready() -> void:
	rng.seed = 20261026
	_make_environment()
	_make_arena()
	_make_player()
	_make_portals()
	_make_bots()
	_make_loot()
	_make_interface()
	_render_storm_ring()

func _make_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.49, 0.68, 0.66)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.70, 0.79, 0.72)
	env.ambient_light_energy = 0.8
	world.environment = env
	add_child(world)
	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-56, -38, 0)
	sunlight.light_energy = 1.0
	sunlight.shadow_enabled = true
	add_child(sunlight)

func _material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.95
	return result

func _solid_box(at: Vector3, dimensions: Vector3, color: Color, tilt: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	body.rotation.x = tilt
	add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions
	mesh.mesh = box
	mesh.material_override = _material(color)
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	return body

func _make_arena() -> void:
	var soil := Color(0.19, 0.32, 0.22)
	var stone := Color(0.38, 0.44, 0.38)
	_solid_box(Vector3(0, -0.7, 0), Vector3(104, 1.4, 104), soil)
	_solid_box(Vector3(0, 2.0, -51), Vector3(104, 4, 2), stone)
	_solid_box(Vector3(0, 2.0, 51), Vector3(104, 4, 2), stone)
	_solid_box(Vector3(-51, 2.0, 0), Vector3(2, 4, 104), stone)
	_solid_box(Vector3(51, 2.0, 0), Vector3(2, 4, 104), stone)
	# Central temple: cover and a defensible raised platform.
	_solid_box(Vector3(0, 0.65, 0), Vector3(13, 1.3, 13), Color(0.42, 0.46, 0.34))
	_solid_box(Vector3(0, 0.38, 8.7), Vector3(4, 0.4, 6), stone, 0.21)
	for x in [-5.0, 5.0]:
		for z in [-5.0, 5.0]:
			_solid_box(Vector3(x, 2.7, z), Vector3(1.2, 4.0, 1.2), stone)
	_solid_box(Vector3(0, 4.65, 0), Vector3(4.0, 0.6, 4.0), Color(0.41, 0.47, 0.39))
	# Two high grounds: climb via solid ramps or reach via a linked portal.
	_make_tower(Vector3(24, 0, -20), 1.0)
	_make_tower(Vector3(-25, 0, 23), -1.0)
	# Tree trunks provide real ballistic cover. Foliage provides visual concealment.
	for i in range(72):
		var x := rng.randf_range(-45, 45)
		var z := rng.randf_range(-45, 45)
		var point := Vector2(x, z)
		if point.length() < 12 or point.distance_to(Vector2(0, 21)) < 7:
			continue
		if point.distance_to(Vector2(24, -20)) < 11 or point.distance_to(Vector2(-25, 23)) < 11:
			continue
		_make_tree(x, z, rng.randf_range(0.75, 1.35))
	for i in range(34):
		var px := rng.randf_range(-46, 46)
		var pz := rng.randf_range(-46, 46)
		var bush := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = rng.randf_range(1.3, 2.1)
		mesh.height = rng.randf_range(1.8, 2.6)
		bush.mesh = mesh
		bush.position = Vector3(px, 0.45, pz)
		bush.material_override = _material(Color(0.13, rng.randf_range(0.26, 0.41), 0.19))
		add_child(bush)
	for i in range(26):
		var px := rng.randf_range(-44, 44)
		var pz := rng.randf_range(-44, 44)
		if Vector2(px, pz).length() < 10 or Vector2(px, pz).distance_to(Vector2(0, 21)) < 6:
			continue
		_solid_box(Vector3(px, 0.8, pz), Vector3(rng.randf_range(1.8, 3.2), 1.6, rng.randf_range(1.4, 3.1)), stone)
	_solid_box(Vector3(12, 1.0, 11), Vector3(3, 2, 3), stone)
	_solid_box(Vector3(-13, 1.25, -12), Vector3(2.5, 2.5, 4), stone)

func _make_tower(center: Vector3, slope_side: float) -> void:
	var stone := Color(0.36, 0.42, 0.37)
	_solid_box(center + Vector3(0, 3.8, 0), Vector3(9, 0.7, 9), stone)
	for dx in [-3.5, 3.5]:
		for dz in [-3.5, 3.5]:
			_solid_box(center + Vector3(dx, 1.85, dz), Vector3(0.85, 3.8, 0.85), stone)
	# Ramp rises toward the tower and is walkable.
	_solid_box(center + Vector3(0, 1.95, 8.5 * slope_side), Vector3(3.4, 0.48, 17.5), stone, -0.22 * slope_side)
	for dx in [-4.1, 4.1]:
		_solid_box(center + Vector3(dx, 4.6, 0), Vector3(0.4, 1.0, 9), Color(0.24, 0.33, 0.27))

func _make_tree(x: float, z: float, scale_factor: float) -> void:
	var trunk := StaticBody3D.new()
	trunk.position = Vector3(x, 2.4 * scale_factor, z)
	add_child(trunk)
	var bark := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.35 * scale_factor
	cylinder.bottom_radius = 0.53 * scale_factor
	cylinder.height = 4.8 * scale_factor
	bark.mesh = cylinder
	bark.material_override = _material(Color(0.24, 0.21, 0.15))
	trunk.add_child(bark)
	var shape := CollisionShape3D.new()
	var cylinder_shape := CylinderShape3D.new()
	cylinder_shape.radius = 0.52 * scale_factor
	cylinder_shape.height = 4.8 * scale_factor
	shape.shape = cylinder_shape
	trunk.add_child(shape)
	for j in range(2):
		var crown := MeshInstance3D.new()
		var leaves := SphereMesh.new()
		leaves.radius = (2.2 - j * 0.35) * scale_factor
		leaves.height = 3.6 * scale_factor
		crown.mesh = leaves
		crown.position.y = (2.4 + j * 1.7) * scale_factor
		crown.material_override = _material(Color(0.14 + j * 0.025, 0.36 + j * 0.04, 0.21))
		trunk.add_child(crown)

func _make_player() -> void:
	player = PlayerScript.new()
	player.position = Vector3(0, 0.2, 21)
	add_child(player)
	player.talent_offered.connect(_show_talent_choice)
	player.message.connect(_display_notice)
	player.eliminated.connect(_player_eliminated)

func _make_portals() -> void:
	_add_portal_pair(Vector3(-34, 1.4, -27), Vector3(24, 5.3, -20), Vector3.FORWARD, Vector3.FORWARD)
	_add_portal_pair(Vector3(32, 1.4, 30), Vector3(-25, 5.3, 23), Vector3.BACK, Vector3.BACK)
	_add_portal_pair(Vector3(-31, 1.4, 4), Vector3(32, 1.4, 4), Vector3.FORWARD, Vector3.FORWARD)

func _add_portal_pair(a_pos: Vector3, b_pos: Vector3, a_dir: Vector3, b_dir: Vector3) -> void:
	var a := PortalScript.new()
	var b := PortalScript.new()
	a.position = a_pos
	b.position = b_pos
	a.exit_direction = a_dir
	b.exit_direction = b_dir
	a.tint = Color(0.20, 0.85, 1.0)
	b.tint = Color(0.70, 0.42, 1.0)
	add_child(a)
	add_child(b)
	a.linked = b
	b.linked = a

func _make_bots() -> void:
	for i in range(11):
		var angle := (TAU * (float(i) + 0.3)) / 11.0
		var bot := EnemyScript.new()
		bot.position = Vector3(cos(angle) * 37.0, 0.3, sin(angle) * 37.0)
		add_child(bot)
		bot.defeated.connect(_bot_defeated)
		bots_left += 1

func _bot_defeated(bot: Node, killer: Node) -> void:
	bots_left -= 1
	if killer == player:
		player.add_kill()
		_display_notice("ELIMINATED! +50 XP +20 Rift Shards")
	if is_instance_valid(bot) and bot is Node3D:
		_drop_loot((bot as Node3D).global_position + Vector3.UP * 0.9, "crystal", 16)
	if bots_left <= 0:
		_finish_match(true)

func _make_loot() -> void:
	for i in range(26):
		var x := rng.randf_range(-42, 42)
		var z := rng.randf_range(-42, 42)
		if Vector2(x, z).distance_to(Vector2(0, 21)) < 4:
			x += 5
		var kind := "crystal"
		if i % 7 == 0:
			kind = "med"
		elif i % 5 == 0:
			kind = "ammo"
		_drop_loot(Vector3(x, 0.85, z), kind, 18)

func _drop_loot(at: Vector3, kind: String, amount: int) -> void:
	var item := Area3D.new()
	item.name = kind.capitalize() + " Pickup"
	item.position = at
	add_child(item)
	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.05
	collider.shape = sphere
	item.add_child(collider)
	var gem := MeshInstance3D.new()
	var model := SphereMesh.new()
	model.radius = 0.45
	model.height = 0.9
	gem.mesh = model
	var color := Color(0.24, 0.87, 1.0)
	if kind == "med":
		color = Color(0.32, 1.0, 0.49)
	elif kind == "ammo":
		color = Color(1.0, 0.79, 0.29)
	var material := _material(color)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color
	gem.material_override = material
	item.add_child(gem)
	item.body_entered.connect(_collect_loot.bind(kind, amount, item))

func _collect_loot(body: Node3D, kind: String, amount: int, item: Area3D) -> void:
	if body != player or not player.alive or not is_instance_valid(item):
		return
	match kind:
		"crystal":
			player.shards += amount
			player.gain_xp(17)
			_display_notice("+%d Rift Shards / +17 XP" % amount)
		"med":
			player.restore_health(30)
			_display_notice("Recovered 30 HP")
		"ammo":
			player.reserve += 48
			_display_notice("+48 ammunition")
	item.queue_free()

func _make_interface() -> void:
	hud = CanvasLayer.new()
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)
	hud_text = Label.new()
	hud_text.position = Vector2(22, 16)
	hud_text.add_theme_font_size_override("font_size", 20)
	root.add_child(hud_text)
	center_text = Label.new()
	center_text.text = "+"
	center_text.add_theme_font_size_override("font_size", 32)
	center_text.set_anchors_preset(Control.PRESET_CENTER)
	center_text.position = Vector2(-10, -24)
	center_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center_text)
	notice = Label.new()
	notice.position = Vector2(25, 160)
	notice.add_theme_font_size_override("font_size", 21)
	root.add_child(notice)
	var guide := Label.new()
	guide.text = "WASD move  |  SHIFT sprint  |  SPACE jump  |  LEFT CLICK fire  |  R reload\nQ blink  |  E rift pulse  |  H heal (25 shards)  |  ESC mouse  |  portals auto-teleport"
	guide.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	guide.position = Vector2(21, -62)
	guide.add_theme_font_size_override("font_size", 15)
	root.add_child(guide)
	# Talent choice pauses combat; selections are meaningful roguelike upgrades.
	talent_panel = PanelContainer.new()
	talent_panel.custom_minimum_size = Vector2(515, 320)
	talent_panel.set_anchors_preset(Control.PRESET_CENTER)
	talent_panel.position = Vector2(-257, -160)
	talent_panel.visible = false
	root.add_child(talent_panel)
	var options := VBoxContainer.new()
	options.add_theme_constant_override("separation", 12)
	talent_panel.add_child(options)
	var heading := Label.new()
	heading.text = "LEVEL UP — CHOOSE ONE TALENT"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 22)
	options.add_child(heading)
	for i in range(3):
		var button := Button.new()
		button.custom_minimum_size = Vector2(480, 65)
		button.pressed.connect(_choose_talent.bind(i))
		options.add_child(button)
		talent_buttons.append(button)
	end_panel = PanelContainer.new()
	end_panel.custom_minimum_size = Vector2(470, 225)
	end_panel.set_anchors_preset(Control.PRESET_CENTER)
	end_panel.position = Vector2(-235, -112)
	end_panel.visible = false
	root.add_child(end_panel)
	var end_contents := VBoxContainer.new()
	end_panel.add_child(end_contents)
	end_title = Label.new()
	end_title.add_theme_font_size_override("font_size", 26)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_contents.add_child(end_title)
	var restart := Button.new()
	restart.text = "PLAY AGAIN"
	restart.custom_minimum_size = Vector2(350, 62)
	restart.pressed.connect(_restart)
	end_contents.add_child(restart)
	storm_mesh = MeshInstance3D.new()
	ring_material = _material(Color(0.87, 0.22, 0.36))
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	storm_mesh.material_override = ring_material
	add_child(storm_mesh)

func _show_talent_choice() -> void:
	if game_finished:
		return
	var pool: Array[String] = []
	for talent in TALENTS.keys():
		pool.append(talent)
	pool.shuffle()
	offered_talents.clear()
	for i in range(3):
		var choice: String = pool[i]
		offered_talents.append(choice)
		talent_buttons[i].text = "%d. %s — %s" % [i + 1, choice, TALENTS[choice]]
	talent_panel.visible = true
	player.ui_blocked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _choose_talent(index: int) -> void:
	if index < 0 or index >= offered_talents.size():
		return
	player.apply_talent(offered_talents[index])
	talent_panel.visible = false
	get_tree().paused = false
	player.ui_blocked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _display_notice(text: String) -> void:
	if notice == null:
		return
	notice.text = text
	notice_timer = 3.0

func _process(delta: float) -> void:
	if game_finished:
		return
	elapsed += delta
	notice_timer -= delta
	if notice_timer <= 0.0 and notice != null:
		notice.text = ""
	var progress := clampf((elapsed - 55.0) / 470.0, 0.0, 1.0)
	storm_radius = lerpf(55.0, 9.0, progress)
	storm_draw_timer += delta
	if storm_draw_timer > 2.0 and storm_mesh != null:
		storm_draw_timer = 0.0
		_render_storm_ring()
	if elapsed > 55.0:
		if Vector2(player.global_position.x, player.global_position.z).length() > storm_radius:
			player.take_damage(7.0 * delta)
		for bot in get_tree().get_nodes_in_group("bots"):
			var actor := bot as Node3D
			if is_instance_valid(actor) and Vector2(actor.global_position.x, actor.global_position.z).length() > storm_radius:
				actor.call("take_damage", 3.0 * delta)
	if hud_text != null:
		hud_text.text = "PORTAL COMBAT  v1.0  |  %d opponents remaining\nHP %d/%d   ARMOR %d/%d   AMMO %d/%d (+%d)\nLV %d   XP %d   KILLS %d   SHARDS %d\nBLINK [Q] %.0fs   PULSE [E] %.0fs   STORM %.0fm" % [
			bots_left, ceili(player.health), ceili(player.max_health),
			ceili(player.armor), ceili(player.max_armor), player.ammo, player.ammo_max,
			player.reserve, player.level, player.xp, player.kills, player.shards,
			player.blink_cooldown, player.pulse_cooldown, storm_radius
		]

func _render_storm_ring() -> void:
	if storm_mesh == null:
		return
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(97):
		var angle := TAU * float(i) / 96.0
		mesh.surface_add_vertex(Vector3(cos(angle) * storm_radius, 0.15, sin(angle) * storm_radius))
	mesh.surface_end()
	storm_mesh.mesh = mesh

func _player_eliminated() -> void:
	_finish_match(false)

func _finish_match(won: bool) -> void:
	if game_finished:
		return
	game_finished = true
	end_title.text = "VICTORY — LAST RANGER STANDING" if won else "ELIMINATED — THE JUNGLE WINS"
	end_panel.visible = true
	talent_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
