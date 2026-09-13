extends CanvasLayer
class_name EcoRushHUD

## HUD principal do EcoRush.
## Toda a interface e toda a API pública da HUD ficam nesta pasta.

signal tipo_lixo_selecionado(tipo: String, numero: int)
signal progresso_lixo_alterado(percentual: int)
signal hud_visibilidade_alterada(ativa: bool)
signal reiniciar_solicitado

const LOCK_TEXTURE: Texture2D = preload("res://hud/lock.svg")
const TRASH_TEXTURE: Texture2D = preload("res://hud/trash.svg")

const TIPOS: Array[String] = [
	"Eletrônico",
	"Plástico",
	"Metal",
	"Orgânico",
	"Papel",
	"Vidro"
]

const CORES: Array[Color] = [
	Color("c83d42"),
	Color("ac765d"),
	Color("827a58"),
	Color("353535"),
	Color("3f627d"),
	Color("3e733d")
]

const CORES_TEXTO: Array[Color] = [
	Color.WHITE,
	Color("332a25"),
	Color("2b2b25"),
	Color.WHITE,
	Color("263440"),
	Color("1e3420")
]

@export var inicia_visivel: bool = false
@export_range(0, 100, 1) var progresso_inicial: int = 0
@export_multiline var texto_inicial: String = "O seu lugar é no\nmeu saco!"

var _raiz: Control
var _texto_label: Label
var _texto_falante_label: Label
var _texto_dica_label: Label
var _texto_persistente: String = ""
var _progresso_label: Label

var _botoes: Array[Button] = []
var _cadeados: Array[TextureRect] = []

var _tipos_ativos: Array[bool] = [
	false,
	false,
	false,
	false,
	false,
	false
]

var _tipo_selecionado: int = -1
var _progresso_lixo: int = 0
var _hud_ativa: bool = true
var _dialogo_ativo: bool = false
var _modo_batalha: bool = false
var _progresso_por_tipo: Dictionary = {}

var _tela_derrota: Control

# Transição da batalha
var _transicao_batalha: ColorRect


func _ready() -> void:
	layer = 100

	for tipo in TIPOS:
		_progresso_por_tipo[tipo] = 0

	_criar_interface()
	_criar_transicao_batalha()
	_criar_tela_derrota()

	_progresso_lixo = clampi(
		progresso_inicial,
		0,
		100
	)

	atualizar_texto(texto_inicial)
	_atualizar_progresso_visual()
	_atualizar_botoes()

	set_hud_ativa(inicia_visivel)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var tecla := event as InputEventKey

	if not tecla.pressed or tecla.echo:
		return

	var codigo := tecla.physical_keycode

	if codigo == KEY_NONE:
		codigo = tecla.keycode

	# Durante diálogos/cutscenes, a HUD fica travada.
	if _dialogo_ativo:
		return

	# Durante batalha, B não fecha a HUD.
	if _modo_batalha and codigo == KEY_B:
		get_viewport().set_input_as_handled()
		return

	if codigo == KEY_B:
		alternar_hud()
		get_viewport().set_input_as_handled()
		return

	if not _hud_ativa:
		return

	match codigo:
		KEY_1:
			selecionar_tipo(1)
			get_viewport().set_input_as_handled()

		KEY_2:
			selecionar_tipo(2)
			get_viewport().set_input_as_handled()

		KEY_3:
			selecionar_tipo(3)
			get_viewport().set_input_as_handled()

		KEY_4:
			selecionar_tipo(4)
			get_viewport().set_input_as_handled()

		KEY_5:
			selecionar_tipo(5)
			get_viewport().set_input_as_handled()

		KEY_6:
			selecionar_tipo(6)
			get_viewport().set_input_as_handled()


# -----------------------------------------------------------------------------
# API PÚBLICA
# -----------------------------------------------------------------------------

func ativar_hud() -> void:
	set_hud_ativa(true)


func desativar_hud() -> void:
	set_hud_ativa(false)


func set_hud_ativa(ativa: bool) -> void:
	_hud_ativa = ativa

	if is_instance_valid(_raiz):
		_raiz.visible = ativa

	hud_visibilidade_alterada.emit(ativa)


func alternar_hud() -> void:
	set_hud_ativa(not _hud_ativa)


func hud_esta_ativa() -> bool:
	return _hud_ativa


func bloquear_todos_tipos() -> void:
	for i in _tipos_ativos.size():
		_tipos_ativos[i] = false

	_tipo_selecionado = -1
	_atualizar_botoes()


func desbloquear_todos_tipos() -> void:
	for i in _tipos_ativos.size():
		_tipos_ativos[i] = true

	if _tipo_selecionado == -1:
		_tipo_selecionado = 0

	_atualizar_botoes()


func set_dialogo_ativo(ativo: bool) -> void:
	_dialogo_ativo = ativo


func dialogo_esta_ativo() -> bool:
	return _dialogo_ativo


func set_modo_batalha(ativo: bool) -> void:
	_modo_batalha = ativo


func batalha_esta_ativa() -> bool:
	return _modo_batalha


# -----------------------------------------------------------------------------
# DIÁLOGOS
# -----------------------------------------------------------------------------

func mostrar_dialogo(
	falante: String,
	texto: String
) -> void:

	if not is_instance_valid(_texto_label):
		return

	if is_instance_valid(_texto_falante_label):
		_texto_falante_label.visible = true
		_texto_falante_label.text = "▶ %s" % falante.to_upper()

		var nome := _normalizar_nome(falante)

		if nome == "elias":
			_texto_falante_label.add_theme_color_override(
				"font_color",
				Color("2f6fa8")
			)

		elif nome == "velho":
			_texto_falante_label.add_theme_color_override(
				"font_color",
				Color("9a6418")
			)

		else:
			_texto_falante_label.add_theme_color_override(
				"font_color",
				Color("333333")
			)

	if is_instance_valid(_texto_dica_label):
		_texto_dica_label.visible = true

	_texto_label.anchor_top = 0.0
	_texto_label.anchor_bottom = 1.0
	_texto_label.offset_top = 24.0
	_texto_label.offset_bottom = -19.0
	_texto_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	_ajustar_tamanho_texto_dialogo(texto)

	_texto_label.text = texto


func _ajustar_tamanho_texto_dialogo(
	texto: String
) -> void:

	if not is_instance_valid(_texto_label):
		return

	var quantidade := texto.length()
	var tamanho := 16

	if quantidade > 115:
		tamanho = 11
	elif quantidade > 95:
		tamanho = 12
	elif quantidade > 75:
		tamanho = 13
	elif quantidade > 60:
		tamanho = 14

	_texto_label.add_theme_font_size_override(
		"font_size",
		tamanho
	)


func atualizar_texto_dialogo(texto: String) -> void:
	if is_instance_valid(_texto_label):
		_texto_label.text = texto


func esconder_dialogo() -> void:
	if is_instance_valid(_texto_falante_label):
		_texto_falante_label.visible = false

	if is_instance_valid(_texto_dica_label):
		_texto_dica_label.visible = false

	if is_instance_valid(_texto_label):
		_texto_label.anchor_top = 0.0
		_texto_label.anchor_bottom = 1.0
		_texto_label.offset_top = 0.0
		_texto_label.offset_bottom = 0.0
		_texto_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		_texto_label.add_theme_font_size_override(
			"font_size",
			25
		)

		_texto_label.text = _texto_persistente


func atualizar_texto(novo_texto: String) -> void:
	_texto_persistente = novo_texto

	if is_instance_valid(_texto_label) and not _dialogo_ativo:
		_texto_label.text = novo_texto


func mudar_texto(novo_texto: String) -> void:
	atualizar_texto(novo_texto)


# -----------------------------------------------------------------------------
# PROGRESSO
# -----------------------------------------------------------------------------

func definir_progresso_lixo(percentual: int) -> void:
	_progresso_lixo = clampi(
		percentual,
		0,
		100
	)

	_atualizar_progresso_visual()
	progresso_lixo_alterado.emit(_progresso_lixo)


func definir_progresso_tipo(
	tipo: Variant,
	percentual: int
) -> void:

	var indice := _resolver_indice_tipo(tipo)

	if indice == -1:
		push_warning(
			"HUD: tipo de lixo inválido para progresso: %s"
			% str(tipo)
		)
		return

	var nome := TIPOS[indice]

	var valor := clampi(
		percentual,
		0,
		100
	)

	_progresso_por_tipo[nome] = valor

	if _tipo_selecionado == indice:
		definir_progresso_lixo(valor)


func obter_progresso_tipo(tipo: Variant) -> int:
	var indice := _resolver_indice_tipo(tipo)

	if indice == -1:
		return 0

	return int(
		_progresso_por_tipo.get(
			TIPOS[indice],
			0
		)
	)


func mostrar_progresso_tipo(tipo: Variant) -> void:
	var indice := _resolver_indice_tipo(tipo)

	if indice == -1:
		return

	definir_progresso_lixo(
		int(
			_progresso_por_tipo.get(
				TIPOS[indice],
				0
			)
		)
	)


func aumentar_progresso_lixo(
	quantidade: int = 1
) -> void:

	definir_progresso_lixo(
		_progresso_lixo + quantidade
	)


func diminuir_progresso_lixo(
	quantidade: int = 1
) -> void:

	definir_progresso_lixo(
		_progresso_lixo - quantidade
	)


func obter_progresso_lixo() -> int:
	return _progresso_lixo


# -----------------------------------------------------------------------------
# TIPOS DE LIXO
# -----------------------------------------------------------------------------

func set_tipo_ativo(
	tipo: Variant,
	ativo: bool
) -> void:

	var indice := _resolver_indice_tipo(tipo)

	if indice == -1:
		push_warning(
			"HUD: tipo de lixo inválido: %s"
			% str(tipo)
		)
		return

	_tipos_ativos[indice] = ativo

	if not ativo and _tipo_selecionado == indice:
		_tipo_selecionado = _primeiro_tipo_ativo()

	elif ativo and _tipo_selecionado == -1:
		_tipo_selecionado = indice

	_atualizar_botoes()


func ativar_tipo(tipo: Variant) -> void:
	set_tipo_ativo(tipo, true)


func desativar_tipo(tipo: Variant) -> void:
	set_tipo_ativo(tipo, false)


func tipo_esta_ativo(tipo: Variant) -> bool:
	var indice := _resolver_indice_tipo(tipo)

	return (
		indice != -1
		and _tipos_ativos[indice]
	)


func selecionar_tipo(tipo: Variant) -> void:
	var indice := _resolver_indice_tipo(tipo)

	if indice == -1 or not _tipos_ativos[indice]:
		return

	_tipo_selecionado = indice

	_progresso_lixo = int(
		_progresso_por_tipo.get(
			TIPOS[indice],
			0
		)
	)

	_atualizar_progresso_visual()
	_atualizar_botoes()

	tipo_lixo_selecionado.emit(
		TIPOS[indice],
		indice + 1
	)


func obter_tipo_selecionado() -> String:
	if (
		_tipo_selecionado < 0
		or _tipo_selecionado >= TIPOS.size()
	):
		return ""

	return TIPOS[_tipo_selecionado]


# -----------------------------------------------------------------------------
# CONSTRUÇÃO DA INTERFACE
# -----------------------------------------------------------------------------

func _criar_interface() -> void:
	_raiz = Control.new()

	_raiz.name = "Interface"
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(_raiz)

	_raiz.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_criar_medidor_lixo()
	_criar_barra_inferior()


func _criar_medidor_lixo() -> void:
	var painel := PanelContainer.new()

	painel.name = "MedidorLixo"

	painel.anchor_left = 1.0
	painel.anchor_right = 1.0

	painel.offset_left = -92.0
	painel.offset_right = -2.0
	painel.offset_top = -3.0
	painel.offset_bottom = 94.0

	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	painel.add_theme_stylebox_override(
		"panel",
		_style_box(
			Color("f7f8e9"),
			Color("111111"),
			4,
			16
		)
	)

	_raiz.add_child(painel)

	var margem := MarginContainer.new()

	margem.add_theme_constant_override(
		"margin_left",
		12
	)

	margem.add_theme_constant_override(
		"margin_right",
		12
	)

	margem.add_theme_constant_override(
		"margin_top",
		7
	)

	margem.add_theme_constant_override(
		"margin_bottom",
		6
	)

	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE

	painel.add_child(margem)

	var coluna := VBoxContainer.new()

	coluna.alignment = BoxContainer.ALIGNMENT_CENTER

	coluna.add_theme_constant_override(
		"separation",
		0
	)

	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE

	margem.add_child(coluna)

	var icone := TextureRect.new()

	icone.name = "IconeLixeira"
	icone.texture = TRASH_TEXTURE
	icone.custom_minimum_size = Vector2(54, 57)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE

	coluna.add_child(icone)

	_progresso_label = Label.new()

	_progresso_label.name = "Percentual"
	_progresso_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_progresso_label.add_theme_font_size_override(
		"font_size",
		14
	)

	_progresso_label.add_theme_color_override(
		"font_color",
		Color("303030")
	)

	_progresso_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	coluna.add_child(_progresso_label)


# -----------------------------------------------------------------------------
# COMPATIBILIDADE COM O SISTEMA DE BATALHA
# -----------------------------------------------------------------------------
# O antigo HUD de vida no topo foi removido.
# Estas funções continuam existindo para que o EcoBattleManager
# não quebre ao chamá-las.

func mostrar_batalha(
	_tipo_lixo: String,
	_vida_elias: int = 100,
	_vida_lixo: int = 100
) -> void:
	pass


func esconder_batalha() -> void:
	pass


func atualizar_vidas_batalha(
	_vida_elias: int,
	_vida_lixo: int
) -> void:
	pass


func atualizar_turno_batalha(
	_texto: String
) -> void:
	pass


# -----------------------------------------------------------------------------
# TRANSIÇÃO DA BATALHA
# -----------------------------------------------------------------------------

func _criar_transicao_batalha() -> void:
	_transicao_batalha = ColorRect.new()

	_transicao_batalha.name = "TransicaoBatalha"

	_transicao_batalha.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_transicao_batalha.color = Color(
		0,
		0,
		0,
		0
	)

	_transicao_batalha.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_transicao_batalha.z_index = 9999

	_transicao_batalha.visible = false

	add_child(_transicao_batalha)


func iniciar_transicao_batalha() -> void:
	if not is_instance_valid(_transicao_batalha):
		return

	_transicao_batalha.visible = true
	_transicao_batalha.mouse_filter = Control.MOUSE_FILTER_STOP

	_transicao_batalha.color = Color(
		0,
		0,
		0,
		0
	)

	var tween := create_tween()

	tween.tween_property(
		_transicao_batalha,
		"color:a",
		1.0,
		0.35
	)

	await tween.finished


func finalizar_transicao_batalha() -> void:
	if not is_instance_valid(_transicao_batalha):
		return

	_transicao_batalha.visible = true
	_transicao_batalha.mouse_filter = Control.MOUSE_FILTER_STOP

	_transicao_batalha.color.a = 1.0

	var tween := create_tween()

	tween.tween_property(
		_transicao_batalha,
		"color:a",
		0.0,
		0.35
	)

	await tween.finished

	_transicao_batalha.visible = false
	_transicao_batalha.mouse_filter = Control.MOUSE_FILTER_IGNORE


# -----------------------------------------------------------------------------
# BARRA INFERIOR
# -----------------------------------------------------------------------------

func _criar_barra_inferior() -> void:
	var fundo := PanelContainer.new()

	fundo.name = "BarraInferior"

	fundo.anchor_left = 0.0
	fundo.anchor_right = 1.0
	fundo.anchor_top = 1.0
	fundo.anchor_bottom = 1.0

	fundo.offset_left = 0.0
	fundo.offset_right = 0.0
	fundo.offset_top = -158.0
	fundo.offset_bottom = 0.0

	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fundo.add_theme_stylebox_override(
		"panel",
		_style_box(
			Color("f7f8e9"),
			Color("111111"),
			4,
			0
		)
	)

	_raiz.add_child(fundo)

	var margem := MarginContainer.new()

	margem.add_theme_constant_override(
		"margin_left",
		7
	)

	margem.add_theme_constant_override(
		"margin_right",
		7
	)

	margem.add_theme_constant_override(
		"margin_top",
		11
	)

	margem.add_theme_constant_override(
		"margin_bottom",
		8
	)

	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fundo.add_child(margem)

	var linha := HBoxContainer.new()

	linha.add_theme_constant_override(
		"separation",
		7
	)

	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE

	margem.add_child(linha)

	var caixa_texto := PanelContainer.new()

	caixa_texto.name = "CaixaTexto"
	caixa_texto.custom_minimum_size = Vector2(330, 0)
	caixa_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caixa_texto.size_flags_stretch_ratio = 0.58
	caixa_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE

	caixa_texto.add_theme_stylebox_override(
		"panel",
		_style_box(
			Color("f9faeb"),
			Color("111111"),
			4,
			18
		)
	)

	linha.add_child(caixa_texto)

	var texto_margem := MarginContainer.new()

	texto_margem.add_theme_constant_override(
		"margin_left",
		33
	)

	texto_margem.add_theme_constant_override(
		"margin_right",
		22
	)

	texto_margem.add_theme_constant_override(
		"margin_top",
		12
	)

	texto_margem.add_theme_constant_override(
		"margin_bottom",
		12
	)

	texto_margem.mouse_filter = Control.MOUSE_FILTER_IGNORE

	caixa_texto.add_child(texto_margem)

	var texto_conteudo := Control.new()

	texto_conteudo.name = "ConteudoTexto"
	texto_conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto_conteudo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	texto_conteudo.clip_contents = true
	texto_conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	texto_margem.add_child(texto_conteudo)

	_texto_falante_label = Label.new()

	_texto_falante_label.name = "Falante"
	_texto_falante_label.text = "▶ VELHO"
	_texto_falante_label.anchor_right = 1.0
	_texto_falante_label.offset_top = 0.0
	_texto_falante_label.offset_bottom = 22.0

	_texto_falante_label.add_theme_font_size_override(
		"font_size",
		16
	)

	_texto_falante_label.add_theme_color_override(
		"font_color",
		Color("9a6418")
	)

	_texto_falante_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto_falante_label.visible = false

	texto_conteudo.add_child(_texto_falante_label)

	_texto_label = Label.new()

	_texto_label.name = "Texto"
	_texto_label.anchor_right = 1.0
	_texto_label.anchor_bottom = 1.0
	_texto_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texto_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto_label.clip_text = true

	_texto_label.add_theme_font_size_override(
		"font_size",
		25
	)

	_texto_label.add_theme_color_override(
		"font_color",
		Color("111111")
	)

	_texto_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	texto_conteudo.add_child(_texto_label)

	_texto_dica_label = Label.new()

	_texto_dica_label.name = "DicaDialogo"
	_texto_dica_label.text = "E  •  continuar"
	_texto_dica_label.anchor_right = 1.0
	_texto_dica_label.anchor_top = 1.0
	_texto_dica_label.anchor_bottom = 1.0
	_texto_dica_label.offset_top = -17.0
	_texto_dica_label.offset_bottom = 0.0
	_texto_dica_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_texto_dica_label.add_theme_font_size_override(
		"font_size",
		11
	)

	_texto_dica_label.add_theme_color_override(
		"font_color",
		Color("666666")
	)

	_texto_dica_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto_dica_label.visible = false

	texto_conteudo.add_child(_texto_dica_label)

	var moldura_botoes := PanelContainer.new()

	moldura_botoes.name = "MolduraTipos"
	moldura_botoes.custom_minimum_size = Vector2(570, 0)
	moldura_botoes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moldura_botoes.size_flags_stretch_ratio = 1.0
	moldura_botoes.mouse_filter = Control.MOUSE_FILTER_IGNORE

	moldura_botoes.add_theme_stylebox_override(
		"panel",
		_style_box(
			Color("f7f8e9"),
			Color("111111"),
			4,
			18
		)
	)

	linha.add_child(moldura_botoes)

	var botoes_margem := MarginContainer.new()

	botoes_margem.add_theme_constant_override(
		"margin_left",
		4
	)

	botoes_margem.add_theme_constant_override(
		"margin_right",
		4
	)

	botoes_margem.add_theme_constant_override(
		"margin_top",
		4
	)

	botoes_margem.add_theme_constant_override(
		"margin_bottom",
		4
	)

	botoes_margem.mouse_filter = Control.MOUSE_FILTER_IGNORE

	moldura_botoes.add_child(botoes_margem)

	var grade := GridContainer.new()

	grade.name = "Tipos"
	grade.columns = 3

	grade.add_theme_constant_override(
		"h_separation",
		3
	)

	grade.add_theme_constant_override(
		"v_separation",
		3
	)

	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	botoes_margem.add_child(grade)

	for i in TIPOS.size():
		var botao := Button.new()

		botao.name = "Tipo%d" % (i + 1)
		botao.text = TIPOS[i]
		botao.focus_mode = Control.FOCUS_NONE
		botao.custom_minimum_size = Vector2(174, 59)
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.size_flags_vertical = Control.SIZE_EXPAND_FILL

		botao.add_theme_font_size_override(
			"font_size",
			25
		)

		botao.tooltip_text = "%d - %s" % [
			i + 1,
			TIPOS[i]
		]

		botao.pressed.connect(
			_on_botao_tipo_pressed.bind(i)
		)

		grade.add_child(botao)
		_botoes.append(botao)

		var cadeado := TextureRect.new()

		cadeado.name = "Cadeado"
		cadeado.texture = LOCK_TEXTURE

		botao.add_child(cadeado)

		cadeado.set_anchors_preset(
			Control.PRESET_CENTER
		)

		cadeado.offset_left = -15.0
		cadeado.offset_top = -15.0
		cadeado.offset_right = 15.0
		cadeado.offset_bottom = 15.0

		cadeado.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cadeado.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cadeado.mouse_filter = Control.MOUSE_FILTER_IGNORE

		_cadeados.append(cadeado)


# -----------------------------------------------------------------------------
# TELA DE DERROTA
# -----------------------------------------------------------------------------

func _criar_tela_derrota() -> void:
	_tela_derrota = Control.new()

	_tela_derrota.name = "TelaDerrota"

	_tela_derrota.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_tela_derrota.mouse_filter = Control.MOUSE_FILTER_STOP
	_tela_derrota.visible = false

	add_child(_tela_derrota)

	var fundo := ColorRect.new()

	fundo.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	fundo.color = Color(
		0.03,
		0.03,
		0.03,
		0.90
	)

	fundo.mouse_filter = Control.MOUSE_FILTER_STOP

	_tela_derrota.add_child(fundo)

	var centro := VBoxContainer.new()

	centro.anchor_left = 0.5
	centro.anchor_right = 0.5
	centro.anchor_top = 0.5
	centro.anchor_bottom = 0.5

	centro.offset_left = -250.0
	centro.offset_right = 250.0
	centro.offset_top = -115.0
	centro.offset_bottom = 115.0

	centro.alignment = BoxContainer.ALIGNMENT_CENTER

	centro.add_theme_constant_override(
		"separation",
		18
	)

	_tela_derrota.add_child(centro)

	var titulo := Label.new()

	titulo.text = "VOCÊ PERDEU"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	titulo.add_theme_font_size_override(
		"font_size",
		44
	)

	titulo.add_theme_color_override(
		"font_color",
		Color("ef5b5b")
	)

	centro.add_child(titulo)

	var subtitulo := Label.new()

	subtitulo.text = "O lixo venceu esta batalha."
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	subtitulo.add_theme_font_size_override(
		"font_size",
		19
	)

	subtitulo.add_theme_color_override(
		"font_color",
		Color("f2f2f2")
	)

	centro.add_child(subtitulo)

	var botao := Button.new()

	botao.text = "RECOMEÇAR"
	botao.custom_minimum_size = Vector2(240, 54)
	botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	botao.focus_mode = Control.FOCUS_ALL

	botao.add_theme_font_size_override(
		"font_size",
		20
	)

	botao.add_theme_stylebox_override(
		"normal",
		_style_box(
			Color("f7f8e9"),
			Color("ffffff"),
			2,
			13
		)
	)

	botao.add_theme_stylebox_override(
		"hover",
		_style_box(
			Color("ffffff"),
			Color("ef5b5b"),
			3,
			13
		)
	)

	botao.add_theme_stylebox_override(
		"pressed",
		_style_box(
			Color("dedfce"),
			Color("ef5b5b"),
			3,
			13
		)
	)

	botao.add_theme_color_override(
		"font_color",
		Color("171717")
	)

	botao.pressed.connect(
		_on_botao_recomecar_pressed
	)

	centro.add_child(botao)


func mostrar_tela_derrota() -> void:
	set_hud_ativa(true)

	if is_instance_valid(_tela_derrota):
		_tela_derrota.visible = true


func esconder_tela_derrota() -> void:
	if is_instance_valid(_tela_derrota):
		_tela_derrota.visible = false


func _on_botao_recomecar_pressed() -> void:
	reiniciar_solicitado.emit()


# -----------------------------------------------------------------------------
# RESET
# -----------------------------------------------------------------------------

func resetar_estado_novo_jogo() -> void:
	_dialogo_ativo = false
	_modo_batalha = false
	_tipo_selecionado = -1
	_progresso_lixo = 0

	for i in _tipos_ativos.size():
		_tipos_ativos[i] = false

	for tipo in TIPOS:
		_progresso_por_tipo[tipo] = 0

	_texto_persistente = texto_inicial

	esconder_dialogo()
	esconder_tela_derrota()

	if is_instance_valid(_transicao_batalha):
		_transicao_batalha.color = Color(
			0,
			0,
			0,
			0
		)

		_transicao_batalha.visible = false
		_transicao_batalha.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_atualizar_progresso_visual()
	_atualizar_botoes()

	set_hud_ativa(false)


# -----------------------------------------------------------------------------
# OUTRAS FUNÇÕES
# -----------------------------------------------------------------------------

func _on_botao_tipo_pressed(indice: int) -> void:
	selecionar_tipo(indice + 1)


func _atualizar_progresso_visual() -> void:
	if is_instance_valid(_progresso_label):
		_progresso_label.text = "%d%%" % _progresso_lixo


func _atualizar_botoes() -> void:
	for i in _botoes.size():
		var botao := _botoes[i]

		var ativo := _tipos_ativos[i]

		var selecionado := (
			ativo
			and i == _tipo_selecionado
		)

		var cor_base := CORES[i]

		var cor_borda := (
			Color("f7f8e9")
			if selecionado
			else Color("b8b39b")
		)

		var largura_borda := (
			4
			if selecionado
			else 2
		)

		botao.disabled = not ativo
		_cadeados[i].visible = not ativo

		botao.add_theme_stylebox_override(
			"normal",
			_style_box(
				cor_base,
				cor_borda,
				largura_borda,
				15
			)
		)

		botao.add_theme_stylebox_override(
			"hover",
			_style_box(
				cor_base.lightened(0.09),
				Color("f7f8e9"),
				4,
				15
			)
		)

		botao.add_theme_stylebox_override(
			"pressed",
			_style_box(
				cor_base.darkened(0.09),
				Color("ffffff"),
				4,
				15
			)
		)

		botao.add_theme_stylebox_override(
			"disabled",
			_style_box(
				cor_base.darkened(0.16),
				Color("b8b39b"),
				2,
				15
			)
		)

		botao.add_theme_color_override(
			"font_color",
			CORES_TEXTO[i]
		)

		botao.add_theme_color_override(
			"font_hover_color",
			CORES_TEXTO[i]
		)

		botao.add_theme_color_override(
			"font_pressed_color",
			CORES_TEXTO[i]
		)

		botao.add_theme_color_override(
			"font_disabled_color",
			CORES_TEXTO[i].darkened(0.28)
		)


func _resolver_indice_tipo(tipo: Variant) -> int:
	if tipo is int:
		var numero := int(tipo)

		if (
			numero >= 1
			and numero <= TIPOS.size()
		):
			return numero - 1

		return -1

	if tipo is String:
		var procurado := _normalizar_nome(
			str(tipo)
		)

		for i in TIPOS.size():
			if _normalizar_nome(TIPOS[i]) == procurado:
				return i

	return -1


func _normalizar_nome(valor: String) -> String:
	var resultado := valor.to_lower()

	resultado = resultado.replace("á", "a")
	resultado = resultado.replace("à", "a")
	resultado = resultado.replace("ã", "a")
	resultado = resultado.replace("â", "a")
	resultado = resultado.replace("é", "e")
	resultado = resultado.replace("ê", "e")
	resultado = resultado.replace("í", "i")
	resultado = resultado.replace("ó", "o")
	resultado = resultado.replace("ô", "o")
	resultado = resultado.replace("õ", "o")
	resultado = resultado.replace("ú", "u")
	resultado = resultado.replace("ç", "c")

	return resultado.strip_edges()


func _primeiro_tipo_ativo() -> int:
	for i in _tipos_ativos.size():
		if _tipos_ativos[i]:
			return i

	return -1


func _style_box(
	cor_fundo: Color,
	cor_borda: Color,
	largura_borda: int,
	raio: int
) -> StyleBoxFlat:

	var estilo := StyleBoxFlat.new()

	estilo.bg_color = cor_fundo
	estilo.border_color = cor_borda

	estilo.border_width_left = largura_borda
	estilo.border_width_top = largura_borda
	estilo.border_width_right = largura_borda
	estilo.border_width_bottom = largura_borda

	estilo.corner_radius_top_left = raio
	estilo.corner_radius_top_right = raio
	estilo.corner_radius_bottom_left = raio
	estilo.corner_radius_bottom_right = raio

	return estilo
