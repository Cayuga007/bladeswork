extends Node3D

var blade_chosen: bool = false

@onready var pick_up_hitboxes: Node3D = $PickUpHitboxes

func _ready() -> void:
	for blade in pick_up_hitboxes.get_children():
		blade.body_entered.connect(func(body):
			if blade_chosen or body.name != "Player": return
			blade_chosen = true
			Transition.blade_equipped = str(blade.name)
			call_deferred("change_scene"))

func change_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")
