#!/usr/bin/env bash
set -euo pipefail

AGENT_DIR="${AGENT_DIR:-.agent}"
PROMPT_PATH="${PROMPT_PATH:-$AGENT_DIR/prompt.md}"
YIELD_PATH="${YIELD_PATH:-$AGENT_DIR/yield.md}"

MODE="${MODE:-}"
LOOP="${LOOP:-}"
ALLOWED_STAGES="${ALLOWED_STAGES:-}"
MODEL="${MODEL:-openai/gpt-5.2-codex}"
VARIANT="${VARIANT:-medium}"

CLI_ONCE="false"
PROMPT_ONLY="false"
ALLOWED_STAGES_SET="false"

usage() {
  cat <<'EOF'
Usage: .agent/agent.sh [options]

Options:
  --once                Run a single iteration (default: loop)
  --prompt-only         Print the prompt and exit
  --allowed-stages STR  Override allowed stages list
  --model STR           Override model (default: openai/gpt-5.2-codex)
  --variant STR         Override variant (default: medium)
  -h, --help            Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --once)
      CLI_ONCE="true"
      shift
      ;;
    --prompt-only)
      PROMPT_ONLY="true"
      shift
      ;;
    --allowed-stages)
      if [[ $# -lt 2 ]]; then
        printf "Missing value for --allowed-stages\n" >&2
        exit 1
      fi
      ALLOWED_STAGES="$2"
      ALLOWED_STAGES_SET="true"
      shift 2
      ;;
    --model)
      if [[ $# -lt 2 ]]; then
        printf "Missing value for --model\n" >&2
        exit 1
      fi
      MODEL="$2"
      shift 2
      ;;
    --variant)
      if [[ $# -lt 2 ]]; then
        printf "Missing value for --variant\n" >&2
        exit 1
      fi
      VARIANT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf "Unknown argument: %s\n" "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$PROMPT_PATH" ]]; then
  printf "Missing prompt file: %s\n" "$PROMPT_PATH" >&2
  exit 1
fi

if [[ "$CLI_ONCE" == "true" ]]; then
  LOOP="once"
fi

RUN_ONCE="false"
if [[ "$LOOP" == "once" ]]; then
  RUN_ONCE="true"
fi

if [[ -z "$LOOP" ]]; then
  if [[ "$RUN_ONCE" == "true" ]]; then
    LOOP="once"
  else
    LOOP="until_yield"
  fi
fi

if [[ -z "$MODE" ]]; then
  if [[ "$RUN_ONCE" == "true" ]]; then
    MODE="plan"
  else
    MODE="autonomous"
  fi
fi

if [[ "$ALLOWED_STAGES_SET" == "false" && -z "$ALLOWED_STAGES" ]]; then
  if [[ "$RUN_ONCE" == "true" ]]; then
    ALLOWED_STAGES="plan"
  else
    ALLOWED_STAGES="execution,verification,review"
  fi
fi

build_prompt() {
  printf "Mode: %s\n" "$MODE"
  printf "Loop: %s\n" "$LOOP"
  if [[ -n "$ALLOWED_STAGES" ]]; then
    printf "Allowed stages: %s\n\n" "$ALLOWED_STAGES"
  else
    printf "Allowed stages: none\n\n"
  fi
  cat "$PROMPT_PATH"
}

run_once() {
  build_prompt | opencode run --model "$MODEL" --variant "$VARIANT"
}

if [[ "$PROMPT_ONLY" == "true" ]]; then
  build_prompt
  exit 0
fi

if [[ "$LOOP" == "once" ]]; then
  run_once
  exit 0
fi

ITERATION=0
while true; do
  if [[ -f "$YIELD_PATH" ]]; then
    exit 0
  fi
  ITERATION=$((ITERATION + 1))
  printf "Starting loop iteration %s at %s.\n" "$ITERATION" "$(date -Is)"
  run_once
  printf "Finished loop iteration %s at %s.\n" "$ITERATION" "$(date -Is)"
done
