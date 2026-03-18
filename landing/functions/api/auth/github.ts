interface Env {
  GITHUB_CLIENT_ID: string
}

export const onRequestGet: PagesFunction<Env> = async ({ env, request }) => {
  const origin = "https://openpua.ai"
  const redirectUri = `${origin}/api/auth/callback`
  const githubUrl = new URL("https://github.com/login/oauth/authorize")
  githubUrl.searchParams.set("client_id", env.GITHUB_CLIENT_ID)
  githubUrl.searchParams.set("redirect_uri", redirectUri)
  githubUrl.searchParams.set("scope", "read:user")
  const target = githubUrl.toString()
  return new Response(
    `<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0;url=${target}"><title>Redirecting...</title></head><body><a href="${target}">Click here if not redirected</a></body></html>`,
    { status: 200, headers: { "Content-Type": "text/html; charset=utf-8" } },
  )
}
