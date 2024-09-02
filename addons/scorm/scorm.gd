extends Node

signal attribute_updated(atribute: Attributes, value: Variant)

@export var verbose_mode: bool = false

enum Attributes {
	SCORE_SCALED,	# float [-1, 1]
	COMPLETION_STATUS,	# enum CompletionStatus
	SUCCESS_STATUS,	# enum SuccessStatus
	SESSION_TIME, # float seconds
}

# See: https://scorm.com/scorm-explained/technical-scorm/run-time/run-time-reference/#section-5
const ATTRIBUTES_TXT = {
	Attributes.SCORE_SCALED: "cmi.score.scaled",
	Attributes.COMPLETION_STATUS: "cmi.completion_status",
	Attributes.SUCCESS_STATUS: "cmi.success_status",
	Attributes.SESSION_TIME: "cmi.session_time",
}

# Finished info
enum CompletionStatus {
	COMPLETED,
	INCOMPLETE,
	NOT_ATTEMPTED,
	UNKNOWN,
}

const COMPLETION_STATUS_TXT = {
	CompletionStatus.COMPLETED: "completed",
	CompletionStatus.INCOMPLETE: "incomplete",
	CompletionStatus.NOT_ATTEMPTED: "not attempted",
	CompletionStatus.UNKNOWN: "unknown",
}

# Success info
enum SuccessStatus {
	PASSED,
	FAILED,
	UNKNOWN,
}

const SUCCESS_STATUS_TXT = {
	SuccessStatus.PASSED: "passed",
	SuccessStatus.FAILED: "failed",
	SuccessStatus.UNKNOWN: "unknown",
}

var TXT2COMPLETION_STATUS := {}
var TXT2SUCCESS_STATUS := {}

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
		self.val = val
		if (!_check()):
			push_error("Not possible to create DME ('%s', '%s')" % [attr, val])
			self.attr = -1
			self.val = null
			self.val_ext = null

	func get_attribute() -> Attributes: return attr

	func get_attribute_ext() -> String: return ATTRIBUTES_TXT[attr]

	func get_value() -> Variant: return self.val

	func get_value_ext() -> Variant: return self.val_ext

	func set_value(nval) -> void:
		self.val = nval
		_check()

	func _check() -> Variant:
		Scorm._logv("> dme_check() '%s' '%s'" % [attr, val])
		match(self.attr):
			Scorm.Attributes.SCORE_SCALED:
				if -1 > self.val or 1 < self.val:
					push_error("Score needs to be in [-1,1] range.")
					return false
				self.val = float(val)
				self.val_ext = self.val
			Scorm.Attributes.SESSION_TIME:
				if 0 > self.val:
					push_error("Session time must be greater than 0.")
					return false
				self.val = float(val)
				self.val_ext = self.val
			Scorm.Attributes.COMPLETION_STATUS:
				if not self.val in Scorm.CompletionStatus.values():
					push_error("Value isn't a valid COMPLETION_STATUS.")
					return false
				self.val_ext = COMPLETION_STATUS_TXT[self.val]
			Scorm.Attributes.SUCCESS_STATUS:
				if not self.val in Scorm.SuccessStatus.values():
					push_error("Value isn't a valid SUCCESS_STATUS.")
					return false
				self.val_ext = SUCCESS_STATUS_TXT[self.val]
			_:
				push_error("Invalid attribute type.")
				return false
		return true


# API
func get_score() -> float:
	var dme := lms_get_attr(Attributes.SCORE_SCALED)
	if !dme:
		return 0.0
	return dme.get_value()


func set_score(value: float) -> void:
	"""Value must be between [-1,1]."""
	lms_set_attr(Attributes.SCORE_SCALED, value)


func get_session_time() -> float:
	var dme := lms_get_attr(Attributes.SESSION_TIME)
	if !dme:
		return 0.0
	return dme.get_value()


func set_session_time(value: float) -> void:
	"""Seconds."""
	lms_set_attr(Attributes.SESSION_TIME, value)


func get_completion_status() -> CompletionStatus:
	var dme := lms_get_attr(Attributes.COMPLETION_STATUS)
	if !dme:
		return CompletionStatus.UNKNOWN
	return dme.get_value()


func set_completion_status(value: CompletionStatus):
	lms_set_attr(Attributes.COMPLETION_STATUS, value)


func get_success_status() -> SuccessStatus:
	var dme := lms_get_attr(Attributes.SUCCESS_STATUS)
	if !dme:
		return SuccessStatus.UNKNOWN
	return dme.get_value()


func set_sucess_status(value: SuccessStatus):
	lms_set_attr(Attributes.SUCCESS_STATUS, value)


## Direct access
func lms_get_attr(attribute: Attributes) -> DME:
	_logv("> lms_get_attr '%s'" % [ATTRIBUTES_TXT[attribute]])
	var lms_value = JavaScriptBridge.eval("ScormProcessGetValue('%s')" % [ATTRIBUTES_TXT[attribute]])
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
	JavaScriptBridge.eval("ScormProcessSetValue('%s', '%s')" % [ATTRIBUTES_TXT[attribute], dme.get_value_ext()])
	dme = lms_get_attr(attribute)
	if !dme:
		return
	attribute_updated.emit(attribute, dme.get_value())


func lms_get_attr_raw(attribute_txt: String) -> String:
	if !attribute_txt: return ""
	_logv("> lms_get_attr_raw '%s'" % [attribute_txt])
	return str(JavaScriptBridge.eval("ScormProcessGetValue('%s')" % [attribute_txt]))


func lms_set_attr_raw(attribute_txt: String, value_txt: String) -> void:
	"""
	NOTE: Sends data directly, bypasses the types or safe-guards. Not emits signal.
	Use only for tests if possible.
	"""
	if !attribute_txt: return
	_logv("> lms_set_attr_raw '%s' '%s'" % [attribute_txt, value_txt])
	JavaScriptBridge.eval("ScormProcessSetValue('%s', '%s')" % [attribute_txt, value_txt])


# Misc
func _pmsg(msg: String) -> String:
	return "Plugin(Scorm): %s" % msg

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
		Scorm.Attributes.SCORE_SCALED,\
		Scorm.Attributes.SESSION_TIME:
			return value
		Scorm.Attributes.COMPLETION_STATUS:
			return TXT2COMPLETION_STATUS[value]
		Scorm.Attributes.SUCCESS_STATUS:
			return TXT2SUCCESS_STATUS[value]
		_:
			return null


func _init():
	for k in COMPLETION_STATUS_TXT:
		var v = COMPLETION_STATUS_TXT[k]
		TXT2COMPLETION_STATUS[v] = k
	for k in SUCCESS_STATUS_TXT:
		var v = SUCCESS_STATUS_TXT[k]
		TXT2SUCCESS_STATUS[v] = k

# To extend the functionality you problably will:
# - Adjust the enums/consts
# - Create a TXT2<enum>, adjust the _init(), adjust _value_ext2type()
# - Adjust DME._check()
