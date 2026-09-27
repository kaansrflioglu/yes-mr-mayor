extends PanelContainer

## MorningBriefingCard.gd - Secretary's sticky Post-It memo for the morning ritual.
## Displays day-specific narrative context, weather/union warnings, and active municipal directives.

@onready var pin_icon: Label = %PinIcon if has_node("%PinIcon") else null
@onready var memo_date_label: Label = %MemoDateLabel if has_node("%MemoDateLabel") else null
@onready var memo_from_label: Label = %MemoFromLabel if has_node("%MemoFromLabel") else null
@onready var memo_text_label: Label = %MemoTextLabel if has_node("%MemoTextLabel") else null
@onready var modifier_badge: PanelContainer = %ModifierBadge if has_node("%ModifierBadge") else null
@onready var modifier_title_label: Label = %ModifierTitleLabel if has_node("%ModifierTitleLabel") else null
@onready var modifier_desc_label: Label = %ModifierDescLabel if has_node("%ModifierDescLabel") else null

var _current_day: int = 1
var _memos_database: Dictionary = {}
var _initial_position: Vector2 = Vector2.ZERO
var _initial_rotation: float = -1.5
var _slide_tween: Tween = null


func _ready() -> void:
	rotation_degrees = -1.5
	_initial_position = position
	_initial_rotation = rotation_degrees
	_load_memos_data()
	if LocalizationManager != null and LocalizationManager.has_signal("locale_changed"):
		LocalizationManager.locale_changed.connect(_on_locale_changed)


func _on_locale_changed(_new_locale: String) -> void:
	setup_briefing(_current_day)


func _load_memos_data() -> void:
	var path := "res://data/morning_memos.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var json_str := file.get_as_text()
	var json := JSON.new()
	if json.parse(json_str) == OK and json.data is Dictionary:
		_memos_database = json.data


## Configures the Post-It memo for the requested day
func setup_briefing(day: int, custom_memo: Dictionary = {}) -> void:
	_current_day = day

	var day_str := str(day)
	var locale := "en"
	if LocalizationManager != null and LocalizationManager.has_method("get_current_locale"):
		locale = LocalizationManager.get_current_locale()

	# Extract localized or custom memo
	var memo_entry: Dictionary = {}
	if not custom_memo.is_empty():
		memo_entry = custom_memo
	elif _memos_database.has(day_str):
		var day_data: Dictionary = _memos_database[day_str]
		if day_data.has(locale):
			memo_entry = day_data[locale]
		elif day_data.has("en"):
			memo_entry = day_data["en"]

	if memo_date_label != null:
		var date_format := tr("UI_DAY_COUNTER")
		if date_format != "UI_DAY_COUNTER" and not date_format.is_empty():
			memo_date_label.text = date_format.format({"day": day}) + " • 08:30 AM"
		else:
			memo_date_label.text = "Day %d • 08:30 AM" % day

	if memo_from_label != null:
		var author: String = memo_entry.get("author", "")
		if author.is_empty():
			author = tr("UI_SECRETARY_MEMO_FROM")
			if author == "UI_SECRETARY_MEMO_FROM":
				author = "From: Clarissa (Executive Secretary)"
		memo_from_label.text = author

	if memo_text_label != null:
		var text: String = memo_entry.get("text", "")
		if text.is_empty():
			text = _get_fallback_memo_text(day)
		memo_text_label.text = text

	_update_directive_badge()


func _update_directive_badge() -> void:
	if modifier_badge == null:
		return
	if DirectiveManager == null:
		modifier_badge.visible = false
		return

	var dir: Dictionary = DirectiveManager.get_active_directive()
	if dir.is_empty() or dir.get("id", "") == DirectiveManager.DIR_STANDARD:
		modifier_badge.visible = false
		return

	modifier_badge.visible = true
	if modifier_title_label != null:
		modifier_title_label.text = "⚠️ " + DirectiveManager.get_active_title()
	if modifier_desc_label != null:
		modifier_desc_label.text = DirectiveManager.get_active_desc()


func _get_fallback_memo_text(day: int) -> String:
	match day:
		1:
			return tr("MEMO_DAY_1_TEXT") if tr("MEMO_DAY_1_TEXT") != "MEMO_DAY_1_TEXT" else "Good morning, Mr. Mayor! Fresh coffee is on your desk. First batch of municipal permits is ready outside."
		3:
			return tr("MEMO_DAY_3_TEXT") if tr("MEMO_DAY_3_TEXT") != "MEMO_DAY_3_TEXT" else "Auditors from the Ministry of Ecology are dining across the street. The Governor's office called twice before 8 AM. Be careful with river permits!"
		7:
			return tr("MEMO_DAY_7_TEXT") if tr("MEMO_DAY_7_TEXT") != "MEMO_DAY_7_TEXT" else "Sanitation union representatives are picketing on the east lawn. Watch out for wage and public work decisions today."
		12:
			return tr("MEMO_DAY_12_TEXT") if tr("MEMO_DAY_12_TEXT") != "MEMO_DAY_12_TEXT" else "Federal subpoena rumors are flying. Shredder is oiled and ready. Keep your eyes sharp!"
		18:
			return tr("MEMO_DAY_18_TEXT") if tr("MEMO_DAY_18_TEXT") != "MEMO_DAY_18_TEXT" else "Heatwave! The air conditioning in City Hall is broken. Focus will drain quickly today."
		28:
			return tr("MEMO_DAY_28_TEXT") if tr("MEMO_DAY_28_TEXT") != "MEMO_DAY_28_TEXT" else "Election in 48 hours! Pollsters say you're leading by 2%. Every single decision counts double."
		_:
			return tr("MEMO_DEFAULT_TEXT") if tr("MEMO_DEFAULT_TEXT") != "MEMO_DEFAULT_TEXT" else "Good morning, Mr. Mayor! The morning docket is assembled. Waiting room is filling up."


func slide_in() -> void:
	if _slide_tween and _slide_tween.is_valid():
		_slide_tween.kill()
	visible = true
	if _initial_position != Vector2.ZERO:
		position = _initial_position
	elif position != Vector2.ZERO:
		_initial_position = position
	rotation_degrees = _initial_rotation
	modulate.a = 0.0
	scale = Vector2(0.88, 0.88)
	_slide_tween = create_tween().set_parallel(true)
	_slide_tween.tween_property(self, "modulate:a", 1.0, 0.28)
	_slide_tween.tween_property(self, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func slide_out() -> Tween:
	if _slide_tween and _slide_tween.is_valid():
		_slide_tween.kill()
	if _initial_position == Vector2.ZERO and position != Vector2.ZERO:
		_initial_position = position
	_slide_tween = create_tween().set_parallel(true)
	_slide_tween.tween_property(self, "position:y", position.y - 300.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_slide_tween.tween_property(self, "rotation_degrees", rotation_degrees - 4.0, 0.32)
	_slide_tween.tween_property(self, "modulate:a", 0.0, 0.28)
	return _slide_tween
