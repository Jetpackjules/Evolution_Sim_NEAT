class_name GeneticAlgorithm
extends Node


"""This class is responsible for generating genomes, placing them into species and
evaluating them. It can be viewed as the main orchestrator of the evolution process,
by delegating the exact details of how each step is achieved to the other classes
within this directory.
"""
var all_species := [] # To store all species across generations
# curr_genome_id gets incremented for every new genome
var curr_genome_id = 0
# the current generation, starting with 1
var curr_generation = 1
# the average fitness of every currently alive genome
var avg_population_fitness = 0
# the all-time best genome
var all_time_best: Genome
# the best genome from the last generation
var curr_best: Genome
# the species with the best average fitness from the last generation
var best_species: Species
#ALL genomes EVER MADE!!!!
var all_genomes = []
# the array of all currently alive genomes
var curr_genomes = []
# array holding all agents, gets updated to only hold alive agents every timestep
var curr_agents = []
# an array containing species objects. Every species holds an array of members.
var curr_species = []
# can be used to determine when a new generation should be started
var all_agents_dead = false
# how many species got purged, and how many new species were founded in the curr generation
var num_dead_species = 0
var num_new_species = 0
var alive = []
# the NeatGUI node is a child of ga, and manages the creation and destruction
# of other GUI nodes.
var gui

# signal to let the gui know when to update
signal made_new_gen
# only true for the first call to next_timestep(), in case any processing needs to
# happen then.
var is_first_timestep = true
# True after evaluate_generation() is called, set to false when next_generation() is called
var generation_evaluated = false

# 0 = show all, 1 = show leaders, 2 = show none. Can be changed using gui
var curr_visibility = Params.default_visibility


func _init(number_inputs: int,
		   number_outputs: int,
		   body_path: String,
		   use_gui = true,
		   custom_params_name = "Default") -> void:
	"""Sets the undefined members of the Params Singleton according to the options
	in the constructor. Body path refers to the filepath for the agents body.
	Loads Params configuration if custom_Params_name is given. Creates the first
	set of genomes and agents, and creates a GUI if use_gui is true.
	"""
	# set the name of the node that contains GeneticAlgorithm Object
	set_name("ga")
	# load the specified Params file
	Params.load_config(custom_params_name)
	# save all specified parameters in the Params singleton
	Params.num_inputs = number_inputs
	Params.num_outputs = number_outputs
	Params.agent_body_path = body_path
	Params.use_gui = use_gui
	# create a new population of genomes
	curr_genomes = create_initial_population()
	# add the gui node as child
	if use_gui:
		gui = load("res://NEAT_usability/gui/NeatGUI.gd").new()
		add_child(gui)


func create_initial_population() -> Array:
	"""This method creates the first generation of genomes. For the first set of
	genomes, there is just a limited number of links created, and no hidden
	neurons. Every genome gets assigned to a species, new species are created
	if necessary. Returns an array of the current genomes.
	"""
	# --- first create a set of input, output and bias neurons
	var made_bias = false
	# current neuron_id is stored in Innovations, and gets incremented there
	var initial_neuron_id: int
	var input_neurons = {}; var output_neurons = {}
	# generate all input neurons and a bias neuron
			
	for i in Params.num_inputs + 1:
		# calculate the position of the input or bias neuron (in the first layer)
		var new_pos = Vector2(0, float(i)/Params.num_inputs)
		# the first neuron should be the bias neuron
		var neuron_type = Params.NEURON_TYPE.input
		if not made_bias:
			neuron_type = Params.NEURON_TYPE.bias
			made_bias = true
		# register neuron in Innovations, make the new neuron
		initial_neuron_id = Innovations.store_neuron(neuron_type)
		var new_neuron = Neuron.new(initial_neuron_id,
									neuron_type,
									new_pos,
									Params.default_curve,
									false)
		input_neurons[initial_neuron_id] = new_neuron
	# now generate all output neurons
	for i in Params.num_outputs:
		var new_pos = Vector2(1, float(i)/Params.num_outputs)
		initial_neuron_id = Innovations.store_neuron(Params.NEURON_TYPE.output)
		var new_neuron = Neuron.new(initial_neuron_id,
									Params.NEURON_TYPE.output,
									new_pos,
									Params.default_curve,
									false)
		output_neurons[initial_neuron_id] = new_neuron
	# merge input and output neurons into a single dict.
	var all_neurons = Utils.merge_dicts(input_neurons, output_neurons)
	# --- generate the first generation of genomes
	
	var spawn_points = call_get_safe_spawn_points(300, 3000)
	
	var initial_genomes = []
	for _initial_genome in Params.population_size:
		# Every genome gets a new set of neurons and random connections
		var links = {}; var neurons = {}
		# copy every input and output neuron for a new genome
		for neuron_id in all_neurons.keys(): 
			neurons[neuron_id] = all_neurons[neuron_id].copy()
		# count how many links are added
		var links_added = 0
		while links_added < Params.num_initial_links:
			# pick some random neuron id's from both input and output
			var from_neuron_id = Utils.random_choice(input_neurons.keys())
			var to_neuron_id = Utils.random_choice(output_neurons.keys())
			# don't add a link that connects from a bias neuron in the first gen
			if neurons[from_neuron_id].neuron_type != Params.NEURON_TYPE.bias:
				# Innovations returns either an existing or new id
				var innov_id = Innovations.check_new_link(from_neuron_id, to_neuron_id)
				# prevent adding duplicates
				if not links.has(innov_id):
					var new_link = Link.new(innov_id,
											Utils.gauss(Params.w_range),
											false,
											from_neuron_id,
											to_neuron_id)
					# add the new link to the genome
					links[innov_id] = new_link
					links_added += 1
		# increase genome counter, create a new genome
		curr_genome_id += 1
		var new_genome = Genome.new(curr_genome_id,
									neurons,
									links, 0, 0)
		# try to find a species to which the new genome is similar. If no existing
		# species is compatible with the genome, a new species is made and returned
		var found_species = find_species(new_genome)
		found_species.add_member(new_genome)
		

		
#		spawn_points.pop_back()
		curr_agents.append(new_genome.generate_agent(spawn_points.pop_back()))
		initial_genomes.append(new_genome)
	# --- end of for loop that creates all genomes.
	# pick random genome and species of first gen, to allow for comparison
	all_time_best = Utils.random_choice(initial_genomes)
	best_species = Utils.random_choice(curr_species)
	# let ui know that it should update the species list
	emit_signal("made_new_gen")
	# return all new genomes 
	return initial_genomes


func evaluate_generation() -> void:
	"""Must get called once before making a new generation. Kills all agents, updates the
	fitness of every genome, and assigns genomes to a species (or creates new ones).
	"""
	# assign the fitness stored in the agent to the genome, then clear the agent array
	finish_current_agents()
	# Get updated list of species that survived into the next generation, and update
	# their spawn amounts based on fitness. Also updates the curr_best, all_time_best
	# and best_species based on the fitness of the last generation.
	curr_species = update_curr_species()
	# print some info about the last generation
	if Params.print_new_generation:
		print_status()
	generation_evaluated = true

func get_agent_by_genome_id(genome_id: int) -> Agent:
	for agent in curr_agents:
		if agent.agent_genome_id == genome_id:
			if agent.body:
				return agent
			else:
				print("Bodiless parent... :(")
	for genome in all_genomes:
		if genome.id == genome_id:
			if genome.agent.body:
				return genome.agent
			else:
				print("Bodiless parent... :(")
				
#	print("Failed to find: ", genome_id)
	return null




func next_generation() -> void:
	"""Goes through every species, and tries to spawn their new members (=genomes)
	either through crossover or asexual reproduction, until the max population size
	is reached. The new genomes then generate an agent, which will handle the
	interactions between the entity that lives in the simulated world, and the
	neural network that is coded for by the genome.
	"""
	if not generation_evaluated:
		push_error("evaluate_generation() must be called before making a new generation")
		breakpoint
	# keep track of new species, increment generation counter
	num_new_species = 0
	curr_generation += 1
	# the array containing all new genomes that will be spawned
	var new_genomes = []
	# keep track of spawned genomes, to not exceed population size
	var num_spawned = 0
	
	var alive_rn = alive.size()
#	print("ALIVE_RN: ", alive_rn)
	for species in curr_species:
#		print("NUM TO SPAWN: ", species.num_to_spawn)
		# reduce num_to_spawn if it would exceed population size
		if (num_spawned + alive_rn) == Params.population_size:
			break
		elif (num_spawned + species.num_to_spawn + alive_rn) > Params.population_size:
			species.num_to_spawn = Params.population_size - (num_spawned + alive_rn)
#			print("NEW NUM TO SPAWN: ", species.num_to_spawn, " ||||||| (num spawned: ", num_spawned, ")")
		# Elitism: best member of each species gets copied w.o. mutation
		var spawned_elite = false
		# spawn all the new members of a species
		var type = "none"
		for spawn in species.num_to_spawn:
			var baby: Genome
			# first clone the species leader for elitism
			if not spawned_elite:
				baby = species.elite_spawn(curr_genome_id)
				spawned_elite = true
				type = "elite"
			# if less than 2 members in spec., crossover cannot be performed
			# there is also prob_asex, which might result in an asex baby
			elif species.pool.size() < 2 or Utils.random_f() < Params.prob_asex:
				baby = species.asex_spawn(curr_genome_id)
				type = "asex"
			# produce a crossed-over genome
			else:
				baby = species.mate_spawn(curr_genome_id)
				type = "mate"
			# check if baby should speciate away from it's current species
			if baby.get_compatibility_score(species.representative) > Params.species_boundary:
				# if the baby is too different, find an existing species to change
				# into. If no compatible species is found, a new one is made and returned
				var found_species = find_species(baby)
				found_species.add_member(baby)
			else:
				# If the baby is still within the species of it's parents, add it as member
				species.add_member(baby)
			curr_genome_id += 1
			num_spawned += 1
			
			
			# lastly generate an agent for the baby and append it to curr_agents
			# Find a parent's position and store it in a variable, e.g., parent_position.
			# Get the parent's position
			var parent1 = get_agent_by_genome_id(baby.parent1_id)
			var parent2 = get_agent_by_genome_id(baby.parent2_id)

			# Choose one of the parents' positions randomly
			var parent_position
			if (str(parent1.body) != "[Deleted Object]") and (str(parent2.body) != "[Deleted Object]"):
				var test = str(parent2.body)
				if not "Booger" in test:
					print(test)
				parent_position = parent1.body.position if Utils.random_f() < 0.5 else parent2.body.position				
			elif str(parent1.body) != "[Deleted Object]":
				parent_position = parent1.body.position
			elif str(parent2.body) != "[Deleted Object]":
				parent_position = parent2.body.position
			else:
#				print("FAILED TO FIND PARENT!")
				print(type)
				parent_position = Vector2(-2000,-2000)
#				print(type)
			# Update the generate_agent() call
			curr_agents.append(baby.generate_agent(parent_position))
			new_genomes.append(baby)
	# if all the current species didn't provide enough offspring, get some more
	if Params.population_size - (num_spawned+alive_rn) > 0:
#		print("NOT ENOUGH!")
		new_genomes += make_hybrids(Params.population_size - (num_spawned+alive_rn))
		
		
	#	Save to all_genomes and removed duplicates:
	if all_genomes.empty():  # Check if all_genomes is empty
		all_genomes = curr_genomes
	else:
		all_genomes += curr_genomes
#		print("MORE THANT 300!")
#		maybe comment this out?
		all_genomes = Utils.sort_and_remove_duplicates(all_genomes)
#		print("TOTAL GENOMES: ", str(len(all_genomes)))
	
	# update curr_genomes alias
	curr_genomes = new_genomes
	all_agents_dead = false
	# let ui know that it should update the species list
	emit_signal("made_new_gen")
	# reset is_first_timestep so it is true for the first call to next_timestep()
	is_first_timestep = true
	if all_species.empty():
		all_species = curr_species
	else:
		for species in curr_species:
			if not (species in all_species):
				all_species.append(species)
	generation_evaluated = false


func find_species(new_genome: Genome) -> Species:
	"""Tries to find a species to which the given genome is similar enough to be
	added as a member. If no compatible species is found, a new one is made. Returns
	the species (but the genome still needs to be added as a member).
	"""
	var found_species: Species
	# try to find an existing species to which the genome is close enough to be a member
	var comp_score = Params.species_boundary
	for species in curr_species:
		if new_genome.get_compatibility_score(species.representative) < comp_score:
			comp_score = new_genome.get_compatibility_score(species.representative)
			found_species = species
	# new genome matches no current species -> make a new one
	if typeof(found_species) == TYPE_NIL:
		found_species = make_new_species(new_genome)
	# return the species, whether it is new or not
	return found_species


func make_new_species(founding_member: Genome) -> Species:
	"""Generates a new species with a unique id, assigns the founding member as
	representative, and adds the new species to curr_species and returns it.
	"""
	var new_species_id = str(curr_generation) + "_" + str(founding_member.id)
	var new_species = Species.new(new_species_id)
	new_species.representative = founding_member
	curr_species.append(new_species)
	num_new_species += 1
	return new_species


func next_timestep() -> void:
	"""Loops through the curr_agents array, removes dead ones from active processing,
	and calls the agent.process_inputs() method. process_inputs() takes the sensory
	information obtained by agent.body.sense(), feeds it into the neural net and
	calls the agent.body.act() method with the networks outputs.
	"""
	# Because agent.bodies are not in the tree when next_generation() finishes,
	# their visibility can be changed only after they are all in the scene
	if is_first_timestep:
		update_visibility(curr_visibility)
		is_first_timestep = false
	# loop through agents array and remove dead agents from active processing
	# by replacing the curr_agents array.
	var new_agents = []
	for agent in curr_agents:
		if not agent.is_dead:
			agent.process_inputs()
			new_agents.append(agent)
#			agent.body.get_node("Sprite").modulate = Color(randf(), randf(), randf(), 1.0)

	# replace curr_agents with all agents that are alive, therefore removing dead ones
	curr_agents = new_agents
	if curr_agents.empty():
		all_agents_dead = true


func finish_current_agents() -> void:
	"""Kills any agents that are still alive, assigns the fitness of the agent.body
	to the genome, and clears the curr_agents array to make way for a new generation.
	"""
	alive = []
	var deads = 0
	for genome in curr_genomes:
		var agent = genome.agent
		# if the generation is terminated before all agents are dead
		if not agent.is_dead:
			agent.fitness = agent.body.get_fitness()
			agent.body.food_score *= 0.3
#			agent.fitness
			agent.body.hunger_multiplier += 0.5
			alive.append(agent)
			genome.fitness = agent.fitness
		else:
#			agent.body.emit_signal("death")
			deads += 1
			genome.fitness = agent.fitness
			agent.body.queue_free()
#	print("DEADS: ", deads)
			
#			

	# clear the agents array
	curr_agents.clear()
	curr_agents = alive


func update_curr_species() -> Array:
	"""Determines which species will get to reproduce in the next generation.
	Calls the Species.update() method, which determines the species fitness as a
	group and removes all its members to make way for a new generation. Then loops
	over all species and updates the amount of offspring they will spawn the next
	generation.
	"""
	num_dead_species = 0
	# find the fittest genome from the last gen. Start with a random genome to allow comparison
	curr_best = Utils.random_choice(curr_genomes)
	# sum the average fitnesses of every species, and sum the average unadjusted fitness
	var total_adjusted_species_avg_fitness = 0
	var total_species_avg_fitness = 0
	# this array holds the updated species
	var updated_species = []
	for species in curr_species:
		# first update the species, this will check if the species gets to survive
		# into the next generation, update the species leader, calculate the average fitness
		# and calculate how many spawns the species gets to have in the next generation
		species.update()
		# check if the species gets to survive
#		print("CHECKING FOR OBLITERATE:")
		if not species.obliterate:
#			print("ALIVE!! ----------------------------------------------")
			updated_species.append(species)
			# collect the average fitness, and the adjusted average fitness
			total_species_avg_fitness += species.avg_fitness
			total_adjusted_species_avg_fitness += species.avg_fitness_adjusted
#			print("new total: ", total_adjusted_species_avg_fitness)
			# update curr_best genome and possibly all_time_best genome
			if species.leader.fitness > curr_best.fitness:
				if species.leader.fitness > all_time_best.fitness:
					all_time_best = species.leader
				curr_best = species.leader
		# remove dead species
		else:
			num_dead_species += 1
			species.purge()
	# update avg population fitness of the previous generation
	avg_population_fitness = total_species_avg_fitness / curr_species.size()
	# this should not normally happen. Consider different parameters and starting a new run
	
	if updated_species.size() == 0 or total_adjusted_species_avg_fitness == 0:
		push_error("mass extinction"); breakpoint

	# loop through the species again to calculate their spawn amounts based on their
	# fitness relative to the total_adjusted_species_avg_fitness
	for species in updated_species:
		species.calculate_offspring_amount(total_adjusted_species_avg_fitness, alive.size())
	# order the updated species by fitness, select the current best species, return
	updated_species.sort_custom(self, "sort_by_spec_fitness")
	best_species = updated_species.front()
	return updated_species


func make_hybrids(num_to_spawn: int) -> Array:
	"""Go through every species num_to_spawn times, pick it's leader, and mate it
	with a species leader from another species.
	"""
	var hybrids = []
	var species_index = 0
	while not hybrids.size() == num_to_spawn:
		# ignore newly added species
#		print(curr_species.size())
		if curr_species[species_index].age != 0 and curr_species[species_index+1]:
			var mom = curr_species[species_index].leader
#			print("!------!")
			if !mom.agent.body:
#				print("new mom")
				mom = curr_species[species_index].new_leader()
				
			var dad = curr_species[species_index + 1].leader
			if !dad.agent.body:
				dad = curr_species[species_index + 1].new_leader()
		
			var baby = mom.crossover(dad, curr_genome_id)
			curr_genome_id += 1
			# determine which species the new hybrid belongs to
			var mom_score =  baby.get_compatibility_score(mom)
			var dad_score =  baby.get_compatibility_score(dad)
			# find or make a new species if the baby matches none of the parents
			if mom_score > Params.species_boundary and dad_score > Params.species_boundary:
				var found_species = find_species(baby)
				found_species.add_member(baby)
			# baby has a score closer to mom than to dad
			elif mom_score < dad_score:
				curr_species[species_index].add_member(baby)
			# baby has a score closer to dad
			else:
				curr_species[species_index + 1].add_member(baby)
			# make an agent for the baby, and append it to the curr_agents array
#			print("SPAWNING AT: ", mom.agent.body.global_position)
			curr_agents.append(baby.generate_agent(mom.agent.body.position))
			hybrids.append(baby)
		# go to next species
		species_index += 1 
		# if we went through every species, but still have spawns, go again
		if species_index == curr_species.size() - 2:
			species_index = 0
	return hybrids


func sort_by_spec_fitness(species1: Species, species2: Species) -> bool:
	"""Used for sort_custom(). Sorts species in descending order.
	"""
	return species1.avg_fitness > species2.avg_fitness


func get_curr_bodies() -> Array:
	"""Returns the body of every agent in the current generation. Useful when
	something needs to be done with the bodies in external code.
	"""
	var curr_bodies = []
	for agent in curr_agents:
		curr_bodies.append(agent.body)
	return curr_bodies


func print_status() -> void:
	"""Prints some basic information about the current progress of evolution.
	"""
	var print_str = """\n Last generation performance:
	\n generation number: {gen_id} \n number new species: {new_s}
	\n number dead species: {dead_s} \n total number of species: {tot_s}
	\n avg. fitness: {avg_fit} \n best fitness: {best} \n """
	var print_vars = {"gen_id" : curr_generation, "new_s" : num_new_species,
					  "dead_s" : num_dead_species, "tot_s" : curr_species.size(),
					  "avg_fit" : avg_population_fitness, "best" : curr_best.fitness}
	print(print_str.format(print_vars))
	
	
#	print("NODE TREE: -----------------")
	_print_node_tree_recursive(get_tree().get_root().get_node("CarMain/Track/Start"), 0)
#	_print_node_tree_recursive(get_tree().get_root().get_node("CarMain/Track/Start"), 1)
#	print("DONE")
	
var total = 0
func _print_node_tree_recursive(node: Node, target_level: int = 0, current_level: int = 0):
	if current_level == target_level:
		# Print the current node's name and the ratio of dead immediate children to alive immediate children
		var dead_children = get_dead_children_count(node)
		var alive_children = get_alive_children_count(node)
		var total_new = alive_children+dead_children
		print(node.name + " [" + str(dead_children) + " dead / " + str(alive_children) + " alive]" + " TOTAL: " + str(alive_children+dead_children) + "|| [" + str(total_new-total) + "]")
		total = total_new
		
	# Recurse through the child nodes
	for child in node.get_children():
		_print_node_tree_recursive(child, target_level, current_level + 1)

# Function to get the total number of dead (not visible) immediate children for a node
func get_dead_children_count(node: Node) -> int:
	var count = 0

	for child in node.get_children():
		# Increment the count if the child node is not visible (dead)
		if child.dead:
			count += 1

	return count

# Function to get the total number of alive (visible) immediate children for a node
func get_alive_children_count(node: Node) -> int:
	var count = 0

	for child in node.get_children():
		# Increment the count if the child node is visible (alive)
		if not child.dead:
			count += 1

	return count



func update_visibility(index: int) -> void:
	"""calls the hide() or show() methods on either all bodies, or just leader bodies.
	"""
	# if this func was called by the species list, change curr_visibility
	curr_visibility = index
	# configure visibilities
	match Params.visibility_options[index]:
		"Show all":
			get_tree().call_group("all_bodies", "show")
		"Show Leaders":
			get_tree().call_group("all_bodies", "hide")
			get_tree().call_group("leader_bodies", "show")
		"Show none":
			get_tree().call_group("all_bodies", "hide")


func call_get_safe_spawn_points(amount, distance):
	var Food_Spawner_node = Global.track_instance.get_node("Food_Spawner")
	var spawn_points = Food_Spawner_node.get_safe_spawn_points(amount, distance)
	Global.track_instance.queue_free()
	return spawn_points

