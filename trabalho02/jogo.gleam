//// Módulo jogo — estado do jogo e transições puras: cada ação recebe o estado
//// atual e devolve um novo estado e a mensagem a exibir (a impressão  vai ficar no menu).

import ambiente.{type Ambiente}
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
  case jogador.tem_item(estado.jogador, "porta aberta") {
    True -> Vitoria
    False ->
      case estado.jogador.pontos_de_vida {
        v if v <= 0 -> Derrota
        _ -> EmAndamento
      }
  }
}

pub fn situacao_examples() {
  let e = novo_jogo("Ana")
  check.eq(situacao(e), EmAndamento)
  check.eq(
    situacao(Estado(..e, jogador: jogador.perder_vida(e.jogador, 100))),
    Derrota,
  )
  check.eq(
    situacao(
      Estado(..e, jogador: jogador.adicionar_item(e.jogador, "porta aberta")),
    ),
    Vitoria,
  )
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
            "usado", _ -> "Você já usou " <> nome <> "."
            _, "usado" -> "Você usou " <> nome <> "."
            _, _ ->
              case novo_j.pontos_de_vida < j.pontos_de_vida {
                True ->
                  "Você levou um choque! Vida: "
                  <> string.inspect(novo_j.pontos_de_vida)
                False -> "Nada acontece."
              }
          }
          #(Estado(novo_j, salas), msg)
        }
      }

    Ir(destino) ->
      case ambiente.tem_saida(sala, destino), requisito(destino) {
        False, _ -> #(estado, "Não há saída para " <> destino <> ".")
        True, Ok(item) ->
          case jogador.tem_item(j, item) {
            True -> mover(estado, destino)
            False -> #(estado, "O acesso a " <> destino <> " está bloqueado.")
          }
        True, Error(_) -> mover(estado, destino)
      }

    Responder(resposta) ->
      case enigma_pendente(sala) {
        Error(_) -> #(estado, "Nenhum enigma pendente nesta sala.")
        Ok(e) ->
          case enigma.resolver_com_mensagem(e, resposta, j) {
            Ok(#(novo_e, novo_j)) -> #(
              Estado(
                novo_j,
                substituir_sala(
                  estado.salas,
                  ambiente.atualizar_enigma(sala, novo_e),
                ),
              ),
              "Correto! " <> e.nome <> " resolvido.",
            )
            Error(mensagem) -> #(estado, mensagem)
          }
      }
  }
}

fn mover(estado: Estado, destino: String) -> #(Estado, String) {
  let novo = Estado(..estado, jogador: jogador.mover(estado.jogador, destino))
  #(
    novo,
    "Você entrou em "
      <> destino
      <> ".\n"
      <> ambiente.explorar(sala_atual(novo), novo.jogador),
  )
}

/// Executa uma sequência de ações (fold sobre a lista), descartando as mensagens.
pub fn executar_todas(estado: Estado, acoes: List(Acao)) -> Estado {
  list.fold(acoes, estado, fn(e, a) { executar(e, a).0 })
}

/// Percurso completo da manutenção até a saída.
fn caminho_vitoria() -> List(Acao) {
  [
    Usar("registro"),
    Usar("planta"),
    Ir("Corredor"),
    Usar("crachá"),
    Responder("3"),
    Ir("Sala 3"),
    Usar("painel"),
    Responder("312"),
    Ir("Saída"),
    Responder("B12"),
    Usar("porta de emergência"),
  ]
}

pub fn executar_examples() {
  let e = novo_jogo("Ana")

  // Sala bloqueada até resolver a trava do corredor
  let no_corredor = executar_todas(e, [Ir("Corredor")])
  check.eq(
    executar(no_corredor, Ir("Sala 3")).1,
    "O acesso a Sala 3 está bloqueado.",
  )
  check.eq(executar(e, Ir("Saída")).1, "Não há saída para Saída.")

  // Resposta errada não muda o estado
  check.eq(executar(no_corredor, Responder("9")), #(
    no_corredor,
    "Resposta incorreta.",
  ))

  // Objeto inexistente e objeto já usado
  check.eq(executar(e, Usar("faca")).1, "Não há faca aqui.")
  let #(e2, msg) = executar(e, Usar("chave"))
  check.eq(msg, "Você usou chave.")
  check.eq(executar(e2, Usar("chave")).1, "Você já usou chave.")
  check.eq(executar(e2, Inventario).1, "Inventário: chave de manutenção")

  // Painel sem crachá dá choque
  let na_sala3 =
    executar_todas(e, [Ir("Corredor"), Responder("3"), Ir("Sala 3")])
  check.eq(
    executar(na_sala3, Usar("painel")).1,
    "Você levou um choque! Vida: 90",
  )
  check.eq(executar(na_sala3, Responder("312")), #(
    na_sala3,
    "Ligue o painel do gerador antes de informar o código.",
  ))
  check.eq(executar(na_sala3, Ir("Saída")).0, na_sala3)
  check.eq(string.contains(executar(na_sala3, Explorar).1, "[apagado]"), True)

  let com_energia = executar_todas(na_sala3, [
    Ir("Corredor"),
    Usar("crachá"),
    Ir("Sala 3"),
    Usar("painel"),
  ])
  check.eq(string.contains(executar(com_energia, Explorar).1, "[ligado]"), True)

  // Percurso completo termina em vitória, e depois disso nada muda
  let fim = executar_todas(e, caminho_vitoria())
  check.eq(situacao(fim), Vitoria)
  check.eq(executar(fim, Explorar), #(fim, "Você já escapou do hospital!"))
}
