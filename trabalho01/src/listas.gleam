//// Modulo listas - funcoes de recursao estrutural sobre listas, usadas
//// como base pelos demais modulos: agregacao (F3), filtragem simples
//// (F4).

import gleam/int
import src/tipos.{type Instancia, type Metrica}

/// Devolve uma nova lista com os elementos de lst1 seguidos dos de lst2.
pub fn concatenar(lst1: List(Metrica), lst2: List(Metrica)) -> List(Metrica) {
  case lst1 {
    [] -> lst2
    [primeiro, ..resto] -> [primeiro, ..concatenar(resto, lst2)]
  }
}


/// Reune em uma unica lista as metricas de todas as instancias.
pub fn metricas_das_instancias(instancias: List(Instancia)) -> List(Metrica) {
  case instancias {
    [] -> []
    [primeiro, ..resto] -> concatenar(primeiro.metricas, metricas_das_instancias(resto))
  }
}

/// Conta os elementos de uma lista de genérica
pub fn quantidade_metricas(metricas: List(a)) -> Int {
  case metricas {
    [] -> 0
    [_, ..resto] -> 1 + quantidade_metricas(resto)
  }
}

// F3 - Agregacao sobre listas

///Devolve a soma das falhas registradas na lista de metricas.
pub fn total_falhas(metricas: List(Metrica)) -> Int {
  case metricas {
    [] -> 0
    [primeiro, ..resto] -> primeiro.falhas + total_falhas(resto)
  }
}


///Devolve a soma das requisicoes da lista de metricas.
pub fn total_requisicoes(metricas: List(Metrica)) -> Int {
  case metricas {
    [] -> 0
    [m, ..resto] -> m.requisicoes + total_requisicoes(resto)
  }
}

/// Devolve a soma das disponibilidades da lista de metricas.
 pub fn soma_disponibilidade(metricas: List(Metrica)) -> Float {
  case metricas {
    [] -> 0.0
    [m, ..resto] -> m.disponibilidade +. soma_disponibilidade(resto)
  }
}

/// Devolve a soma dos tempos de resposta da lista de metricas.
pub fn soma_tempo_resposta(metricas: List(Metrica)) -> Float {
  case metricas {
    [] -> 0.0
    [m, ..resto] -> m.tempo_resposta_ms +. soma_tempo_resposta(resto)
  }
}

/// Devolve a disponibilidade media das metricas.
/// Para a lista vazia devolve 0.0, indicando ausencia de dado.
pub fn disponibilidade_media(metricas: List(Metrica)) -> Float {
  case quantidade_metricas(metricas) {
    0 -> 0.0
    n -> soma_disponibilidade(metricas) /. int.to_float(n)
  }
}

/// Devolve o tempo medio de resposta das metricas.
pub fn tempo_resposta_medio(metricas: List(Metrica)) -> Float {
  case quantidade_metricas(metricas) {
    0 -> 0.0
    n -> soma_tempo_resposta(metricas) /. int.to_float(n)
  }
}

// F4 - Filtragem Recursiva

/// Devolve uma nova lista apenas com as metricas cuja
/// disponibilidade esta abaixo do limite informado.
pub fn metricas_abaixo_de(
  metricas: List(Metrica),
  limite: Float,
) -> List(Metrica) {
  case metricas {
    [] -> []
    [m, ..resto] ->
      case m.disponibilidade <. limite {
        True -> [m, ..metricas_abaixo_de(resto, limite)]
        False -> metricas_abaixo_de(resto, limite)
      }
  }
}