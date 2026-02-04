# Usage

This document describes day-to-day development workflows for this project.

## Quick Reference

| Action | Command |
|--------|---------|
| Run dev server | `{command}` |
| Run all tests | `{command}` |
| Run unit tests | `{command}` |
| Run integration tests | `{command}` |
| Lint | `{command}` |
| Type check | `{command}` |
| Build | `{command}` |

## Development Workflow

{Standard workflow steps}

## Agent Process

### Stages

- Plan: research + story creation + acceptance criteria + design notes
- Breakdown: story tasks + task graph
- Execution: implement tasks in dependency order
- Verification: confirm acceptance criteria and record results in `acceptance.md`
- Review: open/update PR, address review feedback, advance on merge
- Consolidation: archive and merge research

### Transitions

- Plan requires explicit user approval to exit
- Breakdown, Execution, and Verification can self-transition
- Review runs only after Verification passes
- Consolidation is manually triggered between development cycles, except when Review detects a merged PR and runs it automatically

### Guardrails

- If `yield.md` exists, stop and return control to the user
- If `.lock` exists and the last loop was autonomous, treat as dirty state

### Story IDs (Linear)

- Story IDs are Linear ticket IDs in the format `eng-xxxx`
- If none exists, use a temporary story ID (format `temp-001`)
- Ticket creation and story renaming happen automatically on Plan -> Breakdown

## Commit Policy

- Commit at the end of each coherent action (especially each execution task)
- Use the structured commit format:

```
[agent:{stage}] {action_summary}

Artifacts:
- created: {path}
- updated: {path}

Refs: {story-id or task-id}
```

## Test Policy

- If you add or modify tests during a task, run those tests before committing
- If tests fail, fix and rerun until they pass or yield with clear details

## Runner Scripts

- `.agent/agent.sh` is the unified runner (default loop-until-yield, Allowed stages `execution,verification,review`)
- Use `--once` for single-iteration runs (defaults to plan; expand Allowed stages to include breakdown, review, or consolidation)
- Use `--allowed-stages` to override the allowed stages list
- Uses `opencode run --model --variant` for all runs (default: `MODEL=openai/gpt-5.2-codex`, `VARIANT=medium`)
- Use `--prompt-only` to print the prompt without executing
- Loop runs announce iteration number and ISO-8601 timestamps
- The runner must pass `.agent/prompt.md` as the first message and include a short run header

## Project Structure

```
src/
|- {folder}/       # {description}
`- {folder}/       # {description}
```

## Environment

{Environment setup instructions}

## Testing Conventions

{Testing patterns and locations}

## Deployment

{Deployment information or link}
