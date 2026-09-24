import sgleam/check
import src/hierarquia
import src/tipos.{Api, Instancia, Metrica, Servico}

// Monta um pequeno grafo de dependencias:
//
//   gateway (id 1)
//     depende de -> auth (id 2)
//     depende de -> pagamentos (id 3)
//                     depende de -> banco-pagamentos (id 4)
fn grafo_exemplo() {
  let banco_pagamentos =
    Servico(
      id: 4,
      nome: "banco-pagamentos",
      tipo_servico: Api,
      instancias: [Instancia(40, "i40", [Metrica(400, 100, 20.0, 1, 99.0)])],
      dependencias: [],
    )

  let auth =
    Servico(
      id: 2,
      nome: "auth",
      tipo_servico: Api,
      instancias: [Instancia(20, "i20", [Metrica(200, 200, 10.0, 2, 99.5)])],
      dependencias: [],
    )

  let pagamentos =
    Servico(
      id: 3,
      nome: "pagamentos",
      tipo_servico: Api,
      instancias: [Instancia(30, "i30", [Metrica(300, 150, 30.0, 3, 96.0)])],
      dependencias: [banco_pagamentos],
    )

  Servico(
    id: 1,
    nome: "gateway",
    tipo_servico: Api,
    instancias: [Instancia(10, "i10", [Metrica(100, 500, 5.0, 5, 99.0)])],
    dependencias: [auth, pagamentos],
  )
}

fn servico_isolado() {
  Servico(id: 9, nome: "isolado", tipo_servico: Api, instancias: [], dependencias: [])
}

// Caso base: um servico sem dependencias conta apenas ele mesmo.
pub fn contar_servicos_sem_dependencias_examples() {
  check.eq(hierarquia.contar_servicos(servico_isolado()), 1)
}

// F9 - recursao no grafo inteiro: gateway + auth + pagamentos +
// banco-pagamentos = 4.
pub fn contar_servicos_grafo_examples() {
  check.eq(hierarquia.contar_servicos(grafo_exemplo()), 4)
}

// F9 - achatar deve trazer os 4 servicos do grafo.
pub fn achatar_examples() {
  check.eq(
    lista_tamanho(hierarquia.achatar(grafo_exemplo())),
    hierarquia.contar_servicos(grafo_exemplo()),
  )
}

fn lista_tamanho(lista: List(a)) -> Int {
  case lista {
    [] -> 0
    [_, ..resto] -> 1 + lista_tamanho(resto)
  }
}

// F9 - reune instancias do proprio servico e de toda a cadeia de
// dependencias: gateway (1) + auth (1) + pagamentos (1) +
// banco-pagamentos (1) = 4 instancias.
pub fn todas_instancias_examples() {
  check.eq(lista_tamanho(hierarquia.todas_instancias(grafo_exemplo())), 4)
}

// F9 - reune metricas de toda a cadeia (uma metrica por instancia = 4).
pub fn todas_metricas_examples() {
  check.eq(lista_tamanho(hierarquia.todas_metricas(grafo_exemplo())), 4)
}

// F9 - profundidade: gateway -> pagamentos -> banco-pagamentos = 3 niveis.
pub fn profundidade_examples() {
  check.eq(hierarquia.profundidade(grafo_exemplo()), 3)
}

pub fn profundidade_sem_dependencias_examples() {
  check.eq(hierarquia.profundidade(servico_isolado()), 1)
}
