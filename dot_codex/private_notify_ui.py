"""Visual local setup. Uses only Python's standard library on macOS."""
import curses
import getpass
import importlib.util
import json
from pathlib import Path
import sys

BASE = Path(__file__).resolve().parent

def load(name, filename):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def next_selection(key, selected, count):
    if key in (curses.KEY_UP, "k"):
        return (selected - 1) % count
    if key in (curses.KEY_DOWN, "j"):
        return (selected + 1) % count
    return selected


class UI:
    def __init__(self, screen):
        self.screen = screen
        screen.keypad(True)
        curses.noecho()
        try:
            curses.curs_set(0)
        except curses.error:
            pass

    def draw(self, title, lines, selected=None):
        self.screen.erase()
        height, width = self.screen.getmaxyx()
        content = [title, ""] + lines + ["", "↑/↓ selecionar • Enter confirmar • Esc voltar • q sair"]
        for row, line in enumerate(content):
            if row >= height - 1:
                break
            attr = curses.A_REVERSE if selected is not None and row == selected + 2 else 0
            try:
                self.screen.addnstr(row, 2, line, max(0, width - 4), attr)
            except curses.error:
                pass
        self.screen.refresh()

    def menu(self, title, choices):
        selected = 0
        while True:
            self.draw(title, choices, selected)
            key = self.screen.get_wch()
            if key in ("q", "Q", "\x1b", "\x03"):
                return None
            if key in ("\n", "\r", curses.KEY_ENTER):
                return selected
            selected = next_selection(key, selected, len(choices))

    def notice(self, title, lines):
        self.draw(title, lines + ["", "Pressione qualquer tecla para voltar."])
        self.screen.get_wch()

    def secret(self, prompt):
        value = []
        while True:
            # Show no characters, even masked lengths; never retain input in logs.
            self.draw("Credenciais — entrada oculta", [prompt, "Digite o valor e pressione Enter. Esc cancela."])
            key = self.screen.get_wch()
            if key in ("\x1b", "\x03"):
                raise KeyboardInterrupt
            if key in ("\n", "\r", curses.KEY_ENTER):
                return "".join(value)
            if key in (curses.KEY_BACKSPACE, "\x7f", "\b"):
                if value:
                    value.pop()
            elif isinstance(key, str) and key.isascii() and key.isalnum() and len(value) < 31:
                value.append(key)


def run(screen):
    ui = UI(screen)
    notify = load("pushover_notify", "notify.py")
    setup = load("pushover_setup", "notify-setup.py")
    while True:
        options = notify.settings()
        state = "ativo" if options["include_response_summary"] else "desativado"
        choice = ui.menu("Pushover • Codex • macOS | Trecho: " + state, [
            "Cadastrar ou atualizar tokens no Chaves",
            "Configurar trecho da resposta (até 240 caracteres)",
            "Consultar tela e credenciais",
            "Testar notificação respeitando a tela",
            "Testar API agora (ignora a tela)",
            "Sair",
        ])
        if choice is None or choice == 5:
            return
        try:
            if choice == 0:
                # The existing secure storage routine gets its input from our hidden fields.
                previous = getpass.getpass
                try:
                    getpass.getpass = ui.secret
                    notify.configure_credentials()
                finally:
                    getpass.getpass = previous
                ui.notice("Credenciais", ["Credenciais salvas e leitura sem diálogo verificada."])
            elif choice == 1:
                answer = ui.menu("O trecho pode conter informações sensíveis.", [
                    "Não enviar conteúdo da resposta (recomendado no trabalho)",
                    "Enviar até 240 caracteres ao meu Pushover",
                ])
                if answer is not None:
                    value = notify.settings()
                    value["include_response_summary"] = answer == 1
                    setup.write_atomic(BASE / "notify-settings.json", json.dumps(value, indent=2) + "\n")
            elif choice == 2:
                ui.draw("Consultando...", ["Nenhum token será exibido."])
                state = notify.screen_state()
                labels = {"on": "ligada", "off": "apagada", "unknown": "não confirmado"}
                try:
                    notify.credentials()
                    credentials = "disponíveis"
                except Exception:
                    credentials = "indisponíveis"
                ui.notice("Estado atual", ["Tela: " + labels[state], "Credenciais: " + credentials])
            elif choice == 3:
                ui.draw("Testando...", ["O envio só ocorre com a tela apagada."])
                result = notify.handle({"type": "agent-turn-complete", "cwd": str(BASE),
                                        "last-assistant-message": "Resposta sintética de teste."})
                notify.audit(result)
                labels = {"sent": "Pushover aceitou a notificação.",
                          "skipped_display_on": "Envio bloqueado: tela ligada.",
                          "skipped_display_unknown": "Envio bloqueado: tela não confirmada.",
                          "skipped_display_changed": "Envio bloqueado: tela mudou de estado."}
                ui.notice("Teste", [labels.get(result, "Envio não confirmado.")])
            elif choice == 4:
                answer = ui.menu("Enviar teste mesmo com a tela ligada?", ["Cancelar", "Enviar mensagem sintética agora"])
                if answer == 1:
                    ui.draw("Enviando...", ["Nenhuma resposta real será enviada."])
                    notify.push("[Teste explícito] Configurador visual Codex/Pushover. Nenhuma resposta real foi enviada.", notify.credentials())
                    notify.audit("test_api_sent")
                    ui.notice("Teste da API", ["Pushover aceitou a notificação de teste."])
        except KeyboardInterrupt:
            ui.notice("Cancelado", ["Operação cancelada."])
        except Exception:
            # Do not display exception text: it could contain credentials or event content.
            ui.notice("Operação não confirmada", ["Falha segura. Nenhum detalhe sensível foi exibido."])


def main():
    if sys.platform != "darwin" or not sys.stdin.isatty():
        raise RuntimeError("Abra pushover-config em um terminal do macOS.")
    try:
        curses.wrapper(run)
    except KeyboardInterrupt:
        pass
