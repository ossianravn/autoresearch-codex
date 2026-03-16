# autoresearch-codex

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Codex](https://img.shields.io/badge/Codex-Skill-blueviolet)](https://developers.openai.com/codex/skills/)
[![Agent Skills](https://img.shields.io/badge/Agent%20Skills-Compatible-4f46e5)](https://agentskills.io/home)

AutoResearch is an **autonomous experiment loop**: propose a change, run a benchmark, log the result, keep winners, discard losers, and repeat until you stop.

This repo packages AutoResearch as a **Codex skill** (plus a small wrapper CLI) so you can run long-lived optimization loops inside any git repository.

## What you get

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

## One-time setup in a target repository

```bash
cd /path/to/project
codex-autoresearch install-agents
```

That appends a repo-root `AGENTS.md` block that tells Codex how to resume an active AutoResearch session when `autoresearch.md` exists and `.autoresearch-off` does not.

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

## How it works (session model)

AutoResearch persists state **in the target repository** so a long loop can be resumed safely after interruptions and even after chat compaction.

At a high level, a loop looks like this:

1. Define an objective, a benchmark command, and a primary metric (plus optional secondary metrics).
2. Write (or refine) a fast `autoresearch.sh` runner that prints `METRIC name=number` lines.
3. Iterate: change → benchmark → decide keep/discard → log → dashboard → next idea.

The protocol is intentionally simple: **keep** when the primary metric improves (and checks pass, if you use a correctness gate); otherwise **discard** and try a different idea.

Example metric output:

```text
METRIC wall_time_seconds=12.345
```

### Session files written inside the target repository

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

### Optional correctness gate

If you need “faster but still correct”, add an `autoresearch.checks.sh` script. The skill will run it after successful benchmarks and will log failures as `checks_failed` (not `keep`).

## Codex workflow notes

- Use the `autoresearch` skill as the protocol source of truth.
- Use `AGENTS.md` for persistent repository-local autoresearch behavior.
- Use `/permissions` if you want to relax or tighten approvals during an interactive run.
- Use `/plan` if you want Codex to propose a plan before a risky experiment.
- Use `/compact` only after the current experiment has been fully logged.
- Use `/status` or `/diff` to inspect the session state or working tree at any time.
- If you want to continue the most recent interactive session, Codex supports `codex resume --last`.

## Notes on gitignore and tracked session files

The skill appends an autoresearch block to `.gitignore`, including `autoresearch.md`, `autoresearch.sh`, and `autoresearch.checks.sh`.

That is intentional. These files should be force-added on the first session commit so they survive resets, while still staying out of normal untracked-file noise for later sessions.

## Origins (and why this repo exists)

This is a Codex-native port of [`autoresearch-claude-code`](https://github.com/drivelineresearch/autoresearch-claude-code), which itself is a skill-based port of [`pi-autoresearch`](https://github.com/davebcn87/pi-autoresearch).

Codex and Claude Code have different extension models, so this repo focuses on the **same AutoResearch loop** with Codex-native entrypoints and persistence (`$autoresearch` + repo-local `AGENTS.md` guidance + optional `codex-autoresearch` wrapper).

## Uninstall

```bash
cd ~/autoresearch-codex
./uninstall.sh
```

This removes the user-level skill and wrapper symlinks. It does not edit `AGENTS.md` files in repositories you already configured.

## License

MIT
