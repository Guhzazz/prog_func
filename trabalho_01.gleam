///Programação Funcional - Trabalho 01


pub type TipoServico {
    /// Representa os papéis dos serviços da arquitetura em nuvem
  API
  BancoDados
  Armazenamento
  Autenticacao
}

pub type Status {
    /// Representa o estado de "saúde" de uma instância ou serviço
  Operacional
  Degradado
  Indisponivel
}

pub type Metricas {
    /// Represeta todos os indicadores de desempenho e telemetria capturados de uma instância em um único registro.
  Metricas(
    id: Int,
    requisicoes: Int,
    falhas: Int,
    disponibilidade_prcnt: Float,
    tempo_resposta_ms: Option(Float), // Option pq "Indisponivel" não tem tempo de resposta por exemplo
    status: Status,
  )
}