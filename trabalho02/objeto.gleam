import jogador.{type Jogador, adicionar_item, perder_vida, tem_item}
import sgleam/check

pub type Objeto{
    Objeto(nome: String,
    descricao: String,
    interacao : fn (jogador: Jogador) -> Jogador,
    estado: String)
}

// INterações possíveis (funções puras)

fn pegar_chave(jogador: Jogador)-> Jogador{
    adicionar_item(jogador, "Chave da Manutenção")
}

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
    False -> perder_vida(j, 10)
  }
}

fn examinar_porta(jogador: Jogador) -> Jogador {
  jogador
}