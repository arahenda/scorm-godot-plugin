extends Control

var sent_attribute:String

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_check_button_toggled(value):
	$ScormNode.emmit_return_on_set = value


func _on_score_button_pressed():
	$ScormNode._setScormValue("cmi.score.scaled",$VBoxContainer/HBoxContainer/Score.value)




func _on_scorm_node_get_scorm_value(atribute, value):
	match(atribute):
		"cmi.score.scaled":
			$VBoxContainer/HBoxContainer/Result.text = value
		"completion_status":
			$VBoxContainer/HBoxContainer2/Result.text = value
		sent_attribute:
			$VBoxContainer/HBoxContainer3/Result.text = value
		


func _on_button_pressed():
	$VBoxContainer/HBoxContainer/Result.text = $ScormNode._getScormValue("cmi.score.scaled")


func _on_pass_button_toggled(toggled_on):
	if(toggled_on):
		$ScormNode._setScormValue("cmi.completion_status", 'completed')
	else:
		$ScormNode._setScormValue("cmi.completion_status", 'failed')


func _on_button_pass_pressed():
	$VBoxContainer/HBoxContainer2/Result.text = $ScormNode._getScormValue("cmi.completion_status")


func _on_sent_button_pressed():
	sent_attribute = $VBoxContainer/HBoxContainer3/VBoxContainer/HBoxContainer/TextEdit.text
	$ScormNode._setScormValue(sent_attribute, $VBoxContainer/HBoxContainer3/VBoxContainer/HBoxContainer2/TextValue.text)


func _on_button_cusrt_pressed():
	$VBoxContainer/HBoxContainer3/Result.text = $ScormNode._getScormValue(sent_attribute)
