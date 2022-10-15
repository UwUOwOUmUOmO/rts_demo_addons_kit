extends Node

class_name ProcessorsSwarm

func add_cluster(cluster_name := "", auto_commission := false, multithreaded := false) \
	-> ProcessorsCluster:
		var new_cluster := ProcessorsCluster.new(auto_commission)
		new_cluster.multithreading = multithreaded
		if not cluster_name.empty():
			new_cluster.name = cluster_name
		call_deferred("add_child", new_cluster)
		new_cluster.set_deferred("owner", self)
		return new_cluster

func fetch(cluster_name: String) -> ProcessorsCluster:
	return get_node_or_null(cluster_name) as ProcessorsCluster

func automated_fetch(cluster_name: String, auto_commission := false, multithreaded := false) \
	-> ProcessorsCluster:
		var re := fetch(cluster_name)
		if re == null:
			return add_cluster(cluster_name, auto_commission, multithreaded)
		return re

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
