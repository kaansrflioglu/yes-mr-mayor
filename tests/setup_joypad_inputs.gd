extends SceneTree

## setup_joypad_inputs.gd - Helper utility to configure Gamepad / Steam Deck InputEvents.

func _init() -> void:
	var joy_mappings: Dictionary = {
		"mayor_approve": JOY_BUTTON_A,
		"mayor_reject": JOY_BUTTON_B,
		"mayor_bribe": JOY_BUTTON_X,
		"mayor_inspect": JOY_BUTTON_Y,
		"mayor_page_prev": JOY_BUTTON_LEFT_SHOULDER,
		"mayor_page_next": JOY_BUTTON_RIGHT_SHOULDER,
		"mayor_telephone": JOY_BUTTON_BACK
	}

	for action_name in joy_mappings:
		if not ProjectSettings.has_setting("input/" + action_name):
			continue
		var setting: Dictionary = ProjectSettings.get_setting("input/" + action_name)
		var events: Array = setting.get("events", [])

		var button_idx: JoyButton = joy_mappings[action_name] as JoyButton
		var already_exists: bool = false
		for ev in events:
			if ev is InputEventJoypadButton and ev.button_index == button_idx:
				already_exists = true
				break

		if not already_exists:
			var joy_ev := InputEventJoypadButton.new()
			joy_ev.button_index = button_idx
			events.append(joy_ev)
			setting["events"] = events
			ProjectSettings.set_setting("input/" + action_name, setting)

	ProjectSettings.save_custom("res://project.godot")
	quit()
