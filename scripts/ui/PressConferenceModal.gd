class_name PressConferenceModal
extends Control

## PressConferenceModal.gd - Interactive Friday media grilling conference.
## The Mayor faces sharp journalist questions and must choose narrative tactics.

signal conference_finished

@onready var modal_container: Control = %ModalContainer
@onready var header_label: Label = %HeaderLabel
@onready var subheader_label: Label = %SubHeaderLabel
@onready var reporter_label: Label = %ReporterLabel
@onready var question_label: Label = %QuestionLabel
@onready var flash_overlay: ColorRect = %FlashOverlay
@onready var flash_particles: CPUParticles2D = %FlashParticles if has_node("%FlashParticles") else null

@onready var btn_spin: Button = %BtnSpin
@onready var btn_blame: Button = %BtnBlame
@onready var btn_stonewall: Button = %BtnStonewall
@onready var btn_distract: Button = %BtnDistract
@onready var btn_slush: Button = %BtnSlush if has_node("%BtnSlush") else null

var current_question_idx: int = 0
var active_questions: Array[Dictionary] = []
var all_questions_db: Array[Dictionary] = []


func _ready() -> void:
	_load_questions_db()

	if btn_spin != null:
		btn_spin.pressed.connect(func(): _resolve_answer("spin"))
	if btn_blame != null:
		btn_blame.pressed.connect(func(): _resolve_answer("blame"))
	if btn_stonewall != null:
		btn_stonewall.pressed.connect(func(): _resolve_answer("stonewall"))
	if btn_distract != null:
		btn_distract.pressed.connect(func(): _resolve_answer("distract"))
	if btn_slush != null:
		btn_slush.pressed.connect(func(): _resolve_answer("slush"))


func _load_questions_db() -> void:
	var path := "res://data/press_questions.json"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			var txt := f.get_as_text()
			f.close()
			var json := JSON.new()
			if json.parse(txt) == OK and json.data is Array:
				for item in json.data:
					if item is Dictionary:
						all_questions_db.append(item)


func start_conference(recent_events: Array = []) -> void:
	visible = true
	current_question_idx = 0

	active_questions = _generate_contextual_questions(recent_events)
	if active_questions.is_empty():
		active_questions = _get_fallback_questions()

	if AudioManager != null:
		if AudioManager.has_method("play_mic_feedback"):
			AudioManager.play_mic_feedback()
		if AudioManager.has_method("set_crowd_murmur_active"):
			AudioManager.set_crowd_murmur_active(true)

	_trigger_camera_flash()
	_present_question()


func _generate_contextual_questions(recent_events: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var matched_ids: Array[String] = []

	# Check events for trigger keywords
	var has_floodway: bool = false
	var has_bribe: bool = false
	var has_industrial: bool = false
	var has_zoning: bool = false
	var has_labor: bool = false

	for ev in recent_events:
		var ev_cat: String = ""
		var app_dist: String = ""
		var took_bribe: bool = false
		var app_id: String = ""

		if ev is Dictionary:
			ev_cat = str(ev.get("category", "")).to_lower()
			app_dist = str(ev.get("district_id", ""))
			took_bribe = bool(ev.get("took_bribe", false))
			app_id = str(ev.get("event_id", ""))
		elif ev != null and "category" in ev:
			ev_cat = str(ev.category).to_lower()
			if "application_data" in ev and ev.application_data != null:
				app_dist = str(ev.application_data.get("district_id", ""))
			took_bribe = bool(ev.get("took_bribe")) if "took_bribe" in ev else false
			app_id = str(ev.id) if "id" in ev else ""

		if app_dist == "DIST_RIVERBED" or app_id == "EVT_001" or ev_cat == "floodway":
			has_floodway = true
		if took_bribe:
			has_bribe = true
		if ev_cat == "industrial":
			has_industrial = true
		if ev_cat == "zoning" or ev_cat == "development":
			has_zoning = true
		if ev_cat == "labor" or ev_cat == "transit":
			has_labor = true

	# Match questions from database
	for q in all_questions_db:
		var q_id: String = q.get("id", "")
		if q_id == "PRESS_Q_FLOODWAY" and has_floodway and not matched_ids.has(q_id):
			result.append(q)
			matched_ids.append(q_id)
		elif q_id == "PRESS_Q_BRIBE_LEAK" and has_bribe and not matched_ids.has(q_id):
			result.append(q)
			matched_ids.append(q_id)
		elif q_id == "PRESS_Q_SMOG_INDUSTRIAL" and has_industrial and not matched_ids.has(q_id):
			result.append(q)
			matched_ids.append(q_id)
		elif q_id == "PRESS_Q_ZONING_VARIANCE" and has_zoning and not matched_ids.has(q_id):
			result.append(q)
			matched_ids.append(q_id)
		elif q_id == "PRESS_Q_LABOR_DISPUTE" and has_labor and not matched_ids.has(q_id):
			result.append(q)
			matched_ids.append(q_id)

	# Fill up to 2 or 3 questions
	for q in all_questions_db:
		if result.size() >= 3:
			break
		var q_id: String = q.get("id", "")
		if not matched_ids.has(q_id):
			result.append(q)
			matched_ids.append(q_id)

	return result


func _get_fallback_questions() -> Array[Dictionary]:
	return [
		{
			"id": "PRESS_Q_GENERAL_SUSPICION",
			"reporter_name": "Arthur Vance",
			"outlet": "The Daily Watchdog",
			"question_key": "PRESS_Q_SUSPICION_TEXT",
			"default_question": "Arthur Vance again, Mr. Mayor. State audit inspectors have been spotted hovering around municipal archives. Can you look the press in the eye and say your ledger is clean?"
		},
		{
			"id": "PRESS_Q_ZONING_VARIANCE",
			"reporter_name": "Rex Sterling",
			"outlet": "Channel 6 Action News",
			"question_key": "PRESS_Q_ZONING_TEXT",
			"default_question": "Rex Sterling here! Outraged neighborhood associations claim luxury high-rise permits are bulldozing historic landmarks. Who is really running City Hall—you, or the property oligarchs?"
		}
	]


func _present_question() -> void:
	if current_question_idx >= active_questions.size():
		_finish_conference()
		return

	var q: Dictionary = active_questions[current_question_idx]

	if subheader_label != null:
		subheader_label.text = tr("PRESS_CONFERENCE_SUBTITLE").replace("{day}", str(GameManager.current_day)) + (" • (%d/%d)" % [current_question_idx + 1, active_questions.size()])

	if reporter_label != null:
		var rep_name: String = q.get("reporter_name", "Reporter")
		var outlet: String = q.get("outlet", "Press Corps")
		reporter_label.text = "🎤 %s (%s)" % [rep_name, outlet]

	if question_label != null:
		var q_key: String = q.get("question_key", "")
		var text: String = tr(q_key) if (not q_key.is_empty() and tr(q_key) != q_key) else q.get("default_question", "")
		question_label.text = '"%s"' % text

	# Update button states (e.g. distract cost, slush fund cash)
	if btn_distract != null:
		btn_distract.disabled = (GameManager.city_budget < 20000)
		btn_distract.text = "🏛️ " + tr("TACTIC_DISTRACT_TITLE")
	if btn_slush != null:
		btn_slush.disabled = (GameManager.personal_wealth < 25000)
		btn_slush.text = "💼 " + tr("TACTIC_SLUSH_TITLE")


func _trigger_camera_flash() -> void:
	if AudioManager != null and AudioManager.has_method("play_camera_shutter"):
		AudioManager.play_camera_shutter()

	if flash_particles != null:
		flash_particles.restart()
		flash_particles.emitting = true

	if flash_overlay != null:
		flash_overlay.visible = true
		flash_overlay.modulate.a = 0.85
		var tween := create_tween()
		tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.22)
		tween.finished.connect(func(): flash_overlay.visible = false)


func _resolve_answer(tactic: String) -> void:
	_trigger_camera_flash()

	match tactic:
		"spin":
			if GameManager.public_opinion >= 45.0:
				GameManager.apply_resolution({"public_opinion": 8.0, "suspicion": -2.0})
			else:
				GameManager.apply_resolution({"suspicion": 4.0, "public_opinion": -3.0})
		"blame":
			GameManager.apply_resolution({"suspicion": -8.0, "public_opinion": -2.0})
		"stonewall":
			GameManager.apply_resolution({"suspicion": 5.0})
		"distract":
			if GameManager.city_budget >= 20000:
				GameManager.city_budget -= 20000
				GameManager.apply_resolution({"public_opinion": 12.0, "suspicion": -10.0})
			else:
				GameManager.apply_resolution({"suspicion": 3.0, "public_opinion": -5.0})
		"slush":
			if GameManager.personal_wealth >= 25000:
				GameManager.personal_wealth -= 25000
				GameManager.apply_resolution({"public_opinion": 15.0, "suspicion": -15.0})

	current_question_idx += 1
	if current_question_idx >= active_questions.size():
		_finish_conference()
	else:
		_present_question()


func _finish_conference() -> void:
	if AudioManager != null and AudioManager.has_method("set_crowd_murmur_active"):
		AudioManager.set_crowd_murmur_active(false)

	visible = false
	conference_finished.emit()
