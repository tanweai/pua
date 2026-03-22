import { useState, useRef, useCallback, useEffect } from "react"
import type { Lang } from "../i18n"
type User = { logged_in: true; id: string; login: string; avatar: string; upload_count: number }
type Upload = { file_name: string; file_size: number; created_at: string }

interface Props {
  lang: Lang
}

export default function Contribute({ lang }: Props) {
  const L = (zh: string, en: string, ja?: string) => (lang === "zh" ? zh : lang === "ja" ? (ja ?? en) : en) // other langs fallback to en
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [wechatId, setWechatId] = useState("")
  const [dragOver, setDragOver] = useState(false)
  const [uploading, setUploading] = useState(false)
  const [uploadResult, setUploadResult] = useState<{ ok: boolean; message: string } | null>(null)
  const [uploads, setUploads] = useState<Upload[]>([])
  const fileRef = useRef<HTMLInputElement>(null)

  // Check login status
  useEffect(() => {
    fetch("/api/me", { credentials: "include" })
      .then((r) => r.json())
      .then((data) => {
        if (data.logged_in) setUser(data as User)
      })
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  // Load upload history
  useEffect(() => {
    if (!user) return
    fetch("/api/upload", { credentials: "include" })
      .then((r) => r.json())
      .then((data) => {
        if (data.uploads) setUploads(data.uploads)
      })
      .catch(() => {})
  }, [user])

  const handleUpload = useCallback(
    async (file: File) => {
      if (!file.name.endsWith(".jsonl")) {
        setUploadResult({ ok: false, message: L("只接受 .jsonl 文件", "Only .jsonl files accepted") })
        return
      }
      if (file.size > 50 * 1024 * 1024) {
        setUploadResult({ ok: false, message: L("文件过大（最大 50MB）", "File too large (max 50MB)") })
        return
      }
      if (!wechatId.trim()) {
        setUploadResult({ ok: false, message: L("请先填写微信号", "Please enter your WeChat ID first") })
        return
      }

      setUploading(true)
      setUploadResult(null)
      const form = new FormData()
      form.append("file", file)
      form.append("wechat_id", wechatId.trim())

      try {
        const res = await fetch("/api/upload", { method: "POST", body: form, credentials: "include" })
        const data = await res.json()
        if (data.ok) {
          setUploadResult({ ok: true, message: L(`${file.name} 上传成功`, `${file.name} uploaded successfully`) })
          setUploads((prev) => [{ file_name: file.name, file_size: file.size, created_at: new Date().toISOString() }, ...prev])
        } else {
          setUploadResult({ ok: false, message: data.error || "Upload failed" })
        }
      } catch {
        setUploadResult({ ok: false, message: L("网络错误，请重试", "Network error, please retry") })
      } finally {
        setUploading(false)
      }
    },
    [wechatId, lang]
  )

  const onDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault()
      setDragOver(false)
      const file = e.dataTransfer.files[0]
      if (file) handleUpload(file)
    },
    [handleUpload]
  )

  const onFileSelect = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0]
      if (file) handleUpload(file)
      e.target.value = ""
    },
    [handleUpload]
  )

  const formatSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  if (loading) {
    return (
      <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div style={{ color: "var(--text-muted)", fontSize: "0.9rem" }}>Loading...</div>
      </div>
    )
  }

  return (
    <div style={{ minHeight: "100vh", background: "var(--bg-alt)" }}>
      {/* Header */}
      <div
        style={{
          background: "var(--bg)",
          borderBottom: "1px solid var(--border)",
          padding: "1.5rem",
        }}
      >
        <div className="container" style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div>
            <a href="/" style={{ textDecoration: "none", display: "flex", alignItems: "center", gap: "0.75rem" }}>
              <span style={{ fontWeight: 700, fontSize: "1.5rem", letterSpacing: "-0.025em" }}>pua</span>
              <span style={{ color: "var(--text-muted)", fontSize: "0.85rem" }}>/</span>
              <span style={{ fontSize: "0.95rem", fontWeight: 500 }}>{L("贡献数据", "Contribute")}</span>
            </a>
          </div>
          {user && (
            <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
              <img
                src={user.avatar}
                alt={user.login}
                style={{ width: "2rem", height: "2rem", borderRadius: "50%", border: "1px solid var(--gray-200)" }}
              />
              <span style={{ fontSize: "0.85rem", fontWeight: 500 }}>{user.login}</span>
              <form action="/api/auth/logout" method="POST" style={{ display: "inline" }}>
                <button
                  type="submit"
                  style={{
                    background: "none",
                    border: "1px solid var(--gray-200)",
                    borderRadius: "0.375rem",
                    padding: "0.25rem 0.5rem",
                    fontSize: "0.75rem",
                    color: "var(--text-muted)",
                    cursor: "pointer",
                  }}
                >
                  {L("登出", "Logout")}
                </button>
              </form>
            </div>
          )}
        </div>
      </div>

      <div className="container" style={{ padding: "3rem 1.5rem" }}>
        {/* Disclaimer Banner */}
        <div
          style={{
            padding: "1rem 1.25rem",
            borderRadius: "0.75rem",
            border: "1px solid #fbbf24",
            background: "#fffbeb",
            marginBottom: "2rem",
            fontSize: "0.85rem",
            lineHeight: 1.7,
            color: "#92400e",
          }}
        >
          <strong>{L("数据使用声明", "Data Usage Notice")}</strong>
          <br />
          {L(
            "上传的 .jsonl 文件将用于 PUA Skill 的 Benchmark 测试和消融实验（Ablation Study）分析，帮助量化不同 PUA 策略对 AI 调试行为的影响。上传即表示您同意将文件用于上述研究目的。我们不会公开您的原始文件内容。上传时，您的 GitHub 用户名及微信号将与文件一同记录，项目管理员会收到上传通知（含文件名、文件大小及上述账号信息）。",
            "Uploaded .jsonl files will be used for PUA Skill benchmark testing and ablation study analysis, helping quantify how different PUA strategies affect AI debugging behavior. By uploading, you agree to this research use. We will not publicly share your raw file contents. Your GitHub username and WeChat ID will be stored alongside your file, and the project admin will receive an upload notification containing your filename, file size, and account identifiers."
          )}
        </div>

        {!user ? (
          /* Login Card */
          <div
            className="card"
            style={{
              maxWidth: "32rem",
              margin: "0 auto",
              textAlign: "center",
              padding: "3rem 2rem",
            }}
          >
            <div style={{ marginBottom: "1.5rem" }}>
              <h2 style={{ fontSize: "1.5rem", fontWeight: 700, letterSpacing: "-0.02em", marginBottom: "0.75rem" }}>
                {L("贡献你的使用数据", "Contribute Your Usage Data")}
              </h2>
              <p style={{ color: "var(--text-secondary)", fontSize: "0.9rem", lineHeight: 1.7 }}>
                {L(
                  "上传你的 Claude Code / Codex CLI 对话记录（.jsonl），帮助我们改进 PUA Skill 的效果。",
                  "Upload your Claude Code / Codex CLI conversation logs (.jsonl) to help us improve PUA Skill effectiveness."
                )}
              </p>
            </div>
            <a
              href="/api/auth/github"
              className="btn-primary"
              style={{ display: "inline-flex", alignItems: "center", gap: "0.625rem", fontSize: "0.9rem" }}
            >
              <svg viewBox="0 0 98 96" fill="currentColor" style={{ width: "1.1rem", height: "1.1rem" }}>
                <path
                  fillRule="evenodd"
                  clipRule="evenodd"
                  d="M48.854 0C21.839 0 0 22 0 49.217c0 21.756 13.993 40.172 33.405 46.69 2.427.49 3.316-1.059 3.316-2.362 0-1.141-.08-5.052-.08-9.127-13.59 2.934-16.42-5.867-16.42-5.867-2.184-5.704-5.42-7.17-5.42-7.17-4.448-3.015.324-3.015.324-3.015 4.934.326 7.523 5.052 7.523 5.052 4.367 7.496 11.404 5.378 14.235 4.074.404-3.178 1.699-5.378 3.074-6.6-10.839-1.141-22.243-5.378-22.243-24.283 0-5.378 1.94-9.778 5.014-13.2-.485-1.222-2.184-6.275.486-13.038 0 0 4.125-1.304 13.426 5.052a46.97 46.97 0 0 1 12.214-1.63c4.125 0 8.33.571 12.213 1.63 9.302-6.356 13.427-5.052 13.427-5.052 2.67 6.763.97 11.816.485 13.038 3.155 3.422 5.015 7.822 5.015 13.2 0 18.905-11.404 23.06-22.324 24.283 1.78 1.548 3.316 4.481 3.316 9.126 0 6.6-.08 11.897-.08 13.526 0 1.304.89 2.853 3.316 2.364 19.412-6.52 33.405-24.935 33.405-46.691C97.707 22 75.788 0 48.854 0z"
                />
              </svg>
              {L("使用 GitHub 登录", "Login with GitHub")}
            </a>
          </div>
        ) : (
          /* Upload Interface */
          <div style={{ maxWidth: "40rem", margin: "0 auto" }}>
            {/* WeChat ID Input */}
            <div className="card" style={{ marginBottom: "1.25rem" }}>
              <label
                style={{
                  display: "block",
                  fontSize: "0.85rem",
                  fontWeight: 600,
                  marginBottom: "0.5rem",
                }}
              >
                {L("微信号", "WeChat ID")}
                <span style={{ color: "#ef4444", marginLeft: "0.25rem" }}>*</span>
              </label>
              <input
                type="text"
                value={wechatId}
                onChange={(e) => setWechatId(e.target.value)}
                placeholder={L("请输入你的微信号（必填）", "Enter your WeChat ID (required)")}
                style={{
                  width: "100%",
                  padding: "0.625rem 0.875rem",
                  borderRadius: "0.5rem",
                  border: "1px solid var(--gray-200)",
                  fontSize: "0.85rem",
                  outline: "none",
                  background: "var(--bg)",
                  color: "var(--text)",
                  transition: "border-color 0.15s",
                }}
                onFocus={(e) => (e.target.style.borderColor = "#000")}
                onBlur={(e) => (e.target.style.borderColor = "var(--gray-200)")}
              />
              <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: "0.375rem" }}>
                {L("用于后续联系和反馈研究结果", "For follow-up contact and sharing research results")}
              </p>
            </div>

            {/* Drag & Drop Upload Zone */}
            <div
              className="card"
              onDragOver={(e) => {
                e.preventDefault()
                setDragOver(true)
              }}
              onDragLeave={() => setDragOver(false)}
              onDrop={onDrop}
              onClick={() => fileRef.current?.click()}
              style={{
                marginBottom: "1.25rem",
                cursor: "pointer",
                textAlign: "center",
                padding: "3rem 2rem",
                border: dragOver ? "2px dashed #000" : "2px dashed var(--gray-300)",
                background: dragOver ? "var(--gray-50)" : "var(--bg)",
                transition: "all 0.2s ease",
                position: "relative",
              }}
            >
              <input ref={fileRef} type="file" accept=".jsonl" onChange={onFileSelect} style={{ display: "none" }} />

              {uploading ? (
                <div>
                  <div
                    style={{
                      width: "3rem",
                      height: "3rem",
                      border: "3px solid var(--gray-200)",
                      borderTopColor: "#000",
                      borderRadius: "50%",
                      margin: "0 auto 1rem",
                      animation: "spin 0.8s linear infinite",
                    }}
                  />
                  <p style={{ fontSize: "0.9rem", fontWeight: 500 }}>{L("上传中...", "Uploading...")}</p>
                </div>
              ) : (
                <div>
                  <div
                    style={{
                      width: "3.5rem",
                      height: "3.5rem",
                      borderRadius: "50%",
                      background: "var(--gray-100)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      margin: "0 auto 1rem",
                    }}
                  >
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      style={{ width: "1.5rem", height: "1.5rem", color: "var(--text-muted)" }}
                    >
                      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                      <polyline points="17 8 12 3 7 8" />
                      <line x1="12" y1="3" x2="12" y2="15" />
                    </svg>
                  </div>
                  <p style={{ fontSize: "0.95rem", fontWeight: 600, marginBottom: "0.375rem" }}>
                    {L("拖拽 .jsonl 文件到此处", "Drag & drop .jsonl file here")}
                  </p>
                  <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
                    {L("或点击选择文件 · 仅支持 .jsonl · 最大 50MB", "or click to select · .jsonl only · max 50MB")}
                  </p>
                </div>
              )}
            </div>

            {/* Upload Result */}
            {uploadResult && (
              <div
                style={{
                  padding: "0.75rem 1rem",
                  borderRadius: "0.5rem",
                  marginBottom: "1.25rem",
                  fontSize: "0.85rem",
                  background: uploadResult.ok ? "#f0fdf4" : "#fef2f2",
                  border: `1px solid ${uploadResult.ok ? "#86efac" : "#fca5a5"}`,
                  color: uploadResult.ok ? "#166534" : "#991b1b",
                }}
              >
                {uploadResult.message}
              </div>
            )}

            {/* Upload History */}
            {uploads.length > 0 && (
              <div className="card">
                <h3 style={{ fontSize: "0.9rem", fontWeight: 600, marginBottom: "1rem" }}>
                  {L("上传历史", "Upload History")}
                </h3>
                <div style={{ display: "flex", flexDirection: "column", gap: "0.5rem" }}>
                  {uploads.map((u, i) => (
                    <div
                      key={i}
                      style={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        padding: "0.625rem 0.75rem",
                        borderRadius: "0.5rem",
                        background: "var(--bg-alt)",
                        fontSize: "0.8rem",
                      }}
                    >
                      <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                        <svg
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2"
                          style={{ width: "1rem", height: "1rem", color: "var(--text-muted)", flexShrink: 0 }}
                        >
                          <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z" />
                          <polyline points="14 2 14 8 20 8" />
                        </svg>
                        <span style={{ fontFamily: "ui-monospace, monospace", fontWeight: 500 }}>{u.file_name}</span>
                      </div>
                      <div style={{ display: "flex", alignItems: "center", gap: "0.75rem", color: "var(--text-muted)" }}>
                        <span>{formatSize(u.file_size)}</span>
                        <span>{new Date(u.created_at).toLocaleDateString()}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* How to get .jsonl */}
            <div className="card" style={{ marginTop: "1.25rem" }}>
              <h3 style={{ fontSize: "0.9rem", fontWeight: 600, marginBottom: "0.75rem" }}>
                {L("如何获取 .jsonl 文件？", "How to get your .jsonl file?")}
              </h3>
              <div style={{ fontSize: "0.8rem", color: "var(--text-secondary)", lineHeight: 1.8 }}>
                <p style={{ marginBottom: "0.5rem" }}>
                  <strong>Claude Code:</strong>
                </p>
                <div className="code-inline" style={{ marginBottom: "0.75rem" }}>
                  ls ~/.claude/projects/*/sessions/*.jsonl
                </div>
                <p style={{ marginBottom: "0.5rem" }}>
                  <strong>Codex CLI:</strong>
                </p>
                <div className="code-inline">
                  ls ~/.codex/sessions/*.jsonl
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Spinner animation */}
      <style>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  )
}
