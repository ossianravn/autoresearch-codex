#!/usr/bin/env bash
set -euo pipefail

USER_SKILLS_DIR="$HOME/.agents/skills"
USER_BIN_DIR="$HOME/.local/bin"

if [ -L "$USER_SKILLS_DIR/autoresearch" ] || [ -d "$USER_SKILLS_DIR/autoresearch" ]; then
  rm -rf "$USER_SKILLS_DIR/autoresearch"
  echo "Removed $USER_SKILLS_DIR/autoresearch"
fi

if [ -L "$USER_BIN_DIR/codex-autoresearch" ] || [ -f "$USER_BIN_DIR/codex-autoresearch" ]; then
  rm -f "$USER_BIN_DIR/codex-autoresearch"
  echo "Removed $USER_BIN_DIR/codex-autoresearch"
fi

echo "Done. Any AGENTS.md blocks previously added to target repositories were left in place intentionally."
