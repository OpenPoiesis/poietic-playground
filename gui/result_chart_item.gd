class_name ResultChartItem extends PanelContainer

@onready var chart: Chart = %Chart
@onready var chart_label: Label = %ChartLabel

func _on_delete_button_pressed():
	# FIXME: Once this is a proper chart, then use the controller to remove the chart and then update the parent
	self.queue_free()
