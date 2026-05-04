---
description: Process a URL, repo, or transcript into structured knowledge
argument-hint: <url-or-path>
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch, Agent]
---

# Process Knowledge

Read the skill at `~/.claude/skills/knowledge-processing/SKILL.md` for schemas and conventions.

Process the input `$ARGUMENTS` into structured knowledge:

1. **Detect type** from the input:
   - GitHub URL → repo processing
   - YouTube URL → transcript processing (requires yt-dlp)
   - Other URL → article processing
   - Local file path → determine by content

2. **Extract and structure** following the schemas in the skill

3. **Store** the output in the appropriate `~/.claude/knowledge/` subdirectory

4. **Append** an index entry to `~/.claude/knowledge/index.jsonl`

5. **Update** `~/.claude/projects/-home-shawn/memory/urls.jsonl` if it's a URL

6. **Report** a brief summary of what was extracted
