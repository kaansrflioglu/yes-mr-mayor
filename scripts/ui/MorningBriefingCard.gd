extends PanelContainer

## MorningBriefingCard.gd - Morning broadsheet newspaper (The Daily Metropolitan).
## Displays day-specific narrative context, weather/union warnings, and active municipal directives.
## Features halftone dot-matrix photo illustrations and authentic vintage typography.

@onready var pin_icon: Label = %PinIcon if has_node("%PinIcon") else null
@onready var memo_date_label: Label = (
	%MemoDateLabel if has_node("%MemoDateLabel") else null
)
@onready var memo_from_label: Label = (
	%MemoFromLabel if has_node("%MemoFromLabel") else null
)
@onready var memo_text_label: Label = (
	%MemoTextLabel if has_node("%MemoTextLabel") else null
)
@onready var photo_rect: TextureRect = (
	%PhotoRect if has_node("%PhotoRect") else null
)
@onready var modifier_badge: PanelContainer = (
	%ModifierBadge if has_node("%ModifierBadge") else null
)
@onready var modifier_title_label: Label = (
	%ModifierTitleLabel if has_node("%ModifierTitleLabel") else null
)
@onready var modifier_desc_label: Label = (
	%ModifierDescLabel if has_node("%ModifierDescLabel") else null
)

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


## Plays charming entrance slide-in animation
func slide_in() -> Tween:
	visible = true
	modulate.a = 0.0
	position.y = _initial_position.y - 30.0
	rotation_degrees = _initial_rotation - 2.0
	if _slide_tween and _slide_tween.is_valid():
		_slide_tween.kill()
	_slide_tween = create_tween().set_parallel(true)
	_slide_tween.tween_property(self, "modulate:a", 1.0, 0.25)
	_slide_tween.tween_property(
		self, "position:y", _initial_position.y, 0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_slide_tween.tween_property(
		self, "rotation_degrees", _initial_rotation, 0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return _slide_tween


## Plays dismiss slide-out animation
func slide_out() -> Tween:
	if _slide_tween and _slide_tween.is_valid():
		_slide_tween.kill()
	_slide_tween = create_tween().set_parallel(true)
	_slide_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_slide_tween.tween_property(
		self, "position:y", _initial_position.y + 40.0, 0.2
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_slide_tween.chain().tween_callback(func(): visible = false)
	return _slide_tween


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


## Configures the broadsheet newspaper for the requested day
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
		var date_format := tr("UI_MONTH_COUNTER")
		if date_format != "UI_MONTH_COUNTER" and not date_format.is_empty() and "{month}" in date_format:
			memo_date_label.text = date_format.format({"month": day}) + " • 08:30 AM"
		else:
			var day_format := tr("UI_DAY_COUNTER")
			if day_format != "UI_DAY_COUNTER" and not day_format.is_empty():
				memo_date_label.text = day_format.format({"day": day}).replace(
					"Gün", "Ay"
				).replace("Day", "Month") + " • 08:30 AM"
			else:
				memo_date_label.text = "Ay %d • 08:30 AM" % day

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

	_update_photo_for_day(day)
	_update_directive_badge()


func _update_photo_for_day(day: int) -> void:
	if photo_rect == null:
		return
	var photo_path := "res://assets/sprites/ui/newspaper_photo_ribbon.png"
	var has_directive: bool = (
		DirectiveManager != null and DirectiveManager.active_directive_id != DirectiveManager.DIR_STANDARD
	)
	if day == 3 or day == 4 or has_directive:
		photo_path = "res://assets/sprites/ui/newspaper_photo_strike.png"
	elif day >= 5:
		photo_path = "res://assets/sprites/ui/newspaper_photo_scandal.png"

	if ResourceLoader.exists(photo_path):
		photo_rect.texture = load(photo_path) as Texture2D


func _update_directive_badge() -> void:
	if modifier_badge == null:
		return
	if DirectiveManager == null:
		modifier_badge.visible = false
		return

	if DirectiveManager.active_directive_id == DirectiveManager.DIR_STANDARD:
		modifier_badge.visible = false
		return

	var d: Dictionary = DirectiveManager.active_directive
	if d.is_empty():
		modifier_badge.visible = false
		return

	modifier_badge.visible = true
	if modifier_title_label != null:
		modifier_title_label.text = "⚠️ " + tr(d.get("title_key", "MODIFIER_TITLE"))
	if modifier_desc_label != null:
		modifier_desc_label.text = tr(d.get("desc_key", "MODIFIER_DESC"))


func _get_fallback_memo_text(day: int) -> String:
	match day:
		1:
			return tr("MEMO_DAY_1_FALLBACK") if tr(
				"MEMO_DAY_1_FALLBACK"
			) != "MEMO_DAY_1_FALLBACK" else "Welcome to City Hall, Mr. Mayor! The executive docket awaits your official seal."
		2:
			return tr("MEMO_DAY_2_FALLBACK") if tr(
				"MEMO_DAY_2_FALLBACK"
			) != "MEMO_DAY_2_FALLBACK" else "Union representatives are protesting near the docks. Review industrial permits with caution."
		3:
			return tr("MEMO_DAY_3_FALLBACK") if tr(
				"MEMO_DAY_3_FALLBACK"
			) != "MEMO_DAY_3_FALLBACK" else "Environmental protection auditors have arrived. Ecology violations are under strict federal surveillance."
		_:
			return "Municipal administration continues. Check the morning news for evolving district reactions."
