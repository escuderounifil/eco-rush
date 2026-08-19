extends Area2D


@onready var label_interacao: Label = $LabelInteragir
@onready var caixa_dialogo: Label = $CanvasLayer/CaixaDialogo
@onready var texto_dialogo: Label = $CanvasLayer/TextoDialogo


var player_in_area: bool = false
var falando: bool = false
var pode_avancar: bool = false
var fala_index: int = 0

var texto_atual: String = ""
var id_texto: int = 0


var falas: Array[String] = [
	"Testando 123",
	"Ola Elias Lixeiro",
	"Sou um velho coitado que vive com tanto lixo espalhado nesse mundo!"
]


func _ready() -> void:
	caixa_dialogo.visible = false
	texto_dialogo.visible = false
	label_interacao.visible = false


func _physics_process(_delta: float) -> void:

	# Verifica diretamente quem está dentro do Area2D
	var jogador_dentro: bool = false

	for body in get_overlapping_bodies():
		if body.name == "Player":
			jogador_dentro = true
			break


	# Jogador acabou de entrar
	if jogador_dentro and not player_in_area:

		player_in_area = true

		if not falando:
			label_interacao.text = "Pressione 'E' para interagir!"
			label_interacao.visible = true


	# Jogador acabou de sair
	elif not jogador_dentro and player_in_area:

		player_in_area = false

		label_interacao.visible = false

		if falando:
			encerrar_dialogo()


	# Atualiza o estado
	player_in_area = jogador_dentro


	# Interação
	if player_in_area and not falando:

		if Input.is_action_just_pressed("interact"):
			iniciar_dialogo()


	# Durante o diálogo
	elif falando:

		if Input.is_action_just_pressed("interact"):

			if not pode_avancar:
				completar_fala()
			else:
				proxima_fala()


func iniciar_dialogo() -> void:

	falando = true
	pode_avancar = false
	fala_index = 0

	label_interacao.visible = false

	caixa_dialogo.visible = true
	texto_dialogo.visible = true

	proxima_fala()


func proxima_fala() -> void:

	if fala_index < falas.size():

		pode_avancar = false

		texto_dialogo.text = ""

		texto_atual = falas[fala_index]

		fala_index += 1

		mostrar_texto_efeito(texto_atual)

	else:

		encerrar_dialogo()


func mostrar_texto_efeito(texto: String) -> void:

	id_texto += 1

	var meu_id: int = id_texto

	pode_avancar = false
	texto_dialogo.text = ""

	await get_tree().create_timer(0.1).timeout

	if not falando or meu_id != id_texto:
		return

	for letra in texto:

		if not falando or meu_id != id_texto:
			return

		texto_dialogo.text += letra

		await get_tree().create_timer(0.002).timeout

	if falando and meu_id == id_texto:
		pode_avancar = true


func completar_fala() -> void:

	id_texto += 1

	texto_dialogo.text = texto_atual

	pode_avancar = true


func encerrar_dialogo() -> void:

	id_texto += 1

	falando = false
	pode_avancar = false

	texto_atual = ""

	texto_dialogo.text = ""

	texto_dialogo.visible = false
	caixa_dialogo.visible = false

	label_interacao.visible = false
