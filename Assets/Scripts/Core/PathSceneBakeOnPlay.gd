extends PathScene3D


func _ready():
    var track_ring_set := self.bake_instances()
    for ring in track_ring_set:
        ring.reparent(%Rings, true)
        print(ring.name + "reparented")