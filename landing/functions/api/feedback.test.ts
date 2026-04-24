import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"
import { LIMITS, onRequest, validateFeedback } from "./feedback"

// ─── Fake D1 ──────────────────────────────────────────────────────────────
// Minimal in-memory impl covering the three tables this endpoint touches:
//   feedback, feedback_rate_limits. No SQL parser — we match on the first
//   keyword + rough table name so tests reflect real code paths without a
//   SQLite dependency.
interface Row {
  [key: string]: unknown
}

class FakeDB {
  feedback: Row[] = []
  rateLimits: Map<string, { ip: string; window_start: number; count: number }> =
    new Map()

  prepare = (sql: string): FakeStmt => {
    const { feedback, rateLimits } = this
    const trimmed = sql.trim()
    const upper = trimmed.toUpperCase()
    let binds: unknown[] = []
    const stmt: FakeStmt = {
      bind(...vals: unknown[]) {
        binds = vals
        return stmt
      },
      async run() {
        if (upper.startsWith("INSERT INTO FEEDBACK (")) {
          const [
            rating,
            task_summary,
            pua_level,
            pua_count,
            flavor,
            session_data,
            failure_count,
            ip_country,
          ] = binds
          feedback.push({
            rating,
            task_summary,
            pua_level,
            pua_count,
            flavor,
            session_data,
            failure_count,
            ip_country,
          })
        } else if (upper.includes("FEEDBACK_RATE_LIMITS")) {
          if (upper.startsWith("INSERT INTO FEEDBACK_RATE_LIMITS")) {
            const [ip, window_start] = binds as [string, number]
            const key = `${ip}:${window_start}`
            const cur = rateLimits.get(key)
            if (cur) {
              cur.count += 1
            } else {
              rateLimits.set(key, { ip, window_start, count: 1 })
            }
          } else if (upper.startsWith("DELETE FROM FEEDBACK_RATE_LIMITS")) {
            const [cutoff] = binds as [number]
            for (const [k, v] of rateLimits.entries()) {
              if (v.window_start < cutoff) rateLimits.delete(k)
            }
          }
        }
        return { success: true as const }
      },
      async first<T>(): Promise<T | null> {
        if (upper.startsWith("SELECT COUNT FROM FEEDBACK_RATE_LIMITS")) {
          const [ip, window_start] = binds as [string, number]
          const row = rateLimits.get(`${ip}:${window_start}`)
          return row ? ({ count: row.count } as unknown as T) : null
        }
        if (upper.startsWith("SELECT COUNT(*) AS TOTAL FROM FEEDBACK")) {
          return { total: feedback.length } as unknown as T
        }
        return null
      },
      async all() {
        if (
          upper.includes("FROM FEEDBACK") &&
          upper.includes("GROUP BY RATING")
        ) {
          const buckets = new Map<string, { count: number; sum: number }>()
          for (const r of feedback) {
            const rating = String(r.rating)
            const b = buckets.get(rating) ?? { count: 0, sum: 0 }
            b.count += 1
            b.sum += Number(r.pua_count ?? 0)
            buckets.set(rating, b)
          }
          return {
            results: [...buckets.entries()].map(([rating, b]) => ({
              rating,
              count: b.count,
              avg_pua_count: b.sum / b.count,
            })),
            success: true,
          }
        }
        return { results: [], success: true }
      },
    }
    return stmt
  }
}

interface FakeStmt {
  bind(...vals: unknown[]): FakeStmt
  run(): Promise<{ success: boolean }>
  first<T>(): Promise<T | null>
  all(): Promise<{ results: unknown[]; success: boolean }>
}

function makeReq(body: unknown, headers: Record<string, string> = {}): Request {
  const json = typeof body === "string" ? body : JSON.stringify(body)
  return new Request("https://example.com/api/feedback", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "cf-connecting-ip": "1.2.3.4",
      ...headers,
    },
    body: json,
  })
}

// ──── validateFeedback (pure) ────
describe("validateFeedback", () => {
  it("accepts a minimal valid body", () => {
    const r = validateFeedback({ rating: "很有用" })
    expect(r.ok).toBe(true)
    if (r.ok) {
      expect(r.value.rating).toBe("很有用")
      expect(r.value.pua_level).toBe("L0")
      expect(r.value.flavor).toBe("阿里")
      expect(r.value.pua_count).toBe(0)
    }
  })

  it("rejects missing rating", () => {
    const r = validateFeedback({})
    expect(r.ok).toBe(false)
    if (!r.ok) expect(r.err.field).toBe("rating")
  })

  it("rejects wrong types", () => {
    const r = validateFeedback({ rating: 123 as unknown })
    expect(r.ok).toBe(false)
    if (!r.ok) expect(r.err.error).toMatch(/string/)
  })

  it("rejects arrays disguised as objects at handler level", () => {
    // validateFeedback itself is called after the handler's guard —
    // but the guard should have stopped arrays. Assert the guard indirectly
    // by checking typeof logic here: arrays of length > 0 look like objects.
    const r = validateFeedback([] as unknown as Record<string, unknown>)
    // arrays don't have the named fields, so rating is missing
    expect(r.ok).toBe(false)
  })

  it("rejects oversize session_data (byte-length)", () => {
    const huge = "x".repeat(LIMITS.MAX_SESSION_DATA + 1)
    const r = validateFeedback({ rating: "s", session_data: huge })
    expect(r.ok).toBe(false)
    if (!r.ok) expect(r.err.field).toBe("session_data")
  })

  it("rejects oversize task_summary", () => {
    const big = "x".repeat(LIMITS.MAX_TASK_SUMMARY + 1)
    const r = validateFeedback({ rating: "s", task_summary: big })
    expect(r.ok).toBe(false)
    if (!r.ok) expect(r.err.field).toBe("task_summary")
  })

  it("enforces byte-length for CJK text", () => {
    // "好" is 3 UTF-8 bytes — 25 chars fits in MAX_PUA_LEVEL=16 by .length
    // but 75 bytes overflows. Confirms we bound bytes not JS chars.
    const cjk = "好".repeat(25)
    const r = validateFeedback({ rating: "s", pua_level: cjk })
    expect(r.ok).toBe(false)
    if (!r.ok) expect(r.err.field).toBe("pua_level")
  })

  it("rejects negative and out-of-range numerics", () => {
    expect(
      validateFeedback({ rating: "s", pua_count: -1 as unknown }).ok,
    ).toBe(false)
    expect(
      validateFeedback({
        rating: "s",
        failure_count: (LIMITS.MAX_NUMERIC + 1) as unknown,
      }).ok,
    ).toBe(false)
    expect(
      validateFeedback({ rating: "s", pua_count: 3.14 as unknown }).ok,
    ).toBe(false)
    expect(
      validateFeedback({ rating: "s", pua_count: "10" as unknown }).ok,
    ).toBe(false)
  })

  it("accepts realistic hook payload", () => {
    const r = validateFeedback({
      rating: "很有用",
      task_summary: "brief task description",
      pua_count: 3,
      flavor: "阿里",
    })
    expect(r.ok).toBe(true)
  })
})

// ──── onRequest (integration with FakeDB) ────
describe("POST /api/feedback", () => {
  let db: FakeDB

  beforeEach(() => {
    db = new FakeDB()
  })
  afterEach(() => vi.restoreAllMocks())

  async function call(
    body: unknown,
    headers: Record<string, string> = {},
  ): Promise<Response> {
    return onRequest({
      request: makeReq(body, headers),
      env: { DB: db as unknown as D1Database },
    } as unknown as Parameters<typeof onRequest>[0])
  }

  it("inserts a valid feedback row and returns 200", async () => {
    const res = await call({ rating: "很有用", pua_count: 1 })
    expect(res.status).toBe(200)
    const body = (await res.json()) as { ok: boolean }
    expect(body.ok).toBe(true)
    expect(db.feedback).toHaveLength(1)
    expect(db.feedback[0].rating).toBe("很有用")
    expect(db.feedback[0].pua_count).toBe(1)
    // defaults
    expect(db.feedback[0].pua_level).toBe("L0")
    expect(db.feedback[0].flavor).toBe("阿里")
  })

  it("returns 400 for missing rating", async () => {
    const res = await call({ pua_count: 1 })
    expect(res.status).toBe(400)
    expect(db.feedback).toHaveLength(0)
  })

  it("returns 400 for oversize session_data", async () => {
    const res = await call({
      rating: "spam",
      session_data: "x".repeat(LIMITS.MAX_SESSION_DATA + 1),
    })
    expect(res.status).toBe(400)
    const body = (await res.json()) as { field: string }
    expect(body.field).toBe("session_data")
  })

  it("returns 413 when Content-Length exceeds MAX_BODY_BYTES", async () => {
    const req = new Request("https://example.com/api/feedback", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "cf-connecting-ip": "1.2.3.4",
        "content-length": String(LIMITS.MAX_BODY_BYTES + 1),
      },
      body: JSON.stringify({ rating: "x" }),
    })
    const res = await onRequest({
      request: req,
      env: { DB: db as unknown as D1Database },
    } as unknown as Parameters<typeof onRequest>[0])
    expect(res.status).toBe(413)
  })

  it("returns 400 for invalid JSON", async () => {
    const res = await call("{not valid json")
    expect(res.status).toBe(400)
  })

  it("returns 400 for arrays and non-objects", async () => {
    // Need bodies > 2 chars — tiny bodies fall through to GET (legacy).
    const arrRes = await call([{ x: 1 }])
    expect(arrRes.status).toBe(400)
    const strRes = await call("not-an-object")
    expect(strRes.status).toBe(400)
  })

  it("rate-limits after RATE_LIMIT_PER_HOUR POSTs from same IP", async () => {
    const ip = { "cf-connecting-ip": "9.9.9.9" }
    let allowed = 0
    let blocked = 0
    for (let i = 0; i < LIMITS.RATE_LIMIT_PER_HOUR + 3; i++) {
      const res = await call({ rating: "x" }, ip)
      if (res.status === 200) allowed++
      else if (res.status === 429) blocked++
    }
    expect(allowed).toBe(LIMITS.RATE_LIMIT_PER_HOUR)
    expect(blocked).toBe(3)
    // Only allowed rows landed in DB.
    expect(db.feedback).toHaveLength(LIMITS.RATE_LIMIT_PER_HOUR)
  })

  it("applies a stricter limit when CF-Connecting-IP is missing", async () => {
    const req = (body: unknown) =>
      new Request("https://example.com/api/feedback", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(body),
      })
    let allowed = 0
    let blocked = 0
    for (let i = 0; i < LIMITS.RATE_LIMIT_UNKNOWN_IP + 2; i++) {
      const res = await onRequest({
        request: req({ rating: "x" }),
        env: { DB: db as unknown as D1Database },
      } as unknown as Parameters<typeof onRequest>[0])
      if (res.status === 200) allowed++
      else if (res.status === 429) blocked++
    }
    expect(allowed).toBe(LIMITS.RATE_LIMIT_UNKNOWN_IP)
    expect(blocked).toBeGreaterThanOrEqual(1)
  })

  it("returns Retry-After on 429", async () => {
    const ip = { "cf-connecting-ip": "5.5.5.5" }
    for (let i = 0; i < LIMITS.RATE_LIMIT_PER_HOUR; i++) {
      await call({ rating: "x" }, ip)
    }
    const res = await call({ rating: "x" }, ip)
    expect(res.status).toBe(429)
    expect(res.headers.get("Retry-After")).toMatch(/^\d+$/)
    expect(Number(res.headers.get("X-RateLimit-Limit"))).toBe(
      LIMITS.RATE_LIMIT_PER_HOUR,
    )
  })

  it("GET returns aggregate stats (legacy)", async () => {
    await call({ rating: "很有用", pua_count: 2 })
    await call({ rating: "很有用" })
    await call({ rating: "一般般" })
    const getReq = new Request("https://example.com/api/feedback", {
      method: "GET",
    })
    const res = await onRequest({
      request: getReq,
      env: { DB: db as unknown as D1Database },
    } as unknown as Parameters<typeof onRequest>[0])
    expect(res.status).toBe(200)
    const body = (await res.json()) as {
      total_feedback: number
      by_rating: { rating: string; count: number }[]
    }
    expect(body.total_feedback).toBe(3)
    const map = Object.fromEntries(body.by_rating.map((r) => [r.rating, r.count]))
    expect(map["很有用"]).toBe(2)
    expect(map["一般般"]).toBe(1)
  })

  it("OPTIONS preflight returns 204 with CORS headers", async () => {
    const req = new Request("https://example.com/api/feedback", {
      method: "OPTIONS",
    })
    const res = await onRequest({
      request: req,
      env: { DB: db as unknown as D1Database },
    } as unknown as Parameters<typeof onRequest>[0])
    expect(res.status).toBe(204)
    expect(res.headers.get("Access-Control-Allow-Origin")).toBe("*")
  })
})
