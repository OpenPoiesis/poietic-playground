## Palette
##
## A container for displaying selectable palette items in a grid layout.
## Similar to ObjectPanel but using the new PaletteItem system.
##
## Features:
## - Grid layout of PaletteItem cells
## - Single selection model
## - Support for both Node2D icons and Texture icons
## - Signal emission on selection change
##
## Usage:
##   var palette = Palette.new()
##   palette.add_node2d_item("Stock", stock_pictogram_node, "Stock")
##   palette.add_texture_item("Flow", flow_texture, "Flow")
##   palette.item_selected.connect(_on_item_selected)
##

class_name Palette extends PanelContainer

signal item_selected(item_data: Variant)

## Grid container holding all palette items
@onready var item_grid: GridContainer = null

## All palette items
var items: Array[PaletteItem] = []

## Currently selected item (if any)
var selected_item: PaletteItem = null

## Number of columns in the grid
@export var columns: int = 3:
	set(value):
		columns = value
		if item_grid:
			item_grid.columns = columns

## Spacing between items
@export var item_spacing: int = 4:
	set(value):
		item_spacing = value
		if item_grid:
			item_grid.add_theme_constant_override("h_separation", item_spacing)
			item_grid.add_theme_constant_override("v_separation", item_spacing)

func _ready():
	_setup_grid()

func _setup_grid():
	if not item_grid:
		item_grid = GridContainer.new()
		item_grid.columns = columns
		item_grid.add_theme_constant_override("h_separation", item_spacing)
		item_grid.add_theme_constant_override("v_separation", item_spacing)
		add_child(item_grid)

## Add a new item to the palette with a Node2D icon
##
## Parameters:
##   label: Text displayed below the icon
##   icon_node: A Node2D (Pictogram2D, Sprite2D, etc.)
##   data: Metadata to store with this item (typically type name)
##
func add_node2d_item(label: String, icon_node: Node2D, data: Variant = null):
	if not item_grid:
		_setup_grid()

	var item = PaletteItem.new()
	item.label_text = label
	item.item_data = data if data != null else label
	item.item_tooltip = label
	item.icon_node = icon_node
	item.item_pressed.connect(_on_item_pressed)

	item_grid.add_child(item)
	items.append(item)

## Add a new item to the palette with a Texture icon
##
## Parameters:
##   label: Text displayed below the icon
##   texture: A Texture to display as the icon
##   data: Metadata to store with this item (typically type name)
##
func add_texture_item(label: String, texture: Texture, data: Variant = null):
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true

	# TODO: Make icon area constant/configurable
	var texture_size = texture.get_size()
	var scale_factor = min(48.0 / texture_size.x, 48.0 / texture_size.y) * 0.8
	sprite.scale = Vector2(scale_factor, scale_factor)

	add_node2d_item(label, sprite, data)

## Remove all items from the palette
func clear():
	for item in items:
		item_grid.remove_child(item)
		item.queue_free()
	items.clear()
	selected_item = null

## Get the currently selected item's data
func get_selected_data() -> Variant:
	if selected_item:
		return selected_item.item_data
	return null

## Select an item by its data
func select_by_data(data: Variant):
	for item in items:
		if item.item_data == data:
			_select_item(item)
			return

## Deselect all items
func deselect_all():
	for item in items:
		item.is_selected = false
	selected_item = null

func _on_item_pressed(item: PaletteItem):
	_select_item(item)

func _select_item(item: PaletteItem):
	for i in items:
		i.is_selected = false

	item.is_selected = true
	selected_item = item

	item_selected.emit(item.item_data)
