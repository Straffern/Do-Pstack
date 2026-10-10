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
| how-explorer | `@default` | /how complex-question explorers; also source-wave / mining readers |
| how-explainer | `@slow` | /how synthesis |
| arena-runner-a / -b / -c | `@pstack_arena_runner_a` / `_b` / `_c` | /arena candidate seats (each writes only its assigned path) |
| architect-runner-a / -b / -c | `@pstack_architect_runner_a` / `_b` / `_c` | /architect design candidate seats |
| arena-judge | `@pstack_arena_judge` | /arena and /architect readonly cross-judge |
| interrogate-reviewer-a / -b / -c | `@pstack_interrogate_reviewer_a` / `_b` / `_c` | /interrogate reviewers, /how critics, cross-family second opinions and verifiers |
| swarm-worker | `@default` | /swarm slice or race arm |
| why-investigator | `@pstack_why_investigator` | /why per-category investigators |
| why-synthesizer | `@pstack_why_synthesizer` | /why synthesis |
| reflect-judgment | `@pstack_reflect_judgment` | /reflect Judgment and Divergent lenses and synthesizer |
| reflect-tooling | `@pstack_reflect_tooling` | /reflect Tooling lens |
| bug-fix-worker | `@pstack_bug-fix` | Bug fix playbook implementation delegate |
| feature-worker | `@pstack_feature` | Feature playbook implementation delegate |
| perf-issue-worker | `@pstack_perf_issue` | Perf issue playbook implementation delegate |
| hillclimb-worker | `@pstack_hillclimb` | Hillclimb playbook implementation delegate |
| refactoring-worker | `@pstack_refactoring` | Refactoring playbook implementation delegate |

The `pstack_*` roles exist so each panel seat can run a different model. They are custom roles: they appear in `/model` → Roles once set in `modelRoles` (`pstack_arena_runner_a: <provider>/<model>:<thinking>`). An unset `pstack_*` role falls back to the task/session model, which silently collapses the panel onto one model. Point the a/b/c seats of a panel at different models. The interrogate seats double as cross-family second opinions and verifiers, so keep at least one on a family the workers don't use.

## Steps

1. Read `~/.omp/agent/config.yml` `modelRoles` and print the live map. Then list the table above and flag every `pstack_*` role that is unset. Do not write config.yml, models.json, or pstack-models.mdc unless the user asks.
2. If the user wants a different concrete model for a role, tell them to open `/model` → Roles and change that `@role`. If they want one agent on a different role or concrete selector, tell them to open `/agents` and override that agent.
3. Confirm the change is in `/agents` or Roles. New `task` calls pick it up. Re-running this skill only re-lists; it writes no routing files.

## Offer a verification skill (optional)

If the project has no `verify-*` skill or harness, offer once to run `/create-verification-skill`. On no, move on.
