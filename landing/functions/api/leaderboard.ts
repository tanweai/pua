interface Env {
  DB: D1Database
}

interface LeaderboardSubmission {
  id: string
  email: string
  phone?: string
  display_name: string
  pua_count: number
  l3_plus_count: number
  flavor?: string
  action?: string // "register" | "submit" | "delete" | "quit"
}

function maskEmail(email: string): string {
  const [local, domain] = email.split("@")
  if (!domain) return email
  const domainParts = domain.split(".")
  return `${local[0]}***@${domainParts[0][0]}*.${domainParts.slice(1).join(".")}`
}

function calcRank(pua: number, l3rate: number, streak: number): { level: string; title_zh: string; title_en: string } {
  if (pua >= 200 && l3rate >= 0.4 && streak >= 30) return { level: "P10", title_zh: "首席 PUA 官", title_en: "Chief PUA Officer" }
  if (pua >= 100 && l3rate >= 0.3 && streak >= 14) return { level: "P9", title_zh: "PUA Tech Lead", title_en: "PUA Tech Lead" }
  if (pua >= 50 && l3rate >= 0.2) return { level: "P8", title_zh: "PUA 主管", title_en: "PUA Manager" }
  if (pua >= 20 && l3rate >= 0.1) return { level: "P7", title_zh: "PUA 骨干", title_en: "PUA Senior" }
  if (pua >= 5) return { level: "P6", title_zh: "PUA 专员", title_en: "PUA Specialist" }
  return { level: "P5", title_zh: "PUA 实习生", title_en: "PUA Intern" }
}

export const onRequest: PagesFunction<Env> = async ({ request, env }) => {
  const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  }

  if (request.method === "OPTIONS") {
    return new Response(null, { headers: cors })
  }

  // Ensure table exists
  await env.DB.prepare(`
    CREATE TABLE IF NOT EXISTS leaderboard (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL,
      phone TEXT,
      display_name TEXT NOT NULL,
      pua_count INTEGER DEFAULT 0,
      l3_plus_count INTEGER DEFAULT 0,
      total_sessions INTEGER DEFAULT 0,
      streak_days INTEGER DEFAULT 0,
      flavors_used TEXT DEFAULT '[]',
      max_session_pua INTEGER DEFAULT 0,
      last_active TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    )
  `).run()

  // POST: register or submit data
  if (request.method === "POST") {
    try {
      const body = (await request.json()) as LeaderboardSubmission

      if (body.action === "register") {
        if (!body.email || !body.id) {
          return Response.json({ error: "email and id are required" }, { status: 400, headers: cors })
        }
        const displayName = maskEmail(body.email)
        await env.DB.prepare(
          `INSERT OR REPLACE INTO leaderboard (id, email, phone, display_name, created_at, updated_at)
           VALUES (?, ?, ?, ?, datetime('now'), datetime('now'))`
        ).bind(body.id, body.email, body.phone || null, displayName).run()

        return Response.json({ ok: true, display_name: displayName, id: body.id }, { headers: cors })
      }

      if (body.action === "submit") {
        if (!body.id) {
          return Response.json({ error: "id is required" }, { status: 400, headers: cors })
        }
        // Update cumulative stats
        await env.DB.prepare(`
          UPDATE leaderboard SET
            pua_count = pua_count + ?,
            l3_plus_count = l3_plus_count + ?,
            total_sessions = total_sessions + 1,
            last_active = datetime('now'),
            updated_at = datetime('now')
          WHERE id = ?
        `).bind(body.pua_count || 0, body.l3_plus_count || 0, body.id).run()

        return Response.json({ ok: true }, { headers: cors })
      }

      if (body.action === "quit" || body.action === "delete") {
        if (!body.id) {
          return Response.json({ error: "id is required" }, { status: 400, headers: cors })
        }
        await env.DB.prepare("DELETE FROM leaderboard WHERE id = ?").bind(body.id).run()
        return Response.json({ ok: true, deleted: true }, { headers: cors })
      }

      return Response.json({ error: "unknown action" }, { status: 400, headers: cors })
    } catch (e) {
      return Response.json({ error: String(e) }, { status: 500, headers: cors })
    }
  }

  // DELETE: remove user
  if (request.method === "DELETE") {
    const url = new URL(request.url)
    const id = url.searchParams.get("id")
    if (!id) return Response.json({ error: "id required" }, { status: 400, headers: cors })
    await env.DB.prepare("DELETE FROM leaderboard WHERE id = ?").bind(id).run()
    return Response.json({ ok: true }, { headers: cors })
  }

  // GET: return leaderboard
  const url = new URL(request.url)
  const userId = url.searchParams.get("id")
  const period = url.searchParams.get("period") || "all" // all, week, month

  // Top 20
  const top = await env.DB.prepare(
    `SELECT id, display_name, pua_count, l3_plus_count, total_sessions, streak_days, last_active
     FROM leaderboard ORDER BY pua_count DESC LIMIT 20`
  ).all()

  // Total stats
  const stats = await env.DB.prepare(
    `SELECT COUNT(*) as total_users, SUM(pua_count) as total_pua, AVG(pua_count) as avg_pua
     FROM leaderboard`
  ).first<{ total_users: number; total_pua: number; avg_pua: number }>()

  // Enrich with ranks
  const rankings = top.results.map((row: any, i: number) => {
    const l3rate = row.pua_count > 0 ? row.l3_plus_count / row.pua_count : 0
    const rank = calcRank(row.pua_count, l3rate, row.streak_days)
    return {
      position: i + 1,
      display_name: row.display_name,
      pua_count: row.pua_count,
      l3_plus_rate: Math.round(l3rate * 100),
      streak_days: row.streak_days,
      total_sessions: row.total_sessions,
      level: rank.level,
      title_zh: rank.title_zh,
      title_en: rank.title_en,
    }
  })

  // User's own ranking
  let me = null
  if (userId) {
    const myRow = await env.DB.prepare(
      "SELECT *, (SELECT COUNT(*) + 1 FROM leaderboard b WHERE b.pua_count > a.pua_count) as position FROM leaderboard a WHERE id = ?"
    ).bind(userId).first()
    if (myRow) {
      const l3rate = (myRow.pua_count as number) > 0 ? (myRow.l3_plus_count as number) / (myRow.pua_count as number) : 0
      const rank = calcRank(myRow.pua_count as number, l3rate, myRow.streak_days as number)
      me = {
        position: myRow.position,
        display_name: myRow.display_name,
        pua_count: myRow.pua_count,
        l3_plus_rate: Math.round(l3rate * 100),
        streak_days: myRow.streak_days,
        level: rank.level,
        title_zh: rank.title_zh,
        title_en: rank.title_en,
      }
    }
  }

  return Response.json({
    total_users: stats?.total_users || 0,
    total_pua: stats?.total_pua || 0,
    avg_pua: Math.round(stats?.avg_pua || 0),
    rankings,
    me,
  }, { headers: cors })
}
