// Shared session utilities — HMAC-signed cookies
// Cookie format: base64(payload).base64(hmac-sha256(payload, secret))

export interface SessionPayload {
  id: string
  login: string
  avatar: string
}

export interface Env {
  SESSION_SECRET: string
  DB: D1Database
  UPLOADS?: R2Bucket
  GITHUB_CLIENT_ID?: string
  GITHUB_CLIENT_SECRET?: string
}

async function hmacSign(payload: string, secret: string): Promise<string> {
  const enc = new TextEncoder()
  const key = await crypto.subtle.importKey(
    "raw", enc.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]
  )
  const sig = await crypto.subtle.sign("HMAC", key, enc.encode(payload))
  return btoa(String.fromCharCode(...new Uint8Array(sig)))
}

async function hmacVerify(payload: string, signature: string, secret: string): Promise<boolean> {
  const expected = await hmacSign(payload, secret)
  return expected === signature
}

export async function createSessionCookie(data: SessionPayload, secret: string): Promise<string> {
  const payload = btoa(JSON.stringify(data))
  const sig = await hmacSign(payload, secret)
  return `${payload}.${sig}`
}

export async function getSession(request: Request, secret: string): Promise<SessionPayload | null> {
  const cookie = request.headers.get("Cookie") || ""
  const match = cookie.match(/pua_session=([^;]+)/)
  if (!match) return null

  const parts = match[1].split(".")
  if (parts.length !== 2) return null

  const [payload, sig] = parts
  const valid = await hmacVerify(payload, sig, secret)
  if (!valid) return null

  try {
    return JSON.parse(atob(payload)) as SessionPayload
  } catch {
    return null
  }
}
