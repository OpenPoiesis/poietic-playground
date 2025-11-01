class_name ChartAxis extends Node

@export var visible: bool = true
@export var min: float # null for auto
@export var max: float # null for auto
@export var major_steps: float # null for auto
@export var minor_steps: float # null for auto
# reflines: avg, med, min, max, 
@export var show_major: bool = true
@export var show_minor: bool = false
@export var line_color: Color = Color.BLACK
