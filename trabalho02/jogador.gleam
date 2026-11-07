import gleam/list
import sgleam/check

pub type Jogador{
    Jogador(
        nome: String,
        inventario: List(String),
        pontos_de_vida: Int,
        localizacao: String
    )
}

/// Cria um novo jogador no ambiente inicial, sem itens e com a vida cheia
pub fn novo_jogador(nome: String, localizacao: String)-> Jogador{
    Jogador(nome, [], 100, localizacao)
}

pub fn novo_jogador_examples(){
    check.eq(novo_jogador("Ana", "Manutenção"), Jogador("Ana", [], 100, "Manutenção"))
}


/// Adiciona um item ao inventário.
pub fn adicionar_item(jogador: Jogador, item: String) -> Jogador {
  Jogador(..jogador, inventario: [item, ..jogador.inventario])
}

pub fn adicionar_item_examples() {
  check.eq(
    adicionar_item(novo_jogador("Ana", "Manutenção"), "chave").inventario,
    ["chave"],
  )
}


/// Verifica se o jogador possui o item.
pub fn tem_item(jogador: Jogador, item: String) -> Bool {
  list.contains(jogador.inventario, item)
}

pub fn tem_item_examples() {
  let j = adicionar_item(novo_jogador("Ana", "Manutenção"), "chave")
  check.eq(tem_item(j, "chave"), True)
  check.eq(tem_item(j, "crachá"), False)
}


/// Move o jogador para outro ambiente.
pub fn mover(jogador: Jogador, destino: String) -> Jogador {
  Jogador(..jogador, localizacao: destino)
}

pub fn mover_examples() {
  check.eq(
    mover(novo_jogador("Ana", "Manutenção"), "Corredor").localizacao,
    "Corredor",
  )
}


/// Reduz a vida do jogador, sem ficar abaixo de zero.
pub fn perder_vida(jogador: Jogador, dano: Int) -> Jogador {
  let vida = case jogador.pontos_de_vida - dano {
    v if v < 0 -> 0
    v -> v
  }
  Jogador(..jogador, pontos_de_vida: vida)
}

pub fn perder_vida_examples() {
  check.eq(
    perder_vida(novo_jogador("Ana", "Manutenção"), 30).pontos_de_vida,
    70,
  )
  check.eq(
    perder_vida(novo_jogador("Ana", "Manutenção"), 500).pontos_de_vida,
    0,
  )
}
