
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
