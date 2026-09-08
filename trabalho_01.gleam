///Programação Funcional - Trabalho 01


/// Representa os papéis dos serviços da arquitetura em nuvem
pub type TipoServico {
  API
  BancoDados
  Armazenamento
  Autenticacao
}

/// Representa o estado de "saúde" de uma instância ou serviço
pub type Status {
  Operacional
  Degradado
  Indisponivel
}

/// Represeta todos os indicadores de desempenho e telemetria capturados de uma instância em um único registro.
pub type Metricas {
  Metricas(
    requisicoes: Int,
    falhas: Int,
    disponibilidade_prcnt: Float,
    tempo_resposta_ms: Option(Float), // Option pq "Indisponivel" não tem tempo de resposta por exemplo
  )
}

/// Representa a instância de execução de um serviço
pub type Instancia{
  Instancia(id: Int, nome: String, metricas: List(Metricas))
}


///Tipo autorreferente, já que um serviço pode depender de outro
pub type Servico{
  Servico(
    id: Int,
    nome: String,
    status: StatusServico,
    instancias: List(Instancia),
    dependencias: List(Servico)
  )

}

