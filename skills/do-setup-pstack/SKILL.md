---
name: do-setup-pstack
description: Show which pstack plugin agents use which @role, and at what reasoning budget. Change routing via /agents or /model Roles. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
---

# Setup pstack (omp)

Official persist is `/model` → Roles (`modelRoles` in config.yml) and each plugin `agents/*.md` `model: "@role"`. This is **not** `~/.omp/agent/pstack/models.json` (that file is not omp routing; ignore it). Do not edit `~/.omp/agent/config.yml` by hand unless the user asks.

## Plugin agents and current roles

These files live in this plugin's `agents/` directory. Change a mapping with `/agents` (per-agent model override) or `/model` → Roles (the `@role` alias).

| Agent | Role | Typical use |
| --- | --- | --- |
| poteto-agent | `@default` | /poteto-mode delegates and general playbook workers |
| comment-sicko | `@smol` | /no-comments report-only pass |
| how-explorer | `@default` | /how explorer; also the mining reader for /automate-me and /recall |
| swarm-worker | `@default` | /swarm slice or race arm |
| bug-fix-worker, feature-worker, perf-issue-worker, hillclimb-worker, refactoring-worker | `@task` | playbook implementation delegates |
| arena-runner-a, interrogate-reviewer-a | `@slow` | panel seat A |
| arena-runner-b, interrogate-reviewer-b | `@pstack_panel_b` | panel seat B |
| arena-runner-c, interrogate-reviewer-c | `@pstack_panel_c` | panel seat C |
| arena-judge | `@advisor` | /arena readonly cross-judge |

Most agents use the built-in roles (`smol`, `default`, `task`, `slow`, `advisor`). Only the extra angles get custom roles: `pstack_panel_b` and `pstack_panel_c`. Panels (/arena, /architect, /interrogate) run seat A on `slow` and seats B/C on those two roles. The interrogate seats double as cross-family second opinions and verifiers. Set both custom roles in `modelRoles` on model families that differ from `slow` and from each other. An unset custom role falls back to the session model, which silently collapses the panel onto one model. Keep `advisor` on a family that differs from the runners.

## Steps

### 1. Load current state

Read `~/.omp/agent/config.yml` `modelRoles` and print the live map next to the table above. Flag `pstack_panel_b` / `pstack_panel_c` if unset. Do not write config.yml or models.json unless the user asks.

### 2. Budget

Ask for a reasoning budget with `ask`. Offer these three options with these exact labels, and name the current budget when the live roles show one. With no custom setting, say that `large` matches the agent defaults.

- `large — xhigh reasoning`
- `medium — high reasoning`
- `small — medium reasoning`

The budget caps the reasoning level, and no role goes above `xhigh`. Each role has a target level, which is its agent default moved by the budget. `large` keeps it, `medium` lowers it one step, and `small` lowers it two steps, on the ladder `xhigh` > `high` > `medium` > `low`. A target at the bottom of the ladder stays there.

### 3. Apply it

Apply the budget as the `:<level>` suffix on each role's selector in `/model` → Roles, for example `claude-opus-5-5:high`. Use the level from step 2 for every role. A model without that level uses its highest supported level below it. `task.maxEffort` caps every subagent's effort, so check it when a budget looks ignored.

Do not write any model slug the user has not picked from `/model`. If the user wants a different concrete model for a role, tell them to open `/model` → Roles and change that `@role`. If they want one agent on a different role or concrete selector, tell them to open `/agents` and override that agent.

### 4. Confirm

Confirm the change is in `/agents` or Roles. New `task` calls pick it up. Re-running this skill only re-lists; it writes no routing files.

## Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, invoke `/create-verification-skill`. On no, move on without pushing.

## Offer a formal verification skill (optional)

Check whether the project already has a formal verification skill (a project skill that runs a model checker, a proof, or another verifier against the code). If not, offer once: "want a formal verification skill, so agents can prove a key property of your code holds in every case in scope, not only the cases tests reach? I can generate one with /create-formal-verification-skill." On yes, invoke `/create-formal-verification-skill`. On no, move on without pushing.
