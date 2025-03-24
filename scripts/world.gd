extends Node3D

const SPAWN_RANGE = 30
const SPAWN_RATE = 2.0
const STARTING_SPEED = 5.0
const SPEED_INCREASE = 0.2

var enemy = preload("res://scenes/enemy.tscn")
var t: float = SPAWN_RATE
var current_speed: float = STARTING_SPEED
var game_over: bool = false

@onready var player: CharacterBody3D = $Player
@onready var enemies: Node3D = $Enemies

func _ready() -> void:
	player.defeated.connect(func():
		if game_over: return
		game_over = true
		enemies.queue_free()
		if player.points > Transition.highest:
			Transition.highest = player.points
		await get_tree().create_timer(0.1).timeout
		get_tree().reload_current_scene())

func _process(delta: float) -> void:
	if game_over: return
	t += delta
	if t >= SPAWN_RATE:
		t = 0.0
		var new_enemy = enemy.instantiate()
		enemies.add_child(new_enemy)
		new_enemy.position = Vector3(randi_range(-SPAWN_RANGE, SPAWN_RANGE), 0, randi_range(-SPAWN_RANGE, SPAWN_RANGE))
		new_enemy.target = player
		new_enemy.run_speed = current_speed
		current_speed += SPEED_INCREASE
		
		new_enemy.defeated.connect(func():
			player.points += 1
			player.get_node("CanvasLayer").get_node("Points").text = str(player.points))
