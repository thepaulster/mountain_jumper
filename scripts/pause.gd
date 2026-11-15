extends CanvasLayer

@export var player: Player

@onready var pause_button: Button = $PauseButton
@onready var menu: ColorRect = $Menu
@onready var resume_button: Button = $Menu/Box/List/Resume
@onready var restart_button: Button = $Menu/Box/List/Restart

var in_run := false        # only allow pausing while actually flying


func _ready() -> void:
	if player == null:
		push_error("Pause: drag the Player node into the Player box in main.tscn")
		return
	menu.hide()
	pause_button.hide()                        # no button on the title screen

	pause_button.pressed.connect(pause)
	resume_button.pressed.connect(resume)
	restart_button.pressed.connect(restart)
	player.jumped.connect(start_run)
	player.died.connect(end_run)


func _unhandled_input(event: InputEvent) -> void:
	# Escape key on PC also pauses and unpauses
	if in_run and event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			resume()
		else:
			pause()


func start_run() -> void:
	in_run = true
	pause_button.show()


func end_run() -> void:
	in_run = false
	pause_button.hide()


func pause() -> void:
	get_tree().paused = true                   # freeze the world
	menu.show()
	pause_button.hide()
	resume_button.grab_focus()                 # Space or Enter presses Resume


func resume() -> void:
	get_tree().paused = false                  # unfreeze
	menu.hide()
	pause_button.show()


func restart() -> void:
	get_tree().paused = false                  # must unfreeze first, or the new game starts frozen
	get_tree().reload_current_scene()