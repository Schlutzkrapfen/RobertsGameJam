extends MeshInstance3D

var _target: Vector3
var _speed: float

func initialize(from: Vector3, to: Vector3, speed: float):
	global_position = from
	_target = to
	_speed = speed
	
	var distance = global_position.distance_to(_target)
	
	if from != to:
		look_at(to, Vector3.UP)
		rotate_object_local(Vector3.FORWARD, PI / 2) #correct for starting rotation
	
	# Prevent division by zero
	if _speed <= 0.0:
		_speed = 1.0
	
	var travel_time = distance / _speed
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", _target, travel_time)
	tween.finished.connect(queue_free)
