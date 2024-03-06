@tool
extends EditorPlugin



func _enter_tree():
	# Initialization of the plugin goes here.
	add_custom_type("ScormNode", "Node", preload("scorm_node.gd")
		, preload("scorm.svg"))


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_custom_type("ScormNode")

func _export_end():
	var manifest_file = FileAccess.open( "imsmanifest.xml", FileAccess.WRITE)

	var files = DirAccess.open(".")
	print(files)
	var string = '<manifest xmlns="http://www.imsglobal.org/xsd/imscp_v1p1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:adlcp="http://www.adlnet.org/xsd/adlcp_v1p3" xmlns:adlseq="http://www.adlnet.org/xsd/adlseq_v1p3" xmlns:adlnav="http://www.adlnet.org/xsd/adlnav_v1p3" xmlns:imsss="http://www.imsglobal.org/xsd/imsss" identifier="godot_scorm" version="3" xsi:schemaLocation="http://www.imsglobal.org/xsd/imscp_v1p1 imscp_v1p1.xsd http://www.adlnet.org/xsd/adlcp_v1p3 adlcp_v1p3.xsd http://www.adlnet.org/xsd/adlseq_v1p3 adlseq_v1p3.xsd http://www.adlnet.org/xsd/adlnav_v1p3 adlnav_v1p3.xsd http://www.imsglobal.org/xsd/imsss imsss_v1p0.xsd">
<metadata>
<schema>ADL SCORM</schema>
<schemaversion>2004 4th Edition</schemaversion>
</metadata>
<organizations default="godot_scorm_test">
<organization identifier="godot_scorm_test" adlseq:objectivesGlobalToSystem="false">
<title>Godot SCORM Example</title>
<item identifier="item_1" identifierref="resource_1">
<title>Godot SCORM Example</title>
</item>
</organization>
</organizations>
<resources>
<resource identifier="resource_1" type="webcontent" adlcp:scormType="sco" href="index.html">'
	for file in files.get_files():
		string += '<file href="'+file+'"/>'
	string += '</resource>
		</resources>
		</manifest>'
	manifest_file.store_string(string)
	manifest_file.close()
	return true
