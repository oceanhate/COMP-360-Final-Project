@tool
extends EditorPlugin


func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	pass


func _enter_tree() -> void:
	add_custom_type("TwoRadiiEggMesh", "PrimitiveMesh", load("res://addons/egg_generator/primitive_meshes/two_radii_egg.gd"), load("res://addons/egg_generator/icons/egg_icon.svg"))
	add_custom_type("CrackedMesh", "PrimitiveMesh", load("res://addons/egg_generator/primitive_meshes/cracked_mesh.gd"), load("res://addons/egg_generator/icons/cracked_egg_icon.svg"))


func _exit_tree() -> void:
	remove_custom_type("TwoRadiiEggMesh")
	remove_custom_type("CrackedMesh")
