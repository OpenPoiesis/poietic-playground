# TODO: Rename to ObjectPalette
class_name ObjectPanel extends PanelContainer

signal palette_item_changed(identifier: String)

@onready var palette: Palette = %Palette

var selected_item: String = "":
	get:
		return palette.selected_item.item_data
	set(value):
		palette.select_by_data(value)
		selected_item = value
		palette_item_changed.emit(selected_item)

func _ready():
	palette.item_selected.connect(_on_palette_item_selected)

func clear():
	palette.clear()
	
func load_node_pictograms():
	clear()
	var type_names = Global.app.design_controller.get_placeable_pictogram_names()
	for type_name in type_names:
		var pictogram_node = Global.app.canvas_controller.get_pictogram_node(type_name, 48, null)
		if pictogram_node == null:
			continue
		palette.add_node2d_item(type_name.capitalize(), pictogram_node, type_name)

func load_connector_pictograms():
	clear()

	var flow_texture = load("res://resources/icons/white/arrow-outlined.png")
	palette.add_texture_item("Flow", flow_texture, "Flow")	

	var param_texture = load("res://resources/icons/white/arrow-parameter.png")
	palette.add_texture_item("Parameter", param_texture, "Parameter")

func _on_palette_item_selected(item: Variant):
	if item as String:
		palette_item_changed.emit(item)
	else:
		printerr("Invalid object palette item: ", item)
