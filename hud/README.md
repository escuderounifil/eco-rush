# HUD - EcoRush

A HUD fica toda dentro de `res://hud/` e já foi registrada como **Autoload/Singleton** no `project.godot` com o nome global `HUD`.

Ela começa fechada. Pressione `B` ou chame `HUD.ativar_hud()` para mostrar.

## Controles prontos

- `B`: abre/fecha toda a HUD.
- `1`: seleciona Eletrônico.
- `2`: seleciona Plástico.
- `3`: seleciona Metal.
- `4`: seleciona Orgânico.
- `5`: seleciona Papel.
- `6`: seleciona Vidro.
- Um tipo bloqueado não responde nem ao clique nem à tecla numérica e exibe o cadeado.

Estado inicial: **todos os tipos bloqueados**. No primeiro diálogo com o Velho, apenas **Eletrônico** é desbloqueado.

## Uso em qualquer script do jogo

Como a HUD é Singleton, não precisa buscar o nó na cena. Basta chamar `HUD` diretamente:

```gdscript
HUD.ativar_hud()
HUD.desativar_hud()
HUD.alternar_hud()

HUD.mudar_texto("Novo texto da missão")

HUD.definir_progresso_lixo(40)      # vai diretamente para 40%
HUD.aumentar_progresso_lixo(10)    # soma 10%
HUD.diminuir_progresso_lixo(5)     # reduz 5%

HUD.ativar_tipo("Plástico")
HUD.desativar_tipo("Orgânico")
HUD.set_tipo_ativo("Metal", true)

# Também pode usar os números 1..6:
HUD.ativar_tipo(5)                  # desbloqueia Papel
HUD.selecionar_tipo(5)              # seleciona Papel, se estiver desbloqueado
```

O progresso sempre fica automaticamente limitado entre `0%` e `100%`.

## Sinais

```gdscript
HUD.tipo_lixo_selecionado.connect(_quando_tipo_mudar)
HUD.progresso_lixo_alterado.connect(_quando_progresso_mudar)
HUD.hud_visibilidade_alterada.connect(_quando_hud_abrir_ou_fechar)
```

Exemplo:

```gdscript
func _quando_tipo_mudar(tipo: String, numero: int) -> void:
	print("Selecionado: ", tipo, " / tecla: ", numero)
```

## Arquivos da pasta

- `hud.gd`: toda a lógica, construção visual, atalhos e API pública.
- `hud.tscn`: cena opcional para visualizar/reutilizar manualmente a HUD (não precisa ser instanciada porque o projeto usa Autoload).
- `lock.svg`: ícone do cadeado.
- `trash.svg`: ícone da lixeira/progresso.

## Diálogo do Velho

O primeiro diálogo do Velho está em `Scripts/velho.gd`. Ao pressionar `E` perto dele, a HUD abre com todos os tipos bloqueados; durante a conversa o Eletrônico é liberado. O jogador é travado, a câmera foca Elias + Velho e volta ao normal no fim.

Funções adicionadas à HUD:

```gdscript
HUD.bloquear_todos_tipos()
HUD.desbloquear_todos_tipos()
HUD.mostrar_dialogo("VELHO", "Texto")
HUD.atualizar_texto_dialogo("Texto")
HUD.esconder_dialogo()
HUD.set_dialogo_ativo(true)
```
