-- Rate-limit tracking for POST /api/feedback (issue #96)
-- One row per (ip, 1h-window). New hour = INSERT OR REPLACE starting at 1.
-- Old rows are swept lazily on write so the table stays bounded.
CREATE TABLE IF NOT EXISTS feedback_rate_limits (
  ip TEXT NOT NULL,
  window_start INTEGER NOT NULL,   -- unix epoch seconds at start of hour bucket
  count INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (ip, window_start)
);

CREATE INDEX IF NOT EXISTS idx_feedback_ratelimit_window
  ON feedback_rate_limits(window_start);
