extends Area3D

var linked
var exit_direction := Vector3.FORWARD
var tint := Color(0.13, 0.81, 0.97)

func _ready() -> void:
	name = "Linked Rift"
	monitoring = true
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 3.1, 1.3)
	collider.shape = shape
	add_child(collider)
	var disc := MeshInstance3D.new()
	var surface := SphereMesh.new()
	surface.radius = 1.12
	surface.height = 2.6
	disc.mesh = surface
	disc.scale = Vector3(1.0, 1.0, 0.12)
	var glowing := StandardMaterial3D.new()
	glowing.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glowing.albedo_color = Color(tint.r, tint.g, tint.b, 0.5)
	glowing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glowing.emission_enabled = true
	glowing.emission = tint
	disc.material_override = glowing
	add_child(disc)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.13
	torus.outer_radius = 1.31
	ring.mesh = torus
	ring.rotation.x = PI * 0.5
	ring.scale = Vector3(1.0, 1.0, 1.13)
	var edge := StandardMaterial3D.new()
	edge.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge.albedo_color = tint
	edge.emission_enabled = true
	edge.emission = tint
	ring.material_override = edge
	add_child(ring)
	body_entered.connect(_entered)

func _entered(body: Node3D) -> void:
	if is_instance_valid(linked) and body.has_method("portal_travel"):
		body.call("portal_travel", linked.global_position + linked.exit_direction.normalized() * 2.8, linked.exit_direction.normalized())
