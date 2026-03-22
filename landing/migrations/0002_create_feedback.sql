-- Feedback table for PUA skill usage analytics
CREATE TABLE IF NOT EXISTS feedback (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  rating TEXT NOT NULL,           -- '很有用' | '一般般' | '没感觉' | custom
  task_summary TEXT,              -- brief task description (anonymized)
  pua_level TEXT DEFAULT 'L0',    -- L0-L4
  pua_count INTEGER DEFAULT 0,   -- number of [PUA生效] markers
  flavor TEXT DEFAULT '阿里',     -- active flavor
  session_data TEXT,              -- anonymized session (tool calls only)
  failure_count INTEGER DEFAULT 0,
  ip_country TEXT,                -- CF-IPCountry header
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_feedback_rating ON feedback(rating);
CREATE INDEX IF NOT EXISTS idx_feedback_created ON feedback(created_at);
