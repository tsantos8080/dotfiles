# dotfiles

Install with [chezmoi](https://www.chezmoi.io/install):
```
chezmoi init --apply https://github.com/tsantos8080/dotfiles.git
```

On Linux, the bootstrap targets Ubuntu with `main` and `universe` enabled.
System dependencies are installed first (with `sudo`), then mise installs the
pinned tool versions. PHP is compiled once; subsequent applies reuse it. Node
comes exclusively from mise. The Neovim Python provider is installed into mise's
Python. On macOS, Homebrew must already be installed.

The installer preserves the managed `.zshrc`, changes the login shell only when
necessary, and stops on errors. Each script prints its name before running. Open
a new terminal after installation; Bash and Zsh load mise automatically. To
resume an interrupted installation, run `chezmoi apply -v`.

Tool versions live in `dot_config/mise/config.toml.tmpl`. Update them deliberately
and run `.github/scripts/validate.sh` before committing. The Neovim version and
`lazy-lock.json` must be updated together. GitHub Actions also installs the full
configuration as an unprivileged user on clean Ubuntu 26.04, checks PHP
extensions and shell activation, and applies it twice to check repeatability.

### Codex notifications with Pushover (macOS)

On macOS, chezmoi installs a Python notification script and adds Codex CLI's
native `notify` hook to `~/.codex/config.toml`. Existing settings are preserved
and backed up; an existing different `notify` hook is left untouched. Restart
Codex CLI after installation to load the hook.

Notifications are sent only when all online displays are asleep, as reported by
CoreGraphics. Locking the session alone does not qualify. If the display state
cannot be confirmed, no notification is sent. Notification failures do not
interrupt Codex; the hook has a 20-second execution limit.

Open the interactive terminal configurator to register tokens, choose whether
to include response excerpts, inspect display/credential status, and test delivery:

```sh
/usr/bin/python3 ~/.codex/notify-setup.py --interactive
```

It starts with excerpts disabled on new machines. The API test asks for explicit
confirmation because it sends even when the display is on. Token entry is hidden.
The installer used by chezmoi remains noninteractive.

Alternatively, register credentials once per Mac using hidden prompts:

```sh
/usr/bin/python3 ~/.codex/notify.py --configure-credentials
/usr/bin/python3 ~/.codex/notify.py --credentials-status
```

Enter `PUSHOVER_APP_TOKEN` first, then `PUSHOVER_USER_KEY`. They are stored in the
macOS login Keychain, not in Git, chezmoi templates, or the script. No personal
Bitwarden account is required at setup or runtime. Each machine needs its own
local registration; the dotfiles do not distribute credentials.

Response excerpts are **disabled by default on new installations**, suitable
for work machines. Enable them explicitly only if sending response content to
your Pushover account is appropriate. The local setting is not managed by
chezmoi and existing preferences are preserved:

```sh
/usr/bin/python3 ~/.codex/notify-setup.py --summary on
/usr/bin/python3 ~/.codex/notify-setup.py --summary off
```

When enabled, notifications include at most 240 characters from the last reply,
not an AI-generated summary or a secret-filtered response. The project name is
included when available; user prompts are never sent. The current Codex event
does not provide a reliable error status.

Test the integration:

```sh
/usr/bin/python3 ~/.codex/notify.py --screen-status
/usr/bin/python3 ~/.codex/notify.py --test-api
/usr/bin/python3 ~/.codex/notify.py --test-notification
```

`--test-api` deliberately ignores display state and sends a synthetic message;
`--test-notification` respects the display check. API acceptance and display
on/off gating were tested on macOS, and Android receipt was confirmed. Validate
a real native Codex completion after restarting the CLI. See
[the detailed notification guide](dot_codex/private_notify-README.md) for manual
display tests, troubleshooting, and removal.

Sources are `dot_codex/private_executable_notify.py`,
`dot_codex/private_executable_notify-setup.py`, and
`scripts/run_onchange_after_codex-notify.sh.tmpl`. Local settings, credentials,
backups, and logs are not versioned. These files are applied **only on macOS**.
Windows 11, Codex in WSL/Ubuntu, and Claude Code on Ubuntu/GNOME still need their
own implementations and real-system validation. In WSL, display detection must
use the Windows host rather than the Ubuntu guest.

### Keybindings in Neovim

| **Command**        | **Description**                                                     |
|--------------------|---------------------------------------------------------------------|
| `<tab>`            | Switches to the previous buffer.                                   |
| `<leader>t`        | Runs tests using a custom script.                                  |
| `<leader>w`        | Saves the current file.                                            |
| `<leader>gs`       | Toggle split line (TSJToggle).                                     |
| `<leader>gb`       | Toggles GitBlame.                                                  |
| `<leader>lg`       | Opens LazyGit.                                                     |
| `<leader>lf`       | Format code.                                                       |
| `gi`               | Opens the implementation of the current function or variable.      |
| `gr`               | Shows references for the current function or variable.             |
| `K`                | Shows hover information for the item under the cursor.             |
| `r`                | Renames the item under the cursor.                                 |
| `<leader>ff`       | Opens Telescope to search for files.                               |
| `<leader>fo`       | Opens Telescope for recent files (only files from the current directory). |
| `<leader>fg`       | Opens Telescope for Git status.                                    |
| `<leader>fb`       | Opens Telescope to list open buffers.                              |
| `<leader>fb`       | Opens Telescope to list TODOs not pushed yet.                      |
| `<leader>sg`       | Starts live search using Telescope.                                |
| `<leader>e`        | Toggles the visibility of NvimTree (file explorer).                |
| `<leader>E`        | Locates and focuses on the current file in NvimTree.               |
| `s`                | Starts Flash search (works in normal, visual, and operator modes). |
| `S`                | Starts Flash Treesitter search (works in normal, visual, and operator modes). |
| `r`                | Starts remote Flash (works in operator mode).                      |
| `R`                | Starts Treesitter search in operator and visual modes.             |
| `<c-s>`            | Toggles Flash search in command-line mode.                         |

### Agent skills

Personal skills for Claude Code and Codex live in `~/.agents/skills` (source: `dot_agents/skills/`), which Codex reads directly. Claude Code gets them through symlinks in `~/.claude/skills` (source: `dot_claude/skills/symlink_*.tmpl`). Invoke with `/<name>` in Claude Code or `$<name>` in Codex, or just describe the task.

| **Skill**                        | **What it does**                                                                                              | **When to use**                                                              | **Source**                                                      |
|----------------------------------|---------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|-----------------------------------------------------------------|
| `start-task`                     | Kicks off a Jira task: reads it with all comments, grills you with `grilling`, then creates the branch, a draft PR, a Jira comment with the PR link and a review TODO in the Logseq journal. Runs only when invoked. | When starting a new Jira task, before writing code. | own |
| `grilling`                       | Interviews you in rounds of numbered questions, each with a recommended answer, until no decision is left open. `/grill-me` is a shortcut to it. | To stress-test a plan, design or task understanding. | [mattpocock/skills](https://github.com/mattpocock/skills) (MIT) |
| `grill-me`                       | Shortcut that calls `grilling`. Runs only when invoked.                                                       | Same as `grilling`, typed as `/grill-me`.                                    | [mattpocock/skills](https://github.com/mattpocock/skills) (MIT) |
| `verification-plan`              | Lists what must be true after a change, how each point could fail with green tests, and the evidence to prove it; runs the plan at the end. | Before non-trivial features, fixes, data migrations or integrations.        | own                                                             |
| `verification-before-completion` | Requires running the checks and reading the output before claiming something is done, fixed or passing.      | Before saying "done", committing or opening a PR.                           | [obra/superpowers](https://github.com/obra/superpowers) (MIT)   |
| `systematic-debugging`           | Root cause before any fix: reproduce, trace the data, test one hypothesis at a time, then fix with a test.    | Any bug, failing test or unexpected behavior.                               | [obra/superpowers](https://github.com/obra/superpowers) (MIT)   |
| `refactor-sweep`                 | Reviews several merged commits/PRs together for leftovers, duplication, silent behavior changes and test gaps. | After a refactor or a series of PRs in the same area, or before a big deploy. | own                                                           |
| `security-audit`                 | PHP/Laravel security audit focused on exploitable issues, mainly one account reaching another's data.         | Dedicated security reviews or before releasing a sensitive area.            | own                                                             |
| `simplify`                       | Simplifies recently changed code without changing behavior, one change at a time with tests. Codex only (Claude Code ships its own `/simplify`). | After a feature works but the code feels heavy.                  | own                                                             |
| `agent-browser`                  | Drives a separate Chrome from the CLI: navigate, click, fill, screenshot, list the API calls a screen makes, record HAR, mock responses. CLI installed via mise. | To explore or validate front-end behavior, mainly which endpoints a screen calls. Local/staging only. | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) (Apache-2.0, modified) |
| `humanizer`                      | Rewrites AI-sounding text so it reads like a person wrote it, without changing the facts.                     | Docs, PR descriptions, posts or messages that sound generated.              | [blader/humanizer](https://github.com/blader/humanizer) v3.1.0 (MIT) |
| `reflect`                        | Reads recent Claude Code sessions, finds repeated manual work and suggests the lightest fix, or none.        | Occasionally (e.g. monthly) to tune skills, instructions and settings.      | adapted from [oh-my-opencode-slim](https://github.com/alvinunreal/oh-my-opencode-slim) (MIT) |

`start-task` writes to the Logseq graph set in `logseqDir` (asked once by `chezmoi init`, stored in `~/.config/chezmoi/chezmoi.toml`, default `~/Documents/Notes`).

#### `agent-browser` examples

```bash
# Which endpoints does this screen call?
agent-browser open http://localhost:8000/envios
agent-browser snapshot                            # element refs like @e5
agent-browser click @e5
agent-browser network requests --type xhr,fetch   # method, URL, status
agent-browser network request <id>                # headers and body

# Record a flow, response bodies included
agent-browser network har start
agent-browser network har stop /tmp/fluxo.har

# See how the front end reacts before the endpoint exists
agent-browser network route "**/api/v2/envios" --body '{"data": [], "total": 0}'   # always status 200
agent-browser network route "**/api/v2/checkout" --abort                          # network failure
agent-browser close
```
