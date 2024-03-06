@tool
extends EditorPlugin

var export_plugin:ScormExport


func _enter_tree():
	# Initialization of the plugin goes here.
	add_custom_type("ScormNode", "Node", preload("scorm_node.gd")
		, preload("scorm.svg"))
	export_plugin = ScormExport.new()
	add_export_plugin(export_plugin)


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_custom_type("ScormNode")
	remove_export_plugin(export_plugin)
	export_plugin = null

