extends CharacterBody3D

signal health_changed
signal talent_offered
signal message(text: String)
signal eliminated

var health := 100.0
var max_health := 100.0
var armor := 25.0
var max_armor := 25.0
var level := 1
var xp := 0
var shards := 0
var kills := 0
var ammo := 18
var ammo_max := 18
var reserve := 144
var damage_scale := 1.0
var speed_scale := 1.0
var lifesteal := 0.0
var portal_lock := 0.0
var blink_cooldown := 0.0
var pulse_cooldown := 0.0
var reload_timer := 0.0
var shoot_timer := 0.0
var shield_regen := 0.0
var alive := true
var ui_blocked := false
var camera: Camera3D

func _ready() -> void:
	name = "Ranger"
	add_to_group("fighters")
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.43
	capsule.height = 1.85
	shape.shape = capsule
	shape.position.y = 0.95
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 1.62
	camera.current = true
	camera.fov = 78.0
	add_child(camera)
	var weapon := MeshInstance3D.new()
	var gun := BoxMesh.new()
	gun.size = Vector3(0.19, 0.18, 0.75)
	weapon.mesh = gun
	weapon.position = Vector3(0.33, -0.35, -0.7)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.19, 0.25, 0.23)
	weapon.material_override = metal
	camera.add_child(weapon)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if not alive or ui_blocked:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * 0.0025
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * 0.0025, -1.42, 1.42)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_shoot()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
			KEY_R: _start_reload()
			KEY_Q: _blink()
			KEY_E: _pulse()
			KEY_H: _heal()

func _physics_process(delta: float) -> void:
	if not alive:
		return
	portal_lock = maxf(0.0, portal_lock - delta)
	blink_cooldown = maxf(0.0, blink_cooldown - delta)
	pulse_cooldown = maxf(0.0, pulse_cooldown - delta)
	shoot_timer = maxf(0.0, shoot_timer - delta)
	if reload_timer > 0.0:
		reload_timer -= delta
		if reload_timer <= 0.0:
			var amount: int = mini(ammo_max - ammo, reserve)
			ammo += amount
			reserve -= amount
			message.emit("Reload complete")
	if shield_regen > 0.0:
		armor = minf(max_armor, armor + shield_regen * delta)
	if not is_on_floor():
		velocity.y -= 23.0 * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = 7.0
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := global_transform.basis.x
	right.y = 0.0
	var axis := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
	)
	var direction := (right * axis.x + forward * axis.y).normalized()
	var sprint := 1.45 if Input.is_key_pressed(KEY_SHIFT) else 1.0
	var pace := 7.3 * speed_scale * sprint
	velocity.x = move_toward(velocity.x, direction.x * pace, 23.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * pace, 23.0 * delta)
	move_and_slide()

func _shoot() -> void:
	if shoot_timer > 0.0 or reload_timer > 0.0:
		return
	if ammo <= 0:
		_start_reload()
		return
	ammo -= 1
	shoot_timer = 0.16
	var origin := camera.global_position
	var destination := origin - camera.global_transform.basis.z * 130.0
	var query := PhysicsRayQueryParameters3D.create(origin, destination)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty() and result.collider.has_method("take_damage"):
		result.collider.take_damage(27.0 * damage_scale, self)
	if ammo <= 0:
		_start_reload()

func _start_reload() -> void:
	if ammo >= ammo_max or reserve <= 0 or reload_timer > 0:
		return
	reload_timer = 1.65
	message.emit("Reloading...")

func _blink() -> void:
	if blink_cooldown > 0.0:
		return
	var direction := -camera.global_transform.basis.z
	direction.y = 0.0
	direction = direction.normalized()
	var start := global_position + Vector3.UP
	var query := PhysicsRayQueryParameters3D.create(start, start + direction * 8.0)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var reach := 8.0 if hit.is_empty() else maxf(0.0, start.distance_to(hit.position) - 1.3)
	if reach < 1.0:
		message.emit("Blink obstructed")
		return
	global_position += direction * reach
	velocity = Vector3.ZERO
	blink_cooldown = 9.0
	message.emit("Rift Blink!")

func _pulse() -> void:
	if pulse_cooldown > 0.0:
		return
	pulse_cooldown = 17.0
	for target in get_tree().get_nodes_in_group("bots"):
		if is_instance_valid(target) and global_position.distance_to(target.global_position) < 8.5:
			target.take_damage(33.0 * damage_scale, self)
			target.stun(1.2)
	message.emit("Rift Pulse activated")

func _heal() -> void:
	if shards < 25 or health >= max_health:
		message.emit("Healing costs 25 shards and requires missing health")
		return
	shards -= 25
	health = minf(max_health, health + 35.0)
	health_changed.emit()
	message.emit("Restored 35 health")

func take_damage(amount: float, _attacker: Node = null) -> void:
	if not alive:
		return
	var reduced := amount
	if armor > 0.0:
		var absorbed := minf(armor, reduced * 0.7)
		armor -= absorbed
		reduced -= absorbed
	health -= reduced
	health_changed.emit()
	if health <= 0.0:
		alive = false
		eliminated.emit()

func restore_health(value: float) -> void:
	health = minf(max_health, health + value)
	health_changed.emit()

func gain_xp(amount: int) -> void:
	if level >= 10:
		return
	xp += amount
	var threshold := 45 + (level - 1) * 30
	if xp >= threshold:
		xp -= threshold
		level += 1
		message.emit("LEVEL UP: %d" % level)
		if level % 2 == 0:
			talent_offered.emit()

func add_kill() -> void:
	kills += 1
	shards += 20
	gain_xp(50)
	if lifesteal > 0.0:
		restore_health(lifesteal)

func apply_talent(talent: String) -> void:
	match talent:
		"Predator":
			damage_scale += 0.25
		"Swiftstep":
			speed_scale += 0.17
		"Bloodroot":
			lifesteal += 16.0
		"Deep Magazine":
			ammo_max += 9
			ammo += 9
		"Rift Battery":
			blink_cooldown = 0.0
			pulse_cooldown = 0.0
		"Reinforced Vest":
			max_armor += 30.0
			armor += 30.0
		"Regrowth":
			shield_regen += 1.2
		"Vital Roots":
			max_health += 30.0
			health += 30.0
	message.emit("Talent selected: " + talent)

func portal_travel(exit_pos: Vector3, exit_direction: Vector3) -> void:
	if portal_lock > 0.0:
		return
	global_position = exit_pos
	velocity = exit_direction * 6.0
	portal_lock = 1.8
	message.emit("PORTAL TRAVEL")
