extends Node2D
class_name EcoBattlePoint

## Ponto visual de batalha espalhado pelo mapa.
## Não usa colisão: o BattleManager mede a distância até o Elias.

var tipo_lixo: String = ""
var nome_lixo: String = "Lixo"
var numero: int = 0
var cor: Color = Color.WHITE
var concluido: bool = false

var _label_interacao: Label
var _label_numero: Label
var _barra_vida: ProgressBar


func configurar(novo_material: String, novo_nome_lixo: String, novo_numero: int, nova_cor: Color) -> void:
	tipo_lixo = novo_material
	nome_lixo = novo_nome_lixo
	numero = novo_numero
	cor = nova_cor
	z_index = 6
	_criar_visual()
	queue_redraw()


func _draw() -> void:
	if concluido:
		return

	# Marcador simples, visível sem precisar de sprite externo.
	draw_circle(Vector2.ZERO, 20.0, Color(0.05, 0.05, 0.05, 0.45))
	draw_circle(Vector2.ZERO, 15.0, cor)
	draw_circle(Vector2.ZERO, 8.0, cor.lightened(0.22))


func _criar_visual() -> void:
	if is_instance_valid(_label_numero):
		return

	_label_numero = Label.new()
	_label_numero.name = "Numero"
	_label_numero.text = str(numero)
	_label_numero.position = Vector2(-13, -13)
	_label_numero.size = Vector2(26, 26)
	_label_numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_numero.add_theme_font_size_override("font_size", 12)
	_label_numero.add_theme_color_override("font_color", Color.WHITE)
	_label_numero.add_theme_color_override("font_outline_color", Color("202020"))
	_label_numero.add_theme_constant_override("outline_size", 4)
	_label_numero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label_numero)

	_label_interacao = Label.new()
	_label_interacao.name = "Interacao"
	_label_interacao.position = Vector2(-105, -58)
	_label_interacao.size = Vector2(210, 34)
	_label_interacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_interacao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_interacao.add_theme_font_size_override("font_size", 13)
	_label_interacao.add_theme_color_override("font_color", Color.WHITE)
	_label_interacao.add_theme_color_override("font_outline_color", Color("202020"))
	_label_interacao.add_theme_constant_override("outline_size", 5)
	_label_interacao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_interacao.visible = false
	add_child(_label_interacao)

	_criar_barra_vida()


func _criar_barra_vida() -> void:
	_barra_vida = ProgressBar.new()
	_barra_vida.name = "BarraVida"
	_barra_vida.min_value = 0.0
	_barra_vida.max_value = 100.0
	_barra_vida.value = 100.0
	_barra_vida.show_percentage = false
	_barra_vida.size = Vector2(72, 7)
	_barra_vida.custom_minimum_size = Vector2(72, 7)
	_barra_vida.position = Vector2(-36, 28)
	_barra_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra_vida.z_index = 100
	_barra_vida.add_theme_stylebox_override("background", _style_barra(Color("252525"), Color("111111")))
	_barra_vida.add_theme_stylebox_override("fill", _style_barra(Color("c84545"), Color("7e2929")))
	_barra_vida.visible = false
	add_child(_barra_vida)


func _style_barra(cor_fundo: Color, cor_borda: Color) -> StyleBoxFlat:
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


func set_player_proximo(proximo: bool, desbloqueado: bool) -> void:
	if not is_instance_valid(_label_interacao):
		return
	if concluido:
		_label_interacao.visible = false
		return

	_label_interacao.visible = proximo
	if not proximo:
		return

	if desbloqueado:
		_label_interacao.text = "[B] Batalhar — %s" % nome_lixo
		_label_interacao.add_theme_color_override("font_color", Color.WHITE)
	else:
		_label_interacao.text = "[B] PODER NECESSÁRIO"
		_label_interacao.add_theme_color_override("font_color", Color("c9c9c9"))


func mostrar_barra_vida(vida: int = 100) -> void:
	if is_instance_valid(_barra_vida):
		_barra_vida.value = clampi(vida, 0, 100)
		_barra_vida.visible = true


func atualizar_barra_vida(vida: int) -> void:
	if is_instance_valid(_barra_vida):
		_barra_vida.value = clampi(vida, 0, 100)


func esconder_barra_vida() -> void:
	if is_instance_valid(_barra_vida):
		_barra_vida.visible = false


func marcar_concluido() -> void:
	concluido = true
	if is_instance_valid(_barra_vida):
		_barra_vida.visible = false
	visible = false
	if is_instance_valid(_label_interacao):
		_label_interacao.visible = false
	queue_redraw()


func animar_dano() -> void:
	if concluido:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.16)
