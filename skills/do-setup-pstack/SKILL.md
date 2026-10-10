---
name: do-setup-pstack
description: Show which pstack plugin agents use which @role. Change routing via /agents or /model Roles. Use for /setup-pstack, "configure pstack models", or changing pstack's model choices.
---

# Setup pstack (omp)

Official persist is `/model` → Roles (`modelRoles` in config.yml) and each plugin `agents/*.md` `model: "@role"`. This is **not** `~/.omp/agent/pstack/models.json` (that file is not omp routing; ignore it). Do not write Cursor `pstack-models.mdc`. Do not edit `~/.omp/agent/config.yml` by hand unless the user asks.

## Plugin agents and current roles

These files live in this plugin's `agents/` directory. Change a mapping with `/agents` (per-agent model override) or `/model` → Roles (the `@role` alias).

| Agent | Role | Typical use |
| --- | --- | --- |
| poteto-agent | `@default` | /poteto-mode delegates and general playbook workers |
| comment-sicko | `@smol` | /no-comments report-only pass |
| how-explorer | `@default` | /how explorers; source-wave / mining readers |
| how-explainer | `@slow` | /how synthesis |
| swarm-worker | `@default` | /swarm slice or race arm |
| bug-fix-worker, feature-worker, perf-issue-worker, hillclimb-worker, refactoring-worker | `@task` | playbook implementation delegates |
| why-investigator | `@default` | /why per-category investigators |
| why-synthesizer | `@slow` | /why synthesis |
| reflect-judgment | `@slow` | /reflect Judgment and Divergent lenses and synthesizer |
| reflect-tooling | `@pstack_panel_b` | /reflect Tooling lens (a second angle) |
| arena-runner-a, architect-runner-a, interrogate-reviewer-a | `@slow` | panel seat A |
| arena-runner-b, architect-runner-b, interrogate-reviewer-b | `@pstack_panel_b` | panel seat B |
| arena-runner-c, architect-runner-c, interrogate-reviewer-c | `@pstack_panel_c` | panel seat C |
| arena-judge | `@advisor` | /arena and /architect readonly cross-judge |

Most agents use the built-in roles (`smol`, `default`, `task`, `slow`, `advisor`). Only the extra angles get custom roles: `pstack_panel_b` and `pstack_panel_c`. Panels (/arena, /architect, /interrogate, /how critics) run seat A on `slow` and seats B/C on those two roles. The interrogate seats double as cross-family second opinions and verifiers. Set both custom roles in `modelRoles` on model families that differ from `slow` and from each other. An unset custom role falls back to the session model, which silently collapses the panel onto one model. Keep `advisor` on a family that differs from the runners.

## Steps

1. Read `~/.omp/agent/config.yml` `modelRoles` and print the live map. Then list the table above and flag `pstack_panel_b` / `pstack_panel_c` if unset. Do not write config.yml, models.json, or pstack-models.mdc unless the user asks.
2. If the user wants a different concrete model for a role, tell them to open `/model` → Roles and change that `@role`. If they want one agent on a different role or concrete selector, tell them to open `/agents` and override that agent.
3. Confirm the change is in `/agents` or Roles. New `task` calls pick it up. Re-running this skill only re-lists; it writes no routing files.

## Offer a verification skill (optional)

If the project has no `verify-*` skill or harness, offer once to run `/create-verification-skill`. On no, move on.
