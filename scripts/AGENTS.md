# scripts

## Purpose

Maintainer CLI for this package. `pstack.mjs` is `pstack sync` (vendor official skills) and `pstack bump` (semver).

## Ownership

- `pstack.mjs` — `pstack sync` (`--dry-run`, `--force`, `--accept PATH`) and `pstack bump <patch|minor|major>` (`--dry-run`, `--tag`, `--release`).
- `../upstream.lock.json` — written by `sync`: upstream `version`, `commit`, and per `skills/do-*` file the sha256 of the rewritten upstream bytes it last matched. Commit it with every sync.

## Local Contracts

- Source of truth is `https://github.com/cursor/plugins.git` folder `pstack/skills`. Not `backnotprop/pstack`. Not skills.sh. `npx skills add` is not the path (it would install a second skill tree).
- Layout map: upstream `skills/<name>/` → package `skills/do-<name>/`. YAML `name` gets the `do-` prefix. Sibling links `../<name>/` become `../do-<name>/`.
- One skill tree: sibling `skills/` at the package root. Do not write `.omp/skills`, `.claude-plugin/skills`, or agent skill dirs.
- Do not restore `poteto-mode/playbooks/shipping.md` (this fork deleted it).
- Default apply adds missing official files. Where a local file still equals its lock base, it takes the new upstream. A local edit stays while upstream has not moved (`kept`). If both moved, it is a `conflict`: not written, and the old base stays, so it reports until merged by hand and `--accept PATH`. A file with no base is `diverged` (kept). `--accept` records the current upstream as its base. `--force` takes upstream for every file except local subtractions. Files upstream deleted report `removed-upstream` and are never deleted. Written files take upstream's permission bits; a byte-equal file whose mode differs is an `update`.
- `bump <kind>` writes the `version` in `package.json` (omp + pi), `.claude-plugin/plugin.json`, and `.omp-plugin/plugin.json` only; all three must match. Marketplace catalog has no version field. After commit, `bump --tag` tags that HEAD sha; `bump --release` pushes the tag and `gh release create --target <sha>`. Kind and --tag together are refused.

## Work Guidance

Keep sync a fetch + layout rewrite. Keep bump a JSON version rewrite. Do not fold either into `extensions/pstack.ts`.

## Verification

```bash
node scripts/pstack.mjs sync --dry-run
node scripts/pstack.mjs bump patch --dry-run
npx vitest run e2e/unit/sync-skills.test.ts
```

## Child DOX Index

None.
