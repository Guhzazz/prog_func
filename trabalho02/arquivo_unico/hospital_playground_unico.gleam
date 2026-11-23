//// Demonstracao visual em ARQUIVO UNICO para SGleam Web, caso a local modularizada não funcione
//// Esta e uma adaptacao independente das regras, sem imports de outros .gleam.
//// Baseada na API dos slides: world.create, world.on_key_down, world.run.

import gleam/string
import sgleam/fill
import sgleam/image
import sgleam/world

pub const codigo_saida = "B47"

pub type Estado {
  Estado(
    sala: String, vida: Int, chave: Bool, lanterna: Bool,
    registro: Bool, planta: Bool, cracha: Bool, acesso: Bool,
    gerador: Bool, energia: Bool, codigo: Bool, rota: Bool, porta: Bool,
  )
}

pub type Tela {
  Tela(estado: Estado, pagina: String, digitado: String, mensagem: String)
}

pub fn iniciar() -> Tela {
  Tela(
    estado: Estado("Manutenção", 100, False, False, False, False, False,
      False, False, False, False, False, False),
    pagina: "introducao",
    digitado: "",
    mensagem: "",
  )
}

fn encerrado(e: Estado) -> Bool { e.vida <= 0 || e.porta }

fn dano(e: Estado, n: Int) -> Estado {
  let v = e.vida - n
  Estado(..e, vida: case v < 0 {
    True -> 0
    False -> v
  })
}

fn atual(t: Tela, e: Estado, msg: String) -> Tela {
  Tela(..t, estado: e, pagina: "principal", digitado: "", mensagem: msg)
}

fn avisar(t: Tela, msg: String) -> Tela { atual(t, t.estado, msg) }

fn etiqueta(b: Bool, s: String) -> String {
  case b {
    True -> s <> ", "
    False -> ""
  }
}

fn inventario(e: Estado) -> String {
  let itens =
    etiqueta(e.lanterna, "lanterna") <>
    etiqueta(e.chave, "chave de manutenção") <>
    etiqueta(e.registro, "registro consultado") <>
    etiqueta(e.planta, "planta: " <> codigo_saida) <>
    etiqueta(e.cracha, "crachá") <>
    etiqueta(e.acesso, "acesso corredor") <>
    etiqueta(e.gerador, "gerador ligado") <>
    etiqueta(e.energia, "energia restaurada") <>
    etiqueta(e.codigo, "código evacuação") <>
    etiqueta(e.rota, "rota liberada")
  case itens == "" {
    True -> "Inventário vazio."
    False -> "Inventário: " <> itens
  }
}

fn descricao(e: Estado) -> String {
  case e.sala {
    "Manutenção" -> "A equipe ficou trancada. Há uma lanterna, uma chave, um registro e uma planta."
    "Corredor" -> "Corredor escuro. Um crachá foi deixado no chão. A trava pede uma senha."
    "Sala 3" -> "Sala técnica: gerador auxiliar e painel elétrico. Cuidado com choques!"
    _ -> "O terminal controla a porta magnética da saída de emergência."
  }
}

fn enigma(e: Estado) -> String {
  case e.sala {
    "Corredor" -> "Trava: informe o número da sala onde está o gerador (consulte o registro)."
    "Sala 3" -> "Sequência: número da sala seguido dos dígitos da porta indicados na planta."
    "Saída" -> "Terminal: informe a identificação completa da porta indicada na planta."
    _ -> "Não há enigma nesta sala."
  }
}

fn usar(t: Tela, numero: String) -> Tela {
  let e = t.estado
  case e.sala {
    "Manutenção" ->
      case numero {
        "1" -> case e.lanterna {
          True -> avisar(t, "A lanterna já foi coletada.")
          False -> atual(t, Estado(..e, lanterna: True), "Você encontrou uma lanterna funcional.")
        }
        "2" -> case e.chave {
          True -> avisar(t, "A chave já foi coletada.")
          False -> atual(t, Estado(..e, chave: True), "Você pegou a chave de manutenção.")
        }
        "3" -> case e.registro {
          True -> avisar(t, "Você já consultou o registro: o gerador fica na sala 3.")
          False -> atual(t, Estado(..e, registro: True), "Registro: o gerador auxiliar fica na sala 3.")
        }
        "4" -> case e.planta {
          True -> avisar(t, "A planta registra a porta técnica " <> codigo_saida <> ".")
          False -> atual(t, Estado(..e, planta: True), "Na planta há uma anotação: porta técnica " <> codigo_saida <> ".")
        }
        _ -> avisar(t, "Objeto inválido nesta sala.")
      }
    "Corredor" ->
      case numero {
        "1" -> case e.cracha {
          True -> avisar(t, "Você já pegou o crachá.")
          False -> atual(t, Estado(..e, cracha: True), "Você encontrou o crachá da equipe técnica.")
        }
        _ -> avisar(t, "Objeto inválido nesta sala.")
      }
    "Sala 3" ->
      case numero {
        "1" ->
          case e.gerador {
            True -> avisar(t, "O gerador já está ligado.")
            False -> case e.lanterna {
              True -> atual(t, Estado(..e, gerador: True), "Com a lanterna, você ligou o gerador auxiliar.")
              False -> avisar(t, "Sem lanterna, não é possível localizar os controles do gerador.")
            }
          }
        "2" ->
          case e.energia {
            True -> avisar(t, "A energia do hospital já foi restabelecida.")
            False -> case e.lanterna {
              False -> atual(t, dano(e, 20), "Choque elétrico: você perdeu 20 HP por usar o painel sem luz!")
              True -> case e.cracha {
                False -> avisar(t, "O painel exige o crachá de manutenção.")
                True -> case e.gerador {
                  False -> avisar(t, "Primeiro você precisa ligar o gerador auxiliar.")
                  True -> atual(t, Estado(..e, energia: True), "Painel acionado! A energia foi restabelecida.")
                }
              }
            }
          }
        _ -> avisar(t, "Objeto inválido nesta sala.")
      }
    "Saída" ->
      case numero {
        "1" ->
          case e.porta {
            True -> avisar(t, "A porta já está aberta.")
            False -> case e.energia && e.cracha && e.rota {
              True -> atual(t, Estado(..e, porta: True), "A tranca magnética abriu. Evacuação concluída!")
              False -> avisar(t, "A porta exige energia restaurada, crachá e liberação do terminal.")
            }
          }
        _ -> avisar(t, "Objeto inválido nesta sala.")
      }
    _ -> avisar(t, "Sala desconhecida.")
  }
}

fn ir(t: Tela, numero: String) -> Tela {
  let e = t.estado
  case e.sala {
    "Manutenção" -> case numero {
      "1" -> case e.chave {
        False -> avisar(t, "A porta da Manutenção está trancada. Procure a chave.")
        True -> entrar(t, "Corredor")
      }
      _ -> avisar(t, "Destino inválido.")
    }
    "Corredor" -> case numero {
      "1" -> entrar(t, "Manutenção")
      "2" -> case e.acesso {
        True -> entrar(t, "Sala 3")
        False -> avisar(t, "A trava da Sala 3 ainda não foi resolvida.")
      }
      _ -> avisar(t, "Destino inválido.")
    }
    "Sala 3" -> case numero {
      "1" -> entrar(t, "Corredor")
      "2" -> case e.codigo {
        True -> entrar(t, "Saída")
        False -> avisar(t, "Falta obter o código de evacuação.")
      }
      _ -> avisar(t, "Destino inválido.")
    }
    "Saída" -> case numero {
      "1" -> entrar(t, "Sala 3")
      _ -> avisar(t, "Destino inválido.")
    }
    _ -> avisar(t, "Sala desconhecida.")
  }
}

fn entrar(t: Tela, destino: String) -> Tela {
  let e = Estado(..t.estado, sala: destino)
  case destino == "Corredor" && !e.lanterna {
    True -> atual(t, dano(e, 10), "Você tropeçou no Corredor escuro e perdeu 10 HP!")
    False -> atual(t, e, "Você entrou em " <> destino <> ".")
  }
}

fn responder(t: Tela, texto: String) -> Tela {
  let e = t.estado
  let r = string.lowercase(string.trim(texto))
  case e.sala {
    "Corredor" -> case e.acesso {
      True -> avisar(t, "A trava já está resolvida.")
      False -> case r == "3" {
        True -> atual(t, Estado(..e, acesso: True), "Correto! O acesso à Sala 3 foi liberado.")
        False -> avisar(t, "Resposta incorreta. Releia o registro de manutenção.")
      }
    }
    "Sala 3" -> case e.energia && e.planta {
      False -> avisar(t, "Restaure a energia e consulte a planta antes de resolver a sequência.")
      True -> case e.codigo {
        True -> avisar(t, "Sequência já resolvida.")
        False -> case r == "347" {
          True -> atual(t, Estado(..e, codigo: True), "Sequência aceita! Código de evacuação liberado.")
          False -> avisar(t, "Resposta incorreta. Combine sala 3 e dígitos da planta.")
        }
      }
    }
    "Saída" -> case e.energia && e.planta {
      False -> avisar(t, "O terminal exige energia e a identificação encontrada na planta.")
      True -> case e.rota {
        True -> avisar(t, "O terminal já liberou a rota.")
        False -> case r == string.lowercase(codigo_saida) {
          True -> atual(t, Estado(..e, rota: True), "Terminal autorizado. Agora use a porta de emergência.")
          False -> avisar(t, "Identificação incorreta. Consulte a planta do hospital.")
        }
      }
    }
    _ -> avisar(t, "Não há enigma nesta sala.")
  }
}

fn opcoes(e: Estado, pagina: String) -> List(String) {
  case pagina {
    "principal" -> [
      "1 - Explorar ambiente", "2 - Consultar inventário", "3 - Examinar enigma",
      "4 - Usar objeto", "5 - Mudar de sala", "6 - Responder enigma", "7 - Reiniciar",
    ]
    "objetos" -> case e.sala {
      "Manutenção" -> ["1 - Lanterna", "2 - Chave", "3 - Registro", "4 - Planta", "0 - Voltar"]
      "Corredor" -> ["1 - Crachá", "0 - Voltar"]
      "Sala 3" -> ["1 - Gerador", "2 - Painel elétrico", "0 - Voltar"]
      _ -> ["1 - Porta de emergência", "0 - Voltar"]
    }
    "destinos" -> case e.sala {
      "Manutenção" -> ["1 - Corredor", "0 - Voltar"]
      "Corredor" -> ["1 - Manutenção", "2 - Sala 3", "0 - Voltar"]
      "Sala 3" -> ["1 - Corredor", "2 - Saída", "0 - Voltar"]
      _ -> ["1 - Sala 3", "0 - Voltar"]
    }
    _ -> []
  }
}

fn mostrar_linhas(cena: image.Image, linhas: List(String), y: Int) -> image.Image {
  case linhas {
    [] -> cena
    [primeiro, ..resto] ->
      mostrar_linhas(escrever(cena, primeiro, 60, y, 17), resto, y + 37)
  }
}

fn escrever(cena: image.Image, conteudo: String, x: Int, y: Int, tamanho: Int) -> image.Image {
  let imagem = image.text(conteudo, tamanho, fill.white)
  image.place_image(cena, x + image.width(imagem) / 2, y, imagem)
}

fn mensagem(cena: image.Image, conteudo: String) -> image.Image {
  let cena = escrever(cena, string.slice(conteudo, 0, 85), 50, 235, 15)
  let cena = escrever(cena, string.slice(conteudo, 85, 85), 50, 259, 15)
  escrever(cena, string.slice(conteudo, 170, 85), 50, 283, 15)
}

pub fn desenhar(t: Tela) -> image.Image {
  let cena = image.rectangle(920, 680, fill.midnightblue)
  let cena = image.place_image(cena, 460, 45, image.rectangle(880, 64, fill.darkslategray))
  let cena = escrever(cena, "HOSPITAL NO ESCURO", 55, 47, 27)
  case t.pagina {
    "introducao" -> {
      let linhas = [
        "Você integra a equipe de manutenção de um hospital.",
        "Durante o expediente, um apagão deixou sua sala trancada.",
        "Procure a chave, investigue pistas e religue o gerador.",
        "ATENÇÃO: andar no escuro pode causar quedas e choques!",
        "A tranca magnética só abre com energia, crachá e autorização.",
        "PRESSIONE ENTER PARA COMEÇAR",
      ]
      mostrar_linhas(cena, linhas, 158)
    }
    _ -> {
      let situacao = case t.estado.porta {
        True -> "VITÓRIA"
        False -> case t.estado.vida <= 0 {
          True -> "DERROTA"
          False -> "EM ANDAMENTO"
        }
      }
      let cena = escrever(cena, "SALA: " <> t.estado.sala, 48, 105, 19)
      let cena = escrever(cena, "HP: " <> string.inspect(t.estado.vida), 730, 105, 19)
      let cena = escrever(cena, situacao, 48, 148, 15)
      let cena = image.place_image(cena, 460, 250, image.rectangle(880, 158, fill.darkslategray))
      let cena = escrever(cena, "MENSAGEM:", 50, 193, 16)
      let cena = mensagem(cena, t.mensagem)
      case encerrado(t.estado) {
        True -> {
          let cena = escrever(cena, "FIM DE PARTIDA. PRESSIONE 7 PARA REINICIAR.", 50, 380, 22)
          cena
        }
        False -> case t.pagina {
          "resposta" -> {
            let cena = escrever(cena, "Digite a senha e pressione ENTER:", 50, 377, 20)
            let cena = escrever(cena, t.digitado <> "_", 60, 435, 25)
            escrever(cena, "BACKSPACE apaga | ESC retorna", 50, 590, 17)
          }
          _ -> {
            let titulo = case t.pagina {
              "objetos" -> "ESCOLHA UM OBJETO"
              "destinos" -> "ESCOLHA UM DESTINO"
              _ -> "MENU PRINCIPAL"
            }
            let cena = escrever(cena, titulo, 50, 347, 20)
            let cena = mostrar_linhas(cena, opcoes(t.estado, t.pagina), 395)
            escrever(cena, "Use as TECLAS NUMÉRICAS | ESC para voltar", 50, 648, 15)
          }
        }
      }
    }
  }
}

fn escolher(t: Tela, numero: String) -> Tela {
  case encerrado(t.estado) {
    True -> case numero {
      "7" -> iniciar()
      _ -> t
    }
    False -> case t.pagina {
      "principal" -> case numero {
        "1" -> avisar(t, descricao(t.estado))
        "2" -> avisar(t, inventario(t.estado))
        "3" -> avisar(t, enigma(t.estado))
        "4" -> Tela(..t, pagina: "objetos", mensagem: "Selecione um objeto da sala.")
        "5" -> Tela(..t, pagina: "destinos", mensagem: "Selecione um destino.")
        "6" -> Tela(..t, pagina: "resposta", digitado: "", mensagem: enigma(t.estado))
        "7" -> iniciar()
        _ -> t
      }
      "objetos" -> case numero {
        "0" -> Tela(..t, pagina: "principal")
        _ -> usar(t, numero)
      }
      "destinos" -> case numero {
        "0" -> Tela(..t, pagina: "principal")
        _ -> ir(t, numero)
      }
      _ -> t
    }
  }
}

pub fn tratar_tecla(t: Tela, tecla: world.Key) -> Tela {
  case t.pagina {
    "introducao" -> case tecla {
      world.Enter -> Tela(..t, pagina: "principal", mensagem: "Encontre a chave e uma lanterna.")
      _ -> t
    }
    "resposta" -> case tecla {
      world.Escape -> Tela(..t, pagina: "principal", digitado: "")
      world.Backspace -> case string.length(t.digitado) > 0 {
        True -> Tela(..t, digitado: string.slice(t.digitado, 0, string.length(t.digitado) - 1))
        False -> t
      }
      world.Enter -> case string.trim(t.digitado) == "" {
        True -> Tela(..t, mensagem: "Digite uma resposta.")
        False -> responder(t, t.digitado)
      }
      world.Char(c) -> case string.length(t.digitado) < 12 {
        True -> Tela(..t, digitado: t.digitado <> c)
        False -> t
      }
      _ -> t
    }
    _ -> case tecla {
      world.Escape -> Tela(..t, pagina: "principal")
      world.Char(c) -> escolher(t, c)
      _ -> t
    }
  }
}

pub fn main() {
  world.create(iniciar(), desenhar)
  |> world.on_key_down(tratar_tecla)
  |> world.run()
}
