//// Módulo jogo — estado do jogo e transições puras: cada ação recebe o estado
//// atual e devolve um novo estado e a mensagem a exibir (a impressão  vai ficar no menu).

import ambiente.{type Ambiente}
import configuracao
import enigma.{type Enigma}
import gleam/list
import gleam/string
import jogador.{type Jogador}
import objeto
import sgleam/check

/// Estado completo do jogo: o jogador e as salas (com objetos e enigmas atualizados).
pub type Estado {
  Estado(jogador: Jogador, salas: List(Ambiente))
}

/// Ações que o jogador pode realizar.
pub type Acao {
  Explorar
  Inventario
  Enigmas
  Usar(objeto: String)
  Ir(destino: String)
  Responder(resposta: String)
}

/// Situação da partida, sempre calculada a partir do estado.
pub type Situacao {
  EmAndamento
  Vitoria
  Derrota
}

/// Começa a partida na ala de manutenção.
pub fn novo_jogo(nome: String) -> Estado {
  Estado(jogador.novo_jogador(nome, "Manutenção"), ambiente.hospital())
}

pub fn novo_jogo_examples() {
  check.eq(novo_jogo("Ana").jogador.localizacao, "Manutenção")
  check.eq(list.length(novo_jogo("Ana").salas), 4)
}

/// Vitória quando a porta de emergência abre; derrota quando a vida acaba.

pub fn situacao(estado: Estado) -> Situacao {
  case estado.jogador.pontos_de_vida <= 0 {
    True -> Derrota

    False ->
      case ambiente.buscar_ambiente(
        estado.salas,
        "Saída",
      ) {
        Error(_) -> EmAndamento

        Ok(saida) ->
          case ambiente.buscar_objeto(
            saida,
            "porta de emergência",
          ) {
            Ok(porta) if porta.estado == "aberta" ->
              Vitoria

            _ -> EmAndamento
          }
      }
  }
}



pub fn situacao_examples() {
  let e = novo_jogo("Ana")

  check.eq(situacao(e), EmAndamento)

  check.eq(
    situacao(
      Estado(
        ..e,
        jogador: jogador.perder_vida(e.jogador, 100),
      ),
    ),
    Derrota,
  )

  let porta_aberta = objeto.Objeto(
    ..objeto.porta_emergencia(),
    estado: "aberta",
  )

  let saida_atualizada =
    ambiente.atualizar_objeto(
      ambiente.saida(),
      porta_aberta,
    )

  let e2 = Estado(
    ..e,
    salas: substituir_sala(e.salas, saida_atualizada),
  )

  check.eq(situacao(e2), Vitoria)
}


/// Sala onde o jogador está.
pub fn sala_atual(estado: Estado) -> Ambiente {
  // Ir só move para saídas existentes, e hospital_examples garante que toda saída é uma sala.
  let assert Ok(sala) =
    ambiente.buscar_ambiente(estado.salas, estado.jogador.localizacao)
  sala
}

pub fn sala_atual_examples() {
  check.eq(sala_atual(novo_jogo("Ana")).nome, "Manutenção")
}

/// Troca a sala de mesmo nome pela nova versão.
fn substituir_sala(salas: List(Ambiente), nova: Ambiente) -> List(Ambiente) {
  list.map(salas, fn(s) {
    case s.nome == nova.nome {
      True -> nova
      False -> s
    }
  })
}

/// Primeiro enigma ainda pendente da sala.
fn enigma_pendente(sala: Ambiente) -> Result(Enigma, Nil) {
  list.find(sala.enigmas, fn(e) { e.status == enigma.Pendente })
}

/// Item que o jogador precisa ter para entrar em uma sala bloqueada.
fn requisito(destino: String) -> Result(String, Nil) {
  case destino {
    "Sala 3" -> Ok("acesso corredor")
    "Saída" -> Ok("codigo evacuacao")
    _ -> Error(Nil)
  }
}

/// Executa uma ação e devolve o novo estado e a mensagem para o jogador.
/// Com a partida encerrada, nenhuma ação altera o estado.
pub fn executar(estado: Estado, acao: Acao) -> #(Estado, String) {
  case situacao(estado) {
    EmAndamento -> aplicar(estado, acao)
    Vitoria -> #(estado, "Você já escapou do hospital!")
    Derrota -> #(estado, "Fim de jogo: você não tem mais vida.")
  }
}

fn aplicar(estado: Estado, acao: Acao) -> #(Estado, String) {
  let j = estado.jogador
  let sala = sala_atual(estado)
  case acao {
    Explorar -> #(estado, ambiente.explorar(sala, j))

    Inventario ->
      case j.inventario {
        [] -> #(estado, "Inventário vazio.")
        itens -> #(
          estado,
          "Inventário: " <> string.join(list.reverse(itens), ", "),
        )
      }

    Enigmas ->
      case enigma_pendente(sala) {
        Error(_) -> #(estado, "Nenhum enigma pendente nesta sala.")
        Ok(e) -> #(
          estado,
          e.nome
            <> ": "
            <> e.descricao
            <> "\n"
            <> enigma.formatar_pistas(e.pistas),
        )
      }

    Usar(nome) ->
      case ambiente.buscar_objeto(sala, nome) {
        Error(_) -> #(estado, "Não há " <> nome <> " aqui.")
        Ok(obj) -> {
          let #(novo_obj, novo_j) = objeto.interagir(obj, j)
          let salas =
            substituir_sala(
              estado.salas,
              ambiente.atualizar_objeto(sala, novo_obj),
            )
          let msg = case obj.estado, novo_obj.estado {
            "usado", _ ->
              "Você já usou " <> nome <> "."

            "aberta", _ ->
              "A porta já está aberta."

            _, "aberta" ->
              "A porta magnética se abriu. Evacuação concluída!"

            _, "usado" ->
              "Você usou " <> nome <> "."

            _, _ ->
              case novo_j.pontos_de_vida < j.pontos_de_vida {
                True ->
                  "Choque elétrico de 20 HP! Vida: "
                  <> string.inspect(novo_j.pontos_de_vida)

                False ->
                  case nome {
                    "gerador" ->
                      "Sem lanterna, você não consegue ligar o gerador."

                    "painel" ->
                      case jogador.tem_item(j, "crachá") {
                        False ->
                          "O painel exige o crachá de manutenção."

                        True ->
                          "Ligue o gerador antes de usar o painel."
                      }

                    "porta de emergência" ->
                      "Porta bloqueada: é preciso energia, crachá e autorização do terminal."

                    _ -> "Nada acontece."
                  }
              }
          }

          #(Estado(novo_j, salas), msg)
        }
      }


    Ir(destino) ->
      case ambiente.tem_saida(sala, destino) {
        False ->
          #(estado, "Não há saída para " <> destino <> ".")

        True ->
          case sala.nome == "Manutenção"
            && destino == "Corredor"
            && !jogador.tem_item(j, "chave de manutenção") {

            True ->
              #(
                estado,
                "A porta da Manutenção está trancada. Encontre a chave.",
              )

            False ->
              case requisito(destino) {
                Error(_) ->
                  mover(estado, destino)

                Ok(item) ->
                  case jogador.tem_item(j, item) {
                    True -> mover(estado, destino)

                    False ->
                      #(
                        estado,
                        "O acesso a " <> destino <> " está bloqueado.",
                      )
                  }
              }
          }
      }


    
    Responder(resposta) ->
      case sala.nome == "Sala 3"
        && !jogador.tem_item(j, "energia restaurada") {

        True ->
          #(
            estado,
            "Restaure a energia antes de resolver a sequência.",
          )

        False ->
          case sala.nome == "Sala 3"
            && !jogador.tem_item(
              j,
              "pista: porta técnica " <> configuracao.codigo_saida,
            ) {

            True ->
              #(
                estado,
                "Consulte a planta do hospital para encontrar os dígitos.",
              )

            False ->
              case enigma_pendente(sala) {
                Error(_) ->
                  #(estado, "Nenhum enigma pendente nesta sala.")

                Ok(e) -> {
                  let #(novo_e, novo_j, ok) =
                    enigma.tentar_resolver(e, resposta, j)

                  case ok {
                    True ->
                      #(
                        Estado(
                          novo_j,
                          substituir_sala(
                            estado.salas,
                            ambiente.atualizar_enigma(sala, novo_e),
                          ),
                        ),
                        "Correto! " <> e.nome <> " resolvido.",
                      )

                    False ->
                      #(estado, "Resposta incorreta.")
                  }
                }
              }
          }
      }
  }
}


fn mover(estado: Estado, destino: String) -> #(Estado, String) {
  let movido =
    jogador.mover(estado.jogador, destino)

  let caiu =
    destino == "Corredor"
    && !jogador.tem_item(movido, "lanterna")

  let atualizado = case caiu {
    True ->
      jogador.perder_vida(
        movido,
        configuracao.dano_queda,
      )

    False -> movido
  }

  let novo = Estado(
    ..estado,
    jogador: atualizado,
  )

  let aviso = case caiu {
    True ->
      "\nVocê tropeçou no escuro e perdeu 10 HP!"

    False -> ""
  }

  #(
    novo,
    "Você entrou em "
    <> destino
    <> "."
    <> aviso
    <> "\n"
    <> ambiente.explorar(sala_atual(novo), atualizado),
  )
}


/// Executa uma sequência de ações (fold sobre a lista), descartando as mensagens.
pub fn executar_todas(estado: Estado, acoes: List(Acao)) -> Estado {
  list.fold(acoes, estado, fn(e, a) { executar(e, a).0 })
}

/// Percurso completo da manutenção até a saída.

fn caminho_vitoria() -> List(Acao) {
  [
    Usar("lanterna"),
    Usar("chave"),
    Usar("registro"),
    Usar("planta"),

    Ir("Corredor"),
    Usar("crachá"),
    Responder("3"),

    Ir("Sala 3"),
    Usar("gerador"),
    Usar("painel"),

    Responder(
      "3" <> string.slice(
        configuracao.codigo_saida,
        1,
        2,
      ),
    ),

    Ir("Saída"),
    Responder(configuracao.codigo_saida),
    Usar("porta de emergência"),
  ]
}



pub fn executar_examples() {
  let inicial = novo_jogo("Ana")

  // Sem chave, nao sai da Manutencao.
  check.eq(
    executar(inicial, Ir("Corredor")).1,
    "A porta da Manutenção está trancada. Encontre a chave.",
  )

  // Sem lanterna, cada entrada no Corredor tira 10 HP.
  let com_chave =
    executar(inicial, Usar("chave")).0

  let corredor_escuro =
    executar(com_chave, Ir("Corredor")).0

  check.eq(
    corredor_escuro.jogador.pontos_de_vida,
    90,
  )

  let manutencao_novamente =
    executar(corredor_escuro, Ir("Manutenção")).0

  let corredor_outra_vez =
    executar(manutencao_novamente, Ir("Corredor")).0

  check.eq(
    corredor_outra_vez.jogador.pontos_de_vida,
    80,
  )

  // Sem lanterna, o painel tira 20 HP.
  let antes_choque = executar_todas(
    inicial,
    [
      Usar("chave"),
      Ir("Corredor"),
      Responder("3"),
      Ir("Sala 3"),
    ],
  )

  check.eq(
    executar(antes_choque, Usar("painel")).0.jogador.pontos_de_vida,
    70,
  )

  // Sem lanterna, o gerador nao liga.
  check.eq(
    jogador.tem_item(
      executar(antes_choque, Usar("gerador")).0.jogador,
      "gerador ligado",
    ),
    False,
  )

  // Sem energia, o segundo enigma fica bloqueado.
  check.eq(
    executar(antes_choque, Responder("347")).1,
    "Restaure a energia antes de resolver a sequência.",
  )

  // Percurso completo.
  let com_lanterna =
    executar(inicial, Usar("lanterna")).0

  let fim =
    executar_todas(com_lanterna, caminho_vitoria())

  check.eq(situacao(fim), Vitoria)

  // Depois da vitoria, o estado nao pode mudar.
  check.eq(executar(fim, Explorar).0, fim)

  // A porta precisa estar realmente aberta.
  check.eq(
    case ambiente.buscar_objeto(
      sala_atual(fim),
      "porta de emergência",
    ) {
      Ok(porta) -> porta.estado
      Error(_) -> ""
    },
    "aberta",
  )
}

