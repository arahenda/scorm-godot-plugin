extends EditorExportPlugin

# Generates a .zip archive from the exported files. Ignore existent .zip in the folder.
@export var auto_zip := true # Please, reset the Edito after changing this value.
@export var default_zip_filename := "scorm.zip"

const MANIFEST_FILENAME := "imsmanifest.xml"
const SCORMJS_FILENAME := "scorm.js"

var final_file_path: String
var export_dir_path: String

var _plugin_name: String


func _get_name() -> String:
	return _plugin_name	# Needed by the engine it seems.


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	final_file_path = path
	export_dir_path = final_file_path.get_base_dir()


func _export_end() -> void:
	print(_pmsg("Initializing..."))
	assert(final_file_path.contains(".html"), "Error! The 'Scorm' plugin expects an html output file. Are you exporting for the Web?")
	# Copy some essential files to the export directory.
	DirAccess.copy_absolute("res://addons/scorm/%s" % SCORMJS_FILENAME, "%s/%s" % [export_dir_path, SCORMJS_FILENAME])
	DirAccess.copy_absolute("res://addons/scorm/assets/%s" % MANIFEST_FILENAME, "%s/%s" % [export_dir_path, MANIFEST_FILENAME])
	_patch_final_file()
	_create_manifest_file()
	if(auto_zip): _write_zip_file()


func _create_manifest_file() -> void:
	"""Generates the manifest file."""
	const tag_res_file := "$FINAL_FILE"
	const tag_file_stub := "$FILE_LINKS"

	var manifest_path := "%s/%s" % [export_dir_path, MANIFEST_FILENAME]

	var files := DirAccess.open(export_dir_path)

	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	var manifest_text: String = manifest_file.get_as_text()

	# Updates the <resource> with the exported main file's path.
	manifest_text = manifest_text.replace(tag_res_file, final_file_path.get_file())

	# Adds the exported files references as <file> tags inside the <resource>.
	var file_links := ""
	for file in files.get_files():
		if !_ignore_file(file):
			file_links += "<file href=\"%s\"/>\n\t\t\t" % file

	manifest_text = manifest_text.replace(tag_file_stub, file_links)

	manifest_file.close()
	manifest_file = FileAccess.open(manifest_path, FileAccess.WRITE)
	manifest_file.store_string(manifest_text)
	manifest_file.close()
	print(_pmsg("File '%s' created." % MANIFEST_FILENAME))


func _patch_final_file() -> void:
	"""Patches the 'final_file' with the necessary tags."""
	const tag_head_close := "</head>"	# TODO: Make the match process more robust (regex).
	const tag_head_tmpl := "<script src=\"%s\"></script>\n    </head>"
	const tag_body_open := "<body>"
	const tag_body_tmpl := "<body onload=\"doStart(false);\" onbeforeunload=\"doUnload(false);\" onunload=\"doUnload();\">"

	var html_file := FileAccess.open(final_file_path, FileAccess.READ)
	var html_text: String = html_file.get_as_text()

	html_text = html_text.replace(tag_head_close, tag_head_tmpl % [SCORMJS_FILENAME])

	html_text = html_text.replace(tag_body_open, tag_body_tmpl)

	html_file.close()
	html_file = FileAccess.open(final_file_path, FileAccess.WRITE)
	html_file.store_string(html_text)
	html_file.close()
	print(_pmsg("File '%s' patched." % final_file_path.get_file()))


func _write_zip_file(dest_path: String = export_dir_path, zip_filename: String = default_zip_filename) -> void:
	"""Searches all files in the 'dest_path' and add then into the 'zip_filename' archive."""
	print(_pmsg("Preparing to Zip exported files... Others .zip files will be ignored."))
	var writer := ZIPPacker.new()
	var err := writer.open("%s/%s" % [dest_path, zip_filename])
	assert(err == OK, _pmsg("An error occurred when trying to open the path '%s/%s'." % [dest_path, zip_filename]))

	var dir = DirAccess.open(dest_path)
	assert(dir, _pmsg("An error occurred when trying to access the path '%s'." % dest_path))

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir():
			#print("Found file: " + file_name)
			if !_ignore_file(file_name):
				#print("> Writing file: " + file_name)
				var file = FileAccess.open("%s/%s" % [dir.get_current_dir(), file_name], FileAccess.READ)
				writer.start_file(file_name)
				writer.write_file(file.get_buffer(file.get_length()))
				writer.close_file()
				file.close()
		file_name = dir.get_next()

	writer.close()
	print(_pmsg("File '%s' created." % zip_filename))


func _ignore_file(file_name: String) -> bool:
	"""Exported files to be ignored."""
	return file_name.contains(".zip") || file_name.contains(".import")


# Misc
func _pmsg(msg: String) -> String:
	return "Plugin(Scorm): %s" % msg
