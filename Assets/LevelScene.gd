extends Node3D

func _ready() -> void:
    shout_spawn_point()
    var terrain = $Terrain3D/StaticBody3D
    terrain.add_to_group("terrain")

func shout_spawn_point() -> void:
    Global.spawn_point = (%SpawnPoint).transform
    print_debug(Global.spawn_point)
    #SignalHub.set_spawn_point.emit(spawn_point.transform)

