---
name: verification-plan
description: Antes de implementar uma mudança não trivial, monta o plano de como provar que ela funciona, risco por risco, e no fim executa o plano e diz o que foi comprovado. Use antes de features, correções, refactors, migrations de dados ou integrações em que um teste unitário passando não basta como prova, ou quando o usuário pedir "plano de verificação", "como vou saber que funciona", "verification plan". Não use para mudanças triviais.
---

# Plano de verificação

Teste verde prova que o teste passou, não que a mudança está certa. Esta skill
faz o trabalho inverso: parte do que precisa ser verdade depois da mudança e
escolhe a evidência que confirmaria ou derrubaria cada ponto.

Use na proporção do risco. Renomear uma variável não precisa de plano; mudar
uma regra de cálculo, uma integração ou dados em produção precisa.

## 1. Escreva o que precisa ser verdade

Liste afirmações curtas e checáveis, no formato "dado X, quando Y, então Z".
Inclua sempre o que **não pode mudar**: outros fluxos, outros clientes, outras
integrações que passam pelo mesmo código.

Exemplo:

- Dado um envio com destino em SP, quando o prazo cai num feriado estadual de
  SP, então o prazo exibido na cotação avança um dia útil.
- O prazo das outras transportadoras continua igual.

## 2. Liste como cada afirmação pode estar errada com os testes verdes

Para cada afirmação, pergunte o que faria ela ser falsa em produção mesmo com o
teste passando. Fontes comuns em Laravel:

- o teste chama a função, mas o fluxo real usa outro caminho (cache, um job,
  um listener, um endpoint diferente);
- cache de config, de rota ou de dados guardando o valor antigo;
- fila `sync` nos testes e `redis` em produção, ou job antigo ainda na fila;
- fuso horário, horário de verão, "hoje" fixo no teste;
- transação que o teste desfaz, mas em produção fica pela metade;
- API externa que se comporta diferente do fake (ou já faz o que você está
  implementando);
- dados legados que não existem na factory;
- concorrência: duas requisições ou dois workers ao mesmo tempo.

Fique com os riscos que realmente importam para esta mudança.

## 3. Escolha a evidência mais barata que derruba cada risco

Do mais barato para o mais caro:

1. ler o código e o histórico (`git log -p`, chamadores com `rg`);
2. teste unitário;
3. teste de feature passando pela rota, pelo job ou pelo comando real;
4. teste com banco e fila de verdade no ambiente local;
5. execução manual local (`php artisan tinker`, um comando artisan, a tela);
6. ambiente de homologação.

Para cada risco, escolha o nível mais baixo que **de fato exercita** aquele
risco. Um teste unitário não derruba um risco de cache; um teste de feature
derruba.

## 4. Crie o que falta para conseguir observar

Se não existe como controlar ou ver o comportamento, crie o mínimo necessário.
No Laravel, comece pelo que o framework já oferece:

- `Carbon::setTestNow()` para fixar a data;
- `Http::fake()` com `Http::preventStrayRequests()` para integrações;
- `Queue::fake()`, `Bus::fake()`, `Event::fake()`, `Mail::fake()`,
  `Notification::fake()`, `Storage::fake()`;
- `RefreshDatabase` ou `DatabaseTransactions`, conforme o projeto.

Decida se o que você criou é temporário (log de depuração, script de tinker)
ou fica no código (um teste, um método de fábrica). Apague o temporário quando
terminar. Pergunte antes de adicionar dependência ou mudar estrutura só para
conseguir testar.

Se a dúvida for sobre como uma dependência se comporta, leia o código dela em
`vendor/` e a documentação da versão instalada (veja o `composer.lock`) antes
de decidir.

## 5. Mostre o plano antes de implementar

Apresente uma tabela e espere o usuário concordar ou ajustar:

| Afirmação | Risco | Evidência | Status |
|---|---|---|---|
| prazo avança em feriado de SP | cotação lê prazo do cache | teste de feature no endpoint de cotação | pendente |

## 6. Depois de implementar, execute e preencha o status

Rode cada evidência e atualize a tabela com um destes:

- **comprovado**: a evidência rodou e confirma;
- **parcial**: confirma só parte (diga qual parte ficou de fora);
- **refutado**: a evidência mostrou que está errado;
- **não verificado**: não deu para rodar (diga por quê).

"Não rodou" nunca vira "passou". No fim, diga em uma ou duas frases o que está
provado e o que continua sendo suposição.
