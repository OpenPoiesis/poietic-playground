class_name ControlBar extends PanelContainer

# @onready var reset_button: Button = %ControlButtons/ResetButton
@onready var stop_button: Button = %ControlButtons/StopButton
@onready var run_button: Button = %ControlButtons/RunButton
@onready var loop_button: Button = %ControlButtons/LoopButton

@onready var previous_step_button: Button = %ControlButtons/PreviousStepButton
@onready var next_step_button: Button = %ControlButtons/NextStepButton
@onready var last_step_button: Button = %ControlButtons/LastStepButton

@onready var time_field: LineEdit = %TimeField
@onready var end_time_field: LineEdit = %EndTimeField
@onready var time_delta_field: LineEdit = %TimeDeltaField

@export var design_ctrl: DesignController
@export var player: ResultPlayer

func initialize(design_ctrl: DesignController, player: ResultPlayer):
	self.design_ctrl = design_ctrl
	self.player = player
	design_ctrl.design_changed.connect(_on_design_changed)
	design_ctrl.simulation_finished.connect(_on_simulation_success)
	design_ctrl.simulation_failed.connect(_on_simulation_failure)

	player.simulation_player_started.connect(update_player_state)
	player.simulation_player_stopped.connect(update_player_state)
	player.simulation_player_step.connect(update_player_state)

	update_player_state()
	
func update_player_state():
	if player.is_running:
		run_button.set_pressed_no_signal(true)
		# run_button.disabled = true
		stop_button.set_pressed_no_signal(false)
		stop_button.disabled = false
	else:
		run_button.set_pressed_no_signal(false)
		stop_button.set_pressed_no_signal(true)
		# run_button.disabled = false
		stop_button.disabled = true
		
	loop_button.set_pressed_no_signal(player.is_looping)
	time_field.text = str(player.current_step)

func _on_simulation_success(result: PoieticResult):
	end_time_field.text = str(result.end_time)

func _on_simulation_failure():
	pass

func _on_simulator_started():
	update_player_state()

func _on_simulator_step():
	update_player_state()
	
func _on_simulator_stopped():
	update_player_state()

func _on_first_step_button_pressed():
	player.to_first_step()
	update_player_state()

func _on_previous_step_button_pressed():
	player.previous_step()
	update_player_state()


func _on_next_step_button_pressed():
	player.next_step()
	update_player_state()

func _on_last_step_button_pressed():
	player.to_last_step()
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
	update_simulation_times()
	
func update_simulation_times():
	var params: PoieticObject = design_ctrl.get_simulation_parameters_object()
	if params == null:
		return
	
	# var initial_time = params.get_attribute("initial_time")
	var time_delta = params.get_attribute("time_delta")
	var end_time = params.get_attribute("end_time")
	if end_time is float or end_time is int:
		end_time_field.text = str(end_time)
	if time_delta is float or time_delta is int:
		time_delta_field.text = str(time_delta)

func _on_end_time_field_text_submitted(new_text):
	# FIXME: Move this to controller or send an app action
	end_time_field.release_focus()
	if not new_text.is_valid_float():
		update_simulation_times()
		return
	var end_time = float(new_text)
	var params: PoieticObject = design_ctrl.get_simulation_parameters_object()

	if params and params.get_attribute("end_time") == end_time:
		return

	var trans: PoieticTransaction = Global.app.design_controller.new_transaction()

	if params:
		trans.set_attribute(params.object_id, "end_time", end_time)
	else:
		trans.create_object("Simulation", {"end_time": end_time})

	Global.app.design_controller.accept(trans)


func _on_time_field_text_submitted(new_text: String):
	time_field.release_focus()
	if not new_text.is_valid_float():
		update_simulation_times()
		return
	var current_time = float(new_text)
	player.to_time(current_time)


func _on_time_delta_field_text_submitted(new_text):
	# FIXME: Move this to controller or send an app action
	time_delta_field.release_focus()
	if not new_text.is_valid_float():
		update_simulation_times()
		return
		
	var time_delta = float(new_text)
	var params: PoieticObject = design_ctrl.get_simulation_parameters_object()

	if params and params.get_attribute("time_delta") == time_delta:
		return

	var trans: PoieticTransaction = Global.app.design_controller.new_transaction()

	if params:
		trans.set_attribute(params.object_id, "time_delta", time_delta)
	else:
		trans.create_object("Simulation", {"time_delta": time_delta})

	Global.app.design_controller.accept(trans)
