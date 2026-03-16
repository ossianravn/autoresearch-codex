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
