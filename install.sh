#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_SKILLS_DIR="$HOME/.agents/skills"
USER_BIN_DIR="$HOME/.local/bin"

if [ ! -x "$REPO_DIR/bin/codex-autoresearch" ]; then
  chmod +x "$REPO_DIR/bin/codex-autoresearch" || {
    echo "Error: could not mark $REPO_DIR/bin/codex-autoresearch as executable." >&2
    echo "Try: chmod +x \"$REPO_DIR/bin/codex-autoresearch\"" >&2
    exit 1
  }
fi

mkdir -p "$USER_SKILLS_DIR" "$USER_BIN_DIR"
ln -sfn "$REPO_DIR/.agents/skills/autoresearch" "$USER_SKILLS_DIR/autoresearch"

rm -f "$USER_BIN_DIR/codex-autoresearch"
REPO_DIR_Q="$(printf '%q' "$REPO_DIR")"
cat >"$USER_BIN_DIR/codex-autoresearch" <<MSG
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$REPO_DIR_Q
exec bash "\$REPO_DIR/bin/codex-autoresearch" "\$@"
MSG
chmod +x "$USER_BIN_DIR/codex-autoresearch"

cat <<MSG
Installed autoresearch for Codex.

Skill:
  $USER_SKILLS_DIR/autoresearch -> $REPO_DIR/.agents/skills/autoresearch

Wrapper:
  $USER_BIN_DIR/codex-autoresearch (execs $REPO_DIR/bin/codex-autoresearch)

Next steps:
  1. Ensure $USER_BIN_DIR is on your PATH.
  2. In a target repository, run: codex-autoresearch install-agents
  3. Start a loop with: codex-autoresearch "optimize test suite runtime"
  4. Resume with: codex-autoresearch
  5. Pause with: codex-autoresearch off
MSG
