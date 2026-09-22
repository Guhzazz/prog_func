// F1 - Criacao e validacao de valores do dominio.

import servicos_nuvem/tipos.{ type Instancia, type Metrica, type Servico,
  type TipoServico
}


/// Cria uma metrica valida a partir dos dados coletados, ou devolve o
/// primeiro erro de validacao encontrado.
pub fn nova_metrica(
  id: Int,
  requisicoes: Int,
  tempo_resposta_ms: Float,
  falhas: Int,
  disponibilidade: Float,
) -> Result(Metrica, ErroValidacao) {
  case id > 0 {
    False -> Error(IdInvalido)
    True ->
      case disponibilidade >=. 0.0 && disponibilidade <=. 100.0 {
        False -> Error(DisponibilidadeForaDaFaixa)
        True ->
          case tempo_resposta_ms >=. 0.0 {
            False -> Error(TempoRespostaNegativo)
            True ->
              case falhas >= 0 && falhas <= requisicoes {
                False -> Error(FalhasExcedemRequisicoes)
                True ->
                  Ok(Metrica(
                    id,
                    requisicoes,
                    tempo_resposta_ms,
                    falhas,
                    disponibilidade,
                  ))
              }
          }
      }
  }
}



/// Verifica, por recursao estrutural, se todas as metricas de uma lista
/// sao validas. Devolve o primeiro erro encontrado.
pub fn validar_metricas(metricas: List(Metrica)) -> Result(Nil, Error) {
  case metricas {
    [] -> Ok(Nil)
    [m, ..resto] ->
      case
        nova_metrica(
          m.id,
          m.requisicoes,
          m.tempo_resposta_ms,
          m.falhas,
          m.disponibilidade,
        )
      {
        Error(erro) -> Error(erro)
        Ok(_) -> validar_metricas(resto)
      }
  }
}


/// Cria uma instancia valida, validando id, nome e todas as metricas.
pub fn nova_instancia(
  id: Int,
  nome: String,
  metricas: List(Metrica),
) -> Result(Instancia, ErroValidacao) {
  case id > 0 {
    False -> Error(IdInvalido)
    True ->
      case nome {
        "" -> Error(NomeVazio)
        _ ->
          case validar_metricas(metricas) {
            Error(erro) -> Error(erro)
            Ok(_) -> Ok(Instancia(id, nome, metricas))
          }
      }
  }
}



/// Verifica, por recursao estrutural, se todas as instancias sao validas.
pub fn validar_instancias(
  instancias: List(Instancia),
) -> Result(Nil, Error) {
  case instancias {
    [] -> Ok(Nil)
    [i, ..resto] ->
      case nova_instancia(i.id, i.nome, i.metricas) {
        Error(erro) -> Error(erro)
        Ok(_) -> validar_instancias(resto)
      }
  }
}


/// Valida o identificador, o nome, todas as instancias e, recursivamente,
/// todos os servicos dos quais ele depende.
pub fn novo_servico(
  id: Int,
  nome: String,
  tipo: TipoServico,
  instancias: List(Instancia),
  dependencias: List(Servico),
) -> Result(Servico, ErroValidacao) {
  case id > 0 {
    False -> Error(IdInvalido)
    True ->
      case nome {
        "" -> Error(NomeVazio)
        _ ->
          case validar_instancias(instancias) {
            Error(erro) -> Error(erro)
            Ok(_) ->
              case validar_servicos(dependencias) {
                Error(erro) -> Error(erro)
                Ok(_) -> Ok(Servico(id, nome, tipo, instancias, dependencias))
              }
          }
      }
  }
}



/// Valida uma lista de servicos percorrendo tambem suas dependencias
/// (recursao sobre o tipo autorreferente).
pub fn validar_servicos(servicos: List(Servico)) -> Result(Nil, Error) {
  case servicos {
    [] -> Ok(Nil)
    [s, ..resto] ->
      case novo_servico(s.id, s.nome, s.tipo, s.instancias, s.dependencias) {
        Error(erro) -> Error(erro)
        Ok(_) -> validar_servicos(resto)
      }
  }
}

