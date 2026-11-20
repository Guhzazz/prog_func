//// Módulo menu — camada de apresentação do simulador Hospital no Escuro.
//// Concentra a exibição no terminal (gleam/io), os tipos soma de navegação
//// e as funções nomeadas (m1, m2, ..., exit).

import gleam/int
import gleam/io
import gleam/list
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
      io.println("Esta partida já foi encerrada.")
      Encerrada
    }
    Partida(_), Sair -> {
      io.println("Simulação encerrada pelo jogador.")
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
  let assert Partida(estado) = jogar(partida, m5(), "Corredor")
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
  passos: List(#(MainMenu, String)),
) -> Estado {
  case passos {
    [] -> estado
    [#(Sair, arg), ..] -> executar_menu(estado, Sair, arg)
    [#(opcao, arg), ..resto] -> {
      let proximo = executar_menu(estado, opcao, arg)
      case situacao(proximo) {
        EmAndamento -> executar_roteiro(proximo, resto)
        _ -> proximo
      }
    }
  }
}

pub fn executar_roteiro_examples() {
  let e = novo_jogo("Ana")
  check.eq(executar_roteiro(e, [#(exit(), ""), #(m5(), "Corredor")]), e)
}

/// Roteiro completo de fuga do Hospital no Escuro usando as funções de menu.
pub fn roteiro_demonstracao() -> List(#(MainMenu, String)) {
  [
    #(m1(), ""),
    #(m4(), "lanterna"),
    #(m4(), "chave"),
    #(m4(), "registro"),
    #(m4(), "planta"),
    #(m2(), ""),
    #(m5(), "Corredor"),
    #(m4(), "crachá"),
    #(m3(), ""),
    #(m6(), "3"),
    #(m5(), "Sala 3"),
    #(m4(), "painel"),
    #(m3(), ""),
    #(m6(), "312"),
    #(m5(), "Saída"),
    #(m3(), ""),
    #(m6(), "B12"),
    #(m4(), "porta de emergência"),
  ]
}

pub fn roteiro_demonstracao_examples() {
  let inicial = novo_jogo("Ana")
  let final =
    list.fold(roteiro_demonstracao(), inicial, fn(est, passo) {
      case opcao_para_acao(passo.0, passo.1) {
        Ok(acao) -> executar(est, acao).0
        Error(Nil) -> est
      }
    })
  check.eq(situacao(final), Vitoria)
  check.eq(sala_atual(final).nome, "Saída")
}

/// Apresenta o menu e o comando para iniciar uma partida manual.
pub fn main() -> Nil {
  io.println("==========================================")
  io.println("   ESCAPE ROOM: HOSPITAL NO ESCURO")
  io.println("==========================================")
  display_main_menu()

  io.println("\nPara jogar, execute sgleam -i menu.gleam e digite:")
  io.println("let p = iniciar(\"Ana\")")
}
