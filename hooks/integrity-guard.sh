#!/usr/bin/env bash
# PUA Integrity Guard — PreToolUse anti-cheating gate
# Separates action rights from scoring / verifier / environment-modification rights.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/flavor-helper.sh"
PUA_PY="$(pua_python_cmd 2>/dev/null || true)"
[ -n "$PUA_PY" ] || exit 0
PUA_CONFIG_PY="$(pua_to_python_path "$(pua_config_file)")"
export PUA_CONFIG_PY

TMP_INPUT=$(mktemp)
trap 'rm -f "$TMP_INPUT"' EXIT
cat > "$TMP_INPUT"

"$PUA_PY" - "$TMP_INPUT" <<'PY'
import json
import os
import re
import shlex
import sys
from pathlib import Path

input_path = Path(sys.argv[1])
try:
    data = json.loads(input_path.read_text(encoding='utf-8') or '{}')
except Exception:
    sys.exit(0)

PUA_MARKERS = [
    'PUA ACTIVATED',
    'PUA Always-On',
    'PUA生效',
    '[PUA',
    'pua:pua',
    'pua-loop',
    'Confidence Gate',
]


def read_text_tail(path: str, max_bytes: int = 200_000) -> str:
    try:
        p = Path(path).expanduser()
        if not p.is_file():
            return ''
        size = p.stat().st_size
        with p.open('rb') as f:
            if size > max_bytes:
                f.seek(size - max_bytes)
            return f.read().decode('utf-8', errors='ignore')
    except Exception:
        return ''


def config_always_on() -> bool:
    cfg = os.environ.get('PUA_CONFIG_PY') or os.environ.get('PUA_CONFIG') or str(Path.home() / '.pua' / 'config.json')
    try:
        return bool(json.loads(Path(cfg).expanduser().read_text(encoding='utf-8')).get('always_on', False))
    except Exception:
        return False


def is_active() -> bool:
    if os.environ.get('PUA_INTEGRITY_FORCE') == '1' or os.environ.get('PUA_FORCE_ON') == '1':
        return True
    if config_always_on():
        return True
    transcript = data.get('transcript_path') or ''
    text = read_text_tail(transcript)
    return any(marker in text for marker in PUA_MARKERS)

if not is_active():
    sys.exit(0)

tool = data.get('tool_name') or ''
tool_input = data.get('tool_input') or {}

# Keep these patterns intentionally conservative: they target governance assets,
# not ordinary application files.
PROTECTED_WRITE_PATTERNS = [
    (re.compile(r'(^|/)(tests?|__tests__|test|spec|evals?|e2e|cypress|playwright)(/|$)|\.(test|spec)\.[A-Za-z0-9]+$|(^|/)(playwright|cypress)\.config\.', re.I), 'Grader gaming risk: tests/evals/E2E assets are scoring-adjacent.'),
    (re.compile(r'(^|/)(score|scoring|grader|verifier)(\.[A-Za-z0-9]+)?$|(^|/)(scoring|grader|verifier)(/|$)', re.I), 'Grader gaming risk: scoring/verifier assets must not be changed by the executor.'),
    (re.compile(r'(^|/)\.github/workflows(/|$)|(^|/)ci(/|$)|(^|/)(buildkite|circleci|jenkins)(/|$)', re.I), 'Environment-modification risk: CI gates are part of the verifier boundary.'),
    (re.compile(r'(^|/)(feature_contracts\.json|claude-progress\.md|progress\.json|status\.json)$', re.I), 'Self-report cheating risk: status/progress files need verifier ownership.'),
    (re.compile(r'(^|/)(memory|memories)(/|$)|(^|/)(decisions|failures)\.log\.jsonl$|(^|/)CLAUDE\.md$|(^|/)\.claude/(settings|settings\.local)\.json$', re.I), 'Persistent-memory risk: long-term memory/status must be append-only or approved.'),
    (re.compile(r'(^|/)\.env(\.|$)|(^|/)(secrets?|credentials?)(\.|/|$)', re.I), 'Capability-abuse risk: secrets and environment files require human gate.'),
]

CONTAMINATION_PATTERNS = [
    (re.compile(r'(^|/)(hidden[-_]?tests?|verifier[-_]?private|private[-_]?verifier|hidden[-_]?cases?)(/|$)', re.I), 'Solution contamination risk: hidden tests/verifier-private assets must stay outside the agent workspace.'),
    (re.compile(r'(^|/)(hidden_solution|gold_patch|golden_patch|benchmark_answers?|answer_key|official_solution)(\.|/|$)', re.I), 'Solution contamination risk: hidden solution / benchmark answer artifact detected.'),
]

SENSITIVE_READ_PATTERNS = [
    (re.compile(r'(^|/)\.env(\.|$)|(^|/)(secrets?|credentials?)(\.|/|$)|(^|/)(id_rsa|id_ed25519|private[-_]?key)(\.|$)', re.I), 'Capability-abuse risk: secrets and credentials require human gate.'),
]


def load_excluded_patterns():
    """User-configurable allowlist of path patterns exempt from all integrity-guard advisories.

    Source: $PUA_INTEGRITY_EXCLUSIONS env var, else ~/.pua/integrity-guard-exclusions.json.
    Format: {"patterns": ["regex1", "regex2", ...]} or a bare JSON array of strings.
    Patterns compile with re.I and match via re.search against forward-slash-normalized paths.
    Missing/malformed config → empty list (no behavioral change vs current default).
    """
    cfg = os.environ.get('PUA_INTEGRITY_EXCLUSIONS') or str(Path.home() / '.pua' / 'integrity-guard-exclusions.json')
    try:
        data = json.loads(Path(cfg).expanduser().read_text(encoding='utf-8'))
    except Exception:
        return []
    if isinstance(data, dict):
        raw = data.get('patterns') or []
    elif isinstance(data, list):
        raw = data
    else:
        raw = []
    compiled = []
    for p in raw:
        if not isinstance(p, str):
            continue
        try:
            compiled.append(re.compile(p, re.I))
        except re.error:
            continue
    return compiled


EXCLUDED_PATH_PATTERNS = load_excluded_patterns()


MUTATING_BASH = re.compile(
    r'(^|[;&|()\s])(rm|mv|cp|chmod|chown|truncate|tee|touch|mkdir|rmdir|git\s+(reset|clean|checkout|restore)|sed\s+(-i|--in-place)|perl\s+-p?i|python3?\s+.*open\(|node\s+.*writeFile|npm\s+version)\b|>>|>[^&]',
    re.I | re.S,
)
READING_BASH = re.compile(r'(^|[;&|()\s])(cat|less|more|head|tail|sed|awk|grep|rg|find|python3?|node)\b', re.I)
WEB_CONTAMINATION = re.compile(r'(hidden[-_\s]+solution|official[-_\s]+solution|gold[-_\s]+patch|benchmark[-_\s]+answer|swe[-_\s]?bench[-_\s]+solution|leaderboard[-_\s]+answer)', re.I)


def is_mutating_command(command: str) -> bool:
    if MUTATING_BASH.search(command):
        return True
    # Python one-liners often hide writes inside quoted code, so detect common
    # write APIs separately instead of relying on shell-token boundaries.
    return bool(re.search(r'python3?\s+.*(open\(|write_text\(|write_bytes\(|Path\([^)]*\)\.write)', command, re.I | re.S))


def norm_path(p: str) -> str:
    if not p:
        return ''
    return p.replace('\\', '/')


def is_excluded_path(path: str) -> bool:
    if not EXCLUDED_PATH_PATTERNS:
        return False
    n = norm_path(path)
    return any(rx.search(n) for rx in EXCLUDED_PATH_PATTERNS)


def collect_paths(value):
    paths = []
    if isinstance(value, dict):
        for k, v in value.items():
            if k in {'file_path', 'path', 'notebook_path', 'pattern', 'glob'} and isinstance(v, str):
                paths.append(v)
            else:
                paths.extend(collect_paths(v))
    elif isinstance(value, list):
        for item in value:
            paths.extend(collect_paths(item))
    return paths


def find_reason_for_path(path: str, include_write: bool):
    n = norm_path(path)
    if is_excluded_path(n):
        return None
    for rx, reason in CONTAMINATION_PATTERNS:
        if rx.search(n):
            return 'deny', reason, n
    for rx, reason in SENSITIVE_READ_PATTERNS:
        if rx.search(n):
            return 'advisory', reason, n
    if include_write:
        for rx, reason in PROTECTED_WRITE_PATTERNS:
            if rx.search(n):
                return 'advisory', reason, n
    return None


def command_tokens(command: str):
    try:
        return shlex.split(command)
    except Exception:
        return re.split(r'\s+', command)


def path_candidates(tokens):
    for token in tokens:
        if not token:
            continue
        stripped = token.strip("\"'`")
        if stripped:
            yield stripped
        # Pull paths embedded inside code strings, e.g. open("tests/fixtures.json", "w").
        for match in re.findall(r'[A-Za-z0-9_.@+~:-]+(?:/[A-Za-z0-9_.@+~:-]+)+', token.replace('\\', '/')):
            yield match


SSH_IDENTITY_RE = re.compile(r'\bssh\b.*-i\s', re.I)
SSH_KEY_PATH_RE = re.compile(r'(^|/)\.ssh/(id_|.*[-_]key)', re.I)


def is_ssh_identity_usage(command: str, candidate: str) -> bool:
    if not SSH_IDENTITY_RE.search(command):
        return False
    return bool(SSH_KEY_PATH_RE.search(norm_path(candidate)))


def command_hits(command: str):
    tokens = [t for t in command_tokens(command) if t]
    candidates = list(path_candidates(tokens))
    normalized = command.replace('\\', '/')

    # Hidden/private solution artifacts are blocked even for read-like commands.
    for candidate in candidates:
        for rx, reason in CONTAMINATION_PATTERNS:
            if rx.search(norm_path(candidate)):
                return 'deny', reason, candidate
    for rx, reason in CONTAMINATION_PATTERNS:
        m = rx.search(normalized)
        if m:
            return 'deny', reason, m.group(0)
    if WEB_CONTAMINATION.search(command):
        return 'deny', 'Solution contamination risk: command appears to search/fetch benchmark or hidden answers.', command[:160]
    if READING_BASH.search(command):
        for candidate in candidates:
            if is_ssh_identity_usage(command, candidate):
                continue
            for rx, reason in SENSITIVE_READ_PATTERNS:
                if rx.search(norm_path(candidate)):
                    return 'advisory', reason, candidate

    # Protected scoring assets need a human gate only when the command mutates them.
    if is_mutating_command(command):
        # Bucket candidates so we can ignore excluded paths at every layer.
        excluded_hits = [c for c in candidates if is_excluded_path(c)]
        non_excluded_candidates = [c for c in candidates if not is_excluded_path(c)]
        for candidate in non_excluded_candidates:
            for rx, reason in PROTECTED_WRITE_PATTERNS:
                if rx.search(norm_path(candidate)):
                    return 'advisory', reason, candidate
        # Fallback whole-command regex: skip if the command involved any
        # excluded path — the regex would just rediscover it via substring
        # match (e.g. `touch /repo/excluded-view/CLAUDE.md` re-matching
        # `(^|/)CLAUDE\.md$` against the literal command string).
        if not excluded_hits:
            for rx, reason in PROTECTED_WRITE_PATTERNS:
                m = rx.search(normalized)
                if m:
                    return 'advisory', reason, m.group(0)
    return None

hit = None

if tool in {'Write', 'Edit', 'MultiEdit'}:
    for path in collect_paths(tool_input):
        hit = find_reason_for_path(path, include_write=True)
        if hit:
            break
elif tool in {'Read', 'Grep', 'Glob'}:
    for path in collect_paths(tool_input):
        hit = find_reason_for_path(path, include_write=False)
        if hit:
            break
elif tool == 'Bash':
    command = str(tool_input.get('command') or '')
    hit = command_hits(command)
elif tool in {'WebSearch', 'WebFetch'}:
    query = '\n'.join(str(tool_input.get(k) or '') for k in ('query', 'url', 'prompt'))
    if WEB_CONTAMINATION.search(query):
        hit = ('deny', 'Solution contamination risk: searching for benchmark/hidden answers can poison the task.', query[:160])

if not hit:
    sys.exit(0)

decision, reason, target = hit
message = (
    'PUA Integrity Guard: ' + reason +
    ' Four-power separation is active: action right, self-evaluation right, scoring right, and environment-modification right must remain separate. '
    f'Target: {target}'
)

output = {'hookSpecificOutput': {'hookEventName': 'PreToolUse'}}
if decision == 'deny':
    output['hookSpecificOutput']['permissionDecision'] = 'deny'
    output['hookSpecificOutput']['permissionDecisionReason'] = message
    output['hookSpecificOutput']['additionalContext'] = (
        'PUA Integrity Guard: DENY — ' + reason + f' Target: {target}'
    )
else:
    output['hookSpecificOutput']['additionalContext'] = (
        'PUA Integrity Guard (advisory): ' + reason + f' Target: {target}'
    )
print(json.dumps(output, ensure_ascii=False, separators=(',', ':')))
PY
