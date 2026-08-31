# Installing PUA for Codex

Force Codex to exhaust alternatives before giving up. Full Codex support uses the native plugin manifest plus lifecycle hooks.

## Prerequisites

- Git
- Codex with hooks enabled
- `jq`, `python3`, and `bash` available for hook scripts

## Recommended Install

### macOS / Linux

```bash
# 1. Clone the repo
git clone https://github.com/tanweai/pua.git ~/.codex/plugins/src/pua

# 2. Create a local Codex marketplace for PUA
mkdir -p ~/.codex/.tmp/marketplaces/pua-local/.agents/plugins
mkdir -p ~/.codex/.tmp/marketplaces/pua-local/plugins
ln -sfn ~/.codex/plugins/src/pua ~/.codex/.tmp/marketplaces/pua-local/plugins/pua

python3 - <<'PY'
import json, os, pathlib
root = pathlib.Path.home() / ".codex/.tmp/marketplaces/pua-local"
path = root / ".agents/plugins/marketplace.json"
data = {
    "name": "pua-local",
    "interface": {"displayName": "PUA Local"},
    "plugins": [{
        "name": "pua",
        "source": {"source": "local", "path": "./plugins/pua"},
        "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
        "category": "Productivity",
    }],
}
path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
PY

# 3. Register and install
codex plugin marketplace add ~/.codex/.tmp/marketplaces/pua-local
codex plugin add pua@pua-local
```

Restart Codex, run `/hooks`, then trust the `pua@pua-local` hooks.

Do not clone the plugin to `~/.codex/pua`. That old path can be discovered as an extra skill source and duplicate `$pua-*` entries in the skill picker.

### Windows (PowerShell)

```powershell
git clone https://github.com/tanweai/pua.git "$env:USERPROFILE\.codex\plugins\src\pua"
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\.tmp\marketplaces\pua-local\.agents\plugins"
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\.tmp\marketplaces\pua-local\plugins"
cmd /c mklink /J "$env:USERPROFILE\.codex\.tmp\marketplaces\pua-local\plugins\pua" "$env:USERPROFILE\.codex\plugins\src\pua"
```

Then add the same marketplace entry under `%USERPROFILE%\.codex\.tmp\marketplaces\pua-local\.agents\plugins\marketplace.json`, run `codex plugin marketplace add`, run `codex plugin add pua@pua-local`, restart Codex, and trust hooks with `/hooks`.

## Hook Loading Model

Codex hooks are plugin-level lifecycle hooks. After `pua@pua-local` is installed and trusted, the same hook set runs for every session/event; selecting `$pua-p7`, `$pua-kpi`, or another PUA skill does not install a separate hook set.

Skills are menu entries and turn-level instructions. Hooks are loaded before the first chat turn in a new session and then run on lifecycle events such as `SessionStart`, `UserPromptSubmit`, `PostToolUse`, `PreCompact`, `Stop`, and subagent start/stop.

## What Full Codex Support Enables

| Feature | Codex entry |
|---|---|
| Core PUA | `$pua` or `/pua:pua` |
| Sub-modes | `$pua-p7`, `$pua-p9`, `$pua-p10`, `$pua-pro`, `$pua-yes`, `$pua-mama`, `$pua-shot` |
| PUA Loop | `$pua-loop` or `/pua:pua-loop ...` |
| Always-on | `$pua-on` or `/pua:on` |
| Offline mode | `$pua-offline` or `/pua:offline` |
| Survey/flavor/KPI | `$pua-survey`, `$pua-flavor`, `$pua-kpi` |
| Agent lifecycle | `$pua-team-status`, `$pua-reap-orphans`, `$pua-teardown-all` |
| Legacy prompt | `/prompts:pua` |

Codex hooks provide:

- `SessionStart`: always-on context and builder-journal recovery
- `UserPromptSubmit`: frustration trigger and `/pua:*` command router
- `PostToolUse:Bash`: failure escalation and methodology switch reminders
- `PreCompact`: `~/.pua/builder-journal.md` checkpoint
- `Stop`: PUA Loop continuation and silent optional-feedback bookkeeping
- `SubagentStart/SubagentStop`: active-agent accounting
- `PreToolUse`: integrity guard

## Skill-only Fallback

Use this only when you cannot install plugins or trust hooks:

```bash
mkdir -p ~/.codex/skills/pua
curl -o ~/.codex/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/codex/pua/SKILL.md

mkdir -p ~/.codex/prompts
curl -o ~/.codex/prompts/pua.md \
  https://raw.githubusercontent.com/tanweai/pua/main/commands/pua.md
```

Fallback supports `$pua` and `/prompts:pua`, but not deterministic lifecycle hooks. Do not combine the fallback with the plugin install unless you want duplicate skill picker entries.

## Verify

1. Restart Codex.
2. Run `/plugins` and confirm PUA is installed.
3. Run `/hooks` and trust PUA hooks.
4. Start a new thread and type `/pua:on`.
5. Start another new thread; PUA SessionStart context should be active.

Static file checks:

```bash
codex plugin list | grep 'pua@pua-local'
find ~/.codex/plugins/cache/pua-local/pua -path '*/.codex-plugin/plugin.json' -print -quit
find ~/.codex/plugins/cache/pua-local/pua -path '*/hooks/codex-hooks.json' -print -quit
```

## Update

```bash
cd ~/.codex/plugins/src/pua
git pull
codex plugin add pua@pua-local
```

Restart Codex and review `/hooks` again because changed hook definitions need fresh trust.

## Uninstall

Remove the plugin from Codex, then remove the local checkout and marketplace entry:

```bash
codex plugin remove pua@pua-local
codex plugin marketplace remove pua-local
rm -rf ~/.codex/.tmp/marketplaces/pua-local
rm -rf ~/.codex/plugins/src/pua
```

If you previously installed the deprecated skill source, remove it after checking for local changes:

```bash
rm -rf ~/.codex/pua
```

Optional local state cleanup:

```bash
rm -rf ~/.pua
```
