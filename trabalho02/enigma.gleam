//// Módulo enigma — define os tipos algébricos de enigmas, funções puras
//// de resolução e consulta de pistas, além dos desafios do Hospital no Escuro.

import configuracao
import gleam/string
import jogador.{type Jogador, adicionar_item, novo_jogador, tem_item}
import sgleam/check

/// Representa o estado atual de um enigma no jogo (tipo soma).
pub type StatusEnigma {
  Pendente
  Resolvido
}

/// Representa um desafio lógico que recompensa o jogador ao ser solucionado.
pub type Enigma {
  Enigma(
    nome: String,
    descricao: String,
    solucao: String,
    pistas: List(String),
    efeito: fn(Jogador) -> Jogador,
    status: StatusEnigma,
  )
}

/// Normaliza uma resposta textual removendo espaços extras e convertendo
/// para letras minúsculas, facilitando a comparação sem sensibilidade a caixa.
fn normalizar_texto(texto: String) -> String {
  texto
  |> string.trim()
  |> string.lowercase()
}

pub fn normalizar_texto_examples() {
  check.eq(normalizar_texto("  B47 "), "b47")
  check.eq(normalizar_texto("Sala 3"), "sala 3")
}

/// Verifica se a resposta informada corresponde à solução do enigma.
pub fn verificar_resposta(enigma: Enigma, resposta: String) -> Bool {
  normalizar_texto(resposta) == normalizar_texto(enigma.solucao)
}

pub fn verificar_resposta_examples() {
  let e = enigma_terminal_evacuacao()
  check.eq(verificar_resposta(e, "b47"), True)
  check.eq(verificar_resposta(e, "  B47  "), True)
  check.eq(verificar_resposta(e, "a10"), False)
}

const nome_sequencia_gerador = "Sequência do Gerador"

/// Resolve o enigma ou explica por que a tentativa falhou.
pub fn resolver_com_mensagem(
  enigma: Enigma,
  resposta: String,
  jogador: Jogador,
) -> Result(#(Enigma, Jogador), String) {
  case enigma.status {
    Resolvido -> Ok(#(enigma, jogador))
    Pendente -> {
      let sem_energia =
        enigma.nome == nome_sequencia_gerador
        && !tem_item(jogador, "energia restaurada")
      case sem_energia, verificar_resposta(enigma, resposta) {
        True, _ -> Error("Ligue o painel do gerador antes de informar o código.")
        False, False -> Error("Resposta incorreta.")
        False, True -> Ok(#(
          Enigma(..enigma, status: Resolvido),
          enigma.efeito(jogador),
        ))
      }
    }
  }
}

/// Devolve o enigma, o jogador e um indicador de sucesso.
pub fn tentar_resolver(
  enigma: Enigma,
  resposta: String,
  jogador: Jogador,
) -> #(Enigma, Jogador, Bool) {
  case resolver_com_mensagem(enigma, resposta, jogador) {
    Ok(#(resolvido, atualizado)) -> #(resolvido, atualizado, True)
    Error(_) -> #(enigma, jogador, False)
  }
}

pub fn tentar_resolver_examples() {
  let j0 = novo_jogador("Ana", "Corredor")
  let e0 = enigma_trava_corredor()

  // Resposta incorreta mantém estado inalterado
  let #(e_erro, j_erro, ok_erro) = tentar_resolver(e0, "9", j0)
  check.eq(ok_erro, False)
  check.eq(e_erro.status, Pendente)
  check.eq(tem_item(j_erro, "acesso corredor"), False)

  // Resposta correta marca como Resolvido e aplica efeito no jogador
  let #(e_ok, j_ok, ok_acerto) = tentar_resolver(e0, " 3 ", j0)
  check.eq(ok_acerto, True)
  check.eq(e_ok.status, Resolvido)
  check.eq(tem_item(j_ok, "acesso corredor"), True)
}

/// Aplica a resolução do enigma retornando apenas o novo estado do Jogador
pub fn resolver_enigma(
  enigma: Enigma,
  resposta: String,
  jogador: Jogador,
) -> Jogador {
  let #(_, novo_jogador, _) = tentar_resolver(enigma, resposta, jogador)
  novo_jogador
}

pub fn resolver_enigma_examples() {
  let j = novo_jogador("Ana", "Sala 3")
  let e = enigma_sequencia_gerador()
  check.eq(tem_item(resolver_enigma(e, "000", j), "codigo evacuacao"), False)
  check.eq(tem_item(resolver_enigma(e, "347", j), "codigo evacuacao"), True)
}

/// Formata recursivamente uma lista de pistas em uma única String numerada.
pub fn formatar_pistas(pistas: List(String)) -> String {
  formatar_pistas_aux(pistas, 1)
}

fn formatar_pistas_aux(pistas: List(String), indice: Int) -> String {
  case pistas {
    [] -> ""
    [primeira, ..resto] -> {
      let linha = "Pista " <> string.inspect(indice) <> ": " <> primeira
      case resto {
        [] -> linha
        _ -> linha <> "\n" <> formatar_pistas_aux(resto, indice + 1)
      }
    }
  }
}

pub fn formatar_pistas_examples() {
  check.eq(formatar_pistas([]), "")
  check.eq(
    formatar_pistas(["Olhe a planta", "Verifique o registro"]),
    "Pista 1: Olhe a planta\nPista 2: Verifique o registro",
  )
}

/// Verifica recursivamente se todos os enigmas de uma lista já foram resolvidos.
pub fn todos_resolvidos(enigmas: List(Enigma)) -> Bool {
  case enigmas {
    [] -> True
    [primeiro, ..resto] ->
      case primeiro.status {
        Pendente -> False
        Resolvido -> todos_resolvidos(resto)
      }
  }
}

pub fn todos_resolvidos_examples() {
  let pendente = enigma_trava_corredor()
  let resolvido = Enigma(..pendente, status: Resolvido)

  check.eq(todos_resolvidos([]), True)
  check.eq(todos_resolvidos([resolvido]), True)
  check.eq(todos_resolvidos([resolvido, pendente]), False)
}

// --- Enigmas da narrativa: Hospital no Escuro ---

/// Enigma 1: libera o acesso do corredor para a sala do gerador.
pub fn enigma_trava_corredor() -> Enigma {
  Enigma(
    nome: "Trava do Corredor",
    descricao: "O visor de emergência pede o número da sala onde está instalado o gerador auxiliar.",
    solucao: "3",
    pistas: [
      "A resposta é a identificação numérica da sala do gerador.",
      "O registro da Manutenção informa essa identificação. Não há zero à esquerda.",
    ],
    efeito: fn(j) { adicionar_item(j, "acesso corredor") },
    status: Pendente,
  )
}

/// Enigma 2: combina as pistas do registro e da planta para gerar o código de saída.

pub fn enigma_sequencia_gerador() -> Enigma {
  Enigma(
    nome: "Sequência do Gerador",

    descricao: "Informe a sequência de segurança formada pelo número da sala do gerador seguido dos algarismos da identificação da porta técnica.",

    solucao: "3" <> string.slice(
      configuracao.codigo_saida,
      1,
      2,
    ),

    pistas: [
      "Comece com o número da sala onde o gerador está instalado.",
      "Complete com os dois algarismos da identificação na planta, sem a letra.",
    ],

    efeito: fn(j) {
      adicionar_item(j, "codigo evacuacao")
    },

    status: Pendente,
  )
}


/// Enigma 3: destrava a rota final de saída do hospital.

pub fn enigma_terminal_evacuacao() -> Enigma {
  Enigma(
    nome: "Terminal de Saída",

    descricao: "O terminal solicita a identificação completa da porta técnica para autorizar a rota de evacuação.",

    solucao: configuracao.codigo_saida,

    pistas: [
      "Use a identificação alfanumérica registrada na planta, sem remover a letra.",
      "O código da sequência da Sala 3 usa apenas a parte numérica dessa identificação.",
    ],

    efeito: fn(j) {
      adicionar_item(j, "rota liberada")
    },

    status: Pendente,
  )
}
