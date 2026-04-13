# Legion Machine Configuration

Chezmoi-managed dotfiles + recipe-based bootstrap for CachyOS machines.

## Quick Start

```bash
# On a fresh CachyOS install:
git clone git@github.com:LinuxIsCool/legion.git ~/legion-machine
cd ~/legion-machine

# Copy the age decryption key (from existing machine):
mkdir -p ~/.config/chezmoi
# scp shawn@legion:~/.config/chezmoi/key.txt ~/.config/chezmoi/key.txt

# Run bootstrap:
./bootstrap.sh --profile legion    # full workstation
./bootstrap.sh --profile e15       # thin client
./bootstrap.sh --list              # show available profiles
./bootstrap.sh --dry-run --profile legion  # preview
```

## Structure

```
bootstrap.sh          Entry point
lib/                  Shared utilities
profiles/             Machine profiles (TOML)
recipes/              Idempotent setup scripts
home/                 Chezmoi source directory
```

## Profiles

| Profile | Description | Recipes |
|---------|-------------|---------|
| `legion` | Primary workstation — full services | 15 recipes |
| `e15` | Travel laptop — thin client | 11 recipes |

## Recipes

Each recipe is idempotent with `check()` → `install()` pattern:
- Returns immediately if already satisfied
- Generates sudo scripts to `~/.claude/local/scripts/` when root is needed
- Never runs sudo directly

## Chezmoi

The `home/` directory is a chezmoi source. Machine-specific config via hostname templates:
- Font sizes, display scale, service inclusion
- Age-encrypted secrets (SSH keys, fish secrets)
- NVChad pulled as chezmoi external

### The Chezmoi Rule

**NEVER run `chezmoi apply` without `chezmoi diff` first.**

Chezmoi is a one-way overwrite. If you edit a live file (e.g. `~/.config/tmux/plugins.conf`)
instead of the source (`~/legion-machine/home/private_dot_config/tmux/plugins.conf`),
the next `chezmoi apply` silently destroys your change. No merge, no warning.

**Workflow:**
1. **To change config**: Edit the source in `~/legion-machine/home/...`, then `chezmoi apply`
2. **If you edited a live file**: Run `chezmoi add <path>` to capture it into the source
3. **Before any apply**: Run `chezmoi diff` to review what will change
4. **Periodic audit**: Run `chezmoi diff` to catch drift between live and source

## Age Encryption

Secrets are encrypted with age. To set up:
```bash
age-keygen -o ~/.config/chezmoi/key.txt
# Update .chezmoi.toml.tmpl with the public key (age1...)
# Re-encrypt files with: chezmoi encrypt
```
