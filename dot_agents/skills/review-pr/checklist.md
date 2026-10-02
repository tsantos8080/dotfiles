# Checklist de revisão

Use a parte geral em qualquer PR. Use a parte de PHP/Laravel só nos arquivos
`.php` do diff. Regras do próprio projeto (`CLAUDE.md` / `AGENTS.md`) têm
prioridade sobre este checklist.

## Geral

- **Escopo:** o PR entrega o que a tarefa pede, e só isso. Mudança fora do
  escopo vira apontamento, mesmo que seja melhoria.
- **Correção:** casos de borda, caminhos de erro, valores nulos, defaults
  alterados, comportamento antigo que deixou de existir sem querer.
- **Concorrência e repetição:** o que acontece se a mesma requisição, job ou
  comando rodar duas vezes ao mesmo tempo? Operações que deveriam ser
  idempotentes (rodar de novo dá o mesmo resultado) são?
- **Compatibilidade:** formato de resposta da API, dados já gravados, filas com
  jobs antigos, chamadores existentes.
- **Arquitetura:** responsabilidade única (SRP), sem duplicar lógica que já
  existe (DRY), dependências apontando na direção certa, limites entre módulos
  documentados no projeto respeitados. Sem abstração com uma única
  implementação e sem motivo concreto.
- **Nomes:** dizem o que a coisa é ou faz, sem abreviações obscuras.
- **Comentários no código:** explicam *por que* o código foge do esperado, não
  *o que* ele faz. Precisam fazer sentido para quem lê a frio, sem o contexto
  da conversa que gerou a decisão. Estrutura: a intenção + a restrição que força
  a abordagem diferente.
- **Testes:** cobrem o comportamento novo e os caminhos de erro; em correções,
  o teste falha sem a correção. Sem teste redundante: se um teste verifica só
  um subconjunto do que outro já cobre, ele não acrescenta cobertura.

## PHP / Laravel

- **Boas práticas:** SOLID, PSR-12 e as convenções do Laravel.
- **Rotas:** nomes, verbos HTTP e recursos coerentes com o resto da aplicação.
- **Visibilidade:** propriedades e métodos com o modificador mais restrito que
  o uso permite (`private` > `protected` > `public`). `protected` indica que se
  espera herança e precisa de justificativa. Em classes de teste que não servem
  de base, propriedades de setup (`$user`, `$adminUser`) são `private`.
- **Argumentos em várias linhas:** chamada com mais de um argumento tem um
  argumento por linha e vírgula depois do último, para que acrescentar um
  argumento mude só uma linha no diff.

  ```php
  $service->register(
      $user,
      $amount,
  );
  ```

### Testes (PHPUnit)

- **Atributos em vez de anotações de docblock** (as anotações vão deixar de
  funcionar em versões futuras do PHPUnit):
  - `/** @test */` → `#[Test]` (`PHPUnit\Framework\Attributes\Test`)
  - `@dataProvider nome` → `#[DataProvider('nome')]`
  - `@group nome` → `#[Group('nome')]` na classe
  - o mesmo para `@covers`, `@depends`, `@runInSeparateProcess` e outras.
- **Um padrão por classe:** todos os testes com prefixo `test_` ou todos com
  `#[Test]`, nunca os dois na mesma classe.
- **Nome do teste:** descreve o comportamento, sem o prefixo `should_`
  (`returns_forbidden_without_permission`, não
  `should_return_forbidden_without_permission`).
- **Ordem na classe:** testes primeiro, métodos auxiliares privados depois,
  data providers por último.
- **Asserções:** nunca encadeadas direto na requisição. Atribua a `$response`,
  pule uma linha e faça as asserções depois.

  ```php
  $response = $this->postJson(route('transactions.store'), $payload);

  $response->assertForbidden();
  ```

- **URLs:** use `route('nome.da.rota', [...])` em vez de URL escrita à mão.
  Exceção: quando o teste omite de propósito um parâmetro obrigatório da rota,
  porque `route()` lança `UrlGenerationException` antes de a requisição chegar
  ao controller. Nesse caso, URL literal com comentário explicando o motivo:

  ```php
  // URL literal intencional: route() lança UrlGenerationException quando um
  // parâmetro obrigatório é omitido, e este teste existe para omitir {type}.
  $response = $this->getJson('/api/v2/tickets/');
  ```

- **Seeders:** questione se o seeder é necessário para o fluxo testado. Se o
  teste passa sem ele, é ruído. Prefira factories com dados mínimos e
  explícitos, que deixam a intenção visível no próprio teste.
