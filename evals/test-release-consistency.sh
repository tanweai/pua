#!/usr/bin/env bash
# Static release gates: manifest version sync + confidence gate hardening.
set -euo pipefail

PLUGIN_DIR="${PLUGIN_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

python3 - "$PLUGIN_DIR" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
manifest_files = [
    'plugin.json',
    '.claude-plugin/plugin.json',
    '.claude-plugin/marketplace.json',
    '.codebuddy-plugin/plugin.json',
    '.codebuddy-plugin/marketplace.json',
    '.codex-plugin/plugin.json',
]
versions = []
errors = []
for rel in manifest_files:
    path = root / rel
    data = json.loads(path.read_text(encoding='utf-8'))
    if 'version' in data:
        versions.append((rel, data['version']))
    for idx, plugin in enumerate(data.get('plugins', []) or []):
        if plugin.get('name') == 'pua':
            versions.append((f'{rel}:plugins[{idx}]', plugin.get('version')))

unique = {v for _, v in versions}
if len(unique) != 1:
    errors.append('version mismatch: ' + repr(versions))
version = next(iter(unique)) if unique else None
if not version:
    errors.append('no version detected')

claude_market = json.loads((root / '.claude-plugin/marketplace.json').read_text(encoding='utf-8'))
plugin_desc = claude_market['plugins'][0].get('description', '')
if version and f'v{version}:' not in plugin_desc:
    errors.append(f'.claude-plugin/marketplace.json plugin description missing changelog marker v{version}:')

skill = (root / 'skills/pua/SKILL.md').read_text(encoding='utf-8')
required_terms = [
    '信心门控（Confidence Gate）',
    '列声明',
    '找漏洞',
    'P0/P1',
    '跑证据',
    '循环判定',
    '事实上的 100%',
    '缓存/发布链路',
    'hook smoke test',
    'Harness 防作弊治理（权责分离）',
    '行动权 / 自我评价权 / 评分权 / 环境修改权',
    'verifier_status',
    '四代理拓扑',
    'pua-policy-guardian',
    'pua-action-executor',
    'pua-self-reviewer',
    'pua-verifier',
    '文化叙事绑定',
]
for term in required_terms:
    if term not in skill:
        errors.append(f'confidence gate missing required term: {term}')


reference = root / 'skills/pua/references/harness-governance.md'
if not reference.exists():
    errors.append('missing harness governance reference file')
else:
    ref_text = reference.read_text(encoding='utf-8')
    for term in ['把四类权力分开', 'Grader gaming', 'Solution contamination', 'Task Contract', 'Memory 权限模型', '事实上的 100%', '四代理上下文隔离拓扑（v3.2.7）', 'pua-action-executor', 'pua-policy-guardian', '上下文隔离降低叙事污染']:
        if term not in ref_text:
            errors.append(f'harness governance reference missing required term: {term}')

hooks_json = json.loads((root / 'hooks/hooks.json').read_text(encoding='utf-8'))
codex_plugin = json.loads((root / '.codex-plugin/plugin.json').read_text(encoding='utf-8'))
if codex_plugin.get('skills') != './codex/':
    errors.append('.codex-plugin/plugin.json must point skills at ./codex/')
if codex_plugin.get('hooks') != './hooks/codex-hooks.json':
    errors.append('.codex-plugin/plugin.json must point hooks at ./hooks/codex-hooks.json')
codex_hooks_path = root / 'hooks/codex-hooks.json'
if not codex_hooks_path.exists():
    errors.append('missing hooks/codex-hooks.json')
else:
    codex_hooks = json.loads(codex_hooks_path.read_text(encoding='utf-8'))
    def walk_hooks(obj):
        if isinstance(obj, dict):
            if obj.get('type') == 'prompt':
                errors.append('Codex hooks must not use type: prompt')
            for value in obj.values():
                walk_hooks(value)
        elif isinstance(obj, list):
            for value in obj:
                walk_hooks(value)
    walk_hooks(codex_hooks)
    for event in ['SessionStart', 'UserPromptSubmit', 'PostToolUse', 'PreCompact', 'Stop', 'SubagentStart', 'SubagentStop', 'PreToolUse']:
        if event not in codex_hooks.get('hooks', {}):
            errors.append(f'Codex hooks missing event: {event}')
for rel in [
    'hooks/codex-context-wrapper.sh',
    'hooks/codex-command-router.sh',
    'hooks/codex-precompact-checkpoint.sh',
    'hooks/codex-stop-dispatcher.sh',
    'hooks/codex-stop-feedback.sh',
    'hooks/codex-feedback-submit.sh',
    'hooks/codex-subagent-start.sh',
    'codex/pua-shot/SKILL.md',
    'codex/pua-cancel-pua-loop/SKILL.md',
]:
    if not (root / rel).exists():
        errors.append(f'missing Codex hook/alias asset: {rel}')
pre_hooks = hooks_json.get('hooks', {}).get('PreToolUse', [])
if not any(any('integrity-guard.sh' in hook.get('command', '') for hook in item.get('hooks', [])) for item in pre_hooks):
    errors.append('hooks/hooks.json missing PreToolUse integrity-guard.sh registration')
if not (root / 'hooks/integrity-guard.sh').exists():
    errors.append('missing hooks/integrity-guard.sh')
if not (root / 'evals/test-integrity-guard.sh').exists():
    errors.append('missing evals/test-integrity-guard.sh')
if not (root / 'evals/test-windows-python-hooks.sh').exists():
    errors.append('missing evals/test-windows-python-hooks.sh')
if not (root / 'evals/test-issue-regressions.sh').exists():
    errors.append('missing evals/test-issue-regressions.sh')
if not (root / 'evals/test-agent-governance.sh').exists():
    errors.append('missing evals/test-agent-governance.sh')
for agent_file in ['agents/pua-action-executor.md', 'agents/pua-self-reviewer.md', 'agents/pua-verifier.md', 'agents/pua-policy-guardian.md']:
    if not (root / agent_file).exists():
        errors.append(f'missing governance agent: {agent_file}')

integrity_guard = (root / 'hooks/integrity-guard.sh').read_text(encoding='utf-8') if (root / 'hooks/integrity-guard.sh').exists() else ''
for term in ['permissionDecision', 'Grader gaming risk', 'Solution contamination risk', 'Capability-abuse risk', 'PUA_INTEGRITY_FORCE', 'hookEventName']:
    if term not in integrity_guard:
        errors.append(f'integrity guard missing required term: {term}')

flavor_helper = (root / 'hooks/flavor-helper.sh').read_text(encoding='utf-8')
for term in ['pua_python_cmd()', 'pua_to_python_path()', 'pua_json_get()', 'cygpath -w']:
    if term not in flavor_helper:
        errors.append(f'flavor-helper missing Windows/Python compatibility helper: {term}')
for hook_file in ['hooks/frustration-trigger.sh', 'hooks/failure-detector.sh', 'hooks/session-restore.sh', 'hooks/stop-feedback.sh']:
    hook_text = (root / hook_file).read_text(encoding='utf-8')
    if 'pua_json_get' not in hook_text:
        errors.append(f'{hook_file} must read config through pua_json_get')

# Open issue regression guards
required_paths = [
    'commands/offline.md',
    'codex/pua-on/SKILL.md',
    'codex/pua-off/SKILL.md',
    'codex/pua-p7/SKILL.md',
    'codex/pua-p9/SKILL.md',
    'codex/pua-p10/SKILL.md',
    'pi/pua/index.ts',
    'pi/pua/INSTALL.md',
    'pi/package/package.json',
    'pi/package/extensions/pua/index.ts',
    'pi/package/skills/pua/SKILL.md',
    'trae/INSTALL.md',
    'trae/DIFF.md',
    'trae/pua.md',
    '.trae/skills/pua/SKILL.md',
    '.trae/skills/pua-en/SKILL.md',
    '.trae/skills/pua-trae/SKILL.md',
    'docs/FAQ.md',
    'landing/migrations/0003_feedback_rate_limits.sql',
    'evals/test-platform-compat.sh',
    'evals/test-feedback-auth.sh',
    'evals/test-microsoft-flavor.sh',
    'evals/test-heartbeat.sh',
    'evals/test-upload-flow.sh',
    'hooks/heartbeat.sh',
    'landing/functions/api/heartbeat.ts',
    'landing/migrations/0004_heartbeat.sql',
    'landing/migrations/0005_upload_rate_limits.sql',
    'landing/src/pages/AdminStats.tsx',
    'skills/pua/references/methodology-microsoft.md',
]
for rel in required_paths:
    if not (root / rel).exists():
        errors.append(f'missing issue-sweep asset: {rel}')

# D1 migrations must be idempotent because existing production DBs may predate
# Wrangler's migration journal. A non-idempotent CREATE INDEX previously made
# `wrangler d1 migrations apply --remote` fail on 0001 before newer migrations.
for migration in sorted((root / 'landing/migrations').glob('*.sql')):
    text_sql = migration.read_text(encoding='utf-8')
    if 'CREATE INDEX ' in text_sql:
        for line in text_sql.splitlines():
            stripped = line.strip().upper()
            if stripped.startswith('CREATE INDEX ') and not stripped.startswith('CREATE INDEX IF NOT EXISTS '):
                errors.append(f'D1 migration has non-idempotent index creation: {migration.relative_to(root)}')
frustration = (root / 'hooks/frustration-trigger.sh').read_text(encoding='utf-8')
for term in ['TRIGGER_RE', 'PUA Skill Context']:
    if term not in frustration:
        errors.append(f'frustration trigger missing internal filter/context term: {term}')
if 'MUST invoke' in frustration or 'PUA behavioral enforcement' in frustration:
    errors.append('frustration trigger still contains coercive injection wording')
stop_feedback = (root / 'hooks/stop-feedback.sh').read_text(encoding='utf-8')
if '/tmp/pua-plugin-root' in stop_feedback:
    errors.append('stop-feedback must not use /tmp/pua-plugin-root')
if 'offline' not in stop_feedback:
    errors.append('stop-feedback must honor offline config')
feedback_api = (root / 'landing/functions/api/feedback.ts').read_text(encoding='utf-8')
for term in ['MAX_BODY_BYTES', 'MAX_SESSION_DATA_BYTES', 'RATE_LIMIT_MAX_WRITES', 'ALLOWED_ORIGINS', 'getSession(request, env.SESSION_SECRET)', 'Login required for session upload']:
    if term not in feedback_api:
        errors.append(f'feedback endpoint missing abuse-control term: {term}')
stop_feedback = (root / 'hooks/stop-feedback.sh').read_text(encoding='utf-8')
if "json.dumps({'rating': 'session_upload', 'session_data': data})" in stop_feedback:
    errors.append('stop-feedback must not anonymously post session_data to feedback endpoint')
for term in ['X-PUA-Upload-Consent', '--data-binary @', '/api/upload']:
    if term not in stop_feedback:
        errors.append(f'stop-feedback missing anonymous direct upload term: {term}')
for forbidden_stop_term in ['GitHub login', '登录后上传']:
    if forbidden_stop_term in stop_feedback:
        errors.append(f'stop-feedback should not require GitHub login for direct session upload: {forbidden_stop_term}')
if '[PUA-DIAGNOSIS]' not in (root / 'skills/pua/SKILL.md').read_text(encoding='utf-8'):
    errors.append('pua skill missing diagnosis-first rule')
if '军令状' not in (root / 'skills/pua/references/methodology-huawei.md').read_text(encoding='utf-8'):
    errors.append('Huawei methodology missing military-order mode')
for scan_rel in ['agents', 'commands', 'skills/pua/references']:
    for path in (root / scan_rel).rglob('*'):
        if path.is_file() and '下场' in path.read_text(encoding='utf-8', errors='ignore'):
            errors.append(f'ambiguous 下场 wording remains in {path.relative_to(root)}')

session_restore = (root / 'hooks/session-restore.sh').read_text(encoding='utf-8')
if 'Harness Integrity (anti-cheating governance)' not in session_restore:
    errors.append('SessionStart protocol missing Harness Integrity governance injection')
if 'Multi-Agent Governance Topology' not in session_restore:
    errors.append('SessionStart protocol missing Multi-Agent Governance Topology injection')

if not any(any('heartbeat.sh' in hook.get('command', '') for hook in item.get('hooks', [])) for item in hooks_json.get('hooks', {}).get('SessionStart', [])):
    errors.append('SessionStart missing silent heartbeat.sh registration')
heartbeat_hook = (root / 'hooks/heartbeat.sh').read_text(encoding='utf-8') if (root / 'hooks/heartbeat.sh').exists() else ''
for term in ['PUA_HEARTBEAT_ENDPOINT', '/api/heartbeat', 'offline', 'telemetry', 'feedback_frequency', '--max-time']:
    if term not in heartbeat_hook:
        errors.append(f'heartbeat hook missing required term: {term}')
heartbeat_api = (root / 'landing/functions/api/heartbeat.ts').read_text(encoding='utf-8') if (root / 'landing/functions/api/heartbeat.ts').exists() else ''
for term in ['ADMIN_GITHUB_LOGINS', 'getSession(request, env.SESSION_SECRET)', 'heartbeat_installs', 'heartbeat_events', 'COUNT(DISTINCT install_id_hash)', 'sha256Hex']:
    if term not in heartbeat_api:
        errors.append(f'heartbeat endpoint missing required term: {term}')

app_tsx = (root / 'landing/src/App.tsx').read_text(encoding='utf-8')
contribute_tsx = (root / 'landing/src/pages/Contribute.tsx').read_text(encoding='utf-8')
for term in ['pathname', '/contribute.html', '#/contribute']:
    if term not in app_tsx:
        errors.append(f'upload flow missing required term in App.tsx: {term}')
for term in ['file.text()', 'application/jsonl', 'X-PUA-File-Name', 'X-PUA-Wechat-Id']:
    if term not in contribute_tsx:
        errors.append(f'upload flow missing required term in Contribute.tsx: {term}')
for forbidden_upload_term in ['new FormData()', 'readFileAsBase64', 'file_data: fileData']:
    if forbidden_upload_term in contribute_tsx:
        errors.append(f'upload flow must not rely on bloated/multipart browser upload path: {forbidden_upload_term}')

for forbidden in ['Applies to ALL task types', 'All task types', 'code, config, debug, deploy, research']:
    if forbidden in skill.split('---', 2)[1]:
        errors.append(f'pua skill description is too broad and may false-trigger: {forbidden}')
if 'Do not trigger for normal first-attempt coding or information requests.' not in skill.split('---', 2)[1]:
    errors.append('pua skill description must explicitly exclude normal first-attempt requests')

command = (root / 'commands/pua.md').read_text(encoding='utf-8')
command_frontmatter = command.split('---', 2)[1]
if 'Use only when the user explicitly invokes /pua' not in command_frontmatter:
    errors.append('pua slash command description must be explicit-invocation only')
if '任务描述]' in command_frontmatter or '任意任务描述' in command_frontmatter:
    errors.append('pua slash command frontmatter is too broad and may false-trigger')

hook = (root / 'hooks/pua-loop-hook.sh').read_text(encoding='utf-8')
if 'run_with_timeout 120 bash -c "$VERIFY_CMD"' not in hook:
    errors.append('pua-loop hook does not use portable run_with_timeout for verify_command')
if 'VERIFY_OUTPUT=$(timeout 120 bash -c "$VERIFY_CMD"' in hook:
    errors.append('pua-loop hook still calls GNU timeout directly')

helpers = (root / 'evals/test-helpers.sh').read_text(encoding='utf-8')
trigger = (root / 'evals/run-trigger-test.sh').read_text(encoding='utf-8')
if 'run_with_timeout()' not in helpers:
    errors.append('eval helper missing portable run_with_timeout')
if '    timeout 120 claude' in trigger or '    timeout 90 claude' in helpers:
    errors.append('eval scripts still call GNU timeout directly')
if '--output-format stream-json' in trigger and '--verbose' not in trigger:
    errors.append('trigger eval uses stream-json without --verbose')
if 'PUA_CONFIG="$EVAL_PUA_CONFIG" run_with_timeout 120 claude' not in trigger:
    errors.append('trigger eval must use isolated PUA_CONFIG to avoid user ~/.pua/config.json')
if 'observable PUA behavior as triggered' not in trigger:
    errors.append('trigger eval must accept observable PUA behavior fallback to reduce Skill-tool flake')
if 'EVAL_WORKSPACE="$RESULTS_DIR/workspace"' not in trigger or 'cd "$EVAL_WORKSPACE"' not in trigger:
    errors.append('trigger eval must run in a neutral workspace, not the pua plugin repo')
if 'PUA_CONFIG="$eval_config" run_with_timeout 90 claude' not in helpers:
    errors.append('behavior eval must use isolated PUA_CONFIG to avoid user ~/.pua/config.json')

readme_en = (root / 'README.md').read_text(encoding='utf-8')
readme_zh = (root / 'README.zh-CN.md').read_text(encoding='utf-8')
for text, label in [(readme_en, 'README.md'), (readme_zh, 'README.zh-CN.md')]:
    if 'Codex hooks' not in text and 'Codex Hook' not in text:
        errors.append(f'{label} must document Codex hooks support')
    if 'other platforms install the core skill only' in text or '其他平台使用核心 skill，不含 hook' in text:
        errors.append(f'{label} still claims Codex lacks hook/sub-mode support')

if errors:
    print('=== Release consistency FAILED ===')
    for e in errors:
        print(' -', e)
    sys.exit(1)

print('=== Release consistency OK ===')
print('version =', version)
print('manifests checked =', len(manifest_files))
print('confidence/harness/agent terms checked =', len(required_terms))
PY
