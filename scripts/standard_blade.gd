extends Resource

var player: CharacterBody3D
var blade_name: String = "StandardBlade"

var skill1 = {
	"name": "stab",
	"cooldown": 2,
	"global_cooldown": 0.25,
	"damage": 25,
	"action": func(tree):
		var new_hitbox = player.create_new_hitbox(Vector3(1, 1, 3), Vector3(0, 1, -1.5))
		await tree.physics_frame
		await tree.physics_frame
		for enemy in new_hitbox.get_overlapping_bodies():
			if enemy != player and !enemy.blocking:
				player.deal_damage(skill1.damage, enemy)
		new_hitbox.queue_free()
}

var skill2 = {
	"name": "spin",
	"cooldown": 4,
	"global_cooldown": 0.25,
	"damage": 20,
	"action": func(tree):
		var skeleton = player.get_node("Armature").get_node("Skeleton3D")
		var spin_tween = tree.create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		spin_tween.tween_property(skeleton, "rotation:y", skeleton.rotation.y - 2 * PI, 0.5)
		
		var new_hitbox = player.create_new_hitbox(Vector3(4, 1, 4))
		await tree.physics_frame
		await tree.physics_frame
		for enemy in new_hitbox.get_overlapping_bodies():
			if enemy != player and !enemy.blocking:
				player.deal_damage(skill2.damage, enemy)
		new_hitbox.queue_free()
		
		await spin_tween.finished
		skeleton.rotation.y = -PI
}

var skill3 = {
	"name": "enhance",
	"cooldown": 15,
	"global_cooldown": 1,
	"action": func(tree):
		player.heal(50)
}
