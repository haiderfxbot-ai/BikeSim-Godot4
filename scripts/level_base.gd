extends Node2D
class_name LevelBase

@onready var bike_spawn: Marker2D = $BikeSpawn
@onready var ground: StaticBody2D = $Ground

var bike_instance: RigidBody2D = null

func _ready() -> void:
	print("[INTEGRITY CHECK PASSED]: " + get_script().resource_path)
	assert(is_instance_valid(bike_spawn), "[CRITICAL ERROR]: BikeSpawn marker missing in " + get_script().resource_path)
	assert(is_instance_valid(ground), "[CRITICAL ERROR]: Ground missing in " + get_script().resource_path)

func spawn_bike(bike_scene: PackedScene) -> RigidBody2D:
	if not is_instance_valid(bike_scene):
		print("[WARN] Invalid bike scene passed to spawn_bike in " + get_script().resource_path)
		return null
	bike_instance = bike_scene.instantiate()
	bike_instance.global_position = bike_spawn.global_position
	add_child(bike_instance)
	print("[INFO] Bike spawned at: " + str(bike_spawn.global_position))
	return bike_instance
