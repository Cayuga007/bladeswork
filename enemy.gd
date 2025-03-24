extends CharacterBody3D

signal defeated

const MAX_HEALTH = 100
const ATTACK_DAMAGE = 2
const ATTACK_DISTANCE = 1.0

var run_speed: float = 0.0
var health: int = MAX_HEALTH
var can_attack: bool = true
var stunned: bool = false
var blocking = false

@onready var armature: Node3D = $Armature
@onready var animation_tree: AnimationTree = $AnimationTree
@export var target: CharacterBody3D

func _physics_process(delta: float) -> void:
	if stunned: return
	
	var target_vector = target.global_position - global_position
	var direction_to_target = target_vector.normalized()
	var distance_to_target = target_vector.length()
	
	if distance_to_target > ATTACK_DISTANCE:
		velocity.x = lerp(velocity.x, direction_to_target.x * run_speed, 0.15)
		velocity.z = lerp(velocity.z, direction_to_target.z * run_speed, 0.15)
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-direction_to_target.x, -direction_to_target.z), 10 * delta)
		move_and_slide()
	
	if can_attack and distance_to_target <= ATTACK_DISTANCE:
		animation_tree.set("parameters/attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		animation_tree["parameters/attacks/blend_position"] += 1
		if animation_tree["parameters/attacks/blend_position"] > 3:
			animation_tree["parameters/attacks/blend_position"] = 0
			
		deal_damage(ATTACK_DAMAGE, target)
		can_attack = false
		await get_tree().create_timer(0.1).timeout
		can_attack = true

func deal_damage(damage: int, enemy: CharacterBody3D) -> void:
	enemy.take_damage(damage, self)
	
func take_damage(damage: int, _damage_dealer: CharacterBody3D) -> void:
	health -= damage
	if health <= 0:
		defeated.emit()
		queue_free()
