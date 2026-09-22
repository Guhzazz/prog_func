//// Modulo listas - funcoes de recursao estrutural sobre listas, usadas
//// como base pelos demais modulos: agregacao (F3), filtragem simples
//// (F4).

import gleam/int
import src/tipos.{type Instancia, type Metrica}

/// Devolve uma nova lista com os elementos de lst1 seguidos dos de lst2.
pub fn concatenar(lst1: List(Metrica), lst2: List(Metrica)) -> List(Metrica) {
  case lst1 {
    [] -> last2
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