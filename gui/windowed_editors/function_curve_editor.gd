class_name FunctionCurveEditor extends Control

## Interactive graph control for editing function curves.
##
## Displays a 2D function as a curve with editable control points.
## Supports multiple interpolation methods (linear, step, cubic).

signal point_added(index: int)
signal point_moved(index: int)
signal point_selected(index: int)
signal points_changed()

enum InterpolationMethod {
	LINEAR,
	STEP,
	CUBIC
}

# Data
@export var points: PackedVector2Array = PackedVector2Array():
	set(value):
		points = value
		self.fit_range()
		
@export var interpolation: InterpolationMethod = InterpolationMethod.LINEAR

# Range
@export var min_x: float = 0.0
@export var max_x: float = 100.0
@export var min_y: float = 0.0
@export var max_y: float = 100.0

# Visual settings
@export var grid_segments_x: int = 10
@export var grid_segments_y: int = 10
@export var point_radius: float = 6.0

# Colors
@export var background_color: Color = Color(0.15, 0.15, 0.15)
@export var grid_color: Color = Color(0.3, 0.3, 0.3)
@export var axis_color: Color = Color(0.5, 0.5, 0.5)
@export var curve_color: Color = Color(0.4, 0.7, 1.0)
@export var point_normal_color: Color = Color(0.8, 0.8, 0.8)
@export var point_selected_color: Color = Color(1.0, 1.0, 0.3)
@export var point_dragging_color: Color = Color(1.0, 0.5, 0.3)
@export var point_outline_color: Color = Color.BLACK

# Interaction state
var dragging_point_index: int = -1
var dragging_point_value: Vector2 = Vector2.ZERO  # Track the actual point being dragged
var selected_point_index: int = -1

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw():
	var size = get_size()
	if size.x <= 0 or size.y <= 0:
		return

	draw_rect(Rect2(Vector2.ZERO, size), background_color)

	draw_grid()
	draw_axes()
	draw_curve()
	draw_points()

func set_interpolation_method_name(name: String):
	match name.to_lower():
		"step": interpolation = FunctionCurveEditor.InterpolationMethod.STEP
		"cubic": interpolation = FunctionCurveEditor.InterpolationMethod.CUBIC
		_: interpolation = FunctionCurveEditor.InterpolationMethod.LINEAR
	
func interpolation_method_name():
	var name: String
	match interpolation:
		FunctionCurveEditor.InterpolationMethod.STEP: name = "step"
		FunctionCurveEditor.InterpolationMethod.CUBIC: name = "cubic"
		FunctionCurveEditor.InterpolationMethod.LINEAR: name = "linear"
		
	return name

func adapt_range_for_point(point: Vector2):
	var range_changed = false

	if point.x < min_x:
		min_x = point.x
		range_changed = true
	if point.x > max_x:
		max_x = point.x
		range_changed = true
	if point.y < min_y:
		min_y = point.y
		range_changed = true
	if point.y > max_y:
		max_y = point.y
		range_changed = true

	if range_changed:
		queue_redraw()

## Fit exactly to the graph range. Use min_size axis if one of the ranges is zero.
func fit_range(min_size: Vector2 = Vector2(1.0, 1.0)):
	if len(points) == 0:
		return
	min_x = points[0].x
	max_x = points[0].x
	min_y = points[0].y
	max_y = points[0].y
	for point in points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
		
	if is_zero_approx(min_x - max_x):
		max_x = min_x + min_size.x
	if is_zero_approx(min_y - max_y):
		max_y = min_y + min_size.y
	queue_redraw()

func adapt_range():
	for point in points:
		adapt_range_for_point(point)

# Drawing
# ----------------------------------------------------------------------------

func draw_grid():
	var size = get_size()

	for i in range(1, grid_segments_x):
		var x = (size.x / grid_segments_x) * i
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)

	for i in range(1, grid_segments_y):
		var y = (size.y / grid_segments_y) * i
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)

func draw_axes():
	var size = get_size()
	draw_line(Vector2(0, size.y), Vector2(size.x, size.y), axis_color, 2.0)
	draw_line(Vector2(0, 0), Vector2(0, size.y), axis_color, 2.0)

func draw_curve():
	if points.size() < 2:
		return

	var sorted_points = get_sorted_points()
	var curve_points = PackedVector2Array()

	match interpolation:
		InterpolationMethod.LINEAR:
			curve_points = generate_linear_curve(sorted_points)
		InterpolationMethod.STEP:
			curve_points = generate_step_curve(sorted_points)
		InterpolationMethod.CUBIC:
			curve_points = generate_cubic_curve(sorted_points)

	if curve_points.size() >= 2:
		draw_polyline(curve_points, curve_color, 2.0)

func draw_points():
	for i in range(points.size()):
		var screen_pos = value_to_screen(points[i])
		var color = point_normal_color

		if i == dragging_point_index:
			color = point_dragging_color
		elif i == selected_point_index:
			color = point_selected_color

		draw_circle(screen_pos, point_radius, color, true)
		draw_circle(screen_pos, point_radius, color, false, 2)

# Curve Generation
# ----------------------------------------------------------------------------

func generate_linear_curve(sorted_points: PackedVector2Array) -> PackedVector2Array:
	var curve_points = PackedVector2Array()

	for point in sorted_points:
		curve_points.append(value_to_screen(point))

	return curve_points

func generate_step_curve(sorted_points: PackedVector2Array) -> PackedVector2Array:
	var curve_points = PackedVector2Array()

	for i in range(sorted_points.size()):
		var p = sorted_points[i]
		curve_points.append(value_to_screen(p))

		if i < sorted_points.size() - 1:
			var next_p = sorted_points[i + 1]
			curve_points.append(value_to_screen(Vector2(next_p.x, p.y)))

	return curve_points

func generate_cubic_curve(sorted_points: PackedVector2Array) -> PackedVector2Array:
	var curve_points = PackedVector2Array()

	if sorted_points.size() < 2:
		return curve_points

	for i in range(sorted_points.size() - 1):
		var p0 = sorted_points[max(0, i - 1)]
		var p1 = sorted_points[i]
		var p2 = sorted_points[i + 1]
		var p3 = sorted_points[min(sorted_points.size() - 1, i + 2)]

		var steps = 20
		for j in range(steps + 1):
			var t = float(j) / steps
			var point = catmull_rom(p0, p1, p2, p3, t)
			curve_points.append(value_to_screen(point))

	return curve_points

func catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 = t * t
	var t3 = t2 * t

	var v0 = (p2 - p0) * 0.5
	var v1 = (p3 - p1) * 0.5

	return (2.0 * p1 - 2.0 * p2 + v0 + v1) * t3 + \
		   (-3.0 * p1 + 3.0 * p2 - 2.0 * v0 - v1) * t2 + \
		   v0 * t + p1

# Coordinate Transformation
# ----------------------------------------------------------------------------

func value_to_screen(value: Vector2) -> Vector2:
	var size = get_size()
	var x = ((value.x - min_x) / (max_x - min_x)) * size.x
	var y = size.y - ((value.y - min_y) / (max_y - min_y)) * size.y
	return Vector2(x, y)

func screen_to_value(screen: Vector2) -> Vector2:
	var size = get_size()
	var x = (screen.x / size.x) * (max_x - min_x) + min_x
	var y = ((size.y - screen.y) / size.y) * (max_y - min_y) + min_y
	return Vector2(x, y)

# Mouse Interaction
# ----------------------------------------------------------------------------

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_mouse_down(event.position)
			else:
				_on_mouse_up(event.position)
	elif event is InputEventMouseMotion:
		if dragging_point_index >= 0:
			_on_mouse_drag(event.position)

func _on_mouse_down(pos: Vector2):
	# TODO: Extract to "point_at(position:)"
	for i in range(points.size()):
		var screen_pos = value_to_screen(points[i])
		if pos.distance_to(screen_pos) <= point_radius + 2:
			dragging_point_index = i
			dragging_point_value = points[i]  # Remember the point value
			selected_point_index = i
			point_selected.emit(i)
			queue_redraw()
			return

	# Create new point (clamp to current range)
	var value = screen_to_value(pos)
	value.x = clamp(value.x, min_x, max_x)
	value.y = clamp(value.y, min_y, max_y)
	points.append(value)
	dragging_point_index = points.size() - 1
	dragging_point_value = value  # Remember the point value
	selected_point_index = dragging_point_index
	sort_points()
	point_added.emit(dragging_point_index)
	points_changed.emit()
	queue_redraw()

func _on_mouse_up(_pos: Vector2):
	dragging_point_index = -1
	queue_redraw()

func _on_mouse_drag(pos: Vector2):
	if dragging_point_index >= 0:
		var new_value = screen_to_value(pos)

		# Find the point we're dragging by its value (since sorting changes indices)
		for i in range(points.size()):
			if points[i].is_equal_approx(dragging_point_value):
				points[i] = new_value
				dragging_point_value = new_value  # Update tracked value
				sort_points()

				# Find new index after sorting
				for j in range(points.size()):
					if points[j].is_equal_approx(new_value):
						dragging_point_index = j
						break

				point_moved.emit(dragging_point_index)
				points_changed.emit()
				queue_redraw()
				break

# Point Collection
# ----------------------------------------------------------------------------

func sort_points():
	var sorted_array = Array(points.duplicate())
	sorted_array.sort_custom(func(a, b): return a.x < b.x)
	points = PackedVector2Array(sorted_array)

func get_sorted_points() -> PackedVector2Array:
	var sorted_array = Array(points.duplicate())
	sorted_array.sort_custom(func(a, b): return a.x < b.x)
	return PackedVector2Array(sorted_array)

func add_point(point: Vector2) -> int:
	points.append(point)
	sort_points()
	var sorted_points = get_sorted_points()
	for i in range(sorted_points.size()):
		if sorted_points[i].is_equal_approx(point):
			point_added.emit(i)
			points_changed.emit()
			queue_redraw()
			return i
	return -1

func remove_point(index: int) -> bool:
	if index < 0 or index >= points.size():
		return false

	var sorted_points = get_sorted_points()
	if index < sorted_points.size():
		var point_to_remove = sorted_points[index]
		for i in range(points.size()):
			if points[i].is_equal_approx(point_to_remove):
				points.remove_at(i)
				if selected_point_index == index:
					selected_point_index = -1
				points_changed.emit()
				queue_redraw()
				return true
	return false

func clear_selection():
	selected_point_index = -1
	queue_redraw()

func set_range(new_min_x: float, new_max_x: float, new_min_y: float, new_max_y: float):
	min_x = new_min_x
	max_x = new_max_x
	min_y = new_min_y
	max_y = new_max_y
	queue_redraw()

func set_interpolation_method(method: InterpolationMethod):
	interpolation = method
	queue_redraw()

func get_point_at_screen_pos(screen_pos: Vector2) -> int:
	for i in range(points.size()):
		var point_screen_pos = value_to_screen(points[i])
		if screen_pos.distance_to(point_screen_pos) <= point_radius + 2:
			return i
	return -1
