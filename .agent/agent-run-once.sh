#!/usr/bin/env bash
set -euo pipefail

AGENT_DIR="${AGENT_DIR:-.agent}"
PROMPT_PATH="${PROMPT_PATH:-$AGENT_DIR/prompt.md}"
MODE="${MODE:-plan}"
LOOP="once"
ALLOWED_STAGES="${ALLOWED_STAGES:-plan}"
MODEL="${MODEL:-openai/gpt-5.2-codex}"

if [[ ! -f "$PROMPT_PATH" ]]; then
  printf "Missing prompt file: %s\n" "$PROMPT_PATH" >&2
  exit 1
fi

{
  printf "Mode: %s\n" "$MODE"
  printf "Loop: %s\n" "$LOOP"
  if [[ -n "$ALLOWED_STAGES" ]]; then
    printf "Allowed stages: %s\n\n" "$ALLOWED_STAGES"
  else
    printf "Allowed stages: none\n\n"
  fi
  cat "$PROMPT_PATH"
} | opencode --model "$MODEL"
