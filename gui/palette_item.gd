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
	custom_minimum_size = Vector2(100, 80)
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
	_icon_container.custom_minimum_size = Vector2(0, 48)
	_icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through

	# Label (centered below icon)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.text = label_text
	_label.clip_text = true
	_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	# Get font size from Palette theme if available
	var font_size = get_theme_font_size("font_size", "Palette")
	if font_size > 0:
		_label.add_theme_font_size_override("font_size", font_size)

	vbox.add_child(_icon_container)
	vbox.add_child(_label)
	add_child(vbox)

	# Add existing icon if set before _ready
	if icon_node:
		_center_icon(icon_node)
		_icon_container.add_child(icon_node)

func _center_icon(node: Node2D):
	var center_point = Vector2(custom_minimum_size.x / 2, _icon_container.custom_minimum_size.y / 2)

	# Check if this is a Pictogram2D with bounding_box property
	if node.get("bounding_box") != null:
		var bbox: Rect2 = node.get("bounding_box")
		# Position so bounding box center aligns with center_point
		node.position = center_point - bbox.position - bbox.size / 2
	else:
		# Fallback for other Node2D types (Sprite2D, etc.)
		node.position = center_point

func _draw():
	var bg_color: Color
	var border_color: Color = Color.TRANSPARENT
	var border_width: float = 0

	# Visual style based on state
	match current_state:
		State.NORMAL:
			bg_color = Color(0.15, 0.15, 0.2, 1.0)
		State.HOVERED:
			bg_color = Color(0.2, 0.2, 0.3, 1.0)
			border_color = Color(0.4, 0.4, 0.5, 1.0)
			border_width = 1
		State.SELECTED:
			bg_color = Color(0.25, 0.3, 0.4, 1.0)
			border_color = Color(0.5, 0.7, 1.0, 1.0)
			border_width = 2
		State.SELECTED_HOVERED:
			bg_color = Color(0.3, 0.35, 0.45, 1.0)
			border_color = Color(0.6, 0.8, 1.0, 1.0)
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
