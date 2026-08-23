extends Node2D
class_name EcoBattleManager

## Controla todos os encontros de lixo do mapa e o sistema de turnos.

@onready var som_ataque: AudioStreamPlayer = $"../SomAtaque"

@onready var som_eletronico: AudioStreamPlayer = $"../SomAtaqueEletronico"
@onready var som_plastico: AudioStreamPlayer = $"../SomAtaquePlastico"
@onready var som_metal: AudioStreamPlayer = $"../SomAtaqueMetal"
@onready var som_organico: AudioStreamPlayer = $"../SomAtaqueOrganico"
@onready var som_papel: AudioStreamPlayer = $"../SomAtaquePapel"
@onready var som_vidro: AudioStreamPlayer = $"../SomAtaqueVidro"

@onready var som_game_over: AudioStreamPlayer = $"../SomGameOver"
@onready var som_vitoria: AudioStreamPlayer = $"../SomVitoria"

@onready var musica: AudioStreamPlayer = $"../Musica"

const BattlePointScript = preload("res://battle/battle_point.gd")

const DISTANCIA_INTERACAO: float = 125.0
const ZOOM_BATALHA: float = 1.85
const VIDA_MAX_ELIAS: int = 100
const VIDA_MAX_LIXO: int = 100
const DANO_ELIAS: int = 34
const DANO_LIXO: int = 30
const TEMPO_ENTRE_ATAQUES: float = 2.0
const COR_MARCADOR: Color = Color("d8aa3d")

const TIPOS: Array[String] = [
	"Eletrônico",
	"Plástico",
	"Metal",
	"Orgânico",
	"Papel",
	"Vidro"
]

const CORES: Dictionary = {
	"Eletrônico": Color("c83d42"),
	"Plástico": Color("ac765d"),
	"Metal": Color("827a58"),
	"Orgânico": Color("353535"),
	"Papel": Color("3f627d"),
	"Vidro": Color("3e733d")
}

# Três batalhas de cada material.
const PONTOS_BATALHA: Array[Dictionary] = [
	{"tipo": "Eletrônico",
	 "nome": "Celular quebrado", 
	 "pos": Vector2(640, 96), 
	 "sprite":preload("res://Assets/monstros/celular-quebrado.png")
	},
	{"tipo": "Eletrônico",
	 "nome": "Teclado velho",
	 "pos": Vector2(1056, 352),
	 "sprite":preload("res://Assets/monstros/teclado-antigo.png")
	},
	{"tipo": "Eletrônico",
	 "nome": "Carregador queimado",
	 "pos": Vector2(1504, 704),
	"sprite": preload("res://Assets/monstros/carregador-queimado.png")
	},

	{"tipo": "Plástico",
	 "nome": "Garrafa PET",
	 "pos": Vector2(1792, 256),
	 "sprite": preload("res://Assets/monstros/garrafa.png")
	},
	{"tipo": "Plástico",
	 "nome": "Sacola plástica",
	 "pos": Vector2(1696, 896),
	 "sprite": preload("res://Assets/monstros/sacola.png")
	},
	{"tipo": "Plástico",
	 "nome": "Pote de plástico",
	 "pos": Vector2(1200, 1072),
	 "sprite": preload("res://Assets/monstros/pote.png")
	},

	{"tipo": "Metal",
	 "nome": "Lata de alumínio",
	 "pos": Vector2(896, 816),
	 "sprite": preload("res://Assets/monstros/lata.png")
	},
	{"tipo": "Metal",
	 "nome": "Panela velha",
	 "pos": Vector2(-48, 1104),
	 "sprite": preload("res://Assets/monstros/panela-velha.png")
	},
	{"tipo": "Metal",
	 "nome": "Tampa de lixo",
	 "pos": Vector2(-304, 896),
	 "sprite": preload("res://Assets/monstros/tampa-lixo.png")
	},

	{"tipo": "Orgânico",
	 "nome": "Casca de banana",
	 "pos": Vector2(-496, 1200)},
	{"tipo": "Orgânico",
	 "nome": "Restos de comida",
	 "pos": Vector2(-896, 1152)},
	{"tipo": "Orgânico",
	 "nome": "Folhas secas",
	 "pos": Vector2(-1296, 1136)},

	{"tipo": "Papel",
	 "nome": "Jornal velho",
	 "pos": Vector2(-1600, 896)},
	{"tipo": "Papel",
	 "nome": "Caixa de papelão",
	 "pos": Vector2(-1792, 1200)},
	{"tipo": "Papel",
	 "nome": "Folha de caderno",
	 "pos": Vector2(-1520, 784)},

	{"tipo": "Vidro",
	 "nome": "Garrafa de vidro",
	 "pos": Vector2(-304, 608)},
	{"tipo": "Vidro",
	 "nome": "Pote de vidro",
	 "pos": Vector2(96, 560)},
	{"tipo": "Vidro",
	 "nome": "Caco de vidro",
	 "pos": Vector2(-96, 352)}
]

var player: CharacterBody2D = null
var _pontos: Array[Node2D] = []
var _ponto_proximo: Node2D = null
var _ponto_atual: Node2D = null

var _batalha_ativa: bool = false
var _derrota_ativa: bool = false
var _turno_jogador: bool = false
var _vida_elias: int = VIDA_MAX_ELIAS
var _vida_lixo: int = VIDA_MAX_LIXO
var _token_turno: int = 0
var _hud_aberta_por_ponto_bloqueado: bool = false

var _coletas: Dictionary = {
	"Eletrônico": 0,
	"Plástico": 0,
	"Metal": 0,
	"Orgânico": 0,
	"Papel": 0,
	"Vidro": 0
}


func _ready() -> void:
	_criar_pontos()
	call_deferred("_buscar_player")

	if not HUD.tipo_lixo_selecionado.is_connected(_on_tipo_lixo_selecionado):
		HUD.tipo_lixo_selecionado.connect(_on_tipo_lixo_selecionado)

	if not HUD.reiniciar_solicitado.is_connected(_on_reiniciar_solicitado):
		HUD.reiniciar_solicitado.connect(_on_reiniciar_solicitado)

	# Garante o estado 0/33/66/100 para cada material.
	for tipo in TIPOS:
		HUD.definir_progresso_tipo(tipo, 0)


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		_buscar_player()
		return

	if _batalha_ativa or _derrota_ativa or HUD.dialogo_esta_ativo():
		_esconder_labels_pontos()
		return

	_atualizar_ponto_proximo()

	if _hud_aberta_por_ponto_bloqueado and _ponto_proximo == null:
		HUD.desativar_hud()
		_hud_aberta_por_ponto_bloqueado = false


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var tecla := event as InputEventKey

	if not tecla.pressed or tecla.echo:
		return

	var codigo := tecla.physical_keycode

	if codigo == KEY_NONE:
		codigo = tecla.keycode

	if codigo != KEY_B:
		return

	# Em diálogo, derrota ou batalha o B não fecha a HUD e não inicia outro encontro.
	if HUD.dialogo_esta_ativo() or _derrota_ativa:
		get_viewport().set_input_as_handled()
		return

	if _batalha_ativa:
		get_viewport().set_input_as_handled()
		return

	if is_instance_valid(_ponto_proximo):
		get_viewport().set_input_as_handled()
		_tentar_iniciar_batalha(_ponto_proximo)


func _criar_pontos() -> void:
	var numero_por_tipo: Dictionary = {}

	for tipo in TIPOS:
		numero_por_tipo[tipo] = 0

	for dados in PONTOS_BATALHA:
		var tipo := str(dados.get("tipo", ""))
		var nome_lixo := str(dados.get("nome", "Lixo"))
		var posicao: Vector2 = dados.get("pos", Vector2.ZERO)

		# NOVO
		var sprite_lixo: Texture2D = dados.get("sprite")

		numero_por_tipo[tipo] = int(numero_por_tipo.get(tipo, 0)) + 1

		var ponto: Node2D = BattlePointScript.new()

		ponto.name = "Lixo_%s_%d" % [
			_nome_seguro(tipo),
			int(numero_por_tipo[tipo])
		]

		ponto.position = posicao

		add_child(ponto)

		ponto.call(
			"configurar",
			tipo,
			nome_lixo,
			int(numero_por_tipo[tipo]),
			COR_MARCADOR,
			sprite_lixo
		)

		_pontos.append(ponto)


func _atualizar_ponto_proximo() -> void:
	var melhor: Node2D = null
	var melhor_distancia := INF
	var pos_player := _posicao_visual_player()

	for ponto in _pontos:
		if not is_instance_valid(ponto) or bool(ponto.get("concluido")):
			continue

		var distancia := pos_player.distance_to(ponto.global_position)

		if distancia <= DISTANCIA_INTERACAO and distancia < melhor_distancia:
			melhor = ponto
			melhor_distancia = distancia

	_ponto_proximo = melhor

	for ponto in _pontos:
		if not is_instance_valid(ponto):
			continue

		var eh_proximo := ponto == _ponto_proximo
		var tipo := str(ponto.get("tipo_lixo"))

		ponto.call(
			"set_player_proximo",
			eh_proximo,
			HUD.tipo_esta_ativo(tipo)
		)


func _esconder_labels_pontos() -> void:
	_ponto_proximo = null

	for ponto in _pontos:
		if is_instance_valid(ponto):
			ponto.call("set_player_proximo", false, false)


func _tentar_iniciar_batalha(ponto: Node2D) -> void:
	if not is_instance_valid(ponto):
		return

	var tipo := str(ponto.get("tipo_lixo"))

	if not HUD.tipo_esta_ativo(tipo):
		HUD.ativar_hud()
		HUD.mudar_texto(
			"Você ainda não tem a lixeira necessária para coletar este lixo."
		)

		HUD.mostrar_progresso_tipo(tipo)

		_hud_aberta_por_ponto_bloqueado = true
		return

	_iniciar_batalha(ponto)


func _iniciar_batalha(ponto: Node2D) -> void:
	if _batalha_ativa or not is_instance_valid(player):
		return

	_batalha_ativa = true

	# Para a música do mapa quando começa a batalha.
	if is_instance_valid(musica):
		musica.stop()

	_derrota_ativa = false
	_turno_jogador = true
	_token_turno += 1
	_ponto_atual = ponto

	_vida_elias = VIDA_MAX_ELIAS
	_vida_lixo = VIDA_MAX_LIXO
	_hud_aberta_por_ponto_bloqueado = false

	var tipo := str(ponto.get("tipo_lixo"))
	var nome_lixo := str(ponto.get("nome_lixo"))

	HUD.ativar_hud()
	HUD.set_modo_batalha(true)

	HUD.esconder_batalha()
	HUD.mostrar_progresso_tipo(tipo)

	HUD.mudar_texto(
		"BATALHA! Classifique '%s' clicando no material correto." % nome_lixo
	)

	player.set_movimento_bloqueado(true)
	player.mostrar_barra_vida_batalha(_vida_elias)

	ponto.call("mostrar_barra_vida", _vida_lixo)

	var centro := (
		_posicao_visual_player() +
		ponto.global_position
	) * 0.5

	player.iniciar_foco_batalha(centro, ZOOM_BATALHA)

	_esconder_labels_pontos()


func _on_tipo_lixo_selecionado(tipo: String, _numero: int) -> void:
	if not _batalha_ativa or _derrota_ativa or not _turno_jogador:
		return

	if not is_instance_valid(_ponto_atual):
		return

	_turno_jogador = false
	_token_turno += 1

	var meu_token := _token_turno
	var correto := str(_ponto_atual.get("tipo_lixo"))

	if tipo != correto:
		HUD.mudar_texto(
			"Tipo errado! O lixo prepara um ataque certeiro..."
		)

		_atacar_elias(true)
		return

	HUD.mudar_texto("Acertou! Elias prepara o ataque...")

	await get_tree().create_timer(TEMPO_ENTRE_ATAQUES).timeout

	if meu_token != _token_turno:
		return

	if not _batalha_ativa or not is_instance_valid(_ponto_atual):
		return

	_vida_lixo = maxi(0, _vida_lixo - DANO_ELIAS)

	# Som do ataque do Elias.
	if is_instance_valid(som_ataque):
		som_ataque.play()

	_ponto_atual.call("atualizar_barra_vida", _vida_lixo)
	_ponto_atual.call("animar_dano")

	if _vida_lixo <= 0:
		HUD.mudar_texto("Ataque certeiro! O lixo foi derrotado.")
		_vencer_batalha()
		return

	HUD.mudar_texto(
		"Ataque concluído. Agora o lixo prepara o contra-ataque..."
	)

	_atacar_elias(false)


func _atacar_elias(ataque_letal: bool) -> void:
	if not _batalha_ativa:
		return

	var meu_token := _token_turno

	# O ataque do lixo leva 2 segundos antes de causar dano.
	await get_tree().create_timer(TEMPO_ENTRE_ATAQUES).timeout

	if meu_token != _token_turno:
		return

	if not _batalha_ativa:
		return

	# Som diferente de acordo com o tipo de lixo.
	_tocar_som_ataque_lixo()

	if ataque_letal:
		_vida_elias = 0
	else:
		_vida_elias = maxi(0, _vida_elias - DANO_LIXO)

	if is_instance_valid(player):
		player.atualizar_barra_vida_batalha(_vida_elias)

	if _vida_elias <= 0:
		HUD.mudar_texto(
			"O lixo acertou Elias. Você perdeu a batalha."
		)

		await get_tree().create_timer(0.8).timeout

		if _batalha_ativa:
			_perder_batalha()

		return

	_turno_jogador = true

	HUD.mudar_texto(
		"SEU TURNO! Clique no material correto para atacar."
	)


func _tocar_som_ataque_lixo() -> void:
	if not is_instance_valid(_ponto_atual):
		return

	var tipo := str(_ponto_atual.get("tipo_lixo"))

	match tipo:
		"Eletrônico":
			if is_instance_valid(som_eletronico):
				som_eletronico.play()

		"Plástico":
			if is_instance_valid(som_plastico):
				som_plastico.play()

		"Metal":
			if is_instance_valid(som_metal):
				som_metal.play()

		"Orgânico":
			if is_instance_valid(som_organico):
				som_organico.play()

		"Papel":
			if is_instance_valid(som_papel):
				som_papel.play()

		"Vidro":
			if is_instance_valid(som_vidro):
				som_vidro.play()


func _vencer_batalha() -> void:
	if not _batalha_ativa or not is_instance_valid(_ponto_atual):
		return

	# Som de vitória.
	if is_instance_valid(som_vitoria):
		som_vitoria.play()

	_token_turno += 1
	_turno_jogador = false

	var tipo := str(_ponto_atual.get("tipo_lixo"))

	_ponto_atual.call("marcar_concluido")

	var quantidade := clampi(
		int(_coletas.get(tipo, 0)) + 1,
		0,
		3
	)

	_coletas[tipo] = quantidade

	var percentual := _percentual_por_quantidade(quantidade)

	HUD.definir_progresso_tipo(tipo, percentual)
	HUD.mostrar_progresso_tipo(tipo)

	if percentual >= 100:
		if tipo == TIPOS[TIPOS.size() - 1]:
			HUD.mudar_texto(
				"%s concluído: 100%%! Volte ao Velho para entregar a última coleta."
				% tipo
			)
		else:
			HUD.mudar_texto(
				"%s concluído: 100%%! Volte ao Velho para entregar e liberar a próxima lixeira."
				% tipo
			)
	else:
		HUD.mudar_texto(
			"%s coletado: %d%%. Restam %d batalhas desse material."
			% [tipo, percentual, 3 - quantidade]
		)

	await get_tree().create_timer(1.1).timeout

	_encerrar_batalha_vitoriosa()


func _encerrar_batalha_vitoriosa() -> void:
	if not _batalha_ativa:
		return

	_batalha_ativa = false
	_turno_jogador = false
	_ponto_atual = null

	HUD.esconder_batalha()
	HUD.set_modo_batalha(false)
	HUD.desativar_hud()

	if is_instance_valid(player):
		player.esconder_barra_vida_batalha()
		player.encerrar_foco_batalha()
		player.set_movimento_bloqueado(false)

	# Volta a música do mapa depois da vitória.
	if is_instance_valid(musica):
		musica.play()


func _perder_batalha() -> void:
	if not _batalha_ativa:
		return

	_token_turno += 1
	_batalha_ativa = false
	_derrota_ativa = true
	_turno_jogador = false

	if is_instance_valid(_ponto_atual):
		_ponto_atual.call("esconder_barra_vida")

	if is_instance_valid(player):
		player.esconder_barra_vida_batalha()
		player.set_movimento_bloqueado(true)

	# Som de Game Over.
	if is_instance_valid(som_game_over):
		som_game_over.play()

	HUD.mostrar_tela_derrota()


func _on_reiniciar_solicitado() -> void:
	if not _derrota_ativa:
		return

	_derrota_ativa = false
	_batalha_ativa = false
	_turno_jogador = false
	_ponto_atual = null

	HUD.resetar_estado_novo_jogo()
	get_tree().reload_current_scene()


func _percentual_por_quantidade(quantidade: int) -> int:
	match clampi(quantidade, 0, 3):
		0:
			return 0

		1:
			return 33

		2:
			return 66

		_:
			return 100


func obter_coletas(tipo: String) -> int:
	return int(_coletas.get(tipo, 0))


func obter_percentual(tipo: String) -> int:
	return _percentual_por_quantidade(
		obter_coletas(tipo)
	)


func _buscar_player() -> void:
	var cena := get_tree().current_scene

	if cena == null:
		return

	var candidato := cena.get_node_or_null("Player")

	if candidato is CharacterBody2D:
		player = candidato as CharacterBody2D
		return

	var encontrado := cena.find_child("Player", true, false)

	if encontrado is CharacterBody2D:
		player = encontrado as CharacterBody2D


func _posicao_visual_player() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO

	var sprite: Node2D = player.get_node_or_null(
		"AnimatedSprite2D"
	) as Node2D

	if sprite != null:
		return sprite.global_position

	return player.global_position


func _nome_seguro(valor: String) -> String:
	var nome := valor.to_lower()

	nome = nome.replace("á", "a").replace("à", "a").replace("ã", "a").replace("â", "a")
	nome = nome.replace("é", "e").replace("ê", "e").replace("í", "i")
	nome = nome.replace("ó", "o").replace("ô", "o").replace("õ", "o")
	nome = nome.replace("ú", "u").replace("ç", "c")

	return nome.replace(" ", "_")
