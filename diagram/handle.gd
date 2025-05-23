class_name Handle extends Node2D

const touch_shape_radius = 10

@export var size: float = 10:
	set(value):
		size = value
		circle.radius = size / 2
		
@export var color: Color = Color.DEEP_SKY_BLUE:
	set(value):
		color = value
		circle.fill_color = value

@export var outline_color: Color = Color.DEEP_SKY_BLUE:
	set(value):
		outline_color = value
		circle.color = value

@export var shape: Shape2D
@export var circle: Circle2D

## User defined value to identify the handle.
@export var index: int = 0

func _init():
	shape = CircleShape2D.new()
	shape.radius = size / 2
	circle = Circle2D.new()
	circle.radius = shape.radius
	circle.width = 2
	circle.color = outline_color
	circle.fill_color = color
	circle.filled = true
	self.z_index = DiagramCanvas.handle_z_index
	self.add_child(circle)
	
func contains_point(point: Vector2):
	var local_point = to_local(point)
	
	var touch_shape: Shape2D = CircleShape2D.new()
	touch_shape.radius = touch_shape_radius
	var collision_trans = self.transform.translated(local_point)

	return shape.collide(self.transform, touch_shape, collision_trans)
