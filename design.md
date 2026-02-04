# AI Agent Development Process Design

> **Document Version:** 1.0  
> **Created:** 2025-01-29  
> **Purpose:** Complete specification for an iterative AI agent process that translates desired software system behavior changes into executable plans.

---

## Table of Contents

1. [Philosophy & Principles](#philosophy--principles)
2. [Process Overview](#process-overview)
3. [File Structure](#file-structure)
4. [Bootstrap & Runner Scripts](#bootstrap--runner-scripts)
5. [Stage Definitions](#stage-definitions)
6. [Loop Mechanics](#loop-mechanics)
7. [State Management](#state-management)
8. [Artifact System](#artifact-system)
9. [Research System](#research-system)
10. [Templates](#templates)
11. [What's Left to Define](#whats-left-to-define)

---

## Philosophy & Principles

### Core Ideas

1. **Externalized Memory** — Artifacts become the agent's persistent memory across context windows. This transforms the LLM's ephemeral context into durable knowledge.

2. **Self-Documenting Process** — The artifact trail becomes both execution guidance AND audit trail. You can understand *why* decisions were made by reading the chain.

3. **Convergence Through Research** — Starting generic but crystallizing preferences over time mirrors how human teams develop conventions.

4. **Small Context Windows** — The agent works in small iterative loops to maintain LLM performance. Multiple loops occur within stages before transitioning.

5. **Two-Layer Artifacts** — Most artifacts have a README.md (executive summary/head) and a detailed body file. Tasks are single-file for speed and clarity.

6. **Generic but Convergent** — The process suits any software stack, language, or architecture, but research findings cause it to converge on specific patterns over time.

### Design Tensions & Resolutions

| Tension | Resolution |
|---------|------------|
| Context minimization vs. decision quality | Two-layer artifacts (README + body) allow fast relevance scanning |
| Deterministic verification is aspirational | Use automated tests, linting, strong types, SCA where possible; acknowledge manual verification honestly |
| Stage fluidity vs. progress tracking | Track current stage and last loop; require user approval for collaborative stages |

---

## Process Overview

### Stages

| Stage | Mode | Purpose | Artifacts | Exit Condition |
|-------|------|---------|-----------|----------------|
| **Plan** | Interactive only | Research, story definition, acceptance criteria, and design guidance | .agent/research/*, .agent/stories/* | User approval |
| **Breakdown** | Autonomous capable | Decompose into atomic, verifiable tasks | .agent/stories/*/tasks/* | All tasks defined |
| **Execution** | Autonomous capable | Implement tasks in dependency order | Code changes | All tasks complete |
| **Verification** | Autonomous capable | Confirm acceptance criteria and record results in acceptance | .agent/stories/*/acceptance.md | All AC verified or deferred |
| **Review** | Autonomous capable (single-use) | Create/update PR, address review feedback, and capture review learnings | PR, review learnings, state updates | PR merged, then run Consolidation |
| **Consolidation** | Interactive only (auto-run on merged PR) | Archive stale artifacts and merge related research | Archives, merges | User approval or Review auto-run complete |

### Stage Transitions

- The agent may move from one stage to any other stage at any time
- If `allowed_stages` is set in state, transitions must stay within that list
- **Plan** requires explicit user sign-off to exit
- **Breakdown**, **Execution**, and **Verification** can self-transition with guardrails
- **Verification** runs immediately after Execution when allowed; if verification fails, yield for user input
- On Plan -> Breakdown, if the story ID is temporary, create the Linear ticket and rename the story before proceeding
- **Review** runs as a single-use stage and is re-runnable to update the PR or address feedback
- **Review** advances to **Consolidation** only when the PR is merged
- **Consolidation** is manually triggered by user between development cycles, except when Review detects a merged PR and runs it automatically

### Operating Modes

| Mode | Detection | Behavior |
|------|-----------|----------|
| **Interactive** | Default. Agent assumes interactive unless told otherwise. | Agent returns control to user after each loop. |
| **Autonomous** | Prompt explicitly indicates autonomous mode (e.g., from loop.sh script). | Agent continues looping until work complete or yield required. |

### Planning Mode (Stage Lock)

Plan mode is a stage-locked workflow used to define stories, acceptance criteria, and design without entering implementation.

- Set `allowed_stages` to `[plan]` in state (or in the runner header) before the run
- The agent must not transition to Breakdown, Execution, Review, or Consolidation while the lock is active
- Plan runs are typically single-iteration (runner executes once and returns)
- To proceed, update `allowed_stages` to include `breakdown` or clear the lock entirely

### Story IDs (Linear)

- Story IDs are Linear ticket IDs in the format `eng-xxxx`
- When starting a new story, ask if a Linear ticket exists; if yes, use it as the story ID
- If none exists, use a temporary story ID in the format `temp-001` during Plan
- On Plan -> Breakdown, if the story ID is temporary, create a Linear ticket (team `eng`, assignee `me`) and rename the story to the Linear ID
- Include an acceptance criteria summary table from `acceptance.md` in the Linear description
- If Linear creation fails or is blocked, yield and stop before Breakdown

---

## File Structure

```
.agent/
├── state.yaml                      # Current state: stage, focus, review
├── usage.md                        # Day-to-day: commands, tooling, workflows
├── prompt.md                       # Runner bootstrap prompt (first message)
├── agent.sh                        # Unified runner (loop by default, --once for single run)
├── yield.md                        # Singular. Exists = agent needs user. Delete to resume.
├── .lock                           # Uncommitted. Exists during autonomous loop execution.
│
├── templates/
│   ├── _template_research.md       # Research body template
│   ├── _template_story_README.md   # Story README template
│   ├── _template_story_definition.md
│   ├── _template_acceptance.md     # Acceptance criteria template
│   ├── _template_review_learnings.md
│   ├── _template_task.md
│   ├── _template_task_graph.md
│
├── research/
│   ├── README.md                   # Research index
│   ├── internal/                   # Code analysis + internal learnings
│   │   └── {topic-slug}/
│   │       ├── README.md           # Summary, links
│   │       └── {topic-slug}.md     # Full findings
│   └── external/                   # Web research
│       └── {topic-slug}/
│           ├── README.md
│           └── {topic-slug}.md
│
├── stories/
│   ├── README.md                   # Stories index
│   ├── {story-id}/
│   │   ├── README.md               # Story summary, status, links
│   │   ├── definition.md           # Full story, context, scope, design
│   │   ├── acceptance.md           # Testable acceptance criteria
│   │   ├── tasks/
│   │   │   ├── task-graph.md       # Execution order, dependencies
│   │   │   └── {task-id}.md
│   │   ├── review-learnings.md     # Review comment summaries + abstractions
│   └── _archive/                   # Completed/superseded stories
│       └── README.md
│
```

---

## Bootstrap & Runner Scripts

### Bootstrap Sequence

On first run in a new repo:

1. Create the `.agent/` structure and `templates/`
2. Create index files: `.agent/research/README.md`, `.agent/stories/README.md`
3. Create `state.yaml` with default plan stage
4. Create `usage.md`
5. Create `prompt.md` from the bootstrap instructions
6. Optionally add `.agent/.lock` and `yield.md` to `.gitignore`

### Setup Script (agent-setup.sh)

Recommended behavior:

- Idempotent: create missing files only
- Do not overwrite existing content
- Allow targeting any repo root (default: current directory)
- Optionally update `.gitignore` with `.agent/.lock` and `yield.md`

### Runner Scripts

Recommended runner:

- `.agent/agent.sh` — unified runner (loop by default, Allowed stages `execution,verification,review`)
- Use `--once` for single-iteration runs (defaults to plan; expand Allowed stages to include breakdown, review, or consolidation)
- Use `--allowed-stages` to override the allowed stages list
- Uses `opencode run --model --variant` for all runs (default: `MODEL=openai/gpt-5.2-codex`, `VARIANT=medium`)
- Use `--prompt-only` to print the prompt without executing

The runner should pass `prompt.md` as the first message. Include a short run header so the agent knows the mode and lock state.

Example run header usage:

```bash
MODE="plan"
LOOP="once"
ALLOWED_STAGES="plan"

{
  printf "Mode: %s\n" "$MODE"
  printf "Loop: %s\n" "$LOOP"
  printf "Allowed stages: %s\n\n" "$ALLOWED_STAGES"
  cat .agent/prompt.md
} | opencode run
```

Execution loop sketch:

```bash
while true; do
  if [[ -f .agent/yield.md ]]; then
    exit 0
  fi

  MODE="autonomous"
  LOOP="until_yield"
  ALLOWED_STAGES="execution,verification,review"

  {
    printf "Mode: %s\n" "$MODE"
    printf "Loop: %s\n" "$LOOP"
    printf "Allowed stages: %s\n\n" "$ALLOWED_STAGES"
    cat .agent/prompt.md
  } | opencode run
done
```

Review single-run sketch:

```bash
MODE="review"
LOOP="once"
ALLOWED_STAGES="review"

{
  printf "Mode: %s\n" "$MODE"
  printf "Loop: %s\n" "$LOOP"
  printf "Allowed stages: %s\n\n" "$ALLOWED_STAGES"
  cat .agent/prompt.md
} | opencode run
```

---

## Stage Definitions

### Plan Stage

**Mode:** Interactive only  
**Purpose:** Research and collaborate with user to define stories, acceptance criteria, and design guidance.

**Activities:**
- Internal research (code analysis of existing system)
- External research (web research on patterns, technologies, best practices)
- Collaborative story definition with user
- Ask whether a Linear ticket exists for the story
- If no Linear ticket exists, assign a temporary story ID (format `temp-001`)
- Acceptance criteria creation
- Architectural decision making and pattern selection
- Update story definition with design notes
- User collaboration on trade-offs

**Artifacts Produced:**
- `.agent/research/internal/{topic}/README.md` + `{topic}.md`
- `.agent/research/external/{topic}/README.md` + `{topic}.md`
- `.agent/stories/{story-id}/README.md`
- `.agent/stories/{story-id}/definition.md`
- `.agent/stories/{story-id}/acceptance.md`

**Exit Condition:** User explicitly approves that planning work (stories, acceptance criteria, design) is complete.

### Breakdown Stage

**Mode:** Autonomous capable  
**Purpose:** Decompose approved story definitions into atomic, verifiable tasks. Produce task artifacts and dependency graph.

**Activities:**
- If the story ID is temporary, create a Linear ticket (team `eng`, assignee `me`), rename the story to the Linear ID, and update links, indices, and state
- Analyze story definitions and acceptance criteria
- Create atomic tasks (small, deterministically verifiable)
- Define task dependencies
- Create verification approach for each task

**Artifacts Produced:**
- `.agent/stories/{story-id}/tasks/{task-id}.md`
- `.agent/stories/{story-id}/tasks/task-graph.md`

**Exit Condition:** All tasks are defined and dependency graph is complete.

### Execution Stage

**Mode:** Autonomous capable  
**Purpose:** Implement tasks in dependency order.

**Activities:**
- Execute tasks in phase order per `.agent/stories/{story-id}/tasks/task-graph.md`
- Verify each task deterministically (tests, linting, type checking)
- Update task status
- If task verification fails, attempt to fix; if cannot fix, yield

**Artifacts Produced:**
- Code and configuration changes in the repository
- Task status updates

**Exit Condition:** All tasks complete.

### Verification Stage

**Mode:** Autonomous capable  
**Purpose:** Confirm all acceptance criteria and record verification results.

**Timing:** Typically runs immediately after Execution within the same loop when allowed.

**Activities:**
- Read `.agent/stories/{story-id}/acceptance.md`
- Confirm each acceptance criterion
- Run automated tests where possible
- Document manual verification requirements
- Record results and evidence in `acceptance.md`
- If verification fails or is blocked, yield (blocker before Review)

**Artifacts Produced:**
- `.agent/stories/{story-id}/acceptance.md`

**Exit Condition:** All acceptance criteria verified or explicitly deferred (with reason).

### Review Stage

**Mode:** Autonomous capable (single-use)  
**Purpose:** Push the current branch, create or update a PR, address review feedback, capture review learnings, and advance to consolidation when the PR is merged.

**Activities:**
- Push the current branch to the remote
- Discover an existing PR for the current branch; if none exists, create one with `gh pr create`
- If a PR template exists, populate it with the story summary, acceptance verification results, tests run, and known risks
- If a PR exists, pull unresolved review threads and implement requested changes
- Commit and push changes after addressing feedback
- Synthesize review comments into short summaries and abstractions; record in `.agent/stories/{story-id}/review-learnings.md`
- If no review comments exist, record that in `review-learnings.md` with date
- If a retest request template exists and a retest is needed, post a PR comment using that template
- Check PR status (open/merged) and approvals; record PR metadata in state
- If PR is merged, transition to Consolidation and execute it immediately in the same run

**Template Handling:**
- PR templates: `.github/PULL_REQUEST_TEMPLATE.md`, `.github/pull_request_template.md`, or `.github/PULL_REQUEST_TEMPLATE/*.md` (prefer `default.md`, else first by name)
- Retest request templates: any `.github/*retest*template*.md` (case-insensitive); use when requesting CI retest

**Artifacts Produced:**
- PR updates (title/body/comments)
- Code changes + commits (when addressing review feedback)
- `.agent/stories/{story-id}/review-learnings.md`
- `state.yaml` updates (PR metadata/status)

**Exit Condition:** PR merged; Review transitions to Consolidation and runs it immediately.

**Notes:** Review is re-runnable and always returns control after a single pass. If the PR is open and approved but not merged, report status and suggest merging; otherwise report outstanding reviews and stop.

**Constraint:** Review runs only after Verification has passed.

### Consolidation Stage

**Mode:** Interactive only (auto-run when Review detects merged PR)  
**Purpose:** Archive stale artifacts and merge related research. Triggered manually by user between development cycles, or automatically after Review detects a merged PR.

**Activities:**
- Archive superseded/completed stories to `_archive/`
- Merge overlapping research artifacts (with user approval)
- Consolidate research learnings (merge duplicates, update confidence)
- Merge review learnings into research artifacts (update confidence, applied count)
- Clean up dead links in indices
- Reset task graph for next cycle

**Exit Condition:** User approves consolidation is complete. When invoked automatically from Review on a merged PR, the stage completes after actions are executed and reported.

---

## Loop Mechanics

### Loop Structure

Each iteration of the agent follows this structure:

```
LOOP START
│
├─→ 0. PRECHECK
│      - If yield.md exists: READ it, STOP, inform user
│      - If .lock exists AND last_loop.mode == autonomous:
│          - Dirty state detected
│          - If interactive now: Inform user, suggest `git checkout -- .`
│          - If autonomous now: Create yield.md explaining dirty state, STOP
│      - If autonomous mode: Create .lock file
│
├─→ 1. ORIENT
│      - Read state.yaml
│      - Read relevant index (based on current stage)
│      - Read README.md files to find focus
│      - In plan/breakdown: read the active story README, definition, and acceptance
│      - In execution: read task-graph.md, then only the active task file; avoid other task files unless a dependency blocks progress or the active task explicitly references them
│      - In verification: read acceptance criteria and current results
│      - In review: identify PR status, unresolved review threads, and applicable templates
│      - Load body files only when needed
│
├─→ 2. DECIDE
│      - Choose ONE action appropriate to stage
│      - If stuck:
│          - If interactive mode: Ask user
│          - If autonomous mode: Create yield.md, STOP
│
├─→ 3. ACT
│      - Execute the action
│      - Produce/update artifacts (README.md + body files)
│
├─→ 4. RECORD
│      - Update relevant index
│      - Update state.yaml (current stage, focus, review metadata, allowed stages)
│      - Propose research updates if patterns observed
│
├─→ 5. COMMIT
│      - Git commit with structured message
│      - Git push to remote
│      - Update state.yaml (last_loop.mode, at, action, commit)
│      - Delete .lock file (if exists)
│
├─→ 6. CONTINUE / YIELD
│      - If stage complete AND requires user sign-off (plan or consolidation): yield for approval
│      - If execution completes and `verification` is allowed, proceed to verification in the same run
│      - If verification passes and `review` is allowed, proceed to review in the same run; if `review` is not allowed, return control or yield (autonomous mode)
│      - Yield only after review or when blocked
│      - If autonomous AND work remains: continue to next loop
│      - If interactive: return control to user
│
LOOP END
```

### Key Constraint

**One loop = one coherent action.** Not "research everything" but "research authentication patterns for this stack."

### Review Run (Single-use)

Review runs are always single-use. Each invocation performs one review pass, updates the PR if needed, and returns control. If the PR is merged, the run transitions to Consolidation and executes it immediately.

### Git Commit Format

Use a conventional commit type while keeping the agent stage tag:

```
{type}: [agent:{stage}] {action_summary}

Artifacts:
- created: {path}
- updated: {path}

Refs: {story-id or task-id}
```

Recommended types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `build`, `ci`, `perf`.

### Commit Message Examples

Plan:

```
docs: [agent:plan] establish auth story and design baseline

Artifacts:
- created: .agent/research/internal/existing-auth/README.md
- created: .agent/research/internal/existing-auth/existing-auth.md
- created: .agent/stories/eng-1234/README.md
- created: .agent/stories/eng-1234/definition.md
- created: .agent/stories/eng-1234/acceptance.md

Refs: eng-1234
```

Breakdown:

```
docs: [agent:breakdown] define story tasks and dependency graph

Artifacts:
- created: .agent/stories/eng-1234/tasks/task-graph.md
- created: .agent/stories/eng-1234/tasks/task-001.md
- created: .agent/stories/eng-1234/tasks/task-002.md

Refs: eng-1234
```

Execution:

```
feat: [agent:execution] implement auth persistence layer

Artifacts:
- updated: src/auth/storage.ts
- updated: .agent/stories/eng-1234/tasks/task-003.md

Refs: task-003
```

Verification:

```
test: [agent:verification] confirm auth acceptance criteria

Artifacts:
- updated: .agent/stories/eng-1234/acceptance.md

Refs: eng-1234
```

Review:

```
fix: [agent:review] address auth review feedback

Artifacts:
- updated: .agent/state.yaml
- updated: src/auth/storage.ts

Refs: eng-1234
```

Consolidation:

```
chore: [agent:consolidation] merge auth research and archive superseded story

Artifacts:
- updated: .agent/research/internal/existing-auth/existing-auth.md
- updated: .agent/research/README.md
- updated: .agent/stories/_archive/README.md

Refs: eng-1234
```

---

## State Management

### state.yaml Schema

```yaml
# .agent/state.yaml

current:
  stage: plan           # plan | breakdown | execution | verification | review | consolidation
  allowed_stages: []    # optional stage lock, empty means no lock
  focus:
    story: null         # active story id
    task: null          # active task id during execution
  review:
    pr_number: null
    pr_url: null
    pr_state: null      # open | merged | closed
    last_checked: null

last_loop:
  mode: interactive     # interactive | autonomous
  at: "2025-01-29T10:00:00.000Z"
  action: "initialized process"
  commit: null
```

### Stage Locks

If `allowed_stages` is non-empty, the agent must not transition outside that list. This is used for plan mode and for safe resumption after interruptions. If a runner provides a run header with `Allowed stages`, the agent should apply that lock and persist it in state.

### yield.md

A singular file. If it exists, the agent must stop and wait for user.

```markdown
# Yield

> **Created:** 2025-01-29T10:30:45.000Z  
> **Stage:** plan  
> **Last loop mode:** autonomous  

## What I Was Doing

{Description of current work}

## Why I Stopped

{Clear explanation of the blocker}

## What I Need From You

{Specific questions or actions needed}

## How to Resume

1. Respond to the questions above (in chat or edit this file)
2. Delete this file
3. Run the agent again

## Context for Resumption

{What the agent will do when resumed}
```

### .lock File

- Lives in `.agent/.lock`
- Added to `.gitignore` (never committed)
- Created at start of autonomous loop, deleted at end
- If present on next run with `last_loop.mode == autonomous`, indicates dirty state (interrupted mid-loop)

```
# .agent/.lock
started: 2025-01-29T10:45:12.000Z
loop: 47
action: executing task-012
```

### Dirty State Handling

If `.lock` exists and last loop was autonomous:
- **Interactive mode now:** Inform user, suggest `git checkout -- .` to reset
- **Autonomous mode now:** Create yield.md explaining dirty state, stop

---

## Artifact System

### Two-Layer Structure

Most artifacts have:
1. **README.md** — Executive summary (the "head"). Enough for agent to determine relevance.
2. **{name}.md** — Full details (the "body"). Loaded only when needed.

Tasks are single-file artifacts stored under `.agent/stories/{story-id}/tasks/` and linked from the task graph.

### Index Files

Each top-level artifact category has a `README.md` index at its root with a table linking to all artifacts. Tasks are indexed in each story's task graph.

```markdown
# Research Index

> Last updated: 2025-01-29T14:00:00.000Z

## Internal Research

| Topic | Summary | Status | Path |
|-------|---------|--------|------|
| existing-auth | Current auth implementation | complete | [→](./internal/existing-auth/README.md) |

## External Research

| Topic | Summary | Status | Path |
|-------|---------|--------|------|
| jwt-best-practices | JWT security patterns | complete | [→](./external/jwt-best-practices/README.md) |
```

### Artifact Linking Convention

Artifacts reference each other via relative markdown links:

Story IDs should use Linear ticket IDs (`eng-xxxx`). Temporary IDs (`temp-001`) are allowed during Plan and must be replaced on Plan -> Breakdown.

```markdown
## Links

- **Story:** [eng-1234](../README.md)
- **Task Graph:** [execution plan](./task-graph.md)
- **Depends on:** [task-000](./task-000.md)
- **Related research:** [existing-auth](../../../research/internal/existing-auth/README.md)
```

### Task Graph

A single file `.agent/stories/{story-id}/tasks/task-graph.md` defines execution order, dependencies, and the current/next task pointer. Each row includes a one-line summary so the next task can be chosen without opening other task files:

```markdown
# Task Graph

> **Generated:** 2025-01-29T11:00:00.000Z  
> **Story:** [eng-1234](../README.md)  
> **Current task:** task-003  
> **Next task:** task-004

## Execution Order

Tasks execute in phases. All tasks in a phase must complete before the next phase begins. Each task row includes a one-line summary.

### Phase 1: Foundation

| Task | Summary | Status | Blocked By |
|------|---------|--------|------------|
| [task-001](./task-001.md) | Set up base project structure | complete | none |
| [task-002](./task-002.md) | Configure TypeScript + ESLint | complete | none |

### Phase 2: Core Infrastructure

| Task | Summary | Status | Blocked By |
|------|---------|--------|------------|
| [task-003](./task-003.md) | Database connection module | in-progress | none |
| [task-004](./task-004.md) | Base error types | pending | none |

### Phase 3: Feature Implementation

| Task | Summary | Status | Blocked By |
|------|---------|--------|------------|
| [task-005](./task-005.md) | User repository | pending | task-003, task-004 |

### Acceptance Verification

Verification results live inside `.agent/stories/{story-id}/acceptance.md` under each criterion:

```markdown
## AC-001: {Short description}

**Given** {precondition}  
**When** {action}  
**Then** {expected outcome}

**Verification:** {automated | manual}  
**Result:** {pass | fail | pending | deferred}  
**Evidence:** {test output, logs, or link}
```

---

## Research System

### Purpose

Research captures internal and external findings, including learnings and preferences. The agent consults relevant research to maintain consistency and apply established patterns.

### Structure

1. **Root:** `.agent/research/README.md` — Index of research topics
2. **Topics:** `.agent/research/internal/{topic}/` and `.agent/research/external/{topic}/`
3. **Topic files:** `README.md` + `{topic}.md` for full details

### Research Index Fields

Recommended columns for `.agent/research/README.md`:

- Topic
- Summary
- Type (internal | external)
- Status
- Updated
- Path

### Learnings Inside Research

Each research body can include learnings with explicit metadata:

- **Confidence:** {established | emerging | experimental | low}
- **Applied count:** {N}
- **Source:** {user preference | observed pattern | agent hypothesis}
- **Conflicts:** links to related or superseded research

### Review Learnings

Review learnings are captured per story in `.agent/stories/{story-id}/review-learnings.md`. Consolidation merges these learnings into the research system, updating confidence and applied counts, and linking to relevant topics.

### Confidence Levels

| Level | Meaning | Agent Behavior |
|-------|---------|----------------|
| **established** | Confirmed by user or used successfully 3+ times | Follow without question |
| **emerging** | Pattern observed 1-2 times, not yet confirmed | Follow, note in commit if relevant |
| **experimental** | Agent hypothesis, untested | Proceed cautiously, validate outcome |
| **low** | Uncertain, possibly conflicting information | If multiple low-confidence learnings block progress, yield to user |

### Confidence Progression

```
experimental → emerging → established
                 ↓
            (if invalidated)
                 ↓
             archived
```

### How Confidence Changes

- **experimental → emerging:** Learning applied once successfully
- **emerging → established:** User confirms OR learning applied 3+ times without issues
- **Any → low:** Conflicting evidence discovered
- **Any → archived:** User explicitly invalidates OR superseded by new learning

### When to Yield

The agent yields to user if:
- 3+ low-confidence research learnings are relevant to the current task
- A learning directly contradicts user instruction
- Agent is unsure which of two conflicting learnings applies

### Agent Behavior

- Agent should NOT yield just to propose research updates
- Agent ALWAYS captures research learnings when patterns are observed
- Agent assigns confidence level based on evidence
- Agent updates confidence as learnings are applied
- Only yield when low-confidence learnings are blocking progress

---

## Templates

### Research Template

```markdown
# {Topic Title}

> **Type:** {internal | external}  
> **Status:** {draft | active | complete | superseded}  
> **Created:** {YYYY-MM-DDTHH:MM:SS.sssZ}  
> **Updated:** {YYYY-MM-DDTHH:MM:SS.sssZ}

## Summary

{2-4 sentences. Enough to determine relevance without loading full details.}

## Findings

{Key findings, observations, or references}

## Learnings (if any)

### {Learning Title}

- **Pattern:** {clear description of the preferred pattern}
- **Rationale:** {why this is preferred}
- **Source:** {user preference | observed pattern | agent hypothesis}
- **Confidence:** {established | emerging | experimental | low}
- **Applied count:** {N}
- **Conflicts:** {links to related or superseded research}

## Sources

- {links, citations, or artifacts}
```

### Story README Template

```markdown
# {Story ID}: {Title}

> **Status:** {draft | active | complete | superseded}  
> **Created:** {YYYY-MM-DDTHH:MM:SS.sssZ}  
> **Updated:** {YYYY-MM-DDTHH:MM:SS.sssZ}

## Summary

{2-3 sentence description of what this story achieves from user perspective}

## Links

- **Definition:** [Full story details](./definition.md)
- **Acceptance Criteria:** [Testable criteria](./acceptance.md)
- **Review Learnings:** [review learnings](./review-learnings.md)
- **Tasks:** [task graph](./tasks/task-graph.md)
- **Research:** [related research](../../research/internal/{topic}/README.md)
- **Linear:** {eng-xxxx}
```

### Story Definition Template

```markdown
# {Story ID}: Definition

## User Story

As a {persona},  
I want {capability},  
so that {benefit}.

## Context

{Background information, business context, why this matters}

## Scope

### In Scope

- {Specific capability 1}
- {Specific capability 2}

### Out of Scope

- {Explicitly excluded item 1}
- {Explicitly excluded item 2}

## Design / Approach

{Architecture, patterns, and implementation guidance captured for this story}

## Dependencies

- {External system, API, or other story this depends on}

## Assumptions

- {Assumption about user, system, or environment}

## Open Questions

- [ ] {Question that needs resolution}

## Research References

- [internal research](../../research/internal/{topic}/README.md)
- [external research](../../research/external/{topic}/README.md)
```

### Acceptance Criteria Template

```markdown
# {Story ID}: Acceptance Criteria

## Format

Each criterion follows the pattern:
- **Given** {precondition}
- **When** {action}
- **Then** {expected outcome}
- **Verification:** {automated | manual}
- **Result:** {pass | fail | pending | deferred}
- **Evidence:** {test output, logs, or link}

---

## AC-001: {Short description}

**Given** {precondition}  
**When** {action}  
**Then** {expected outcome}

**Verification:** {automated | manual}  
**Test location:** `{path to test file}` (if automated)  
**Result:** {pass | fail | pending | deferred}  
**Evidence:** {test output, logs, or link}  
**Notes:** {any clarification}

---

## Summary

| AC | Description | Method | Result | Priority |
|----|-------------|--------|--------|----------|
| AC-001 | {desc} | automated | pending | must |
| AC-002 | {desc} | manual | pending | should |
```

### Review Learnings Template

```markdown
# {Story ID}: Review Learnings

> **PR:** {pr-url}  \
> **Captured:** {YYYY-MM-DDTHH:MM:SS.sssZ}  \
> **Status:** {draft | consolidated}

## Comment Summaries

{Short summaries of review comments. Include thread links or quoted excerpts.}

## Abstractions / Learnings

### {Learning Title}

- **Summary:** {short abstraction derived from comments}
- **Rationale:** {why this matters}
- **Source:** {review feedback | user preference}
- **Confidence:** {established | emerging | experimental | low}
- **Applied count:** {N}
- **Related research:** {links if any}

## Follow-ups

- {Any open questions, recommended research updates, or changes to apply next time}
```

### Task Template

```markdown
# {Task ID}: {Title}

> **Status:** {pending | in-progress | complete | blocked}  
> **Created:** {YYYY-MM-DDTHH:MM:SS.sssZ}  
> **Updated:** {YYYY-MM-DDTHH:MM:SS.sssZ}

## Summary

{One sentence: what this task accomplishes}

## Links

- **Story:** [eng-1234](../README.md)
- **Phase:** {N} (see [task-graph](./task-graph.md))
- **Depends on:** [task-000](./task-000.md)
- **Related research:** [topic](../../../research/internal/{topic}/README.md)

## Context

{Why this task exists, what it enables, any relevant background}

## Instructions

{Step-by-step implementation guidance}

1. ...
2. ...
3. ...

## Files to Create/Modify

- `src/path/to/file.ts` — {purpose}
- `tests/path/to/file.test.ts` — {what to test}

## Verification

**Type:** {automated | manual}

{If automated:}
- Run: `{command}`
- Expected: {outcome}

{If manual:}
- Steps to verify manually
- Expected observation

## Edge Cases

- {Edge case 1 and how to handle}
- {Edge case 2 and how to handle}

## Done When

- [ ] {Concrete checklist item}
- [ ] {Another checklist item}
- [ ] Verification passes
```

### Task Graph Template

```markdown
# Task Graph

> **Generated:** {YYYY-MM-DDTHH:MM:SS.sssZ}  
> **Story:** [eng-1234](../README.md)  
> **Current task:** {task-id | none}  
> **Next task:** {task-id | none}

## Execution Order

Tasks execute in phases. All tasks in a phase must complete before the next phase begins. Each task row includes a one-line summary.

### Phase 1: Foundation

| Task | Summary | Status | Blocked By |
|------|---------|--------|------------|
| [task-001](./task-001.md) | {one-line summary} | pending | none |

### Phase 2: Core Infrastructure

| Task | Summary | Status | Blocked By |
|------|---------|--------|------------|
| [task-002](./task-002.md) | {one-line summary} | pending | task-001 |

```

### usage.md Template

```markdown
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

## Runner Scripts

- `.agent/agent.sh` is the unified runner (default loop-until-yield, Allowed stages `execution,verification,review`)
- Use `--once` for single-iteration runs (defaults to plan; expand Allowed stages to include breakdown, review, or consolidation)
- Use `--allowed-stages` to override the allowed stages list
- Use `--prompt-only` to print the prompt without executing
- The runner must pass `.agent/prompt.md` as the first message and include a short run header

## Project Structure

```
src/
├── {folder}/       # {description}
└── {folder}/       # {description}
```

## Environment

{Environment setup instructions}

## Testing Conventions

{Testing patterns and locations}

## Deployment

{Deployment information or link}
```
