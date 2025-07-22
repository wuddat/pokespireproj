# map_path_tile_renderer_with_terrain.gd
class_name MapLineRenderer
extends Node2D

@export_group("TileSet Configuration")
@export var tileset_resource: TileSet
@export var tileset_texture: Texture2D
@export var tile_size: Vector2i = Vector2i(16, 16)
@export var create_tileset_automatically: bool = false

@export_group("Terrain Settings")
@export var use_terrain_system: bool = true
@export var terrain_set_index: int = 0
@export var path_terrain_index: int = 0
@export var terrain_paint_mode: TerrainPaintMode = TerrainPaintMode.PAINT_INDIVIDUAL

@export_group("Manual Atlas Coordinates (if not using terrain)")
@export var horizontal_tile: Vector2i = Vector2i(0, 0)
@export var vertical_tile: Vector2i = Vector2i(1, 0)
@export var corner_tl_tile: Vector2i = Vector2i(2, 0)
@export var corner_tr_tile: Vector2i = Vector2i(3, 0)
@export var corner_bl_tile: Vector2i = Vector2i(4, 0)
@export var corner_br_tile: Vector2i = Vector2i(5, 0)
@export var cross_tile: Vector2i = Vector2i(6, 0)
@export var end_point_tile: Vector2i = Vector2i(7, 0)
@export var straight_tile: Vector2i = Vector2i(8, 0)

@export_group("Path Drawing Settings")
@export var path_style: PathStyle = PathStyle.MANHATTAN_HORIZONTAL_FIRST
@export var allow_diagonals: bool = false

enum PathStyle {
	MANHATTAN_HORIZONTAL_FIRST,  # Move horizontal first, then vertical
	MANHATTAN_VERTICAL_FIRST,    # Move vertical first, then horizontal
	MANHATTAN_SHORTEST,          # Choose direction based on shortest distance
	MANHATTAN_ALTERNATING,       # Alternate between horizontal and vertical steps
	BRESENHAM_DIAGONAL          # Original diagonal-allowing algorithm
}

@export_group("Background Fill")
@export var fill_background: bool = true
@export var use_random_background_tiles: bool = true
@export var background_tile: Vector2i = Vector2i(0, 4)  # Fallback if not using random
@export var fill_area_size: Vector2i = Vector2i(100, 100)  # How large area to fill
@export var center_fill_on_paths: bool = true  # Center the fill area on the path bounds

@export_group("Random Background Tiles")
@export var background_tile_pool: Array[BackgroundTileEntry] = []

# Built-in class for weighted tile entries
class BackgroundTileEntry extends Resource:
	@export var tile_coords: Vector2i = Vector2i(6, 0)
	@export var weight: float = 1.0
	
	func _init(coords: Vector2i = Vector2i(6, 0), w: float = 1.0):
		tile_coords = coords
		weight = w

enum TerrainPaintMode {
	PAINT_INDIVIDUAL,    # Paint each cell individually
	PAINT_CONNECTED,     # Use terrain connect for automatic transitions
	PAINT_PATH          # Use terrain path for smooth lines
}

const TILESET_SOURCE_ID = 0

var tile_map_layer: TileMapLayer
var rendered_paths: Array[Vector2i] = []
var background_tiles: Array[Vector2i] = []
var path_atlas_coords: Dictionary
var random_generator: RandomNumberGenerator

func _ready() -> void:
	_update_atlas_coordinates()
	
	# Initialize random generator
	random_generator = RNG.instance
	
	# Setup default background tile pool if empty
	if background_tile_pool.is_empty():
		_setup_default_background_pool()
	
	if not tile_map_layer:
		tile_map_layer = TileMapLayer.new()
		add_child(tile_map_layer)
	
	if not tileset_resource and create_tileset_automatically:
		tileset_resource = _create_tileset_with_terrain()
	
	if tileset_resource:
		tile_map_layer.tile_set = tileset_resource

func _setup_default_background_pool() -> void:
	# Create the default weighted pool with your specified tiles
	var default_tiles = [
		{"coords": Vector2i(6, 0), "weight": 10.0},  # More common
		{"coords": Vector2i(6, 1), "weight": 10.0},
		{"coords": Vector2i(6, 2), "weight": 10.0},
		{"coords": Vector2i(7, 0), "weight": 5.0},
		{"coords": Vector2i(7, 1), "weight": 10.0},
		{"coords": Vector2i(7, 2), "weight": 2.0},
		{"coords": Vector2i(8, 0), "weight": 1.0}   # Less common
	]
	
	background_tile_pool.clear()
	for tile_data in default_tiles:
		var entry = BackgroundTileEntry.new()
		entry.tile_coords = tile_data.coords
		entry.weight = tile_data.weight
		background_tile_pool.append(entry)

func _get_random_background_tile() -> Vector2i:
	if not use_random_background_tiles or background_tile_pool.is_empty():
		return background_tile
	
	# Calculate total weight
	var total_weight = 0.0
	for entry in background_tile_pool:
		total_weight += entry.weight
	
	# Generate random number
	var random_value = random_generator.randf() * total_weight
	
	# Select tile based on weighted probability
	var current_weight = 0.0
	for entry in background_tile_pool:
		current_weight += entry.weight
		if random_value <= current_weight:
			return entry.tile_coords
	
	# Fallback to first tile (shouldn't happen)
	return background_tile_pool[0].tile_coords
func _update_atlas_coordinates() -> void:
	path_atlas_coords = {
		"horizontal": horizontal_tile,
		"vertical": vertical_tile,
		"corner_tl": corner_tl_tile,
		"corner_tr": corner_tr_tile,
		"corner_bl": corner_bl_tile,
		"corner_br": corner_br_tile,
		"cross": cross_tile,
		"end_point": end_point_tile,
		"straight": straight_tile
	}

func _create_tileset_with_terrain() -> TileSet:
	if not tileset_texture:
		push_error("No tileset texture assigned!")
		return null
	
	var tileset = TileSet.new()
	var atlas_source = TileSetAtlasSource.new()
	
	atlas_source.texture = tileset_texture
	atlas_source.texture_region_size = tile_size
	
	# Create basic tiles
	for y in range(10):
		for x in range(10):
			var atlas_coords = Vector2i(x, y)
			atlas_source.create_tile(atlas_coords)
	
	# Add terrain set if using terrain system
	if use_terrain_system:
		tileset.add_terrain_set()
		var terrain_set = tileset.get_terrain_set(terrain_set_index)
		
		# Add a terrain (you can add more terrains as needed)
		tileset.add_terrain(terrain_set_index)
		tileset.set_terrain_name(terrain_set_index, path_terrain_index, "Path")
		tileset.set_terrain_color(terrain_set_index, path_terrain_index, Color.BROWN)
		
		# Configure terrain peering bits for path tiles
		_setup_terrain_peering_bits(atlas_source)
	
	tileset.add_source(atlas_source, TILESET_SOURCE_ID)
	return tileset

func _setup_terrain_peering_bits(atlas_source: TileSetAtlasSource) -> void:
	# This is where you'd configure which tiles connect to which
	# Example for a horizontal path tile at (0,0):
	var horizontal_coords = horizontal_tile
	if atlas_source.has_tile(horizontal_coords):
		var tile_data = atlas_source.get_tile_data(horizontal_coords, 0)
		# Set terrain peering bits for horizontal connections
		tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE, path_terrain_index)
		tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE, path_terrain_index)
		tile_data.set_terrain(path_terrain_index)
	
	# Similar setup for other tile types...
	# This is quite complex and depends on your specific tileset layout

func render_map_paths_on_tilemap(map_data: Array[Array]) -> void:
	if not tile_map_layer or not tileset_resource:
		push_error("TileMapLayer or TileSet not properly configured!")
		return
	
	clear_rendered_paths()
	
	# Fill background first if enabled
	if fill_background:
		_fill_background_tiles(map_data)
	
	if use_terrain_system:
		_render_with_terrain_system(map_data)
	else:
		_render_with_manual_tiles(map_data)

func _render_with_terrain_system(map_data: Array[Array]) -> void:
	var path_positions = _get_all_path_positions(map_data)
	
	match terrain_paint_mode:
		TerrainPaintMode.PAINT_INDIVIDUAL:
			_paint_terrain_individual(path_positions)
		TerrainPaintMode.PAINT_CONNECTED:
			_paint_terrain_connected(path_positions)
		TerrainPaintMode.PAINT_PATH:
			_paint_terrain_paths(map_data)

func _paint_terrain_individual(path_positions: Array[Vector2i]) -> void:
	# Paint each position individually with the terrain
	for pos in path_positions:
		tile_map_layer.set_cell(pos, TILESET_SOURCE_ID, Vector2i(0, 0))
		# Set terrain for this cell
		var terrain_peering_bits = {}
		terrain_peering_bits[TileSet.CELL_NEIGHBOR_LEFT_SIDE] = path_terrain_index
		terrain_peering_bits[TileSet.CELL_NEIGHBOR_RIGHT_SIDE] = path_terrain_index
		terrain_peering_bits[TileSet.CELL_NEIGHBOR_TOP_SIDE] = path_terrain_index
		terrain_peering_bits[TileSet.CELL_NEIGHBOR_BOTTOM_SIDE] = path_terrain_index
		
		# Note: You'll need to use the proper terrain painting methods
		# tile_map_layer.set_cells_terrain_connect(...) for automatic connections
		rendered_paths.append(pos)

func _paint_terrain_connected(path_positions: Array[Vector2i]) -> void:
	# Use Godot's terrain connect system for automatic tile selection
	var cells_to_paint = []
	for pos in path_positions:
		cells_to_paint.append(pos)
	
	# This automatically selects the right tiles based on terrain rules
	tile_map_layer.set_cells_terrain_connect(cells_to_paint, terrain_set_index, path_terrain_index, false)
	rendered_paths.append_array(cells_to_paint)

func _paint_terrain_paths(map_data: Array[Array]) -> void:
	# Use terrain path painting for smooth lines
	for floor in map_data:
		for room in floor:
			for next_room in room.next_rooms:
				var start_tile = _world_to_tile(room.position)
				var end_tile = _world_to_tile(next_room.position)
				
				# Create a path between the two points
				var path_points = [start_tile, end_tile]
				tile_map_layer.set_cells_terrain_path(path_points, terrain_set_index, path_terrain_index, false)
				
				# Track for cleanup
				var line_positions = _get_line_tile_positions(room.position, next_room.position)
				rendered_paths.append_array(line_positions)

func _render_with_manual_tiles(map_data: Array[Array]) -> void:
	# Fallback to manual tile placement (original method)
	var path_grid = _create_path_grid_from_lines(map_data)
	
	for grid_pos in path_grid:
		var tile_type = _determine_tile_type_from_grid(path_grid, grid_pos)
		_place_tile_at_position(grid_pos, tile_type)

func _get_all_path_positions(map_data: Array[Array]) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	
	for floor in map_data:
		for room in floor:
			for next_room in room.next_rooms:
				var line_positions = _get_line_tile_positions(room.position, next_room.position)
				for pos in line_positions:
					if not positions.has(pos):
						positions.append(pos)
	
	return positions

func _create_path_grid_from_lines(map_data: Array[Array]) -> Dictionary:
	var path_positions = {}
	
	for floor in map_data:
		for room in floor:
			for next_room in room.next_rooms:
				var line_positions = _get_line_tile_positions(room.position, next_room.position)
				for pos in line_positions:
					path_positions[pos] = true
	
	return path_positions

func _get_line_tile_positions(start_world: Vector2, end_world: Vector2) -> Array[Vector2i]:
	var start_tile = _world_to_tile(start_world)
	var end_tile = _world_to_tile(end_world)
	
	match path_style:
		PathStyle.MANHATTAN_HORIZONTAL_FIRST:
			return _get_manhattan_path_horizontal_first(start_tile, end_tile)
		PathStyle.MANHATTAN_VERTICAL_FIRST:
			return _get_manhattan_path_vertical_first(start_tile, end_tile)
		PathStyle.MANHATTAN_SHORTEST:
			return _get_manhattan_path_shortest(start_tile, end_tile)
		PathStyle.MANHATTAN_ALTERNATING:
			return _get_manhattan_path_alternating(start_tile, end_tile)
		PathStyle.BRESENHAM_DIAGONAL:
			return _get_bresenham_path(start_tile, end_tile)
		_:
			return _get_manhattan_path_horizontal_first(start_tile, end_tile)

func _get_manhattan_path_horizontal_first(start_tile: Vector2i, end_tile: Vector2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	var current = start_tile
	
	# Move horizontally first
	while current.x != end_tile.x:
		positions.append(current)
		current.x += 1 if end_tile.x > current.x else -1
	
	# Then move vertically
	while current.y != end_tile.y:
		positions.append(current)
		current.y += 1 if end_tile.y > current.y else -1
	
	# Add the final position
	positions.append(end_tile)
	return positions

func _get_manhattan_path_vertical_first(start_tile: Vector2i, end_tile: Vector2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	var current = start_tile
	
	# Move vertically first
	while current.y != end_tile.y:
		positions.append(current)
		current.y += 1 if end_tile.y > current.y else -1
	
	# Then move horizontally
	while current.x != end_tile.x:
		positions.append(current)
		current.x += 1 if end_tile.x > current.x else -1
	
	# Add the final position
	positions.append(end_tile)
	return positions

func _get_manhattan_path_shortest(start_tile: Vector2i, end_tile: Vector2i) -> Array[Vector2i]:
	var dx = abs(end_tile.x - start_tile.x)
	var dy = abs(end_tile.y - start_tile.y)
	
	# Choose the direction that requires fewer steps first
	if dx >= dy:
		return _get_manhattan_path_horizontal_first(start_tile, end_tile)
	else:
		return _get_manhattan_path_vertical_first(start_tile, end_tile)

func _get_manhattan_path_alternating(start_tile: Vector2i, end_tile: Vector2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	var current = start_tile
	
	# Calculate total steps needed in each direction
	var steps_x = abs(end_tile.x - start_tile.x)
	var steps_y = abs(end_tile.y - start_tile.y)
	var dir_x = 1 if end_tile.x > start_tile.x else -1
	var dir_y = 1 if end_tile.y > start_tile.y else -1
	
	positions.append(current)
	
	# Alternate between horizontal and vertical movement
	var move_horizontal = true  # Start with horizontal movement
	
	while current != end_tile:
		var moved = false
		
		if move_horizontal and current.x != end_tile.x:
			# Move horizontally if we can
			current.x += dir_x
			moved = true
		elif not move_horizontal and current.y != end_tile.y:
			# Move vertically if we can
			current.y += dir_y
			moved = true
		elif current.x != end_tile.x:
			# If we can't move in preferred direction, move horizontally
			current.x += dir_x
			moved = true
		elif current.y != end_tile.y:
			# If we can't move horizontally, move vertically
			current.y += dir_y
			moved = true
		
		if moved:
			positions.append(current)
			move_horizontal = not move_horizontal  # Alternate direction
		else:
			break  # Safety break (shouldn't happen)
	
	return positions
	# Original Bresenham algorithm (allows diagonals)
	positions = []
	current = start_tile
	var target = end_tile
	var dx = abs(target.x - current.x)
	var dy = abs(target.y - current.y)
	var sx = 1 if current.x < target.x else -1
	var sy = 1 if current.y < target.y else -1
	var err = dx - dy
	
	while true:
		positions.append(current)
		if current == target:
			break
		
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			current.x += sx
		if e2 < dx:
			err += dx
			current.y += sy
	
	return positions

func _get_bresenham_path(start_tile: Vector2i, end_tile: Vector2i) -> Array[Vector2i]:
	# Original Bresenham algorithm (allows diagonals)
	var positions: Array[Vector2i] = []
	var current = start_tile
	var target = end_tile
	var dx = abs(target.x - current.x)
	var dy = abs(target.y - current.y)
	var sx = 1 if current.x < target.x else -1
	var sy = 1 if current.y < target.y else -1
	var err = dx - dy
	
	while true:
		positions.append(current)
		if current == target:
			break
		
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			current.x += sx
		if e2 < dx:
			err += dx
			current.y += sy
	
	return positions


func _determine_tile_type_from_grid(path_grid: Dictionary, pos: Vector2i) -> String:
	if not path_grid.has(pos):
		return ""
	
	var connections = {
		"up": path_grid.has(Vector2i(pos.x, pos.y - 1)),
		"down": path_grid.has(Vector2i(pos.x, pos.y + 1)),
		"left": path_grid.has(Vector2i(pos.x - 1, pos.y)),
		"right": path_grid.has(Vector2i(pos.x + 1, pos.y))
	}
	
	var connection_count = 0
	for direction in connections:
		if connections[direction]:
			connection_count += 1
	
	match connection_count:
		0, 1:
			return "end_point"
		2:
			if connections.up and connections.down:
				return "vertical"
			elif connections.left and connections.right:
				return "horizontal"
			elif connections.up and connections.right:
				return "corner_bl"
			elif connections.up and connections.left:
				return "corner_br"
			elif connections.down and connections.right:
				return "corner_tl"
			elif connections.down and connections.left:
				return "corner_tr"
			else:
				return "horizontal"
		3, 4:
			return "cross"
		_:
			return "straight"

func _place_tile_at_position(tile_pos: Vector2i, tile_type: String) -> void:
	if tile_type == "" or not path_atlas_coords.has(tile_type):
		return
	
	var atlas_coords = path_atlas_coords[tile_type]
	tile_map_layer.set_cell(tile_pos, TILESET_SOURCE_ID, atlas_coords)
	rendered_paths.append(tile_pos)

func _world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(round(world_pos.x / tile_size.x)),
		int(round(world_pos.y / tile_size.y))
	)

func clear_rendered_paths() -> void:
	for tile_pos in rendered_paths:
		tile_map_layer.erase_cell(tile_pos)
	rendered_paths.clear()
	
	# Also clear background tiles
	for tile_pos in background_tiles:
		tile_map_layer.erase_cell(tile_pos)
	background_tiles.clear()

func _fill_background_tiles(map_data: Array[Array]) -> void:
	var fill_bounds = _calculate_fill_bounds(map_data)
	
	# Fill the entire area with randomly selected background tiles
	for y in range(fill_bounds.position.y, fill_bounds.end.y):
		for x in range(fill_bounds.position.x, fill_bounds.end.x):
			var tile_pos = Vector2i(x, y)
			var selected_tile = _get_random_background_tile()
			tile_map_layer.set_cell(tile_pos, TILESET_SOURCE_ID, selected_tile)
			background_tiles.append(tile_pos)

func _calculate_fill_bounds(map_data: Array[Array]) -> Rect2i:
	if center_fill_on_paths:
		# Calculate bounds based on actual path positions
		var path_positions = _get_all_path_positions(map_data)
		
		if path_positions.is_empty():
			# Fallback to center of world if no paths
			var center = Vector2i(0, 0)
			return Rect2i(
				center - fill_area_size / 2,
				fill_area_size
			)
		
		# Find min/max bounds of all paths
		var min_x = path_positions[0].x
		var max_x = path_positions[0].x
		var min_y = path_positions[0].y
		var max_y = path_positions[0].y
		
		for pos in path_positions:
			min_x = min(min_x, pos.x)
			max_x = max(max_x, pos.x)
			min_y = min(min_y, pos.y)
			max_y = max(max_y, pos.y)
		
		# Add padding around the paths
		var padding = Vector2i(10, 10)  # Adjust as needed
		var bounds_min = Vector2i(min_x, min_y) - padding
		var bounds_max = Vector2i(max_x, max_y) + padding
		
		return Rect2i(bounds_min, bounds_max - bounds_min)
	else:
		# Use fixed area centered at origin
		return Rect2i(
			Vector2i(0, 0) - fill_area_size / 2,
			fill_area_size
		)

# Alternative method: Fill only specific areas
func fill_background_around_paths(padding: int = 5) -> void:
	var path_positions = {}
	for pos in rendered_paths:
		path_positions[pos] = true
	
	# Find all positions around paths that need background
	var background_positions = {}
	
	for path_pos in rendered_paths:
		# Check area around each path tile
		for y_offset in range(-padding, padding + 1):
			for x_offset in range(-padding, padding + 1):
				var check_pos = Vector2i(path_pos.x + x_offset, path_pos.y + y_offset)
				
				# If this position doesn't have a path tile, it needs background
				if not path_positions.has(check_pos):
					background_positions[check_pos] = true
	
	# Place background tiles
	for bg_pos in background_positions:
		tile_map_layer.set_cell(bg_pos, TILESET_SOURCE_ID, background_tile)
		background_tiles.append(bg_pos)

# Method to fill a specific rectangular area
func fill_background_area(top_left: Vector2i, size: Vector2i) -> void:
	for y in range(top_left.y, top_left.y + size.y):
		for x in range(top_left.x, top_left.x + size.x):
			var tile_pos = Vector2i(x, y)
			# Only fill if there's no existing tile
			if tile_map_layer.get_cell_source_id(tile_pos) == -1:
				tile_map_layer.set_cell(tile_pos, TILESET_SOURCE_ID, background_tile)
				background_tiles.append(tile_pos)

func refresh_tileset() -> void:
	_update_atlas_coordinates()
	if create_tileset_automatically:
		tileset_resource = _create_tileset_with_terrain()
		if tile_map_layer:
			tile_map_layer.tile_set = tileset_resource

# Additional background fill methods you can call manually:

# Fill background but preserve existing tiles
func fill_background_preserve_existing() -> void:
	var fill_bounds = _calculate_fill_bounds([])  # Pass empty if you want fixed area
	
	for y in range(fill_bounds.position.y, fill_bounds.end.y):
		for x in range(fill_bounds.position.x, fill_bounds.end.x):
			var tile_pos = Vector2i(x, y)
			# Only place background if no tile exists
			if tile_map_layer.get_cell_source_id(tile_pos) == -1:
				var selected_tile = _get_random_background_tile()
				tile_map_layer.set_cell(tile_pos, TILESET_SOURCE_ID, selected_tile)
				background_tiles.append(tile_pos)

# Fill only empty spaces in a given area
func fill_empty_tiles_in_area(area: Rect2i, use_random: bool = true) -> void:
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var tile_pos = Vector2i(x, y)
			if tile_map_layer.get_cell_source_id(tile_pos) == -1:
				var selected_tile = _get_random_background_tile() if use_random else background_tile
				tile_map_layer.set_cell(tile_pos, TILESET_SOURCE_ID, selected_tile)
				background_tiles.append(tile_pos)

# Clear only background tiles (keep paths)
func clear_background_only() -> void:
	for tile_pos in background_tiles:
		tile_map_layer.erase_cell(tile_pos)
	background_tiles.clear()

# Helper functions for managing the tile pool
func add_background_tile(coords: Vector2i, weight: float = 1.0) -> void:
	var entry = BackgroundTileEntry.new()
	entry.tile_coords = coords
	entry.weight = weight
	background_tile_pool.append(entry)

func set_background_tile_weight(coords: Vector2i, new_weight: float) -> void:
	for entry in background_tile_pool:
		if entry.tile_coords == coords:
			entry.weight = new_weight
			break

func remove_background_tile(coords: Vector2i) -> void:
	for i in range(background_tile_pool.size() - 1, -1, -1):
		if background_tile_pool[i].tile_coords == coords:
			background_tile_pool.remove_at(i)
			break

# Set a new random seed for consistent generation
func set_random_seed(seed_value: int) -> void:
	random_generator.seed = seed_value

# Get current tile pool info for debugging
func get_tile_pool_info() -> String:
	var info = "Background Tile Pool:\n"
	var total_weight = 0.0
	
	for entry in background_tile_pool:
		total_weight += entry.weight
	
	for entry in background_tile_pool:
		var percentage = (entry.weight / total_weight) * 100.0
		info += "(%d,%d) - Weight: %.1f (%.1f%%)\n" % [entry.tile_coords.x, entry.tile_coords.y, entry.weight, percentage]
	
	return info
