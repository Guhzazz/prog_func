
//// Interface gráfica do Hospital no Escuro.
//// Todas as regras continuam no módulo jogo.

import gleam/bit_array
import gleam/list
import gleam/result
import gleam/string
import jogo
import sgleam/check
import sgleam/fill
import sgleam/image
import sgleam/key
import sgleam/world


pub type Tela {
  Tela(
    estado: jogo.Estado,
    pagina: String,
    digitado: String,
    mensagem: String,
  )
}

pub fn iniciar() -> Tela {
  Tela(
    estado: jogo.novo_jogo("Técnico"),
    pagina: "introducao",
    digitado: "",
    mensagem: "",
  )
}

// Coloca texto na cena, alinhado à esquerda.
fn escrever(
  cena: image.Image,
  conteudo: String,
  x: Int,
  y: Int,
  tamanho: Int,
) -> image.Image {
  let frase = image.text(conteudo, tamanho, fill.rgb(24, 48, 50))

  image.place_image(
    cena,
    x + image.width(frase) / 2,
    y,
    frase,
  )
}

// Mesmo procedimento, com texto dourado.
fn escrever_destaque(
  cena: image.Image,
  conteudo: String,
  x: Int,
  y: Int,
  tamanho: Int,
) -> image.Image {
  let frase = image.text(conteudo, tamanho, fill.rgb(11, 91, 86))

  image.place_image(
    cena,
    x + image.width(frase) / 2,
    y,
    frase,
  )
}

// Divide mensagens grandes em até cinco trechos.
// Quebra um texto em várias linhas sem cortar palavras.
fn separar_linhas(
  palavras: List(String),
  atual: String,
  acumuladas: List(String),
  limite: Int,
) -> List(String) {
  case palavras {
    [] ->
      case atual {
        "" -> list.reverse(acumuladas)
        _ -> list.reverse([atual, ..acumuladas])
      }

    [palavra, ..resto] -> {
      let candidato = case atual {
        "" -> palavra
        _ -> atual <> " " <> palavra
      }

      case string.length(candidato) > limite && atual != "" {
        True ->
          separar_linhas(
            resto,
            palavra,
            [atual, ..acumuladas],
            limite,
          )

        False ->
          separar_linhas(
            resto,
            candidato,
            acumuladas,
            limite,
          )
      }
    }
  }
}

// Prepara o texto para ser quebrado em linhas.
fn texto_em_linhas(texto: String, limite: Int) -> List(String) {
  texto
  |> string.split("\n")
  |> list.flat_map(fn(linha) {
    separar_linhas(string.split(linha, " "), "", [], limite)
  })
}

// Desenha uma lista de linhas na tela.
fn desenhar_linhas(
  cena: image.Image,
  linhas_texto: List(String),
  x: Int,
  y: Int,
  restantes: Int,
) -> image.Image {
  case linhas_texto {
    [linha, ..resto] if restantes > 0 -> {
      let cena = escrever(cena, linha, x, y, 16)
      desenhar_linhas(cena, resto, x, y + 22, restantes - 1)
    }

    _ -> cena
  }
}

// Desenha a mensagem quebrando por palavras, e não no meio delas.
fn mensagem_em_linhas(
  cena: image.Image,
  texto: String,
  x: Int,
  y: Int,
  linhas: Int,
) -> image.Image {
  desenhar_linhas(
    cena,
    texto_em_linhas(texto, 94),
    x,
    y,
    linhas,
  )
}

// Devolve as opções conforme a página atual.
fn opcoes(tela: Tela) -> List(String) {
  let sala = jogo.sala_atual(tela.estado)

  case tela.pagina {
    "principal" -> [
      "Explorar ambiente",
      "Consultar inventário",
      "Examinar enigma e pistas",
      "Usar objeto",
      "Mudar de sala",
      "Responder enigma",
      "Reiniciar partida",
    ]

    "objetos" ->
      list.map(sala.objetos, fn(obj) { obj.nome })

    "destinos" -> sala.saidas

    _ -> []
  }
}

// Desenha cada opção e seu número recursivamente.
fn listar_opcoes(
  cena: image.Image,
  itens: List(String),
  numero: Int,
  y: Int,
) -> image.Image {
  case itens {
    [] -> cena

    [primeiro, ..resto] -> {
      let cena = escrever_destaque(
        cena,
        string.inspect(numero) <> ".",
        52,
        y,
        19,
      )

      let cena = escrever(
        cena,
        primeiro,
        105,
        y,
        19,
      )

      listar_opcoes(
        cena,
        resto,
        numero + 1,
        y + 40,
      )
    }
  }
}

// Mensagem inicial com a história do hospital.
fn desenhar_introducao(cena: image.Image) -> image.Image {
  let cena = escrever_destaque(
    cena,
    "APAGÃO NO HOSPITAL",
    55,
    150,
    27,
  )

  let cena = escrever(
    cena,
    "Você faz parte da equipe de manutenção do hospital.",
    55,
    220,
    20,
  )

  let cena = escrever(
    cena,
    "Durante o expediente, as luzes se apagaram e as portas travaram.",
    55,
    260,
    19,
  )

  let cena = escrever(
    cena,
    "Você ficou preso na sala de Manutenção.",
    55,
    300,
    19,
  )

  let cena = escrever(
    cena,
    "Encontre pistas, ligue o gerador e libere a saída de emergência.",
    55,
    340,
    19,
  )

  let cena = escrever_destaque(
    cena,
    "CUIDADO: andar no corredor sem lanterna provoca quedas!",
    55,
    425,
    19,
  )

  let cena = escrever(
    cena,
    "O painel elétrico também pode causar choques perigosos.",
    55,
    462,
    18,
  )

  escrever_destaque(
    cena,
    "PRESSIONE ENTER PARA COMEÇAR",
    55,
    565,
    22,
  )
}

fn situacao_texto(estado: jogo.Estado) -> String {
  case jogo.situacao(estado) {
    jogo.EmAndamento -> "Em andamento"
    jogo.Vitoria -> "Vitória"
    jogo.Derrota -> "Derrota"
  }
}

// Função que desenha toda a interface.
pub fn desenhar(tela: Tela) -> image.Image {
  let cena = image.rectangle(
    900,
    700,
    fill.midnightblue,
  )

  let cena = image.place_image(
    cena,
    865,
    68,
    image.rectangle(865, 68, fill.rgb(199, 240, 232)),
  )

  let cena = escrever_destaque(
    cena,
    "HOSPITAL NO ESCURO",
    42,
    47,
    27,
  )

  case tela.pagina {
    "introducao" ->
      desenhar_introducao(cena)

    _ -> {
      let sala = jogo.sala_atual(tela.estado)

      let vida =
        string.inspect(tela.estado.jogador.pontos_de_vida)

      let situacao = situacao_texto(tela.estado) {
        jogo.EmAndamento -> "EM ANDAMENTO"
        jogo.Vitoria -> "VITÓRIA"
        jogo.Derrota -> "DERROTA"
      }

      let cena = escrever(
        cena,
        "SALA: " <> sala.nome,
        47,
        111,
        19,
      )

      let cena = escrever(
        cena,
        "VIDA: " <> vida <> " HP",
        640,
        111,
        19,
      )

      let cena = escrever_destaque(
        cena,
        situacao,
        47,
        145,
        16,
      )

      let cena = image.place_image(
        cena,
        450,
        248,
        image.rectangle(862, 216, fill.rgb(229, 248, 244)),
      )

      let cena = escrever_destaque(
        cena,
        "MENSAGEM",
        45,
        195,
        17,
      )

      let cena = mensagem_em_linhas(
        cena,
        tela.mensagem,
        45,
        226,
        8,
      )

      let cena = case tela.pagina {
        "resposta" -> {
          let cena = escrever_destaque(
            cena,
            "DIGITE SUA RESPOSTA",
            45,
            423,
            20,
          )

          let cena = escrever(
            cena,
            tela.digitado <> "_",
            60,
            480,
            25,
          )

          escrever(
            cena,
            "ENTER confirma | BACKSPACE apaga | ESC volta",
            50,
            540,
            16,
          )
        }

        _ -> {
          let titulo = case tela.pagina {
            "objetos" -> "OBJETOS DA SALA"
            "destinos" -> "DESTINOS DISPONÍVEIS"
            _ -> "MENU PRINCIPAL"
          }

          let cena = escrever_destaque(
            cena,
            titulo,
            45,
            423,
            20,
          )

          listar_opcoes(
            cena,
            opcoes(tela),
            1,
            469,
          )
        }
      }

      case tela.pagina {
        "resposta" -> cena
        _ ->
          escrever(
            cena,
            "1 a 7 para escolher  •  Esc para voltar",
            42,
            790,
            16,
          )
      }
    }
  }
}

// Executa uma ação usando a lógica original do grupo.
fn executar_acao(
  tela: Tela,
  acao: jogo.Acao,
) -> Tela {
  let resultado = jogo.executar(
    tela.estado,
    acao,
  )

  Tela(
    estado: resultado.0,
    pagina: "principal",
    digitado: "",
    mensagem: resultado.1,
  )
}

// Converte a opção numerada em uma ação.
fn selecionar(tela: Tela, indice: Int) -> Tela {
  case tela.pagina {
    "principal" ->
      case indice {
        0 -> executar_acao(tela, jogo.Explorar)
        1 -> executar_acao(tela, jogo.Inventario)
        2 -> executar_acao(tela, jogo.Enigmas)

        3 ->
          Tela(
            ..tela,
            pagina: "objetos",
            mensagem: "Escolha o objeto pelo número.",
          )

        4 ->
          Tela(
            ..tela,
            pagina: "destinos",
            mensagem: "Escolha um destino pelo número.",
          )

        5 ->
          Tela(
            ..tela,
            pagina: "resposta",
            digitado: "",
            mensagem: "Digite o código e pressione Enter.",
          )

        6 -> iniciar()
        _ -> tela
      }

    "objetos" ->
      case list.drop(jogo.sala_atual(tela.estado).objetos, indice) {
        [obj, ..] -> executar_acao(tela, jogo.Usar(obj.nome))
        [] -> tela
      }

    "destinos" ->
      case list.drop(jogo.sala_atual(tela.estado).saidas, indice) {
        [destino, ..] -> executar_acao(tela, jogo.Ir(destino))
        [] -> tela
      }

    _ -> tela
  }
}

// Converte uma tecla numérica em índice da lista.
fn indice_da_tecla(tecla: String) -> Result(Int, Nil) {
  case tecla {
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

// Recebe o estado e uma tecla, devolvendo a nova tela.
pub fn tratar_tecla(
  tela: Tela,
  tecla: key.Event,
) -> Tela {
  case tela.pagina {
    "introducao" ->
      case tecla {
        key.Enter ->
          Tela(
            ..tela,
            pagina: "principal",
            mensagem: "Encontre a chave e procure uma lanterna.",
          )

        _ -> tela
      }

    "resposta" ->
      case tecla {
        key.Escape ->
          Tela(
            ..tela,
            pagina: "principal",
            digitado: "",
          )

        key.Backspace ->
          case string.length(tela.digitado) > 0 {
            True ->
              Tela(
                ..tela,
                digitado: string.slice(
                  tela.digitado,
                  0,
                  string.length(tela.digitado) - 1,
                ),
              )

            False -> tela
          }

        key.Enter ->
          case string.trim(tela.digitado) {
            "" ->
              Tela(
                ..tela,
                mensagem: "Digite alguma resposta antes de confirmar.",
              )

            resposta ->
              executar_acao(
                tela,
                jogo.Responder(resposta),
              )
          }

        key.Char(caractere) ->
          case string.length(tela.digitado) < 8 {
            True ->
              Tela(
                ..tela,
                digitado: tela.digitado <> caractere,
              )

            False -> tela
          }

        _ -> tela
      }

    _ ->
      case tecla {
        key.Escape ->
          Tela(
            ..tela,
            pagina: "principal",
          )

        key.Char(caractere) ->
          case indice_da_tecla(caractere) {
            Ok(indice) ->
              selecionar(tela, indice)

            Error(_) -> tela
          }

        _ -> tela
      }
  }
}

// Ponto de entrada da interface gráfica.
pub fn smain() {
  world.create(iniciar(), desenhar)
  |> world.on_key_down(tratar_tecla)
}

// Exemplos para testar os comandos básicos.
pub fn visual_examples() {
  let intro = iniciar()

  check.eq(intro.pagina, "introducao")

  let principal = tratar_tecla(
    intro,
    key.Enter,
  )

  check.eq(principal.pagina, "principal")

  let objetos = tratar_tecla(
    principal,
    key.Char("4"),
  )

  check.eq(objetos.pagina, "objetos")

  let depois = tratar_tecla(
    objetos,
    key.Char("1"),
  )

  check.eq(depois.pagina, "principal")

  check.eq(
    list.contains(
      depois.estado.jogador.inventario,
      "lanterna",
    ),
    True,
  )
}



pub fn interacao_examples() {
  let inicial = iniciar()
  check.eq(inicial.pagina, "introducao")

  let partida = tratar_tecla(inicial, key.Enter)
  check.eq(partida.pagina, "principal")

  let objetos = tratar_tecla(partida, key.Char("4"))
  check.eq(objetos.pagina, "objetos")

  let voltou = tratar_tecla(objetos, key.Escape)
  check.eq(voltou.pagina, "principal")

  let resposta = tratar_tecla(voltou, key.Char("6"))
  check.eq(resposta.pagina, "resposta")

  let digitando = tratar_tecla(resposta, key.Char("1"))
  check.eq(digitando.digitado, "1")

  let apagou = tratar_tecla(digitando, key.Backspace)
  check.eq(apagou.digitado, "")

  let vazia = tratar_tecla(apagou, key.Enter)
  check.eq(
    vazia.mensagem,
    "Digite alguma resposta antes de confirmar.",
  )
}

