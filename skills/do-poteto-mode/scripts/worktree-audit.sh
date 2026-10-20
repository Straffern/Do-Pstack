#!/usr/bin/env bash
# Read-only worktree prune audit. Classifies every git worktree by size, merge
# state, uncommitted work, remote/PR state, and the most recent chat that
# operated in it. Emits a table sorted by size with a suggested bucket. Never
# deletes anything; deletion stays a human-gated step in the playbook.
#
# Usage: worktree-audit.sh [-b|--base <ref>] [repo-path]
#   repo-path defaults to the current repo.
#   -b sets the ref the MERGED column checks against (e.g. origin/integration).
#   Without it the base is origin/HEAD, then origin/main, then origin/master.
#   origin/HEAD is the remote's default branch, not necessarily the branch PRs
#   merge into; pass -b when they differ.
set -u

base=""
while [ $# -gt 0 ]; do
	case "$1" in
	-b|--base) [ $# -ge 2 ] || { echo "error: $1 needs a ref" >&2; exit 2; }; base="$2"; shift 2 ;;
	-h|--help) sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
	-*) echo "error: unknown option: $1" >&2; exit 2 ;;
	*) break ;;
	esac
done

repo="${1:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -z "$repo" ] && { echo "not in a git repo; pass a repo path" >&2; exit 1; }
cd "$repo" || exit 1
git rev-parse --git-dir >/dev/null 2>&1 || { echo "error: not a git repo: $repo" >&2; exit 1; }

# Main worktree is the first entry; everything else is a candidate.
main_wt=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')

if [ -z "$base" ]; then
	for cand in "$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)" origin/main origin/master; do
		[ -n "$cand" ] && git rev-parse --verify --quiet "$cand^{commit}" >/dev/null && { base="$cand"; break; }
	done
	[ -z "$base" ] && { echo "error: no base ref (origin/HEAD, origin/main, origin/master all missing); pass -b <ref>" >&2; exit 1; }
	echo "warn: no -b given; MERGED checks against $base" >&2
fi

# The base drives the merge check. The fetch is best-effort (stale is fine for
# a first pass) and runs before the check, since -b may name a branch not
# fetched yet. The explicit refspec creates it even in a single-branch clone.
case "$base" in
origin/*) git fetch origin "+refs/heads/${base#origin/}:refs/remotes/$base" --quiet 2>/dev/null \
	|| echo "warn: could not fetch $base; merged column may be stale" >&2 ;;
esac
git rev-parse --verify --quiet "$base^{commit}" >/dev/null 2>&1 || { echo "error: base ref not found: $base" >&2; exit 1; }

# PR state by branch, fetched once as [{number, state, head}] with a lowercase
# state. Origin when its CLI can read this repo's PRs, otherwise gh. Empty when
# neither can.
prs=$(mktemp)
if command -v origin >/dev/null 2>&1 \
	&& raw=$(origin pr list --author "@me" --state all --limit 1000 \
		--json number,status,headRef 2>/dev/null); then
	printf '%s' "$raw" | jq '[.[] | {number, state: .status, head: .headRef}]' > "$prs" 2>/dev/null
elif raw=$(gh pr list --author "@me" --state all --limit 1000 \
	--json number,state,headRefName 2>/dev/null); then
	printf '%s' "$raw" | jq '[.[] | {number, state: (.state | ascii_downcase), head: .headRefName}]' > "$prs" 2>/dev/null
fi
[ -s "$prs" ] || echo "[]" > "$prs"

# Transcripts: each host keeps one bucket per cwd. The recall skill's "Where
# transcripts live" section owns the layouts; this mirrors them.
#   omp:         <agent>/sessions/, temp -> -tmp-<rel>, home -> -<rel>, else --<abs>--
#   Pi:          <agent>/sessions/, always --<abs>-- (getDefaultSessionDirPath)
#   Claude Code: ${CLAUDE_CONFIG_DIR:-~/.claude}/projects/, every non-alnum -> -;
#                past 200 chars, cut to 200 plus -<hash> (matched here by glob)
# omp and Pi both honor PI_CODING_AGENT_DIR and nothing in a bucket says which
# host wrote it, so both rules run under every agent root: the env dir plus the
# two defaults. Pi's flat PI_CODING_AGENT_SESSION_DIR is searched whole.
agent_roots=("$HOME/.omp/agent" "$HOME/.pi/agent")
case "${PI_CODING_AGENT_DIR:-}" in
"") ;;
"~" | "~/"*) agent_roots+=("$HOME${PI_CODING_AGENT_DIR#\~}") ;;
*) agent_roots+=("$PI_CODING_AGENT_DIR") ;;
esac
claude_projects="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects"
home_real=$(cd "$HOME" 2>/dev/null && pwd -P || echo "$HOME")
tmp_real=$(cd "${TMPDIR:-/tmp}" 2>/dev/null && pwd -P || echo "${TMPDIR:-/tmp}")
add_dir() { [ -d "$1" ] && dirs+=("$1"); return 0; }
# bucket_dirs <path>: append every existing host bucket for <path> to dirs.
# Claude's encoding is per UTF-16 unit and ours is per byte, so non-ASCII
# paths can yield a different bucket name; ASCII paths match exactly.
bucket_dirs() {
	local p r abs enc d
	p=$(cd "$1" 2>/dev/null && pwd -P || echo "$1")
	case "$p" in
	"$tmp_real") r=-tmp ;;
	"$tmp_real"/*) r=${p#"$tmp_real"/}; r=-tmp-${r//[\/:]/-} ;;
	"$home_real") r=- ;;
	"$home_real"/*) r=${p#"$home_real"/}; r=-${r//[\/:]/-} ;;
	*) r=${p#/}; r=--${r//[\/:]/-}-- ;;
	esac
	abs=${p#/}; abs=--${abs//[\/\\:]/-}--
	for d in "${agent_roots[@]}"; do
		add_dir "$d/sessions/$r"
		[ "$abs" = "$r" ] || add_dir "$d/sessions/$abs"
	done
	enc=$(printf '%s' "$p" | LC_ALL=C tr -c 'a-zA-Z0-9' '-')
	if [ ${#enc} -le 200 ]; then add_dir "$claude_projects/$enc"
	else for d in "$claude_projects/${enc:0:200}"-*; do add_dir "$d"; done; fi
}
now=$(date +%s)

echo "# base: $base"
printf "SIZE\tAGE\tMERGED\tDIRTY\tREMOTE\tPR\tLAST_CHAT\tBUCKET\tWORKTREE\n"

git worktree list --porcelain | awk '/^worktree /{print $2}' | while read -r wt; do
	[ "$wt" = "$main_wt" ] && continue

	size=$(du -sh "$wt" 2>/dev/null | awk '{print $1}')
	head=$(git -C "$wt" rev-parse HEAD 2>/dev/null)
	head_ts=$(git -C "$wt" log -1 --format='%ct' HEAD 2>/dev/null || echo 0)
	age=$([ "$head_ts" -gt 0 ] 2>/dev/null && echo "$(( (now - head_ts) / 86400 ))d" || echo "?")

	# Squash-merged branches are not ancestors of the base, so PR state is the
	# real signal; merge-base only catches fast-forward/rebase merges.
	git merge-base --is-ancestor "$head" "$base" 2>/dev/null && merged=YES || merged=no

	# Distinguish real WIP (tracked edits) from disposable untracked scratch.
	porcelain=$(git -C "$wt" status --porcelain 2>/dev/null)
	if [ -z "$porcelain" ]; then dirty=clean
	elif printf '%s\n' "$porcelain" | grep -qv '^??'; then
		dirty="wip:$(printf '%s\n' "$porcelain" | grep -cv '^??')"
	else dirty="scratch:$(printf '%s\n' "$porcelain" | grep -c '^??')"; fi

	branch=$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")
	if [ -z "$branch" ]; then remote=detached
	elif git -C "$wt" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
		[ "$(git -C "$wt" rev-parse "origin/$branch" 2>/dev/null)" = "$head" ] \
			&& remote=pushed \
			|| remote="ahead$(git -C "$wt" rev-list --count "origin/$branch..HEAD" 2>/dev/null)"
	else remote=no-remote; fi

	pr=$([ -n "$branch" ] && jq -r --arg b "$branch" \
		'.[] | select(.head==$b) | "#\(.number)/\(.state)"' "$prs" 2>/dev/null | head -1)
	[ -z "$pr" ] && pr="-"

	# Most recent chat that operated in this worktree, from any host: one
	# started there (its own buckets) or a main-worktree chat that touched it.
	# Match path followed by "/" or a quote so glint-482 does not match
	# glint-482-r37. rg sorts by modified time; the newest match wins.
	last="-"; last_ts=0
	dirs=()
	bucket_dirs "$main_wt"
	bucket_dirs "$wt"
	[ -n "${PI_CODING_AGENT_SESSION_DIR:-}" ] && add_dir "$PI_CODING_AGENT_SESSION_DIR"
	f=""
	[ ${#dirs[@]} -gt 0 ] && f=$(rg -l --sortr modified -e "${wt}/" -e "${wt}\"" "${dirs[@]}" 2>/dev/null | head -1)
	if [ -n "$f" ]; then last_ts=$(date -r "$f" +%s 2>/dev/null || echo 0)
		last=$(date -r "$f" '+%Y-%m-%d' 2>/dev/null); fi
	recent=$([ "$last_ts" -gt 0 ] 2>/dev/null && [ $(( (now - last_ts) / 86400 )) -le 4 ] && echo yes || echo no)

	case "$dirty" in wip:*) bucket=hold-wip ;; *)
		case "$pr" in */open|*/draft) bucket=hold-open-pr ;; *)
			if [ "$recent" = yes ]; then bucket=verify-recent-chat
			elif [ "$merged" = YES ] || [ "$pr" != "-" ]; then bucket=safe
			else bucket=review; fi ;;
		esac ;;
	esac

	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
		"$size" "$age" "$merged" "$dirty" "$remote" "$pr" "$last" "$bucket" "$wt"
done | sort -t$'\t' -k1,1 -rh

rm -f "$prs"
