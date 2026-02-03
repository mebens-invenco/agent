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

- Discovery: research + story creation
- Design: architecture and implementation notes inside story definition
- Breakdown: story tasks + task graph
- Execution: implement tasks in dependency order
- Verification: verify acceptance criteria
- Consolidation: archive and merge research

### Transitions

- Discovery and Design require explicit user approval to exit
- Breakdown, Execution, and Verification can self-transition with guardrails
- Consolidation is manually triggered between development cycles

### Guardrails

- If `yield.md` exists, stop and return control to the user
- If `.lock` exists and the last loop was autonomous, treat as dirty state
- Thrashing: more than 3 transitions without artifact creation yields to the user

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
- Execution + verification: loop-until-yield runner (e.g., `.agent/agent-loop.sh`, defaults Allowed stages to `execution`)
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
