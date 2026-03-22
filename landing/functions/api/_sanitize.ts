// Sanitization logic ported from hooks/sanitize-session.sh
// Patterns are compiled ONCE at module scope — never re-compiled per request.
// Applied to raw JSONL text (no JSON.parse overhead, ~5-10x faster than per-value walk).

// ── Layer 1: Known-format blacklist ───────────────────────────────────────────
// Order matters: specific prefixes before generic ones (e.g. sk-ant- before sk-)
const L1: [RegExp, string][] = [
  // File paths — quoted forms first, then unquoted
  [/"\/Users\/[^"\n]+"/g,                               '"[PATH]"'],
  [/\/Users\/[^\s\n"'`]+/g,                              '[PATH]'],
  [/"\/home\/[^"\n]+"/g,                                '"[PATH]"'],
  [/\/home\/[^\s\n"'`]+/g,                               '[PATH]'],
  [/\/root\/[^\s\n"'`]+/g,                               '[PATH]'],
  [/\/mnt\/[a-z]\/[^\s\n"'`]+/g,                        '[PATH]'],
  [/\/[a-z]\/(?:Users|home)\/[^\s\n"'`]+/g,             '[PATH]'],
  [/[A-Za-z]:\\[^\s\n"]+/g,                              '[PATH]'],
  [/[A-Za-z]:\/[A-Za-z][^\s\n"]+/g,                     '[PATH]'],

  // Anthropic / OpenAI — specific prefixes before generic sk-
  [/sk-ant-[a-zA-Z0-9_-]{20,}/g,                        '[API_KEY]'],
  [/sk-proj-[a-zA-Z0-9_-]{20,}/g,                       '[API_KEY]'],
  [/sk-[a-zA-Z0-9]{20,}/g,                              '[API_KEY]'],

  // Stripe
  [/sk_(?:live|test)_[a-zA-Z0-9]{24,}/g,                '[STRIPE_KEY]'],
  [/pk_(?:live|test)_[a-zA-Z0-9]{24,}/g,                '[STRIPE_KEY]'],
  [/rk_(?:live|test)_[a-zA-Z0-9]{24,}/g,                '[STRIPE_KEY]'],

  // GitHub
  [/github_pat_[a-zA-Z0-9_]{40,}/g,                     '[GITHUB_TOKEN]'],
  [/gh[opsr]_[a-zA-Z0-9]{36}/g,                         '[GITHUB_TOKEN]'],

  // AWS
  [/AKIA[A-Z0-9]{16}/g,                                  '[AWS_KEY]'],

  // International services
  [/glpat-[a-zA-Z0-9_-]{20}/g,                          '[GITLAB_TOKEN]'],
  [/xox[bpas]-[0-9A-Za-z-]+/g,                          '[SLACK_TOKEN]'],
  [/hf_[a-zA-Z0-9]{30,}/g,                              '[HF_TOKEN]'],
  [/npm_[a-zA-Z0-9]{36}/g,                              '[NPM_TOKEN]'],
  [/AIza[0-9A-Za-z_-]{35}/g,                            '[FIREBASE_KEY]'],
  [/SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}/g,        '[SENDGRID_KEY]'],
  [/AC[a-f0-9]{32}/g,                                    '[TWILIO_SID]'],

  // Chinese cloud
  [/LTAI[a-zA-Z0-9]{16,20}/g,                           '[ALIYUN_KEY]'],
  [/AKID[a-zA-Z0-9]{32,}/g,                             '[TENCENT_KEY]'],

  // Auth tokens
  [/ya29\.[a-zA-Z0-9_-]{60,}/g,                         '[GOOGLE_OAUTH]'],
  [/eyJ[a-zA-Z0-9_-]{20,}/g,                            '[JWT]'],
  [/Bearer\s+[a-zA-Z0-9_./-]{10,}/g,                    '[BEARER_TOKEN]'],

  // PEM private keys ([\s\S]*? handles both literal newlines and \\n in JSON strings)
  [/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----[\s\S]*?-----END (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/gs,
                                                          '[PRIVATE_KEY]'],

  // Database URLs
  [/(?:postgresql|mysql|mongodb(?:\+srv)?|redis|mssql):\/\/[^\s"']+/g, '[DB_URL]'],

  // PII
  [/[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/g, '[EMAIL]'],
  [/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/g,           '[IP]'],
  [/\b1[3-9]\d{9}\b/g,                                   '[CN_PHONE]'],
  [/ssh-(?:rsa|ed25519|ecdsa)\s+\S+/g,                   '[SSH_KEY]'],

  // Credentials in URLs (://user:pass@)
  [/:\/\/[^:"'\s]+:[^@"'\s]+@/g,                        '://[CRED]@'],

  // Query-param credentials (?key=value)
  [/[?&](?:password|passwd|pwd|secret|token|api_?key)=[^&\s"']+/g, '[QUERYPARAM_CRED]'],
]

// ── Layer 2: K=V context-aware redaction ──────────────────────────────────────
// The _KV alternation is built as a string so we can compose it into multiple patterns.
// Note: [_\\-] in the string becomes [_\-] in the regex (literal hyphen, escaped to be safe).
const _KV =
  '(?:password|passwd|pwd|secret' +
  '|api[_\\-]?key|apikey|app[_\\-]?key' +
  '|access[_\\-]?key|secret[_\\-]?key|private[_\\-]?key' +
  '|auth[_\\-]?token|access[_\\-]?token|refresh[_\\-]?token' +
  '|client[_\\-]?secret|app[_\\-]?secret' +
  '|db[_\\-]?pass(?:word)?|database[_\\-]?(?:url|password)' +
  '|encryption[_\\-]?key|signing[_\\-]?key' +
  '|密钥|密码|口令)'

// Replacements use $1 (JS backreference) to preserve the key name.
// gi = global + case-insensitive, matching Python's (?i) flag.
const L2: [RegExp, string][] = [
  // KEY="VALUE"  (env file double-quoted)
  [new RegExp(`(${_KV})\\s*=\\s*"([^"]{8,})"`, 'gi'),          '$1="[REDACTED]"'],
  // KEY='VALUE'  (env file single-quoted)
  [new RegExp(`(${_KV})\\s*=\\s*'([^']{8,})'`, 'gi'),          "$1='[REDACTED]'"],
  // KEY=VALUE or KEY = VALUE  (env file, shell, unquoted)
  [new RegExp(`(${_KV})\\s*=\\s*([^\\s\\n"']{8,})`, 'gi'),     '$1=[REDACTED]'],
  // export KEY=VALUE  (shell)
  [new RegExp(`export\\s+(${_KV})\\s*=\\s*([^\\s\\n"']{8,})`, 'gi'), 'export $1=[REDACTED]'],
  // "key": "value"  (JSON)
  [new RegExp(`"(${_KV})"\\s*:\\s*"([^"]{8,})"`, 'gi'),         '"$1": "[REDACTED]"'],
  // key: value  (YAML unquoted)
  [new RegExp(`(${_KV})\\s*:\\s*([a-zA-Z0-9_\\-+/]{12,})`, 'gi'), '$1: [REDACTED]'],
]

// ── Layer 3: Shannon entropy detection ───────────────────────────────────────
// Flags 32+ char alphanumeric tokens with entropy > threshold.
// Pure hex strings (git hashes, UUIDs) use a higher threshold to avoid false positives.
const _ENTROPY_TOKEN_RE = /[A-Za-z0-9+\/=_\-]{32,}/g
const _PURE_HEX_RE = /^[0-9a-f]+$/

function _entropy(s: string): number {
  const freq = new Map<string, number>()
  for (const c of s) freq.set(c, (freq.get(c) ?? 0) + 1)
  const n = s.length
  let h = 0
  for (const count of freq.values()) {
    const p = count / n
    h -= p * Math.log2(p)
  }
  return h
}

function _redactEntropy(text: string): string {
  // .replace() with a global regex always starts from position 0 regardless of
  // the regex object's lastIndex — safe to use module-scope compiled regex here.
  return text.replace(_ENTROPY_TOKEN_RE, (m) => {
    // Pure hex strings (git hashes, UUIDs) have theoretical max entropy = log2(16) = 4.0;
    // use 4.1 so they are never flagged.
    const threshold = _PURE_HEX_RE.test(m) ? 4.1 : 3.5
    return _entropy(m) > threshold ? '[HIGH_ENTROPY_SECRET]' : m
  })
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Sanitize a single line of raw text through all 3 layers.
 * Internal — exposed for testing.
 */
export function sanitizeLine(line: string): string {
  for (const [pat, rep] of L1) line = line.replace(pat, rep)
  for (const [pat, rep] of L2) line = line.replace(pat, rep)
  return _redactEntropy(line)
}

/**
 * Sanitize raw JSONL text using the same 3-layer logic as sanitize-session.sh.
 *
 * Processes line-by-line so peak memory stays at ~2× single-line size rather
 * than ~2× entire-file size. Critical for files approaching the 50MB upload limit
 * under Cloudflare Workers' 128MB memory cap.
 */
export function sanitize(text: string): string {
  return text
    .split("\n")
    .map(sanitizeLine)
    .join("\n")
}
