#!/usr/bin/python3
"""Codex notify -> Pushover. No reply content leaves the Mac by default."""
import argparse
import ctypes
import datetime
import getpass
import json
import os
from pathlib import Path
import re
import shlex
import ssl
import stat
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

BASE = Path(__file__).resolve().parent
SETTINGS = BASE / "notify-settings.json"
STATE = Path.home() / ".local/state/codex-notify"
TITLE = "Codex — Tarefa finalizada"
NAMES = ("PUSHOVER_APP_TOKEN", "PUSHOVER_USER_KEY")
ACCOUNT = "codex-notify"


def private_read(path):
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o077:
        raise ValueError("unsafe_file")
    return path.read_text(encoding="utf-8")


def settings():
    value = json.loads(private_read(SETTINGS))
    if not isinstance(value, dict):
        raise ValueError("invalid_settings")
    for key in ("include_response_summary", "include_project_name"):
        if type(value.get(key)) is not bool:
            raise ValueError("invalid_settings")
    return value


def audit(result):
    """Only fixed reason codes and timestamps; never event contents or secrets."""
    try:
        STATE.mkdir(parents=True, mode=0o700, exist_ok=True)
        info = STATE.lstat()
        if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o077:
            return
        flags = os.O_WRONLY | os.O_APPEND | os.O_CREAT | os.O_NOFOLLOW
        fd = os.open(str(STATE / "events.jsonl"), flags, 0o600)
        with os.fdopen(fd, "a", encoding="utf-8") as stream:
            info = os.fstat(stream.fileno())
            if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o077:
                return
            stream.write(json.dumps({"time": datetime.datetime.now().astimezone().isoformat(),
                                     "result": result}) + "\n")
    except Exception:
        pass


def screen_state():
    """Require every online display to sleep; lock status is intentionally unused."""
    try:
        cg = ctypes.CDLL("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics")
        cg.CGGetOnlineDisplayList.argtypes = [ctypes.c_uint32, ctypes.POINTER(ctypes.c_uint32),
                                             ctypes.POINTER(ctypes.c_uint32)]
        cg.CGGetOnlineDisplayList.restype = ctypes.c_int32
        cg.CGDisplayIsAsleep.argtypes = [ctypes.c_uint32]
        cg.CGDisplayIsAsleep.restype = ctypes.c_uint32
        count = ctypes.c_uint32()
        if cg.CGGetOnlineDisplayList(0, None, ctypes.byref(count)) or not 0 < count.value <= 64:
            return "unknown"
        ids = (ctypes.c_uint32 * count.value)()
        actual = ctypes.c_uint32()
        if cg.CGGetOnlineDisplayList(count.value, ids, ctypes.byref(actual)):
            return "unknown"
        if actual.value != count.value:
            return "unknown"
        states = [cg.CGDisplayIsAsleep(identifier) for identifier in ids]
        if any(value not in (0, 1) for value in states):
            return "unknown"
        return "off" if all(states) else "on"
    except Exception:
        return "unknown"


def keychain_value(name):
    """Native Security API with UI explicitly forbidden (safe for a dark screen)."""
    cf = ctypes.CDLL("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation")
    sec = ctypes.CDLL("/System/Library/Frameworks/Security.framework/Security")
    ptr = ctypes.c_void_p
    cf.CFStringCreateWithCString.argtypes = [ptr, ctypes.c_char_p, ctypes.c_uint32]
    cf.CFStringCreateWithCString.restype = ptr
    cf.CFDictionaryCreate.argtypes = [ptr, ctypes.POINTER(ptr), ctypes.POINTER(ptr),
                                      ctypes.c_long, ptr, ptr]
    cf.CFDictionaryCreate.restype = ptr
    cf.CFDataGetLength.argtypes = [ptr]
    cf.CFDataGetLength.restype = ctypes.c_long
    cf.CFDataGetBytePtr.argtypes = [ptr]
    cf.CFDataGetBytePtr.restype = ptr
    cf.CFRelease.argtypes = [ptr]
    cf.CFRelease.restype = None
    sec.SecItemCopyMatching.argtypes = [ptr, ctypes.POINTER(ptr)]
    sec.SecItemCopyMatching.restype = ctypes.c_int32
    constant = lambda key: ptr.in_dll(sec, key).value
    service = cf.CFStringCreateWithCString(None, ("codex.pushover." + name).encode(), 0x08000100)
    account = cf.CFStringCreateWithCString(None, ACCOUNT.encode(), 0x08000100)
    keys = (ptr * 6)(*[constant(key) for key in ("kSecClass", "kSecAttrService", "kSecAttrAccount",
                          "kSecReturnData", "kSecMatchLimit", "kSecUseAuthenticationUI")])
    values = (ptr * 6)(constant("kSecClassGenericPassword"), service, account,
                       ptr.in_dll(cf, "kCFBooleanTrue").value, constant("kSecMatchLimitOne"),
                       constant("kSecUseAuthenticationUIFail"))
    query = None
    result = ptr()
    try:
        query = cf.CFDictionaryCreate(None, keys, values, 6,
                    ctypes.addressof(ctypes.c_byte.in_dll(cf, "kCFTypeDictionaryKeyCallBacks")),
                    ctypes.addressof(ctypes.c_byte.in_dll(cf, "kCFTypeDictionaryValueCallBacks")))
        if not query or sec.SecItemCopyMatching(query, ctypes.byref(result)) != 0 or not result.value:
            return None
        length = cf.CFDataGetLength(result)
        if length != 30:
            return None
        return ctypes.string_at(cf.CFDataGetBytePtr(result), length).decode("ascii")
    finally:
        if result.value:
            cf.CFRelease(result)
        if query:
            cf.CFRelease(query)
        cf.CFRelease(service)
        cf.CFRelease(account)


def credentials():
    if any(name in os.environ for name in NAMES):
        values = [os.environ.get(name, "") for name in NAMES]
    else:
        values = [keychain_value(name) or "" for name in NAMES]
    if not all(re.fullmatch(r"[A-Za-z0-9]{30}", value) for value in values):
        raise ValueError("credentials_unavailable")
    return values


def configure_credentials():
    if not sys.stdin.isatty():
        raise ValueError("terminal_required")
    keychain = Path.home() / "Library/Keychains/login.keychain-db"
    if not keychain.is_file():
        raise ValueError("login_keychain_unavailable")
    values = [getpass.getpass(name + " (entrada oculta): ") for name in NAMES]
    if not all(re.fullmatch(r"[A-Za-z0-9]{30}", value) for value in values):
        raise ValueError("invalid_credentials")
    # Secrets go through stdin of security's own parser, never shell/argv/logs.
    for name, value in zip(NAMES, values):
        args = ["add-generic-password", "-U", "-a", ACCOUNT, "-s", "codex.pushover." + name,
                "-w", value, "-T", sys.executable, "-T", "/usr/bin/security", str(keychain)]
        subprocess.run(["/usr/bin/security", "-i"],
            input=" ".join(shlex.quote(arg) for arg in args) + "\n", text=True,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30, check=True)
    if [keychain_value(name) for name in NAMES] != values:
        raise ValueError("keychain_verification_failed")


def message(event, options):
    parts = []
    cwd = event.get("cwd")
    if options["include_project_name"] and isinstance(cwd, str) and cwd:
        project = Path(cwd).name
        project = "".join(c for c in project if c.isprintable())[:120]
        if project:
            parts.append("Projeto: " + project)
    parts.append("Interação finalizada.")
    reply = event.get("last-assistant-message")
    if options["include_response_summary"] and isinstance(reply, str) and reply.strip():
        excerpt = " ".join(reply.split())[:240]
        parts.append("Resumo (trecho da resposta): " + excerpt)
    elif not options["include_response_summary"]:
        parts.append("Resumo da resposta omitido por privacidade.")
    return "\n".join(parts)[:1024]


def push(text, values):
    body = urllib.parse.urlencode({"token": values[0], "user": values[1],
                                  "title": TITLE, "message": text}).encode("utf-8")
    request = urllib.request.Request("https://api.pushover.net/1/messages.json", data=body,
                    headers={"Content-Type": "application/x-www-form-urlencoded"}, method="POST")
    with urllib.request.urlopen(request, timeout=8, context=ssl.create_default_context()) as response:
        result = json.loads(response.read(16384))
    if result.get("status") != 1:
        raise ValueError("api_rejected")


def handle(event):
    if not isinstance(event, dict) or event.get("type") != "agent-turn-complete":
        return "skipped_event"
    state = screen_state()
    if state != "off":
        return "skipped_display_" + state
    options = settings()
    values = credentials()
    # Recheck after fetching credentials, in case the user has woken the screen.
    if screen_state() != "off":
        return "skipped_display_changed"
    push(message(event, options), values)
    return "sent"


def cli(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("event", nargs="?", help="JSON recebido do notify nativo")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--screen-status", action="store_true")
    group.add_argument("--configure-credentials", action="store_true")
    group.add_argument("--credentials-status", action="store_true")
    group.add_argument("--test-api", action="store_true", help="Teste explícito que ignora a tela")
    group.add_argument("--test-notification", action="store_true", help="Teste que respeita a tela")
    args = parser.parse_args(argv)
    diagnostic = args.event is None
    try:
        if args.screen_status:
            state = screen_state()
            print(json.dumps({"screen": state, "detector": "CGDisplayIsAsleep"}))
            return 0 if state != "unknown" else 2
        if args.configure_credentials:
            configure_credentials()
            print("Credenciais salvas e leitura sem diálogo verificada no Chaves do macOS.")
            return 0
        if args.credentials_status:
            credentials()
            print("As duas credenciais estão disponíveis; valores ocultos.")
            return 0
        if args.test_api:
            push("[Teste explícito] Integração Codex/Pushover validada. Nenhuma resposta real foi enviada.", credentials())
            print("Pushover aceitou a notificação de teste.")
            audit("test_api_sent")
            return 0
        event = {"type": "agent-turn-complete", "cwd": str(BASE),
                 "last-assistant-message": "Resposta sintética de teste."} if args.test_notification else json.loads(args.event or "null")
        result = handle(event)
        audit(result)
        if diagnostic:
            print(result)
        return 0
    except Exception:
        audit("failed_safe")
        if diagnostic:
            print("Falha segura: operação não confirmada. Nenhum detalhe sensível foi registrado.", file=sys.stderr)
            return 2
        return 0


def main(argv):
    # Bound native calls as well as HTTP; a stuck macOS API cannot leave notify hanging.
    if len(argv) == 1 and not argv[0].startswith("--"):
        try:
            subprocess.run([sys.executable, str(Path(__file__).resolve()),
                            "--internal-worker", argv[0]], timeout=20,
                           stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL, check=False)
        except subprocess.TimeoutExpired:
            audit("timed_out_safe")
        except Exception:
            audit("failed_safe")
        return 0
    if argv and argv[0] == "--internal-worker":
        return cli(argv[1:])
    return cli(argv)


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except Exception:
        # Notify must never interrupt Codex, even for unexpected local failures.
        sys.exit(0)
