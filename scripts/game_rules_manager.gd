extends Node
class_name GameRulesManager

var _bike: BikePhysics = null
var _engine: BikeEngine = null
var _prev_gear: int = 0
var _ghost_ride_active: bool = false

func _ready() -> void:
	print("[INTEGRITY CHECK PASSED]: " + get_script().resource_path)

func _process(delta: float) -> void:
	_bike = _find_bike_in_scene()
	if not is_instance_valid(_bike):
		return
	_engine = _bike.bike_engine
	if not is_instance_valid(_engine):
		print("[WARN] BikeEngine not found in " + get_script().resource_path)
		return

	if _bike.out_of_control_state != BikePhysics.OutOfControlState.NORMAL:
		_ghost_ride_active = false
		return

	_check_clutch_gear_shock()
	_check_flip_out(delta)
	_check_ghost_ride(delta)
	_prev_gear = _engine.current_gear

func _find_bike_in_scene() -> BikePhysics:
	var root = get_tree().current_scene
	if not is_instance_valid(root):
		return null
	var bike_node = root.find_child("Bike", true, false)
	if is_instance_valid(bike_node) and bike_node is BikePhysics:
		return bike_node as BikePhysics
	return null

func _check_clutch_gear_shock() -> void:
	if _engine.current_gear == _prev_gear:
		return
	if _engine.engine_state != BikeEngine.EngineState.RUNNING:
		return
	if _prev_gear != 0 and _engine.clutch_pressed_percentage < 0.7:
		print("[RULES] Clutch-Gear Shock triggered!")
		_engine.stall_engine()
		var shock_force: Vector2 = Vector2.RIGHT * 600.0
		_bike.apply_central_impulse(shock_force)
		_bike.bike_crashed.emit()

func _check_flip_out(delta: float) -> void:
	var angle: float = _bike.global_rotation
	if abs(angle) > deg_to_rad(75.0):
		print("[RULES] Bike flip detected! Angle: " + str(rad_to_deg(angle)))
		_bike.execute_crash_sequence()

func _check_ghost_ride(delta: float) -> void:
	if _engine.current_gear == 0:
		_ghost_ride_active = false
		return
	if _engine.engine_state != BikeEngine.EngineState.RUNNING:
		_ghost_ride_active = false
		return
	if _engine.throttle_input < 0.9:
		_ghost_ride_active = false
		return
	var speed: float = abs(_bike.linear_velocity.x)
	if speed > 100.0:
		_ghost_ride_active = true
		var ghost_force: Vector2 = Vector2.RIGHT * _engine.engine_rpm * 0.1 * delta
		_bike.apply_central_force(ghost_force)
		_bike.apply_torque(randf_range(-5.0, 5.0))
