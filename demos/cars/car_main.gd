extends Node2D

"""This demo shows how to evolve arcade-style cars to successfully complete a track.
This is accomplished by assigning fitness based on how many degrees around the track
a car has driven, and regularly starting a new generation where the fittest individuals
are more prevalent.

New generations are started based on a timer (generation_step), because a lot of
cars end up just loitering around the track, and I haven't implemented a method
to detect this yet. This may cause successful agents to be stopped prematurely however.
"""
var first = true
# 1.0 = one second. time gets reset every time_step, then all agents get updated
var time = 0
# total_time gets reset every time a new generation is started
var total_time = 0
# every time_step the cars network takes sensory information and decides how to act
var time_step = 0.1
#USED TO BE 0.2!!

# every generation_step a new generation is made. this gets increased over time.
var generation_step = 10

# path to the car scene that will be controlled by the AI
var agent_body_path = "res://demos/cars/car/Car.tscn"
# initialize the main node that handles the genetic algorithm with 11 inputs, 4 outputs
# the path to the car scene, enable the NEAT_Gui, and use the car_params parameters, which
# are saved under user://param_configs

onready var tree = preload("res://NEAT_usability/gui/graph/tree.tscn")



# chosen track. Tracks are numbered, however the car_splash refers to them by difficulty
var curr_track_num: int
# end the demo when the first car reaches this. TAU (360 degrees) = complete one track
#var fitness_threshold = TAU + 1
var first_ever = true
#Changed for food foraging so it never ends:
var fitness_threshold = 250
var num = 0

# a splash screen on how to continue after reaching fitness threshold
onready var DemoCompletedSplash = preload("res://demos/demo_loader/DemoCompletedSplash.tscn")
# while the splashscreen is open, do not continue the genetic algorithm
var paused = true
var ga

# when the first car reaches the halfway checkpoint, the generation time gets increased
var first_car_reached_checkpoint = false

func load_track(track_num: int) -> void:
	"""Loads the selected track, adds the GeneticAlgorithm node as a child and places
	the agent_bodies at the starting position of the track.
	"""
	curr_track_num = track_num
	# load the selected track
	var track_path = "res://demos/cars/tracks/track_%s/Track_%s.tscn" % [track_num, track_num]
	add_child(load(track_path).instance())
	# connect a signal to increase the generation_step once the first car reaches HalfLap
	# IMPORTANT add the ga node as a child
	#old config: car_params
	ga = GeneticAlgorithm.new(34, 3, agent_body_path, true, "Custom_Evolution_Config")

	add_child(ga)

		
	# Center the camera on the starting position
	$ZoomPanCam.position = $Track/Start.position
	paused = false



func _physics_process(delta) -> void:
	"""Car agents update their networks every time_step seconds, and then drive
	according to the networks output. If generation_step time has passed, start a
	new generation.
	"""
	
	if first_ever:
		ga.spawn_first_wave()
		# get the bodies (agent_body_path instances) generated by the ga, and place them on the track
		place_bodies(ga.get_curr_bodies())
		first_ever = false
#		update()  # Request an update for the drawing	
		
	
	
	
#	updating species and pop counts (this is intentional dont change it -jules):
	ga.emit_signal("made_new_gen")
	
	if not paused:
		# update time since last update
		time += delta; total_time += delta
		# if enough time has passed for the next time_step, update all agents
		if time > time_step:
			ga.next_timestep()
			time = 0
		# check if enough time has passed to start a new generation
		if total_time > generation_step or ga.all_agents_dead:

			for creature in ga.alive:
				creature.body.age += 1


			# check if the best agent exceeded the fitness threshold
			ga.evaluate_generation()
			if ga.curr_best.fitness > fitness_threshold:
				# either resume with next generation or switch to demo-choosing scene
				end_car_demo()
			# go to the next gen
			ga.next_generation()
			

			place_bodies(ga.get_curr_bodies())
			# every x gens, increase the generation_step
			if ga.curr_generation % 2 == 0:
				generation_step = min(generation_step + 1, 35)
				print("increased step to " + str(generation_step))
			total_time = 0
			
			


func place_bodies(bodies: Array) -> void:
	"""Adds the bodies scenes generated by the ga to the tree, and removes the old ones.
	"""

	# Removing DEAD bodies from the last generation:
	for survivor in $Track/Start.get_children():
		if survivor.dead == true:
			survivor.queue_free()


	# Adding the new bodies to the track
	for body in bodies:
		if not body in $Track/Start.get_children():
			$Track/Start.add_child(body)



#	COLORING AGENTS:
	for species in ga.curr_species:
		if not species.obliterate:
			for member in species.alive_members:
				if !member.agent.is_dead:
					member.agent.body.get_node("Sprite").modulate = species.color
				else:
					print("DEAAAAAAAAAAAAAAATH!") 
#					SOMETHING IS VERRRY WRONG!
					breakpoint




func increase_time(_body) -> void:
	"""Dependant on the chosen track, this method increases the generation_step
	such that capable generations are not terminated prematurely.
	"""
	if not first_car_reached_checkpoint:
		match curr_track_num:
			1:
				generation_step = 100
			2:
				generation_step = 70
			3:
				generation_step = 60
		first_car_reached_checkpoint = true


func end_car_demo() -> void:
	"""Open the DemoCompletedSplash.
	"""
	paused = true
	var demo_completed_splash = DemoCompletedSplash.instance()
	demo_completed_splash.initialize(ga, fitness_threshold)
	demo_completed_splash.connect("set_new_threshold", self, "continue_ga")
	add_child(demo_completed_splash)


func continue_ga(new_threshold) -> void:
	"""Continue the evolution until new_threshold is reached.
	"""
	fitness_threshold = new_threshold
	paused = false


func get_everyone() -> Array:
	return ga.all_genomes

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.is_action_pressed("Show_Tree"):
				$Track/FamilyTree.cycle(ga.all_species)
			if event.is_action_pressed("freeze"):
				paused = !paused


func _draw():
	draw_spawn_circles()

func draw_spawn_circles():
	var circle_radius = 10
	var circle_color = Color(1, 1, 1, 1)  # Red color

	for position in ga.spawns:
		draw_circle(position, circle_radius, circle_color)
#		print_tree_pretty()
