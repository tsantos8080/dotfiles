#!/usr/bin/env python3
"""Exercise rendered bootstrap scripts with isolated homes and fake installers."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[2]


def render(path, platform="linux"):
    return subprocess.check_output(
        ["chezmoi", "--source", str(SOURCE), "execute-template", "--override-data",
         '{"chezmoi":{"os":"' + platform + '"}}'],
        input=(SOURCE / path).read_bytes(),
    ).decode()


class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.bin = self.home / ".local/bin"
        self.bin.mkdir(parents=True)
        self.trace = self.home / "calls"
        self.env = dict(os.environ, HOME=str(self.home),
                        PATH=f"{self.bin}:/usr/bin:/bin", TRACE=str(self.trace))

    def stub(self, name, body):
        path = self.bin / name
        path.write_text("#!/usr/bin/env bash\nset -eu\n" + body + "\n")
        path.chmod(0o755)

    def run_script(self, path, platform="linux"):
        shell = "bash" if platform == "linux" else "zsh"
        return subprocess.run([shell], input=render(path, platform), text=True,
                              env=self.env, capture_output=True)

    def test_dependency_failure_stops_before_install(self):
        self.stub("sudo", 'echo "$*" >> "$TRACE"; exit 42')
        result = self.run_script("scripts/run_once_before_00_dependencies.sh.tmpl")
        self.assertEqual(result.returncode, 42, result.stderr)
        self.assertEqual(self.trace.read_text().splitlines(), ["apt-get update"])
        self.assertIn("Falha em", result.stderr)

    def test_macos_dependency_failure_reports_original_exit_code(self):
        self.stub("brew", 'echo "$*" >> "$TRACE"; exit 42')
        result = self.run_script("scripts/run_once_before_00_dependencies.sh.tmpl", "darwin")
        self.assertEqual(result.returncode, 42, result.stderr)
        self.assertIn("Falha em", result.stderr)

    def test_dependencies_include_php_toolchain_and_desktop(self):
        self.stub("sudo", 'echo "$*" >> "$TRACE"')
        result = self.run_script("scripts/run_once_before_00_dependencies.sh.tmpl")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.trace.read_text().splitlines()
        self.assertEqual(calls[0], "apt-get update")
        packages = calls[1].split()
        for package in ["build-essential", "autoconf", "re2c", "pkg-config",
                        "libxml2-dev", "libicu-dev", "libsodium-dev", "zsh",
                        "tmux", "kitty", "flameshot", "unzip", "fontconfig"]:
            self.assertIn(package, packages)
        self.assertNotIn("libxml2", packages)
        self.assertNotIn("php-cli", packages)

    def test_mise_failure_does_not_report_success(self):
        self.stub("mise", 'echo "$*" >> "$TRACE"; if [ "$1" = install ]; then exit 43; fi')
        result = self.run_script("scripts/run_once_mise.sh.tmpl")
        self.assertEqual(result.returncode, 43, result.stderr)
        self.assertIn("install --yes", self.trace.read_text())
        self.assertNotIn("Ferramentas instaladas", result.stdout)

    def test_existing_zsh_does_not_run_installer_or_chsh(self):
        omz = self.home / ".oh-my-zsh"
        omz.mkdir()
        (omz / "oh-my-zsh.sh").touch()
        for name in ["zsh-autosuggestions", "zsh-syntax-highlighting", "zsh-you-should-use"]:
            (omz / "custom/plugins" / name).mkdir(parents=True)
        zshrc = self.home / ".zshrc"
        zshrc.write_text("# preserved configuration\n")
        self.stub("getent", 'echo "user:x:1000:1000::/home/user:/usr/bin/zsh"')
        for command in ["sudo", "curl", "git"]:
            self.stub(command, f'echo "unexpected {command}" >> "$TRACE"; exit 44')
        result = self.run_script("scripts/run_once_oh-my-zsh.sh.tmpl")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.trace.exists())
        self.assertEqual(zshrc.read_text(), "# preserved configuration\n")

    def test_script_headers_and_syntax_on_both_platforms(self):
        for platform, shell in [("linux", "bash"), ("darwin", "zsh")]:
            scripts = list((SOURCE / "scripts").glob("*.tmpl"))
            if platform == "linux":
                scripts += list((SOURCE / "scripts/linux").glob("*.tmpl"))
            for path in scripts:
                with self.subTest(platform=platform, script=path.name):
                    script = render(path.relative_to(SOURCE), platform)
                    self.assertEqual(script.splitlines()[0], f"#!/usr/bin/env {shell}")
                    result = subprocess.run([shell, "-n"], input=script, text=True,
                                            capture_output=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertIn("set -euo pipefail", script)


if __name__ == "__main__":
    unittest.main(verbosity=2)
