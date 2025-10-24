class_name TimeSeriesInspectorTraitPanel extends InspectorTraitPanel

@onready var chart: Chart = %Chart
@onready var stats_container = $VBoxContainer/StatsContainer

func on_selection_changed():
	# Chart
	# TODO: Check whether having a chart is relevant
	chart.clear_series()
	var series_info: Array[Chart.SeriesInfo] = []
	for id in selection:
		var object:PoieticObject = design_ctrl.get_object(id)
		if object == null:
			continue
		var info = Chart.SeriesInfo.new()
		info.object_id = id
		var color_name = object.get_attribute("color")
		if color_name != null:
			info.color_name = str(color_name)
		else:
			info.color_name = ""
			
		chart.append_series(info)
	chart.show()
	
	var result = Global.player.result
	if result == null:
		chart.hide()
	else:
		_on_result_updated(result)

func _on_result_updated(result: PoieticResult):
	chart.update_from_result(result)
	chart.show()
	
	if len(selection) == 1:
		update_stats(result, selection[0])
	else:
		stats_container.hide()
		

func update_stats(result: PoieticResult, id: int):
	var series:PoieticTimeSeries = result.time_series(id)
	if series == null:
		stats_container.hide()
		return
	stats_container.show()
	%MinValue.text = str(series.data_min)
	%MaxValue.text = str(series.data_max)

func _on_result_removed():
	chart.hide()
