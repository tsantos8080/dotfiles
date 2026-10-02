---
name: simplify
description: Simplifica código que já funciona, sem mudar o comportamento, para ficar mais fácil de ler e de alterar - menos aninhamento, nomes melhores, duplicação removida, abstrações inúteis desfeitas. Por padrão mexe só no código alterado recentemente. Use quando o usuário pedir "simplifica", "deixa mais legível", "limpa esse código", "simplify", ou depois que uma feature passa nos testes e o código ficou pesado. Não use em código que ainda não está entendido ou que vai ser reescrito.
---

# Simplificar sem mudar o comportamento

O objetivo é código que uma pessoa nova no time entende mais rápido, não código
com menos linhas. Se uma mudança não deixa isso claramente melhor, não faça.

## Antes de mexer

1. **Defina o alcance.** Sem pedido explícito, só o código alterado
   recentemente: `git diff` do trabalho atual, ou `git diff <base>...HEAD` do
   branch. Nada de refactor "aproveitando a viagem" em arquivo vizinho.
2. **Entenda o código.** Para cada trecho: o que ele faz, quem chama
   (`rg -n "nomeDoMetodo"`), o que ele chama, quais são os casos de borda e os
   caminhos de erro, e por que pode ter sido escrito assim. Se não souber
   responder, leia mais antes de mudar.
3. **Garanta uma rede.** Veja quais testes cobrem o trecho. Se nenhum cobre um
   comportamento que você vai tocar, escreva um teste que fixe o comportamento
   atual antes de simplificar, ou diga ao usuário que a mudança fica sem
   cobertura.
4. **Siga o estilo do projeto.** Leia o `AGENTS.md` e olhe como o código ao
   redor resolve o mesmo tipo de problema. Simplificar é deixar mais parecido
   com o resto do projeto, não com o seu gosto.

## O que procurar

- `if` aninhado que vira retorno antecipado (*guard clause*);
- ternário dentro de ternário, ou expressão que precisa ser lida duas vezes;
- método longo fazendo várias coisas, que pode virar métodos com nomes claros;
- parâmetro booleano que muda o que o método faz (`gerar($dados, true)`), que
  pede dois métodos ou um enum;
- nomes genéricos (`$data`, `$aux`, `$result2`, `process()`);
- a mesma condição ou a mesma lógica repetida em vários lugares;
- código morto: variável sem uso, `else` depois de `return`, método sem
  chamador (confirme com `rg`);
- classe, interface ou wrapper que só repassa a chamada sem acrescentar nada;
- em Laravel: laço montando array onde uma Collection (`map`, `filter`,
  `keyBy`, `groupBy`) fica mais clara; consulta repetida que pode virar um
  scope local; `if` sobre string que deveria ser um enum; regra de validação
  espalhada que cabe num FormRequest.

## O que não fazer

- mudar saída, exceções lançadas, efeitos colaterais, ordem de execução,
  consultas ao banco ou eventos disparados;
- trocar código claro por código curto e esperto;
- juntar lógicas diferentes num método maior só porque estão perto;
- remover uma abstração que existe para testes ou para um ponto de extensão
  real;
- tocar em código crítico de desempenho se a versão simples for mais lenta;
- misturar simplificação com feature ou correção no mesmo passo.

Na dúvida se a mudança preserva o comportamento, não faça.

## Como aplicar

Uma simplificação por vez:

1. faça a mudança;
2. rode os testes que cobrem o trecho e a análise estática do projeto
   (phpstan, php-cs-fixer em `--dry-run`, ou o que o projeto usar);
3. se algo quebrar, desfaça e reavalie em vez de ajustar o teste.

## No fim

Mostre um resumo curto: o que mudou e por quê, em uma linha cada, e quais
checagens rodaram. Confira que o diff é fácil de revisar e que nenhum
comportamento mudou. Se nada valia a pena simplificar, diga isso.
