//// Módulo menu — camada de apresentação do simulador Hospital no Escuro.
//// Concentra a exibição no terminal (echo), os tipos soma de navegação
//// e as funções nomeadas (m1, m2, ..., exit).

import gleam/list
import sgleam/env.{type Env}
import configuracao
import gleam/string
import gleam/int
import jogo.{
  type Acao, type Estado, Derrota, EmAndamento, Vitoria, executar, novo_jogo,
  sala_atual, situacao,
}
import sgleam/check

/// Opções do menu principal (tipo soma).
pub type MainMenu {
  Explorar
  Inventario
  Enigmas
  UsarObjeto
  MoverSala
  ResponderEnigma
  Sair
}

fn mostrar(texto: String) -> Nil {
  echo texto
  Nil
}

/// Exibe as opções disponíveis no menu principal.
pub fn display_main_menu() -> Nil {
  mostrar("\n--- MENU PRINCIPAL (HOSPITAL NO ESCURO) ---")
  mostrar("m1(): Explorar ambiente atual")
  mostrar("m2(): Consultar inventário")
  mostrar("m3(): Examinar enigmas da sala")
  mostrar("m4(): Usar ou coletar objeto")
  mostrar("m5(): Mover para outra sala")
  mostrar("m6(): Responder enigma")
  mostrar("exit(): Encerrar simulação")
}

// Funções nomeadas para seleção de opções no menu funcional.

pub fn m1() -> MainMenu {
  Explorar
}

pub fn m2() -> MainMenu {
  Inventario
}

pub fn m3() -> MainMenu {
  Enigmas
}

pub fn m4() -> MainMenu {
  UsarObjeto
}

pub fn m5() -> MainMenu {
  MoverSala
}

pub fn m6() -> MainMenu {
  ResponderEnigma
}

pub fn exit() -> MainMenu {
  Sair
}

/// Converte uma opção de menu e um argumento opcional em uma Acao pura do jogo.
pub fn opcao_para_acao(opcao: MainMenu, argumento: String) -> Result(Acao, Nil) {
  case opcao {
    Explorar -> Ok(jogo.Explorar)
    Inventario -> Ok(jogo.Inventario)
    Enigmas -> Ok(jogo.Enigmas)
    UsarObjeto -> Ok(jogo.Usar(argumento))
    MoverSala -> Ok(jogo.Ir(argumento))
    ResponderEnigma -> Ok(jogo.Responder(argumento))
    Sair -> Error(Nil)
  }
}

pub fn opcao_para_acao_examples() {
  check.eq(opcao_para_acao(m1(), ""), Ok(jogo.Explorar))
  check.eq(opcao_para_acao(m2(), ""), Ok(jogo.Inventario))
  check.eq(opcao_para_acao(m3(), ""), Ok(jogo.Enigmas))
  check.eq(opcao_para_acao(m4(), "chave"), Ok(jogo.Usar("chave")))
  check.eq(opcao_para_acao(m5(), "Corredor"), Ok(jogo.Ir("Corredor")))
  check.eq(opcao_para_acao(m6(), "3"), Ok(jogo.Responder("3")))
  check.eq(opcao_para_acao(exit(), ""), Error(Nil))
}

/// Formata o cabeçalho de status do jogador (localização, vida e situação).
pub fn formatar_status(estado: Estado) -> String {
  let j = estado.jogador
  let sit = case situacao(estado) {
    EmAndamento -> "Em andamento"
    Vitoria -> "VITÓRIA - Hospital evacuado!"
    Derrota -> "DERROTA - Sem pontos de vida"
  }
  "["
  <> j.nome
  <> " | Local: "
  <> j.localizacao
  <> " | Vida: "
  <> int.to_string(j.pontos_de_vida)
  <> " HP | "
  <> sit
  <> "]"
}

pub fn formatar_status_examples() {
  let e = novo_jogo("Ana")
  check.eq(
    formatar_status(e),
    "[Ana | Local: Manutenção | Vida: 100 HP | Em andamento]",
  )
}

/// Exibe o status atual do jogador no terminal.
pub fn exibir_status(estado: Estado) -> Nil {
  mostrar(formatar_status(estado))
}

/// Guarda o estado entre comandos sem imprimir todas as salas no modo interativo.
pub type Partida {
  Partida(estado: fn() -> Estado)
  Encerrada
}

pub fn iniciar(nome: String) -> Partida {
  let estado = novo_jogo(nome)
  display_main_menu()
  exibir_status(estado)
  Partida(fn() { estado })
}

pub fn jogar(partida: Partida, opcao: MainMenu, argumento: String) -> Partida {
  case partida, opcao {
    Encerrada, _ -> {
      mostrar("Esta partida já foi encerrada.")
      Encerrada
    }
    Partida(_), Sair -> {
      mostrar("Simulação encerrada pelo jogador.")
      Encerrada
    }
    Partida(estado), _ -> {
      let proximo = executar_menu(estado(), opcao, argumento)
      Partida(fn() { proximo })
    }
  }
}

pub fn jogar_examples() {
  let partida = iniciar("Ana")
  let com_chave = jogar(partida, m4(), "chave")
  let assert Partida(estado) = jogar(com_chave, m5(), "Corredor")
  check.eq(estado().jogador.localizacao, "Corredor")
  let encerrada = jogar(partida, exit(), "")
  check.eq(encerrada, Encerrada)
  check.eq(jogar(encerrada, m5(), "Corredor"), Encerrada)
}

/// Executa uma opção do menu sobre o estado atual, exibe a resposta no terminal
/// e devolve o novo estado do jogo.
pub fn executar_menu(
  estado: Estado,
  opcao: MainMenu,
  argumento: String,
) -> Estado {
  case opcao_para_acao(opcao, argumento) {
    Error(Nil) -> {
      mostrar("Simulação encerrada pelo jogador.")
      estado
    }
    Ok(acao) -> {
      let #(novo_estado, mensagem) = executar(estado, acao)
      mostrar("\n> " <> mensagem)
      exibir_status(novo_estado)
      novo_estado
    }
  }
}

/// Executa recursivamente uma lista de passos de menu #(MainMenu, String),
/// exibindo cada etapa no terminal.
pub fn executar_roteiro(
  estado: Estado,
  passos: List(Acao),
) -> Estado {
  case passos {
    [] -> estado

    [acao, ..resto] -> {
      let resultado = executar(estado, acao)

      mostrar("\n> " <> resultado.1)
      exibir_status(resultado.0)

      case situacao(resultado.0) {
        EmAndamento ->
          executar_roteiro(resultado.0, resto)

        _ -> resultado.0
      }
    }
  }
}


/// Roteiro completo de fuga do Hospital no Escuro usando as funções de menu.

pub fn roteiro_demonstracao() -> List(Acao) {
  [
    jogo.Explorar,
    jogo.Usar("lanterna"),
    jogo.Usar("chave"),
    jogo.Usar("registro"),
    jogo.Usar("planta"),
    jogo.Inventario,

    jogo.Ir("Corredor"),
    jogo.Usar("crachá"),
    jogo.Enigmas,
    jogo.Responder("3"),

    jogo.Ir("Sala 3"),
    jogo.Usar("gerador"),
    jogo.Usar("painel"),
    jogo.Enigmas,

    jogo.Responder(
      "3" <> string.slice(
        configuracao.codigo_saida,
        1,
        2,
      ),
    ),

    jogo.Ir("Saída"),
    jogo.Enigmas,
    jogo.Responder(configuracao.codigo_saida),
    jogo.Usar("porta de emergência"),
  ]
}



pub fn roteiro_demonstracao_examples() {
  let inicial = novo_jogo("Ana")

  let final =
    jogo.executar_todas(
      inicial,
      roteiro_demonstracao(),
    )

  check.eq(situacao(final), Vitoria)
  check.eq(sala_atual(final).nome, "Saída")
}


/// Ponto de entrada para demonstração completa no terminal.
pub fn main() -> Nil {
  mostrar("==========================================")
  mostrar("   ESCAPE ROOM: HOSPITAL NO ESCURO")
  mostrar("==========================================")

  mostrar("")
  mostrar("Um apagão atingiu o hospital!")
  mostrar("Você pertence à equipe de manutenção.")
  mostrar("A sala de Manutenção ficou trancada.")
  mostrar("Encontre uma chave, procure pistas e restaure a energia.")
  mostrar("Cuidado: caminhar pelo Corredor sem lanterna é perigoso.")
  mostrar("Seu objetivo é liberar a porta magnética de emergência.")
  mostrar("")

  display_main_menu()

  let estado_inicial = novo_jogo("Ana")
  mostrar("\nIniciando partida...")
  exibir_status(estado_inicial)

  let _estado_final = executar_roteiro(estado_inicial, roteiro_demonstracao())
  mostrar("\n==========================================")
}
type Etapa {
  Principal
  Objetos
  Destinos
  Resposta
}

type Turno {
  Turno(estado: Estado, etapa: Etapa, mensagem: String)
}

fn itens(estado: Estado, etapa: Etapa) -> List(String) {
  let sala = sala_atual(estado)
  case etapa {
    Objetos -> list.map(sala.objetos, fn(objeto) { objeto.nome })
    Destinos -> sala.saidas
    _ -> []
  }
}

fn agir(estado: Estado, acao: Acao) -> Turno {
  let resultado = executar(estado, acao)
  Turno(resultado.0, Principal, resultado.1)
}

fn escolher(t: Turno, entrada: String) -> Turno {
  case t.etapa, string.trim(entrada) {
    _, "0" -> Turno(t.estado, Principal, "")
    Principal, "1" -> agir(t.estado, jogo.Explorar)
    Principal, "2" -> agir(t.estado, jogo.Inventario)
    Principal, "3" -> agir(t.estado, jogo.Enigmas)
    Principal, "4" -> Turno(t.estado, Objetos, "")
    Principal, "5" -> Turno(t.estado, Destinos, "")
    Principal, "6" -> Turno(t.estado, Resposta, "")
    Resposta, "" -> Turno(..t, mensagem: "Digite uma resposta.")
    Resposta, texto -> agir(t.estado, jogo.Responder(texto))
    Principal, _ -> Turno(..t, mensagem: "Escolha um número do menu.")
    etapa, numero -> {
      let opcoes = itens(t.estado, etapa)
      case int.parse(numero) {
        Ok(n) if n > 0 -> case list.drop(opcoes, n - 1) {
          [nome, ..] -> case etapa {
            Objetos -> agir(t.estado, jogo.Usar(nome))
            _ -> agir(t.estado, jogo.Ir(nome))
          }
          [] -> Turno(..t, mensagem: "Opção inválida.")
        }
        _ -> Turno(..t, mensagem: "Opção inválida.")
      }
    }
  }
}

pub fn smain(contexto: Env) -> String {
  let inicio = Turno(novo_jogo("Eu"), Principal, "Um apagão trancou você na Manutenção. Encontre uma saída.")
  let t = list.fold(env.args(contexto), inicio, escolher)
  let opcoes = case situacao(t.estado), t.etapa {
    EmAndamento, Principal -> "1. Explorar a sala\n2. Ver inventário\n3. Consultar pistas\n4. Usar objeto\n5. Mudar de sala\n6. Responder enigma"
    EmAndamento, Resposta -> "Digite a resposta do enigma (0 para voltar)."
    EmAndamento, etapa -> {
      let lista = list.index_map(itens(t.estado, etapa), fn(nome, i) {
        int.to_string(i + 1) <> ". " <> nome
      })
      string.join(lista, "\n") <> "\n0. Voltar"
    }
    _, _ -> "Fim da partida."
  }
  "HOSPITAL NO ESCURO\n" <> formatar_status(t.estado) <> "\n\n" <> t.mensagem
  <> "\n\n" <> opcoes <> "\nq. Sair"
}
