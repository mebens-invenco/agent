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
- Verification: confirm all acceptance criteria and record results in `acceptance.md`
- Review: open/update PR, address review feedback, advance on merge
- Consolidation: archive and merge research

### Transitions

- Plan requires explicit user approval to exit
- Breakdown, Execution, and Verification can self-transition with guardrails
- Verification runs immediately after Execution when allowed; if verification fails, yield for user input
- In loop mode, proceed to Review only if `review` is allowed; otherwise yield after Verification
- Review is single-use and re-runnable; it advances to Consolidation only when the PR is merged
- Consolidation is manually triggered between development cycles, except when Review detects a merged PR and runs it automatically

### Guardrails

- If `yield.md` exists, stop and return control to the user
- If `.lock` exists and the last loop was autonomous, treat as dirty state

### Story IDs (Linear)

- Story IDs are Linear ticket IDs in the format `eng-xxxx`
- When starting a new story, ask if a Linear ticket exists; if yes, use it
- If none exists, use a temporary story ID (format `temp-001`)
- On Plan -> Breakdown, if the story ID is temporary, create a Linear ticket in team `eng`, assign it to `me`, and rename the story to the Linear ID
- Include an acceptance criteria summary table from `acceptance.md` in the Linear description

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

- Plan + breakdown: single-iteration runner (e.g., `.agent/agent-run-once.sh`)
- Execution + verification + review: loop-until-yield runner (e.g., `.agent/agent-loop.sh`, defaults Allowed stages to `execution,verification,review`)
- Review + consolidation: single-iteration runner (e.g., `.agent/agent-run-once.sh`, Allowed stages `review` or `consolidation`)
- `.agent/agent-run-once.sh` uses `opencode --model` for interactive sessions
- `.agent/agent-loop.sh` uses `opencode run --model --variant` for looping runs (default: `VARIANT=medium`)
- Both runners must pass `.agent/prompt.md` as the first message and include a short run header

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
