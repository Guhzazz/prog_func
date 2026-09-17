// F1 - Criacao e validacao de valores do dominio.

import servicos_nuvem/tipos.{ type Instancia, type Metrica, type Servico,
  type TipoServico
}


/// Verifica, por recursao estrutural, se todas as metricas de uma lista
/// sao validas. Devolve o primeiro erro encontrado.
pub fn validar_metricas(metricas: List(Metrica)) -> Result(Nil, ErroValidacao) {
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


/// Verifica, por recursao estrutural, se todas as instancias sao validas.
pub fn validar_instancias(
  instancias: List(Instancia),
) -> Result(Nil, ErroValidacao) {
  case instancias {
    [] -> Ok(Nil)
    [i, ..resto] ->
      case nova_instancia(i.id, i.nome, i.metricas) {
        Error(erro) -> Error(erro)
        Ok(_) -> validar_instancias(resto)
      }
  }
}


/// Valida uma lista de servicos percorrendo tambem suas dependencias
/// (recursao sobre o tipo autorreferente).
pub fn validar_servicos(servicos: List(Servico)) -> Result(Nil, ErroValidacao) {
  case servicos {
    [] -> Ok(Nil)
    [s, ..resto] ->
      case novo_servico(s.id, s.nome, s.tipo, s.instancias, s.dependencias) {
        Error(erro) -> Error(erro)
        Ok(_) -> validar_servicos(resto)
      }
  }
}

