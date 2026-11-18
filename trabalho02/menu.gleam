//// Módulo menu — camada de apresentação do simulador Hospital no Escuro.
//// Concentra a exibição no terminal (gleam/io), os tipos soma de navegação
//// e as funções nomeadas (m1, m2, ..., exit).

import configuracao
import gleam/string
import gleam/int
import gleam/io
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

/// Exibe as opções disponíveis no menu principal.
pub fn display_main_menu() -> Nil {
  io.println("\n--- MENU PRINCIPAL (HOSPITAL NO ESCURO) ---")
  io.println("m1(): Explorar ambiente atual")
  io.println("m2(): Consultar inventário")
  io.println("m3(): Examinar enigmas da sala")
  io.println("m4(): Usar ou coletar objeto")
  io.println("m5(): Mover para outra sala")
  io.println("m6(): Responder enigma")
  io.println("exit(): Encerrar simulação")
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
  io.println(formatar_status(estado))
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
      io.println("Simulação encerrada pelo jogador.")
      estado
    }
    Ok(acao) -> {
      let #(novo_estado, mensagem) = executar(estado, acao)
      io.println("\n> " <> mensagem)
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

      io.println("\n> " <> resultado.1)
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
  io.println("==========================================")
  io.println("   ESCAPE ROOM: HOSPITAL NO ESCURO")
  io.println("==========================================")

  io.println("")
  io.println("Um apagão atingiu o hospital!")
  io.println("Você pertence à equipe de manutenção.")
  io.println("A sala de Manutenção ficou trancada.")
  io.println("Encontre uma chave, procure pistas e restaure a energia.")
  io.println("Cuidado: caminhar pelo Corredor sem lanterna é perigoso.")
  io.println("Seu objetivo é liberar a porta magnética de emergência.")
  io.println("")

  display_main_menu()

  let estado_inicial = novo_jogo("Ana")
  io.println("\nIniciando partida...")
  exibir_status(estado_inicial)

  let _estado_final = executar_roteiro(estado_inicial, roteiro_demonstracao())
  io.println("\n==========================================")
}