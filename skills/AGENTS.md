# skills

## Purpose

pstack skill tree. Sibling `skills/` at the package root is what omp auto-discovers after `omp plugin link ./` and what Claude Code loads from the plugin root after install. Do not add a second skills tree. Do not nest skills inside `.claude-plugin/`.

## Ownership

- `*/SKILL.md` plus that skill's references, playbooks, and scripts.

## Local Contracts

- Skill directories and YAML `name` use the `do-` prefix. After `omp plugin link ./`, the live slash is `/skill:do-<name>`. After Claude plugin install, the live slash is `/pstack:do-<name>`. Do not rename the `do-` set.
- Every `SKILL.md` has YAML frontmatter with non-empty `name` and `description`.
- `python3 e2e/ci_static.py --frontmatter` is the gate.
- Skills and scripts that read chat transcripts cover omp, Pi, and Claude Code. The encodings live in the **recall** skill's Where transcripts live section. `do-poteto-mode/scripts/worktree-audit.sh` mirrors them in `bucket_dirs()`; keep the two in sync.

## Work Guidance

Keep leaf skills operational. Do not add a per-skill AGENTS.md unless a skill becomes its own durable boundary.

Official skill bodies come from `cursor/plugins` `pstack/skills`. Refresh this tree with `npm run sync` (`node scripts/pstack.mjs sync`). That maps `skills/<name>` → `skills/do-<name>` here. Do not add a second skills tree. Do not `npx skills add`. Editing an official file here is fine: `upstream.lock.json` keeps it through later syncs, and sync reports a conflict once upstream changes the same file.

## Verification

```bash
python3 e2e/ci_static.py --frontmatter
```

## Child DOX Index

None. One contract covers the tree.
