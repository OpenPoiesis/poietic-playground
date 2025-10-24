class_name Chart extends Control

var plot_offset: Vector2 = Vector2()
var _plot_rect: Rect2 = Rect2()

var object_id: int
## Information about the series presented in the chart.
##
## Note: The series might refer to objects which might not be currently
## present in the simulation result or a design frame. They should be
## gracefuly ignored or the user should be non-intrusively notified in a
## non-blocking way.
##
var series_info: Array[SeriesInfo] = []
var series_data: Dictionary[int,PoieticTimeSeries] = {}

class SeriesInfo:
	var object_id: int
	var color_name: String

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
	series_data.clear()
	series_info.clear()
	self.x_min = 0
	self.x_max = 0
	self.y_min = 0
	self.y_max = 0
	self.data_plot_offset = Vector2()
	self.data_plot_size = Vector2()
	queue_redraw()

func append_series(info: SeriesInfo):
	self.series_info.append(info)
	prints("CHART: Appending series of color ", info.color_name)
	queue_redraw()

func set_series_data(id: int, data: PoieticTimeSeries):
	# FIXME: This is old single-series chart leftover, update this
	self.x_min = min(x_min, data.time_start)
	self.x_max = max(x_max, data.time_end)
	self.y_min = min(y_min, data.data_min)
	self.y_max = max(y_max, data.data_max)
	self.data_plot_offset = Vector2(x_min, y_min)
	self.data_plot_size = Vector2(x_max - x_min, y_max - y_min)
	self.series_data[data.object_id] = data
	queue_redraw()

func plot_scale(scale: Vector2) -> Vector2:
	return scale / data_plot_size

func _init():
	self.series_data = {}
	self.series_info = []

	minimum_size_changed.connect(self._layout_plotting_area)
	var x_axis = ChartAxis.new()
	var y_axis = ChartAxis.new()

func _ready():
	_layout_plotting_area()

func _draw():
	if series_info.is_empty():
		return
		
	_layout_plotting_area()
	var size = self.get_rect().size
	# draw_rect(self.get_rect(), Color.ORANGE, false)

	# draw_rect(_plot_rect, Color.ORANGE, false)
	_draw_grid()
	_draw_axes()
	for info in series_info:
		_draw_line_plot(info)

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
	
func _draw_line_plot(info: SeriesInfo):
	var plot_series: PoieticTimeSeries = series_data[info.object_id]
	if plot_series == null:
		return
		
	var curve = screen_curve_for_series(plot_series, _plot_rect.size)
	var points = curve.tessellate()
	for index in range(0, len(points)):
		points[index] = points[index]
	var color = Global.get_adaptable_color(info.color_name, Color.WHITE)
	prints("CHART: drawing ",info.object_id,
		   " with color ", color,
		   " name:", info.color_name,
		   " type", type_string(typeof(info.color_name)))
	draw_polyline(points, color, 4.0)
	
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
	series_data.clear()
	for info in series_info:
		var series = result.time_series(info.object_id)
		if series == null:
			continue
		set_series_data(info.object_id, series)
