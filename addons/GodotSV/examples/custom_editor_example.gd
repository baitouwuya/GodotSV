extends Node

## Example showing how to register custom cell editors for GDSVEditorRegistry
##
## Usage:
## 1. Add this script to an autoload or run it in _ready() before opening CSV files
## 2. Define custom type in schema with "type": "color" or other custom types
## 3. The table view will automatically use your custom editor

func _ready() -> void:
	# Example 1: Register a custom color picker editor
	GDSVEditorRegistry.register_editor("color", _create_color_editor)

	# Example 2: Register a custom slider editor for "rating" type
	GDSVEditorRegistry.register_editor("rating", _create_rating_editor)

	# Example 3: Register a custom editor with method-based get_value()
	GDSVEditorRegistry.register_editor("percentage", _create_percentage_editor)

	print("Custom editors registered: ", GDSVEditorRegistry.get_registered_types())


## Factory function for color editor
## Returns a ColorPickerButton that works with hex color values
static func _create_color_editor(row: int, column: int, config: Dictionary) -> Control:
	var picker := ColorPickerButton.new()
	picker.edit_alpha = config.get("allow_alpha", true)

	# Set initial value from config if provided
	var initial_value: String = config.get("initial_value", "#FFFFFFFF")
	if initial_value.begins_with("#") and initial_value.length() >= 7:
		var hex := initial_value.substr(1)
		var r := hex.substr(0, 2).hex_to_int() / 255.0
		var g := hex.substr(2, 2).hex_to_int() / 255.0
		var b := hex.substr(4, 2).hex_to_int() / 255.0
		var a := 1.0
		if hex.length() >= 8:
			a = hex.substr(6, 2).hex_to_int() / 255.0
		picker.color = Color(r, g, b, a)

	# Custom editors can implement get_value() via metadata callable
	# TableView checks: 1. metadata, 2. method, 3. fallback
	picker.set_meta("get_value", func() -> String:
		var c := picker.color
		var r := int(c.r * 255)
		var g := int(c.g * 255)
		var b := int(c.b * 255)
		var a := int(c.a * 255)
		return "#%02X%02X%02X%02X" % [r, g, b, a]
	)

	return picker


## Factory function for rating editor
## Returns a HSlider for numeric ratings
static func _create_rating_editor(row: int, column: int, config: Dictionary) -> Control:
	var container := HBoxContainer.new()

	var slider := HSlider.new()
	slider.min_value = config.get("min", 0.0)
	slider.max_value = config.get("max", 5.0)
	slider.step = config.get("step", 0.5)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(slider)

	var label := Label.new()
	label.custom_minimum_size.x = 40
	container.add_child(label)

	# Set initial value
	var initial_value: String = config.get("initial_value", "0")
	if initial_value.is_valid_float():
		slider.value = initial_value.to_float()
	label.text = str(slider.value)

	slider.value_changed.connect(func(value: float) -> void:
		label.text = str(value)
	)

	# Implement get_value() method via metadata callable
	container.set_meta("get_value", func() -> String:
		return str(slider.value)
	)

	return container


## Example: Unregister an editor (useful for testing)
func _unregister_example() -> void:
	GDSVEditorRegistry.unregister_editor("color")
	print("Color editor unregistered")


## Example: Clear all custom editors
func _clear_all_editors() -> void:
	GDSVEditorRegistry.clear()
	print("All custom editors cleared")


## Factory function for percentage editor (demonstrates method-based approach)
## Returns a custom control with get_value() method
static func _create_percentage_editor(row: int, column: int, config: Dictionary) -> Control:
	# Create custom editor class with get_value() method
	var editor := PercentageEditor.new()

	# Set initial value
	var initial_value: String = config.get("initial_value", "0")
	if initial_value.is_valid_float():
		editor.set_percentage(initial_value.to_float())

	return editor


## Custom editor control with get_value() method
## TableView will call this method to retrieve the edited value
class PercentageEditor extends HBoxContainer:
	var _spinbox: SpinBox
	var _label: Label

	func _init() -> void:
		_spinbox = SpinBox.new()
		_spinbox.min_value = 0.0
		_spinbox.max_value = 100.0
		_spinbox.step = 0.1
		_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(_spinbox)

		_label = Label.new()
		_label.text = "%"
		_label.custom_minimum_size.x = 20
		add_child(_label)

		_spinbox.value_changed.connect(func(_value: float) -> void:
			# Update UI when value changes
			pass
		)

	## This method is called by TableView to get the edited value
	func get_value() -> String:
		return str(_spinbox.value)

	## Helper to set initial value
	func set_percentage(value: float) -> void:
		_spinbox.value = clamp(value, 0.0, 100.0)
