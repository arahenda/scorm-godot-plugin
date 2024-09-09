@tool
extends EditorPlugin

const AUTOLOAD_NAME = "Scorm"

const EXPORT_PLUGIN_SCRIPT := preload("res://addons/scorm/scorm_export.gd")

var _export_plugin = null

func _enter_tree():
	# Initialization of the plugin goes here.
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/scorm/scorm.gd")
	_export_plugin = EXPORT_PLUGIN_SCRIPT.new()
	add_export_plugin(_export_plugin)


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_autoload_singleton(AUTOLOAD_NAME)
	remove_export_plugin(_export_plugin)
	_export_plugin = null
