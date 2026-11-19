
//// Hospital no Escuro - menu interativo de terminal.
//// Baseado no exemplo do professor: in.read_line, case e recursao.

import gleam/int
import gleam/io
import gleam/list
import gleam/string
import in
import jogo
import objeto

// Remove a quebra de linha da entrada do teclado.
fn ler_entrada() -> String {
  case in.read_line() {
    Ok(linha) -> string.trim(linha)
    Error(_) -> "0"
  }
}

fn linha() {
  io.println("------------------------------------------------------------")
}

fn introducao() {
  linha()
  io.println("              HOSPITAL NO ESCURO")
  linha()
  io.println("Voce e um tecnico da equipe de manutencao de um hospital.")
  io.println("Um apagao interrompeu a energia e a sala ficou trancada.")
  io.println("Encontre a chave, investigue os ambientes e religue o gerador.")
  io.println("Cuidado: andar pelo Corredor sem lanterna causa quedas de 10 HP.")
  io.println("Utilizar o painel sem iluminacao causa choque de 20 HP.")
  io.println("Objetivo: liberar a rota e abrir a porta de emergencia.")
  linha()
}

fn mostrar_situacao(estado: jogo.Estado) {
  let nome = estado.jogador.nome
  let local = estado.jogador.localizacao
  let vida = int.to_string(estado.jogador.pontos_de_vida)

  io.println(
    "Jogador: " <> nome
    <> " | Sala: " <> local
    <> " | HP: " <> vida
  )
}

// Executa uma acao e continua a partida com o estado atualizado.
fn executar_e_voltar(estado: jogo.Estado, acao: jogo.Acao) {
  let resultado = jogo.executar(estado, acao)

  io.println("")
  io.println("> " <> resultado.1)

  menu_principal(resultado.0)
}

// Lista os objetos existentes na sala.
fn listar_objetos(itens: List(objeto.Objeto), numero: Int) {
  case itens {
    [] -> Nil

    [primeiro, ..resto] -> {
      io.println(
        int.to_string(numero)
        <> " - "
        <> objeto.descrever(primeiro)
      )

      listar_objetos(resto, numero + 1)
    }
  }
}

// Lista os caminhos que saem da sala atual.
fn listar_destinos(destinos: List(String), numero: Int) {
  case destinos {
    [] -> Nil

    [primeiro, ..resto] -> {
      io.println(int.to_string(numero) <> " - " <> primeiro)
      listar_destinos(resto, numero + 1)
    }
  }
}

fn escolher_objeto(estado: jogo.Estado) {
  let sala = jogo.sala_atual(estado)

  io.println("")
  linha()
  io.println("OBJETOS EM: " <> sala.nome)
  linha()

  listar_objetos(sala.objetos, 1)

  io.println("0 - Voltar")
  io.println("Escolha o numero do objeto:")

  case ler_entrada() {
    "0" -> menu_principal(estado)

    resposta ->
      case int.parse(resposta) {
        Ok(numero) if numero > 0 ->
          case list.at(sala.objetos, numero - 1) {
            Ok(item) ->
              executar_e_voltar(estado, jogo.Usar(item.nome))

            Error(_) -> {
              io.println("Objeto inexistente.")
              escolher_objeto(estado)
            }
          }

        _ -> {
          io.println("Opcao invalida.")
          escolher_objeto(estado)
        }
      }
  }
}

fn escolher_destino(estado: jogo.Estado) {
  let sala = jogo.sala_atual(estado)

  io.println("")
  linha()
  io.println("SAIDAS DE: " <> sala.nome)
  linha()

  listar_destinos(sala.saidas, 1)

  io.println("0 - Voltar")
  io.println("Escolha o numero do destino:")

  case ler_entrada() {
    "0" -> menu_principal(estado)

    resposta ->
      case int.parse(resposta) {
        Ok(numero) if numero > 0 ->
          case list.at(sala.saidas, numero - 1) {
            Ok(destino) ->
              executar_e_voltar(estado, jogo.Ir(destino))

            Error(_) -> {
              io.println("Destino inexistente.")
              escolher_destino(estado)
            }
          }

        _ -> {
          io.println("Opcao invalida.")
          escolher_destino(estado)
        }
      }
  }
}

fn responder_enigma(estado: jogo.Estado) {
  io.println("")
  linha()
  io.println("ENIGMA DA SALA ATUAL")
  linha()

  io.println(jogo.executar(estado, jogo.Enigmas).1)
  io.println("Digite a resposta (ou 0 para voltar):")

  case ler_entrada() {
    "0" -> menu_principal(estado)

    "" -> {
      io.println("A resposta nao pode estar vazia.")
      responder_enigma(estado)
    }

    resposta ->
      executar_e_voltar(estado, jogo.Responder(resposta))
  }
}

fn menu_encerrado(estado: jogo.Estado) {
  io.println("")
  linha()

  case jogo.situacao(estado) {
    jogo.Vitoria ->
      io.println("VITORIA! A porta de emergencia foi aberta.")

    jogo.Derrota ->
      io.println("DERROTA! Seus pontos de vida acabaram.")

    jogo.EmAndamento ->
      io.println("Partida em andamento.")
  }

  mostrar_situacao(estado)

  io.println("7 - Jogar novamente")
  io.println("0 - Sair")

  case ler_entrada() {
    "7" -> {
      introducao()
      menu_principal(jogo.novo_jogo(estado.jogador.nome))
    }

    "0" ->
      io.println("Programa encerrado.")

    _ -> {
      io.println("Opcao invalida.")
      menu_encerrado(estado)
    }
  }
}

// Menu principal: preserva o estado entre as escolhas.
fn menu_principal(estado: jogo.Estado) {
  case jogo.situacao(estado) {
    jogo.Vitoria -> menu_encerrado(estado)
    jogo.Derrota -> menu_encerrado(estado)

    jogo.EmAndamento -> {
      io.println("")
      linha()
      io.println("HOSPITAL NO ESCURO  |  MENU PRINCIPAL")
      mostrar_situacao(estado)
      linha()

      io.println("1 - Explorar ambiente")
      io.println("2 - Consultar inventario")
      io.println("3 - Examinar enigma e pistas")
      io.println("4 - Usar objeto da sala")
      io.println("5 - Mudar de sala")
      io.println("6 - Responder enigma")
      io.println("7 - Reiniciar partida")
      io.println("0 - Encerrar jogo")
      io.println("Digite a opcao e pressione Enter:")

      case ler_entrada() {
        "1" ->
          executar_e_voltar(estado, jogo.Explorar)

        "2" ->
          executar_e_voltar(estado, jogo.Inventario)

        "3" ->
          executar_e_voltar(estado, jogo.Enigmas)

        "4" ->
          escolher_objeto(estado)

        "5" ->
          escolher_destino(estado)

        "6" ->
          responder_enigma(estado)

        "7" -> {
          io.println("Partida reiniciada.")
          menu_principal(jogo.novo_jogo(estado.jogador.nome))
        }

        "0" ->
          io.println("Programa encerrado.")

        _ -> {
          io.println("Opcao invalida. Digite um numero entre 0 e 7.")
          menu_principal(estado)
        }
      }
    }
  }
}

// Ponto de entrada da partida interativa.
pub fn main() {
  introducao()

  io.println("Nome do jogador (Enter para usar Tecnico):")
  let nome_digitado = ler_entrada()

  let nome = case nome_digitado {
    "" -> "Tecnico"
    outro -> outro
  }

  menu_principal(jogo.novo_jogo(nome))
}
