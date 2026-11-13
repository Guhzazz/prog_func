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
  adicionar_item(jogador, "pista: porta técnica B12")
}

fn ler_registro(jogador: Jogador) -> Jogador {
  adicionar_item(jogador, "pista: gerador na sala 3")
}

fn pegar_lanterna(jogador: Jogador) -> Jogador {
  adicionar_item(jogador, "lanterna")
}

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

fn examinar_porta(jogador: Jogador) -> Jogador {
  jogador
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

pub fn painel() -> Objeto {
  Objeto("painel", "Painel do gerador, sem energia.", ligar_painel, "intacto")
}

pub fn porta_emergencia() -> Objeto {
  Objeto("porta de emergência", "Porta da saída de evacuação, trancada.", examinar_porta, "trancada")
}

// Operações

/// Aplica a interação do objeto, se o inventário mudou, o objeto vira usado.
/// Um objeto usado não faz nada(para evitar itens duplicados)
pub fn interagir(objeto: Objeto, jogador: Jogador)-> #(Objeto, Jogador){
    case objeto.estado == "usado"{
        True-> #(objeto, jogador)
        False-> {
            let novo = objeto.interacao(jogador)
            case novo.inventario != jogador.inventario{
                True-> #(Objeto(..objeto, estado: "usado"), novo)
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
    "lanterna: Uma lanterna caída no chão. [intacto]",
  )
}