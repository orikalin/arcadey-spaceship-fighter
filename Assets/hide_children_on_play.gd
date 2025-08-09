extends Node3D

@export var set_children_to:bool = false

func _ready() -> void:
    var node_children = get_children()
    for child:Node3D in node_children:
        child.visible = set_children_to