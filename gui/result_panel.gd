class_name ResultPanel extends Node

# TODO: Use group "live_charts" for chart nodes for updating

@export var design_ctrl: DesignController
@export var player: ResultPlayer
@export var canvas: DiagramCanvas

@onready var chart_container: Container = %ChartContainer

@export var result_panel: Node

func initialize(design_ctrl: DesignController, player: ResultPlayer, canvas: DiagramCanvas):
	self.design_ctrl = design_ctrl
	self.player = player
	self.canvas = canvas
	
	design_ctrl.design_changed.connect(_on_design_changed)
	design_ctrl.simulation_finished.connect(_on_simulation_success)
	design_ctrl.simulation_failed.connect(_on_simulation_failed)
	design_ctrl.selection_manager.selection_changed.connect(_on_selection_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_design_changed(has_issues: bool):
	sync_charts()

func _on_simulation_success(result):
	update_data(result)
	
func _on_simulation_failed():
	pass
	
func _on_selection_changed(selection):
	pass

func sync_charts():
	# Important: We do not update data here, that can be updated if we have the result
	for child in chart_container.get_children():
		child.queue_free()
		
	var ids = design_ctrl.get_object_ids("Chart")
	ids = design_ctrl.vaguely_ordered(ids, "order")
	for id in ids:
		var chart_object = design_ctrl.get_object(id)
		var chart_item: ResultChartItem = load("res://gui/result_chart_item.tscn").instantiate()
		chart_container.add_child(chart_item)
		var chart: Chart = chart_item.chart
		chart.custom_minimum_size.x = 200
		chart.custom_minimum_size.y = 120
		chart.add_to_group(&"live_charts")
		sync_chart_from(chart_item, chart_object)

func sync_chart_from(chart_item: ResultChartItem, object: PoieticObject):
	# Important: We do not update data here, that can be updated if we have the result
	var edge_ids = design_ctrl.get_outgoing_ids(object.object_id, "ChartSeries")
	var series_ids: PackedInt64Array = PackedInt64Array()
	if edge_ids.is_empty():
		push_warning("Chart series is empty")
	for id in edge_ids:
		var edge: PoieticObject = design_ctrl.get_object(id)
		if not edge:
			push_error("Unknown series edge object: ", id)
			continue
		series_ids.append(edge.target)
	chart_item.chart.series_ids = series_ids
		
func update_data(result: PoieticResult):
	for item in chart_container.get_children():
		if not item is ResultChartItem:
			return
		update_chart_item_data(item, result)

func update_chart_item_data(item: ResultChartItem, result: PoieticResult):
	item.chart.update_from_result(result)
	var names: Array[String] = []
	for id in item.chart.series_ids:
		var object: PoieticObject = design_ctrl.get_object(id)
		if not object:
			continue
		var name = object.object_name
		if not name:
			name = "unknown"
		names.append(name)
	if names.is_empty():
		item.chart_label.text = "(empty)"
	else:
		item.chart_label.text = ", ".join(names)

func _on_add_chart_button_pressed():
	var ids = canvas.selection.get_ids()
	if not ids:
		push_error("Result IDs are null")
		return
	add_chart(ids)

func add_chart(series_ids: PackedInt64Array):
	# TODO: Make sures that seris is a numeric object
	# TODO: Add chart order
	if series_ids.is_empty():
		return
		
	var trans: PoieticTransaction = design_ctrl.new_transaction()
	var chart_obj_id = trans.create_node("Chart", null, {})
	
	for series_id in series_ids:
		var series_obj = trans.create_edge("ChartSeries", chart_obj_id, series_id)
		
	design_ctrl.accept(trans)
