import configuracao
import jogador.{type Jogador, adicionar_item, perder_vida, tem_item}
import sgleam/check

pub type Objeto{
    Objeto(
    nome: String,
    descricao: String,
    interacao : fn(Jogador) -> Jogador,
    estado: String)
}

// INterações possíveis (funções puras)

fn pegar_chave(jogador: Jogador) -> Jogador {
  adicionar_item(jogador, "chave de manutenção")
}


fn ler_planta(jogador: Jogador) -> Jogador {
  adicionar_item(
    jogador,
    "pista: porta técnica " <> configuracao.codigo_saida,
  )
}



fn ler_registro(jogador: Jogador) -> Jogador {
  adicionar_item(
    jogador,
    "registro: gerador auxiliar instalado na sala 3",
  )
}

fn pegar_lanterna(jogador: Jogador) -> Jogador {
  adicionar_item(jogador, "lanterna")
}

fn pegar_cracha(jogador: Jogador) -> Jogador {
  adicionar_item(jogador, "crachá")
}


fn ligar_gerador(jogador: Jogador) -> Jogador {
  case tem_item(jogador, "lanterna") {
    True -> adicionar_item(jogador, "gerador ligado")
    False -> jogador
  }
}


/// O painel só liga com o cracha, sem ele o jogador leva um choque e perde 10 de vida

fn ligar_painel(jogador: Jogador) -> Jogador {
  case tem_item(jogador, "lanterna") {
    False ->
      perder_vida(jogador, configuracao.dano_choque)

    True ->
      case tem_item(jogador, "crachá") {
        False -> jogador

        True ->
          case tem_item(jogador, "gerador ligado") {
            False -> jogador

            True ->
              adicionar_item(jogador, "energia restaurada")
          }
      }
  }
}


/// A porta só abre depois do terminal de saída liberar a rota; sem isso, nada acontece

fn abrir_porta(jogador: Jogador) -> Jogador {
  case tem_item(jogador, "energia restaurada")
    && tem_item(jogador, "crachá")
    && tem_item(jogador, "rota liberada") {

    True -> adicionar_item(jogador, "porta aberta")
    False -> jogador
  }
}

// Descrição dos objetos do hospital(funções fn() -> Jogador ainda não implementadas)

pub fn chave() -> Objeto {
  Objeto("chave", "Uma chave de manutenção pendurada no quadro", pegar_chave, "intacto")
}

pub fn planta() -> Objeto{
    Objeto("planta", "Uma planta do hospital com um código rabiscado", ler_planta, "intacto")
}

pub fn registro() -> Objeto {
  Objeto("registro", "Registro de falhas dos equipamentos.", ler_registro, "intacto")
}

pub fn lanterna() -> Objeto{
    Objeto("lanterna", "Uma lanterna caída no chão", pegar_lanterna, "intacto")
}

pub fn cracha() -> Objeto {
  Objeto("crachá", "Crachá de acesso do técnico de plantão.", pegar_cracha, "intacto")
}


pub fn gerador() -> Objeto {
  Objeto(
    "gerador",
    "Gerador auxiliar sem iluminação na área de trabalho.",
    ligar_gerador,
    "intacto",
  )
}



pub fn painel() -> Objeto {
  Objeto(
    "painel",
    "Painel elétrico. Exige gerador ligado, lanterna e crachá.",
    ligar_painel,
    "intacto",
  )
}

pub fn porta_emergencia() -> Objeto {
  Objeto("porta de emergência", "Porta da saída de evacuação, trancada.", abrir_porta, "trancada")
}


pub fn porta_emergencia_examples() {
  let j = jogador.novo_jogador("Ana", "Saída")

  check.eq(
    interagir(porta_emergencia(), j).0.estado,
    "trancada",
  )

  let autorizado = adicionar_item(
    adicionar_item(
      adicionar_item(j, "energia restaurada"),
      "crachá",
    ),
    "rota liberada",
  )

  check.eq(
    interagir(porta_emergencia(), autorizado).0.estado,
    "aberta",
  )

  check.eq(
    tem_item(
      interagir(porta_emergencia(), autorizado).1,
      "porta aberta",
    ),
    True,
  )
}


pub fn gerador_painel_examples() {
  let j = jogador.novo_jogador("Ana", "Sala 3")

  check.eq(
    tem_item(interagir(gerador(), j).1, "gerador ligado"),
    False,
  )

  check.eq(
    interagir(painel(), j).1.pontos_de_vida,
    80,
  )

  let iluminado = adicionar_item(j, "lanterna")

  check.eq(
    tem_item(
      interagir(gerador(), iluminado).1,
      "gerador ligado",
    ),
    True,
  )

  check.eq(
    interagir(painel(), iluminado).1.pontos_de_vida,
    100,
  )


  check.eq(
    tem_item(
      interagir(painel(), iluminado).1,
      "energia restaurada",
    ),
    False,
  )

  let com_cracha = adicionar_item(
    iluminado,
    "crachá",
  )

  check.eq(
    tem_item(
      interagir(painel(), com_cracha).1,
      "energia restaurada",
    ),
    False,
  )


  let preparado = adicionar_item(
    adicionar_item(iluminado, "crachá"),
    "gerador ligado",
  )

  check.eq(
    tem_item(
      interagir(painel(), preparado).1,
      "energia restaurada",
    ),
    True,
  )
}



// Operações

/// Aplica a interação do objeto, se o inventário mudou, o objeto vira usado.
/// Um objeto usado não faz nada(para evitar itens duplicados)
pub fn interagir(objeto: Objeto, jogador: Jogador)-> #(Objeto, Jogador){
    case objeto.estado == "usado" || objeto.estado == "aberta"{
        True-> #(objeto, jogador)
        False-> {
            let novo = objeto.interacao(jogador)
            case novo.inventario != jogador.inventario{
                True -> {
                  let estado_final =
                    case objeto.nome == "porta de emergência" {
                      True -> "aberta"
                      False -> "usado"
                    }

                  #(Objeto(..objeto, estado: estado_final), novo)
                }
                False-> #(objeto, novo)
            }
        }
    }
}

pub fn interagir_examples() {
  let j = jogador.novo_jogador("Ana", "Manutenção")
  let #(obj, j2) = interagir(chave(), j)
  check.eq(obj.estado, "usado")
  check.eq(tem_item(j2, "chave de manutenção"), True)
  let #(_, j3) = interagir(obj, j2)
  check.eq(j3.inventario, ["chave de manutenção"])
}

/// Texto usado pelo comando "explorar".
pub fn descrever(objeto: Objeto) -> String {
  objeto.nome <> ": " <> objeto.descricao <> " [" <> objeto.estado <> "]"
}

pub fn descrever_examples() {
  check.eq(
    descrever(lanterna()),
    "lanterna: Uma lanterna caída no chão [intacto]",
  )
}