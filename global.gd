extends Node

# View Preferences
var show_value_indicators: bool = true

# Poietic Backend
var app: PoieticApplication
var player: ResultPlayer

# Application State
var canvas: DiagramCanvas = null

# TODO: Move to app
@onready var adaptable_design_colors: ColorPalette = preload("res://resources/adaptable_design_colors.tres")
const adaptable_color_names: Array[String] = [
	"purple", "red", "pink", "brown", "orange", "yellow", "lime", "green", "cyan", "teal", "blue", "indigo"
]


func get_adaptable_color(name: String, default_color: Color) -> Color:
	var index = adaptable_color_names.find(name)
	if index == -1:
		return default_color
	elif index < len(adaptable_design_colors.colors):
		return adaptable_design_colors.colors[index]
	else:
		return default_color

func initialize(app: PoieticApplication, player: ResultPlayer):
	print("Initializing globals ...")
	self.app = app
	self.player = player
