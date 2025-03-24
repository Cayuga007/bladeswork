extends Resource

var player: CharacterBody3D
var blade_name: String = "IceBlade"

var skill1 = {
	"name": "stab",
	"cooldown": 2,
	"global_cooldown": 0.25,
	"damage": 25,
	"action": func():
		pass
}

var skill2 = {
	"name": "spin",
	"cooldown": 4,
	"global_cooldown": 0.25,
	"damage": 20,
	"action": func():
		pass
}

var skill3 = {
	"name": "enhance",
	"cooldown": 15,
	"global_cooldown": 1,
	"action": func():
		pass
}
