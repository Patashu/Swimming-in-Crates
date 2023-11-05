tool
extends TileSet

func _is_tile_bound(drawn_id, neighbor_id) -> bool:
	# non-walls bind to walls
	if neighbor_id == 0:
		return true;
	return false;
