extends Node2D

# Key to toggle the family tree window
const TOGGLE_KEY = KEY_T

# Sample creatures array

#onready var Main_Overseer = preload("res://demos/boogers/CarMain.tscn")

# Family tree nodes
var tree_nodes = {}
var orphan_nodes = {}

# UI elements
var panel

func _ready():
	# Initialize the panel
	panel = $CanvasLayer/Control/Panel
	panel.rect_min_size = Vector2(800, 600)
	panel.rect_pivot_offset = panel.rect_min_size / 2
	panel.visible = false

func generate_family_tree(creatures):
	#	Grabbing all current genomes:
	
	# Create nodes for all creatures
	for creature in creatures:
		var node = Node2D.new()
		node.name = "Creature_" + str(creature.id)
		node.position = Vector2(0, 0)
		add_child(node)

		if creature.parent_id1 == 0 and creature.parent_id2 == 0:
			orphan_nodes[creature.id] = node
		else:
			tree_nodes[creature.id] = node

	# Arrange nodes in the family tree
	for creature in creatures:
		var node = tree_nodes[creature.id]

		if creature.parent_id1 != 0 and creature.parent_id2 != 0:
			if creature.parent_id1 == creature.parent_id2:
				node.position.x = (tree_nodes[creature.parent_id1].position.x + tree_nodes[creature.parent_id2].position.x) / 2
				node.position.y = max(tree_nodes[creature.parent_id1].position.y, tree_nodes[creature.parent_id2].position.y) + 100
			else:
				node.position.x = (tree_nodes[creature.parent_id1].position.x + tree_nodes[creature.parent_id2].position.x) / 2
				node.position.y = max(tree_nodes[creature.parent_id1].position.y, tree_nodes[creature.parent_id2].position.y) + 150
		elif creature.parent_id1 != 0:
			node.position.x = tree_nodes[creature.parent_id1].position.x
			node.position.y = tree_nodes[creature.parent_id1].position.y + 150
		elif creature.parent_id2 != 0:
			node.position.x = tree_nodes[creature.parent_id2].position.x
			node.position.y = tree_nodes[creature.parent_id2].position.y + 150

	# Arrange orphan nodes
	var x_offset = 50
	for node in orphan_nodes.values():
		node.position.x = x_offset
		node.position.y = 50
		x_offset += 100

func cycle(creatures):
	$CanvasLayer/Control/Panel.visible = !$CanvasLayer/Control/Panel.visible
	if $CanvasLayer/Control/Panel.visible == true:
		generate_family_tree(creatures)
				
