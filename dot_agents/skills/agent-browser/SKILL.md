---
name: agent-browser
description: Browser automation CLI for AI agents. Use when the user needs to explore or validate behavior in a web front end: navigate pages, fill forms, click buttons, take screenshots, extract data, see which API calls a screen makes (method, URL, status, payload), record traffic as HAR, or mock backend responses to see how the front end reacts. Triggers include "abre a página", "testa no front", "valida o comportamento no front", "o que essa tela chama", "quais requisições", "mocka a resposta", "tira um screenshot", "open a website", "test this web app", "fill out a form", "login to a site", exploratory testing and QA. Use only against local or staging environments.
allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*)
---

# agent-browser

Fast browser automation CLI for AI agents. Chrome/Chromium via CDP with accessibility-tree snapshots and compact `@eN` element refs.

Install: `npm i -g agent-browser && agent-browser install`

## Start here

This file is a discovery stub, not the usage guide. Before running any `agent-browser` command, load the actual workflow content from the CLI:

```bash
agent-browser skills get core             # start here — workflows, common patterns, troubleshooting
agent-browser skills get core --full      # include full command reference and templates
```

The CLI serves skill content that always matches the installed version, so instructions never go stale. The content in this stub cannot change between releases, which is why it just points at `skills get core`.

## Specialized skills

Load a specialized skill when the task falls outside browser web pages:

```bash
agent-browser skills get electron          # Electron desktop apps (VS Code, Slack, Discord, Figma, ...)
agent-browser skills get slack             # Slack workspace automation
agent-browser skills get dogfood           # Exploratory testing / QA / bug hunts
agent-browser skills get derive-client     # Record a HAR, derive a standalone API client for a site
agent-browser skills get vercel-sandbox    # agent-browser inside Vercel Sandbox microVMs
agent-browser skills get protected-vercel-deployments  # Access protected Vercel deployments
agent-browser skills get agentcore         # AWS Bedrock AgentCore cloud browsers
```

Run `agent-browser skills list` to see everything available on the installed version.

## Why agent-browser

- Fast native Rust CLI, not a Node.js wrapper
- Works with any AI agent (Cursor, Claude Code, Codex, Continue, Windsurf, etc.)
- Chrome/Chromium via CDP with no Playwright or Puppeteer dependency
- Accessibility-tree snapshots with element refs for reliable interaction
- Sessions, authentication vault, state persistence, video recording
- Specialized skills for Electron apps, Slack, exploratory testing, cloud providers

## Observability Dashboard

The dashboard runs independently of browser sessions on port 4848 and can also be opened through a proxied or forwarded URL such as `https://dashboard.agent-browser.localhost`. Agents should stay on the dashboard origin: session tabs, status, and stream traffic are proxied internally, so session ports do not need to be exposed.

## Backend use: exploring the front end

Most useful when you need to know what the front end actually does with the API:

```bash
# Which endpoints does this screen call, and with what?
agent-browser open http://localhost:8000/envios
agent-browser snapshot                 # find the element refs
agent-browser click @e5
agent-browser network requests --type xhr,fetch   # only API calls: method, URL, status
agent-browser network requests --method POST --status 4xx
agent-browser network request <id>     # headers and body of one request

# Record a whole flow to study offline (response bodies included)
agent-browser network har start
# ... navigate and interact ...
agent-browser network har stop /tmp/fluxo.har

# How does the front end react to a response the backend doesn't return yet?
# (--body always answers with status 200; use --abort to simulate a network failure)
agent-browser network route "**/api/v2/envios" --body '{"data": [], "total": 0}'
agent-browser network route "**/api/v2/checkout" --abort
agent-browser network unroute          # remove the mocks

# Evidence for a PR or a bug report
agent-browser screenshot --annotate tela.png   # numbered labels matching the @eN refs
agent-browser screenshot --full pagina.png     # full scroll height
agent-browser record start fluxo.webm --cursor # needs ffmpeg installed
agent-browser record stop
```

`network route` cannot set a status code: `--body` always answers 200 and
`--abort` fails the request. To see how the front end handles a 4xx/5xx, make
the local backend return it.

## Rules

- Use it only against local or staging environments. Never against production.
- Never save production credentials with `agent-browser auth save`.
- HAR files and request bodies can contain personal data and tokens. Keep them
  in a temporary directory, delete them when done, and never commit them.
- Close the browser when finished: `agent-browser close`.

---

Based on the `agent-browser` skill from
[vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser)
(Apache-2.0, see `LICENSE`). Changes: rewritten `description` (web-only
triggers, plus backend and Portuguese triggers), removed `hidden: true`, and
added the "Backend use" and "Rules" sections.
