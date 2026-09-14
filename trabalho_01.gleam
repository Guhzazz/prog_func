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
    status: Status,
    instancias: List(Instancia),
    dependencias: List(Servico)
  )

}

/// Tipo produto: aplicação distribuída, conjunto de serviços de topo.
pub type Aplicacao {
  Aplicacao(nome: String, servicos: List(Servico))
}

// F1: criação e validação

/// Verifica se um id é válido(maior que 0)
pub fn validar_id(id: Int) -> Result(Nil, String) {
  case id > 0 {
    True -> Ok(Nil)
    False -> Error("id deve ser um inteiro positivo")
  }
}

/// Verifica se um nome é válido(não pode ser vazio)
pub fn validar_nome(nome: String) -> Result(Nil, String) {
  case nome {
    "" -> Error("nome do serviço não pode ser vazio")
    _ -> Ok(Nil)
  }
}


/// Verifica se todas as métricas de todas as instâncias têm
/// disponibilidade dentro da faixa válida (0, 100).
fn validar_instancias(instancias: List(Instancia)) -> Result(Nil, String) {
  case instancias {
    [] -> Ok(Nil)
    [primeiro, ..resto] ->
      case validar_metricas(primeiro.metricas) {
        Error(msg) -> Error(msg)
        Ok(_) -> validar_instancias(resto)
      }
  }
}
