//// Módulo ambiente — define as salas do hospital, com seus objetos, saídas
//// e enigmas, além de funções puras de consulta e atualização.

import enigma.{
  type Enigma, enigma_sequencia_gerador, enigma_terminal_evacuacao,
  enigma_trava_corredor,
}
import gleam/list
import gleam/string
import jogador.{type Jogador, novo_jogador}
import objeto.{type Objeto}
import sgleam/check

/// Uma sala do jogo
pub type Ambiente {
  Ambiente(
    nome: String,
    descricao: String,
    objetos: List(Objeto),
    saidas: List(String),
    enigmas: List(Enigma),
  )
}

/// Texto do comando "explorar": descrição da sala, objetos e saídas.
pub fn explorar(ambiente: Ambiente, _jogador: Jogador) -> String {
  let objetos_txt = list.map(ambiente.objetos, objeto.descrever)
  string.join(
    [
      ambiente.descricao,
      "Objetos: " <> string.join(objetos_txt, ", "),
      "Saídas: " <> string.join(ambiente.saidas, ", "),
    ],
    "\n",
  )
}

pub fn explorar_examples() {
  let amb = Ambiente("Teste", "Uma sala vazia.", [], ["Corredor"], [])
  check.eq(
    explorar(amb, novo_jogador("Ana", "Teste")),
    "Uma sala vazia.\nObjetos: \nSaídas: Corredor",
  )
}

/// Procura um objeto da sala pelo nome.
pub fn buscar_objeto(ambiente: Ambiente, nome: String) -> Result(Objeto, Nil) {
  list.find(ambiente.objetos, fn(obj) { obj.nome == nome })
}

pub fn buscar_objeto_examples() {
  let amb = manutencao()
  check.eq(buscar_objeto(amb, "inexistente"), Error(Nil))
  check.eq(
    case buscar_objeto(amb, "chave") {
      Ok(obj) -> obj.nome
      Error(_) -> ""
    },
    "chave",
  )
}

/// Procura um enigma da sala pelo nome.
pub fn buscar_enigma(ambiente: Ambiente, nome: String) -> Result(Enigma, Nil) {
  list.find(ambiente.enigmas, fn(e) { e.nome == nome })
}

pub fn buscar_enigma_examples() {
  check.eq(buscar_enigma(manutencao(), "Trava do Corredor"), Error(Nil))
  check.eq(
    case buscar_enigma(corredor(), "Trava do Corredor") {
      Ok(e) -> e.nome
      Error(_) -> ""
    },
    "Trava do Corredor",
  )
}

/// Verifica se a sala tem uma saída para o destino.
pub fn tem_saida(ambiente: Ambiente, destino: String) -> Bool {
  list.contains(ambiente.saidas, destino)
}

pub fn tem_saida_examples() {
  check.eq(tem_saida(manutencao(), "Corredor"), True)
  check.eq(tem_saida(manutencao(), "Saída"), False)
}

/// Devolve a sala com o objeto de mesmo nome trocado pela nova versão
/// (usado depois de uma interação, para guardar o novo estado do objeto).
pub fn atualizar_objeto(ambiente: Ambiente, novo: Objeto) -> Ambiente {
  let objetos =
    list.map(ambiente.objetos, fn(obj) {
      case obj.nome == novo.nome {
        True -> novo
        False -> obj
      }
    })
  Ambiente(..ambiente, objetos: objetos)
}

pub fn atualizar_objeto_examples() {
  let usada = objeto.Objeto(..objeto.chave(), estado: "usado")
  let amb = atualizar_objeto(manutencao(), usada)
  check.eq(
    case buscar_objeto(amb, "chave") {
      Ok(obj) -> obj.estado
      Error(_) -> ""
    },
    "usado",
  )
  check.eq(list.length(amb.objetos), list.length(manutencao().objetos))
}

/// Devolve a sala com o enigma de mesmo nome trocado pela nova versão
/// (usado depois de uma tentativa de resolução).
pub fn atualizar_enigma(ambiente: Ambiente, novo: Enigma) -> Ambiente {
  let enigmas =
    list.map(ambiente.enigmas, fn(e) {
      case e.nome == novo.nome {
        True -> novo
        False -> e
      }
    })
  Ambiente(..ambiente, enigmas: enigmas)
}

pub fn atualizar_enigma_examples() {
  let resolvido =
    enigma.Enigma(..enigma_trava_corredor(), status: enigma.Resolvido)
  let amb = atualizar_enigma(corredor(), resolvido)
  check.eq(enigma.todos_resolvidos(amb.enigmas), True)
  check.eq(enigma.todos_resolvidos(corredor().enigmas), False)
}

/// Procura uma sala pelo nome na lista de salas do jogo.
pub fn buscar_ambiente(
  ambientes: List(Ambiente),
  nome: String,
) -> Result(Ambiente, Nil) {
  list.find(ambientes, fn(a) { a.nome == nome })
}

pub fn buscar_ambiente_examples() {
  check.eq(buscar_ambiente(hospital(), "Telhado"), Error(Nil))
  check.eq(
    case buscar_ambiente(hospital(), "Sala 3") {
      Ok(a) -> a.nome
      Error(_) -> ""
    },
    "Sala 3",
  )
}

// Salas da narrativa

/// Ponto de partida: a ala de manutenção onde a equipe ficou isolada.
pub fn manutencao() -> Ambiente {
  Ambiente(
    nome: "Manutenção",
    descricao: "A Manutenção ficou trancada após o apagão. Procure a chave antes de tentar o Corredor.",    
    objetos: [
      objeto.lanterna(),
      objeto.chave(),
      objeto.registro(),
      objeto.planta(),
    ],
    saidas: ["Corredor"],
    enigmas: [],
  )
}

/// Corredor bloqueado: o visor pede o número da sala do gerador.
pub fn corredor() -> Ambiente {
  Ambiente(
    nome: "Corredor",
    descricao: "O Corredor está escuro e cheio de obstáculos, cuidado para não tropeçar. A trava da Sala 3 pede uma senha. ",
    objetos: [objeto.cracha()],
    saidas: ["Manutenção", "Sala 3"],
    enigmas: [enigma_trava_corredor()],
  )
}

/// Sala do gerador auxiliar: é preciso religar o painel e gerar o código.
pub fn sala_gerador() -> Ambiente {
  Ambiente(
    nome: "Sala 3",
    descricao: "Na Sala 3 há um gerador desligado e um painel elétrico. Ative-os na ordem correta.",
    objetos: [
      objeto.gerador(),
      objeto.painel(),
    ],
    saidas: ["Corredor", "Saída"],
    enigmas: [enigma_sequencia_gerador()],
  )
}

/// Saída de evacuação, o terminal libera a rota e a porta abre.
pub fn saida() -> Ambiente {
  Ambiente(
    nome: "Saída",
    descricao: "A porta de evacuação, controlada por um terminal de segurança.",
    objetos: [objeto.porta_emergencia()],
    saidas: ["Sala 3"],
    enigmas: [enigma_terminal_evacuacao()],
  )
}

/// Todas as salas do hospital, na ordem do percurso.
pub fn hospital() -> List(Ambiente) {
  [manutencao(), corredor(), sala_gerador(), saida()]
}

pub fn hospital_examples() {
  let nomes = list.map(hospital(), fn(a) { a.nome })
  check.eq(
    list.all(hospital(), fn(a) {
      list.all(a.saidas, fn(s) { list.contains(nomes, s) })
    }),
    True,
  )
}
