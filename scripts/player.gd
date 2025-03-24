extends CharacterBody3D

signal defeated

enum dashes {FORWARD, BACKWARD, LEFT, RIGHT}

const RUN_SPEED = 10.0
const DASH_SPEED = 1500.0
const JUMP_VELOCITY = 20.0
const FALL_VELOCITY = 5.0
const MAX_HEALTH = 100
const REGEN_AMOUNT = 2
const ATTACK_DAMAGE = 5
const COUNTER_STUN_DURATION = 1

var cooldowns = {
	"attack": {"cooldown": 0.1, "global_cooldown": 0, "active": true},
	"dash": {"cooldown": 0.5, "global_cooldown": 0, "active": true},
	"block": {"cooldown": 2, "global_cooldown": 1, "active": true},
	"skill1": {"cooldown": 1, "global_cooldown": 1, "active": true},
	"skill2": {"cooldown": 1, "global_cooldown": 1, "active": true},
	"skill3": {"cooldown": 1, "global_cooldown": 1, "active": true},
}

var blade_equipped: String =  "StandardBlade" # Transition.blade_equipped
var dash_velocity: Vector3 = Vector3.ZERO
var regen_t: float = 0.0
var health: int = MAX_HEALTH
var points: int = 0
var can_action: bool = true
var blocking: bool = false
var stunned: bool = false

@onready var armature: Node3D = $Armature
@onready var attack_hitbox: Area3D = $Armature/AttackHitbox
@onready var spring_arm_pivot: Node3D = $SpringArmPivot
@onready var spring_arm: SpringArm3D = $SpringArmPivot/SpringArm3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var blades: Node3D = $Armature/Skeleton3D/BoneAttachment3D/Blades
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@export var skills: Resource

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Transition.highest > 0:
		var highest_label = canvas_layer.get_node("Highest")
		highest_label.visible = true
		highest_label.text = "Highest: " + str(Transition.highest)
	
	var blade = blades.find_child(blade_equipped)
	if blade:
		canvas_layer.visible = true
		blade.visible = true
		skills[blade_equipped].player = self
		for i in range(1, 4):
			var skill = "skill" + str(i)
			cooldowns[skill].cooldown = skills[blade_equipped][skill].cooldown
			cooldowns[skill].global_cooldown = skills[blade_equipped][skill].global_cooldown
	else:
		canvas_layer.visible = false

func _physics_process(delta: float) -> void:
	regen_t += delta
	if regen_t >= 1 and health < MAX_HEALTH:
		heal(REGEN_AMOUNT)
		regen_t = 0.0
	
	var move_direction = get_move_direction()
	if !stunned:
		if move_direction:
			animate("run")
			velocity.x = lerp(velocity.x, move_direction.x * RUN_SPEED, 0.15) + dash_velocity.x * delta
			velocity.z = lerp(velocity.z, move_direction.z * RUN_SPEED, 0.15) + dash_velocity.z * delta
		else:
			animate("idle")
			velocity.x = lerp(velocity.x, 0.0, 0.15)
			velocity.z = lerp(velocity.z, 0.0, 0.15)
	if not is_on_floor():
		animate("jump")
		velocity += get_gravity() * FALL_VELOCITY * delta
	move_and_slide()
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		spring_arm_pivot.rotate_y(-event.relative.x * .005)
		spring_arm.rotate_x(-event.relative.y * .005)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)
		armature.rotation.y = spring_arm_pivot.rotation.y
	
	if Input.is_action_just_pressed("menu"):
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().quit()
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if stunned: return
		
	if try_action("attack"):
		animate("attack")
		for enemy in attack_hitbox.get_overlapping_bodies():
			if enemy != self and !enemy.blocking:
				deal_damage(ATTACK_DAMAGE, enemy)
		set_cooldown("attack")
		return
		
	if try_action("dash"):
		var move_direction = get_move_direction()
		if move_direction.dot(-armature.transform.basis.z) >= 0.5:
			animate("dash", dashes.FORWARD)
		elif move_direction.dot(-armature.transform.basis.z) <= -0.5:
			animate("dash", dashes.BACKWARD)
		elif move_direction.dot(armature.transform.basis.x) > 0:
			animate("dash", dashes.RIGHT)
		elif move_direction.dot(armature.transform.basis.x) < 0:
			animate("dash", dashes.LEFT)
		dash_velocity = move_direction * DASH_SPEED
		await get_tree().create_timer(0.1).timeout
		dash_velocity = Vector3.ZERO
		set_cooldown("dash")
		return
		
	if try_action("block"):
		animate("block")
		blocking = true
		set_cooldown("block")
		return
		
	if try_action("skill1"):
		animate("skill", skills[blade_equipped].skill1.name)
		skills[blade_equipped].skill1["action"].call(get_tree())
		set_cooldown("skill1")
		return
		
	if try_action("skill2"):
		animate("skill", skills[blade_equipped].skill2.name)
		skills[blade_equipped].skill2["action"].call(get_tree())
		set_cooldown("skill2")
		return
		
	if try_action("skill3"):
		animate("skill", skills[blade_equipped].skill3.name)
		skills[blade_equipped].skill3["action"].call(get_tree())
		set_cooldown("skill3")
		return
		
func get_move_direction() -> Vector3:
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	return direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
		
func try_action(action: String) -> bool:
	return Input.is_action_just_pressed(action) and can_action and cooldowns[action].active \
	and blade_equipped != " "
	
func set_cooldown(action: String) -> void:
	var skill_cooldown = cooldowns[action].cooldown
	var global_cooldown = cooldowns[action].global_cooldown
	
	var cover = canvas_layer.get_node("Hotbar").get_node(action.to_pascal_case())\
	.get_node("Control").get_node("Cover")
	cover.size.y = cover.size.x
	create_tween().tween_property(cover, "size:y", 0, skill_cooldown)
	
	cooldowns[action].active = false
	can_action = false
	await get_tree().create_timer(global_cooldown).timeout
	can_action = true
	blocking = false
	
	await get_tree().create_timer(skill_cooldown - global_cooldown).timeout
	cooldowns[action].active = true

func deal_damage(damage: int, enemy: CharacterBody3D) -> void:
	enemy.take_damage(damage, self)
	
func take_damage(damage: int, damage_dealer: CharacterBody3D) -> void:
	if blocking:
		animate("counter")
		animation_tree.set("parameters/block/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
		can_action = true
		damage_dealer.stunned = true
		await get_tree().create_timer(COUNTER_STUN_DURATION).timeout
		if damage_dealer:
			damage_dealer.stunned = false
	else:
		regen_t = 0.0
		health -= damage
		canvas_layer.get_node("HealthBar").value = health
		if health <= 0:
			defeated.emit()
			
func heal(amount):
	health = clamp(health + amount, 0, MAX_HEALTH)
	canvas_layer.get_node("HealthBar").value = health
			
func create_new_hitbox(hitbox_size: Vector3, hitbox_position: Vector3 = Vector3(0, 1, 0)) -> Area3D:
	var new_hitbox = Area3D.new()
	var new_collision_shape = CollisionShape3D.new()
	get_node("Armature").add_child(new_hitbox)
	new_hitbox.add_child(new_collision_shape)
	new_hitbox.collision_mask = 2
	new_collision_shape.shape = BoxShape3D.new()
	new_collision_shape.shape.size = hitbox_size
	new_collision_shape.position = hitbox_position
	return new_hitbox

func animate(animation, animation_name = 0) -> void:
	match animation:
		"idle":
			animation_tree.set("parameters/core/transition_request", "Idle")
		"run":
			animation_tree.set("parameters/core/transition_request", "Run")
		"jump":
			animation_tree.set("parameters/core/transition_request", "Jump")
		"dash":
			animation_tree.set("parameters/dashes/blend_position", animation_name)
			animation_tree.set("parameters/dash/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		"attack":
			animation_tree.set("parameters/attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			animation_tree["parameters/attacks/blend_position"] += 1
			if animation_tree["parameters/attacks/blend_position"] > 3:
				animation_tree["parameters/attacks/blend_position"] = 0
		"block":
			animation_tree.set("parameters/block/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		"counter":
			animation_tree.set("parameters/counter/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		"skill":
			animation_tree.tree_root.get_node("skill_anim").animation = animation_name
			animation_tree.set("parameters/skill/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
