---
name: autoresearch
description: Set up, resume, pause, and run an autonomous experiment loop inside a git repository. Use when asked to run autoresearch, optimize something through repeated experiments, continue an existing loop from autoresearch.md or autoresearch.jsonl, or apply new user steering to the next experiment while keeping the loop going.
compatibility: Designed for Codex CLI, Codex IDE, and Codex app with git access, shell access, and permission to edit files in the working tree.
---

# Autoresearch

Autonomous experiment loop: try ideas, measure results, keep winners, discard losers, and continue until interrupted or the ideas backlog is exhausted.

## Handle intent first

- If the user asks to pause, stop, or turn off autoresearch, create `.autoresearch-off` at the repository root, confirm that the loop is paused, and stop.
- If `autoresearch.md` already exists at the repository root and the user asks to continue, resume, keep going, or steer the research, remove `.autoresearch-off` if it exists and resume from the session files.
- If `autoresearch.md` exists at the repository root and repository instructions indicate autoresearch is active, treat a short prompt like “continue” or “keep going” as a resume.
- Otherwise create a new session.

## Repository prerequisites

- Work inside a git repository. Prefer the repository root for session files.
- Read the relevant source files, tests, build scripts, and benchmark entrypoints before you design experiments.
- Keep session artifacts predictable. Ensure `.gitignore` contains this block if the entries are not already present:

```gitignore
# autoresearch session state
experiments/*
!experiments/worklog.md
autoresearch.jsonl
autoresearch-dashboard.md
autoresearch.md
autoresearch.sh
autoresearch.checks.sh
autoresearch.ideas.md
.autoresearch-off
plots/
```

- Create `experiments/` if it does not exist.

## Install persistent repository instructions

Use the repository root `AGENTS.md` for persistent autoresearch behavior. Preserve existing instructions and append an autoresearch section instead of overwriting the file.

Append this block if there is not already an equivalent section:

```markdown
<!-- autoresearch-codex:start -->
## Autoresearch session rules
When `autoresearch.md` exists at the repository root and `.autoresearch-off` does not exist there:
- Read `autoresearch.md`, `autoresearch.jsonl`, `autoresearch-dashboard.md`, `experiments/worklog.md`, `autoresearch.ideas.md` if present, and recent git history before proposing work.
- Use the `autoresearch` skill for setup, logging, and resume behavior.
- Treat new user messages as steering for the next experiment unless they explicitly ask to pause or stop.
- Finish logging the current experiment before changing direction.
- Continue the loop until interrupted or until no credible next experiments remain.

When `.autoresearch-off` exists at the repository root:
- Do not resume autoresearch automatically.
<!-- autoresearch-codex:end -->
```

## Set up a new session

1. Ask or infer the **goal**, **benchmark command**, **primary metric** (name + unit + lower/higher is better), **secondary metrics** if useful, **files in scope**, and **constraints**.
2. Create or switch to a branch named `autoresearch/<goal>-<yyyymmdd>`.
3. Write `autoresearch.md`, `autoresearch.sh`, `experiments/worklog.md`, and optionally `autoresearch.checks.sh` when correctness gates are required.
4. Commit the session scaffolding. Because `autoresearch.md` and `autoresearch.sh` may be ignored, force-add them on the first commit:

```bash
git add .gitignore AGENTS.md experiments/worklog.md 2>/dev/null || git add .gitignore experiments/worklog.md
git add -f autoresearch.md autoresearch.sh
test -f autoresearch.checks.sh && git add -f autoresearch.checks.sh || true
git diff --cached --quiet || git commit -m "Initialize autoresearch session"
```

5. Initialize `autoresearch.jsonl` with a config header.
6. Run the baseline, log it, generate `autoresearch-dashboard.md`, and start iterating immediately.

### `autoresearch.md`

This file is the durable session brief. A fresh Codex instance should be able to read it and continue intelligently.

```markdown
# Autoresearch: <goal>

## Objective
<Specific description of what is being optimized and why it matters.>

## Metrics
- **Primary**: <name> (<unit>, lower/higher is better)
- **Secondary**: <name>, <name>, ...

## How to Run
`./autoresearch.sh` — emits `METRIC name=number` lines.

## Correctness Gate
<If `autoresearch.checks.sh` exists, describe what it validates and when failures should block a keep.>

## Files in Scope
<Every file the loop may modify, with a short note.>

## Off Limits
<What must not be changed.>

## Constraints
<Hard rules: tests must pass, no new deps, no API changes, etc.>

## What's Been Tried
<Update this section as experiments accumulate. Capture wins, dead ends, and architectural insights so a resuming agent does not repeat them.>
```

Update `autoresearch.md` periodically, especially after breakthroughs or clear dead ends.

### `autoresearch.sh`

Write a fast benchmark script with `set -euo pipefail` that:

- performs the cheapest sanity checks first,
- runs the workload,
- emits one or more lines in the form `METRIC name=number`, and
- keeps benchmark-only time separate from any optional correctness checks.

Prefer stable, repeatable measurements over noisy ones.

### `autoresearch.checks.sh` (optional)

Only create this file when the user’s constraints require a correctness gate such as tests, type checks, lint, or safety checks.

- Run it only after a successful benchmark run.
- Keep the output brief and error-focused.
- A failure in this script must block a keep and should be logged as `checks_failed`.

## JSONL state protocol

All durable state lives in `autoresearch.jsonl`.

### Config header

The first line, and every re-initialization line, is a config header:

```json
{"type":"config","name":"<session name>","metricName":"<primary metric name>","metricUnit":"<unit>","bestDirection":"lower|higher"}
```

Rules:

- The first line of the file is always a config header.
- Each later config header starts a new **segment**.
- The baseline for a segment is the first result line after that segment’s config header.

### Result line

Each experiment appends one JSON object:

```json
{"run":1,"commit":"abc1234","metric":42.3,"metrics":{"secondary_metric":123},"status":"keep","description":"baseline","timestamp":1234567890,"segment":0}
```

Fields:

- `run`: sequential run number across all segments.
- `commit`: 7-character git hash. For `keep`, use the commit after the keep commit. For `discard`, `crash`, or `checks_failed`, use the current `HEAD` before reverting.
- `metric`: primary metric value. Use the measured value for successful benchmark runs. Use `0` only when no primary metric is available because the benchmark crashed before reporting one.
- `metrics`: object of secondary metric values. Once a secondary metric appears, include it in every later result.
- `status`: one of `keep`, `discard`, `crash`, `checks_failed`.
- `description`: short description of the experiment.
- `timestamp`: Unix epoch seconds.
- `segment`: zero-based segment index.

### Initialization

To initialize or re-initialize:

```bash
echo '{"type":"config","name":"<name>","metricName":"<metric>","metricUnit":"<unit>","bestDirection":"<lower|higher>"}' > autoresearch.jsonl
```

Append instead of overwrite when changing optimization targets mid-session.

## Running experiments

Run the benchmark while capturing output and wall-clock time:

```bash
set +e
START_TIME=$(date +%s%N)
bash -c "./autoresearch.sh" 2>&1 | tee /tmp/autoresearch-output.txt
EXIT_CODE=${PIPESTATUS[0]}
END_TIME=$(date +%s%N)
set -e
DURATION=$(python3 - <<PY
start = int("$START_TIME")
end = int("$END_TIME")
print(f"{(end-start)/1_000_000_000:.3f}")
PY
)
echo "Duration: ${DURATION}s, Exit code: ${EXIT_CODE}"
```

After the run:

- parse every `METRIC name=number` line,
- identify the primary metric plus any secondary metrics,
- if the benchmark exit code is non-zero, this run is a `crash`,
- if `autoresearch.checks.sh` exists and the benchmark passed, run it now,
- if checks fail, this run is `checks_failed`, not `keep`.

## Logging protocol

After each experiment, follow this sequence exactly.

### 1. Determine status

- `keep`: primary metric improved versus the best kept result in the current segment, and checks passed if a checks script exists.
- `discard`: primary metric was worse or equal, or the improvement was too small to justify the complexity.
- `crash`: benchmark command failed.
- `checks_failed`: benchmark passed but `autoresearch.checks.sh` failed.

Primary metric is the default decision-maker. Only reject a primary improvement for catastrophic secondary-metric or correctness regressions, and explain the reason in the description.

### 2. Git operations

**If keep:**

```bash
git add -A
git diff --cached --quiet && echo "nothing to commit" || git commit -m "<description>

Result: {\"status\":\"keep\",\"<metricName>\":<value>,<secondary metrics>}"
git rev-parse --short=7 HEAD
```

**If discard, crash, or checks_failed:**

```bash
CURRENT_HASH=$(git rev-parse --short=7 HEAD)
git checkout -- .
git clean -fd
```

Use `CURRENT_HASH` as the `commit` value for the logged result.

### 3. Append result to JSONL

```bash
echo '{"run":<N>,"commit":"<hash>","metric":<value>,"metrics":{<secondaries>},"status":"<status>","description":"<desc>","timestamp":'$(date +%s)',"segment":<seg>}' >> autoresearch.jsonl
```

### 4. Regenerate `autoresearch-dashboard.md`

After every logged result, regenerate the dashboard from the current segment.

Use this shape:

```markdown
# Autoresearch Dashboard: <name>

**Runs:** 12 | **Kept:** 8 | **Discarded:** 2 | **Checks failed:** 1 | **Crashed:** 1
**Baseline:** <metric_name>: <value><unit> (#1)
**Best:** <metric_name>: <value><unit> (#8, -26.2%)

| # | commit | <metric_name> | status | description |
|---|--------|---------------|--------|-------------|
| 1 | abc1234 | 42.3s | keep | baseline |
| 2 | def5678 | 40.1s (-5.2%) | keep | optimize hot loop |
| 3 | abc1234 | 43.0s (+1.7%) | discard | try vectorization |
```

Show all runs in the current segment, not just the recent ones.

### 5. Append to `experiments/worklog.md`

After each run, append a concise narrative entry:

```markdown
### Run N: <short description> — <primary_metric>=<value> (<STATUS>)
- Timestamp: YYYY-MM-DD HH:MM
- What changed: <1-2 short sentences>
- Result: <metric values>, <delta vs best>
- Insight: <what this taught you>
- Next: <what to try next>
```

Maintain `Key Insights` and `Next Ideas` sections near the bottom of the worklog.

### 6. Secondary metric consistency

Once you track a secondary metric, include it in every later result. If you introduce a new one mid-session, keep it from that point onward.

## Compaction and resume discipline

Codex sessions may be compacted or resumed later. Before any compaction, or whenever the conversation is becoming long:

- finish the current experiment,
- update `autoresearch.jsonl`, `autoresearch-dashboard.md`, and `experiments/worklog.md`, and
- refresh `autoresearch.md` if new strategic knowledge was learned.

On resume, treat `autoresearch.md`, `autoresearch.jsonl`, `experiments/worklog.md`, `autoresearch.ideas.md` if present, and recent git history as the source of truth.

## Loop rules

- Loop continuously until interrupted or until no credible next experiments remain.
- Prefer small, reviewable changes over giant speculative rewrites.
- Simpler code for equal performance is usually a keep.
- Do not thrash on the same failed idea. When stuck, change level: algorithm, data layout, batching, caching, I/O, or measurement method.
- Fix trivial crashes quickly; otherwise log them and move on.
- Think deeply when stuck. Re-read the code and reason about the real bottleneck instead of random mutation.
- If the user sends a new idea while a run is in progress, finish logging the current run first, then use the user’s steer in the next experiment.

## Ideas backlog

When you notice promising ideas that are too large or premature, append them to `autoresearch.ideas.md`.

If the loop resumes after interruption and `autoresearch.ideas.md` exists:

1. prune duplicated or already-tried ideas,
2. convert the best remaining ideas into new experiments,
3. delete the file only when every credible path has been exhausted and the research is genuinely complete.
