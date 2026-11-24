## Pomocník pro interakce: objekty ve skupině "interactable" mají metody
## can_interact(player) -> bool, interact(player) a get_prompt() -> String (překladový klíč).
class_name Interact
extends RefCounted

const RANGE: float = 2.0


static func nearest(p: Player) -> Node:
	if p == null or not p.is_inside_tree():
		return null
	var best: Node = null
	var best_d: float = INF
	for n: Node in p.get_tree().get_nodes_in_group(&"interactable"):
		var n3: Node3D = n as Node3D
		if n3 == null:
			continue
		# Velké věci (dodávka) mají vlastní dosah `interact_range`.
		var reach: float = float(n.get("interact_range")) if n.get("interact_range") != null else RANGE
		var d: float = n3.global_position.distance_to(p.global_position)
		if d < reach and d < best_d and bool(n.call("can_interact", p)):
			best = n
			best_d = d
	return best
