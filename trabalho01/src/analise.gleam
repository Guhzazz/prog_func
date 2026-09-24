// F2 - Classificacao

/// Classifica a situacao a partir da disponibilidade media das
/// metricas informadas:
///   media >= 99.0        -> Operacional
///   90.0 <= media < 99.0 -> Degradado
///   media <  90.0        -> Indisponivel
/// A lista vazia e classificada como Indisponivel.
pub fn classificar_metricas(metricas: List(Metrica)) -> Status {
  let media = listas.disponibilidade_media(metricas)
  case media >=. 99.0, media >=. 90.0 {
    True, _ -> Operacional
    False, True -> Degradado
    False, False -> Indisponivel
  }
}


/// F2 - Classifica um servico a partir das metricas de suas instancias.
pub fn classificar_servico(servico: Servico) -> Status {
  classificar_metricas(listas.metricas_das_instancias(servico.instancias))
}