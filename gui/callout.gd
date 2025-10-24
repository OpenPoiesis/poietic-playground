class_name CallOut extends Container

enum PointSide { TOP, BOTTOM, LEFT, RIGHT }

@export var point_side: PointSide = PointSide.TOP:
	set(value):
		point_side = value
		_update_size()
		queue_redraw()

const triangle_size: float = 20.0
const triangle_height: float = (sqrt(3.0) / 2.0) * triangle_size
const padding: float = 10

@export var border_width: float = 2.0
@export var border_color: Color = Color.WHITE

var callout_position: Vector2 = Vector2()


func _ready():
	if get_child_count() > 0:
		_update_size()
		queue_sort()

func _notification(notif):
	if notif == NOTIFICATION_RESIZED:
		_update_size()

func _update_size():
	if get_child_count() == 0:
		return
	var child = get_child(0)

	var child_size = child.get_combined_minimum_size()
	var new_size = Vector2(child_size.x + padding * 2, child_size.y + padding * 2)

	match point_side:
		PointSide.TOP, PointSide.BOTTOM:
			new_size.y += triangle_height
		PointSide.LEFT, PointSide.RIGHT:
			new_size.x += triangle_height

	custom_minimum_size = new_size
	var child_rect = Rect2(Vector2(padding, padding), child_size)
	if point_side == PointSide.TOP:
		child_rect.position.y += triangle_height
	elif point_side == PointSide.LEFT:
		child_rect.position.x += triangle_height

	fit_child_in_rect(child, child_rect)
	queue_redraw()
		
func _draw():
	var rect = Rect2(Vector2.ZERO, self.size)
	match point_side:
		PointSide.TOP:
			rect.position.y += triangle_height
			rect.size.y -= triangle_height
		PointSide.BOTTOM:
			rect.size.y -= triangle_height
		PointSide.LEFT:
			rect.position.x += triangle_height
			rect.size.x -= triangle_height
		PointSide.RIGHT:
			rect.size.x -= triangle_height

	var cut_point = Vector2.ZERO
	
	# Draw content background rect
	draw_rect(rect, Color.BLACK)

	var bubble: PackedVector2Array = PackedVector2Array()

	match point_side:
		PointSide.TOP:
			bubble = [
				Vector2(0, triangle_height),
				Vector2(size.x / 2 - triangle_size/2, triangle_height),
				Vector2(size.x / 2, 0),
				Vector2(size.x / 2 + triangle_size/2, triangle_height),
				Vector2(size.x, triangle_height),
				Vector2(size.x, size.y),
				Vector2(0, size.y),
				Vector2(0, triangle_height)
			]
		PointSide.BOTTOM:
			bubble = [
				Vector2(0, 0),
		  		Vector2(size.x, 0),
		  		Vector2(size.x, size.y -triangle_height),
				Vector2(size.x / 2 + triangle_size/2, size.y -triangle_height),
				Vector2(size.x / 2, size.y),
				Vector2(size.x / 2 - triangle_size/2, size.y -triangle_height),
				Vector2(0, size.y -triangle_height),
		  		Vector2(0, 0)
			]
		PointSide.LEFT:
			bubble = [
				Vector2(triangle_height, 0),
				Vector2(size.x, 0),
				Vector2(size.x, size.y), 
				Vector2(triangle_height, size.y),
				Vector2(triangle_height, size.y / 2 + triangle_size/2),
				Vector2(0, size.y / 2),
				Vector2(triangle_height, size.y / 2 - triangle_size/2),
				Vector2(triangle_height, 0)
			]
		PointSide.RIGHT:
			bubble = [
				Vector2(0, 0),
				Vector2(size.x - triangle_height, 0), 
				Vector2(size.x - triangle_height, size.y / 2 - triangle_size/2), 
				Vector2(size.x, size.y / 2), 
				Vector2(size.x - triangle_height, size.y / 2 + triangle_size/2), 
				Vector2(size.x - triangle_height, size.y),
				Vector2(0, size.y),
				Vector2(0, 0)
			]
	draw_polyline(bubble, border_color, border_width)

func recommended_point_side(target_position: Vector2) -> PointSide:
	var viewport_size: Vector2 = get_viewport_rect().size
	var grid_x: int = int((target_position.x / viewport_size.x) * 3)
	var grid_y: int = int((target_position.y / viewport_size.y) * 3)
	if grid_x == 0:  # Top-left
		point_side = PointSide.LEFT
	elif grid_x == 2 :  # Top-right
		point_side = PointSide.RIGHT
	elif grid_x == 1 and grid_y == 0:  # Top-center
		point_side = PointSide.TOP
	elif grid_x == 1 and grid_y == 2:  # Bottom-center
		point_side = PointSide.BOTTOM
	elif grid_x == 1 and grid_y == 1:  # Center
		point_side = PointSide.TOP
	elif grid_x == 2 and grid_y == 1:  # Center-right
		point_side = PointSide.RIGHT
	else:
		point_side = PointSide.TOP  # Default

	return point_side
	
func set_position_with_target(target_position: Vector2):
	assert(self.is_inside_tree())

	self.callout_position = target_position

	# HACK: Force size recalculation. This is necessary in Godot 4.4. 
	# Not sure what is going on here, but when we assign to the `position` then
	# the size of the control is recalculated.
	# prints("BEFORE: ", self.size, self.get_minimum_size())
	position = position
	# prints("AFTER: ", self.size, self.get_minimum_size())

	match point_side:
		PointSide.TOP:
			position = target_position + Vector2(-size.x / 2, triangle_height)
		PointSide.BOTTOM:
			position = target_position + Vector2(-size.x / 2, -size.y - triangle_height)
		PointSide.LEFT:
			position = target_position + Vector2(0 + triangle_height, - size.y / 2)
		PointSide.RIGHT:
			position = target_position + Vector2(-size.x - triangle_height, -size.y / 2)

	queue_redraw()
