---
name: flow-video
description: Grava em vídeo (.mp4) um fluxo de uma aplicação web com o agent-browser, do ponto de partida até o resultado, e grava no vídeo legendas que dão o contexto que a tela não mostra (cenário, regra aplicada, resultado no banco). Serve como evidência para Jira, PR, QA ou documentação. Use quando o usuário pedir "grava um vídeo do fluxo", "vídeo com legenda", "gera um vídeo para o Jira/PR", "mostra isso em vídeo", "evidência em vídeo". Não use para um print simples ou para explorar uma tela sem gravar.
---

# Flow video

Gera um vídeo curto de um fluxo navegado no browser, com legendas que explicam o
que acontece por trás da tela. Depende da skill `agent-browser` (carregue o guia
com `agent-browser skills get core` antes de usar) e do `ffmpeg` com
`drawtext` (`ffmpeg -filters | grep drawtext`).

Scripts em `scripts/` (nesta pasta):

- `rec-lib.sh`: funções para gravar (`wref`, `glide`, `tap`, `sscroll`, `key`,
  `mark`, `hold`, `now`).
- `burn-captions.py`: grava no vídeo bruto as legendas e os selos de tecla.
- `contact-grid.py`: gera uma imagem com um quadro por legenda, para conferir.

Só rode contra ambiente local ou de staging, nunca contra produção.

## 1. Roteiro antes de gravar

Combine com o usuário, numa mensagem só:

- **ponto de partida**: a home ou o menu de onde a navegação começa (não abra a
  tela final direto pela URL, a não ser que o usuário peça);
- **passos**: o que clicar e preencher, na ordem;
- **legendas**: uma por passo, em `FV_DIR/legendas.json`, no formato
  `{"1": ["legenda 1", "legenda 2"], "2": [...]}` (a chave é o id do fluxo).

As legendas dão contexto que a tela não mostra: o cenário montado, a regra que o
sistema aplica, o que mudou no banco e por que isso importa. Não descreva o
clique, que já aparece no vídeo. Cada vídeo deve fazer sentido sozinho, então a
primeira legenda traz o cenário completo. Passe o texto pelo `humanizer` e mostre
ao usuário antes de gravar.

## 2. Preparação

- Crie a pasta de trabalho no scratchpad (`FV_DIR`), fora do repositório.
- Use uma sessão própria do agent-browser (`FV_SESSION`); a padrão é
  compartilhada com outros agentes.
- Faça login sem mostrar a senha: leia de onde ela estiver (seeder, cofre) para
  uma variável e passe com `agent-browser fill @eN "$PW"`; depois `unset PW`.
- Tenha um script que leva os dados ao estado inicial do cenário e rode antes de
  **cada** tentativa, inclusive depois de uma gravação que falhou.
- Se o fluxo depende de um serviço externo que não existe no ambiente local,
  suba um mock local e aponte o `.env` para ele só durante a gravação. Faça
  backup do `.env` antes e restaure no fim (veja a seção 6).

## 3. Gravação

```bash
export FV_DIR=<scratchpad>/flow-video FV_SESSION=<nome> FV_FLOW=1
source <esta skill>/scripts/rec-lib.sh
agent-browser set viewport 1280 800
agent-browser open <ponto de partida>; agent-browser wait --load networkidle
R=$(wref 'textbox "pesquisar..."')            # ache o primeiro elemento antes de gravar
agent-browser record start "$FV_DIR/fluxo-1-bruto.mp4" --cursor; T0=$(now)
mark 1 1                                       # legenda 1 começa
tap $R; agent-browser type @$R "..."           # cursor desliza, anel no clique
key 1 Enter                                    # aperta Enter e mostra o selo da tecla
hold 1 1                                       # espera o tempo de leitura da legenda 1
mark 1 2
R=$(wref 'link "Conta"'); tap $R
R=$(wref 'button "Salvar"' all); sscroll $R; tap $R   # rola com animação até o botão
# ... um mark/hold por legenda ...
agent-browser wait --text "<mensagem de sucesso>" --timeout 20000
mark 1 N; hold 1 N; mark 1 fim
agent-browser record stop
```

- Use `wref` antes de cada clique. Ele espera o elemento aparecer; sem isso, o
  snapshot pode ser tirado antes de a tela renderizar e o passo falha.
- Clique com `tap` em vez de `click`. Ele leva o cursor até o elemento numa
  curva suave (`glide`) e desenha um anel laranja que se expande no ponto do
  clique; a onda do `--cursor` sozinha quase não aparece no vídeo. Com `hover`,
  o cursor salta de um ponto a outro.
- Role com `sscroll` em vez de `scrollintoview`, que salta direto. O `sscroll`
  anima a rolagem até o elemento ficar no meio da tela e não faz nada se ele
  já estiver visível. Rode antes do `tap`, porque a posição usada é a da área
  visível.
- Aperte teclas com `key FLUXO TECLA`. Além de apertar, ele registra o horário,
  e o `burn-captions.py` mostra um selo "Tecla: Enter ⏎" no canto superior
  direito por 1,2 s.
- No caminho, o cursor pode passar sobre menus e ativar o realce deles. Se
  incomodar, faça o caminho em duas partes, com um `mouse move` intermediário.
- Espere a mensagem final (`wait --text`) antes de parar. Se parar logo depois
  do clique, o vídeo termina antes de a página recarregar.
- O tempo de cada legenda sai do tamanho do texto: cerca de 22 caracteres por
  segundo, entre 3 e 8,5 s (`FV_CPS`, `FV_MIN`, `FV_MAX`). Quem precisar de mais
  tempo pausa o vídeo.
- Depois de parar, confira `marcas-<id>.txt`, a duração do vídeo
  (`ffmpeg -i <video> 2>&1 | grep Duration`) e o estado do banco.

## 4. Legendas

```bash
python3 <skill>/scripts/burn-captions.py --dir "$FV_DIR" --flow 1 \
  --raw "$FV_DIR/fluxo-1-bruto.mp4" --out <destino>/1-<nome>.mp4
```

Estilo fixo: texto branco em DejaVu Sans, caixa única preta a 60% de
opacidade, centralizada embaixo, com linhas de tamanho parecido. Quando algum
clique feito com `tap` durante uma legenda cai nos 220 px de baixo da tela (um
botão no fim do formulário, por exemplo), essa legenda vai para o topo para não
esconder o clique. Para isso, defina `FV_FLOW` com o id do fluxo antes de
gravar; o `tap` registra os cliques em `cliques-<id>.txt`. Para mudar
texto ou estilo, rode de novo a partir do vídeo bruto; não precisa regravar.

## 5. Conferência

```bash
python3 <skill>/scripts/contact-grid.py --video <final>.mp4 \
  --marks "$FV_DIR/marcas-1.txt" --out "$FV_DIR/grade-1.png"
```

Abra a imagem e confira: cada legenda no passo certo, a caixa sem cobrir nada
importante e o último quadro mostrando o resultado. Só diga que o vídeo está
pronto depois disso.

## 6. Entrega e limpeza

- Antes de commitar `.mp4`, rode `git check-attr text binary <arquivo>`. Se o
  `.gitattributes` trata o arquivo como texto (por exemplo, `*.* text eol=lf`),
  o Git corrompe o vídeo no commit. Crie um `.gitattributes` na pasta com
  `*.mp4 binary` e confira depois: `git hash-object --no-filters <arquivo>` tem
  que ser igual a `git rev-parse HEAD:<arquivo>`.
- Restaure o `.env` do backup, pare o mock e apague os dados de teste.
- Feche o browser: `agent-browser close`.
- Diga ao usuário onde estão os vídeos, a duração e o tamanho de cada um.

## Armadilhas

- **zsh**: `"$i:layout"` vira modificador de variável (`:l`) e quebra o
  comando. Use `"${i}:layout"`, ou monte comandos de ffmpeg em Python.
- **pkill dentro de `sh -c`**: `docker exec <c> sh -c 'pkill -f "php -S ..."; rm ...'`
  mata o próprio `sh` antes do `rm`. Rode o `pkill` e o `rm` em comandos
  separados, com o padrão ancorado (`pkill -f "^php -S ..."`).
- **Comando cancelado pelo usuário**: pode ter rodado mesmo assim. Confira o
  estado (banco, arquivos, gravação em andamento) antes de tentar de novo.
- **Legenda com `subtitles`/libass**: o estilo de caixa (`BorderStyle=3`) faz uma
  caixa por linha, que se sobrepõe e escurece entre as linhas; o `BorderStyle=4`
  não tem margem sem o contorno das letras. Por isso o script usa `drawtext`.
- **ffprobe** pode não estar instalado; use `ffmpeg -i <arquivo>` e leia o stderr.

## Melhor Envio

- **Ambiente**: `https://melhorenvio.test`, com o PHP no container
  `melhorenvio-php-1` (`docker exec melhorenvio-php-1 php artisan tinker <arquivo>`).
- **Login**: conta `tecnologia@melhorenvio.com`, com a senha em
  `database/seeders/data/users.json`. Leia com Python para uma variável; nunca
  mostre a senha.
- **Ponto de partida**: a home da diretoria, `https://melhorenvio.test/direction`.
  O campo "pesquisar..." do topo leva direto ao cliente quando recebe o e-mail.
- **Cenário**: clientes do seeder, como `fake@melhorenvio.com` e
  `contato@melhorenvio.com`. Monte e desfaça o cenário com scripts PHP copiados
  para o container (`docker cp`) e rodados pelo `tinker`.
- **Migrations**: se uma tela der erro de tabela inexistente, pergunte antes de
  rodar `php artisan migrate` no banco local.
- **Serviços externos** (por exemplo, o invoice-emitter): suba um mock com
  `docker exec -d melhorenvio-php-1 php -S 127.0.0.1:8099 /tmp/<mock>/router.php`
  e acrescente as variáveis no fim do `.env`, com backup. Implemente também as
  rotas que as telas do caminho chamam (listagens, totais), senão a tela quebra
  antes de chegar ao fluxo.
- **`.gitattributes`**: a raiz tem `*.* text eol=lf` e não lista `*.mp4` como
  binário. Use um `.gitattributes` na pasta dos vídeos.
