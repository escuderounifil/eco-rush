extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera_2d: Camera2D = $Camera2D

const SPEED = 300.0
const ACCEL = 2.0

var last_direction: Vector2 = Vector2.RIGHT
var movimento_bloqueado: bool = false

var _foco_dialogo_ativo: bool = false
var _camera_posicao_original: Vector2 = Vector2.ZERO
var _camera_zoom_original: Vector2 = Vector2.ONE
var _camera_tween: Tween
var _barra_vida_batalha: ProgressBar = null


func _physics_process(_delta: float) -> void:
	if movimento_bloqueado:
		velocity = Vector2.ZERO
		process_animation(last_direction)
		move_and_slide()
		return

	process_movement()
	move_and_slide()


func process_movement() -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
	else:
		velocity = Vector2.ZERO
	process_animation(last_direction)


func process_animation(direction: Vector2) -> void:
	if velocity != Vector2.ZERO:
		play_animation("run", direction)
	else:
		play_animation("idle", direction)


func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")


# -----------------------------------------------------------------------------
# API usada por diálogos/cutscenes.
# -----------------------------------------------------------------------------

func set_movimento_bloqueado(bloqueado: bool) -> void:
	movimento_bloqueado = bloqueado
	if bloqueado:
		velocity = Vector2.ZERO
		process_animation(last_direction)


func olhar_para(alvo_global: Vector2) -> void:
	var origem := animated_sprite_2d.global_position
	var direcao := (alvo_global - origem).normalized()
	if direcao == Vector2.ZERO:
		return

	# Prioriza o eixo com maior diferença para escolher uma animação coerente.
	if absf(direcao.x) > absf(direcao.y):
		last_direction = Vector2(signf(direcao.x), 0)
	else:
		last_direction = Vector2(0, signf(direcao.y))
	process_animation(last_direction)


func iniciar_foco_dialogo(alvo_global: Vector2, zoom_alvo: float = 1.65, duracao: float = 0.35) -> void:
	if not is_instance_valid(camera_2d):
		return

	if not _foco_dialogo_ativo:
		_camera_posicao_original = camera_2d.position
		_camera_zoom_original = camera_2d.zoom
		_foco_dialogo_ativo = true

	if is_instance_valid(_camera_tween):
		_camera_tween.kill()

	var alvo_local := to_local(alvo_global)
	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_QUAD)
	_camera_tween.set_ease(Tween.EASE_OUT)
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(camera_2d, "position", alvo_local, duracao)
	_camera_tween.tween_property(camera_2d, "zoom", Vector2(zoom_alvo, zoom_alvo), duracao)


func encerrar_foco_dialogo(duracao: float = 0.35) -> void:
	if not _foco_dialogo_ativo or not is_instance_valid(camera_2d):
		return

	if is_instance_valid(_camera_tween):
		_camera_tween.kill()

	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_QUAD)
	_camera_tween.set_ease(Tween.EASE_OUT)
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(camera_2d, "position", _camera_posicao_original, duracao)
	_camera_tween.tween_property(camera_2d, "zoom", _camera_zoom_original, duracao)
	_foco_dialogo_ativo = false


# -----------------------------------------------------------------------------
# API usada pelo sistema de batalha.
# -----------------------------------------------------------------------------

func iniciar_foco_batalha(alvo_global: Vector2, zoom_alvo: float = 1.85, duracao: float = 0.30) -> void:
	iniciar_foco_dialogo(alvo_global, zoom_alvo, duracao)


func encerrar_foco_batalha(duracao: float = 0.30) -> void:
	encerrar_foco_dialogo(duracao)


## Mostra uma barra pequena de vida logo abaixo do Elias.
## A barra não exibe números nem porcentagem.
func mostrar_barra_vida_batalha(vida: int = 100) -> void:
	_garantir_barra_vida_batalha()
	atualizar_barra_vida_batalha(vida)
	if is_instance_valid(_barra_vida_batalha):
		_barra_vida_batalha.visible = true


func atualizar_barra_vida_batalha(vida: int) -> void:
	_garantir_barra_vida_batalha()
	if is_instance_valid(_barra_vida_batalha):
		_barra_vida_batalha.value = clampi(vida, 0, 100)


func esconder_barra_vida_batalha() -> void:
	if is_instance_valid(_barra_vida_batalha):
		_barra_vida_batalha.visible = false


func _garantir_barra_vida_batalha() -> void:
	if is_instance_valid(_barra_vida_batalha):
		return

	_barra_vida_batalha = ProgressBar.new()
	_barra_vida_batalha.name = "BarraVidaBatalha"
	_barra_vida_batalha.min_value = 0.0
	_barra_vida_batalha.max_value = 100.0
	_barra_vida_batalha.value = 100.0
	_barra_vida_batalha.show_percentage = false
	_barra_vida_batalha.size = Vector2(72, 7)
	_barra_vida_batalha.custom_minimum_size = Vector2(72, 7)
	# O sprite do Elias é deslocado dentro do CharacterBody2D; a barra acompanha
	# esse deslocamento e fica logo abaixo dos pés.
	_barra_vida_batalha.position = animated_sprite_2d.position + Vector2(-36, 57)
	_barra_vida_batalha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra_vida_batalha.z_index = 100
	_barra_vida_batalha.add_theme_stylebox_override("background", _style_barra_vida(Color("252525"), Color("111111")))
	_barra_vida_batalha.add_theme_stylebox_override("fill", _style_barra_vida(Color("4baa62"), Color("2a6738")))
	_barra_vida_batalha.visible = false
	add_child(_barra_vida_batalha)


func _style_barra_vida(cor_fundo: Color, cor_borda: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = cor_fundo
	style.border_color = cor_borda
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style
