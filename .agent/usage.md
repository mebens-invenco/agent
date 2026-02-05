# Usage

This document describes how the agent runs. Repo-specific workflows, commands, and environment details belong in `CLAUDE.md`.

## Agent Process

### Stages

- Plan: research + story creation + acceptance criteria + design notes
- Breakdown: story tasks + task graph
- Execution: implement tasks in dependency order
- Verification: confirm acceptance criteria and record results in `acceptance.md`
- Review: open/update PR, address review feedback, commit and push fixes, capture review learnings, advance on merge
- Consolidation: archive and merge research, merge review learnings

### Transitions

- Plan requires explicit user approval to exit
- Breakdown, Execution, and Verification can self-transition
- Review runs only after Verification passes
- Consolidation is manually triggered between development cycles, except when Review detects a merged PR and runs it automatically

### Review Learnings

- Capture review feedback in `.agent/stories/{story-id}/review-learnings.md` as short summaries and abstractions
- Consolidation merges review learnings into the research system (update confidence and applied count)

### Guardrails

- If `.agent/yield.md` exists, stop and return control to the user
- If `.lock` exists and the last loop was autonomous, treat as dirty state

### Story IDs (Linear)

- Story IDs are Linear ticket IDs in the format `eng-xxxx`
- If none exists, use a temporary story ID (format `temp-001`)
- Ticket creation and story renaming happen automatically on Plan -> Breakdown

## Commit Policy

- Commit at the end of each coherent action (especially each execution task)
- Use a conventional commit type while keeping the agent stage tag:

```
{type}: [agent:{stage}] {action_summary}

Artifacts:
- created: {path}
- updated: {path}

Refs: {story-id or task-id}
```

Recommended types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `build`, `ci`, `perf`.

## Test Policy

- If you add or modify tests during a task, run those tests before committing
- If tests fail, fix and rerun until they pass or yield with clear details
