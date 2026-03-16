#!/usr/bin/env bash
# check-prerequisites.sh — lightweight prerequisite check for Transmute Framework
# Runs before every Skill invocation. Warns on missing files; never blocks execution.

# Only run checks if this looks like a Transmute project
if [ ! -d "plancasting/" ]; then
  exit 0
fi

# Inside a Transmute project — check key prerequisites
missing=()

if [ ! -f "CLAUDE.md" ]; then
  missing+=("CLAUDE.md (required for all stages)")
fi

if [ ! -f "plancasting/tech-stack.md" ]; then
  missing+=("plancasting/tech-stack.md (required after Stage 0)")
fi

if [ ${#missing[@]} -gt 0 ]; then
  echo "[transmute] prerequisite warning: missing files:"
  for item in "${missing[@]}"; do
    echo "  - $item"
  done
fi

exit 0
