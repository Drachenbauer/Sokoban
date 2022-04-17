extends TileMap


onready var targets = $Targets
onready var box_path = preload("res://scenes/Box.tscn")
onready var player_path = preload("res://scenes/Player.tscn")
onready var options = $OptionPanel

var tile_size = get_cell_size()
var grid_size = Vector2(32, 24)
var target_grid = []
var grid = []
var level = 0

enum {WALL, TARGET, BOX, PLAYER}

# Called when the node enters the scene tree for the first time.
func _ready():
	level = G.level
	setup_grid()
	generate_walls()
	generate_targets()
	generate_boxes()
	generate_player()
	count_boxes_on_target()
	options.set_as_toplevel(true)


func _process(_delta):
	if Input.is_action_just_pressed("options"):
		options.visible = true
		get_tree().paused = true


func _on_OptionPanel_refresh():
	clear()
	generate_walls()
	generate_targets()
	var ground = get_parent().get_node("Ground")
	for cell in ground.get_used_cells():
		ground.set_cellv(cell, options.wall_type)


func setup_grid():
	for x in range(grid_size.x):
		target_grid.append([])
		grid.append([])
		for _y in range(grid_size.y):
			target_grid[x].append(null)
			grid[x].append(null)


func generate_walls():
	for y in range(G.MAPS[level - 1][options.wall_thickness].size() - 1):
		for x in range(G.MAPS[level - 1][options.wall_thickness][y].size() - 1):
			if G.MAPS[level - 1][options.wall_thickness][y][x] == 1:
				set_cell(x - 1, y - 1, options.wall_type)
				update_bitmask_area(Vector2(x - 1, y - 1))
	
	var wall_positions = get_used_cells()
	for wall_pos in wall_positions:
		if wall_pos.x < grid_size.x and wall_pos.y < grid_size.y:
			grid[wall_pos.x][wall_pos.y] = WALL


func generate_targets():
	for y in range(G.MAPS[level - 1][options.wall_thickness].size() - 1):
		for x in range(G.MAPS[level - 1][options.wall_thickness][y].size() - 1):
			if G.MAPS[level - 1][options.wall_thickness][y][x] == 2:
				targets.set_cell(x - 1, y - 1, options.wall_type)
	
	var target_positions = targets.get_used_cells()
	for target_pos in target_positions:
		if target_pos.x < grid_size.x and target_pos.y < grid_size.y:
			target_grid[target_pos.x][target_pos.y] = TARGET


func generate_boxes():
	for box_pos in G.BOX_POSITIONS[level - 1]:
		var box = box_path.instance()
		box.position = map_to_world(box_pos)
		add_child(box)
		G.boxes += 1
		grid[box_pos.x][box_pos.y] = BOX


func generate_player():
	var player_pos = G.PLAYER_POSITIONS[level - 1]
	var player = player_path.instance()
	player.position = map_to_world(player_pos)
	add_child(player)
	grid[player_pos.x][player_pos.y] = PLAYER

#called by player to know, if can move to the next cell
func is_valid_move(pos, direction):
	var own_pos = world_to_map(pos)
	var target_pos = own_pos + direction
	var behind_box_pos = target_pos + direction
	
	if target_pos.x < grid_size.x and target_pos.x >= 0:
		if target_pos.y < grid_size.y and target_pos.y >= 0:
			if grid[target_pos.x][target_pos.y] == WALL:
				return false
			elif grid[target_pos.x][target_pos.y] == BOX:
				return grid[behind_box_pos.x][behind_box_pos.y] == null
			else:
				return true
	return false

#called by the box to know, if the player is about to push it
func has_pusher(pos, direction):
	var own_pos = world_to_map(pos)
	var pusher_pos = own_pos - direction
	return grid[pusher_pos.x][pusher_pos.y] == PLAYER

#called by player to know, if pushing a box
func is_pushing(pos, direction):
	var own_pos = world_to_map(pos)
	var box_pos = own_pos + direction
	return grid[box_pos.x][box_pos.y] == BOX

#called by the box to know, if it´s placed on a target
func is_on_target(pos):
	var own_pos = world_to_map(pos)
	return target_grid[own_pos.x][own_pos.y] == TARGET

#called by the player at te end of a move to display nomber of boxes on target
func count_boxes_on_target():
	G.on_target = 0
	var boxes = get_tree().get_nodes_in_group("Boxes")
	for box in boxes:
		if box.is_on_target():
			G.on_target += 1

#called by player and box to set their new positions in the grid
func update_child_pos(child_node):
	var grid_pos = world_to_map(child_node.pos)
	var last_pos = grid_pos - child_node.direction
	
	grid[last_pos.x][last_pos.y] = null
	grid[grid_pos.x][grid_pos.y] = child_node.type

#called at undo move by player and box to set their last positions in the grid
func update_child_pos_undo(child_node):
	var grid_pos = world_to_map(child_node.pos)
	var last_pos = world_to_map(child_node.undo_pos)
	
	grid[last_pos.x][last_pos.y] = null
	grid[grid_pos.x][grid_pos.y] = child_node.type
