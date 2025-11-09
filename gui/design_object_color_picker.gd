extends Control

signal color_selected(color_name: String)

@onready var colors: ColorPalette = preload("res://resources/adaptable_design_colors.tres")

@export var selected_color_name: String = ""
@export var cell_size: Vector2 = Vector2(16, 16):
	set(value):
		cell_size = value
		for child in %ColorGrid.get_children():
			if child as Button:
				child.custom_minimum_size = cell_size

var button_group = ButtonGroup.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(0, len(Global.adaptable_color_names)):
		var name = Global.adaptable_color_names[i]
		var color = colors.colors[i]

		var button = Button.new()
		button.custom_minimum_size = cell_size
		button.tooltip_text = name
		button.toggle_mode = true
		button.button_group = button_group
		button.focus_mode = Control.FOCUS_NONE
		button.set_meta("color_name", name)
		
		var style = StyleBoxFlat.new()
		style.bg_color = color
		button.add_theme_stylebox_override("normal", style)

		var style_hover = style.duplicate()
		style_hover.bg_color = color
		style_hover.border_color = color.lightened(0.5)
		style_hover.set_border_width_all(5)		
		button.add_theme_stylebox_override("hover", style_hover)

		var selected_style = StyleBoxFlat.new()
		selected_style.bg_color = color
		selected_style.border_color = Color.WHITE
		selected_style.set_border_width_all(3)		
		button.add_theme_stylebox_override("pressed", selected_style)
		
		button.pressed.connect(_on_color_button_pressed.bind(name, button))

		%ColorGrid.add_child(button)

	%DefaultColorButton.toggle_mode = true
	%DefaultColorButton.button_group = button_group
	%DefaultColorButton.focus_mode = Control.FOCUS_NONE
	%DefaultColorButton.pressed.connect(_on_color_button_pressed.bind("", %DefaultColorButton))
	var def_selected_style = StyleBoxFlat.new()
	def_selected_style.bg_color = Color.BLACK
	def_selected_style.border_color = Color.WHITE
	def_selected_style.set_border_width_all(3)		
	%DefaultColorButton.add_theme_stylebox_override("pressed", def_selected_style)

func set_selected_color(color_name: String) -> void:
	# If empty or invalid color name, deselect all
	if color_name.is_empty() or not Global.adaptable_color_names.has(color_name):
		if button_group.get_pressed_button():
			button_group.get_pressed_button().set_pressed_no_signal(false)
			selected_color_name = ""
			color_selected.emit("")
			return

	# Find and select the button with matching color name
	for button in %ColorGrid.get_children():
		if button is Button and button.get_meta("color_name") == color_name:
			button.set_pressed_no_signal(true)
			selected_color_name = color_name
			color_selected.emit(color_name)
			return

func set_selected_color_no_signal(color_name: String) -> void:
	# If empty or invalid color name, deselect all
	if color_name.is_empty() or not Global.adaptable_color_names.has(color_name):
		if button_group.get_pressed_button():
			button_group.get_pressed_button().set_pressed_no_signal(false)
			selected_color_name = ""
			return

	# Find and select the button with matching color name
	for button in %ColorGrid.get_children():
		if button is Button and button.get_meta("color_name") == color_name:
			button.set_pressed_no_signal(true)
			selected_color_name = color_name
			return

func _on_color_button_pressed(color_name: String, button: Button):
	if selected_color_name == color_name and button.button_pressed:
		button.set_pressed_no_signal(false)
		selected_color_name = ""
	else:
		selected_color_name = color_name

	color_selected.emit(selected_color_name)
