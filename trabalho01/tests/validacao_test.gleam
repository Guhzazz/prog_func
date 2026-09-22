//// Testes de src/validacao.gleam (F1) e da conversao de erros de
//// src/tipos.gleam, incluindo casos tipicos, casos-limite e erros.

import sgleam/check
import src/tipos.{
Instancia, Metrica, Servico,
}
import src/validacao

pub fn nova_metrica_examples() {
  check.eq(
    validacao.nova_metrica(1, 100, 12.0, 2, 99.9),
    Ok(Metrica(1, 100, 12.0, 2, 99.9)),
  )
  check.eq(validacao.nova_metrica(0, 100, 12.0, 2, 99.9), Error(IdInvalido))
  check.eq(
    validacao.nova_metrica(1, 100, 12.0, 2, 120.0),
    Error(DisponibilidadeForaDaFaixa),
  )
  check.eq(
    validacao.nova_metrica(1, 100, 12.0, 2, -0.5),
    Error(DisponibilidadeForaDaFaixa),
  )
  check.eq(
    validacao.nova_metrica(1, 100, -1.0, 2, 99.9),
    Error(TempoRespostaNegativo),
  )
  check.eq(
    validacao.nova_metrica(1, 10, 12.0, 20, 99.9),
    Error(FalhasExcedemRequisicoes),
  )
  check.eq(
    validacao.nova_metrica(1, 10, 12.0, -1, 99.9),
    Error(FalhasExcedemRequisicoes),
  )
  check.eq(
    validacao.nova_metrica(1, 0, 0.0, 0, 100.0),
    Ok(Metrica(1, 0, 0.0, 0, 100.0)),
  )
}

pub fn validar_metricas_examples() {
  check.eq(validacao.validar_metricas([]), Ok(Nil))
  check.eq(validacao.validar_metricas([Metrica(1, 10, 5.0, 1, 99.0)]), Ok(Nil))
  check.eq(
    validacao.validar_metricas([
      Metrica(1, 10, 5.0, 1, 99.0),
      Metrica(2, 10, 5.0, 1, 99.0),
    ]),
    Ok(Nil),
  )
  check.eq(
    validacao.validar_metricas([
      Metrica(1, 10, 5.0, 1, 99.0),
      Metrica(2, 10, 5.0, 99, 99.0),
    ]),
    Error(FalhasExcedemRequisicoes),
  )
  check.eq(
    validacao.validar_metricas([Metrica(0, 10, 5.0, 1, 99.0)]),
    Error(IdInvalido),
  )
}

pub fn nova_instancia_examples() {
  check.eq(
    validacao.nova_instancia(1, "api-1", []),
    Ok(Instancia(1, "api-1", [])),
  )
  check.eq(validacao.nova_instancia(0, "api-1", []), Error(IdInvalido))
  check.eq(validacao.nova_instancia(1, "", []), Error(NomeVazio))
  check.eq(
    validacao.nova_instancia(1, "api-1", [Metrica(1, 10, 5.0, 50, 99.0)]),
    Error(FalhasExcedemRequisicoes),
  )
}

pub fn validar_instancias_examples() {
  check.eq(validacao.validar_instancias([]), Ok(Nil))
  check.eq(validacao.validar_instancias([Instancia(1, "a", [])]), Ok(Nil))
  check.eq(
    validacao.validar_instancias([Instancia(1, "", [])]),
    Error(NomeVazio),
  )
  check.eq(
    validacao.validar_instancias([
      Instancia(1, "a", []),
      Instancia(2, "", []),
    ]),
    Error(NomeVazio),
  )
}

pub fn novo_servico_examples() {
  check.eq(
    validacao.novo_servico(1, "api", tipos.Api, [], []),
    Ok(Servico(1, "api", tipos.Api, [], [])),
  )
  check.eq(
    validacao.novo_servico(0, "api", tipos.Api, [], []),
    Error(IdInvalido),
  )
  check.eq(validacao.novo_servico(1, "", tipos.Api, [], []), Error(NomeVazio))
  check.eq(
    validacao.novo_servico(
      1,
      "api",
      tipos.Api,
      [Instancia(1, "i", [Metrica(1, 10, 5.0, 50, 99.0)])],
      [],
    ),
    Error(FalhasExcedemRequisicoes),
  )
  check.eq(
    validacao.novo_servico(1, "api", tipos.Api, [], [
      Servico(2, "", tipos.BancoDados, [], []),
    ]),
    Error(NomeVazio),
  )
}

pub fn validar_servicos_examples() {
  check.eq(validacao.validar_servicos([]), Ok(Nil))
  check.eq(
    validacao.validar_servicos([Servico(1, "a", tipos.Api, [], [])]),
    Ok(Nil),
  )
  check.eq(
    validacao.validar_servicos([
      Servico(1, "a", tipos.Api, [], [
        Servico(0, "b", tipos.BancoDados, [], []),
      ]),
    ]),
    Error(IdInvalido),
  )
}

