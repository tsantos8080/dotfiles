#!/usr/bin/python3
"""Install the macOS hook without replacing local Codex settings or secrets."""
import argparse
import datetime
import json
import os
from pathlib import Path
import re
import sys
import subprocess
import tempfile

BASE = Path.home() / ".codex"

def write_atomic(path, content, mode=0o600):
    fd, temporary = tempfile.mkstemp(dir=path.parent)
    try:
        os.fchmod(fd, mode)
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(content)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)

def install(base=BASE):
    base.mkdir(mode=0o700, exist_ok=True)
    options = base / "notify-settings.json"
    if not options.exists():
        write_atomic(options, json.dumps({"include_response_summary": False,
                                         "include_project_name": True}, indent=2) + "\n")
    config = base / "config.toml"
    raw = config.read_text() if config.exists() else ""
    command = ["/usr/bin/python3", str(base / "notify.py")]
    line = "notify = " + json.dumps(command)
    # Be conservative: preserve any existing notify, including unfamiliar syntax.
    if re.search(r'(?m)^\s*(?:notify|"notify"|\'notify\')\s*=', raw):
        if line not in raw.splitlines():
            print("notify existente preservado; integração automática não aplicada.")
        return
    if raw:
        backups = Path.home() / ".local/state/codex-notify/backups"
        backups.mkdir(mode=0o700, parents=True, exist_ok=True)
        name = "config-" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f") + ".toml"
        write_atomic(backups / name, raw)
    if config.exists() and config.read_text() != raw:
        raise RuntimeError("Configuração mudou durante instalação; tente novamente.")
    write_atomic(config, line + "\n\n" + raw,
                 config.stat().st_mode & 0o777 if config.exists() else 0o600)

def set_summary(enabled, base=BASE):
    path = base / "notify-settings.json"
    value = json.loads(path.read_text())
    value["include_response_summary"] = enabled
    write_atomic(path, json.dumps(value, indent=2) + "\n")
    print("Trecho da resposta " + ("habilitado." if enabled else "desativado."))


def interactive(base=BASE):
    if not sys.stdin.isatty():
        raise RuntimeError("Abra o configurador em um terminal interativo.")
    print("Codex → Pushover — configuração local do macOS")
    print("Tokens ficam no Chaves; trechos podem conter informações sensíveis.")
    while True:
        value = json.loads((base / "notify-settings.json").read_text())
        state = "habilitado" if value["include_response_summary"] else "desativado"
        print("\nTrecho da resposta: " + state)
        print("1. Cadastrar ou atualizar tokens (entrada oculta)")
        print("2. Configurar trecho curto da resposta")
        print("3. Verificar tela e disponibilidade das credenciais")
        print("4. Testar notificação respeitando a tela")
        print("5. Testar API agora, mesmo com a tela ligada")
        print("0. Sair")
        try:
            choice = input("Opção: ").strip()
            if choice == "0":
                print("Reinicie o Codex CLI se acabou de instalar o hook.")
                return
            elif choice == "2":
                answer = input("Enviar até 240 caracteres da resposta ao Pushover? [s/N]: ").strip().lower()
                if answer not in ("", "n", "s"):
                    print("Resposta inválida; preferência preservada.")
                    continue
                set_summary(answer == "s", base)
                continue
            elif choice == "1":
                commands = ["--configure-credentials"]
            elif choice == "3":
                commands = ["--screen-status", "--credentials-status"]
            elif choice == "4":
                commands = ["--test-notification"]
            elif choice == "5":
                answer = input("Enviar uma notificação sintética agora? [s/N]: ").strip().lower()
                if answer != "s":
                    continue
                commands = ["--test-api"]
            else:
                print("Opção inválida.")
                continue
            for command in commands:
                # Credentials are entered in the child terminal, never command arguments.
                result = subprocess.run(["/usr/bin/python3", str(base / "notify.py"), command],
                                        timeout=120)
                if result.returncode:
                    print("Operação não confirmada; confira o resultado acima.")
        except (EOFError, KeyboardInterrupt):
            print("\nConfigurador encerrado.")
            return
        except subprocess.TimeoutExpired:
            print("Operação excedeu o limite de tempo e foi interrompida.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--summary", choices=("on", "off"))
    group.add_argument("--interactive", action="store_true")
    args = parser.parse_args()
    if sys.platform != "darwin":
        parser.error("Esta implementação é específica do macOS.")
    install()
    if args.summary:
        set_summary(args.summary == "on")
    elif args.interactive:
        interactive()


if __name__ == "__main__":
    main()
