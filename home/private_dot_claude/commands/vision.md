---
description: "Turn the current idea into a claude-backlog vision and roadmap item"
argument-hint: "[optional title or focus]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch, Skill]
---

Create a `claude-backlog` task from the user's current idea or the recent conversation context.

Use the `claude-backlog` system as the source of truth:

- Data root: `~/.claude/local/backlog/`
- File shape: `task-NNN - slug.md`
- ID rule: scan `~/.claude/local/backlog/task-*.md`, extract the highest numeric ID, then use `max + 1`
- Before creating the file, check the latest IDs to avoid parallel-numbering collisions
- Keep tasks flat; do not create status folders
- Status belongs in frontmatter

If `$ARGUMENTS` is present, use it as the title or focus. Otherwise infer a title from the user's preceding request.

Create one comprehensive backlog item with frontmatter compatible with the local backlog contract:

```yaml
---
id: <next-id>
title: "<clear title>"
status: backlog
priority: medium
created: <YYYY-MM-DD>
milestone: null
tags: [vision, roadmap]
estimated_hours: null
depends_on: []
blocks: []
effort: null
due: null
venture: null
intent: "<one-line intent>"
expected_impact:
  primary: "<one-line expected outcome>"
  secondary: []
  impact_count_predicted: 3
---
```

Then write the backlog body as a complete vision and multi-phase roadmap document. Include:

1. Context and problem statement
2. North star vision
3. Design principles
4. Current-state assumptions and unknowns
5. Research notes or evidence gathered before drafting
6. Proposed architecture or operating model
7. Multi-phase roadmap with concrete phases
8. Acceptance criteria
9. Risks, constraints, and mitigations
10. Dependencies and open questions
11. First 3-5 next actions

Before drafting, do supplementary brainstorming and targeted research when it would materially improve the plan. Prefer local context first, then web research for current technical or market facts. Do not perform long-running scans or destructive commands.

Optimize for reliability, maintainability, modularity, clarity, simplicity, completeness, extensibility, portability, taste, effectiveness, efficiency, meaning, discoverability, DRYness, robustness, and elegance.

After writing the file, report the created path and the assigned task ID.
