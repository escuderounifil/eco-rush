extends Control

@onready var musica: AudioStreamPlayer = $Musica
@onready var som_click: AudioStreamPlayer =$SomClick

var button_type = null

func _on_texture_button_pressed() -> void:
	som_click.play()
	
	button_type = "start"
	$ColorRect.show()
	$ColorRect/Fade_timer.start()
	$ColorRect/AnimationPlayer.play("fade_in")


func _on_timer_timeout() -> void:
	if button_type == "start":
		get_tree().change_scene_to_file("res://eco_rush.tscn")
