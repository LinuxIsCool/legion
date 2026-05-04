---
description: Scaffold a new Claude Code slash command
argument-hint: <command-name> [description]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# Develop Command

You are scaffolding a new Claude Code slash command. Commands are user-invoked via `/<command-name>`.

## Input

Parse `$ARGUMENTS` for:
- **command-name**: Required. The name used after `/`.
- **description**: Optional. If not provided, ask the user.

## Process

### 1. Establish Intent

- What should this command do when invoked?
- Does it take arguments? What format?
- What tools does it need access to?
- Should it use a specific model? (haiku for fast/cheap, sonnet for balanced, opus for complex)

### 2. Determine Location

- **Project-level**: `.claude/commands/<name>.md` — available in this project only
- **Inside a plugin**: `<plugin>/commands/<name>.md` — portable and installable

### 3. Scaffold

Create the command file:

```yaml
---
description: <short description for /help listing>
argument-hint: <required-arg> [optional-arg]
allowed-tools: [Read, Glob, Grep, Bash]
model: sonnet
---

# Command instructions here

Use `$ARGUMENTS` to access user input.

## Steps
1. ...
2. ...
```

### Guidelines

- `description` appears in `/help` — keep it concise and clear
- `argument-hint` shows usage pattern — use `<required>` and `[optional]` notation
- `allowed-tools` pre-approves tools to reduce permission prompts
- `model` overrides the session model — use `haiku` for fast tasks, `sonnet` for most things
- The command body is a prompt — write it as instructions to Claude
- Use `$ARGUMENTS` to reference whatever the user typed after the command name
- Commands can reference other commands, skills, and agents

### 4. Test

After creating, test by running `/<command-name>` with sample arguments.
