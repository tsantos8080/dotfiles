#!/usr/bin/env python3
"""Validates the agent skills of a rendered chezmoi home.

Checks every <home>/.agents/skills/<name>/SKILL.md (frontmatter is valid YAML,
has name and description, name matches the folder, description fits the
1024-character limit) and every <home>/.claude/skills symlink (points to an
existing skill).

Usage: validate_skills.py <rendered-home>
"""
import re
import sys
from pathlib import Path

import yaml

MAX_DESCRIPTION = 1024
FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n", re.S)


def error(message):
    print(f"::error::{message}")


def check_skill(skill_dir):
    path = skill_dir / "SKILL.md"
    if not path.is_file():
        error(f"{skill_dir.name}: missing SKILL.md")
        return False
    match = FRONTMATTER.match(path.read_text(encoding="utf-8"))
    if not match:
        error(f"{skill_dir.name}: SKILL.md has no frontmatter")
        return False
    try:
        data = yaml.safe_load(match.group(1))
    except yaml.YAMLError as exc:
        error(f"{skill_dir.name}: invalid frontmatter YAML: {exc}".replace("\n", " "))
        return False
    if not isinstance(data, dict):
        error(f"{skill_dir.name}: frontmatter is not a mapping")
        return False

    ok = True
    name = data.get("name")
    description = data.get("description")
    if name != skill_dir.name:
        error(f"{skill_dir.name}: name '{name}' does not match the folder name")
        ok = False
    if not isinstance(description, str) or not description.strip():
        error(f"{skill_dir.name}: missing description")
        ok = False
    elif len(description) > MAX_DESCRIPTION:
        error(f"{skill_dir.name}: description has {len(description)} characters (max {MAX_DESCRIPTION})")
        ok = False
    return ok


def main():
    home = Path(sys.argv[1])
    skills = home / ".agents" / "skills"
    links = home / ".claude" / "skills"
    ok = True

    names = set()
    for skill_dir in sorted(p for p in skills.iterdir() if p.is_dir()):
        names.add(skill_dir.name)
        ok = check_skill(skill_dir) and ok

    if links.is_dir():
        for link in sorted(links.iterdir()):
            if not link.is_symlink():
                continue
            target = Path(link.readlink()).name
            if target not in names:
                error(f".claude/skills/{link.name}: points to missing skill '{target}'")
                ok = False

    print(f"{'ok  ' if ok else 'FAIL'} {len(names)} skills checked")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
