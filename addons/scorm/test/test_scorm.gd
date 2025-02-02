extends Control

@export var auto_update: bool

@onready var score_input := $Container/ScoreLine/Score
@onready var score_value := $Container/ScoreLine/ScoreValue
@onready var session_time_input := $Container/SessionTimeLine/SessionTime
@onready var session_time_value := $Container/SessionTimeLine/SessionTimeValue
@onready var success_status_input := $Container/SuccessStatusLine/SuccessStatusOptionButton
@onready var success_status_value := $Container/SuccessStatusLine/SuccessStatusValue
@onready var lesson_status_value := $Container/CompletionStatusLine/CompletionStatusValue
@onready var custom_prop_attr := $Container/CustomPropLine/LeftContainer/HBoxContainer/CustomPropAttr
@onready var custom_prop_input := $Container/CustomPropLine/LeftContainer/HBoxContainer2/CustomPropInput
@onready var custom_prop_value := $Container/CustomPropLine/CustomPropValue


func _init() -> void:
	Scorm.attribute_updated.connect(_on_scorm_attribute_updated)


func _on_scorm_attribute_updated(attribute: Scorm.Attributes, value: Variant) -> void:
	if(auto_update):
		_update_labels(attribute, value)


func _update_labels(attribute: Scorm.Attributes, value: Variant) -> void:
	print("Updating from event ('%s' '%s')..." % [Scorm.ATTRIBUTES_TXT[attribute], Scorm.dme_lookup[attribute].get_value_ext()])
	match(attribute):
		Scorm.Attributes.SCORE:
			score_value.text = str(value)
		#Scorm.Attributes.SESSION_TIME:
			#session_time_value.text = str(value)
		Scorm.Attributes.LESSON_STATUS:
			lesson_status_value.text = Scorm.LESSON_STATUS_TXT[value]
		#Scorm.Attributes.SUCCESS_STATUS:
			#success_status_value.text = Scorm.SUCCESS_STATUS_TXT[value]
	_update_custom_prop_label()


func _update_custom_prop_label() -> void:
	if custom_prop_attr.text:
		custom_prop_value.text = Scorm.lms_get_attr_raw(custom_prop_attr.text)


func _on_auto_refresh_toggle_toggled(value: bool) -> void:
	auto_update = value


func _on_score_submit_button_pressed() -> void:
	# NOTE: The 'Score' node limits the accepted values between 0 and 100.
	Scorm.set_score(score_input.value)


func _on_score_refresh_button_pressed() -> void:
	score_value.text = str(Scorm.get_score())


func _on_session_time_submit_button_pressed():
	print("Session time: %s" % session_time_input.text)
	print("Set session time disabled for now.")
	# Scorm.set_session_time(float(session_time_input.text))


func _on_session_time_refresh_button_pressed():
	print("Get session not available. Attribute is WO.")
	#session_time_value.text = str(Scorm.get_session_time())


func _on_pass_toggle_toggled(toggled_on: bool) -> void:
	if(toggled_on):
		Scorm.lms_set_lesson_status(Scorm.LessonStatus.COMPLETED)
	else:
		Scorm.lms_set_lesson_status(Scorm.LessonStatus.INCOMPLETE)


func _on_status_refresh_button_pressed() -> void:
	lesson_status_value.text = Scorm.LESSON_STATUS_TXT[Scorm.lms_get_lesson_status()]


func _on_success_status_submit_button_pressed():
	# NOTE: The order of the options must be the same of the Scorm's SucessStatus enum
	print("success_status isnt supported by SCORM 1.2.")
	# var val: Scorm.SuccessStatus = success_status_input.get_item_index(success_status_input.get_selected_id())
	# Scorm.set_sucess_status(val)


func _on_success_status_refresh_button_pressed():
	success_status_value.text = Scorm.SUCCESS_STATUS_TXT[Scorm.get_success_status()]


# Adjusts scene to be a dropdown
func _on_custom_prop_submit_button_pressed() -> void:
	Scorm.lms_set_attr_raw(custom_prop_attr.text, custom_prop_input.text)


func _on_custom_prop_refresh_button_pressed() -> void:
	_update_custom_prop_label()


func _on_button_pressed():
	Scorm.lesson_completed()


func _on_incomplete_pressed():
	Scorm.lesson_incomplete()


func _on_passed_pressed():
	Scorm.lesson_passed()


func _on_failed_pressed():
	Scorm.lesson_failed()
