/// Testes de src/listas.gleam: agregacao (F3), filtragem simples (F4)

import sgleam/check
import src/listas
import src/tipos.{Instancia, Metrica}

pub fn concatenar_examples() {
  check.eq(listas.concatenar([], []), [])
  check.eq(listas.concatenar([], [Metrica(1, 1, 1.0, 0, 100.0)]), [
    Metrica(1, 1, 1.0, 0, 100.0),
  ])
  check.eq(listas.concatenar([Metrica(1, 1, 1.0, 0, 100.0)], []), [
    Metrica(1, 1, 1.0, 0, 100.0),
  ])
  check.eq(
    listas.concatenar([Metrica(1, 1, 1.0, 0, 100.0)], [
      Metrica(2, 1, 1.0, 0, 100.0),
    ]),
    [Metrica(1, 1, 1.0, 0, 100.0), Metrica(2, 1, 1.0, 0, 100.0)],
  )
}


pub fn metricas_das_instancias_examples() {
  check.eq(listas.metricas_das_instancias([]), [])
  check.eq(listas.metricas_das_instancias([Instancia(1, "a", [])]), [])
  check.eq(
    listas.metricas_das_instancias([
      Instancia(1, "a", [Metrica(1, 1, 1.0, 0, 100.0)]),
      Instancia(2, "b", [Metrica(2, 1, 1.0, 0, 100.0)]),
    ]),
    [Metrica(1, 1, 1.0, 0, 100.0), Metrica(2, 1, 1.0, 0, 100.0)],
  )
}

pub fn quantidade_metricas_examples() {
  check.eq(listas.quantidade_metricas([]), 0)
  check.eq(listas.quantidade_metricas([Metrica(1, 1, 1.0, 0, 100.0)]), 1)
  check.eq(
    listas.quantidade_metricas([
      Metrica(1, 1, 1.0, 0, 100.0),
      Metrica(2, 1, 1.0, 0, 100.0),
      Metrica(3, 1, 1.0, 0, 100.0),
    ]),
    3,
  )
}
