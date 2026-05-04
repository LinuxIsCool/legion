---
description: Quick system health check and session orientation
argument-hint: [verbose]
allowed-tools: [Read, Bash, Grep, Glob]
model: haiku
---

# Status Check

Run a quick health check and orient to the current session. This is Legion's "start of shift" routine.

## Steps

### 1. System Vitals (always)
Run these in parallel:
```bash
# Temps and load
sensors | grep "Package\|fan" 2>/dev/null; uptime

# Memory
free -h | head -2

# GPU
nvidia-smi --query-gpu=temperature.gpu,fan.speed,power.draw,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null

# Disk
df -h / /home /boot | tail -n +2

# Failed services
systemctl --failed --no-pager 2>/dev/null | grep -c "loaded" || echo "0 failed"

# Docker services
docker compose -f ~/.config/letta/compose.yaml ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null || echo "letta stack: docker not available"
curl -sf http://localhost:8283/v1/health > /dev/null 2>&1 && echo "letta-api: healthy" || echo "letta-api: unreachable"
```

### 2. Pending Items
Read `/home/shawn/.claude/projects/-home-shawn/memory/legion-role.md` and report the pending items checklist — what's done, what's still open.

### 3. Recent Changes
```bash
# Recent package changes
expac --timefmt='%Y-%m-%d' '%l\t%n' | sort -r | head -5

# Snapshot count
sudo snapper list 2>/dev/null | wc -l || echo "snapper needs sudo"
```

### 4. Report
Present a concise status report:
- System health (temps, load, disk, GPU — flag anything unusual)
- Pending items count and any urgent ones
- Quick note on what's changed since last check

If `$ARGUMENTS` contains "verbose", also include:
- Full service status
- Network status
- Detailed disk breakdown
- Package orphan check

Keep the output concise. Only flag things that need attention.
