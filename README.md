# prog_func
Trabalhos da disciplina de Programação Funcional
=======
# Monitoramento de Serviços em Nuvem — Trabalho Prático 1

**Disciplina:** Programação Funcional  
**Tema (Seção 4, item 8):** Monitoramento de serviços e instâncias de uma aplicação distribuída  
**Integrantes:** Bernardo Wilchen de Oliveira, Gustavo Valério dos Santos  
**Linguagem/ferramenta:** Gleam, testado com **`sgleam`**

## Descrição do sistema

O sistema modela o monitoramento de uma aplicação distribuída composta por
vários **serviços** (APIs, bancos de dados, armazenamento, autenticação).
Cada serviço roda uma ou mais **instâncias**, e cada instância acumula
várias leituras de **métrica** ao longo do tempo (requisições, tempo de
resposta, falhas, disponibilidade). Um serviço também pode **depender**
de outros serviços — essa relação é o tipo autorreferente do projeto e
forma um grafo (`Aplicação → Serviço → Instância → Métrica`, mais
`Serviço → dependências → Serviço`).

O estado de saúde (`Operacional`, `Degradado`, `Indisponível`) **nunca é
armazenado** — é sempre calculado a partir das métricas (F2), para nunca
ficar desatualizado.


## Tipos criados (modelagem — Seção 3.1)

| Tipo | Categoria de ADT | Papel |
|---|---|---|
| `TipoServico` | tipo soma | papel do serviço: `Api`, `BancoDados`, `Armazenamento`, `Autenticacao` |
| `Status` | tipo soma | estado de saúde: `Operacional`, `Degradado`, `Indisponivel` — **sempre calculado**, nunca armazenado |
| `ErroValidacao` | tipo soma | motivo específico de falha de validação (usado com `Result`) |
| `Metrica` | tipo produto | `id, requisicoes, tempo_resposta_ms, falhas, disponibilidade` |
| `Instancia` | tipo produto | `id, nome, metricas: List(Metrica)` |
| `Servico` | tipo produto **autorreferente** | `id, nome, tipo_servico, instancias: List(Instancia), dependencias: List(Servico)` |
| `Aplicacao` | tipo produto | `nome, servicos: List(Servico)` |

**A autorreferência do projeto é `Servico.dependencias: List(Servico)`**
— um grafo de dependências entre serviços. Assumimos que esse grafo não
tem ciclos (documentado em `hierarquia.gleam`).

> **Decisão de design:** `Servico` tem 6 campos, sem um campo `status`
> separado. Um rascunho anterior tinha `status: Status` guardado junto
> com `tipo_servico`, mas isso conflitava com um teste que já existia
> (`validacao_test.gleam`, que sempre assumiu 5 campos) e, mais
> importante, nenhuma função do projeto chegou a *ler* esse campo — o
> status sempre foi recalculado a partir das métricas. Resolvido a favor
> dos 5 campos.

## Relação entre as funcionalidades (F1–F10) e o código

| Func. | O que faz | Onde está implementada |
|---|---|---|
| F1 | Criação e validação | `validacao.nova_metrica/5`, `validacao.nova_instancia/3`, `validacao.novo_servico/5` |
| F2 | Classificação por pattern matching (3 categorias) | `analise.classificar_metricas/1`, `analise.classificar_servico/1` |
| F3 | Agregação sobre lista | `listas.total_requisicoes/1`, `listas.total_falhas/1`, `listas.soma_disponibilidade/1`, `listas.soma_tempo_resposta/1`, `listas.disponibilidade_media/1`, `listas.tempo_resposta_medio/1` |
| F4 | Filtragem recursiva | `listas.metricas_abaixo_de/2` (parametrizada por limite) |
| F5 | Transformação recursiva | `listas.penalizar_por_falhas/1` |
| F6 | Busca | `listas.buscar_instancia_por_id/2` |
| F7 | Maior/menor elemento | `listas.metrica_com_menor_disponibilidade/1`, `listas.instancia_com_mais_falhas/1` |
| F8 | Análise combinada | `analise.requisicoes_em_risco/2`, `analise.metrica_mais_critica/2` |
| F9 | Processamento hierárquico (autorreferência) | `hierarquia.contar_servicos/1`, `hierarquia.achatar/1`, `hierarquia.todas_instancias/1`, `hierarquia.todas_metricas/1`, `hierarquia.profundidade/1` |
| F10 | Relatório textual | `analise.gerar_relatorio/1` |


## Estrutura do projeto

```
trabalho01/
  src/
    tipos.gleam         - ADTs do domínio (Seção 3.1)
    validacao.gleam      - F1
    listas.gleam         - F3, F4, F5, F6, F7
    hierarquia.gleam      - F9 (recursão sobre o grafo de dependências)
    analise.gleam         - F2, F8, F10
  tests/
    validacao_test.gleam
    listas_test.gleam
    hierarquia_test.gleam
    analise_test.gleam
```

## Como executar

A partir da pasta `trabalho01/`:

```
sgleam test tests/validacao_test.gleam
sgleam test tests/listas_test.gleam
sgleam test tests/hierarquia_test.gleam
sgleam test tests/analise_test.gleam
```

Os imports internos (`import src/tipos`, `import src/analise` etc.)
assumem que o comando é rodado de dentro de `trabalho01/`.

### Como isso foi validado

Sem o `sgleam` disponível neste ambiente, tudo foi validado com o
compilador `gleam` padrão (Erlang) + uma implementação própria,
compatível, do módulo `sgleam/check` — rodando de fato cada função
`_examples`, não só compilando. **Compila limpo e todos os testes
passam**, com uma exceção conhecida:

> `listas_test.soma_tempo_resposta_examples` espera `0.1 + 0.2 == 0.3`
> exatamente. Em ponto flutuante isso dá `0.30000000000000004`, não
> `0.3` — é uma limitação normal de `Float`, não um bug de lógica.   