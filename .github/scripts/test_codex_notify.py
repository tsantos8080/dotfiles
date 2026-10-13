#!/usr/bin/env python3
"""Local, standard-library tests; never access credentials or send notifications."""
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
def load(name, file):
    spec = importlib.util.spec_from_file_location(name, ROOT / file)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

setup = load("setup", "dot_codex/private_executable_notify-setup.py")
notify = load("notify", "dot_codex/private_executable_notify.py")
ui = load("notify_ui", "dot_codex/private_notify_ui.py")

class NotificationTests(unittest.TestCase):
    def test_install_and_preserve(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            # Empty config avoids writing test backups into the real home.
            setup.install(base)
            raw = (base / "config.toml").read_text()
            self.assertFalse(json.loads((base / "notify-settings.json").read_text())["include_response_summary"])
            setup.install(base)
            self.assertEqual((base / "config.toml").read_text(), raw)
            (base / "config.toml").write_text('notify = ["existing"]\n')
            setup.set_summary(True, base)
            setup.install(base)
            self.assertEqual((base / "config.toml").read_text(), 'notify = ["existing"]\n')
            self.assertTrue(json.loads((base / "notify-settings.json").read_text())["include_response_summary"])

    def test_interactive_safe_defaults(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            setup.install(base)
            with patch.object(setup.sys.stdin, "isatty", return_value=True), patch("builtins.input", side_effect=["2", "", "5", "", "0"]), patch.object(setup.subprocess, "run") as run:
                setup.interactive(base)
                run.assert_not_called()
            self.assertFalse(json.loads((base / "notify-settings.json").read_text())["include_response_summary"])

    def test_interactive_explicit_api_test(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            setup.install(base)
            with patch.object(setup.sys.stdin, "isatty", return_value=True), patch("builtins.input", side_effect=["5", "s", "0"]), patch.object(setup.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)) as run:
                setup.interactive(base)
                self.assertEqual(run.call_count, 1)
                self.assertEqual(run.call_args[0][0][-1], "--test-api")

    def test_display_fail_closed(self):
        for state in ("on", "unknown"):
            with patch.object(notify, "screen_state", return_value=state), patch.object(notify, "credentials") as credentials, patch.object(notify, "push") as push:
                self.assertEqual(notify.handle({"type": "agent-turn-complete"}), "skipped_display_" + state)
                credentials.assert_not_called()
                push.assert_not_called()

    def test_excerpt_privacy(self):
        event = {"cwd": "/private/project", "input-messages": ["PRIVATE_INPUT"], "last-assistant-message": "x" * 500}
        options = {"include_project_name": True, "include_response_summary": False}
        text = notify.message(event, options)
        self.assertNotIn("x" * 10, text)
        self.assertNotIn("/private", text)
        options["include_response_summary"] = True
        text = notify.message(event, options)
        self.assertIn("x" * 240, text)
        self.assertNotIn("x" * 241, text)
        self.assertNotIn("PRIVATE_INPUT", text)

    def test_visual_navigation(self):
        self.assertEqual(ui.next_selection(ui.curses.KEY_DOWN, 0, 6), 1)
        self.assertEqual(ui.next_selection(ui.curses.KEY_UP, 0, 6), 5)
        screen = unittest.mock.Mock()
        screen.get_wch.side_effect = [ui.curses.KEY_DOWN, "\n"]
        with patch.object(ui.curses, "noecho"), patch.object(ui.curses, "curs_set"):
            visual = ui.UI(screen)
        with patch.object(visual, "draw"):
            self.assertEqual(visual.menu("test", ["a", "b"]), 1)
        screen.get_wch.side_effect = ["\x1b"]
        with patch.object(visual, "draw"):
            self.assertIsNone(visual.menu("test", ["a", "b"]))

    def test_visual_credentials_are_hidden_and_cancellable(self):
        screen = unittest.mock.Mock()
        screen.get_wch.side_effect = ["a", "b", ui.curses.KEY_BACKSPACE, "c", "\n"]
        with patch.object(ui.curses, "noecho"), patch.object(ui.curses, "curs_set"):
            visual = ui.UI(screen)
        with patch.object(visual, "draw") as draw:
            self.assertEqual(visual.secret("Token"), "ac")
            self.assertNotIn("ac", str(draw.call_args_list))
        screen.get_wch.side_effect = ["\x1b"]
        with patch.object(visual, "draw"):
            with self.assertRaises(KeyboardInterrupt):
                visual.secret("Token")

    def test_timeout_returns_zero(self):
        with patch.object(notify.subprocess, "run", side_effect=subprocess.TimeoutExpired("test", 20)), patch.object(notify, "audit") as audit:
            self.assertEqual(notify.main(["{}"]), 0)
            audit.assert_called_once_with("timed_out_safe")

if __name__ == "__main__":
    unittest.main()
