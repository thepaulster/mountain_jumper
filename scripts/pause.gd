extends CanvasLayer

@export var player: Player

@onready var pause_button: Button = $PauseButton
@onready var menu: ColorRect = $Menu
@onready var resume_button: Button = $Menu/Box/List/Resume
@onready var restart_button: Button = $Menu/Box/List/Restart
@onready var sound_button: Button = $Menu/Box/List/Sound

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
	sound_button.pressed.connect(toggle_sound)
	update_sound_label()  


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
	player.holding = false                     # forget any finger that was down
	player.diving = false
	player.touches.clear()
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

func toggle_sound() -> void:
	SaveData.sound_on = not SaveData.sound_on   # flip it: on becomes off, off becomes on
	SaveData.apply_sound()
	SaveData.save_game()                        # remember it for next time
	update_sound_label()


func update_sound_label() -> void:
	sound_button.text = "SOUND: ON" if SaveData.sound_on else "SOUND: OFF"