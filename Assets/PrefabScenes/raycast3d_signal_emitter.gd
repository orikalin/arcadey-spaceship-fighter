class_name RayCast3D_Signal_Emitter extends RayCast3D

## the idea here is to make a reusable script that emits a global signal using SignalHub whenever the ray detects a viable target

@export var mask_value:int
var current_target:Object

func _physics_process(delta: float) -> void:
    if is_colliding(): 
        if !current_target:
            _body_entered()
    else:
        if current_target:
            _body_exited()
        
            

func _body_entered() -> void:
    current_target = get_collider()

    # if current_target.get_collision_mask_value(mask_value):
    #     print_debug(current_target.name + " in sights!")
    # elif current_target.get_collision_mask_value(1):
    #     print_debug("line of sight should break: " + current_target.name)

func _body_exited() -> void:
    if current_target:
        # print_debug(current_target.name + " exited sights!")
        current_target = null