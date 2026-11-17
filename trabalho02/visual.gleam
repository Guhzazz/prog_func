//// Interface grafica do Hospital no Escuro para SGleam Web.
//// Reutiliza as regras puras de jogo.gleam: nao replica regras aqui.

import gleam/list
import gleam/string
import jogo
import sgleam/check
import sgleam/fill
import sgleam/image
import sgleam/world

pub type Pagina {
  Introducao
  Principal
  Objetos
  Destinos
  Resposta
}

pub type Tela {
  Tela(
    estado: jogo.Estado,
    pagina: Pagina,
    digitado: String,
    mensagem: String,
  )
}

pub fn iniciar() -> Tela {
  Tela(
    estado: jogo.novo_jogo("Tecnico"),
    pagina: Introducao,
    digitado: "",
    mensagem: "",
  )
}


fn opcoes(tela: Tela) -> List(String) {
  let sala = jogo.sala_atual(tela.estado)
  case tela.pagina {
    Introducao -> []
    Principal -> [
      "Explorar ambiente",
      "Consultar inventario",
      "Examinar enigma e pistas",
      "Usar ou coletar objeto",
      "Ir para outra sala",
      "Responder enigma",
      "Reiniciar partida",
    ]
    Objetos -> list.map(sala.objetos, fn(o) { o.nome })
    Destinos -> sala.saidas
    Resposta -> []
  }
}

fn cabecalho(pagina: Pagina) -> String {
  case pagina {
    Introducao -> "INTRODUCAO"
    Principal -> "MENU PRINCIPAL"
    Objetos -> "ESCOLHA UM OBJETO"
    Destinos -> "ESCOLHA UM DESTINO"
    Resposta -> "DIGITE A RESPOSTA"
  }
}

fn estado_partida(estado: jogo.Estado) -> String {
  case jogo.situacao(estado) {
    jogo.EmAndamento -> "EM ANDAMENTO"
    jogo.Vitoria -> "VITORIA - ROTA LIBERADA!"
    jogo.Derrota -> "DERROTA - SEM VIDA"
  }
}

// image.place_image posiciona o CENTRO da imagem na coordenada escolhida.
// Calculando metade da largura, podemos alinhar o texto a esquerda.
fn texto(
  cena: image.Image,
  conteudo: String,
  x: Int,
  y: Int,
  tamanho: Int,
) -> image.Image {
  let letra = image.text(conteudo, tamanho, fill.white)
  image.place_image(cena, x + image.width(letra) / 2, y, letra)
}

fn texto_aux(
  cena: image.Image,
  conteudo: String,
  x: Int,
  y: Int,
  tamanho: Int,
) -> image.Image {
  let letra = image.text(conteudo, tamanho, fill.lightsteelblue)
  image.place_image(cena, x + image.width(letra) / 2, y, letra)
}

fn texto_ouro(
  cena: image.Image,
  conteudo: String,
  x: Int,
  y: Int,
  tamanho: Int,
) -> image.Image {
  let letra = image.text(conteudo, tamanho, fill.gold)
  image.place_image(cena, x + image.width(letra) / 2, y, letra)
}

// Separa o texto em linhas com limite aproximado de caracteres.
fn quebrar_palavras(
  palavras: List(String),
  atual: String,
  acumulado: List(String),
) -> List(String) {
  case palavras {
    [] ->
      case atual {
        "" -> list.reverse(acumulado)
        _ -> list.reverse([atual, ..acumulado])
      }
    [palavra, ..resto] -> {
      let candidato = case atual {
        "" -> palavra
        _ -> atual <> " " <> palavra
      }
      case string.length(candidato) > 67 && atual != "" {
        True -> quebrar_palavras(resto, palavra, [atual, ..acumulado])
        False -> quebrar_palavras(resto, candidato, acumulado)
      }
    }
  }
}

fn quebrar(conteudo: String) -> List(String) {
  let sem_quebra = string.replace(conteudo, "\n", " ")
  quebrar_palavras(string.split(sem_quebra, " "), "", [])
}

fn linhas(
  cena: image.Image,
  textos: List(String),
  x: Int,
  y: Int,
  tamanho: Int,
  restantes: Int,
) -> image.Image {
  case textos {
    [primeira, ..resto] if restantes > 0 ->
      linhas(texto(cena, primeira, x, y, tamanho), resto, x, y + 23, tamanho, restantes - 1)
    _ -> cena
  }
}

fn desenhar_opcoes(
  cena: image.Image,
  opcoes: List(String),
  numero: Int,
  y: Int,
) -> image.Image {
  case opcoes {
    [] -> cena
    [opcao, ..resto] -> {
      let cena = image.place_image(
        cena,
        480,
        y,
        image.rectangle(870, 31, fill.darkslategray),
      )
      let cena = texto_ouro(cena, string.inspect(numero) <> ".", 60, y, 19)
      let cena = texto(cena, opcao, 103, y, 19)
      desenhar_opcoes(cena, resto, numero + 1, y + 41)
    }
  }
}

fn desenhar_introducao(cena: image.Image) -> image.Image {
  let cena = texto_ouro(cena, "A LUZ ACABOU", 52, 139, 27)
  let cena = texto(cena, "Voce faz parte da equipe de manutencao de um hospital.", 52, 195, 20)
  let cena = texto(cena, "Durante o expediente, um apagao derrubou a energia.", 52, 232, 20)
  let cena = texto(cena, "A porta da Manutencao ficou trancada. Voces precisam evacuar.", 52, 269, 20)
  let cena = texto(cena, "Procure pistas, acione o gerador e reabra a saida de emergencia.", 52, 306, 20)
  let cena = texto_ouro(cena, "ATENCAO: caminhar pelo corredor sem luz causa quedas!", 52, 374, 20)
  let cena = texto_aux(cena, "Choques no painel eletrico tambem sao perigosos.", 52, 414, 18)
  let cena = texto(cena, "Pressione ENTER para iniciar uma nova partida.", 52, 504, 23)
  texto_aux(cena, "A senha e fixa para todas as partidas. Consulte a planta.", 52, 552, 16)
}

pub fn desenhar(tela: Tela) -> image.Image {
  let cena = image.rectangle(960, 700, fill.midnightblue)
  let cena = image.place_image(cena, 480, 46, image.rectangle(930, 70, fill.darkslategray))
  let cena = texto_ouro(cena, "HOSPITAL NO ESCURO", 38, 46, 27)

  case tela.pagina {
    Introducao -> desenhar_introducao(cena)
    _ -> {
      let sala = jogo.sala_atual(tela.estado)
      let vida = string.inspect(tela.estado.jogador.pontos_de_vida)
      let cena = texto_aux(cena, "LOCAL: " <> sala.nome, 45, 107, 19)
      let cena = texto_aux(cena, "HP: " <> vida, 740, 107, 19)
      let cena = texto_aux(cena, estado_partida(tela.estado), 45, 135, 15)
      let cena = linhas(cena, quebrar(sala.descricao), 45, 172, 16, 2)
      let cena = image.place_image(cena, 480, 245, image.rectangle(920, 96, fill.darkslategray))
      let cena = texto_ouro(cena, "MENSAGEM", 48, 213, 15)
      let cena = linhas(cena, quebrar(tela.mensagem), 48, 240, 15, 3)
      let cena = texto_ouro(cena, cabecalho(tela.pagina), 48, 319, 20)
      let cena = case tela.pagina {
        Resposta -> {
          let cena = texto(cena, "Digite a senha: " <> tela.digitado <> "_", 70, 389, 23)
          texto_aux(cena, "ENTER: confirmar | BACKSPACE: apagar | ESC: voltar", 70, 445, 16)
        }
        _ ->
          case opcoes(tela) {
            [] -> texto_aux(cena, "Nenhuma opcao disponivel. Pressione ESC.", 70, 381, 17)
            opcoes -> desenhar_opcoes(cena, opcoes, 1, 365)
          }
      }
      let ajuda = case jogo.situacao(tela.estado) {
        jogo.EmAndamento -> "TECLAS 1-7: escolher | ESC: voltar | ENTER: enviar resposta"
        _ -> "PARTIDA ENCERRADA | TECLA 7: reiniciar pelo menu | ESC: menu"
      }
      texto_aux(cena, ajuda, 40, 679, 14)
    }
  }
}

fn executar_acao(tela: Tela, acao: jogo.Acao) -> Tela {
  let #(estado, mensagem) = jogo.executar(tela.estado, acao)
  Tela(
    ..tela,
    estado: estado,
    pagina: Principal,
    digitado: "",
    mensagem: mensagem,
  )
}

fn selecionar(tela: Tela, indice: Int) -> Tela {
  case tela.pagina {
    Introducao -> tela
    Principal ->
      case indice {
        0 -> executar_acao(tela, jogo.Explorar)
        1 -> executar_acao(tela, jogo.Inventario)
        2 -> executar_acao(tela, jogo.Enigmas)
        3 -> Tela(..tela, pagina: Objetos, mensagem: "Selecione o objeto que deseja usar.")
        4 -> Tela(..tela, pagina: Destinos, mensagem: "Selecione o destino desejado.")
        5 -> Tela(..tela, pagina: Resposta, digitado: "", mensagem: "Digite a resposta do enigma desta sala.")
        6 -> iniciar()
        _ -> tela
      }
    Objetos ->
      case list.at(jogo.sala_atual(tela.estado).objetos, indice) {
        Ok(objeto) -> executar_acao(tela, jogo.Usar(objeto.nome))
        Error(_) -> tela
      }
    Destinos ->
      case list.at(jogo.sala_atual(tela.estado).saidas, indice) {
        Ok(destino) -> executar_acao(tela, jogo.Ir(destino))
        Error(_) -> tela
      }
    Resposta -> tela
  }
}

fn indice_numero(numero: String) -> Result(Int, Nil) {
  case numero {
    "1" -> Ok(0)
    "2" -> Ok(1)
    "3" -> Ok(2)
    "4" -> Ok(3)
    "5" -> Ok(4)
    "6" -> Ok(5)
    "7" -> Ok(6)
    _ -> Error(Nil)
  }
}

pub fn tratar_tecla(tela: Tela, tecla: world.Key) -> Tela {
  case tela.pagina {
    Introducao ->
      case tecla {
        world.Enter -> Tela(
          ..tela,
          estado: jogo.novo_jogo("Tecnico"),
          pagina: Principal,
          mensagem: "Encontre a chave para sair da manutencao. Nao esqueça a lanterna!",
        )
        _ -> tela
      }
    Resposta ->
      case tecla {
        world.Escape -> Tela(..tela, pagina: Principal, digitado: "")
        world.Backspace ->
          case string.length(tela.digitado) > 0 {
            True -> Tela(..tela, digitado: string.slice(tela.digitado, 0, string.length(tela.digitado) - 1))
            False -> tela
          }
        world.Enter ->
          case string.trim(tela.digitado) {
            "" -> Tela(..tela, mensagem: "Digite uma resposta antes de confirmar.")
            resposta -> executar_acao(tela, jogo.Responder(resposta))
          }
        world.Char(caractere) ->
          case string.length(tela.digitado) < 8 {
            True -> Tela(..tela, digitado: tela.digitado <> caractere)
            False -> tela
          }
        _ -> tela
      }
    _ ->
      case tecla {
        world.Escape -> Tela(..tela, pagina: Principal)
        world.Char(caractere) ->
          case indice_numero(caractere) {
            Error(_) -> tela
            Ok(i) ->
              case i < list.length(opcoes(tela)) {
                True -> selecionar(tela, i)
                False -> tela
              }
          }
        _ -> tela
      }
  }
}

/// Execute este main no SGleam Web com os outros modulos carregados.
pub fn main() {
  world.create(iniciar(), desenhar)
  |> world.on_key_down(tratar_tecla)
  |> world.run()
}

pub fn visual_examples() {
  let intro = iniciar()
  check.eq(intro.pagina, Introducao)
  let tela = tratar_tecla(intro, world.Enter)
  check.eq(tela.pagina, Principal)
  let objs = tratar_tecla(tela, world.Char("4"))
  check.eq(objs.pagina, Objetos)
  let usada = tratar_tecla(objs, world.Char("1"))
  check.eq(usada.pagina, Principal)
  check.eq(jogador_tem_lanterna(usada), True)
}

fn jogador_tem_lanterna(tela: Tela) -> Bool {
  list.contains(tela.estado.jogador.inventario, "lanterna")
}
