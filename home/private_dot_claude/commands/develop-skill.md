---
description: Scaffold a new skill with proper structure and progressive disclosure
argument-hint: <skill-name> [description]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Agent]
---

# Develop Skill

You are scaffolding a new Claude Code skill. Follow the Agent Skills specification and the user's established patterns.

## Input

Parse `$ARGUMENTS` for:
- **skill-name**: Required. Lowercase, hyphens only, max 64 chars.
- **description**: Optional. If not provided, interview the user to establish intent.

## Process

### 1. Establish Intent (before any code)

Understand what the skill should do. Capture:
- What capability does this enable?
- When should it trigger? (specific phrases, contexts, keywords)
- What's the expected output?
- What tools/resources does it need?

Separate the **intent** from the **implementation**. Document the intent clearly — it should survive if we rewrite the implementation from scratch.

### 2. Choose the Pattern

Based on complexity, select the right pattern:

| Pattern | When | Structure |
|---------|------|-----------|
| Instructions-only | Simple behavioral guidance | `SKILL.md` only |
| Instructions + examples | Needs reference outputs | `SKILL.md` + `examples/` |
| Instructions + scripts | Has deterministic/repetitive tasks | `SKILL.md` + `scripts/` |
| Instructions + refs | Large domain knowledge | `SKILL.md` + `references/` |
| Full progressive | Complex multi-concern skill | All directories |

Default to the **simplest pattern** that serves the intent. Don't add structure you don't need.

### 3. Scaffold

Determine where to create the skill based on context:
- If inside a plugin repo: `skills/<skill-name>/`
- If standalone: prompt user for location

Create the directory and files. The SKILL.md must follow this structure:

```yaml
---
name: <skill-name>
description: |
  <What this does AND when to trigger. Be specific with trigger phrases.
   Be slightly pushy — Claude undertriggers skills by default.>
---
```

The markdown body should:
- Stay under 500 lines (split to references/ if longer)
- Use imperative form
- Explain WHY, not just WHAT — Claude responds better to reasoning than rigid MUSTs
- Include examples of inputs/outputs where helpful
- Reference bundled files with clear guidance on when to read them

### 4. Apply the Master Skill Pattern

If this skill has subskills or is part of a larger plugin:
- ONE discoverable SKILL.md as the entry point
- Additional sub-skills in `subskills/` loaded on-demand via Read
- This keeps the ~15,000 char skill description budget in check

### 5. Script Best Practices (if scripts/ needed)

Scripts must be:
- Non-interactive (agents run in non-interactive shells)
- Support `--help`
- Use structured output (JSON/CSV) to stdout, diagnostics to stderr
- Idempotent where possible
- Self-contained dependencies (PEP 723 inline metadata for Python, npx for Node)

### 6. Offer Next Steps

After scaffolding, suggest:
1. Run `/skill-creator` to test and iterate on the skill with evals
2. Optimize the description for triggering accuracy
3. Package into a plugin if it should be portable

## References

Read the skill anatomy reference for complete structural details:
- `/home/shawn/.claude/projects/-home-shawn/memory/skill-anatomy.md`
