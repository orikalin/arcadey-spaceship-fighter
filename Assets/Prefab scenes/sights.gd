extends CanvasLayer

## The idea I'm having is to make two cones, in which case I may not need the raycast3d
## these cone shape colliders will start at the player origin, and do not move or rotate locally
## the small cone will act as a target acquierer. it can auto send out signals on body enter, at which point a ray will be cast towards to target
## to see if any terrain or other obstacles are in the way. If not, we soft lock to that target.
##
## the larger cone is a lock-on limit. if the far sight leaves the large cone, the lock will be broken
## the large cone and far sight have collide exlusively with eachother
## the small cone collides with only viable targets
## and the raycast colliders with terrain. Can save some work maybe by only allowing the lock on to happen if the ray collision (first collision)
## isn't terrain and is a viable target


@export var sight_one:Sprite2D
@export var sight_two:Sprite2D

func _ready() -> void:
    pass


# func update_sights(one, two):
