import sgleam/check
import gleam/string
import src/analise
import src/tipos.{
  Api, Armazenamento, BancoDados, Degradado, Indisponivel, Instancia,
  Metrica, Operacional, Servico,
}

pub fn classificar_metricas_examples() {
  check.eq(analise.classificar_metricas([]), Indisponivel)
  check.eq(
    analise.classificar_metricas([Metrica(1, 10, 1.0, 0, 99.9)]),
    Operacional,
  )
  check.eq(
    analise.classificar_metricas([Metrica(1, 10, 1.0, 0, 99.0)]),
    Operacional,
  )
  check.eq(
    analise.classificar_metricas([Metrica(1, 10, 1.0, 1, 95.0)]),
    Degradado,
  )
  check.eq(
    analise.classificar_metricas([Metrica(1, 10, 1.0, 1, 90.0)]),
    Degradado,
  )
  check.eq(
    analise.classificar_metricas([Metrica(1, 10, 1.0, 5, 89.9)]),
    Indisponivel,
  )
}

pub fn classificar_servico_examples() {
  check.eq(
    analise.classificar_servico(
      Servico(
        id: 1,
        nome: "s",
        tipo_servico: Api,
        instancias: [],
        dependencias: [],
      ),
    ),
    Indisponivel,
  )
  check.eq(
    analise.classificar_servico(
      Servico(
        id: 4,
        nome: "storage",
        tipo_servico: Armazenamento,
        instancias: [
          Instancia(4, "s3-regional", [Metrica(6, 300, 400.0, 60, 85.0)]),
        ],
        dependencias: [],
      ),
    ),
    Indisponivel,
  )
  check.eq(
    analise.classificar_servico(
      Servico(
        id: 3,
        nome: "database",
        tipo_servico: BancoDados,
        instancias: [
          Instancia(3, "db-primario", [
            Metrica(4, 5000, 15.0, 2, 99.99),
            Metrica(5, 4800, 18.0, 1, 99.95),
          ]),
        ],
        dependencias: [],
      ),
    ),
    Operacional,
  )
}

// F8 - analise combinada: usa a cadeia de dependencias inteira, nao so
// as instancias do proprio servico.
fn servico_com_dependencia_critica() {
  let banco_critico =
    Servico(
      id: 2,
      nome: "banco-legado",
      tipo_servico: BancoDados,
      instancias: [
        Instancia(20, "i20", [Metrica(200, 300, 900.0, 260, 30.0)]),
      ],
      dependencias: [],
    )

  Servico(
    id: 1,
    nome: "servico-pagamentos",
    tipo_servico: Api,
    instancias: [
      Instancia(10, "i10", [Metrica(100, 1000, 80.0, 2, 99.5)]),
    ],
    dependencias: [banco_critico],
  )
}

pub fn requisicoes_em_risco_examples() {
  check.eq(analise.requisicoes_em_risco(servico_com_dependencia_critica(), 99.0), 300)
}

pub fn requisicoes_em_risco_sem_problemas_examples() {
  let servico =
    Servico(
      id: 1,
      nome: "ok",
      tipo_servico: Api,
      instancias: [Instancia(10, "i10", [Metrica(100, 500, 1.0, 0, 99.9)])],
      dependencias: [],
    )
  check.eq(analise.requisicoes_em_risco(servico, 99.0), 0)
}

pub fn metrica_mais_critica_examples() {
  case analise.metrica_mais_critica(servico_com_dependencia_critica(), 99.0) {
    Ok(metrica) -> check.eq(metrica.id, 200)
    Error(Nil) -> check.true(False)
  }
}

// F10 - relatorio textual: confere que os numeros principais aparecem.
pub fn gerar_relatorio_examples() {
  let relatorio = analise.gerar_relatorio(servico_com_dependencia_critica())
  check.true(string.contains(relatorio, "servico-pagamentos"))
  check.true(string.contains(
    relatorio,
    "Requisicoes em risco (metricas abaixo de 99%): 300",
  ))
}
