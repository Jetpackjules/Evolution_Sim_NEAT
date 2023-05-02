extends Panel

class TreeGraphNode:
	var id
	var position
	var connections = []
	var generation
	var father_id = null


var added_elements = []


#var family_treeinput = [
#	{"id": 1, "parent1_id": null, "parent2_id": null},
#	{"id": 2, "parent1_id": null, "parent2_id": null},
#	{"id": 3, "parent1_id": 1, "parent2_id": 2},
#	{"id": 4, "parent1_id": 1, "parent2_id": 2},
#	{"id": 5, "parent1_id": 1, "parent2_id": 2},
#	{"id": 6, "parent1_id": 3, "parent2_id": 4},
#	{"id": 7, "parent1_id": 3, "parent2_id": 4},
#	{"id": 8, "parent1_id": 3, "parent2_id": 4},
#	{"id": 9, "parent1_id": 5, "parent2_id": null},
#	{"id": 10, "parent1_id": 5, "parent2_id": null},
#	{"id": 11, "parent1_id": 5, "parent2_id": null},
#	{"id": 12, "parent1_id": 6, "parent2_id": 7},
#	{"id": 13, "parent1_id": 6, "parent2_id": 7},
#	{"id": 14, "parent1_id": 6, "parent2_id": 7},
#	{"id": 15, "parent1_id": 8, "parent2_id": null},
#	{"id": 16, "parent1_id": 8, "parent2_id": null},
#	{"id": 17, "parent1_id": 8, "parent2_id": null},
#	{"id": 18, "parent1_id": 9, "parent2_id": null},
#	{"id": 19, "parent1_id": 9, "parent2_id": null},
#	{"id": 20, "parent1_id": 10, "parent2_id": null},
#	{"id": 21, "parent1_id": 10, "parent2_id": null},
#	{"id": 22, "parent1_id": 11, "parent2_id": null},
#	{"id": 23, "parent1_id": 12, "parent2_id": 13},
#	{"id": 24, "parent1_id": 12, "parent2_id": 13},
#	{"id": 25, "parent1_id": 14, "parent2_id": 15},
#	{"id": 26, "parent1_id": 14, "parent2_id": 15},
#	{"id": 27, "parent1_id": 16, "parent2_id": null},
#	{"id": 28, "parent1_id": 17, "parent2_id": null},
#	{"id": 29, "parent1_id": 18, "parent2_id": 19},
#	{"id": 30, "parent1_id": 20, "parent2_id": 21}
#]
class Creature:
	var id
	var parent1_id
	var parent2_id

	func _init(_id, parent1_id2, parent2_id2):
		id = _id
		parent1_id = parent1_id2
		parent2_id = parent2_id2


var family_treeinput = [
	Creature.new(1, null, null),
	Creature.new(2, null, null),
]

func clear_elements():
	for element in added_elements:
		element.queue_free()
	added_elements.clear()


func draw_family_tree(family_tree):
	clear_elements()
	var nodes = {}
	var generations = {}

	# Step 1: Create all nodes first
	for person in family_tree:
		var new_node = TreeGraphNode.new()
		new_node.id = person["id"]
		nodes[person["id"]] = new_node

	# Step 2: Set up connections and other properties
	for person in family_tree:
		var node = nodes[person["id"]]

		var gen = 0
		if (person["parent1_id"] != null) and (person["parent1_id"] !=  0):
			var old_gen = nodes[person["parent1_id"]]
			if not old_gen.generation:
				old_gen.generation = 0
			gen = old_gen.generation + 1
		if ((person["parent2_id"] != null) and (person["parent2_id"] !=  0)):
			var old_gen = nodes[person["parent2_id"]]
			if not old_gen.generation:
				old_gen.generation = 0
			if nodes[person["parent2_id"]].generation + 1 > gen:
				gen = old_gen.generation + 1

		node.generation = gen

		if not generations.has(gen):
			generations[gen] = []

		generations[gen].append(node)

		if (person["parent1_id"] != null) and (person["parent1_id"] !=  0):
			node.connections.append(nodes[person["parent1_id"]])
			nodes[person["parent1_id"]].connections.append(node)
			nodes[person["parent1_id"]].father_id = person["parent2_id"]

	calculate_node_positions(nodes, generations)
	draw_nodes(nodes)
	draw_connections(nodes)

func calculate_node_positions(nodes, generations):
	var generation_offset = 300
	var sibling_offset = 150

	var tree_width = calculate_tree_width(generations, sibling_offset)
	
	for gen in generations:
		var siblings = generations[gen]
		var total_sibling_count = siblings.size()
		var x_start = (tree_width - total_sibling_count * sibling_offset) / 2
		for i in range(siblings.size()):
			var node = siblings[i]
			var x_pos = x_start + i * sibling_offset
			node.position = Vector2(x_pos, gen * generation_offset)


var highlighted_lines = []
func reset_line_colors():
	for line in highlighted_lines:
		line.default_color = Color(0, 0, 0, 0)
	highlighted_lines.clear()



static func sum_array(array):
	var sum = 0.0
	for element in array:
		 sum += element
	return sum


func calculate_tree_width(generations, sibling_offset):
	var max_width = 0
	for gen in generations:
		var siblings = generations[gen]
		var gen_width = 0
		for node in siblings:
			gen_width += max(1, len(node.connections)) * sibling_offset
		if gen_width > max_width:
			max_width = gen_width
	return max_width



func draw_nodes(nodes):

	var bottom_right_rect = Vector2(0, 0)
	var bottom_right_node = null
	for node in nodes.values():

		node.position += Vector2(0, 50)

		var rect = ColorRect.new()
		rect.rect_min_size = Vector2(50, 50)
		rect.color = Color(0.2, 0.5, 1)
		rect.rect_position = node.position
		add_child(rect)
		added_elements.append(rect)

		var label = Label.new()
		label.text = str(node.id)
		label.align = Label.ALIGN_CENTER
		label.valign = Label.VALIGN_CENTER
		label.rect_min_size = Vector2(50, 50)
		label.rect_position = node.position
		add_child(label)
		added_elements.append(label)


		# Inside the draw_nodes function, after creating the rect and label, add:
		rect.connect("mouse_entered", self, "_on_node_mouse_entered", [node])
		rect.connect("mouse_exited", self, "_on_node_mouse_exited", [node])
		label.connect("mouse_entered", self, "_on_node_mouse_entered", [node])
		label.connect("mouse_exited", self, "_on_node_mouse_exited", [node])


		# Check if this rectangle is the bottom-right most
		if rect.rect_position.x > bottom_right_rect.x:
			bottom_right_rect.x = rect.rect_position.x
		if rect.rect_position.y > bottom_right_rect.y:
			bottom_right_rect.y = rect.rect_position.y

		# Update the bottom-right most node
		if bottom_right_node == null or node.position.x > bottom_right_node.position.x and node.position.y > bottom_right_node.position.y:
			bottom_right_node = node

	# Add a small rectangle indicator at the bottom-right most node
	if bottom_right_node != null:
		var indicator = ColorRect.new()
		indicator.rect_min_size = Vector2(10, 10)
		indicator.color = Color(1, 0, 0)
		indicator.rect_position = bottom_right_node.position + Vector2(40, 40)  # Adjust the position based on the size of the node rectangle
		add_child(indicator)
		added_elements.append(indicator)

	# Print the coordinates of the bottom-right most rectangle
	if bottom_right_rect != null:
		var target_size = bottom_right_rect + Vector2(100, 100)
#		self.rect_position.x = target_size.x*2
		
#		target_size.x *= 2

#		get_parent().rect_min_size = target_size * 2
#		self.rect_min_size = target_size * 2
		
		get_parent().rect_min_size = bottom_right_rect + Vector2(100, 100)



		print("Bottom-right most rectangle coordinates: ", target_size)

func _on_node_mouse_entered(node):
	reset_line_colors()
	for connection in node.connections:
		var line = Line2D.new()
		line.width = 4
		line.default_color = Color(1, 0, 0)

		line.add_point(node.position + Vector2(25, 50 if connection.generation > node.generation else 0))

		line.add_point(connection.position + Vector2(25, 50 if connection.generation < node.generation else 0))

		add_child(line)
		highlighted_lines.append(line)

func _on_node_mouse_exited(node):
	reset_line_colors()

func draw_connections(nodes):
	
	for node in nodes.values():
		for connection in node.connections:
			if node.generation < connection.generation:
				var line = Line2D.new()
				line.width = 4
				line.default_color = Color(0, 0, 0)

				line.add_point(node.position + Vector2(25, 50))
				line.add_point(Vector2(node.position.x + 25, node.position.y + 50 + (connection.position.y - node.position.y) / 2))
				line.add_point(Vector2(connection.position.x + 25, node.position.y + 50 + (connection.position.y - node.position.y) / 2))
				line.add_point(connection.position + Vector2(25, 0))
				add_child(line)
				added_elements.append(line)

				if node.father_id != null:
					var label = Label.new()
					label.text = str(node.father_id)
					label.rect_min_size = Vector2(20, 20)
					label.rect_position = Vector2(node.position.x + 30, node.position.y + 15 + (connection.position.y - node.position.y) / 2 - 10)
					add_child(label)
					added_elements.append(label)
