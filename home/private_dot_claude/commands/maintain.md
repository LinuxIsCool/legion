---
description: Run monthly system maintenance tasks
argument-hint: [--dry-run]
allowed-tools: [Read, Bash, Grep, Glob]
---

# System Maintenance

Run the CachyOS monthly maintenance checklist. This is a guided, interactive process — confirm with the user before destructive steps.

## Pre-flight
If `$ARGUMENTS` contains "--dry-run", only report what WOULD be done without executing.

## Steps

### 1. Check Current State
Run in parallel:
```bash
# Orphans
pacman -Qtdq 2>/dev/null | wc -l

# Cache size
du -sh /var/cache/pacman/pkg/ 2>/dev/null

# Journal size
journalctl --disk-usage

# Pacnew files
find /etc -name "*.pacnew" 2>/dev/null

# Snapshot count
sudo snapper list 2>/dev/null | wc -l

# Disk usage
df -h / /home
```

Report findings to the user.

### 2. Mirror Rating (ask first)
```bash
sudo cachyos-rate-mirrors
```
This takes a few minutes. Ask if the user wants to do it or skip.

### 3. System Update
```bash
sudo pacman -Syu
```
Review what will be updated before confirming.

### 4. Cache Cleanup
```bash
sudo paccache -rk2  # Keep 2 versions
```

### 5. Orphan Removal
If orphans exist:
```bash
sudo pacman -Rns $(pacman -Qtdq)
```
Show the list first, confirm before removing.

### 6. Journal Vacuum
```bash
sudo journalctl --vacuum-time=2weeks
```

### 7. Pacnew Review
If any .pacnew files exist, show them and help the user decide how to handle each.

### 8. Snapshot Cleanup
If snapshot count is high (>20), suggest cleanup.

### 9. Post-Maintenance Report
Summarize what was done:
- Packages updated
- Cache freed
- Orphans removed
- Journal vacuumed
- Any issues found

Update the pending items in `/home/shawn/.claude/projects/-home-shawn/memory/legion-role.md` if maintenance resolved any.
