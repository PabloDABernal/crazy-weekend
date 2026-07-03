class_name ResolutionFeedbackOverlay extends Control

const DISPLAY_DURATION_SECONDS: float = 1.6

@onready var _amount_label: Label = $NotificationAnchor/AmountLabel
@onready var _detail_label: Label = $DetailLabel

var _queue: Array[Dictionary] = []
var _display_timer: Timer = null


func _ready() -> void:
	visible = false
	_display_timer = Timer.new()
	_display_timer.one_shot = true
	_display_timer.wait_time = DISPLAY_DURATION_SECONDS
	add_child(_display_timer)
	_display_timer.timeout.connect(_on_display_timer_timeout)


func show_win(amount_returned: int, net: int) -> void:
	_enqueue({"won": true, "net": net, "amount_returned": amount_returned})


func show_loss(amount_lost: int) -> void:
	_enqueue({"won": false, "amount_lost": amount_lost})


func _enqueue(entry: Dictionary) -> void:
	_queue.append(entry)
	if not visible:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		visible = false
		return

	var entry: Dictionary = _queue.pop_front()
	visible = true

	if entry["won"]:
		_amount_label.text = "+$%d" % entry["amount_returned"]
		_amount_label.add_theme_color_override("font_color", Color(0.067, 0.902, 0.392, 1))
		_detail_label.text = "neto +$%d" % entry["net"]
	else:
		_amount_label.text = "-$%d" % entry["amount_lost"]
		_amount_label.add_theme_color_override("font_color", Color(0.894, 0.271, 0.271, 1))
		_detail_label.text = ""

	_display_timer.start()


func _on_display_timer_timeout() -> void:
	_show_next()
