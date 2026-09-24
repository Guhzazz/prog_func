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
        status: Indisponivel,
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
        status: Indisponivel,
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
        status: Operacional,
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