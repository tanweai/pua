interface Env {
  DB: D1Database
  RATE_LIMITER: KVNamespace
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-Feedback-Token",
}

// Rate limit: max 5 requests per IP per hour
const RATE_LIMIT_MAX = 5
const RATE_LIMIT_WINDOW = 3600 // 1 hour in seconds

// Max sizes for fields
const MAX_SESSION_DATA_SIZE = 10000 // 10KB max
const MAX_TASK_SUMMARY_SIZE = 1000

async function isRateLimited(ip: string, env: Env): Promise<boolean> {
  const key = `feedback:${ip}`
  const count = await env.RATE_LIMITER.get(key)
  const currentCount = count ? parseInt(count, 10) : 0
  
  if (currentCount >= RATE_LIMIT_MAX) {
    return true
  }
  
  // Increment counter
  await env.RATE_LIMITER.put(key, String(currentCount + 1), {
    expirationTtl: RATE_LIMIT_WINDOW
  })
  
  return false
}

function getClientIP(request: Request): string {
  // Try CF-Connecting-IP first (Cloudflare)
  const cfIP = request.headers.get("CF-Connecting-IP")
  if (cfIP) return cfIP
  
  // Fallback to X-Forwarded-For
  const xff = request.headers.get("X-Forwarded-For")
  if (xff) return xff.split(",")[0].trim()
  
  return "unknown"
}

export const onRequest: PagesFunction<Env> = async ({ request, env }) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders })
  }

  // Detect POST: method=POST or has JSON Content-Type (custom domain may rewrite method)
  const hasJsonContentType = request.headers.get("content-type")?.includes("application/json")
  const isPost = request.method === "POST" || hasJsonContentType

  if (isPost) {
    // Rate limiting
    const clientIP = getClientIP(request)
    if (env.RATE_LIMITER) {
      const limited = await isRateLimited(clientIP, env)
      if (limited) {
        return Response.json(
          { error: "Rate limit exceeded. Please try again later." },
          { status: 429, headers: corsHeaders }
        )
      }
    }
    
    // Try to read body — custom domain may strip it
    let bodyText: string | null = null
    try { bodyText = await request.text() } catch {}

    if (bodyText && bodyText.length > 2) {
      try {
        const body = JSON.parse(bodyText) as {
          rating?: string
          task_summary?: string
          pua_level?: string
          pua_count?: number
          flavor?: string
          session_data?: string
          failure_count?: number
        }

        if (!body.rating) {
          return Response.json({ error: "rating is required" }, { status: 400, headers: corsHeaders })
        }

        // Validate and sanitize field sizes
        const rating = body.rating.slice(0, 50) // Limit rating length
        const taskSummary = body.task_summary?.slice(0, MAX_TASK_SUMMARY_SIZE) || null
        const sessionData = body.session_data?.slice(0, MAX_SESSION_DATA_SIZE) || null

        await env.DB.prepare(
          `INSERT INTO feedback (rating, task_summary, pua_level, pua_count, flavor, session_data, failure_count, ip_country)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
        )
          .bind(
            rating,
            taskSummary,
            body.pua_level || "L0",
            body.pua_count || 0,
            body.flavor?.slice(0, 100) || "阿里",
            sessionData,
            body.failure_count || 0,
            request.headers.get("CF-IPCountry") || "unknown"
          )
          .run()

        return Response.json({ ok: true }, { headers: corsHeaders })
      } catch (e) {
        return Response.json(
          { error: "Failed to save feedback", detail: String(e) },
          { status: 500, headers: corsHeaders }
        )
      }
    }
    // Body was empty/stripped — fall through to GET
  }

  // GET: aggregate stats
  const stats = await env.DB.prepare(
    `SELECT rating, COUNT(*) as count, AVG(pua_count) as avg_pua_count
     FROM feedback GROUP BY rating ORDER BY count DESC`
  ).all()

  const total = await env.DB.prepare(
    "SELECT COUNT(*) as total FROM feedback"
  ).first<{ total: number }>()

  return Response.json({
    total_feedback: total?.total || 0,
    by_rating: stats.results,
  }, { headers: corsHeaders })
}
