# Installing PUA Skill for Codex

Force AI to exhaust every possible solution before giving up. Installs via native skill discovery (`~/.codex/skills/`).

## Prerequisites

- Git

## Installation

### macOS / Linux

```bash
# 1. Clone the repo
git clone https://github.com/tanweai/pua.git ~/.codex/pua

# 2. Create skill symlink (enables auto-discovery)
mkdir -p ~/.codex/skills
ln -s ~/.codex/pua/codex/pua ~/.codex/skills/pua

# 3. Install /prompts:pua trigger
mkdir -p ~/.codex/prompts
ln -s ~/.codex/pua/commands/pua.md ~/.codex/prompts/pua.md

# 4. Restart Codex
```

### Windows (PowerShell)

```powershell
# 1. Clone the repo
git clone https://github.com/tanweai/pua.git "$env:USERPROFILE\.codex\pua"

# 2. Create skill junction (enables auto-discovery)
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\skills"
cmd /c mklink /J "$env:USERPROFILE\.codex\skills\pua" "$env:USERPROFILE\.codex\pua\codex\pua"

# 3. Install /prompts:pua trigger
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\prompts"
cmd /c mklink "$env:USERPROFILE\.codex\prompts\pua.md" "$env:USERPROFILE\.codex\pua\commands\pua.md"

# 4. Restart Codex
```

## Verify

Type `$pua` in a Codex conversation. If the skill is loaded, you'll see it activate.

Or check directly:
```bash
# macOS / Linux
ls ~/.codex/skills/pua/SKILL.md

# Windows PowerShell
Test-Path "$env:USERPROFILE\.codex\skills\pua\SKILL.md"
```

## Trigger Methods

| Method | Command | Requires |
|--------|---------|----------|
| Auto trigger | No action needed, matches by description | SKILL.md |
| Direct call | Type `$pua` in conversation | SKILL.md |
| Manual prompt | Type `/prompts:pua` in conversation | SKILL.md + prompts/pua.md |

## Language Variants

| Language | Skill path |
|----------|------------|
| 🇨🇳 Chinese (default) | `codex/pua/SKILL.md` |
| 🇺🇸 English (PIP) | `codex/pua-en/SKILL.md` |
| 🇯🇵 Japanese | `codex/pua-ja/SKILL.md` |

To install a different language variant, replace `pua` with `pua-en` or `pua-ja` in the symlink/junction step:

```bash
# Example: English variant (macOS/Linux)
ln -s ~/.codex/pua/codex/pua-en ~/.codex/skills/pua-en
```

## Update

```bash
cd ~/.codex/pua
git pull
```

The symlink/junction automatically picks up the latest version — no reinstall needed.

## Uninstall

### macOS / Linux

```bash
rm ~/.codex/skills/pua
rm ~/.codex/prompts/pua.md
rm -rf ~/.codex/pua
```

### Windows (PowerShell)

```powershell
Remove-Item "$env:USERPROFILE\.codex\skills\pua"
Remove-Item "$env:USERPROFILE\.codex\prompts\pua.md"
Remove-Item -Recurse "$env:USERPROFILE\.codex\pua"
```
