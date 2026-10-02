# dotfiles

Install with [chezmoi](https://www.chezmoi.io/install):
```
chezmoi init --apply https://github.com/tsantos8080/dotfiles.git
```

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
| `verification-plan`              | Lists what must be true after a change, how each point could fail with green tests, and the evidence to prove it; runs the plan at the end. | Before non-trivial features, fixes, data migrations or integrations.        | own                                                             |
| `verification-before-completion` | Requires running the checks and reading the output before claiming something is done, fixed or passing.      | Before saying "done", committing or opening a PR.                           | [obra/superpowers](https://github.com/obra/superpowers) (MIT)   |
| `systematic-debugging`           | Root cause before any fix: reproduce, trace the data, test one hypothesis at a time, then fix with a test.    | Any bug, failing test or unexpected behavior.                               | [obra/superpowers](https://github.com/obra/superpowers) (MIT)   |
| `refactor-sweep`                 | Reviews several merged commits/PRs together for leftovers, duplication, silent behavior changes and test gaps. | After a refactor or a series of PRs in the same area, or before a big deploy. | own                                                           |
| `security-audit`                 | PHP/Laravel security audit focused on exploitable issues, mainly one account reaching another's data.         | Dedicated security reviews or before releasing a sensitive area.            | own                                                             |
| `simplify`                       | Simplifies recently changed code without changing behavior, one change at a time with tests. Codex only (Claude Code ships its own `/simplify`). | After a feature works but the code feels heavy.                  | own                                                             |
| `humanizer`                      | Rewrites AI-sounding text so it reads like a person wrote it, without changing the facts.                     | Docs, PR descriptions, posts or messages that sound generated.              | [blader/humanizer](https://github.com/blader/humanizer) v3.1.0 (MIT) |
| `reflect`                        | Reads recent Claude Code sessions, finds repeated manual work and suggests the lightest fix, or none.        | Occasionally (e.g. monthly) to tune skills, instructions and settings.      | adapted from [oh-my-opencode-slim](https://github.com/alvinunreal/oh-my-opencode-slim) (MIT) |

`start-task` writes to the Logseq graph set in `logseqDir` (asked once by `chezmoi init`, stored in `~/.config/chezmoi/chezmoi.toml`, default `~/Documents/Notes`).
