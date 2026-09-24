extends Node

## LocalizationManager.gd - Central manager for language switching and locale validation.
## Strict i18n compliant for "Yes, Mr. Mayor!".

signal locale_changed(new_locale: String)

const SUPPORTED_LOCALES: Array[String] = ["en", "tr", "es"]

func _ready() -> void:
	var system_locale := TranslationServer.get_locale().substr(0, 2).to_lower()
	if system_locale in SUPPORTED_LOCALES:
		set_locale(system_locale)
	else:
		set_locale("en")


## Sets engine locale if supported, falls back to "en" otherwise
func set_locale(locale_code: String) -> void:
	var code := locale_code.to_lower()
	if code in SUPPORTED_LOCALES:
		TranslationServer.set_locale(code)
		locale_changed.emit(code)
	else:
		push_warning("Locale %s not supported, falling back to English." % locale_code)
		TranslationServer.set_locale("en")
		locale_changed.emit("en")


## Returns current 2-letter locale code
func get_current_locale() -> String:
	return TranslationServer.get_locale().substr(0, 2).to_lower()
