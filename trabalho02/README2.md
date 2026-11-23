
## História

Um apagão deixa a equipe de manutenção presa em uma ala do hospital.

O jogador deve encontrar uma chave, explorar ambientes, obter um crachá, ligar o gerador e restabelecer a energia para abrir a saída de emergência.

## Ambientes

- Manutenção: chave, lanterna, registro e planta.
- Corredor: crachá e trava com senha.
- Sala 3: gerador auxiliar e painel elétrico.
- Saída: terminal de evacuação e porta magnética.

## Regras principais

- Sem chave, não é possível sair da Manutenção.
- Entrar no Corredor sem lanterna causa perda de 10 HP.
- O gerador só liga com lanterna.
- Usar o painel sem lanterna causa choque de 20 HP.
- O painel exige lanterna, crachá e gerador ligado.
- A porta de emergência exige energia, crachá e rota autorizada.

## Arquivos

- configuracao.gleam: constantes do jogo.
- jogador.gleam: informações do jogador.
- objeto.gleam: objetos e interações.
- enigma.gleam: desafios e pistas.
- ambiente.gleam: ambientes e conexões.
- jogo.gleam: lógica da partida.
- menu.gleam: demonstração no terminal.
- visual.gleam: interface gráfica.

## Execução

Verifique a instalação do SGleam com `sgleam --help`.

Para executar a demonstração textual, utilize `sgleam menu.gleam`.

Os testes são definidos por funções terminadas em `_examples` e podem ser executados com o comando `sgleam test`, conforme a versão utilizada.

A interface gráfica foi desenvolvida com `sgleam/image` e `sgleam/world`, seguindo o material de aula. Sua execução depende de um ambiente SGleam Web compatível que consiga carregar todos os módulos.
# Trabalho 2 da disciplina de Programação Funcional - Escape Room
## Tema: Hospital no escuro
Obs: Neste trabalho, ao contrário do primeiro, não utilizaremos módulos separados para os exemplos, apenas os módulos que separam o código para manter organização e clareza.

## Narrativa

Uma tempestade derruba a rede elétrica da cidade e o hospital fica no escuro.
O gerador auxiliar não liga sozinho e as portas automáticas entram em modo de
bloqueio. O jogador faz parte da equipe de manutenção e ficou isolado na
**ala de manutenção**, iluminada apenas pela luz de emergência.

Para sair, o jogador precisa juntar as pistas deixadas na ala (o registro de
falhas dos equipamentos e a planta do prédio), destravar o corredor, religar o
painel do gerador e gerar o código de evacuação. Com o código, chega à saída de
emergência, onde o terminal de segurança libera a rota e a porta se abre.

**Objetivo:** reabrir a rota segura de evacuação, abrindo a porta de emergência.

**Derrota:** os pontos de vida chegam a zero (o painel do gerador dá choque de
10 de vida em quem tenta ligá-lo sem o crachá do técnico).

## Mapa das salas

```
Manutenção  <-->  Corredor  <-->  Sala 3  <-->  Saída
 (início)      [Trava do       [Sequência do  [Terminal de
                Corredor]       Gerador]       Saída]
```

| Sala | Objetos | Enigma | Para entrar é preciso |
|---|---|---|---|
| Manutenção | lanterna, chave, registro, planta | — | — (sala inicial) |
| Corredor | crachá | Trava do Corredor | — |
| Sala 3 | painel | Sequência do Gerador | `acesso corredor` |
| Saída | porta de emergência | Terminal de Saída | `codigo evacuacao` |

## Pistas e enigmas

| Enigma | Pergunta | De onde vem a resposta | Resposta | Recompensa |
|---|---|---|---|---|
| Trava do Corredor | número da sala do gerador | registro: "gerador na sala 3" | `3` | `acesso corredor` |
| Sequência do Gerador | sala do gerador + dígitos da porta técnica | registro (3) + planta (B12) | `312` | `codigo evacuacao` |
| Terminal de Saída | código completo da porta técnica | planta: "porta técnica B12" | `B12` | `rota liberada` |

As respostas ignoram maiúsculas/minúsculas e espaços nas pontas (`" b12 "` também vale).

## Caminho completo até a saída

Cada passo é uma `Acao` aplicada por `jogo.executar(estado, acao)`, que devolve
o novo estado e a mensagem. A partida começa com `jogo.novo_jogo("Ana")`, na
Manutenção, com 100 de vida e inventário vazio.

| # | Sala | Ação | O que acontece |
|---|---|---|---|
| 1 | Manutenção | `Usar("registro")` | ganha `pista: gerador na sala 3` |
| 2 | Manutenção | `Usar("planta")` | ganha `pista: porta técnica B12` |
| 3 | Manutenção | `Ir("Corredor")` | entra no Corredor |
| 4 | Corredor | `Usar("crachá")` | ganha `crachá` (evita o choque no painel) |
| 5 | Corredor | `Responder("3")` | resolve a Trava do Corredor, ganha `acesso corredor` |
| 6 | Corredor | `Ir("Sala 3")` | entra na sala do gerador |
| 7 | Sala 3 | `Usar("painel")` | com o crachá, ganha `energia restaurada` |
| 8 | Sala 3 | `Responder("312")` | resolve a Sequência do Gerador, ganha `codigo evacuacao` |
| 9 | Sala 3 | `Ir("Saída")` | entra na Saída |
| 10 | Saída | `Responder("B12")` | resolve o Terminal de Saída, ganha `rota liberada` |
| 11 | Saída | `Usar("porta de emergência")` | ganha `porta aberta` → **Vitória** |

A qualquer momento, `Explorar` mostra a sala, os objetos e as saídas;
`Inventario` lista os itens; e `Enigmas` mostra o enigma pendente da sala com
suas pistas numeradas.

Esse percurso está em `caminho_vitoria()` (`jogo.gleam`) e é testado em
`executar_examples`, que confere que a partida termina em `Vitoria` e que,
depois disso, nenhuma ação altera o estado.

### O que acontece fora do caminho

- `Ir("Sala 3")` antes de resolver a Trava do Corredor: "O acesso a Sala 3 está bloqueado."
- `Usar("painel")` sem o crachá: choque, perde 10 de vida e o painel continua apagado.
- Na Sala 3, o painel precisa estar ligado para aceitar a sequência do gerador. Use `Explorar` para verificar se ele está `[apagado]` ou `[ligado]`.
- `Usar("porta de emergência")` antes do terminal: nada acontece, a porta continua trancada.
- Resposta errada: "Resposta incorreta." e o estado não muda.
- Usar um objeto já usado: "Você já usou ..." (o item não é duplicado).
- A lanterna e a chave de manutenção podem ser pegas, mas não são exigidas para sair.

## Módulo `menu` (apresentação no terminal)

O `menu.gleam` é a única camada que usa `gleam/io`; a lógica continua pura em
`jogo.gleam`. As opções do menu são o tipo soma `MainMenu`, selecionadas por
funções nomeadas:

| Função | Opção | Ação do jogo | Argumento |
|---|---|---|---|
| `m1()` | `Explorar` | `Explorar` | — |
| `m2()` | `Inventario` | `Inventario` | — |
| `m3()` | `Enigmas` | `Enigmas` | — |
| `m4()` | `UsarObjeto` | `Usar(arg)` | nome do objeto |
| `m5()` | `MoverSala` | `Ir(arg)` | nome da sala |
| `m6()` | `ResponderEnigma` | `Responder(arg)` | resposta |
| `exit()` | `Sair` | — (encerra) | — |

Funções principais:

- `opcao_para_acao(opcao, arg)`: converte a opção em `Ok(Acao)`, ou `Error(Nil)` para `exit()`.
- `formatar_status(estado)`: monta a linha `[Ana | Local: Manutenção | Vida: 100 HP | Em andamento]`.
- `executar_menu(estado, opcao, arg)`: executa a opção, imprime a mensagem e o status e devolve o novo estado.
- `executar_roteiro(estado, passos)`: executa recursivamente uma lista de `#(MainMenu, String)`; para em `exit()`, na vitória ou na derrota.
- `iniciar(nome)`: exibe o menu e o status e devolve uma `Partida` nova.
- `jogar(partida, opcao, arg)`: executa uma jogada e devolve a `Partida` atualizada (para o modo interativo).
- `main()`: exibe o título e o menu principal (`sgleam menu.gleam`).

## Jogando manualmente (modo interativo)

Abra o modo interativo do sgleam com o módulo `menu` carregado:

```
sgleam -i menu.gleam
```

Comece a partida guardando-a em `p`, e a cada jogada atualize `p` com `jogar`:

```
let p = iniciar("Ana")
let p = jogar(p, m1(), "")
let p = jogar(p, m4(), "registro")
let p = jogar(p, m5(), "Corredor")
let p = jogar(p, m6(), "3")
```

Cada jogada imprime a mensagem e o status, por exemplo:

```
> Correto! Trava do Corredor resolvido.
[Ana | Local: Corredor | Vida: 100 HP | Em andamento]
Partida(estado: //fn() { ... })
```

A última linha é o valor guardado em `p` e pode ser ignorada. O estado fica
dentro de uma função porque o modo interativo só guarda em `let` tipos
definidos no próprio `menu` e, assim, não imprime o estado inteiro.

Comandos:

| Jogada | O que faz |
|---|---|
| `jogar(p, m1(), "")` | explora a sala atual |
| `jogar(p, m2(), "")` | mostra o inventário |
| `jogar(p, m3(), "")` | mostra o enigma da sala e as pistas |
| `jogar(p, m4(), "objeto")` | usa/coleta um objeto |
| `jogar(p, m5(), "sala")` | vai para outra sala |
| `jogar(p, m6(), "resposta")` | responde o enigma da sala |
| `jogar(p, exit(), "")` | encerra a simulação |

Jogadas para testar os erros:

- `jogar(p, m5(), "Sala 3")` logo no início: "Não há saída para Sala 3."
- `jogar(p, m4(), "painel")` na Sala 3 sem ter pego o crachá: choque, a vida cai para 90.
- `jogar(p, m6(), "999")`: "Resposta incorreta."

O caminho até a vitória está na seção "Caminho completo até a saída".

Para sair do modo interativo: `Ctrl+D` (ou `Ctrl+Z` e Enter no Windows).

## Como executar os testes

A partir da pasta `trabalho02/`:

```
sgleam -t jogador.gleam
sgleam -t objeto.gleam
sgleam -t enigma.gleam
sgleam -t ambiente.gleam
sgleam -t jogo.gleam
sgleam -t menu.gleam
```
