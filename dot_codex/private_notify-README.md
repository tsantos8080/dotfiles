# Codex → Pushover no macOS

O `notify` em `config.toml` chama `/usr/bin/python3 ~/.codex/notify.py` com o evento JSON como último argumento. Reinicie o Codex CLI para garantir que a nova configuração seja carregada. As opções anteriores foram preservadas, com backup privado em `~/.local/state/codex-notify/backups/`.

## Tela e privacidade

O detector usa CoreGraphics (`CGGetOnlineDisplayList` e `CGDisplayIsAsleep`), sem consultar o bloqueio da sessão. Só envia se todos os displays online estiverem em repouso. Falhas, ausência de displays ou mudança de estado impedem o envio. A condição é consultada novamente antes do POST; há uma pequena janela inevitável entre essa consulta e o envio. Isso detecta o estado de energia informado pelo macOS, não mede fisicamente a luz de um monitor externo desligado pelo botão.

O teste real nesta máquina confirmou bloqueio do envio com tela ligada e envio aceito com tela apagada. `IODisplayWrangler` não expôs um estado de energia utilizável nesta versão do macOS. O comando `pmset displaysleepnow` aguardou o despertar no primeiro teste; use-o em segundo plano nos testes manuais.

Por autorização do usuário, `notify-settings.json` habilita um trecho de até 240 caracteres da última resposta, com espaços condensados. Não é um resumo gerado por IA nem uma filtragem de segredos. Para não enviar respostas, altere `include_response_summary` para `false`. O nome do projeto usa somente o último componente de `cwd`, controlado por `include_project_name`. As mensagens de entrada nunca são enviadas. O evento atual não informa sucesso/erro; o script não tenta inferir isso do texto.

## Configurador interativo

```sh
/usr/bin/python3 ~/.codex/notify-setup.py --interactive
```

O menu permite cadastrar tokens com entrada oculta, escolher se envia um trecho da resposta, consultar tela/credenciais e testar o envio. O teste que ignora a tela pede confirmação explícita. A instalação automática pelo chezmoi continua sem perguntas.

## Credenciais

Execute no terminal, sem colocar valores no comando:

```sh
/usr/bin/python3 ~/.codex/notify.py --configure-credentials
/usr/bin/python3 ~/.codex/notify.py --credentials-status
```

Primeiro informe `PUSHOVER_APP_TOKEN`, depois `PUSHOVER_USER_KEY`, em entradas ocultas. São armazenados no Chaves de login, nos serviços `codex.pushover.PUSHOVER_APP_TOKEN` e `codex.pushover.PUSHOVER_USER_KEY`, conta `codex-notify`. A leitura usa a API nativa Security e proíbe diálogos. Se o Chaves estiver bloqueado ou negar acesso, a notificação é descartada. O interpretador fixo funciona sem depender do PATH do terminal/IDE. Ambos os nomes também podem ser fornecidos como variáveis de ambiente; se apenas um estiver presente, falha sem misturar fontes.

## Testes

```sh
/usr/bin/python3 ~/.codex/notify.py --screen-status
/usr/bin/python3 ~/.codex/notify.py --test-api
/usr/bin/python3 ~/.codex/notify.py --test-notification
```

`--test-api` é um teste explícito que ignora a tela e envia somente texto sintético. `--test-notification` respeita a tela. Nenhum teste precisa de resposta real.

Teste manual de tela apagada, sem mover o mouse até terminar:

```sh
(sleep 5; /usr/bin/python3 ~/.codex/notify.py --test-notification) &
pmset displaysleepnow &
```

Acorde a tela depois de receber a notificação. Para distinguir bloqueio de repouso: mantenha a tela acordada com `caffeinate -d -t 30`, agende o teste com o comando acima e bloqueie a sessão com Control+Command+Q; enquanto a tela de bloqueio continuar iluminada, não deve haver envio.

Para validar o evento nativo de ponta a ponta: reinicie o Codex CLI, peça uma resposta inofensiva, apague a tela antes de ela terminar e confira a notificação. Os testes automatizados usam o formato do código oficial da versão instalada (0.160.1); não iniciam uma nova interação de IA. Logs locais contêm somente horário e códigos de resultado em `~/.local/state/codex-notify/events.jsonl`. A confirmação HTTP significa aceitação pelo Pushover, não confirmação de entrega física no Android.

O hook nativo retorna zero mesmo em falhas; o subprocesso tem limite total de 20 segundos e a requisição HTTPS tem timeout de 8 segundos. Não há dependências externas ao Python/macOS.

## Chezmoi e outros sistemas

O script, o instalador e este documento são gerenciados pelo chezmoi, exclusivamente no macOS por enquanto. O instalador adiciona o hook sem substituir configurações existentes. Se encontrar outro notify, preserva-o e avisa. `config.toml` continua local, não é copiado entre máquinas.

Tokens, Chaves, backups, logs e `notify-settings.json` não são versionados. Em cada máquina, cadastre as credenciais com a entrada oculta. A primeira instalação cria `include_response_summary: false`, apropriado para máquinas de trabalho. Neste Mac a autorização anterior de trecho curto foi preservada. Para habilitar ou desabilitar localmente:

```sh
/usr/bin/python3 ~/.codex/notify-setup.py --summary on
/usr/bin/python3 ~/.codex/notify-setup.py --summary off
```

Não há dependência do Bitwarden pessoal. Windows/WSL e Claude Code no Ubuntu/GNOME ainda precisam de implementação e validação próprias; o chezmoi não aplica estes arquivos macOS nesses sistemas.

## Desfazer

Remova somente a linha `notify = [...]` adicionada no topo de `config.toml` e reinicie o Codex. Mantenha as demais configurações. Os arquivos `notify.py`, `notify-settings.json` e este documento podem então ser removidos. As duas entradas de credenciais podem ser excluídas pelo aplicativo Acesso às Chaves, buscando os serviços acima.

## Referências

- https://learn.chatgpt.com/docs/config-file/config-advanced
- https://github.com/openai/codex/blob/rust-v0.160.1/codex-rs/hooks/src/legacy_notify.rs
- https://developer.apple.com/documentation/coregraphics/cgdisplayisasleep(_:)
- https://pushover.net/api
