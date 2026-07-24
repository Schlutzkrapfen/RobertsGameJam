@tool
extends StaticBody3D

@export var size := Vector3.ONE:
	set(value):
		size = value
		_update_size()

func _process(_delta):
	if Engine.is_editor_hint() and scale != Vector3.ONE:
		size *= scale
		scale = Vector3.ONE

func _ready():
	if $MeshInstance3D.mesh:
		$MeshInstance3D.mesh = $MeshInstance3D.mesh.duplicate()
	if $CollisionShape3D.shape:
		$CollisionShape3D.shape = $CollisionShape3D.shape.duplicate()

	_update_size()

func _update_size():
	if !is_node_ready():
		return

	($MeshInstance3D.mesh as BoxMesh).size = size
	($CollisionShape3D.shape as BoxShape3D).size = size
