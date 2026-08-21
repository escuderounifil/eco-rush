# Sistema de batalha / coleta

A lógica principal fica em `battle/battle_manager.gd` e os pontos do mapa usam `battle/battle_point.gd`.

## Fluxo de progressão

A progressão é feita com o Velho, nesta ordem:

1. Eletrônico
2. Plástico
3. Metal
4. Orgânico
5. Papel
6. Vidro

O Velho libera inicialmente apenas **Eletrônico**. Existem 3 batalhas de cada tipo. Ao vencer as três, o medidor daquele material fica em **100%** e o jogador precisa voltar ao Velho e entregar a coleta. Só depois dessa entrega o próximo tipo é desbloqueado.

O ciclo é sempre:

`coletar 3 -> chegar a 100% -> voltar ao Velho -> entregar -> desbloquear próximo tipo`

Depois dos 3 vidros, Elias volta ao Velho para finalizar a missão.

## Turnos

- Elias e o lixo atacam uma vez cada.
- Cada ataque demora **no mínimo 3 segundos** para ser concluído.
- Durante esses 3 segundos os botões de ataque ficam sem efeito porque não é o turno do jogador.
- Se o jogador selecionar o material correto, Elias causa dano.
- Se selecionar o material errado, o lixo prepara um ataque fatal e Elias perde.

Para mudar o intervalo, altere em `battle_manager.gd`:

```gdscript
const TEMPO_ENTRE_ATAQUES: float = 3.0
```

## Barras de vida

As barras não ficam mais no painel superior da HUD.

- A vida do Elias aparece em uma barrinha logo abaixo do personagem.
- A vida do lixo aparece em uma barrinha logo abaixo do ponto de batalha.
- As barras não exibem números nem porcentagens.

As funções do Elias estão em `Scripts/player.gd`:

```gdscript
mostrar_barra_vida_batalha(100)
atualizar_barra_vida_batalha(70)
esconder_barra_vida_batalha()
```

E as do lixo em `battle/battle_point.gd`:

```gdscript
mostrar_barra_vida(100)
atualizar_barra_vida(70)
esconder_barra_vida()
```
