import { getSession } from "./_session"

interface Env {
  DB: D1Database
  SESSION_SECRET: string
}

export const onRequestGet: PagesFunction<Env> = async ({ request, env }) => {
  const session = await getSession(request, env.SESSION_SECRET)
  if (!session) {
    return Response.json({ logged_in: false }, { status: 401 })
  }

  // Get upload count for this user
  const result = await env.DB.prepare(
    "SELECT COUNT(*) as count FROM uploads WHERE github_id = ?"
  ).bind(session.id).first<{ count: number }>()

  return Response.json({
    logged_in: true,
    id: session.id,
    login: session.login,
    avatar: session.avatar,
    upload_count: result?.count || 0,
  })
}
