class_name ObjectPalette extends CallOut

signal place_object(Vector2, String)

@onready var item_grid: GridContainer = %ItemGrid

class ObjectPaletteItem extends TextureButton:
	var pictogram: Pictogram

	func _init(pictogram: Pictogram):
		self.pictogram = pictogram
		self.texture_normal = pictogram.get_texture()
		self.ignore_texture_size = true
		self.stretch_mode = StretchMode.STRETCH_KEEP_ASPECT_CENTERED
		self.tooltip_text = pictogram.name

func _ready():
	update_items()
	# call_deferred("update_items")
	# _child = $MarginContainer

func update_items():
	item_grid = %ItemGrid
	for child in item_grid.get_children():
		item_grid.remove_child(child)
	for pictogram in Global.get_placeable_pictograms():
		add_item(pictogram)

func add_item(pictogram: Pictogram):
	var item: ObjectPaletteItem = ObjectPaletteItem.new(pictogram)
	item.custom_minimum_size = Vector2(60, 60)
	item.pressed.connect(_on_item_selected.bind(item))
	item_grid.add_child(item)
	item_grid.queue_sort()
	_update_size()
	queue_sort()
	queue_redraw()

func _on_item_selected(item: ObjectPaletteItem):
	place_object.emit(callout_position, item.pictogram.name)
