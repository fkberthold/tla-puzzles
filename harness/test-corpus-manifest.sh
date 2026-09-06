#!/usr/bin/env bash
# Gate for corpus/manifest.tsv, the list of candidate systems PRACTICE-PLAN.md
# curates from.
#
# The invariant: every row names a repo, a path that exists in that repo at the
# recorded SHA, a licence, and a level in 1..5.
#
# Path existence needs a clone of the corpus, which is not in this repo and is
# 54M. So that half of the check runs only when TLA_CORPUS points at one, and
# reports itself as skipped otherwise. Everything else runs offline.
#
# Lineage: bead tla-e7q2.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_ROOT/corpus/manifest.tsv"

PASS=0
FAIL=0
SKIP=0

ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
skip() { SKIP=$((SKIP+1)); printf '  skip %s\n' "$1"; }

HEADER='system	repo	sha	dir	modules	level	describable	prose	prose_path	licence	checkable	tlc_seconds	why'

# Checks one manifest file and prints a defect count on stdout. Runs over a
# here-string rather than a pipe, since a pipeline into an early-exiting
# consumer returns 141 under pipefail and reads as a pass.
check_file() {
  local file="$1"
  local defects=0
  local line_no=0
  local seen_header=""
  local systems=""

  if [ ! -f "$file" ]; then
    printf 'missing\n'
    return 0
  fi

  local line
  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no+1))

    if [ "$line_no" -eq 1 ]; then
      seen_header="$line"
      if [ "$line" != "$HEADER" ]; then
        defects=$((defects+1))
      fi
      continue
    fi

    [ -z "$line" ] && continue

    local n
    n="$(awk -F'\t' '{print NF}' <<<"$line")"
    if [ "$n" -ne 13 ]; then
      defects=$((defects+1))
      continue
    fi

    # Split with awk, one field per line, rather than with read. Tab is IFS
    # whitespace, so `IFS=$'\t' read` collapses a run of tabs into one
    # delimiter and an empty field disappears. The empty-licence control
    # caught that.
    local F
    mapfile -t F < <(awk -F'\t' '{for (i=1; i<=NF; i++) print $i}' <<<"$line")

    local system="${F[0]}"  repo="${F[1]}"        sha="${F[2]}"
    local modules="${F[4]}" level="${F[5]}"       describable="${F[6]}"
    local prose="${F[7]}"   licence="${F[9]}"

    [ -n "$system" ]  || defects=$((defects+1))
    [ -n "$repo" ]    || defects=$((defects+1))
    [ -n "$modules" ] || defects=$((defects+1))
    [ -n "$licence" ] || defects=$((defects+1))

    case "$level" in
      1|2|3|4|5) ;;
      *) defects=$((defects+1)) ;;
    esac

    case "$describable" in
      yes|no) ;;
      *) defects=$((defects+1)) ;;
    esac

    case "$prose" in
      yes|no) ;;
      *) defects=$((defects+1)) ;;
    esac

    if ! [[ "$sha" =~ ^[0-9a-f]{7,40}$ ]]; then
      defects=$((defects+1))
    fi

    case "$systems" in
      *"|$system|"*) defects=$((defects+1)) ;;
      *) systems="$systems|$system|" ;;
    esac
  done <"$file"

  if [ -z "$seen_header" ]; then
    defects=$((defects+1))
  fi

  printf '%s\n' "$defects"
}

printf 'corpus manifest gate\n'

# 1. The manifest is there and clean.
result="$(check_file "$MANIFEST")"
if [ "$result" = "missing" ]; then
  bad "corpus/manifest.tsv exists"
elif [ "$result" -eq 0 ]; then
  ok "corpus/manifest.tsv: every row well formed"
else
  bad "corpus/manifest.tsv: $result malformed rows"
fi

# 2. Controls. Each is a manifest the checker MUST reject. A checker that
#    passes these is not reading the fields it claims to read.
CTRL="$(mktemp -d)"
trap 'rm -rf "$CTRL"' EXIT

printf '%s\n' "$HEADER" > "$CTRL/level.tsv"
printf 'a\tr\tabc1234\td\tM\t6\tyes\tyes\tp\tMIT\tyes\t1.0\tbecause\n' >> "$CTRL/level.tsv"

printf '%s\n' "$HEADER" > "$CTRL/licence.tsv"
printf 'a\tr\tabc1234\td\tM\t3\tyes\tyes\tp\t\tyes\t1.0\tbecause\n' >> "$CTRL/licence.tsv"

printf '%s\n' "$HEADER" > "$CTRL/sha.tsv"
printf 'a\tr\tnotasha\td\tM\t3\tyes\tyes\tp\tMIT\tyes\t1.0\tbecause\n' >> "$CTRL/sha.tsv"

printf '%s\n' "$HEADER" > "$CTRL/dup.tsv"
printf 'a\tr\tabc1234\td\tM\t3\tyes\tyes\tp\tMIT\tyes\t1.0\tbecause\n' >> "$CTRL/dup.tsv"
printf 'a\tr\tabc1234\td\tM\t3\tyes\tyes\tp\tMIT\tyes\t1.0\tbecause\n' >> "$CTRL/dup.tsv"

printf '%s\n' "$HEADER" > "$CTRL/width.tsv"
printf 'a\tr\tabc1234\td\tM\t3\n' >> "$CTRL/width.tsv"

printf 'system\trepo\n' > "$CTRL/header.tsv"
printf 'a\tr\n' >> "$CTRL/header.tsv"

for c in level licence sha dup width header; do
  r="$(check_file "$CTRL/$c.tsv")"
  if [ "$r" != "missing" ] && [ "$r" -gt 0 ]; then
    ok "control $c: rejected ($r defects)"
  else
    bad "control $c: accepted, so the check is blind to it"
  fi
done

# 3. Paths resolve, when a corpus clone is available.
if [ -n "${TLA_CORPUS:-}" ] && [ -d "${TLA_CORPUS:-}" ] && [ -f "$MANIFEST" ]; then
  missing=0
  rows=0
  # awk again, not read. A spec sitting at its repository root has an empty
  # dir, and `IFS=$'\t' read` swallows it, so every such row resolves against
  # the wrong field. That misreported 9 good rows as broken on the first run.
  while IFS= read -r row; do
    [ -z "$row" ] && continue
    rows=$((rows+1))
    local_repo="$(awk -F'\t' '{print $2}' <<<"$row")"
    local_dir="$(awk -F'\t' '{print $4}' <<<"$row")"
    [ -d "$TLA_CORPUS/$local_repo/$local_dir" ] || {
      missing=$((missing+1))
      printf '       unresolved: %s/%s\n' "$local_repo" "$local_dir"
    }
  done < <(tail -n +2 "$MANIFEST")
  if [ "$missing" -eq 0 ]; then
    ok "all $rows rows resolve under TLA_CORPUS"
  else
    bad "$missing of $rows rows name a directory not in TLA_CORPUS"
  fi
else
  skip "path resolution (set TLA_CORPUS to a corpus clone to run it)"
fi

printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
