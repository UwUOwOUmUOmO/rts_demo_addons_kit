extends Node

class_name ProcessorsSwarm

func add_cluster(cluster_name := "", auto_commission := false) -> ProcessorsCluster:
	var new_cluster := ProcessorsCluster.new(auto_commission)
	if not cluster_name.empty():
		new_cluster.name = cluster_name
	call_deferred("add_child", new_cluster)
	new_cluster.set_deferred("owner", self)
	return new_cluster

func fetch(cluster_name: String) -> ProcessorsCluster:
	return get_node_or_null(cluster_name) as ProcessorsCluster

func decommission(cluster_name: String) -> void:
	var cluster = get_node_or_null(cluster_name)
	if cluster == null:
		Out.print_error("Cluster not available for decommission: " \
			+ cluster_name, get_stack())
		return
	cluster.decommission()

func decommission_all() -> void:
	var childrens := get_children()
	for child in childrens:
		child.decommission()
