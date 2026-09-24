extends Control

## DeskView.gd - Primary gameplay canvas for "Yes, Mr. Mayor!"
## Handles tactile document stamping, drawer interactions, micro-camera shake, and shift loop.

const DOCUMENT_SCENE: PackedScene = preload("res://scenes/desk/DocumentItem.tscn")

@onready var shake_root: Control = %ShakeRoot
@onready var document_drop_zone: Control = %DocumentDropZone
@onready var btn_stamp_approve: Button = %BtnStampApprove
@onready var btn_stamp_reject: Button = %BtnStampReject
@onready var safe_drawer_panel: PanelContainer = %SafeDrawerPanel
@onready var drawer_label: Label = %DrawerLabel
@onready var drawer_hint: Label = %DrawerHint
@onready var next_day_box: PanelContainer = %NextDayBox
@onready var btn_next_day: Button = %BtnNextDay
@onready var shift_info_label: Label = %ShiftInfoLabel

var active_document: Control = null
var is_processing_decision: bool = false
var _shake_tween: Tween


func _ready() -> void:
	btn_stamp_approve.pressed.connect(_on_approve_pressed)
	btn_stamp_reject.pressed.connect(_on_reject_pressed)
	btn_next_day.pressed.connect(_on_next_day_pressed)
	safe_drawer_panel.gui_input.connect(_on_drawer_gui_input)

	LocalizationManager.locale_changed.connect(_update_locale_texts)
	_update_locale_texts("")

	next_day_box.visible = false
	_start_or_continue_shift()


func _update_locale_texts(_loc: String) -> void:
	btn_stamp_approve.text = tr("UI_STAMP_APPROVED")
	btn_stamp_reject.text = tr("UI_STAMP_REJECTED")
	drawer_label.text = tr("UI_DRAWER_LABEL")
	drawer_hint.text = tr("UI_DRAWER_HINT")
	btn_next_day.text = tr("UI_NEXT_DAY")
	shift_info_label.text = tr("UI_NO_MORE_DOCS")


func _start_or_continue_shift() -> void:
	if EventManager.daily_queue.is_empty():
		EventManager.prepare_daily_queue(4)
	_present_next_document()


## Draws and animates the next document onto the desk
func _present_next_document() -> void:
	if active_document != null and is_instance_valid(active_document):
		active_document.queue_free()
		active_document = null

	var next_event: EventData = EventManager.pop_daily_event()
	if next_event == null:
		_on_daily_quota_completed()
		return

	next_day_box.visible = false
	_set_stamps_enabled(false)

	var doc_instance := DOCUMENT_SCENE.instantiate()
	document_drop_zone.add_child(doc_instance)
	active_document = doc_instance

	doc_instance.setup_event(next_event)
	GameManager.present_event(next_event)

	var desk_center := Vector2(630, 160)
	var spawn_pos := Vector2(-700, 350)
	doc_instance.animate_slide_in(spawn_pos, desk_center, -0.015)

	doc_instance.slide_in_completed.connect(func():
		_set_stamps_enabled(true)
		is_processing_decision = false
	)


func _on_approve_pressed() -> void:
	_execute_stamping(true)


func _on_reject_pressed() -> void:
	_execute_stamping(false)


func _execute_stamping(approved: bool) -> void:
	if is_processing_decision or active_document == null or GameManager.active_event == null:
		return

	is_processing_decision = true
	_set_stamps_enabled(false)

	# 1. Micro-camera shake on desk
	_trigger_camera_shake(0.25, 6.0)

	# 2. Tactile ink stamp slam on document
	active_document.apply_stamp_visual(approved)

	# 3. Apply decision to GameManager
	var took_bribe: bool = active_document.has_pocketed_bribe
	GameManager.resolve_event(GameManager.active_event, approved, took_bribe)

	# 4. Brief delay to let player savor the stamped document
	await get_tree().create_timer(0.45).timeout

	# 5. Slide document offscreen to right
	var exit_pos := Vector2(2100, 160)
	active_document.animate_slide_out(exit_pos)
	active_document.slide_out_completed.connect(func():
		_present_next_document()
	)


func _trigger_camera_shake(duration: float, intensity: float) -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	_shake_tween = create_tween()
	var steps: int = int(duration / 0.04)
	for i in range(steps):
		var damp: float = 1.0 - (float(i) / float(steps))
		var offset := Vector2(
			randf_range(-intensity, intensity) * damp,
			randf_range(-intensity, intensity) * damp
		)
		_shake_tween.tween_property(shake_root, "position", offset, 0.04)
	_shake_tween.tween_property(shake_root, "position", Vector2.ZERO, 0.04)


func _on_drawer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_animate_drawer_pull()
		# If document has unpocketed bribe, pocket it
		if active_document != null and not active_document.has_pocketed_bribe:
			if GameManager.active_event and GameManager.active_event.bribe_offered > 0:
				active_document.pocket_bribe()


func _animate_drawer_pull() -> void:
	var tween := create_tween()
	tween.tween_property(safe_drawer_panel, "position:y", safe_drawer_panel.position.y + 16.0, 0.1)
	tween.tween_property(safe_drawer_panel, "position:y", safe_drawer_panel.position.y, 0.15)


func _on_daily_quota_completed() -> void:
	_set_stamps_enabled(false)
	next_day_box.visible = true


func _on_next_day_pressed() -> void:
	GameManager.advance_day()
	EventManager.prepare_daily_queue(4)
	_present_next_document()


func _set_stamps_enabled(enabled: bool) -> void:
	btn_stamp_approve.disabled = not enabled
	btn_stamp_reject.disabled = not enabled
