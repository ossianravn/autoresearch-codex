# autoresearch-codex

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Codex](https://img.shields.io/badge/Codex-Skill-blueviolet)](https://developers.openai.com/codex/skills/)
[![Agent Skills](https://img.shields.io/badge/Agent%20Skills-Compatible-4f46e5)](https://agentskills.io/home)

Autonomous experiment loop for Codex.

This is a Codex-native port of [`autoresearch-claude-code`](https://github.com/drivelineresearch/autoresearch-claude-code), which itself is a skill-based port of [`pi-autoresearch`](https://github.com/davebcn87/pi-autoresearch).

The goal is the same: run repeated experiments, measure the result, keep winners, discard losers, and continue until interrupted.

## Why this port looks different from the Claude Code version

Codex has a different extension model than Claude Code, so this port adapts the architecture instead of doing a direct rename.

| Concern | Claude Code port | Codex port |
|---|---|---|
| Main entrypoint | Custom `/autoresearch` command | `$autoresearch` skill mention and `codex-autoresearch` wrapper |
| Persistent repo instructions | `UserPromptSubmit` hook | `AGENTS.md` block at the target repo root |
| Skill location | `~/.claude/skills` | `.agents/skills` in-repo or `$HOME/.agents/skills` for user install |
| Long unattended runs | Same interactive session | Same interactive flow, plus optional `codex exec --full-auto --sandbox workspace-write` wrapper mode |
| Skill metadata | Claude skill only | Agent Skills layout + optional `agents/openai.yaml` |

The result is still “autoresearch as a skill”, but with Codex-native entrypoints and persistence.

## What is included

```text
.agents/skills/autoresearch/SKILL.md      # Codex skill
.agents/skills/autoresearch/agents/openai.yaml
bin/codex-autoresearch                    # convenience wrapper for start/resume/off/exec/install-agents
templates/AGENTS.autoresearch.md          # repo-local persistent guidance block
install.sh                                # installs the skill to $HOME/.agents/skills and the wrapper to ~/.local/bin
uninstall.sh                              # removes the user-level symlinks
```

## Install

```bash
git clone <your-fork-or-local-copy> ~/autoresearch-codex
cd ~/autoresearch-codex
./install.sh
```

If you see `Permission denied`, run `chmod +x install.sh` (or use `bash install.sh`).

Then make sure `~/.local/bin` is on your `PATH`.

## Recommended setup inside a target repository

```bash
cd /path/to/project
codex-autoresearch install-agents
```

That appends a repo-root `AGENTS.md` block that tells Codex how to resume an active autoresearch session when `autoresearch.md` exists and `.autoresearch-off` does not.

If the repository does not already have an `AGENTS.md`, you can also start from Codex’s built-in scaffold:

```text
/init
```

Then append the template block from `templates/AGENTS.autoresearch.md`.

## Usage

### Start a new loop

```bash
cd /path/to/project
codex-autoresearch "optimize test suite runtime"
```

That launches interactive Codex with an explicit `$autoresearch` skill prompt.

### Resume an existing loop

```bash
codex-autoresearch
```

If `autoresearch.md` already exists at the repository root, the wrapper sends a resume prompt.

### Pause a loop

```bash
codex-autoresearch off
```

This creates `.autoresearch-off` at the repository root.

### Explicit resume with new steering

```bash
codex-autoresearch resume "focus on batching and cache locality next"
```

### Non-interactive run

```bash
codex-autoresearch exec "reduce CI wall time without changing test behavior"
```

This uses `codex exec --full-auto --sandbox workspace-write`, which is useful for automation or CI-style runs.

### Direct skill invocation inside Codex

You can also start Codex yourself and invoke the skill explicitly:

```text
$autoresearch optimize bundle size without changing public behavior
```

## Session files written inside the target repository

The wrapper resolves the repository root with `git rev-parse --show-toplevel` when available, so the session files are intended to live at the repo root even if you launch from a nested directory.

| File | Purpose |
|---|---|
| `autoresearch.md` | Durable session brief: objective, metrics, scope, constraints, what has been tried |
| `autoresearch.sh` | Fast benchmark runner that emits `METRIC name=number` lines |
| `autoresearch.checks.sh` | Optional correctness gate for tests/types/lint |
| `autoresearch.jsonl` | Append-only machine-readable state log |
| `autoresearch-dashboard.md` | Human-readable dashboard generated after each run |
| `experiments/worklog.md` | Narrative worklog that survives compaction and resume |
| `autoresearch.ideas.md` | Backlog for larger or postponed ideas |
| `.autoresearch-off` | Pause sentinel |

## Codex-native workflow notes

- Use the `autoresearch` skill as the protocol source of truth.
- Use `AGENTS.md` for persistent repository-local autoresearch behavior.
- Use `/permissions` if you want to relax or tighten approvals during an interactive run.
- Use `/plan` if you want Codex to propose a plan before a risky experiment.
- Use `/compact` only after the current experiment has been fully logged.
- Use `/status` or `/diff` to inspect the session state or working tree at any time.
- For chained non-interactive workflows, Codex itself supports `codex exec resume --last ...`.

## Optional correctness gate

Unlike the Claude port, this Codex version restores one useful pattern from `pi-autoresearch`: an optional `autoresearch.checks.sh` file.

Create it when the optimization target must preserve behavior and the loop should reject “faster but broken” experiments. The skill logs these as `checks_failed` instead of `keep`.

## Notes on gitignore and tracked session files

The skill appends an autoresearch block to `.gitignore`, including `autoresearch.md`, `autoresearch.sh`, and `autoresearch.checks.sh`.

That is intentional. These files should be force-added on the first session commit so they survive resets, while still staying out of normal untracked-file noise for later sessions.

## Uninstall

```bash
cd ~/autoresearch-codex
./uninstall.sh
```

This removes the user-level skill and wrapper symlinks. It does not edit `AGENTS.md` files in repositories you already configured.

## License

MIT
