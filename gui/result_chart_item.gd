class_name ResultChartItem extends PanelContainer

@onready var chart: Chart = %Chart
@onready var chart_label: Label = %ChartLabel

func _on_delete_button_pressed():
	self.queue_free()
	Global.app.perform_objects_action("delete_objects", PackedInt64Array([chart.object_id]))
