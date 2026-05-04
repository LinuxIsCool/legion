---
description: Scaffold a new Claude Code plugin with skills, commands, agents, and hooks
argument-hint: <plugin-name> [description]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Agent]
---

# Develop Plugin

You are scaffolding a new Claude Code plugin. Plugins are the unit of portable, installable functionality.

## Input

Parse `$ARGUMENTS` for:
- **plugin-name**: Required. Lowercase, hyphens only.
- **description**: Optional. If not provided, interview the user.

## Process

### 1. Establish Intent

Before creating anything, understand:
- What capability bundle does this plugin provide?
- Who is it for? (personal use, team, public marketplace)
- What components does it need? (skills, commands, agents, hooks, MCP servers)
- What's the simplest version that delivers value?

### 2. Interview for Components

Walk through each component type and ask if needed:

| Component | Purpose | User-invoked? |
|-----------|---------|---------------|
| **Skills** | Auto-triggered by Claude based on description | No — Claude decides |
| **Commands** | Slash commands the user explicitly calls | Yes — `/command-name` |
| **Agents** | Sub-agents for specialized tasks | No — spawned by skills/commands |
| **Hooks** | Event-driven scripts (PreToolUse, PostToolUse, Stop, etc.) | No — automatic |
| **MCP Servers** | Persistent stateful services | No — background process |
| **Output Styles** | Formatting templates | No — applied to responses |

**Prefer skills + agents over MCP servers.** Only use MCP when persistent state is required.

### 3. Scaffold

Create the plugin directory with:

```
<plugin-name>/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── commands/           (if commands needed)
│   └── .gitkeep
├── skills/             (if skills needed)
│   └── <primary-skill>/
│       └── SKILL.md
├── agents/             (if agents needed)
│   └── .gitkeep
└── hooks/              (if hooks needed)
    └── hooks.json
```

**plugin.json format:**
```json
{
  "name": "<plugin-name>",
  "version": "0.1.0",
  "description": "<what this plugin does>",
  "author": {
    "name": "Shawn",
    "email": ""
  }
}
```

### 4. Component Scaffolding

For each component the user wants, scaffold it:

**Commands** (`commands/<name>.md`):
```yaml
---
description: Short description for /help
argument-hint: <required> [optional]
allowed-tools: [Read, Glob, Grep, Bash]
model: sonnet
---
```

**Agents** (`agents/<name>.md`):
```yaml
---
name: agent-name
description: What this agent does
tools: Glob, Grep, Read, Bash
model: sonnet
color: green
---
```

**Skills**: Use `/develop-skill` for each skill.

**Hooks** (`hooks/hooks.json`):
```json
{
  "hooks": {
    "PreToolUse": [],
    "PostToolUse": [],
    "UserPromptSubmit": [],
    "Stop": []
  }
}
```

### 5. Create GitHub Repo

Every plugin should be its own git repo:

```bash
cd <plugin-name>
git init
git add -A
git commit -m "Initial plugin scaffold"
gh repo create LinuxIsCool/<plugin-name> --private \
  --description "<description>" --source . --push
```

### 6. Add to Marketplace

Add the plugin as a git submodule in the legion-plugins marketplace:

```bash
cd ~/.claude/plugins/local/legion-plugins

# Add as submodule
git submodule add git@github.com:LinuxIsCool/<plugin-name>.git plugins/<plugin-name>

# Update marketplace.json — add entry to "plugins" array:
# {"name": "<plugin-name>", "source": "./plugins/<plugin-name>",
#  "description": "...", "version": "0.1.0",
#  "author": {"name": "Shawn"}, "category": "..."}

git add .gitmodules plugins/<plugin-name> .claude-plugin/marketplace.json
git commit -m "Add <plugin-name> to marketplace"
git push
```

### 7. Install the Plugin

```bash
# Update the marketplace index
claude plugin marketplace update legion-plugins

# Install the plugin
claude plugin install <plugin-name>
```

### 8. Verify Installation

```bash
# Check it's registered
python3 -c "
import json
with open('$HOME/.claude/plugins/installed_plugins.json') as f:
    plugins = json.load(f).get('plugins', {})
key = '<plugin-name>@legion-plugins'
if key in plugins:
    print(f'OK: {key} installed, enabled={plugins[key].get(\"enabled\")}')
else:
    print(f'MISSING: {key} not in installed_plugins.json')
"

# Check cache exists
ls ~/.claude/plugins/cache/legion-plugins/<plugin-name>/.claude-plugin/plugin.json
```

**Restart Claude Code** for hooks and skills to load.

### 9. Test Hooks (if any)

Manually fire a hook to verify:
```bash
echo '{"session_id":"test","cwd":"/tmp"}' | \
  CLAUDE_PROJECT_DIR=/tmp \
  CLAUDE_PLUGIN_ROOT=~/.claude/plugins/cache/legion-plugins/<plugin-name> \
  uv run ~/.claude/plugins/cache/legion-plugins/<plugin-name>/hooks/handler.py -e SessionStart
```

### 10. Iterate

After initial install:
1. Develop individual skills with `/develop-skill`
2. Make changes in the plugin's own repo (`~/plugin-name/`)
3. Commit and push
4. Pull in marketplace: `cd ~/.claude/plugins/local/legion-plugins && git submodule update --remote plugins/<plugin-name>`
5. Reinstall: `claude plugin marketplace update legion-plugins && claude plugin install <plugin-name>`
6. Restart Claude Code

## Key Gotchas

- **Bare symlinks don't work** — plugins must go through the marketplace install flow
- **Changes need reinstall** — edit source → submodule update → marketplace update → plugin install → restart
- **Hook env vars:** `CLAUDE_PROJECT_DIR`, `CLAUDE_PLUGIN_ROOT`, `CLAUDE_ENV_FILE`, `CLAUDE_CODE_REMOTE`
- **No plugin settings API** — use env vars or `.claude/<plugin>.local.md` pattern for config

## References

- `/home/shawn/.claude/projects/-home-shawn/memory/skill-anatomy.md`
