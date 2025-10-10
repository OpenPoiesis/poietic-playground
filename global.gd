extends Node

# View Preferences
var show_value_indicators: bool = true

# Poietic Backend
var app: PoieticApplication
var player: ResultPlayer

# Application State
var canvas: DiagramCanvas = null

func initialize(app: PoieticApplication, player: ResultPlayer):
	print("Initializing globals ...")
	self.app = app
	self.player = player
