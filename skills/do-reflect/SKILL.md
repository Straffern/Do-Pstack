---
name: do-reflect
description: Spawn three parallel review subagents over the active transcript, surface learnings, and route each to a concrete edit on an existing skill. Use when the user says reflect.
disable-model-invocation: true
---

# Reflect

Mine the current conversation for durable learnings, then route them into skill edits.

Invoke when the user says "reflect" or "/reflect". Skip when the conversation is trivial, off-topic, or already covered by an existing skill the parent followed correctly. One-offs are not learnings.

## 1. Locate the active transcript

Before fanning out, find this conversation's transcript in this workspace's buckets, per the **recall** skill's Where transcripts live section. Never glob across all buckets. That crosses workspace boundaries and reads private chats from unrelated projects.

```bash
ls -t <bucket>/*.jsonl <bucket>/*/*.jsonl <bucket>/*/subagents/*.jsonl 2>/dev/null | head -10
```

Run it once per bucket. That covers chat files (`<timestamp>_<id>.jsonl` on omp and Pi, `<id>.jsonl` on Claude Code) and subagent transcripts (`<timestamp>_<id>/<agent>.jsonl` on omp and Pi, `<id>/subagents/agent-<id>.jsonl` on Claude Code). The live chat is usually the newest chat file. Confirm with `grep -lF` on a distinctive phrase from the conversation's opening user prompt, one without quotes or line breaks since the JSON escapes those, and take the file that matches. If none matches, pass a tight digest of the session instead.

## 2. Spawn three reviewers in parallel

One `task` call with three `tasks` entries: `agent: "reflect-judgment"` for the Judgment and Divergent lenses, `agent: "reflect-tooling"` for the Tooling lens (reviewers need MCP; do not pass `model` or `readonly`). Distinct lens in the task text (Judgment / Tooling / Divergent). The prompt forbids file writes; the parent applies edits. Pick each subagent's reasoning level and fast or standard speed for the job, per the Subagents section of the **poteto-mode** skill.

| Lens | Prompt template |
|---|---|
| Judgment | `references/judgment-reviewer.md` |
| Tooling | `references/tooling-reviewer.md` |
| Divergent | `references/divergent-reviewer.md` |

Pass each template verbatim, substituting the transcript path or digest where marked. Reviewers return findings in the `task` response body.

## 3. Synthesize

One `task` call with `tasks: [{ agent: "reflect-judgment", task: "<synthesizer brief>" }]`. Do not pass `model` or `readonly`. The synthesizer's quality check includes spot-verifying citations, which can require MCP access. Use `references/synthesizer.md` verbatim, with each reviewer's full output inlined where marked. The synthesizer returns a structured Accepted / Rejected / Backlog list.

## 4. Structural enforcement check

Move any Accepted item that a lint rule, script, metadata flag, or runtime check would enforce more reliably to Backlog. See the **encode-lessons-in-structure** principle skill.

## 5. Apply

Present the synthesizer's full Accepted / Rejected / Backlog output and wait for explicit approval before applying any Accepted edit. The user picks the subset and may redirect routings. Skill changes affect every future agent in the org. Do not auto-apply.

File each Backlog item to your team's devex or backlog tracker without waiting. Only the Accepted list waits for approval.

Follow each approved row's Routing exactly:

- Trivial existing-skill edit (a one-line bullet, a tightened sentence, a stale fact corrected): the parent does it directly.
- Substantive existing-skill edit (a new section, a new pattern table, more than ~10 lines): hand to Cursor's built-in `create-skill` skill and run its draft / test / iterate loop.
- `tune description: <skill path>` (the skill exists but didn't trigger when it should have): hand to `create-skill` and run its description-optimization loop.
- `new skill via create-skill: <kebab-name>`: hand creation to `create-skill`. Do not invent the shape ad hoc.

If your environment ships a SKILL.md validator, run it on every touched skill before declaring done.

## 6. Summarize for the user

Short list, no preamble:

- Edits applied: `<skill path>`. What changed, one line each.
- New skills created: `<skill path>`. One line each (rare).
- Backlog filed to the devex tracker: `<issue title>` (`<tags>`). One line each.
- Dropped: one line per rejected finding + reason from the synthesizer.
