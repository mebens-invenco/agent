#!/usr/bin/env bash
set -euo pipefail

TARGET="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      printf "Usage: %s [target-directory]\n" "$0"
      exit 0
      ;;
    *)
      TARGET="$1"
      shift
      ;;
  esac
done

if [[ ! -d "$TARGET" ]]; then
  printf "Target directory not found: %s\n" "$TARGET" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
SOURCE_AGENT="$SOURCE_ROOT/.agent"

if [[ ! -d "$SOURCE_AGENT" ]]; then
  printf "Source .agent folder not found: %s\n" "$SOURCE_AGENT" >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"
AGENT_DIR="$TARGET/.agent"

ensure_gitignore_entry() {
  local entry="$1"
  local gitignore="$TARGET/.gitignore"
  if [[ ! -f "$gitignore" ]]; then
    printf "%s\n" "$entry" > "$gitignore"
    return 0
  fi
  if ! grep -qxF "$entry" "$gitignore"; then
    printf "%s\n" "$entry" >> "$gitignore"
  fi
}

mkdir -p "$AGENT_DIR"

rsync -a --ignore-existing "$SOURCE_AGENT/" "$AGENT_DIR/"

for file in prompt.md usage.md agent.sh; do
  if [[ -f "$SOURCE_AGENT/$file" ]]; then
    rsync -a "$SOURCE_AGENT/$file" "$AGENT_DIR/$file"
  fi
done

if [[ -f "$AGENT_DIR/agent.sh" ]]; then
  chmod +x "$AGENT_DIR/agent.sh"
fi

ensure_gitignore_entry ".agent/.lock"
ensure_gitignore_entry ".agent/yield.md"

printf "Initialized .agent scaffold in %s\n" "$TARGET"
