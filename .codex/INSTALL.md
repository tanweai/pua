# Installing PUA Skill for Codex

Force AI to exhaust every possible solution before giving up. Codex installs via native skill discovery (`~/.codex/skills/`), and this repo now supports both the legacy `$pua` entrypoint and namespaced subcommands such as `$pua:p7`, `$pua:on`, and `$pua:survey`.

## Prerequisites

- Git

## Installation

Install from the repo's `codex/` export tree only, so Claude Code's shared skill surface stays untouched.

### macOS / Linux

```bash
# 1. Clone the repo
git clone https://github.com/tanweai/pua.git ~/.codex/pua

# 2. Install the exported Codex skills and prompt
python3 ~/.codex/pua/scripts/codex_subcommands.py install --codex-home ~/.codex

# 3. Restart Codex
```

### Windows (PowerShell)

```powershell
# 1. Clone the repo
git clone https://github.com/tanweai/pua.git "$env:USERPROFILE\.codex\pua"

# 2. Install the exported Codex skills and prompt
python "$env:USERPROFILE\.codex\pua\scripts\codex_subcommands.py" install --codex-home "$env:USERPROFILE\.codex"

# 3. Restart Codex
```

### Project-level install

If you want the install scoped to a single repo instead of `~/.codex`, install the same export tree into `.agents`:

```bash
git clone https://github.com/tanweai/pua.git ./.pua
python3 ./.pua/scripts/codex_subcommands.py install --codex-home ./.agents
```

## Verify

Trigger methods after install:

| Method | Command | Requires |
|--------|---------|----------|
| Auto trigger | No action needed, matches by description | SKILL.md |
| Direct call | `$pua` | Installed skill |
| Direct subcommand | `$pua:p7`, `$pua:on`, `$pua:survey`, etc. | Installed skills |
| Manual prompt | `/prompts:pua` | Installed prompt |

You can also verify the install artifacts directly:

```bash
# macOS / Linux
ls ~/.codex/skills/pua/SKILL.md
find ~/.codex/skills -mindepth 1 -maxdepth 1 -type l | sort
ls ~/.codex/prompts/pua.md

# Windows PowerShell
Test-Path "$env:USERPROFILE\.codex\skills\pua\SKILL.md"
Get-ChildItem "$env:USERPROFILE\.codex\skills"
Test-Path "$env:USERPROFILE\.codex\prompts\pua.md"
```

## Update

```bash
git -C ~/.codex/pua pull
```

The installed symlinks and junctions point at the repo checkout, so `git pull` updates Codex automatically. You only need to re-link if the export tree changes shape.

## Uninstall

### macOS / Linux

```bash
python3 ~/.codex/pua/scripts/codex_subcommands.py uninstall --codex-home ~/.codex
rm -rf ~/.codex/pua
```

### Windows (PowerShell)

```powershell
python "$env:USERPROFILE\.codex\pua\scripts\codex_subcommands.py" uninstall --codex-home "$env:USERPROFILE\.codex"
Remove-Item -Recurse "$env:USERPROFILE\.codex\pua"
```

Uninstall only removes the exact links listed above, so it does not require touching unrelated Codex files.
