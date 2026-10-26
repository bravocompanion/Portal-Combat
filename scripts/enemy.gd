extends CharacterBody3D

signal defeated(bot: Node, killer: Node)

var health := 95.0
var portal_lock := 0.0
var stun_timer := 0.0
var attack_timer := 0.0
var scan_timer := 0.0
var target
var visual: Node3D
var base_color := Color(0.72, 0.27, 0.24)
var dead := false

func _ready() -> void:
	name = "Jungle Hunter"
	add_to_group("bots")
	add_to_group("fighters")
	var hitbox := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.47
	capsule.height = 1.9
	hitbox.shape = capsule
	hitbox.position.y = 1.0
	add_child(hitbox)
	visual = Node3D.new()
	add_child(visual)
	var chest := MeshInstance3D.new()
	var torso := BoxMesh.new()
	torso.size = Vector3(0.85, 1.1, 0.48)
	chest.mesh = torso
	chest.position.y = 1.03
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	chest.material_override = mat
	visual.add_child(chest)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.34
	sphere.height = 0.68
	head.mesh = sphere
	head.position.y = 1.76
	head.material_override = mat
	visual.add_child(head)
	var weapon := MeshInstance3D.new()
	var rifle := BoxMesh.new()
	rifle.size = Vector3(0.18, 0.16, 0.85)
	weapon.mesh = rifle
	weapon.position = Vector3(0.36, 1.12, -0.38)
	weapon.material_override = mat
	visual.add_child(weapon)

func _physics_process(delta: float) -> void:
	if dead:
		return
	portal_lock = maxf(0.0, portal_lock - delta)
	stun_timer = maxf(0.0, stun_timer - delta)
	attack_timer -= delta
	scan_timer -= delta
	if scan_timer <= 0.0:
		scan_timer = 0.65 + randf() * 0.4
		_acquire_target()
	if not is_on_floor():
		velocity.y -= 23.0 * delta
	if stun_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
	elif is_instance_valid(target):
		var offset := target.global_position - global_position
		offset.y = 0.0
		var distance := offset.length()
		var move_dir := offset.normalized()
		if distance > 9.0:
			velocity.x = move_dir.x * 4.3
			velocity.z = move_dir.z * 4.3
		else:
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		if distance < 25.0 and attack_timer <= 0.0:
			_attack()
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
	move_and_slide()

func _acquire_target() -> void:
	target = null
	var best := 28.0
	for fighter in get_tree().get_nodes_in_group("fighters"):
		if fighter == self or not is_instance_valid(fighter):
			continue
		if fighter.get("health") == null or fighter.health <= 0.0:
			continue
		var distance := global_position.distance_to(fighter.global_position)
		if distance < best:
			best = distance
			target = fighter

func _attack() -> void:
	attack_timer = randf_range(0.9, 1.5)
	if not is_instance_valid(target):
		return
	var origin := global_position + Vector3.UP * 1.45
	var destination := target.global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(origin, destination)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider == target and randf() < 0.73:
		target.call("take_damage", randf_range(7.0, 12.0), self)

func take_damage(amount: float, attacker: Node = null) -> void:
	if dead:
		return
	health -= amount
	if health <= 0.0:
		dead = true
		defeated.emit(self, attacker)
		queue_free()

func stun(seconds: float) -> void:
	stun_timer = maxf(stun_timer, seconds)

func portal_travel(exit_pos: Vector3, exit_direction: Vector3) -> void:
	if portal_lock > 0.0 or dead:
		return
	global_position = exit_pos
	velocity = exit_direction * 4.0
	portal_lock = 2.0
