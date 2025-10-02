class_name ObjectPalette extends CallOut

signal place_object(Vector2, String)

@onready var item_grid: GridContainer = %ItemGrid

class ObjectPaletteItem extends TextureButton:
	var type_name: String

	func _init(type_name: String, icon_source: Variant):
		self.type_name = type_name
		self.tooltip_text = type_name
		self.ignore_texture_size = true
		self.stretch_mode = StretchMode.STRETCH_KEEP_ASPECT_CENTERED

		# Handle both Texture and Node2D (Pictogram2D)
		if icon_source is Texture:
			self.texture_normal = icon_source
		elif icon_source is Node2D:
			# For Node2D, we'll add it as a child after initialization
			# Use call_deferred to ensure button is ready
			call_deferred("_setup_node_icon", icon_source)

	func _setup_node_icon(node: Node2D):
		# Center the node in the button
		node.position = size / 2
		add_child(node)

func _ready():
	update_items()
	# call_deferred("update_items")
	# _child = $MarginContainer

func update_items():
	item_grid = %ItemGrid
	for child in item_grid.get_children():
		item_grid.remove_child(child)

	var type_names = Global.app.design_controller.get_placeable_pictogram_names()
	for type_name in type_names:
		var pictogram_node = Global.app.canvas_controller.get_pictogram_node(type_name, 60, null)
		if pictogram_node:
			add_item(type_name, pictogram_node)

func add_item(type_name: String, icon_source: Variant):
	var item: ObjectPaletteItem = ObjectPaletteItem.new(type_name, icon_source)
	item.custom_minimum_size = Vector2(60, 60)
	item.pressed.connect(_on_item_selected.bind(item))
	item_grid.add_child(item)
	item_grid.queue_sort()
	_update_size()
	queue_sort()
	queue_redraw()

func _on_item_selected(item: ObjectPaletteItem):
	place_object.emit(callout_position, item.type_name)
