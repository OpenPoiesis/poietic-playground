## PaletteItem
##
## A selectable gallery-style cell for displaying icons with labels.
## Used in palettes for object selection (blocks, connectors, etc.).
##
## Features:
## - Visual states: normal, hovered, selected, selected+hovered
## - Supports any Node2D as icon (Pictogram2D, Sprite2D, etc.)
## - Label displayed below icon
## - Click to select
##

class_name PaletteItem extends Control
const default_size = Vector2(80, 60)
const default_icon_size = Vector2(0, 40)

signal item_pressed(item: PaletteItem)

enum State {
	NORMAL,
	HOVERED,
	SELECTED,
	SELECTED_HOVERED
}

## Current visual state of the item
var current_state: State = State.NORMAL

## Metadata associated with this item (typically type name)
var item_data: Variant

## Whether this item is selected
var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_state()

## Whether mouse is hovering over this item
var is_hovered: bool = false:
	set(value):
		is_hovered = value
		_update_state()

## The icon node displayed in this item (Pictogram2D, Sprite2D, etc.)
var icon_node: Node2D = null:
	set(value):
		if icon_node and icon_node.get_parent() == _icon_container:
			_icon_container.remove_child(icon_node)
			icon_node.queue_free()
		icon_node = value
		if icon_node and _icon_container:
			_center_icon(icon_node)
			_icon_container.add_child(icon_node)

## Text displayed below the icon
var label_text: String = "":
	set(value):
		label_text = value
		if _label:
			_label.text = value

## Tooltip shown on hover
var item_tooltip: String = "":
	set(value):
		item_tooltip = value
		tooltip_text = value

# Internal UI components
var _icon_container: Control
var _label: Label

func _init():
	custom_minimum_size = default_size
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready():
	_setup_layout()

func _setup_layout():
	# Main vertical layout
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)

	# Icon area (plain Control for Node2D positioning)
	_icon_container = Control.new()
	_icon_container.custom_minimum_size = default_icon_size
	_icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through

	# Label (centered below icon)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.text = label_text
	_label.clip_text = true
	_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	var font_size = get_theme_font_size("font_size", "Palette")
	if font_size > 0:
		_label.add_theme_font_size_override("font_size", font_size)

	vbox.add_child(_icon_container)
	vbox.add_child(_label)
	add_child(vbox)

	if icon_node:
		_center_icon(icon_node)
		_icon_container.add_child(icon_node)

func _center_icon(node: Node2D):
	var center_point = Vector2(custom_minimum_size.x / 2, _icon_container.custom_minimum_size.y / 2)

	if node.get("bounding_box") != null:
		var bbox: Rect2 = node.get("bounding_box")
		node.position = center_point - bbox.position - bbox.size / 2
	else:
		node.position = center_point

func _draw():
	var bg_color: Color
	var border_color: Color = Color.TRANSPARENT
	var border_width: float = 0

	# Visual style based on state
	match current_state:
		State.NORMAL:
			bg_color = Color("D0CCBD")
		State.HOVERED:
			bg_color = Color("ebe6d5ff")
			border_color = Color("b8b4a7ff")
			border_width = 1
		State.SELECTED:
			bg_color = Color("b3a49bff")
			border_color = Color("8c6e51ff")
			border_width = 2
		State.SELECTED_HOVERED:
			bg_color = Color("d6c5baff")
			border_width = 2

	# Draw background
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)

	# Draw border if needed
	if border_width > 0:
		draw_rect(Rect2(Vector2.ZERO, size), border_color, false, border_width)

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			item_pressed.emit(self)
			accept_event()

func _mouse_entered():
	is_hovered = true

func _mouse_exited():
	is_hovered = false

func _update_state():
	if is_selected and is_hovered:
		current_state = State.SELECTED_HOVERED
	elif is_selected:
		current_state = State.SELECTED
	elif is_hovered:
		current_state = State.HOVERED
	else:
		current_state = State.NORMAL

	queue_redraw()
