# Generate PR Description Command

## Overview

Analyze the git diff in pr-diff.txt and create a comprehensive PR description.

Focus on the 'why' and 'what' rather than detailed code changes.

After generating the PR description, clean up by deleting pr-diff.txt file.

## Manual Workflow

1. **Generate diff**: `git diff main > pr-diff.txt`
2. **Analyze with AI**: Use this prompt with the generated file
3. **Cleanup**: `rm pr-diff.txt` (or `del pr-diff.txt` on Windows)

## AI Prompt Template

```
Based on the git diff in pr-diff.txt, create a comprehensive PR description in Brazilian Portuguese.

Rules:
 - Output ONLY the markdown PR description content. No AI commentary, no explanations, no metadata, no notes about tools or execution.
 - Start IMMEDIATELY with the PR title in **Conventional Commit (in Portuguese)**.
   Examples:
     feat: adiciona nova validação de CPF
     fix: corrige cálculo de tarifas
     chore: atualiza dependências internas
 - After the title, continue with the PR template normally.
 - You must ALWAYS extract the Jira issue key from the branch name (e.g., feature/PTB-1234 → PTB-1234).
 - You must ALWAYS generate the Jira issue URL in this format:
   https://melhorenvio.atlassian.net/browse/<ISSUE_KEY>
 - The Jira URL MUST appear **exactly one line before** the `[Instruções]` placeholder inside the template. Never place it anywhere else.
 - If the issue key cannot be determined, use:
   https://melhorenvio.atlassian.net/browse/UNKNOWN
 - When possible, include instructions for how to test or simulate behavior via Tinker.

Use this template (starting right after the Conventional Commit title):

## Qual a proposta do PR?

Faça uma breve descrição. O detalhamento devem estar na tarefa linkada ao Jira.

https://melhorenvio.atlassian.net/browse/FOO-1234

[Descrição]

##  Instruções para aplicação do PR e deploy:

Informe os comandos que devem ser executados, alterações em variáveis de ambiente, criação de filas, depreciação e/ou criação de recursos adicionais, etc. Não inclua informações sensíveis como senhas e credenciais.

[Instruções]

## Instruções para simulação de sucesso ou erro desta entrega:

Que procedimentos devem ser realizados para constatar o sucesso ou erro desta entrega?
Exemplo: Após a entrega deve ser realizado uma compra de um frete de Correios / SEDEX, realizada a impressão e verificado se o campo observação é exibido corretamente na etiqueta de frete em dados do destinatário, visto que esse campo não era exibido anteriormente.

[Instruções]

## É possível reverter este PR se apresentar erros graves em ambiente de produção?

Informe as tapas que devem ser executadas para a reversão ou então o motivo pelo qual não se pode reverter.

[Sim / Não]

Motivo: [Descrição]

Procedimento de reversão: [Descrição]

## Quando este PR deve ser publicado?

Informe uma data prevista para publicação em ambiente de produção ou então deixa a opção "assim que possível" para que seja incluído no próximo deploy. Se houver algum impedimento informe "não definido".

[dd/mm/YYYY H / Assim que possível / Não definido].

## Existem modificações de estrutura de banco de dados que devem ser informados a outros times com o intuito de evitar que processos que dependam dessas informações falhem?

O BI pode ser afetado por modificações em estrutura de banco de dados.

[Sim / Não]

## Existe manipulação de dados pessoais ou sensíveis neste PR?

Marcar alguém do time de segurança.

[Sim / Não]

---
Recomendações para pull requests, deploys e entregas podem ser acessadas [clicando aqui](https://menv.io/vwdamlK).





<-- BEGIN EXAMPLE 1 -->

## Qual a proposta do PR?

Adiciona a coluna orders.delivery_promise (promessa de entrega) no banco de dados.

https://melhorenvio.atlassian.net/browse/FOO-1234

##  Instruções para aplicação do PR e deploy:

Rodar migrations.

## Instruções para simulação de sucesso ou erro desta entrega:

A nova coluna orders.delivery_promise é criada na tabela orders do banco de dados, aceitando valores nulos por padrão.

## É possível reverter este PR se apresentar erros graves em ambiente de produção?

Sim, removendo a coluna migrada.

## Quando este PR deve ser publicado?

Assim que possível.

## Existem modificações de estrutura de banco de dados que devem ser informados a outros times com o intuito de evitar que processos que dependam dessas informações falhem?

Não.

## Existe manipulação de dados pessoais ou sensíveis neste PR?

Não.

---
Recomendações para pull requests, deploys e entregas podem ser acessadas [clicando aqui](https://menv.io/vwdamlK).

<-- END EXAMPLE 1 -->

<-- BEGIN EXAMPLE 2 -->

## Qual a proposta do PR?

Adicionar o novo motivo de encerramento de operação "Operação encerrada devido à retenção provisória de crédito recente" (ID 12) para cobrir casos onde um valor fica temporariamente indisponível devido à retenção automática aplicada após uma operação de crédito recente.

O novo motivo permite que o time financeiro informe corretamente aos clientes que a operação foi encerrada porque o crédito possui um período de retenção de 5 dias antes de estar disponível, quando há crédito recente associado.

https://melhorenvio.atlassian.net/browse/FOO-1234

## Instruções para aplicação do PR e deploy:

1. Executar o seeder para popular o novo motivo de encerramento no banco de dados:

`php artisan db:seed --class=OperationClosureReasonSeeder`

## Instruções para simulação de sucesso ou erro desta entrega:

**Cenário de sucesso:**

1. Acessar o painel de operações (`/console/operations`)
2. Selecionar uma operação com status **"Em validação"**
3. Alterar o status para **"Encerrada"**
4. Verificar que o novo motivo **"Operação encerrada devido à retenção provisória de crédito recente"** aparece na lista de motivos do modal
5. Selecionar o novo motivo e confirmar o encerramento
6. Verificar que:
   - O status da operação foi alterado para **"Encerrada"**
   - O `closure_reason_id` da operação foi atualizado para **12**
   - Uma notificação foi enviada ao cliente informando o encerramento com o motivo específico
   - A notificação contém a descrição **"Operação encerrada devido à retenção provisória de crédito recente"

**API**

Verificar que a API `/core/v1/operations/closure-reasons` retorna o novo motivo na listagem.

**Teste via Tinker:**
``php
$operation = App\Domain\Operation::factory()->closed()->create([
    'closure_reason_id' => App\Domain\OperationClosureReason::CREDIT_TEMPORARY_HOLD,
]);

App\Support\Notifications::send(
    new App\Notifications\Operation\OperationClosedNotification($operation)
);
``

## É possível reverter este PR se apresentar erros graves em ambiente de produção?

Sim, removendo o registro adicionado pelo seeder.

## Quando este PR deve ser publicado?

Assim que possível.

## Existem modificações de estrutura de banco de dados que devem ser informados a outros times com o intuito de evitar que processos que dependam dessas informações falhem?

Não.

## Existe manipulação de dados pessoais ou sensíveis neste PR?

Não.

---

Recomendações para pull requests, deploys e entregas podem ser acessadas [clicando aqui](https://menv.io/vwdamlK).
<-- END EXAMPLE 2 -->
```
