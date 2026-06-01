extends CanvasLayer
class_name MobileUI

var bike: BikePhysics = null

@onready var key_switch_btn: Button = $KeySwitchButton
@onready var kick_start_btn: Button = $KickStartButton
@onready var clutch_btn: Button = $ClutchButton
@onready var brake_btn: Button = $BrakeButton
@onready var gear_up_btn: Button = $GearUpButton
@onready var gear_down_btn: Button = $GearDownButton
@onready var throttle_slider: VSlider = $ThrottleSlider

@onready var gear_label: Label = $Dashboard/GearLabel
@onready var rpm_label: Label = $Dashboard/RPMLabel
@onready var speed_label: Label = $Dashboard/SpeedLabel
@onready var state_label: Label = $Dashboard/StateLabel
@onready var rpm_bar: ProgressBar = $Dashboard/RPMBar
@onready var crash_overlay: Panel = $CrashOverlay
@onready var try_again_btn: Button = $CrashOverlay/TryAgainButton

var _clutch_held: bool = false

func _ready() -> void:
	print("[INTEGRITY CHECK PASSED]: " + get_script().resource_path)

	assert(is_instance_valid(key_switch_btn), "[CRITICAL ERROR]: KeySwitchButton missing in " + get_script().resource_path)
	assert(is_instance_valid(kick_start_btn), "[CRITICAL ERROR]: KickStartButton missing in " + get_script().resource_path)
	assert(is_instance_valid(clutch_btn), "[CRITICAL ERROR]: ClutchButton missing in " + get_script().resource_path)
	assert(is_instance_valid(brake_btn), "[CRITICAL ERROR]: BrakeButton missing in " + get_script().resource_path)
	assert(is_instance_valid(gear_up_btn), "[CRITICAL ERROR]: GearUpButton missing in " + get_script().resource_path)
	assert(is_instance_valid(gear_down_btn), "[CRITICAL ERROR]: GearDownButton missing in " + get_script().resource_path)
	assert(is_instance_valid(throttle_slider), "[CRITICAL ERROR]: ThrottleSlider missing in " + get_script().resource_path)

	key_switch_btn.pressed.connect(_on_key_pressed)
	kick_start_btn.pressed.connect(_on_kick_pressed)
	clutch_btn.toggled.connect(_on_clutch_toggled)
	brake_btn.button_down.connect(_on_brake_down)
	brake_btn.button_up.connect(_on_brake_up)
	gear_up_btn.pressed.connect(_on_gear_up)
	gear_down_btn.pressed.connect(_on_gear_down)
	throttle_slider.value_changed.connect(_on_throttle_changed)
	try_again_btn.pressed.connect(_on_try_again)

	call_deferred("_deferred_bike_setup")

func _deferred_bike_setup() -> void:
	bike = _find_bike()
	if is_instance_valid(bike):
		if bike.bike_crashed.is_connected(_on_bike_crashed) == false:
			bike.bike_crashed.connect(_on_bike_crashed)
		print("[INFO] Bike connected to UI in " + get_script().resource_path)
	else:
		print("[WARN] Bike not found after deferred setup in " + get_script().resource_path)

func _find_bike() -> BikePhysics:
	var root = get_tree().current_scene
	if not is_instance_valid(root):
		return null
	var bike_node = root.find_child("Bike", true, false)
	if is_instance_valid(bike_node) and bike_node is BikePhysics:
		return bike_node as BikePhysics
	return null

func _on_key_pressed() -> void:
	if not is_instance_valid(bike):
		return
	SoundManager.play_key_click()
	bike.bike_engine.insert_and_turn_key()

func _on_kick_pressed() -> void:
	if not is_instance_valid(bike):
		return
	SoundManager.play_kick_sound()
	bike.bike_engine.kick_start()

func _on_clutch_toggled(pressed: bool) -> void:
	if not is_instance_valid(bike):
		return
	_clutch_held = pressed
	if pressed:
		bike.bike_engine.clutch_pressed_percentage = 1.0
		clutch_btn.modulate = Color(0.6, 0.8, 1.0, 1)
	else:
		bike.bike_engine.clutch_pressed_percentage = 0.0
		clutch_btn.modulate = Color(1, 1, 1, 1)

func _on_brake_down() -> void:
	if is_instance_valid(bike):
		bike.brake_active = true

func _on_brake_up() -> void:
	if is_instance_valid(bike):
		bike.brake_active = false

func _on_gear_up() -> void:
	if is_instance_valid(bike):
		SoundManager.play_kick_sound()
		bike.bike_engine.shift_gear_up()

func _on_gear_down() -> void:
	if is_instance_valid(bike):
		SoundManager.play_kick_sound()
		bike.bike_engine.shift_gear_down()

func _on_throttle_changed(value: float) -> void:
	if is_instance_valid(bike):
		bike.bike_engine.throttle_input = value

func _on_bike_crashed() -> void:
	crash_overlay.visible = true
	SoundManager.play_crash_sound()

func _on_try_again() -> void:
	crash_overlay.visible = false
	get_tree().reload_current_scene()

func _process(delta: float) -> void:
	if not is_instance_valid(bike):
		return
	var eng = bike.bike_engine
	gear_label.text = "GEAR: " + ("N" if eng.current_gear == 0 else str(eng.current_gear))
	rpm_label.text = "RPM: " + str(int(eng.engine_rpm))
	speed_label.text = "SPD: " + str(int(bike.get_speed_kmh())) + " km/h"
	match eng.engine_state:
		BikeEngine.EngineState.OFF:
			state_label.text = "STATE: OFF"
			state_label.modulate = Color(1, 0.3, 0.3, 1)
		BikeEngine.EngineState.KEY_ON:
			state_label.text = "STATE: KEY ON"
			state_label.modulate = Color(1, 0.8, 0.2, 1)
		BikeEngine.EngineState.RUNNING:
			state_label.text = "STATE: RUNNING"
			state_label.modulate = Color(0.2, 1, 0.2, 1)
		BikeEngine.EngineState.STALLED:
			state_label.text = "STATE: STALLED!"
			state_label.modulate = Color(1, 0, 0, 1)
	var rpm_pct: float = (eng.engine_rpm / eng.max_rpm) * 100.0
	rpm_bar.value = rpm_pct
	rpm_bar.modulate = Color(1, 1 - rpm_pct / 100.0, 1 - rpm_pct / 100.0, 1) if rpm_pct > 80.0 else Color(1, 1, 1, 1)
