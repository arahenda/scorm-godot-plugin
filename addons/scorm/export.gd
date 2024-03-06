extends EditorExportPlugin
class_name ScormExport
var _plugin_name = "<plugin_name>"
var final_file:String

func _export_begin(features, debug, path,flags):
	final_file = path


func _export_end():
	var final_path_array = final_file.split('/')
	var export_path = ""
	for i in range(final_path_array.size()-1):
		export_path += final_path_array[i]+"/"
	var files = DirAccess.open(export_path)
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
<resource identifier="resource_1" type="webcontent" adlcp:scormType="sco" href="'+final_path_array[final_path_array.size()-1]+'">'
	for file in files.get_files():
		string += '<file href="'+file+'"/>'
	string += '</resource>
		</resources>
		</manifest>'
	var manifest_file = FileAccess.open( export_path+"imsmanifest.xml", FileAccess.WRITE)
	manifest_file.store_string(string)
	manifest_file.close()
	
func _get_name():
		return _plugin_name
