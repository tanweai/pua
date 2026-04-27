// D1-backed fixed-window rate limiter for anonymous POST endpoints.
// One row per (ip, hour-bucket). Check is atomic per-request: upsert-then-select.
// Old rows are swept lazily on ~1% of writes so the table stays bounded without a cron.

const WINDOW_SECONDS = 3600
const SWEEP_AGE_SECONDS = 6 * 3600

export interface RateLimitResult {
  allowed: boolean
  remaining: number
  limit: number
  retryAfter: number
}

function nowSec(): number {
  return Math.floor(Date.now() / 1000)
}

function windowStart(ts: number): number {
  return ts - (ts % WINDOW_SECONDS)
}

/**
 * Reserve one slot in the IP's current hour window.
 *
 * Returns allowed=false when the count would exceed `limit`. The existing
 * count is returned in `remaining` so callers can include it in 429 bodies.
 *
 * Notes:
 * - D1 uses SQLite's local transaction semantics — the INSERT…ON CONFLICT
 *   path is atomic enough for a rate limit. Concurrent increments under the
 *   same (ip, window) can race by 1-2 counts; acceptable for abuse control.
 * - `ip` is the raw CF-Connecting-IP. Pass "" or "unknown" for missing
 *   headers; the caller decides whether to block or use a stricter limit.
 */
export async function checkRateLimit(
  db: D1Database,
  ip: string,
  limit: number,
): Promise<RateLimitResult> {
  const now = nowSec()
  const window = windowStart(now)

  // Bump count for (ip, window). If the row is brand-new, count starts at 1.
  await db
    .prepare(
      `INSERT INTO feedback_rate_limits (ip, window_start, count)
       VALUES (?, ?, 1)
       ON CONFLICT(ip, window_start) DO UPDATE SET count = count + 1`,
    )
    .bind(ip, window)
    .run()

  const row = await db
    .prepare(
      `SELECT count FROM feedback_rate_limits WHERE ip = ? AND window_start = ?`,
    )
    .bind(ip, window)
    .first<{ count: number }>()

  const count = row?.count ?? 1

  // Lazy sweep — cheap, infrequent, avoids a cron trigger dependency.
  if (Math.random() < 0.01) {
    await db
      .prepare(`DELETE FROM feedback_rate_limits WHERE window_start < ?`)
      .bind(now - SWEEP_AGE_SECONDS)
      .run()
  }

  const retryAfter = window + WINDOW_SECONDS - now
  return {
    allowed: count <= limit,
    remaining: Math.max(0, limit - count),
    limit,
    retryAfter,
  }
}
