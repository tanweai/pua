import { getSession } from "./_session"
import { sanitize } from "./_sanitize"

interface Env {
  DB: D1Database
  UPLOADS: R2Bucket
  SESSION_SECRET: string
}

export const onRequestPost: PagesFunction<Env> = async ({ request, env }) => {
  const session = await getSession(request, env.SESSION_SECRET)
  if (!session) {
    return Response.json({ error: "Unauthorized" }, { status: 401 })
  }

  const formData = await request.formData()
  const file = formData.get("file") as File | null
  const wechatId = formData.get("wechat_id") as string | null

  if (!file) {
    return Response.json({ error: "No file provided" }, { status: 400 })
  }
  if (!wechatId?.trim()) {
    return Response.json({ error: "WeChat ID is required" }, { status: 400 })
  }
  if (!file.name.endsWith(".jsonl")) {
    return Response.json({ error: "Only .jsonl files are accepted" }, { status: 400 })
  }
  if (file.size > 50 * 1024 * 1024) {
    return Response.json({ error: "File too large (max 50MB)" }, { status: 400 })
  }

  // Sanitize before storing (3-layer: blacklist + K=V + entropy)
  const raw = await file.text()
  let sanitized: string
  try {
    sanitized = sanitize(raw)
  } catch {
    return Response.json({ error: "Sanitization failed — file may be too large or malformed" }, { status: 422 })
  }

  // Upload sanitized content to R2
  const key = `${session.login}/${Date.now()}-${file.name}`
  await env.UPLOADS.put(key, sanitized, {
    httpMetadata: { contentType: "application/jsonl" },
    customMetadata: {
      github_id: session.id,
      github_login: session.login,
      wechat_id: wechatId.trim(),
    },
  })

  // Record sanitized byte length (post-sanitization size, not original)
  const sanitizedSize = new TextEncoder().encode(sanitized).byteLength
  await env.DB.prepare(
    "INSERT INTO uploads (github_id, github_login, wechat_id, file_key, file_name, file_size) VALUES (?, ?, ?, ?, ?, ?)"
  ).bind(session.id, session.login, wechatId.trim(), key, file.name, sanitizedSize).run()

  // Send email notification (fire-and-forget)
  const sizeMB = (file.size / 1024 / 1024).toFixed(2)
  const emailBody = [
    `New PUA Skill data upload:`,
    ``,
    `GitHub: ${session.login} (${session.id})`,
    `WeChat: ${wechatId.trim()}`,
    `File: ${file.name} (${sizeMB} MB)`,
    `R2 Key: ${key}`,
    `Time: ${new Date().toISOString()}`,
  ].join("\n")

  fetch("https://api.mailchannels.net/tx/v1/send", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      personalizations: [{ to: [{ email: "xsser.w@gmail.com", name: "PUA Admin" }] }],
      from: { email: "noreply@pua-skill.pages.dev", name: "PUA Skill Upload" },
      subject: `[PUA Upload] ${session.login} uploaded ${file.name}`,
      content: [{ type: "text/plain", value: emailBody }],
    }),
  }).catch(() => {})

  return Response.json({ ok: true, key, file_name: file.name, file_size: file.size })
}

// GET: list user's uploads
export const onRequestGet: PagesFunction<Env> = async ({ request, env }) => {
  const session = await getSession(request, env.SESSION_SECRET)
  if (!session) {
    return Response.json({ error: "Unauthorized" }, { status: 401 })
  }

  const { results } = await env.DB.prepare(
    "SELECT file_name, file_size, created_at FROM uploads WHERE github_id = ? ORDER BY created_at DESC LIMIT 50"
  ).bind(session.id).all()

  return Response.json({ uploads: results })
}
