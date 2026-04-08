---
name: pua:survey
description: "Run the PUA feedback survey workflow. Use only when the user explicitly invokes `$pua:survey` or asks to complete the feedback survey."
license: MIT
---

# PUA Survey

Read `../pua/references/survey.md` and use AskUserQuestion to guide the user through the survey in sections. After collecting responses, write the JSON summary to `~/.pua/survey-response.json` and upload it to `https://pua-skill.pages.dev/api/feedback`.
