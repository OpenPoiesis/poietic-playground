## Graphical connector between two diagram objects.
##
class_name Connector extends Node2D

const selection_outline_width: float = 4

@export var origin_point: Vector2 = Vector2():
	set(value):
		origin_point = value
		queue_redraw()
		
@export var target_point: Vector2 = Vector2():
	set(value):
		target_point = value
		queue_redraw()

@export var midpoints: PackedVector2Array:
	set(value):
		midpoints = value
		queue_redraw()

@export var outline_visible: bool = false:
	set(value):
		outline_visible = value
		queue_redraw()

@export var outline_color: Color = Color.BLUE:
	set(value):
		outline_color = value
		queue_redraw()

const outline_width = 4

@export var head_size: float = 500
@export var line_width: float = -1
@export var line_color: Color = Color.WHITE

func set_endpoints(origin: Vector2, target: Vector2):
	self.origin_point = origin
	self.target_point = target
	queue_redraw()

func selection_outline(width: float = selection_outline_width) -> Array[PackedVector2Array]:
	var polygons = Geometry2D.offset_polyline([origin_point, target_point], width, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
	return polygons
