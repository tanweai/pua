import { checkRateLimit } from "./_ratelimit"

interface Env {
  DB: D1Database
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
}

// Size caps — tuned against real payloads from hooks/stop-feedback.sh:
//   rating / pua_level / flavor are short enums or Chinese labels.
//   task_summary is a one-liner.
//   session_data is an anonymized JSONL session (hook passes the transcript),
//     capped well below the 50MB upload.ts accepts so /feedback stays cheap.
//   MAX_BODY_BYTES bounds total JSON payload including overhead.
export const LIMITS = {
  MAX_BODY_BYTES: 2 * 1024 * 1024, // 2 MiB total request body
  MAX_RATING: 64,
  MAX_PUA_LEVEL: 16,
  MAX_FLAVOR: 64,
  MAX_TASK_SUMMARY: 2048,
  MAX_SESSION_DATA: 1 * 1024 * 1024, // 1 MiB — anonymized tool-call stream
  MAX_NUMERIC: 100_000,
  RATE_LIMIT_PER_HOUR: 30, // per CF-Connecting-IP
  RATE_LIMIT_UNKNOWN_IP: 5, // stricter when IP is missing
}

interface FeedbackBody {
  rating?: unknown
  task_summary?: unknown
  pua_level?: unknown
  pua_count?: unknown
  flavor?: unknown
  session_data?: unknown
  failure_count?: unknown
}

type StrField = "rating" | "task_summary" | "pua_level" | "flavor" | "session_data"
type NumField = "pua_count" | "failure_count"

const STR_LIMITS: Record<StrField, number> = {
  rating: LIMITS.MAX_RATING,
  task_summary: LIMITS.MAX_TASK_SUMMARY,
  pua_level: LIMITS.MAX_PUA_LEVEL,
  flavor: LIMITS.MAX_FLAVOR,
  session_data: LIMITS.MAX_SESSION_DATA,
}

export interface ValidationError {
  error: string
  field?: string
}

export interface ValidatedFeedback {
  rating: string
  task_summary: string | null
  pua_level: string
  pua_count: number
  flavor: string
  session_data: string | null
  failure_count: number
}

function asString(
  v: unknown,
  field: StrField,
): { ok: true; value: string | null } | { ok: false; err: ValidationError } {
  if (v === undefined || v === null) return { ok: true, value: null }
  if (typeof v !== "string") {
    return { ok: false, err: { error: `${field} must be a string`, field } }
  }
  // Byte length, not JS string length — UTF-8 blows up for CJK text.
  const bytes = new TextEncoder().encode(v).length
  if (bytes > STR_LIMITS[field]) {
    return {
      ok: false,
      err: { error: `${field} exceeds ${STR_LIMITS[field]} bytes`, field },
    }
  }
  return { ok: true, value: v }
}

function asNumber(
  v: unknown,
  field: NumField,
): { ok: true; value: number } | { ok: false; err: ValidationError } {
  if (v === undefined || v === null) return { ok: true, value: 0 }
  if (typeof v !== "number" || !Number.isFinite(v) || !Number.isInteger(v)) {
    return { ok: false, err: { error: `${field} must be an integer`, field } }
  }
  if (v < 0 || v > LIMITS.MAX_NUMERIC) {
    return {
      ok: false,
      err: {
        error: `${field} must be between 0 and ${LIMITS.MAX_NUMERIC}`,
        field,
      },
    }
  }
  return { ok: true, value: v }
}

/**
 * Validate a parsed JSON body. Exported for unit tests.
 */
export function validateFeedback(
  body: FeedbackBody,
): { ok: true; value: ValidatedFeedback } | { ok: false; err: ValidationError } {
  const rating = asString(body.rating, "rating")
  if (!rating.ok) return rating
  if (!rating.value) {
    return { ok: false, err: { error: "rating is required", field: "rating" } }
  }

  const taskSummary = asString(body.task_summary, "task_summary")
  if (!taskSummary.ok) return taskSummary

  const puaLevel = asString(body.pua_level, "pua_level")
  if (!puaLevel.ok) return puaLevel

  const flavor = asString(body.flavor, "flavor")
  if (!flavor.ok) return flavor

  const sessionData = asString(body.session_data, "session_data")
  if (!sessionData.ok) return sessionData

  const puaCount = asNumber(body.pua_count, "pua_count")
  if (!puaCount.ok) return puaCount

  const failureCount = asNumber(body.failure_count, "failure_count")
  if (!failureCount.ok) return failureCount

  return {
    ok: true,
    value: {
      rating: rating.value,
      task_summary: taskSummary.value,
      pua_level: puaLevel.value ?? "L0",
      pua_count: puaCount.value,
      flavor: flavor.value ?? "阿里",
      session_data: sessionData.value,
      failure_count: failureCount.value,
    },
  }
}

function jsonError(
  err: ValidationError,
  status: number,
  extraHeaders: Record<string, string> = {},
): Response {
  return Response.json(err, {
    status,
    headers: { ...corsHeaders, ...extraHeaders },
  })
}

async function readBodyWithLimit(
  request: Request,
): Promise<
  { ok: true; text: string } | { ok: false; status: number; err: ValidationError }
> {
  // Prefer Content-Length to reject oversize payloads before reading.
  const cl = request.headers.get("content-length")
  if (cl) {
    const n = Number(cl)
    if (Number.isFinite(n) && n > LIMITS.MAX_BODY_BYTES) {
      return {
        ok: false,
        status: 413,
        err: { error: `request body exceeds ${LIMITS.MAX_BODY_BYTES} bytes` },
      }
    }
  }

  let text: string
  try {
    text = await request.text()
  } catch {
    return { ok: false, status: 400, err: { error: "failed to read request body" } }
  }

  // Belt-and-suspenders: Content-Length can be absent (chunked) or lie.
  if (new TextEncoder().encode(text).length > LIMITS.MAX_BODY_BYTES) {
    return {
      ok: false,
      status: 413,
      err: { error: `request body exceeds ${LIMITS.MAX_BODY_BYTES} bytes` },
    }
  }
  return { ok: true, text }
}

export const onRequest: PagesFunction<Env> = async ({ request, env }) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders })
  }

  const hasJsonContentType = request.headers
    .get("content-type")
    ?.includes("application/json")
  const isPost = request.method === "POST" || hasJsonContentType

  if (isPost) {
    // Rate limit: per-IP hour bucket. Unknown IP gets a much stricter cap
    // so proxies that strip CF-Connecting-IP can't be used as a bypass.
    const rawIp = request.headers.get("CF-Connecting-IP")?.trim() ?? ""
    const ip = rawIp || "__unknown__"
    const limit = rawIp
      ? LIMITS.RATE_LIMIT_PER_HOUR
      : LIMITS.RATE_LIMIT_UNKNOWN_IP

    const rl = await checkRateLimit(env.DB, ip, limit)
    const rlHeaders = {
      "X-RateLimit-Limit": String(rl.limit),
      "X-RateLimit-Remaining": String(rl.remaining),
    }
    if (!rl.allowed) {
      return jsonError(
        { error: "rate limit exceeded — try again later" },
        429,
        { ...rlHeaders, "Retry-After": String(rl.retryAfter) },
      )
    }

    const bodyRead = await readBodyWithLimit(request)
    if (!bodyRead.ok) {
      return jsonError(bodyRead.err, bodyRead.status, rlHeaders)
    }

    if (bodyRead.text && bodyRead.text.length > 2) {
      let body: FeedbackBody
      try {
        body = JSON.parse(bodyRead.text) as FeedbackBody
      } catch {
        return jsonError({ error: "invalid JSON body" }, 400, rlHeaders)
      }
      if (body === null || typeof body !== "object" || Array.isArray(body)) {
        return jsonError({ error: "body must be a JSON object" }, 400, rlHeaders)
      }

      const validated = validateFeedback(body)
      if (!validated.ok) {
        return jsonError(validated.err, 400, rlHeaders)
      }
      const v = validated.value

      try {
        await env.DB.prepare(
          `INSERT INTO feedback (rating, task_summary, pua_level, pua_count, flavor, session_data, failure_count, ip_country)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        )
          .bind(
            v.rating,
            v.task_summary,
            v.pua_level,
            v.pua_count,
            v.flavor,
            v.session_data,
            v.failure_count,
            request.headers.get("CF-IPCountry") || "unknown",
          )
          .run()
      } catch (e) {
        return jsonError(
          { error: "failed to save feedback", field: String(e) },
          500,
          rlHeaders,
        )
      }

      return Response.json(
        { ok: true },
        { headers: { ...corsHeaders, ...rlHeaders } },
      )
    }
    // Body was empty/stripped — fall through to GET stats (legacy behavior).
  }

  // GET: aggregate stats (unchanged)
  const stats = await env.DB.prepare(
    `SELECT rating, COUNT(*) as count, AVG(pua_count) as avg_pua_count
     FROM feedback GROUP BY rating ORDER BY count DESC`,
  ).all()

  const total = await env.DB.prepare(
    "SELECT COUNT(*) as total FROM feedback",
  ).first<{ total: number }>()

  return Response.json(
    {
      total_feedback: total?.total || 0,
      by_rating: stats.results,
    },
    { headers: corsHeaders },
  )
}
