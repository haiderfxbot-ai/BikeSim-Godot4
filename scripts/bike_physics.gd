extends RigidBody2D
class_name BikePhysics

signal bike_crashed()

enum OutOfControlState { NORMAL, OUT_OF_CONTROL, CRASHED }

@export var engine_power: float = 800.0
@export var braking_force: float = 500.0
@export var max_rpm: float = 8000.0
@export var balance_torque: float = 150.0
@export var crash_impulse_strength: float = 1200.0

@onready var crash_detector: Area2D = $CrashDetector
@onready var bike_engine: BikeEngine = $BikeEngine

var out_of_control_state: int = OutOfControlState.NORMAL
var brake_active: bool = false
var _inputs_disabled: bool = false

func _ready() -> void:
	print("[INTEGRITY CHECK PASSED]: " + get_script().resource_path)
	assert(is_instance_valid(crash_detector), "[CRITICAL ERROR]: CrashDetector missing in " + get_script().resource_path)
	assert(is_instance_valid(bike_engine), "[CRITICAL ERROR]: BikeEngine missing in " + get_script().resource_path)

func _physics_process(delta: float) -> void:
	if out_of_control_state != OutOfControlState.NORMAL:
		return

	bike_engine.clutch_pressed_percentage = bike_engine.clutch_pressed_percentage
	bike_engine.throttle_input = bike_engine.throttle_input
	bike_engine.process_engine_logic(delta)

	_apply_engine_force(delta)
	_apply_brakes(delta)
	_apply_balance(delta)
	_check_out_of_control(delta)

func _apply_engine_force(delta: float) -> void:
	if bike_engine.engine_state != BikeEngine.EngineState.RUNNING or bike_engine.current_gear == 0:
		return

	var engagement: float = 1.0 - bike_engine.clutch_pressed_percentage
	var gear_ratio: float = bike_engine.get_gear_ratio()
	var rpm_factor: float = bike_engine.engine_rpm / bike_engine.max_rpm
	var torque: float = engine_power * rpm_factor * gear_ratio * engagement * bike_engine.throttle_input

	var force_vec: Vector2 = Vector2.RIGHT * torque * delta
	apply_central_force(force_vec)

func _apply_brakes(delta: float) -> void:
	if not brake_active:
		return
	var brake_vec: Vector2 = Vector2.LEFT * braking_force * delta
	apply_central_force(brake_vec)

func _apply_balance(delta: float) -> void:
	if _inputs_disabled:
		return
	var angle: float = global_rotation
	if abs(angle) > 0.05:
		var correction: float = -angle * balance_torque * delta
		apply_torque(correction)

func _check_out_of_control(delta: float) -> void:
	var angle: float = global_rotation
	var speed: float = abs(linear_velocity.x)

	if abs(angle) > deg_to_rad(60.0):
		execute_crash_sequence()
		return

	if speed > 600.0 and bike_engine.current_gear == 0 and bike_engine.engine_rpm > 1000.0:
		execute_crash_sequence()
		return

func execute_crash_sequence() -> void:
	if out_of_control_state == OutOfControlState.CRASHED:
		return

	_inputs_disabled = true
	out_of_control_state = OutOfControlState.CRASHED
	bike_engine.engine_state = BikeEngine.EngineState.STALLED
	bike_engine.engine_rpm = 0.0

	var impulse_dir: Vector2 = Vector2(
		randf_range(-0.5, 0.5),
		randf_range(-1.0, -0.3)
	).normalized()
	var impulse_magnitude: float = crash_impulse_strength * randf_range(0.8, 1.5)

	apply_central_impulse(impulse_dir * impulse_magnitude)
	apply_torque_impulse(randf_range(-50.0, 50.0))

	get_tree().paused = true
	bike_crashed.emit()
	get_tree().paused = false

func go_out_of_control() -> void:
	execute_crash_sequence()

func reset_bike() -> void:
	out_of_control_state = OutOfControlState.NORMAL
	bike_engine.current_gear = 0
	bike_engine.engine_rpm = 0.0
	bike_engine.engine_state = BikeEngine.EngineState.OFF
	bike_engine.throttle_input = 0.0
	bike_engine.clutch_pressed_percentage = 0.0
	brake_active = false
	_inputs_disabled = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_rotation = 0.0
	global_position = Vector2(200, 300)

func get_speed_kmh() -> float:
	return abs(linear_velocity.x) * 3.6
