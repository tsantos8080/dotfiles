---
name: review-pr
description: >-
  Revisa o PR da branch atual antes de pedir revisão ao time, como um substituto da revisão humana -
  confere se o PR entrega o que a tarefa do Jira pede, roda as checagens do projeto, um subagente
  revisor aponta problemas usando o checklist pessoal, um segundo subagente verifica cada apontamento
  no código e descarta falsos positivos, e no fim publica os comentários aprovados pelo usuário como
  uma review no GitHub. Use quando o usuário chamar /review-pr ou $review-pr, ou pedir para "revisar
  meu PR" antes de pedir revisão.
disable-model-invocation: true
---

# Revisar o próprio PR

Objetivo: chegar à revisão do time com o PR já limpo. Um agente revisa, outro
verifica, e só o que se sustenta vai para o GitHub. Tom sempre profissional:
os comentários ficam visíveis para o time.

## 1. Identifique o PR

```bash
git rev-parse --show-toplevel
gh pr view --json number,url,title,body,baseRefName,headRefName,headRefOid,isDraft
```

- Sem PR para a branch atual: avise e ofereça revisar o diff contra a branch
  padrão sem publicar nada no fim.
- Compare `headRefOid` com `git rev-parse HEAD`. Se houver commits locais sem
  push, ou o remoto estiver à frente, pare e pergunte: a revisão precisa ser
  do mesmo código que está no GitHub, senão as linhas dos comentários não
  batem.
- Árvore suja (`git status --short`): avise que alterações não commitadas
  ficam fora da revisão.

## 2. Junte o contexto (você mesmo, antes dos subagentes)

1. **Diff:** `git fetch origin <base>` e `git diff origin/<base>...HEAD`.
   Monte a lista de arquivos alterados com as linhas válidas do lado novo de
   cada hunk; só essas linhas aceitam comentário no GitHub.
2. **Tarefa:** extraia a chave do Jira do nome da branch (ex.: `PTB-1234`).
   Se o MCP do Atlassian estiver disponível, leia a tarefa com todos os
   comentários (`getAccessibleAtlassianResources` + `getJiraIssue`). Sem chave
   ou sem MCP, siga sem e registre isso no relatório.
3. **Regras do projeto:** `CLAUDE.md` / `AGENTS.md` do repositório e a
   documentação de arquitetura que ele indicar.
4. **Checagens:** descubra como o projeto se valida (`composer run-script
   --list`, workflows de CI, documentação) e rode, dentro do container se o
   projeto usar Docker:
   - testes das áreas alteradas (a suíte inteira só se for barata);
   - análise estática (ex.: phpstan; com baseline, só erros novos contam);
   - estilo **em modo de conferência** (ex.: php-cs-fixer `--dry-run --diff`).
   Anote o que passou, o que falhou e o que não pôde rodar.
5. **Teste que prova a correção:** se o PR é um `fix` e há teste novo ou
   alterado para o bug, verifique se ele falha sem a correção: crie um
   worktree temporário da base (`git worktree add <tmp> origin/<base>`), copie
   para lá só os arquivos de teste do PR, rode esses testes e remova o
   worktree. Se for caro ou inviável, registre como "não verificado".

## 3. Rodada 1: revisor (subagente)

Despache um subagente **sem o contexto desta conversa**, para que ele não
herde as justificativas de quem escreveu o código. Passe no prompt: o diff
completo, a lista de arquivos com linhas válidas, o resumo da tarefa do Jira e
dos comentários, os resultados das checagens, as regras do projeto e o
conteúdo de `checklist.md` (nesta pasta). Peça que ele:

- verifique primeiro se o PR entrega o que a tarefa pede e nada além do escopo;
- revise o diff pelo checklist e pelo que mais encontrar (regressões, casos de
  borda, testes faltando);
- leia o código ao redor quando precisar, mas não altere nada;
- retorne **só** um array JSON:

```json
[{"file": "app/Foo.php", "line": 42, "severity": "bloqueante|deve-corrigir|detalhe",
  "title": "resumo curto", "comment": "texto do comentário", "suggestion": "código opcional"}]
```

Regras do texto de `comment`:

- português, tom profissional e direto, como um colega explicando;
- comece pelo problema em uma frase, depois diga por que importa e o que fazer;
- explique em poucas palavras, na primeira vez, qualquer termo técnico, sigla
  ou regra citada (ex.: "idempotente: rodar duas vezes dá o mesmo resultado");
- sempre que ajudar a entender, mostre um exemplo curto de código (como está e
  como ficaria) em bloco de código com a linguagem indicada;
- para trocas pequenas e certeiras na própria linha, preencha `suggestion` com
  o código que substitui exatamente a linha comentada.

## 4. Rodada 2: verificador (subagente)

Despache outro subagente, também sem o contexto da conversa, com o diff, a
lista de linhas válidas, o checklist e o array do revisor. Para **cada**
apontamento ele deve conferir no código (abrir o arquivo, procurar chamadores
com `rg`, ler testes) e devolver o mesmo array com dois campos a mais:

- `verdict`: `procede`, `falso-positivo` ou `discutivel`;
- `reason`: uma frase com a evidência (o que viu e onde).

Ele pode corrigir `line`, `severity` e o texto de um apontamento que procede,
e pode acrescentar um apontamento novo só se for `bloqueante`, marcado com
`"found_by": "verificador"`.

Se o agente não suportar subagentes, faça as duas rodadas você mesmo, em
sequência, e na segunda releia o código em vez de confiar na primeira.

## 4.1 Revise o texto dos comentários (humanizer)

Antes de mostrar qualquer coisa, reescreva o `comment` de cada apontamento que
procede ou é discutível seguindo a skill `humanizer`
(`~/.agents/skills/humanizer/SKILL.md`): sem frases de efeito, sem "não é X, é
Y", sem negrito decorativo, sem inflar a importância, sem inventar fatos. Não
altere blocos de código, nomes de classes, métodos, arquivos nem o conteúdo de
`suggestion`.

## 5. Relatório para o usuário

Mostre, em português:

1. **Checagens:** o que passou, falhou ou não rodou.
2. **Tarefa do Jira:** o que o PR cobre, o que falta e o que está fora do
   escopo pedido.
3. **Apontamentos** (`procede` e `discutivel`), agrupados por gravidade
   (bloqueante, deve corrigir, detalhe), cada um com `arquivo:linha`, o
   comentário e, nos discutíveis, o motivo da dúvida.
4. Uma linha com quantos foram descartados como falso positivo.

Pergunte o que publicar: todos, alguns (por número) ou nenhum. Se houver
bloqueantes, sugira corrigir antes de publicar.

## 6. Publique no GitHub

Publique **uma única review** com os comentários escolhidos. Como o PR é do
próprio usuário, o GitHub só aceita o evento `COMMENT`.

- Comentário em linha precisa estar numa linha válida do lado novo do diff;
  o que não couber vai para o corpo da review, com `arquivo:linha`.
- Com `suggestion`, acrescente ao corpo do comentário um bloco
  ```` ```suggestion ```` com o código, para aplicar com um clique.
- Corpo da review: resumo das checagens, da cobertura da tarefa e da
  contagem por gravidade.

```bash
# monte o JSON num arquivo temporário e envie
gh api repos/{owner}/{repo}/pulls/<numero>/reviews --method POST --input <arquivo.json>
```

Formato do JSON: `{"commit_id": "<headRefOid>", "event": "COMMENT", "body":
"...", "comments": [{"path": "...", "line": 42, "side": "RIGHT", "body":
"..."}]}`. Apague o arquivo temporário depois e mostre a URL da review.

Nunca publique sem a escolha explícita do usuário na etapa 5.
