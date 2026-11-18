//// Módulo objeto — objetos do hospital e suas interações puras: cada
//// interação recebe o jogador e devolve um novo jogador.

import jogador.{type Jogador, adicionar_item, perder_vida, tem_item}
import sgleam/check

/// Objeto de uma sala; `interacao` é aplicada ao jogador quando ele usa o objeto
/// e `estado` indica se ele está "intacto", "trancada" ou "usado".
pub type Objeto {
  Objeto(
    nome: String,
    descricao: String,
    interacao: fn(Jogador) -> Jogador,
    estado: String,
  )
}

// Interações possíveis (funções puras)

/// Coloca a chave de manutenção no inventário.
fn pegar_chave(jogador: Jogador) -> Jogador {
  adicionar_item(jogador, "chave de manutenção")
}

/// Ler a planta dá a pista do código da porta técnica.
fn ler_planta(jogador: Jogador) -> Jogador {
  adicionar_item(jogador, "pista: porta técnica B12")
}

/// Ler o registro dá a pista da sala do gerador.
fn ler_registro(jogador: Jogador) -> Jogador {
  adicionar_item(jogador, "pista: gerador na sala 3")
}

/// Coloca a lanterna no inventário.
fn pegar_lanterna(jogador: Jogador) -> Jogador {
  adicionar_item(jogador, "lanterna")
}

/// Coloca o crachá no inventário (protege do choque do painel).
fn pegar_cracha(jogador: Jogador) -> Jogador {
  adicionar_item(jogador, "crachá")
}

/// O painel só liga com o cracha, sem ele o jogador leva um choque e perde 10 de vida
fn ligar_painel(jogador: Jogador) -> Jogador {
  case tem_item(jogador, "crachá") {
    True -> adicionar_item(jogador, "energia restaurada")
    False -> perder_vida(jogador, 10)
  }
}

/// A porta só abre depois do terminal de saída liberar a rota; sem isso, nada acontece
fn abrir_porta(jogador: Jogador) -> Jogador {
  case tem_item(jogador, "rota liberada") {
    True -> adicionar_item(jogador, "porta aberta")
    False -> jogador
  }
}

// Objetos do hospital

/// Chave de manutenção (sala Manutenção).
pub fn chave() -> Objeto {
  Objeto(
    "chave",
    "Uma chave de manutenção pendurada no quadro",
    pegar_chave,
    "intacto",
  )
}

/// Planta do prédio com o código da porta técnica (sala Manutenção).
pub fn planta() -> Objeto {
  Objeto(
    "planta",
    "Uma planta do hospital com um código rabiscado",
    ler_planta,
    "intacto",
  )
}

/// Registro de falhas que indica a sala do gerador (sala Manutenção).
pub fn registro() -> Objeto {
  Objeto(
    "registro",
    "Registro de falhas dos equipamentos.",
    ler_registro,
    "intacto",
  )
}

/// Lanterna (sala Manutenção).
pub fn lanterna() -> Objeto {
  Objeto("lanterna", "Uma lanterna caída no chão", pegar_lanterna, "intacto")
}

/// Crachá do técnico de plantão (Corredor).
pub fn cracha() -> Objeto {
  Objeto(
    "crachá",
    "Crachá de acesso do técnico de plantão.",
    pegar_cracha,
    "intacto",
  )
}

/// Painel do gerador (Sala 3).
pub fn painel() -> Objeto {
  Objeto("painel", "Painel do gerador, sem energia.", ligar_painel, "intacto")
}

/// Porta de emergência, começa trancada (Saída).
pub fn porta_emergencia() -> Objeto {
  Objeto(
    "porta de emergência",
    "Porta da saída de evacuação, trancada.",
    abrir_porta,
    "trancada",
  )
}

pub fn porta_emergencia_examples() {
  let j = jogador.novo_jogador("Ana", "Saída")
  let #(porta, j2) = interagir(porta_emergencia(), j)
  check.eq(porta.estado, "trancada")
  check.eq(tem_item(j2, "porta aberta"), False)
  let #(porta2, j3) =
    interagir(porta_emergencia(), adicionar_item(j, "rota liberada"))
  check.eq(porta2.estado, "usado")
  check.eq(tem_item(j3, "porta aberta"), True)
}

// Operações

/// Aplica a interação do objeto, se o inventário mudou, o objeto vira usado.
/// Um objeto usado não faz nada(para evitar itens duplicados)
pub fn interagir(objeto: Objeto, jogador: Jogador) -> #(Objeto, Jogador) {
  case objeto.estado == "usado" {
    True -> #(objeto, jogador)
    False -> {
      let novo = objeto.interacao(jogador)
      case novo.inventario != jogador.inventario {
        True -> #(Objeto(..objeto, estado: "usado"), novo)
        False -> #(objeto, novo)
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
