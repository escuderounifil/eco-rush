# HUD + diálogo do Velho

## Como funciona

1. A HUD começa escondida e com os 6 tipos de lixo bloqueados.
2. Ao chegar perto do Velho aparece **[E] Conversar**.
3. Pressione **E** para iniciar o diálogo.
4. Elias fica parado e a câmera dá zoom no ponto entre Elias e o Velho.
5. O diálogo aparece dentro da caixa inferior esquerda da HUD (a mesma área usada pela missão) e mostra claramente **VELHO** ou **ELIAS** como falante.
6. Pressione **E** durante uma fala para completar o texto imediatamente; pressione novamente para avançar.
7. Durante a fala em que o Velho entrega o poder, somente **Eletrônico** é desbloqueado.
8. No fim do diálogo, o zoom volta ao normal e Elias pode andar novamente.
9. Conversar novamente com o Velho não bloqueia de novo os poderes já conquistados.

## Onde editar o diálogo

Arquivo:

`Scripts/velho.gd`

Edite o array `DIALOGO_MISSAO`.

Cada fala usa:

```gdscript
{
	"falante": "VELHO",
	"texto": "Texto aqui."
}
```

Para disparar o desbloqueio do eletrônico após uma fala:

```gdscript
{
	"falante": "VELHO",
	"texto": "Vou liberar o poder de coleta de lixo eletrônico.",
	"evento": "desbloquear_eletronico"
}
```

## Ajustes rápidos

No começo de `Scripts/velho.gd`:

```gdscript
const DISTANCIA_INTERACAO: float = 155.0
const VELOCIDADE_TEXTO: float = 0.018
const ZOOM_DIALOGO: float = 1.65
```

- `DISTANCIA_INTERACAO`: distância para aparecer `[E] Conversar`.
- `VELOCIDADE_TEXTO`: tempo entre cada letra.
- `ZOOM_DIALOGO`: intensidade do zoom durante a conversa.

## Funções novas da HUD

```gdscript
HUD.bloquear_todos_tipos()
HUD.desbloquear_todos_tipos()
HUD.mostrar_dialogo("VELHO", "Texto")
HUD.atualizar_texto_dialogo("Texto")
HUD.esconder_dialogo()
HUD.set_dialogo_ativo(true)
HUD.set_dialogo_ativo(false)
```

As funções anteriores da HUD continuam funcionando normalmente.

## Ajustes de comportamento

- Depois que um diálogo com o Velho termina, a HUD permanece aberta enquanto Elias estiver próximo dele e fecha automaticamente assim que Elias sai da distância de interação.
- Falas longas são paginadas automaticamente para caber na caixa inferior sem alterar a altura da HUD.
- A área de diálogo possui altura fixa: nome do falante, fala e indicador `E • continuar` não empurram a barra inferior para baixo.
