#!/usr/bin/env python3
"""Resumo compacto das sessões recentes do Claude Code, para a skill reflect.

Só lê ~/.claude/projects. Não grava nada. Mascara o que parece credencial.

Uso:
    claude-sessions.py [--days 30] [--project TRECHO] [--prompt-chars 160]
"""
import argparse
import collections
import json
import re
import time
from datetime import datetime
from pathlib import Path

PROJECTS = Path.home() / ".claude" / "projects"

SECRET_ASSIGN = re.compile(
    r"(?i)(api[_-]?key|token|secret|password|passwd|authorization|bearer)"
    r"([\"'\s:=]+)([^\s\"']{6,})"
)
LONG_OPAQUE = re.compile(r"\b[A-Za-z0-9_\-]{32,}\b")
COMMAND_TAG = re.compile(r"<command-name>\s*(/[^<\s]+)\s*</command-name>")


def mask(text):
    text = SECRET_ASSIGN.sub(lambda m: m.group(1) + m.group(2) + "***", text)
    return LONG_OPAQUE.sub("***", text)


def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def bash_prefix(command):
    """Primeiras palavras relevantes de um comando, sem `cd ... &&` e variáveis."""
    line = command.strip().splitlines()[0] if command.strip() else ""
    line = re.sub(r"^(cd\s+\S+\s*(&&|;)\s*)+", "", line)
    words = [w for w in line.split() if "=" not in w.split("/")[0]]
    if not words:
        return ""
    head = words[0].rsplit("/", 1)[-1]
    if head in {"git", "composer", "docker", "php", "npm", "yarn", "chezmoi", "mise", "gh"} and len(words) > 1:
        return f"{head} {words[1]}"
    return head


def text_blocks(content):
    if isinstance(content, str):
        return [content]
    if isinstance(content, list):
        return [b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text"]
    return []


def summarize(path, prompt_chars):
    s = {
        "id": path.stem[:8], "cwd": None, "branch": None, "start": None, "end": None,
        "prompts": [], "commands": collections.Counter(), "skills": collections.Counter(),
        "tools": collections.Counter(), "bash": collections.Counter(),
    }
    for line in path.open(encoding="utf-8", errors="replace"):
        try:
            d = json.loads(line)
        except json.JSONDecodeError:
            continue
        if d.get("isSidechain"):
            continue
        s["cwd"] = s["cwd"] or d.get("cwd")
        s["branch"] = s["branch"] or d.get("gitBranch")
        ts = parse_ts(d.get("timestamp"))
        if ts:
            s["start"] = min(s["start"], ts) if s["start"] else ts
            s["end"] = max(s["end"], ts) if s["end"] else ts
        message = d.get("message")
        if not isinstance(message, dict):
            continue
        content = message.get("content")
        if d.get("type") == "user" and not d.get("isMeta"):
            for text in text_blocks(content):
                for cmd in COMMAND_TAG.findall(text):
                    s["commands"][cmd] += 1
                text = text.strip()
                if text and not text.startswith("<"):
                    s["prompts"].append(mask(" ".join(text.split()))[:prompt_chars])
        if d.get("type") == "assistant" and isinstance(content, list):
            for block in content:
                if not isinstance(block, dict) or block.get("type") != "tool_use":
                    continue
                name = block.get("name", "?")
                args = block.get("input") or {}
                s["tools"][name] += 1
                if name == "Bash" and isinstance(args.get("command"), str):
                    prefix = bash_prefix(args["command"])
                    if prefix:
                        s["bash"][prefix] += 1
                if name == "Skill" and args.get("skill"):
                    s["skills"][args["skill"]] += 1
    return s


def fmt_counter(counter, limit=8):
    return ", ".join(f"{k} x{v}" for k, v in counter.most_common(limit)) or "-"


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--days", type=int, default=30)
    parser.add_argument("--project", default="")
    parser.add_argument("--prompt-chars", type=int, default=160)
    args = parser.parse_args()

    cutoff = time.time() - args.days * 86400
    files = sorted(
        (p for p in PROJECTS.glob("*/*.jsonl") if p.stat().st_mtime >= cutoff and args.project in str(p.parent)),
        key=lambda p: p.stat().st_mtime,
    )
    if not files:
        print(f"Nenhuma sessão do Claude Code nos últimos {args.days} dias em {PROJECTS}.")
        return

    totals = {k: collections.Counter() for k in ("bash", "skills", "commands", "tools")}
    in_sessions = {k: collections.Counter() for k in ("bash", "skills", "commands")}
    projects = collections.Counter()

    for path in files:
        s = summarize(path, args.prompt_chars)
        if not s["prompts"] and not s["tools"]:
            continue
        project = s["cwd"] or path.parent.name
        projects[project] += 1
        for key in totals:
            totals[key].update(s[key])
        for key in in_sessions:
            in_sessions[key].update(set(s[key]))
        start = s["start"].strftime("%Y-%m-%d %H:%M") if s["start"] else "?"
        minutes = int((s["end"] - s["start"]).total_seconds() // 60) if s["start"] and s["end"] else "?"
        print(f"## {project} | {s['id']} | {start} | {minutes} min | branch {s['branch'] or '-'}")
        for prompt in s["prompts"][:6]:
            print(f"  > {prompt}")
        if len(s["prompts"]) > 6:
            print(f"  > ... (+{len(s['prompts']) - 6} pedidos)")
        print(f"  comandos: {fmt_counter(s['commands'])}")
        print(f"  skills: {fmt_counter(s['skills'])}")
        print(f"  ferramentas: {fmt_counter(s['tools'])}")
        print(f"  bash: {fmt_counter(s['bash'])}")
        print()

    count = sum(projects.values())
    print(f"# Totais ({count} sessões, {len(projects)} projetos, últimos {args.days} dias)")
    print(f"projetos: {fmt_counter(projects, 20)}")
    for key, label in (("bash", "bash"), ("skills", "skills"), ("commands", "comandos")):
        ranked = ", ".join(f"{k} ({in_sessions[key][k]} sessões)" for k, _ in totals[key].most_common(15)) or "-"
        print(f"{label}: {ranked}")
    print(f"ferramentas: {fmt_counter(totals['tools'], 15)}")


if __name__ == "__main__":
    main()
