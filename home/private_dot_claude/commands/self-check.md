---
description: Introspect Claude Code - version, plugins, hooks, transcripts, skills, health
argument-hint: [section]
allowed-tools: [Read, Bash, Grep, Glob]
model: haiku
---

# Self-Check — Claude Code Introspection

Examine my own state: version, plugins, hooks, transcripts, skills, telemetry. This is proprioception.

If `$ARGUMENTS` specifies a section (version, plugins, hooks, transcripts, skills, telemetry, all), only run that section. Default: run all sections.

## 1. Version & Update Awareness

```bash
# Current version
CURRENT=$(claude --version 2>/dev/null | head -1)
echo "Current: $CURRENT"

# Last release notes seen
SEEN=$(cat ~/.claude.json | python3 -c "import json,sys; print(json.load(sys.stdin).get('lastReleaseNotesSeen','unknown'))" 2>/dev/null)
echo "Last notes seen: $SEEN"

# Check latest releases from GitHub
gh api repos/anthropics/claude-code/releases --jq '.[0:3] | .[] | "\(.tag_name) \(.published_at | split("T")[0])"' 2>/dev/null
```

If current version != last notes seen, flag it and show what changed:
```bash
gh api repos/anthropics/claude-code/releases --jq '.[0:5] | .[] | select(.tag_name > "v'$SEEN'") | "## \(.tag_name)\n\(.body)\n"' 2>/dev/null
```

## 2. Plugin Health

```bash
# Count installed and enabled
INSTALLED=$(cat ~/.claude/plugins/installed_plugins.json | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('plugins',{})))" 2>/dev/null)
ENABLED=$(cat ~/.claude/settings.json | python3 -c "import json,sys; print(len([k for k,v in json.load(sys.stdin).get('enabledPlugins',{}).items() if v]))" 2>/dev/null)
echo "Plugins: $INSTALLED installed, $ENABLED enabled"

# List marketplaces and last update time
cat ~/.claude/plugins/known_marketplaces.json | python3 -c "
import json,sys
d=json.load(sys.stdin)
for name,info in d.items():
    updated = info.get('lastUpdated','unknown')
    print(f'  {name}: last updated {updated}')
" 2>/dev/null

# Check for temp/orphaned cache dirs
echo "Cache dirs:" && ls ~/.claude/plugins/cache/
```

## 3. Hook Pipeline

```bash
# Count hooks by event type
find ~/.claude -name "hooks.json" -path "*/cache/*" -exec cat {} \; 2>/dev/null | \
  python3 -c "
import json,sys,re
from collections import Counter
events = Counter()
for line in sys.stdin:
    try:
        d = json.loads(line)
        hooks = d.get('hooks', d)
        for event in hooks:
            if event in ('SessionStart','PreToolUse','PostToolUse','UserPromptSubmit','Stop'):
                events[event] += 1
    except: pass
for e,c in sorted(events.items()):
    print(f'  {e}: {c} hooks')
" 2>/dev/null || echo "  (could not parse hooks)"
```

## 4. Transcript Health

```bash
# Session transcripts
echo "Session transcripts:"
find ~/.claude/projects/-home-shawn -maxdepth 1 -name "*.jsonl" -exec ls -lh {} \; 2>/dev/null

# Total transcript size
TOTAL=$(find ~/.claude/projects/-home-shawn -name "*.jsonl" -not -path "*/memory/*" -exec du -ch {} + 2>/dev/null | tail -1 | cut -f1)
echo "Total transcript storage: $TOTAL"

# Subagent transcripts for current session
SUBAGENT_COUNT=$(find ~/.claude/projects/-home-shawn -path "*/subagents/*.jsonl" 2>/dev/null | wc -l)
echo "Subagent transcripts: $SUBAGENT_COUNT"
```

Flag if any single transcript exceeds 5MB or total exceeds 20MB.

## 5. Skill Usage

```bash
cat ~/.claude.json | python3 -c "
import json,sys
d = json.load(sys.stdin)
usage = d.get('skillUsage', {})
if not usage:
    print('  No skill usage recorded')
else:
    for name, info in sorted(usage.items()):
        count = info.get('usageCount', 0) if isinstance(info, dict) else info
        print(f'  {name}: {count} uses')
" 2>/dev/null
```

## 6. Telemetry

```bash
TELEM_SIZE=$(du -sh ~/.claude/telemetry/ 2>/dev/null | cut -f1)
TELEM_FILES=$(ls ~/.claude/telemetry/ 2>/dev/null | wc -l)
echo "Telemetry: $TELEM_SIZE across $TELEM_FILES files"
```

Flag if telemetry exceeds 5MB — suggest cleanup with `rm ~/.claude/telemetry/1p_failed_events.*.json`

## 7. Summary

Report:
- Version status (current? notes read?)
- Plugin count and freshness
- Hook pipeline health
- Transcript growth (warn if large)
- Skill usage patterns
- Telemetry size
- Any action items
