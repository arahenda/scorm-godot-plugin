extends Node

signal attribute_updated(atribute: Attributes, value: Variant)

# Enables debug messages.
@export var verbose_mode: bool = false


# Represents the student score in the current SCO attempt.
enum Attributes {
	SCORE,	# int 0-100
	SCORE_MAX, # int 0
	SCORE_MIN, # int 100
	LESSON_STATUS,	# enum LessonStatus (1.2 name, in 2004 it's 'completion_status')
	#SESSION_TIME,	# Write only, managed at scorm.js
	#SUCCESS_STATUS,	# enum SuccessStatus (scorm 2004)
}

# See SCORM 1.2 reference: https://scorm.com/scorm-explained/technical-scorm/run-time/run-time-reference/#section-2
const ATTRIBUTES_TXT = {
	Attributes.SCORE: "cmi.core.score.raw",
	Attributes.SCORE_MAX: "cmi.core.score.max",
	Attributes.SCORE_MIN: "cmi.core.score.min",
	Attributes.LESSON_STATUS: "cmi.core.lesson_status",
	# Attributes.SUCCESS_STATUS: "cmi.success_status",
	#Attributes.SESSION_TIME: "cmi.core.session_time",
}

# Finished info
enum LessonStatus {
	NOT_ATTEMPTED,
	INCOMPLETE,
	COMPLETED,
	PASSED, # 1.2
	FAILED, # 1.2
	# UNKNOWN, # 2004
}

const LESSON_STATUS_TXT = {
	LessonStatus.NOT_ATTEMPTED: "not attempted",
	LessonStatus.INCOMPLETE: "incomplete",
	LessonStatus.COMPLETED: "completed",
	LessonStatus.PASSED: "passed",
	LessonStatus.FAILED: "failed",
	# LessonStatus.UNKNOWN: "unknown",
}

# Success info
# enum SuccessStatus {	# 2004
# 	PASSED,
# 	FAILED,
# 	UNKNOWN,
# }

# const SUCCESS_STATUS_TXT = {
# 	SuccessStatus.PASSED: "passed",
# 	SuccessStatus.FAILED: "failed",
# 	SuccessStatus.UNKNOWN: "unknown",
# }

var TXT2LESSON_STATUS := {}
# var TXT2SUCCESS_STATUS := {}

# key: attribute | value: DME
var dme_lookup = {}

class DME:
	"""Data Model Element"""
	var id: int
	var attr: Attributes
	var val: Variant
	var val_ext: Variant	# Contains the 'external' value as expected by the LMS. Setted in check().

	func _init(attr: Attributes, val: Variant):
		self.id = Scorm._id_next()
		self.attr = attr
		#self.val = val
		if (!_set_safe(val)):
			push_error("Not possible to create DME ('%s', '%s')" % [attr, val])
			self.attr = -1
			self.val = null
			self.val_ext = null

	func get_attribute() -> Attributes: return attr

	func get_attribute_ext() -> String: return ATTRIBUTES_TXT[attr]

	func get_value() -> Variant: return self.val

	func get_value_ext() -> Variant: return self.val_ext

	func set_value(nval) -> void:
		_set_safe(nval)

	func _set_safe(val: Variant) -> Variant:
		Scorm._logv("> dme_set_safe() '%s' '%s'" % [attr, val])
		match(self.attr):
			Scorm.Attributes.SCORE,\
			Scorm.Attributes.SCORE_MAX,\
			Scorm.Attributes.SCORE_MIN:
				val = int(val)
				if 0 > val or 100 < val:
					push_error("Score needs to be in [0,100] range. Received '%s'." % [val])
					return false
				self.val_ext = val
				self.val = val
			Scorm.Attributes.LESSON_STATUS:
				Scorm._logv("%s" % [Scorm.LessonStatus.values()])
				if not val in Scorm.LessonStatus.values():
					push_error("LessonStatus '%s' isn't valid." % [val])
					return false
				self.val_ext = LESSON_STATUS_TXT[val]
				self.val = val
			_:
				push_error("Error! Not possible to process attribute '%s'." % [self.attr])
				return false
		return true


# API
func get_score() -> int:
	var dme := lms_get_attr(Attributes.SCORE)
	if !dme:
		return 0
	return dme.get_value()


func set_score(value: int) -> void:
	"""Value must be between [0, 100]."""
	lms_set_attr(Attributes.SCORE_MAX, 100)
	lms_set_attr(Attributes.SCORE_MIN, 0)
	lms_set_attr(Attributes.SCORE, value)


func set_lesson_status(status: LessonStatus) -> void:
	_logv("> lesson_completed")
	lms_set_attr(Attributes.LESSON_STATUS, status)
	if status == LessonStatus.INCOMPLETE:
		js_scorm.reachedEnd = false
	else:
		js_scorm.reachedEnd = true


func get_lesson_status() -> LessonStatus:
	var dme := lms_get_attr(Attributes.LESSON_STATUS)
	if !dme:
		return LessonStatus.NOT_ATTEMPTED
	return dme.get_value()


## Direct access
func lms_get_attr(attribute: Attributes) -> DME:
	_logv("> lms_get_attr '%s'" % [ATTRIBUTES_TXT[attribute]])
	var lms_value = js_scorm.getValue(ATTRIBUTES_TXT[attribute])
	_logv("> lms_value '%s'" % [lms_value])
	if !lms_value:
		_logv("> Value no present in LMS.")
		return null
	var sanitized_value := _value_ext2type(attribute, lms_value)
	_logv("> sanitized_value '%s'" % [sanitized_value])
	if sanitized_value == null:
		_log("Error! Unable to identify the value type of '%s'." % [lms_value])
		return null
	var dme: DME = _dme_get_or_create(attribute, sanitized_value)
	if !dme:
		return null
	dme.set_value(sanitized_value)
	_logv("> dme_value '%s'" % [dme.get_value()])
	_logv("> dme_value_ext '%s'" % [dme.get_value_ext()])
	return dme


func lms_set_attr(attribute: Attributes, value: Variant) -> void:
	var dme: DME = _dme_get_or_create(attribute, value)
	_logv("> lms_set_attr '%s' '%s'" % [ATTRIBUTES_TXT[attribute], dme.get_value_ext()])
	js_scorm.setValue(ATTRIBUTES_TXT[attribute], dme.get_value_ext())
	lms_commit()
	dme = lms_get_attr(attribute)
	if !dme:
		return
	attribute_updated.emit(attribute, dme.get_value())


func lms_get_attr_raw(attribute_txt: String) -> String:
	if !attribute_txt: return ""
	_logv("> lms_get_attr_raw '%s'" % [attribute_txt])
	return js_scorm.getValue(attribute_txt)


func lms_set_attr_raw(attribute_txt: String, value_txt: String) -> void:
	"""
	NOTE: Sends data directly, bypasses the types or safe-guards. Not emits signal.
	Use only for tests if possible.
	"""
	if !attribute_txt: return
	_logv("> lms_set_attr_raw '%s' '%s'" % [attribute_txt, value_txt])
	js_scorm.setValue(attribute_txt, value_txt)


func lms_commit() -> void:
	js_scorm.commit()


# Misc
func _pmsg(msg: String) -> String:
	return "Plugin(Scorm): %s" % [msg]

func _log(msg: String) -> void:
	print(_pmsg("%s" % [msg]))

func _logv(msg: String) -> void:
	if verbose_mode: print(_pmsg("%s" % [msg]))

var _counter := 0
func _id_next():
	var ret := _counter
	_counter+=1
	return ret


func _dme_get_or_create(attribute: Attributes, value: Variant) -> DME:
	var dme: DME = dme_lookup.find_key(attribute)
	if !dme:
		dme = DME.new(attribute, value)
		dme_lookup[attribute] = dme
	return dme


func _value_ext2type(attribute: Attributes, value: Variant) -> Variant:
	match(attribute):
		Scorm.Attributes.SCORE,\
		Scorm.Attributes.SCORE_MAX,\
		Scorm.Attributes.SCORE_MIN:
			return int(value)
		Scorm.Attributes.LESSON_STATUS:
			return TXT2LESSON_STATUS[value]
		_:
			push_error("Error! Attribute '%s' with value '%s' not mapped." % [attribute, value])
			return null


var js_scorm
class MockScorm:
	const _mock_msg := "Mocked object"

	var reachedEnd: bool
	func getValue(key: String) -> Variant:
		print(_mock_msg)
		return ""
	func setValue(key: String, val: Variant) -> void:
		print(_mock_msg)
		return
	func commit() -> void:
		print(_mock_msg)
		return


func _init():
	js_scorm = JavaScriptBridge.get_interface("scorm")
	if !js_scorm:
		js_scorm = MockScorm.new()

	for k in LESSON_STATUS_TXT:
		var v = LESSON_STATUS_TXT[k]
		TXT2LESSON_STATUS[v] = k
