class_name RayCast3D_Signal_Emitter extends RayCast3D

## the idea here is to make a reusable script that emits a global signal using SignalHub whenever the ray detects a viable target

func _physics_process(delta: float) -> void:
    if is_colliding():
        pass
            