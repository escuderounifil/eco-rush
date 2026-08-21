extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const DISTANCIA_INTERACAO: float = 155.0
const VELOCIDADE_TEXTO: float = 0.018
const ZOOM_DIALOGO: float = 1.65

const TIPOS_PROGRESSAO: Array[String] = [
	"Eletrônico",
	"Plástico",
	"Metal",
	"Orgânico",
	"Papel",
	"Vidro"
]

const NOMES_COLETA: Dictionary = {
	"Eletrônico": "eletrônicos",
	"Plástico": "plásticos",
	"Metal": "metais",
	"Orgânico": "orgânicos",
	"Papel": "papéis",
	"Vidro": "vidros"
}

const DIALOGO_MISSAO: Array[Dictionary] = [
	{
		"falante": "VELHO",
		"texto": "Elias! Finalmente você chegou. Seja bem-vindo à nossa cidade."
	},
	{
		"falante": "ELIAS",
		"texto": "Obrigado! Mas... o que aconteceu aqui? Tem lixo por toda parte."
	},
	{
		"falante": "VELHO",
		"texto": "É exatamente por isso que eu precisava de você. A cidade inteira está sendo tomada pelo lixo."
	},
	{
		"falante": "VELHO",
		"texto": "Sua missão é limpar toda a cidade, rua por rua, até não restar mais nada espalhado."
	},
	{
		"falante": "ELIAS",
		"texto": "Pode deixar comigo. Só preciso saber por onde começar."
	},
	{
		"falante": "VELHO",
		"texto": "Começaremos aos poucos. Para sua primeira habilidade, vou lhe dar o poder da coleta de lixo eletrônico.",
		"evento": "desbloquear_eletronico"
	},
	{
		"falante": "VELHO",
		"texto": "Colete os três eletrônicos espalhados pela cidade. Quando chegar a 100%, volte aqui e entregue a coleta para mim."
	},
	{
		"falante": "ELIAS",
		"texto": "Entendido. Vou começar pelos eletrônicos e volto quando terminar!"
	}
]

const DIALOGO_FINALIZADO: Array[Dictionary] = [
	{
		"falante": "VELHO",
		"texto": "A cidade continua limpa graças a você, Elias. Excelente trabalho!"
	},
	{
		"falante": "ELIAS",
		"texto": "Missão cumprida!"
	}
]

var player: CharacterBody2D = null
var battle_manager: Node = null
var label_interacao: Label

var player_proximo: bool = false
var falando: bool = false
var fala_index: int = 0
var fala_completa: bool = false
var missao_entregue: bool = false
var _missao_finalizada: bool = false
var _indice_poder_atual: int = 0
var _dialogo_atual: Array[Dictionary] = []
var _token_texto: int = 0
var _evento_fala_executado: bool = false
var _dialogo_eh_missao: bool = false
var _fechar_hud_ao_sair: bool = false
var _tipo_para_desbloquear: String = ""


func _ready() -> void:
	play_idle()
	_criar_label_interacao()
	call_deferred("_buscar_player")
	call_deferred("_buscar_battle_manager")


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		_buscar_player()
		return
	if not is_instance_valid(battle_manager):
		_buscar_battle_manager()

	var distancia := _posicao_visual_player().distance_to(animated_sprite.global_position)
	player_proximo = distancia <= DISTANCIA_INTERACAO

	# Depois que a conversa termina, a HUD fica aberta enquanto Elias ainda
	# está ao lado do Velho. Assim que ele se afasta, ela minimiza sozinha.
	if _fechar_hud_ao_sair and not falando and not player_proximo:
		HUD.desativar_hud()
		_fechar_hud_ao_sair = false

	if is_instance_valid(label_interacao):
		label_interacao.visible = player_proximo and not falando and not HUD.batalha_esta_ativa()
		if label_interacao.visible:
			_atualizar_texto_interacao()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var tecla := event as InputEventKey
	if not tecla.pressed or tecla.echo:
		return

	var codigo := tecla.physical_keycode
	if codigo == KEY_NONE:
		codigo = tecla.keycode

	if codigo != KEY_E:
		return

	if HUD.batalha_esta_ativa():
		return

	if falando:
		_avancar_dialogo()
		get_viewport().set_input_as_handled()
	elif player_proximo:
		iniciar_dialogo()
		get_viewport().set_input_as_handled()


func play_idle() -> void:
	animated_sprite.play("down-idle")


func iniciar_dialogo() -> void:
	if falando or not is_instance_valid(player) or HUD.batalha_esta_ativa():
		return

	if not is_instance_valid(battle_manager):
		_buscar_battle_manager()

	falando = true
	_fechar_hud_ao_sair = false
	fala_index = 0
	fala_completa = false
	_token_texto += 1
	_tipo_para_desbloquear = ""

	_dialogo_eh_missao = not missao_entregue
	if _dialogo_eh_missao:
		_dialogo_atual = DIALOGO_MISSAO
		# Primeiro encontro: começa realmente do zero.
		HUD.bloquear_todos_tipos()
		HUD.definir_progresso_lixo(0)
		HUD.mudar_texto("Missão: limpe toda a cidade!")
	elif _missao_finalizada:
		_dialogo_atual = DIALOGO_FINALIZADO
	elif _material_atual_concluido():
		if _indice_poder_atual < TIPOS_PROGRESSAO.size() - 1:
			var tipo_atual := TIPOS_PROGRESSAO[_indice_poder_atual]
			_tipo_para_desbloquear = TIPOS_PROGRESSAO[_indice_poder_atual + 1]
			_dialogo_atual = _criar_dialogo_entrega(tipo_atual, _tipo_para_desbloquear)
		else:
			_dialogo_atual = _criar_dialogo_final()
	else:
		_dialogo_atual = _criar_dialogo_retorno()

	HUD.ativar_hud()
	HUD.set_dialogo_ativo(true)

	player.set_movimento_bloqueado(true)
	player.olhar_para(animated_sprite.global_position)

	var centro := (animated_sprite.global_position + _posicao_visual_player()) * 0.5
	player.iniciar_foco_dialogo(centro, ZOOM_DIALOGO)

	if is_instance_valid(label_interacao):
		label_interacao.visible = false

	_mostrar_fala_atual()


func _criar_dialogo_entrega(tipo_atual: String, proximo_tipo: String) -> Array[Dictionary]:
	var atual := _nome_coleta(tipo_atual)
	var proximo := _nome_coleta(proximo_tipo)
	var dialogo: Array[Dictionary] = []
	dialogo.append({
		"falante": "ELIAS",
		"texto": "Terminei a coleta de %s. Trouxe tudo para você." % atual
	})
	dialogo.append({
		"falante": "VELHO",
		"texto": "Excelente, Elias! Entrega recebida. Mais uma parte da cidade está limpa."
	})
	dialogo.append({
		"falante": "VELHO",
		"texto": "Agora você está pronto para o próximo poder: coleta de %s." % proximo,
		"evento": "desbloquear_proximo"
	})
	dialogo.append({
		"falante": "VELHO",
		"texto": "Colete os três %s, complete 100%% e volte aqui novamente para fazer a entrega." % proximo
	})
	dialogo.append({
		"falante": "ELIAS",
		"texto": "Pode deixar. Vou continuar a limpeza!"
	})
	return dialogo


func _criar_dialogo_retorno() -> Array[Dictionary]:
	var tipo_atual := TIPOS_PROGRESSAO[_indice_poder_atual]
	var coletados := _obter_coletas(tipo_atual)
	var faltam := maxi(0, 3 - coletados)
	var nome := _nome_coleta(tipo_atual)
	var dialogo: Array[Dictionary] = []
	dialogo.append({
		"falante": "VELHO",
		"texto": "Continue a coleta de %s. Ainda faltam %d para completar essa etapa." % [nome, faltam]
	})
	dialogo.append({
		"falante": "VELHO",
		"texto": "Quando o medidor chegar a 100%, volte aqui e entregue a coleta. Só então vou liberar o próximo poder."
	})
	dialogo.append({
		"falante": "ELIAS",
		"texto": "Entendido. Eu volto quando terminar."
	})
	return dialogo


func _criar_dialogo_final() -> Array[Dictionary]:
	var dialogo: Array[Dictionary] = []
	dialogo.append({
		"falante": "ELIAS",
		"texto": "Terminei a coleta de vidros. Essa era a última etapa."
	})
	dialogo.append({
		"falante": "VELHO",
		"texto": "Incrível, Elias. Você devolveu todas as coletas e limpou cada tipo de lixo da cidade."
	})
	dialogo.append({
		"falante": "VELHO",
		"texto": "A cidade está limpa outra vez. Sua missão está concluída!",
		"evento": "concluir_missao"
	})
	dialogo.append({
		"falante": "ELIAS",
		"texto": "Missão cumprida!"
	})
	return dialogo


func _avancar_dialogo() -> void:
	if not falando:
		return

	if not fala_completa:
		_completar_fala_imediatamente()
		return

	fala_index += 1
	if fala_index >= _dialogo_atual.size():
		encerrar_dialogo()
		return

	_mostrar_fala_atual()


func _mostrar_fala_atual() -> void:
	if fala_index < 0 or fala_index >= _dialogo_atual.size():
		encerrar_dialogo()
		return

	_token_texto += 1
	var meu_token := _token_texto
	fala_completa = false
	_evento_fala_executado = false

	var fala := _dialogo_atual[fala_index]
	var falante := str(fala.get("falante", ""))
	var texto := str(fala.get("texto", ""))

	# Envia primeiro a fala completa para a HUD calcular o tamanho ideal da fonte.
	# Em seguida limpa o conteúdo para manter o efeito de digitação.
	HUD.mostrar_dialogo(falante, texto)
	HUD.atualizar_texto_dialogo("")

	for i in texto.length():
		if not falando or meu_token != _token_texto:
			return

		HUD.atualizar_texto_dialogo(texto.substr(0, i + 1))
		await get_tree().create_timer(VELOCIDADE_TEXTO).timeout

	if falando and meu_token == _token_texto:
		HUD.atualizar_texto_dialogo(texto)
		fala_completa = true
		_executar_evento_da_fala()


func _completar_fala_imediatamente() -> void:
	if fala_index < 0 or fala_index >= _dialogo_atual.size():
		return

	_token_texto += 1
	var fala := _dialogo_atual[fala_index]
	HUD.atualizar_texto_dialogo(str(fala.get("texto", "")))
	fala_completa = true
	_executar_evento_da_fala()


func _executar_evento_da_fala() -> void:
	if _evento_fala_executado:
		return

	_evento_fala_executado = true
	if fala_index < 0 or fala_index >= _dialogo_atual.size():
		return

	var evento := str(_dialogo_atual[fala_index].get("evento", ""))
	match evento:
		"desbloquear_eletronico":
			_indice_poder_atual = 0
			HUD.ativar_tipo("Eletrônico")
			HUD.selecionar_tipo("Eletrônico")
			HUD.mudar_texto("Missão: colete os eletrônicos e volte ao Velho em 100%!")
		"desbloquear_proximo":
			if _tipo_para_desbloquear != "":
				var novo_indice := TIPOS_PROGRESSAO.find(_tipo_para_desbloquear)
				if novo_indice != -1:
					_indice_poder_atual = novo_indice
				HUD.ativar_tipo(_tipo_para_desbloquear)
				HUD.selecionar_tipo(_tipo_para_desbloquear)
				HUD.mudar_texto("Missão: colete os %s e volte ao Velho em 100%%!" % _nome_coleta(_tipo_para_desbloquear))
		"concluir_missao":
			_missao_finalizada = true
			HUD.mudar_texto("Missão concluída: toda a cidade foi limpa!")


func encerrar_dialogo() -> void:
	if not falando:
		return

	_token_texto += 1
	falando = false
	fala_completa = false
	HUD.esconder_dialogo()
	HUD.set_dialogo_ativo(false)

	if _dialogo_eh_missao:
		missao_entregue = true

	# Não fecha imediatamente: a HUD permanece visível enquanto Elias estiver
	# perto do Velho e é minimizada automaticamente quando ele se afastar.
	_fechar_hud_ao_sair = true

	if is_instance_valid(player):
		player.encerrar_foco_dialogo()
		player.set_movimento_bloqueado(false)

	if is_instance_valid(label_interacao):
		label_interacao.visible = player_proximo


func _material_atual_concluido() -> bool:
	if not missao_entregue or not is_instance_valid(battle_manager):
		return false
	var tipo_atual := TIPOS_PROGRESSAO[_indice_poder_atual]
	return _obter_coletas(tipo_atual) >= 3


func _obter_coletas(tipo: String) -> int:
	if not is_instance_valid(battle_manager):
		return 0
	if not battle_manager.has_method("obter_coletas"):
		return 0
	return int(battle_manager.call("obter_coletas", tipo))


func _nome_coleta(tipo: String) -> String:
	return str(NOMES_COLETA.get(tipo, tipo.to_lower()))


func _atualizar_texto_interacao() -> void:
	if not is_instance_valid(label_interacao):
		return
	if missao_entregue and not _missao_finalizada and _material_atual_concluido():
		label_interacao.text = "[E] Entregar coleta"
	else:
		label_interacao.text = "[E] Conversar"


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


func _buscar_battle_manager() -> void:
	var cena := get_tree().current_scene
	if cena == null:
		return

	var candidato := cena.get_node_or_null("BattleManager")
	if candidato != null:
		battle_manager = candidato
		return

	var encontrado := cena.find_child("BattleManager", true, false)
	if encontrado != null:
		battle_manager = encontrado


func _posicao_visual_player() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO

	var sprite: Node2D = player.get_node_or_null("AnimatedSprite2D") as Node2D
	if sprite != null:
		return sprite.global_position
	return player.global_position


func _criar_label_interacao() -> void:
	label_interacao = Label.new()
	label_interacao.name = "LabelInteracao"
	label_interacao.text = "[E] Conversar"
	label_interacao.position = animated_sprite.position + Vector2(-58, -88)
	label_interacao.size = Vector2(116, 28)
	label_interacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_interacao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_interacao.add_theme_font_size_override("font_size", 12)
	label_interacao.add_theme_color_override("font_color", Color.WHITE)
	label_interacao.add_theme_color_override("font_outline_color", Color("202020"))
	label_interacao.add_theme_constant_override("outline_size", 5)
	label_interacao.z_index = 10
	label_interacao.visible = false
	add_child(label_interacao)
