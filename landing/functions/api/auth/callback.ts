interface Env {
  GITHUB_CLIENT_ID: string
  GITHUB_CLIENT_SECRET: string
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

  // Store session in cookie (base64 encoded JSON)
  const session = btoa(JSON.stringify({
    id: String(user.id),
    login: user.login,
    avatar: user.avatar_url,
    token: tokenData.access_token,
  }))

  return new Response(null, {
    status: 302,
    headers: {
      Location: "https://openpua.ai/#/contribute",
      "Set-Cookie": `pua_session=${session}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=604800`,
    },
  })
}
