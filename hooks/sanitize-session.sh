#!/bin/bash
# PUA session sanitizer — strips sensitive data before upload
# Layers: (1) known-format blacklist  (2) K=V context-aware  (3) Shannon entropy
# Usage: bash sanitize-session.sh [input.jsonl] [output.jsonl]

INPUT="${1:-$(ls -t ~/.claude/projects/*/*.jsonl 2>/dev/null | head -1)}"
OUTPUT="${2:-/tmp/pua-sanitized-session.jsonl}"

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  echo "No session file found" >&2
  exit 1
fi

export PUA_INPUT="$INPUT"
export PUA_OUTPUT="$OUTPUT"

python3 - << 'PYEOF'
import os, json, re, math
from collections import Counter

input_file  = os.environ["PUA_INPUT"]
output_file = os.environ["PUA_OUTPUT"]

# ── Layer 1: Known-format blacklist ──────────────────────────────────────────
PATTERNS = [
    # --- File paths ---
    # Quoted forms first (handles spaces in path); unquoted forms follow
    (r'"/Users/[^"\n]+"',                                         '"[PATH]"'), # macOS quoted
    (r"/Users/[^\s\n\"'`]+",                                      "[PATH]"),   # macOS unquoted
    (r'"/home/[^"\n]+"',                                          '"[PATH]"'), # Linux quoted
    (r"/home/[^\s\n\"'`]+",                                       "[PATH]"),   # Linux unquoted
    (r"/root/[^\s\n\"'`]+",                                       "[PATH]"),   # Linux root
    (r"/mnt/[a-z]/[^\s\n\"'`]+",                                  "[PATH]"),   # WSL
    (r"/[a-z]/(?:Users|home)/[^\s\n\"'`]+",                       "[PATH]"),   # Git Bash (/c/Users/...)
    (r"[A-Za-z]:\\[^\s\n\"]+",                                    "[PATH]"),   # Windows backslash
    (r"[A-Za-z]:/[A-Za-z][^\s\n\"]+",                             "[PATH]"),   # Windows forward-slash

    # --- Anthropic / OpenAI (specific prefixes first, generic last) ---
    (r"sk-ant-[a-zA-Z0-9_-]{20,}",                               "[API_KEY]"),
    (r"sk-proj-[a-zA-Z0-9_-]{20,}",                              "[API_KEY]"),
    (r"sk-[a-zA-Z0-9]{20,}",                                     "[API_KEY]"),

    # --- Stripe ---
    (r"sk_(?:live|test)_[a-zA-Z0-9]{24,}",                       "[STRIPE_KEY]"),
    (r"pk_(?:live|test)_[a-zA-Z0-9]{24,}",                       "[STRIPE_KEY]"),
    (r"rk_(?:live|test)_[a-zA-Z0-9]{24,}",                       "[STRIPE_KEY]"),

    # --- GitHub ---
    (r"github_pat_[a-zA-Z0-9_]{40,}",                            "[GITHUB_TOKEN]"),  # fine-grained PAT
    (r"gh[opsr]_[a-zA-Z0-9]{36}",                                "[GITHUB_TOKEN]"),  # ghp_/gho_/ghs_/ghr_

    # --- AWS ---
    (r"AKIA[A-Z0-9]{16}",                                         "[AWS_KEY]"),

    # --- International services ---
    (r"glpat-[a-zA-Z0-9_-]{20}",                                 "[GITLAB_TOKEN]"),
    (r"xox[bpas]-[0-9A-Za-z-]+",                                 "[SLACK_TOKEN]"),
    (r"hf_[a-zA-Z0-9]{30,}",                                     "[HF_TOKEN]"),
    (r"npm_[a-zA-Z0-9]{36}",                                     "[NPM_TOKEN]"),
    (r"AIza[0-9A-Za-z_-]{35}",                                   "[FIREBASE_KEY]"),
    (r"SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}",               "[SENDGRID_KEY]"),
    (r"AC[a-f0-9]{32}",                                           "[TWILIO_SID]"),

    # --- Chinese cloud services ---
    (r"LTAI[a-zA-Z0-9]{16,20}",                                  "[ALIYUN_KEY]"),    # Alibaba Cloud AK
    (r"AKID[a-zA-Z0-9]{32,}",                                    "[TENCENT_KEY]"),   # Tencent Cloud SecretId

    # --- Auth tokens ---
    (r"ya29\.[a-zA-Z0-9_-]{60,}",                                "[GOOGLE_OAUTH]"),
    (r"eyJ[a-zA-Z0-9_-]{20,}",                                   "[JWT]"),
    (r"Bearer\s+[a-zA-Z0-9_./-]{10,}",                           "[BEARER_TOKEN]"),

    # --- PEM private keys (multiline) ---
    (r"(?s)-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----.*?-----END (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
                                                                   "[PRIVATE_KEY]"),

    # --- Database connection strings ---
    (r"(?:postgresql|mysql|mongodb(?:\+srv)?|redis|mssql)://[^\s\"']+",
                                                                   "[DB_URL]"),

    # --- PII ---
    (r"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}",       "[EMAIL]"),
    (r"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b",                  "[IP]"),
    (r"\b1[3-9]\d{9}\b",                                           "[CN_PHONE]"),  # Chinese mobile
    (r"ssh-(?:rsa|ed25519|ecdsa)\s+\S+",                           "[SSH_KEY]"),

    # --- Credentials in URLs ---
    (r"://[^:\"'\s]+:[^@\"'\s]+@",                                "://[CRED]@"),
    (r"[?&](?:password|passwd|pwd|secret|token|api_?key)=[^&\s\"']+",
                                                                   "[QUERYPARAM_CRED]"),
]

# ── Layer 2: K=V context-aware redaction ────────────────────────────────────
_KV = (
    r"(?:password|passwd|pwd|secret|api[_-]?key|apikey|app[_-]?key|"
    r"access[_-]?key|secret[_-]?key|private[_-]?key|"
    r"auth[_-]?token|access[_-]?token|refresh[_-]?token|"
    r"client[_-]?secret|app[_-]?secret|"
    r"db[_-]?pass(?:word)?|database[_-]?(?:url|password)|"
    r"encryption[_-]?key|signing[_-]?key|"
    r"密钥|密码|口令)"
)

KV_PATTERNS = [
    # KEY="VALUE"  (env file with double-quoted values)
    (r'(?i)(' + _KV + r')\s*=\s*"([^"]{8,})"',                r'\1="[REDACTED]"'),
    # KEY='VALUE'  (env file with single-quoted values)
    (r"(?i)(" + _KV + r")\s*=\s*'([^']{8,})'",                r"\1='[REDACTED]'"),
    # KEY=VALUE or KEY = VALUE  (env file, shell, unquoted)
    (r"(?i)(" + _KV + r")\s*=\s*([^\s\n\"']{8,})",            r"\1=[REDACTED]"),
    # export KEY="VALUE"  (shell)
    (r"(?i)export\s+(" + _KV + r")\s*=\s*([^\s\n\"']{8,})",   r"export \1=[REDACTED]"),
    # "key": "value"  (JSON)
    (r'(?i)"(' + _KV + r')"\s*:\s*"([^"]{8,})"',               r'"\1": "[REDACTED]"'),
    # key: value  (YAML unquoted)
    (r"(?i)(" + _KV + r")\s*:\s*([a-zA-Z0-9_\-+/]{12,})",     r"\1: [REDACTED]"),
]

# ── Layer 3: Shannon entropy detection ──────────────────────────────────────
_TOKEN_RE = re.compile(r"[A-Za-z0-9+/=_\-]{32,}")
_PURE_HEX_RE = re.compile(r"^[0-9a-f]+$")  # git hashes, UUID hex — max entropy = log2(16) = 4.0

def _entropy(s):
    n = len(s)
    freq = Counter(s)
    return -sum((c / n) * math.log2(c / n) for c in freq.values())

def _redact_entropy(text):
    def _sub(m):
        s = m.group()
        # Pure lowercase hex strings (git hashes, UUIDs) have theoretical max entropy = 4.0;
        # use threshold 4.1 so they are never flagged as secrets.
        threshold = 4.1 if _PURE_HEX_RE.match(s) else 3.5
        return "[HIGH_ENTROPY_SECRET]" if _entropy(s) > threshold else s
    return _TOKEN_RE.sub(_sub, text)

# ── Sanitize ─────────────────────────────────────────────────────────────────
def sanitize(text):
    if not isinstance(text, str):
        return text
    for pat, rep in PATTERNS:
        text = re.sub(pat, rep, text)
    for pat, rep in KV_PATTERNS:
        text = re.sub(pat, rep, text)
    text = _redact_entropy(text)
    return text

def sanitize_obj(obj):
    if isinstance(obj, str):  return sanitize(obj)
    if isinstance(obj, dict): return {k: sanitize_obj(v) for k, v in obj.items()}
    if isinstance(obj, list): return [sanitize_obj(i) for i in obj]
    return obj

count = 0
skipped = 0
with open(input_file, encoding="utf-8") as f, open(output_file, "w", encoding="utf-8") as out:
    for line in f:
        try:
            out.write(json.dumps(sanitize_obj(json.loads(line)), ensure_ascii=False) + "\n")
            count += 1
        except Exception:
            skipped += 1

print(f"Sanitized {count} lines -> {output_file}" + (f" (skipped {skipped})" if skipped else ""))
PYEOF
