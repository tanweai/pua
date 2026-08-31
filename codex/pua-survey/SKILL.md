---
name: pua-survey
description: "Run the PUA research questionnaire."
license: MIT
---

# pua-survey

This is a Codex CLI alias for the Claude Code `/pua:survey` command.

Guide the user through the PUA survey and save the response to `~/.pua/survey-response.json`. Local file only — never POST it anywhere; PUA has no collection endpoint.

When this alias changes `~/.pua/config.json`, preserve unknown fields and create `~/.pua/` if missing. Do not claim completion without command/output evidence.
