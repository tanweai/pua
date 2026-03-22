interface Env {
  DB: D1Database
}

// Use single onRequest handler — custom domains may not route onRequestPost correctly
export const onRequest: PagesFunction<Env> = async ({ request, env }) => {
  if (request.method === "POST") {
    try {
      const body = (await request.json()) as {
        rating?: string
        task_summary?: string
        pua_level?: string
        pua_count?: number
        flavor?: string
        session_data?: string
        failure_count?: number
      }

      if (!body.rating) {
        return Response.json({ error: "rating is required" }, { status: 400 })
      }

      await env.DB.prepare(
        `INSERT INTO feedback (rating, task_summary, pua_level, pua_count, flavor, session_data, failure_count, ip_country)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
      )
        .bind(
          body.rating,
          body.task_summary || null,
          body.pua_level || "L0",
          body.pua_count || 0,
          body.flavor || "阿里",
          body.session_data || null,
          body.failure_count || 0,
          request.headers.get("CF-IPCountry") || "unknown"
        )
        .run()

      return Response.json({ ok: true })
    } catch (e) {
      return Response.json(
        { error: "Failed to save feedback", detail: String(e) },
        { status: 500 }
      )
    }
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
  })
}
