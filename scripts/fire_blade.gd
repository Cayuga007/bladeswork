extends Resource

var player: CharacterBody3D
var blade_name: String = "FireBlade"

var skill1 = {
	"name": "stab", # cartwheel
	"cooldown": 5,
	"global_cooldown": 0.25,
	"damage": 20,
	"action": func():
		pass
}

var skill2 = {
	"name": "spin", # slicer
	"cooldown": 4,
	"global_cooldown": 0.5,
	"damage": 15,
	"action": func():
		pass
}

var skill3 = {
	"name": "enhance", # fireball
	"cooldown": 10,
	"global_cooldown": 1,
	"damage": 30,
	"action": func():
		pass
}
