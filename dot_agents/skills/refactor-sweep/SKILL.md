---
name: refactor-sweep
description: Revisa em conjunto uma sequência de commits ou PRs já mergeados numa mesma área, depois de um refactor, procurando o que as revisões de cada PR isolado não pegam - duplicação entre PRs, código morto, sobras, mudança de comportamento silenciosa, testes faltando ou instáveis e checagens quebradas. Use quando o usuário falar em "pós-refactor", "depois do refactor", "revisar os últimos PRs", "varredura", "refactor sweep", ou antes de um deploy grande. Não use para revisar um único PR aberto.
---

# Varredura pós-refactor

Cada PR pode estar certo sozinho e o conjunto ainda assim deixar problema: duas
funções iguais criadas em PRs diferentes, uma classe antiga que ninguém mais
chama, um comportamento que mudou no meio do caminho. Esta skill olha para o
resultado somado.

Por padrão, só revise e relate. Edite código apenas se o usuário pedir.

## 1. Defina o intervalo

- Se o usuário deu um intervalo (commits, PRs, tag, datas), use exatamente ele.
- Senão, proponha um e confirme com o usuário. Bons pontos de partida:
  - os últimos merges no branch principal:
    `git log --first-parent --merges --oneline -15`
  - desde a última tag: `git describe --tags --abbrev=0`
- Mostre o tamanho do que vai revisar: `git diff --stat <início>..<fim>`.

Se o intervalo mistura áreas sem relação, separe por área e revise cada uma.

## 2. Rode as checagens do projeto

Descubra como o projeto checa a si mesmo antes de inventar comandos:
`composer run-script --list`, os workflows de CI e a documentação. Se o projeto
roda em Docker, rode dentro do container da aplicação.

O conjunto típico em PHP/Laravel:

- estilo: php-cs-fixer **sempre com `--dry-run --diff`** e a config do projeto
  (uma revisão não altera arquivos);
- análise estática: phpstan. Com baseline, conte só os erros novos, e trate o
  baseline crescendo no intervalo como problema;
- testes: os das áreas tocadas primeiro, a suíte inteira se for barato;
- dependências: `composer audit` (e `npm audit` se o intervalo mexeu em front);
- compatibilidade: a checagem de quebra de API do projeto, se existir.

Ferramenta que não está instalada é uma lacuna a relatar, não uma aprovação.

## 3. Procure no diff somado

Olhe o diff do intervalo inteiro (`git diff <início>..<fim>`), não PR por PR.

**Sobras**
- métodos, classes, rotas, bindings do container ou configs sem nenhum uso
  (confira com `rg` antes de afirmar);
- comentários, docblocks e documentação descrevendo o comportamento antigo;
- `dd()`, `dump()`, `ray()`, `var_dump()` e logs de depuração esquecidos.

**Duplicação**
- lógica parecida criada em PRs diferentes, que deveria ser uma só;
- constantes e valores mágicos repetidos (`$status === 7`) que pedem um enum
  ou uma constante.

**Comportamento que mudou sem querer**
- exceção que antes subia e agora é engolida por um `catch` amplo, ou deixou de
  chegar no monitoramento de erros;
- valor padrão, retorno `null`, ordenação ou formato de resposta da API
  (Resources, `$hidden`, casts) diferente do antigo;
- jobs, eventos e listeners cujo construtor mudou enquanto ainda pode haver
  jobs antigos na fila;
- `env()` fora de `config/`, que retorna `null` com o config em cache.

**Banco e Eloquent**
- consultas N+1 porque o acesso à relação mudou de lugar ou o eager loading
  sumiu;
- várias escritas que antes estavam num `DB::transaction` e agora não estão;
- `whereRaw`/`DB::raw` com variável concatenada;
- mudanças em `$fillable`/`$guarded`;
- migration que não tem volta ou que trava uma tabela grande.

**Estrutura**
- interface, classe abstrata ou trait nova com uma única implementação e sem
  motivo concreto;
- import que atravessa os limites entre módulos documentados no projeto.

**Testes**
- comportamento novo ou alterado sem teste que o cubra;
- teste que verifica detalhe de implementação em vez de comportamento;
- sinais de teste instável: `Carbon::setTestNow()` sem reset, chamada HTTP real
  onde deveria haver `Http::fake()`, estado estático compartilhado, dependência
  de ordem dos seeders, `sleep`, e testes que quebram em paralelo (paratest).

Se um teste falhar uma vez, rode de novo só ele antes de concluir. Se passar,
relate como "falha intermitente observada", não como resolvido.

## 4. Relate

Classifique cada achado:

- **🔴 corrigir antes do deploy**: regressão provável, falha de segurança,
  perda de dados, checagem quebrada;
- **🟡 corrigir em breve**: duplicação que vai divergir, teste faltando para
  uma mudança real, sobra que vai confundir a próxima pessoa;
- **⚪ opcional**: limpeza e legibilidade.

Formato:

```markdown
## Varredura: <intervalo>

Checagens: <o que passou, o que falhou, o que não rodou>

### Achados
- 🔴 `arquivo.php:42` — <problema>. Por que importa: <...>. Sugestão: <...>. (verificado com: <comando ou leitura>)

### Áreas revisadas sem problema
- <...>

### Próximo passo sugerido
- <uma ação concreta, ou "nenhum">
```

Se nada precisar mudar, diga isso direto e liste as checagens que passaram.
