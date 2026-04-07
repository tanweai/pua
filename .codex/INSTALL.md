# Installing PUA Skill for Codex

Force AI to exhaust every possible solution before giving up. Installs via native skill discovery (`~/.codex/skills/`).

This repository now keeps `commands/*.md` as the source of truth and generates same-suffix bridge skills into `skills/`. Codex exposes the command surface through the plugin namespace, for example:

- Claude Code: `/pua:p7`
- Codex: `$pua:p7`

## Prerequisites

- Git

## Installation

### macOS / Linux

```bash
# 1. Clone the repo
git clone https://github.com/tanweai/pua.git ~/.codex/pua

# 2. Link every shared skill (core skills + generated command bridges)
mkdir -p ~/.codex/skills
for dir in ~/.codex/pua/skills/*; do
  [ -d "$dir" ] || continue
  ln -sfn "$dir" "$HOME/.codex/skills/$(basename "$dir")"
done

# 3. Restart Codex
```

### Windows (PowerShell)

```powershell
# 1. Clone the repo
git clone https://github.com/tanweai/pua.git "$env:USERPROFILE\.codex\pua"

# 2. Link every shared skill (core skills + generated command bridges)
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\skills"
Get-ChildItem "$env:USERPROFILE\.codex\pua\skills" -Directory | ForEach-Object {
  $target = Join-Path "$env:USERPROFILE\.codex\skills" $_.Name
  if (Test-Path $target) {
    Remove-Item $target -Recurse -Force
  }
  cmd /c mklink /J "$target" "$($_.FullName)" | Out-Null
}

# 3. Restart Codex
```

## Verify

Type `$pua:pua` or `$pua:p7` in a Codex conversation. If the skills are loaded, you'll see them activate.

Or check directly:
```bash
# macOS / Linux
ls ~/.codex/skills/pua/SKILL.md
ls ~/.codex/skills/p7/SKILL.md

# Windows PowerShell
Test-Path "$env:USERPROFILE\.codex\skills\pua\SKILL.md"
Test-Path "$env:USERPROFILE\.codex\skills\p7\SKILL.md"
```

## Trigger Methods

| Method | Command | Requires |
|--------|---------|----------|
| Auto trigger | No action needed, matches by description | SKILL.md |
| Direct core skill | Type `$pua:pua` in conversation | `skills/pua/SKILL.md` |
| Namespaced command | Type `$pua:p7`, `$pua:pro`, `$pua:flavor`, etc. | Canonical skills in `skills/` plus generated same-suffix bridges such as `skills/flavor/` |

## Language Variants

| Language | Skill path |
|----------|------------|
| 🇨🇳 Chinese (default) | `skills/pua/SKILL.md` |
| 🇺🇸 English (PIP) | `skills/pua-en/SKILL.md` |
| 🇯🇵 Japanese | `skills/pua-ja/SKILL.md` |

To install a different language variant, keep the shared install loop above and call `$pua:pua-en` or `$pua:pua-ja` explicitly.

```bash
# Example: verify the English variant exists
ls ~/.codex/skills/pua-en/SKILL.md
```

## Update

```bash
cd ~/.codex/pua
git pull
```

The symlink, junction, or hard link automatically picks up the latest version — no reinstall needed.

If you installed an older Codex version by linking `~/.codex/skills/pua*` to `~/.codex/pua/codex/pua*`, the legacy core skill path continues to work via compatibility shims after `git pull`.

To enable namespaced subcommands such as `$pua:p7` and `$pua:flavor`, re-link once to the shared `skills/*` layout from the Installation section above.

## Uninstall

### macOS / Linux

```bash
for dir in ~/.codex/pua/skills/*; do
  rm -f "$HOME/.codex/skills/$(basename "$dir")"
done
rm -rf ~/.codex/pua
```

### Windows (PowerShell)

```powershell
Get-ChildItem "$env:USERPROFILE\.codex\pua\skills" -Directory | ForEach-Object {
  $target = Join-Path "$env:USERPROFILE\.codex\skills" $_.Name
  if (Test-Path $target) {
    Remove-Item $target -Recurse -Force
  }
}
Remove-Item -Recurse "$env:USERPROFILE\.codex\pua"
```
