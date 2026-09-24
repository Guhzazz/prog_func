// F9 - Processamento hierarquico.
//
// O tipo autorreferente do projeto e Servico.dependencias: List(Servico).
// Este modulo percorre esse grafo de dependencias, reaproveitando
// listas.metricas_das_instancias (ja escrita em listas.gleam) para obter
// as metricas de toda a cadeia. Assumimos que o grafo nao tem ciclos (um
// servico nao depende, direta ou indiretamente, de si mesmo) - suposicao
// documentada no relatorio.

import src/listas
import src/tipos.{type Aplicacao, type Instancia, type Metrica, type Servico}

/// Conta quantos servicos existem a partir de um servico: ele mesmo mais
/// todas as suas dependencias, recursivamente, em qualquer profundidade.
/// Caso base: sem dependencias, conta 1 (ele mesmo).
/// Caso recursivo: 1 + soma das contagens de cada dependencia direta.
pub fn contar_servicos(servico: Servico) -> Int {
  1 + contar_servicos_lista(servico.dependencias)
}

fn contar_servicos_lista(servicos: List(Servico)) -> Int {
  case servicos {
    [] -> 0
    [s, ..resto] -> contar_servicos(s) + contar_servicos_lista(resto)
  }
}

/// Achata o grafo de dependencias de um servico (ele mesmo + todas as
/// dependencias, recursivamente) em uma lista simples de Servico.
pub fn achatar(servico: Servico) -> List(Servico) {
  [servico, ..achatar_lista(servico.dependencias)]
}

fn achatar_lista(servicos: List(Servico)) -> List(Servico) {
  case servicos {
    [] -> []
    [s, ..resto] -> lista_servicos_concat(achatar(s), achatar_lista(resto))
  }
}

// Concatenacao generica de List(Servico); listas.concatenar e especifica
// para List(Metrica), entao repetimos o mesmo padrao aqui para Servico.
fn lista_servicos_concat(a: List(Servico), b: List(Servico)) -> List(Servico) {
  case a {
    [] -> b
    [primeiro, ..resto] -> [primeiro, ..lista_servicos_concat(resto, b)]
  }
}

/// Reune as instancias do proprio servico com as de todas as suas
/// dependencias (recursivamente). Util para agregar metricas sobre toda
/// a cadeia de dependencia de um servico, nao so sobre ele mesmo.
pub fn todas_instancias(servico: Servico) -> List(Instancia) {
  lista_instancias_concat(
    servico.instancias,
    todas_instancias_lista(servico.dependencias),
  )
}

fn todas_instancias_lista(servicos: List(Servico)) -> List(Instancia) {
  case servicos {
    [] -> []
    [s, ..resto] ->
      lista_instancias_concat(
        todas_instancias(s),
        todas_instancias_lista(resto),
      )
  }
}

fn lista_instancias_concat(
  a: List(Instancia),
  b: List(Instancia),
) -> List(Instancia) {
  case a {
    [] -> b
    [primeiro, ..resto] -> [primeiro, ..lista_instancias_concat(resto, b)]
  }
}

/// Reune, ja em metricas (List(Metrica)), tudo que esta na cadeia de
/// dependencias de um servico. Combina F9 (percorrer o grafo) com a
/// funcao metricas_das_instancias que ja existe em listas.gleam (F3).
pub fn todas_metricas(servico: Servico) -> List(Metrica) {
  listas.metricas_das_instancias(todas_instancias(servico))
}

/// Profundidade da cadeia de dependencias a partir de um servico
/// (servico sem dependencias tem profundidade 1).
pub fn profundidade(servico: Servico) -> Int {
  1 + maior_profundidade_lista(servico.dependencias)
}

fn maior_profundidade_lista(servicos: List(Servico)) -> Int {
  case servicos {
    [] -> 0
    [unico] -> profundidade(unico)
    [primeiro, ..resto] -> {
      let p = profundidade(primeiro)
      let resto_max = maior_profundidade_lista(resto)
      case p > resto_max {
        True -> p
        False -> resto_max
      }
    }
  }
}

/// Reune as instancias de todos os servicos de topo de uma aplicacao,
/// incluindo as dependencias de cada um.
pub fn todas_instancias_aplicacao(aplicacao: Aplicacao) -> List(Instancia) {
  todas_instancias_lista(aplicacao.servicos)
}
