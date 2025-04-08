class_name ControlBar extends PanelContainer

@onready var reset_button: Button = %ResetButton
@onready var stop_button: Button = %StopButton
@onready var run_button: Button = %RunButton
@onready var loop_button: Button = %LoopButton
@onready var time_field: Label = %TimeField
@onready var end_time_field: LineEdit = %EndTimeField

@export var design_ctrl: PoieticDesignController
@export var player: PoieticPlayer

func initialize(design_ctrl: PoieticDesignController, player: PoieticPlayer):
	self.design_ctrl = design_ctrl
	self.player = player
	design_ctrl.design_changed.connect(_on_design_changed)
	design_ctrl.simulation_finished.connect(_on_simulation_success)
	design_ctrl.simulation_failed.connect(_on_simulation_failure)

	player.simulation_player_started.connect(update_player_state)
	player.simulation_player_stopped.connect(update_player_state)
	player.simulation_player_restarted.connect(update_player_state)
	player.simulation_player_step.connect(update_player_state)

	update_player_state()
	
func update_player_state():
	if player.is_running:
		run_button.set_pressed_no_signal(true)
		run_button.disabled = true
		stop_button.set_pressed_no_signal(false)
		stop_button.disabled = false
	else:
		run_button.set_pressed_no_signal(false)
		stop_button.set_pressed_no_signal(true)
		run_button.disabled = false
		stop_button.disabled = true
		
	loop_button.set_pressed_no_signal(player.is_looping)
	time_field.text = str(player.current_step)

func _on_simulation_success(result: PoieticResult):
	end_time_field.text = str(result.end_time)
	pass
	
func _on_simulation_failure():
	pass

func _on_simulator_started():
	update_player_state()

func _on_simulator_step():
	update_player_state()
	
func _on_simulator_stopped():
	update_player_state()

func _on_reset_button_pressed():
	player.stop()
	player.restart()
	update_player_state()

func _on_run_button_pressed():
	if player.is_running:
		return
	player.run()

func _on_stop_button_pressed():
	if !player.is_running:
		return
	player.stop()


func _on_loop_button_pressed():
	player.is_looping = loop_button.button_pressed
	update_player_state()

func _on_design_changed(has_issues: bool):
	var params: PoieticObject = design_ctrl.get_simulation_parameters_object()
	if params:
		# TODO Set initial time
		var initial_time = params.get_attribute("initial_time")
		var time_delta = params.get_attribute("time_delta")
		var end_time = params.get_attribute("end_time")
		if end_time is float or end_time is int:
			# FIXME %EndTimeField.text = str(end_time)
			pass

func _on_end_time_field_text_submitted(new_text):
	pass # Replace with function body.
