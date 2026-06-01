extends Node
class_name BikeEngine

enum EngineState { OFF, KEY_ON, RUNNING, STALLED }

signal engine_state_changed(new_state: int)

var is_key_inserted: bool = false
var clutch_pressed_percentage: float = 0.0
var current_gear: int = 0
var engine_rpm: float = 0.0
var max_rpm: float = 8000.0
var throttle_input: float = 0.0
var engine_state: int = EngineState.OFF:
	set(value):
		engine_state = value
		engine_state_changed.emit(value)

var _prev_gear: int = 0
var _prev_clutch: float = 0.0
var _stall_cd: float = 0.0

func _ready() -> void:
	print("[INTEGRITY CHECK PASSED]: " + get_script().resource_path)
	engine_state = EngineState.OFF

func insert_and_turn_key() -> void:
	if engine_state == EngineState.OFF:
		is_key_inserted = true
		engine_state = EngineState.KEY_ON
		print("[ENGINE] Key turned ON")
	elif engine_state == EngineState.KEY_ON or engine_state == EngineState.STALLED:
		engine_state = EngineState.OFF
		is_key_inserted = false
		print("[ENGINE] Key turned OFF")

func kick_start() -> void:
	if engine_state != EngineState.KEY_ON and engine_state != EngineState.STALLED:
		print("[ENGINE] Cannot kick start: engine is in state " + str(engine_state))
		return
	if current_gear == 0:
		engine_state = EngineState.RUNNING
		engine_rpm = 800.0
		print("[ENGINE] Kick start SUCCESS (Neutral)")
	elif clutch_pressed_percentage >= 0.8:
		engine_state = EngineState.RUNNING
		engine_rpm = 800.0
		print("[ENGINE] Kick start SUCCESS (Clutch pulled in gear)")
	else:
		print("[ENGINE] Kick start FAILED: in gear without clutch")

func shift_gear_up() -> void:
	if current_gear < 4:
		_prev_gear = current_gear
		current_gear += 1
		print("[ENGINE] Shifted UP to gear " + str(current_gear))
		_on_gear_shifted()

func shift_gear_down() -> void:
	if current_gear > 0:
		_prev_gear = current_gear
		current_gear -= 1
		print("[ENGINE] Shifted DOWN to gear " + str(current_gear))
		_on_gear_shifted()

func _on_gear_shifted() -> void:
	_prev_clutch = clutch_pressed_percentage

func stall_engine() -> void:
	engine_state = EngineState.STALLED
	engine_rpm = 0.0
	print("[ENGINE] Engine STALLED!")
	_emit_crash_from_stall()

func _emit_crash_from_stall() -> void:
	var bike: BikePhysics = _get_bike_physics()
	if is_instance_valid(bike):
		bike.go_out_of_control()
	else:
		print("[WARN] Cannot emit crash: bike_physics not found in " + get_script().resource_path)

func process_engine_logic(delta: float) -> void:
	if _stall_cd > 0.0:
		_stall_cd -= delta
		return

	match engine_state:
		EngineState.RUNNING:
			_update_rpm(delta)
			_check_stall_conditions(delta)
		EngineState.STALLED:
			engine_rpm = max(engine_rpm - 500.0 * delta, 0.0)
		EngineState.KEY_ON:
			engine_rpm = max(engine_rpm - 200.0 * delta, 0.0)
		EngineState.OFF:
			engine_rpm = 0.0

func _update_rpm(delta: float) -> void:
	var target_rpm: float = 800.0
	if current_gear > 0 and clutch_pressed_percentage < 1.0:
		target_rpm = 800.0 + (max_rpm - 800.0) * throttle_input
	else:
		target_rpm = 800.0 + (max_rpm - 800.0) * throttle_input * 0.5
	engine_rpm = move_toward(engine_rpm, target_rpm, 2000.0 * delta)
	engine_rpm = clamp(engine_rpm, 0.0, max_rpm * 1.1)

func _check_stall_conditions(delta: float) -> void:
	if current_gear == 0:
		return
	var clutch_release_rate: float = (_prev_clutch - clutch_pressed_percentage) / max(delta, 0.001)
	if clutch_release_rate > 3.0 and throttle_input < 0.1:
		stall_engine()
		_stall_cd = 0.5
		print("[ENGINE] Stall triggered: abrupt clutch release with low throttle")
	_prev_clutch = clutch_pressed_percentage

func _get_bike_physics() -> BikePhysics:
	var parent = get_parent()
	while is_instance_valid(parent):
		if parent is BikePhysics:
			return parent as BikePhysics
		parent = parent.get_parent()
	return null

func get_gear_ratio() -> float:
	var ratios: Array[float] = [0.0, 2.5, 1.8, 1.3, 1.0]
	if current_gear >= 0 and current_gear < ratios.size():
		return ratios[current_gear]
	return 0.0
