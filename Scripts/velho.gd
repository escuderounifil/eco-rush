extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	play_idle()


func play_idle() -> void:
	animated_sprite.play("down-idle")
