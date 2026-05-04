---
description: Archive old session transcripts to reduce storage bloat
argument-hint: [--dry-run]
allowed-tools: [Read, Bash, Grep, Glob]
---

# Archive Transcripts

Session transcripts (.jsonl) accumulate and grow. This command identifies large/old transcripts
and archives them while keeping them searchable.

## Strategy
- **Keep**: Current session and recent sessions (< 7 days)
- **Archive**: Older sessions → compress to ~/.claude/archives/transcripts/
- **Never delete**: Transcripts are valuable for the transcript-search plugin and Subconscious

## Process

### 1. Survey
```bash
echo "=== Transcript Survey ==="
find ~/.claude/projects/-home-shawn -maxdepth 1 -name "*.jsonl" -exec ls -lh {} \; | sort -k5 -h -r

echo ""
echo "=== Subagent Transcripts ==="
find ~/.claude/projects/-home-shawn -path "*/subagents/*.jsonl" -exec ls -lh {} \; 2>/dev/null | sort -k5 -h -r

echo ""
TOTAL=$(find ~/.claude/projects/-home-shawn -name "*.jsonl" -not -path "*/memory/*" -exec du -ch {} + 2>/dev/null | tail -1)
echo "Total: $TOTAL"
```

### 2. Identify Archivable

If `$ARGUMENTS` contains "--dry-run", only list what would be archived.

Find transcripts older than 7 days:
```bash
find ~/.claude/projects/-home-shawn -maxdepth 1 -name "*.jsonl" -mtime +7 2>/dev/null
```

Find subagent directories for sessions older than 7 days:
```bash
find ~/.claude/projects/-home-shawn -maxdepth 1 -type d -name "????????-????-????-????-????????????" -mtime +7 2>/dev/null
```

### 3. Archive
```bash
mkdir -p ~/.claude/archives/transcripts/

# For each old transcript, compress and move
for f in <files>; do
    session_id=$(basename "$f" .jsonl)
    zstd "$f" -o ~/.claude/archives/transcripts/${session_id}.jsonl.zst
    rm "$f"

    # Also archive subagent transcripts if they exist
    if [ -d "~/.claude/projects/-home-shawn/${session_id}/subagents" ]; then
        tar -c -C ~/.claude/projects/-home-shawn/${session_id} subagents | zstd > ~/.claude/archives/transcripts/${session_id}-subagents.tar.zst
        rm -r ~/.claude/projects/-home-shawn/${session_id}/subagents
    fi
done
```

### 4. Report
- How many sessions archived
- Space freed
- Space remaining in archives
- Remind: archived transcripts can be decompressed with `zstd -d` for searching
