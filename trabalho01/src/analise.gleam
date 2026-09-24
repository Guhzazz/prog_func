import gleam/float
import gleam/int
import src/hierarquia
import src/listas
import src/tipos.{
  type Metrica, type Servico, type Status, Degradado, Indisponivel,
  Operacional,
}

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

// F8 - Analise combinada

/// Etapa 1: reune as metricas do servico e de toda a sua cadeia de
/// dependencias (F9, hierarquia.todas_metricas). Etapa 2: filtra so as
/// que estao abaixo do limite de disponibilidade informado (F4,
/// listas.metricas_abaixo_de). Etapa 3: soma as requisicoes dessas
/// metricas (F3, listas.total_requisicoes).
/// Resultado: quantas requisicoes estao passando, agora, por alguma
/// metrica abaixo do limite, considerando toda a cadeia de dependencias.
pub fn requisicoes_em_risco(servico: Servico, limite: Float) -> Int {
  let todas = hierarquia.todas_metricas(servico)
  let criticas = listas.metricas_abaixo_de(todas, limite)
  listas.total_requisicoes(criticas)
}

/// F8 - variacao: entre as metricas abaixo do limite, na cadeia de
/// dependencias inteira, aponta a de menor disponibilidade (combina
/// filtro F4 + menor elemento F7), para priorizar o que investigar
/// primeiro.
pub fn metrica_mais_critica(
  servico: Servico,
  limite: Float,
) -> Result(Metrica, Nil) {
  let todas = hierarquia.todas_metricas(servico)
  let criticas = listas.metricas_abaixo_de(todas, limite)
  listas.metrica_com_menor_disponibilidade(criticas)
}

// F10 - Relatorio textual

/// Reune pelo menos tres informacoes calculadas sobre um servico e toda
/// a sua cadeia de dependencias, como pede o enunciado.
pub fn gerar_relatorio(servico: Servico) -> String {
  let todos_servicos = hierarquia.achatar(servico)
  let metricas = hierarquia.todas_metricas(servico)

  let qtd_servicos = quantidade_servicos(todos_servicos)
  let total_req = listas.total_requisicoes(metricas)
  let total_falhas = listas.total_falhas(metricas)
  let disp_media = listas.disponibilidade_media(metricas)
  let status = classificar_metricas(metricas)
  let risco = requisicoes_em_risco(servico, 99.0)

  "Relatorio de monitoramento - "
  <> servico.nome
  <> "\n"
  <> "Status calculado: "
  <> status_para_texto(status)
  <> "\n"
  <> "Servicos na cadeia de dependencias (incluindo o proprio): "
  <> int.to_string(qtd_servicos)
  <> "\n"
  <> "Total de requisicoes: "
  <> int.to_string(total_req)
  <> "\n"
  <> "Total de falhas: "
  <> int.to_string(total_falhas)
  <> "\n"
  <> "Disponibilidade media: "
  <> float.to_string(disp_media)
  <> "%\n"
  <> "Requisicoes em risco (metricas abaixo de 99%): "
  <> int.to_string(risco)
}

fn status_para_texto(status: Status) -> String {
  case status {
    Operacional -> "Operacional"
    Degradado -> "Degradado"
    Indisponivel -> "Indisponivel"
  }
}

fn quantidade_servicos(servicos: List(Servico)) -> Int {
  case servicos {
    [] -> 0
    [_, ..resto] -> 1 + quantidade_servicos(resto)
  }
}
