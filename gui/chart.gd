class_name Chart extends Control

var plot_offset: Vector2 = Vector2()
var _plot_rect: Rect2 = Rect2()

## IDs of objects representing time series.
##
## `series_ids` is used when data needs to be refreshed automatically.
## The attribute is not required if the chart content is managed manually.
##
## Note that the series_ids might contain IDs that might not be currently
## present in the simulation result or a design frame. They should be
## gracefuly ignored or the user should be non-intrusively notified.
##
var series_ids: PackedInt64Array = PackedInt64Array()
var data: Array[PoieticTimeSeries] = []

# Styling
@export var x_axis: ChartAxis = ChartAxis.new()
@export var y_axis: ChartAxis = ChartAxis.new()
@export var x_axis_width: float = 20
@export var y_axis_width: float = 20

@export var x_min: float = 0.0
@export var x_max: float = 0.0
@export var y_min: float = 0.0
@export var y_max: float = 0.0

# TODO: Use Axis for this
var x_step:float = 1.0
var y_step:float = 10.0

var data_plot_size: Vector2
var data_plot_offset: Vector2

@export var x_axis_visible: bool:
	set(value):
		x_axis.visible = value
		_layout_plotting_area()

@export var y_axis_visible: bool:
	set(value):
		y_axis.visible = value
		_layout_plotting_area()
		
func clear_series():
	data.clear()
	self.x_min = 0
	self.x_max = 0
	self.y_min = 0
	self.y_max = 0
	self.data_plot_offset = Vector2()
	self.data_plot_size = Vector2()
	queue_redraw()

func append_series(series: PoieticTimeSeries):
	self.x_min = min(x_min, series.time_start)
	self.x_max = max(x_max, series.time_end)
	self.y_min = min(y_min, series.data_min)
	self.y_max = max(y_max, series.data_max)
	self.data_plot_offset = Vector2(x_min, y_min)
	self.data_plot_size = Vector2(x_max - x_min, y_max - y_min)
	self.data.append(series)
	queue_redraw()

func plot_scale(scale: Vector2) -> Vector2:
	return scale / data_plot_size

func _init():
	self.data = []

	minimum_size_changed.connect(self._layout_plotting_area)
	var x_axis = ChartAxis.new()
	var y_axis = ChartAxis.new()
	# _create_demo_data()

func _ready():
	_layout_plotting_area()

func _draw():
	if data.is_empty():
		return
	_layout_plotting_area()
	var size = self.get_rect().size
	# draw_rect(self.get_rect(), Color.ORANGE, false)

	# draw_rect(_plot_rect, Color.ORANGE, false)
	_draw_grid()
	_draw_axes()
	for plot_series in data:
		_draw_line_plot(plot_series)

func _draw_axes():
	var bbox = self.get_rect()
	var plot_zero = Vector2(_plot_rect.position.x, _plot_rect.position.y + _plot_rect.size.y)
	# X-Axis
	var x_axis_rect = Rect2(_plot_rect.position.x, bbox.size.y-x_axis_width, _plot_rect.size.x, x_axis_width)
	draw_line(plot_zero, plot_zero + Vector2(x_axis_rect.size.x, 0), x_axis.line_color, 2.0)

	var y_axis_rect = Rect2(0, 0, y_axis_width, _plot_rect.size.y)
	draw_line(plot_zero, plot_zero + Vector2(0, -y_axis_rect.size.y), y_axis.line_color, 2.0)
	
func _draw_grid():
	var plot_zero = Vector2(_plot_rect.position.x, _plot_rect.position.y + _plot_rect.size.y)

	var x_ticks = tick_marks(x_min, x_max, x_step)
	for tick in x_ticks:
		var ptick = to_plot(Vector2(tick, x_min), _plot_rect.size)
		draw_line(ptick, ptick + Vector2(0, +10), x_axis.line_color)

	var y_ticks = tick_marks(y_min, y_max, (y_max - y_min) / 10)
	for tick in y_ticks:
		var ptick = to_plot(Vector2(x_min, tick), _plot_rect.size)
		draw_line(ptick, ptick - Vector2(+10, 0), y_axis.line_color)
	pass
	
func _draw_line_plot(plot_series: PoieticTimeSeries):
	var curve = screen_curve_for_series(plot_series, _plot_rect.size)
	var points = curve.tessellate()
	for index in range(0, len(points)):
		points[index] = points[index]

	draw_polyline(points, Color.WHITE, 4.0)
	
func screen_curve_for_series(series: PoieticTimeSeries, size: Vector2) -> Curve2D:
	var curve: Curve2D = Curve2D.new()
	for data_point in series.get_points():
		var plot_point = to_plot(data_point, size)
		curve.add_point(plot_point)
	return curve

func _layout_plotting_area():
	plot_offset = Vector2(y_axis_width, 0)
	_plot_rect = Rect2(plot_offset, Vector2(size.x - y_axis_width, size.y - x_axis_width))
	
## Converts a data point to a plot point given plot size.
##
## Note: The y-coordinate is flipped, so that the resulting point corresponds to
## Godot viewport coordinate.
##
func to_plot(data_point: Vector2, size: Vector2) -> Vector2:
	var point = (data_point - data_plot_offset) * plot_scale(size)
	var flipped_point = Vector2(point.x, size.y - point.y)
	return flipped_point + plot_offset

func tick_marks(min: float, max: float, step: float) -> PackedFloat32Array:
	var value = min
	var result = PackedFloat32Array()
	while value < max:
		result.append(value)
		value += step
	return result

func _data_changed():
	pass

func update_from_result(result: PoieticResult) -> void:
	if not result: # TODO: Investigate when update is requested without result
		return
	clear_series()
	for id in series_ids:
		var series = result.time_series(id)
		if not series:
			continue
		append_series(series)
