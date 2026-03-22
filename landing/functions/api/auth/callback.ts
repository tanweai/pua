import { createSessionCookie } from "../_session"

interface Env {
  GITHUB_CLIENT_ID: string
  GITHUB_CLIENT_SECRET: string
  SESSION_SECRET: string
}

export const onRequestGet: PagesFunction<Env> = async ({ env, request }) => {
  const url = new URL(request.url)
  const code = url.searchParams.get("code")
  if (!code) {
    return new Response("Missing code", { status: 400 })
  }

  // Exchange code for access token
  const tokenRes = await fetch("https://github.com/login/oauth/access_token", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify({
      client_id: env.GITHUB_CLIENT_ID,
      client_secret: env.GITHUB_CLIENT_SECRET,
      code,
    }),
  })

  const tokenData = (await tokenRes.json()) as { access_token?: string; error?: string }
  if (!tokenData.access_token) {
    return new Response("OAuth failed: " + (tokenData.error || "unknown"), { status: 400 })
  }

  // Get user info
  const userRes = await fetch("https://api.github.com/user", {
    headers: {
      Authorization: `Bearer ${tokenData.access_token}`,
      "User-Agent": "pua-skill-landing",
    },
  })
  const user = (await userRes.json()) as { id: number; login: string; avatar_url: string }

  // Create HMAC-signed session cookie (no token stored in cookie)
  const session = await createSessionCookie(
    { id: String(user.id), login: user.login, avatar: user.avatar_url },
    env.SESSION_SECRET
  )

  const redirectPage = `<!DOCTYPE html><html><head>
<meta charset="utf-8"><title>Redirecting...</title>
<script>window.location.replace("https://openpua.ai/#/contribute");</script>
</head><body><p>Redirecting... <a href="https://openpua.ai/#/contribute">Click here</a></p></body></html>`

  return new Response(redirectPage, {
    status: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Set-Cookie": `pua_session=${session}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=604800`,
    },
  })
}
