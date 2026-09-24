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


pub fn total_falhas_examples() {
  check.eq(listas.total_falhas([]), 0)
  check.eq(listas.total_falhas([Metrica(1, 10, 1.0, 0, 100.0)]), 0)
  check.eq(listas.total_falhas([Metrica(1, 10, 1.0, 2, 99.0)]), 2)
  check.eq(
    listas.total_falhas([
      Metrica(1, 10, 1.0, 2, 99.0),
      Metrica(2, 10, 1.0, 3, 99.0),
    ]),
    5,
  )
  check.eq(
    listas.total_falhas([
      Metrica(1, 10, 1.0, 2, 99.0),
      Metrica(2, 10, 1.0, 3, 99.0),
      Metrica(3, 10, 1.0, 5, 90.0),
    ]),
    10,
  )
}


pub fn total_requisicoes_examples() {
  check.eq(listas.total_requisicoes([]), 0)
  check.eq(listas.total_requisicoes([Metrica(1, 10, 1.0, 0, 100.0)]), 10)
  check.eq(
    listas.total_requisicoes([
      Metrica(1, 10, 1.0, 0, 100.0),
      Metrica(2, 15, 1.0, 0, 100.0),
    ]),
    25,
  )
}

pub fn soma_disponibilidade_examples(){
    check.eq(listas.soma_disponibilidade([]), 0.0)
    check.eq(listas.soma_disponibilidade([Metrica(1, 10, 1.0, 0,  55.0), Metrica(2, 10, 1.0, 0, 45.0)]), 100.0)
    check.eq(listas.soma_disponibilidade([Metrica(3, 10, 1.0, 0, 0.0), Metrica(4, 10, 1.0, 0, 100.0)]), 100.0)

}

pub fn soma_tempo_resposta_examples(){
    check.eq(listas.soma_tempo_resposta([]), 0.0)
    check.eq(listas.soma_tempo_resposta([Metrica(1, 10, 0.0, 0, 100.0), Metrica(2, 10, 0.25, 0, 100.0)]), 0.25)
    check.eq(listas.soma_tempo_resposta([Metrica(3, 10, 1.0, 0, 100.0), Metrica(4, 10, 0.5, 0, 100.0)]), 1.5)
}

pub fn disponibilidade_media_examples() {
  check.eq(listas.disponibilidade_media([]), 0.0)
  check.eq(listas.disponibilidade_media([Metrica(1, 10, 1.0, 0, 99.0)]), 99.0)
  check.eq(
    listas.disponibilidade_media([
      Metrica(1, 10, 1.0, 0, 100.0),
      Metrica(2, 10, 1.0, 0, 90.0),
    ]),
    95.0,
  )
  check.eq(
    listas.disponibilidade_media([
      Metrica(1, 10, 1.0, 0, 100.0),
      Metrica(2, 10, 1.0, 0, 80.0),
      Metrica(3, 10, 1.0, 0, 60.0),
    ]),
    80.0,
  )
}

pub fn tempo_resposta_medio_examples() {
  check.eq(listas.tempo_resposta_medio([]), 0.0)
  check.eq(listas.tempo_resposta_medio([Metrica(1, 10, 20.0, 0, 99.0)]), 20.0)
  check.eq(
    listas.tempo_resposta_medio([
      Metrica(1, 10, 100.0, 0, 99.0),
      Metrica(2, 10, 200.0, 0, 99.0),
    ]),
    150.0,
  )
}

pub fn metricas_abaixo_de_examples() {
  check.eq(listas.metricas_abaixo_de([], 99.0), [])
  check.eq(listas.metricas_abaixo_de([Metrica(1, 10, 1.0, 0, 99.9)], 99.0), [])
  check.eq(listas.metricas_abaixo_de([Metrica(1, 10, 1.0, 5, 80.0)], 99.0), [
    Metrica(1, 10, 1.0, 5, 80.0),
  ])
  check.eq(listas.metricas_abaixo_de([Metrica(1, 10, 1.0, 0, 99.0)], 99.0), [])
  check.eq(
    listas.metricas_abaixo_de(
      [
        Metrica(1, 10, 1.0, 5, 80.0),
        Metrica(2, 10, 1.0, 0, 99.9),
        Metrica(3, 10, 1.0, 3, 95.0),
      ],
      99.0,
    ),
    [Metrica(1, 10, 1.0, 5, 80.0), Metrica(3, 10, 1.0, 3, 95.0)],
  )
}
// F5 - transformacao recursiva
pub fn penalizar_por_falhas_examples() {
  check.eq(listas.penalizar_por_falhas([]), [])
  check.eq(
    listas.penalizar_por_falhas([Metrica(1, 100, 10.0, 10, 99.0)]),
    [Metrica(1, 100, 10.0, 10, 89.0)],
  )
  // sem requisicoes: nao ha divisao por zero, metrica fica inalterada
  check.eq(
    listas.penalizar_por_falhas([Metrica(1, 0, 0.0, 0, 100.0)]),
    [Metrica(1, 0, 0.0, 0, 100.0)],
  )
}

// F6 - busca
pub fn buscar_instancia_por_id_examples() {
  let instancias = [Instancia(1, "a", []), Instancia(2, "b", [])]
  check.eq(
    listas.buscar_instancia_por_id(instancias, 2),
    Ok(Instancia(2, "b", [])),
  )
  check.eq(listas.buscar_instancia_por_id(instancias, 99), Error(Nil))
  check.eq(listas.buscar_instancia_por_id([], 1), Error(Nil))
}

// F7 - maior/menor elemento
pub fn metrica_com_menor_disponibilidade_examples() {
  check.eq(listas.metrica_com_menor_disponibilidade([]), Error(Nil))
  let m1 = Metrica(1, 10, 1.0, 1, 99.0)
  let m2 = Metrica(2, 10, 1.0, 40, 60.0)
  let m3 = Metrica(3, 10, 1.0, 10, 90.0)
  check.eq(listas.metrica_com_menor_disponibilidade([m1, m2, m3]), Ok(m2))
}

pub fn instancia_com_mais_falhas_examples() {
  check.eq(listas.instancia_com_mais_falhas([]), Error(Nil))
  let i1 = Instancia(1, "a", [Metrica(1, 10, 1.0, 1, 99.0)])
  let i2 = Instancia(2, "b", [Metrica(2, 10, 1.0, 40, 60.0)])
  let i3 = Instancia(3, "c", [Metrica(3, 10, 1.0, 10, 90.0)])
  check.eq(listas.instancia_com_mais_falhas([i1, i2, i3]), Ok(i2))
}
