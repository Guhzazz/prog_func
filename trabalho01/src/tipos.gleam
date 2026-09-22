
/// Representa os papéis dos serviços da arquitetura em nuvem
pub type TipoServico {
  Api
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

/// Erros de validacao do dominio.
pub type ErroValidacao {
  IdInvalido
  NomeVazio
  DisponibilidadeForaDaFaixa
  TempoRespostaNegativo
  FalhasExcedemRequisicoes
}


/// Represeta todos os indicadores de desempenho e telemetria capturados de uma instância em um único registro.
pub type Metrica {
  Metrica(
    id: Int,
    requisicoes: Int,
    tempo_resposta_ms: Float,
    falhas: Int,
    disponibilidade: Float,
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
    status: Status,
    instancias: List(Instancia),
    dependencias: List(Servico)
  )

}

/// Tipo produto: aplicação distribuída, conjunto de serviços de topo.
pub type Aplicacao {
  Aplicacao(nome: String, servicos: List(Servico))
}

