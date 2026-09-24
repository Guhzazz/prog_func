//// Modulo listas - funcoes de recursao estrutural sobre listas, usadas
//// como base pelos demais modulos: agregacao (F3), filtragem simples
//// (F4).

import gleam/int
import src/tipos.{type Instancia, type Metrica, Metrica}

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

// F5 - Transformacao recursiva

/// Devolve uma nova lista de metricas com a disponibilidade recalculada,
/// penalizada pela taxa de falhas (falhas / requisicoes, em pontos
/// percentuais), sem nunca ficar negativa. Nao altera a lista original
/// (imutabilidade estrutural) - cada Metrica penalizada e um valor novo.
pub fn penalizar_por_falhas(metricas: List(Metrica)) -> List(Metrica) {
  case metricas {
    [] -> []
    [m, ..resto] -> [penalizar_metrica(m), ..penalizar_por_falhas(resto)]
  }
}

fn penalizar_metrica(metrica: Metrica) -> Metrica {
  case metrica.requisicoes {
    0 -> metrica
    _ -> {
      let taxa_falha = int.to_float(metrica.falhas) /. int.to_float(metrica.requisicoes)
      let penalizada = metrica.disponibilidade -. taxa_falha *. 100.0
      let nova = case penalizada <. 0.0 {
        True -> 0.0
        False -> penalizada
      }
      Metrica(..metrica, disponibilidade: nova)
    }
  }
}

// F6 - Busca

/// Localiza uma instancia pelo id em uma lista. Error(Nil) se nao
/// encontrada.
pub fn buscar_instancia_por_id(
  instancias: List(Instancia),
  id_procurado: Int,
) -> Result(Instancia, Nil) {
  case instancias {
    [] -> Error(Nil)
    [i, ..resto] ->
      case i.id == id_procurado {
        True -> Ok(i)
        False -> buscar_instancia_por_id(resto, id_procurado)
      }
  }
}

// F7 - Maior ou menor elemento

/// Metrica com a menor disponibilidade registrada em uma lista.
pub fn metrica_com_menor_disponibilidade(
  metricas: List(Metrica),
) -> Result(Metrica, Nil) {
  case metricas {
    [] -> Error(Nil)
    [unica] -> Ok(unica)
    [primeira, ..resto] ->
      case metrica_com_menor_disponibilidade(resto) {
        Error(Nil) -> Ok(primeira)
        Ok(pior) ->
          case primeira.disponibilidade <. pior.disponibilidade {
            True -> Ok(primeira)
            False -> Ok(pior)
          }
      }
  }
}

/// Instancia com mais falhas acumuladas em suas metricas (usa
/// total_falhas, de F3, como auxiliar).
pub fn instancia_com_mais_falhas(
  instancias: List(Instancia),
) -> Result(Instancia, Nil) {
  case instancias {
    [] -> Error(Nil)
    [unica] -> Ok(unica)
    [primeira, ..resto] ->
      case instancia_com_mais_falhas(resto) {
        Error(Nil) -> Ok(primeira)
        Ok(campea) ->
          case
            total_falhas(primeira.metricas) > total_falhas(campea.metricas)
          {
            True -> Ok(primeira)
            False -> Ok(campea)
          }
      }
  }
}
