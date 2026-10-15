#!/usr/bin/env bash
# Gate for drill/INVENTORY.md's coverage fields and the generator that writes
# them.
#
# THE INVARIANT. Every one of the 105 ROW lines carries ten tab-delimited
# fields, field 10 names one of four verdicts and is never empty, and
# scripts/gen-coverage.sh reproduces the whole file byte for byte from
# drill/*/*/META.md and reading/*/*/USES.md. A coverage cell that disagrees
# with what the two corpora declare reddens this gate.
#
# WHY THE FILE NEEDS A GATE AT ALL. 105 rows times two channels is 210 cells
# nobody maintains by hand without drift, and the drift is silent: a stale
# cell reads exactly like a fresh one. So the file is generated and this suite
# proves the generated form is the form on disk.
#
# WHAT MUTATION BUYS OVER A GREEN RUN. A gate over a generated file is easy to
# write vacuously, because the generator and the gate agree with each other by
# construction. Parts 3 to 6 mutate a copy of the real corpora and require the
# gate to redden, one defect at a time. A control that passes means the check
# is blind to that defect, and it is reported as a failure.
#
# THE MIRROR. Mutation runs against a metadata-only copy of both corpora: 64
# META.md, 25 USES.md and the inventory, about 168 KB. The real tree is never
# written. Copying the .tla and .cfg files would multiply the cost for nothing,
# since the generator reads neither.
#
# Lineage: bead tla-zhfc.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GEN="$REPO_ROOT/scripts/gen-coverage.sh"
INVENTORY="$REPO_ROOT/drill/INVENTORY.md"

PASS=0
FAIL=0
SKIP=0

ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
skip() { SKIP=$((SKIP+1)); printf '  skip %s\n' "$1"; }

# Indents a captured block under a FAIL line. awk rather than
# `sed 's/^/       /'`, which shellcheck flags as SC2001 every time it sees a
# here-string on the left.
indent() { awk '{ print "       " $0 }' <<<"$1"; }

# How many non-blank lines a captured block holds.
lines() { awk 'NF > 0 { n++ } END { print n+0 }' <<<"$1"; }

# A control reddened the gate, which is what a control is for.
ctl_ok()  { ok "control: $1"; }
ctl_bad() { bad "control: $1 was accepted, so the check is blind to it"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

ROWS_EXPECTED=105
VERDICTS='both drill-only reading-only neither'

# ---------------------------------------------------------------------------
# Part 0: the pieces exist and run.
# ---------------------------------------------------------------------------
echo "part 0: the generator and the inventory"

if [ -f "$GEN" ] && [ -x "$GEN" ]; then
  ok "scripts/gen-coverage.sh exists and is executable"
else
  bad "scripts/gen-coverage.sh is missing or not executable"
  printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
  exit 1
fi

if [ -f "$INVENTORY" ]; then
  ok "drill/INVENTORY.md exists"
else
  bad "drill/INVENTORY.md is missing"
  printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
  exit 1
fi

# NO LITERAL REPO PATH IN CODE. scripts/gen-curriculum-map.sh used to open with
# `cd /home/frank/repos/tla-puzzles`, so running it from a worktree wrote its
# output into the MAIN checkout. A footprint check cannot see that, because it
# happens inside the script. (bead tla-1hf)
#
# COMMENTS ARE EXEMPT, and they have to be. The generator's own header quotes
# the path that caused tla-1hf so a reader knows what the hazard looked like,
# and a check that reddened on the quote would push the next author to delete
# the explanation. So the scan drops comment lines first. A path in a comment
# does not cd anywhere.
hardcoded="$(sed 's/#.*$//' "$GEN" | grep -nE '/(home|Users)/[A-Za-z0-9_.-]+/')" || hardcoded=""
if [ -z "$hardcoded" ]; then
  ok "the generator carries no literal home-directory path"
else
  bad "the generator carries a literal path, which writes across checkouts:"
  printf '       %s\n' "$hardcoded"
fi

if grep -qE 'BASH_SOURCE' "$GEN"; then
  ok "the generator resolves its root from BASH_SOURCE"
else
  bad "the generator does not resolve its root from BASH_SOURCE"
fi

# ---------------------------------------------------------------------------
# Part 1: the shape of the live file.
#
# awk with -F'\t' throughout, never `IFS=$'\t' read`. Tab is an IFS whitespace
# character, so a run of tabs collapses into one delimiter and an empty cell
# disappears, shifting every later field left. Fields 8 and 9 are empty on 29
# of the 105 rows between them, which is exactly the case that triggers it.
# ---------------------------------------------------------------------------
echo
echo "part 1: the shape of drill/INVENTORY.md"

# The real slug set, built once. `-mindepth 2 -maxdepth 2` picks up
# drill/study/check as well as the 89 items, which only widens the set a claim
# is checked against, so it is harmless here.
find "$REPO_ROOT/drill" "$REPO_ROOT/reading" -mindepth 2 -maxdepth 2 -type d \
  ! -path "$REPO_ROOT/drill/.*" ! -path "$REPO_ROOT/reading/.*" \
  | sed 's|.*/||' | sort -u > "$WORK/slugs-real"

# shape_defects <inventory>. one "<code> <detail>" line per defect found, and
# nothing at all on a clean file.
#
# FACTORED INTO A FUNCTION so the same code can run against the live file and
# against a deliberately broken copy. A shape check that only ever sees a good
# file is a check nobody has watched fail.
shape_defects() {
  local file="$1" n
  n="$(awk -F'\t' '$1 == "ROW" { c++ } END { print c+0 }' "$file")"
  [ "$n" -eq "$ROWS_EXPECTED" ] || printf 'ROWCOUNT %s rows, expected %s\n' "$n" "$ROWS_EXPECTED"

  awk -F'\t' '$1 == "ROW" && NF != 10 { printf "FIELDCOUNT %s has %s field(s)\n", $2, NF }' "$file"
  awk -F'\t' '$1 == "ROW" && $10 == "" { printf "EMPTYVERDICT %s\n", $2 }' "$file"
  awk -F'\t' -v v="$VERDICTS" '
    BEGIN { split(v, a, " "); for (i in a) good[a[i]] = 1 }
    $1 == "ROW" && $10 != "" && !($10 in good) { printf "BADVERDICT %s = %s\n", $2, $10 }' "$file"

  # The verdict has to agree with which of the two list fields are populated.
  # This is what keeps field 10 from being a free-text cell.
  awk -F'\t' '
    $1 != "ROW" { next }
    {
      want = ($8 != "" && $9 != "") ? "both" :
             ($8 != "") ? "drill-only" :
             ($9 != "") ? "reading-only" : "neither"
      if ($10 != want) printf "DISAGREE %s says %s, fields 8 and 9 say %s\n", $2, $10, want
    }' "$file"

  # Every slug named has to be an item directory that exists.
  awk -F'\t' '$1 == "ROW" { print $8 "," $9 }' "$file" \
    | tr ',' '\n' | sort -u | sed '/^$/d' > "$WORK/slugs-claimed"
  comm -23 "$WORK/slugs-claimed" "$WORK/slugs-real" | sed 's/^/PHANTOMSLUG /'
}

live="$(shape_defects "$INVENTORY")"
if [ -z "$live" ]; then
  ok "$ROWS_EXPECTED rows, 10 fields each, a verdict on every one, every slug real"
else
  bad "the live inventory has $(lines "$live") shape defect(s):"
  indent "$live"
fi

echo
echo "part 1b: controls on the shape check"

# `shape_ctl <code> <label> <awk-program>` writes a broken copy, runs the shape
# check over it, and requires the named defect code to come back.
shape_ctl() {
  local code="$1" label="$2" prog="$3" out
  awk -F'\t' -v OFS='\t' "$prog" "$INVENTORY" > "$WORK/broken"
  out="$(shape_defects "$WORK/broken")"
  if grep -qE "^${code} " <<<"$out"; then
    ctl_ok "$label"
  else
    ctl_bad "$label"
  fi
}

# The six controls sit in a function so one directive covers all of them. The
# single quotes are load-bearing: every program's `$1`, `$9` and `$10` are awk
# field references and must not reach awk already expanded by the shell.
# shellcheck disable=SC2016
shape_controls() {
  shape_ctl EMPTYVERDICT "an empty field 10, the shape the file carried on all 105 rows" \
    '$1 == "ROW" && $2 == "K001" { $10 = "" } { print }'
  shape_ctl BADVERDICT "a field 10 reading 'covered', which is not one of the four verdicts" \
    '$1 == "ROW" && $2 == "K001" { $10 = "covered" } { print }'
  shape_ctl DISAGREE "a verdict of 'neither' on a row whose field 8 names two items" \
    '$1 == "ROW" && $2 == "K001" { $10 = "neither" } { print }'
  shape_ctl PHANTOMSLUG "a field 9 naming an item directory that does not exist" \
    '$1 == "ROW" && $2 == "K001" { $9 = "99-no-such-item" } { print }'
  shape_ctl FIELDCOUNT "a row cut back to the old eight fields" \
    '$1 == "ROW" && $2 == "K001" { print $1, $2, $3, $4, $5, $6, $7, $8; next } { print }'
  shape_ctl ROWCOUNT "a row deleted outright" \
    '$1 == "ROW" && $2 == "K001" { next } { print }'
}
shape_controls

# ---------------------------------------------------------------------------
# Part 2: the live file matches the live corpora.
# ---------------------------------------------------------------------------
echo
echo "part 2: the generator reproduces the live file"

if out="$("$GEN" --check 2>&1)"; then
  ok "gen-coverage.sh --check is clean against the real corpora"
else
  bad "gen-coverage.sh --check reports drift. Regenerate with bash scripts/gen-coverage.sh"
  indent "$out"
fi

# ---------------------------------------------------------------------------
# The mirror. Metadata only, so a mutation is cheap and the real tree is never
# touched.
# ---------------------------------------------------------------------------
build_mirror() {
  local dest="$1"
  local rel d
  rm -rf "$dest"
  mkdir -p "$dest/drill" "$dest/reading"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    rel="${f#"$REPO_ROOT"/}"
    d="$dest/${rel%/*}"
    mkdir -p "$d"
    cp "$f" "$d/"
  done < <(find "$REPO_ROOT/drill" -mindepth 3 -maxdepth 3 -type f -name META.md \
             ! -path "$REPO_ROOT/drill/.*" ! -path "$REPO_ROOT/drill/*/.*")
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    rel="${f#"$REPO_ROOT"/}"
    d="$dest/${rel%/*}"
    mkdir -p "$d"
    cp "$f" "$d/"
  done < <(find "$REPO_ROOT/reading" -mindepth 3 -maxdepth 3 -type f -name USES.md \
             ! -path "$REPO_ROOT/reading/.*" ! -path "$REPO_ROOT/reading/*/.*")
  cp "$INVENTORY" "$dest/drill/INVENTORY.md"
}

# Runs the generator against a mirror and leaves its exit code in $GEN_RC and
# its combined output in $GEN_OUT.
#
# IT SETS GLOBALS AND RETURNS NOTHING ON STDOUT, on purpose. The first version
# echoed the rc so a caller could write `rc="$(run_gen ...)"`, and that call
# form is a SUBSHELL: GEN_OUT assigned inside it never reached the caller. Two
# checks then read a GEN_OUT left over from the previous control and reported
# the wrong verdict, one of them in the passing direction. drill-gate.sh's
# inv_index carries a note about the same trap.
GEN_OUT=""
GEN_RC=0
run_gen() {
  local dest="$1" mode="$2"
  GEN_RC=0
  GEN_OUT="$("$GEN" "$mode" \
    --inventory "$dest/drill/INVENTORY.md" \
    --drill "$dest/drill" \
    --reading "$dest/reading" 2>&1)" || GEN_RC=$?
}

build_mirror "$WORK/base"

echo
echo "part 2b: the mirror is a faithful copy"

n_meta="$(find "$WORK/base/drill" -name META.md -type f | sed -n '$=')"
n_uses="$(find "$WORK/base/reading" -name USES.md -type f | sed -n '$=')"
if [ "${n_meta:-0}" -eq 64 ] && [ "${n_uses:-0}" -eq 25 ]; then
  ok "the mirror holds 64 META.md and 25 USES.md"
else
  bad "the mirror holds ${n_meta:-0} META.md and ${n_uses:-0} USES.md, expected 64 and 25"
fi

run_gen "$WORK/base" --check
rc="$GEN_RC"
if [ "$rc" = "0" ]; then
  ok "--check is clean against the unmutated mirror"
else
  bad "--check reddens on the unmutated mirror, so every control below is meaningless"
  indent "$GEN_OUT"
fi

# ---------------------------------------------------------------------------
# Part 3: controls on the inventory itself.
# ---------------------------------------------------------------------------
echo
echo "part 3: controls that corrupt a coverage cell"

# `field <n> <k-id> <file>` echoes that row's field n.
field() {
  awk -F'\t' -v want="$2" -v n="$1" '$1 == "ROW" && $2 == want { print $n }' "$3"
}

# `poke <k-id> <field-n> <value> <file>` rewrites one cell in place.
poke() {
  local id="$1" n="$2" val="$3" file="$4"
  awk -F'\t' -v OFS='\t' -v id="$id" -v n="$n" -v val="$val" '
    $1 == "ROW" && $2 == id { $n = val; print; next }
    { print }' "$file" > "$file.poked"
  mv "$file.poked" "$file"
}

# 3a. A verdict that disagrees with its own item lists.
cp -r "$WORK/base" "$WORK/c3a"
poke K001 10 neither "$WORK/c3a/drill/INVENTORY.md"
run_gen "$WORK/c3a" --check
rc="$GEN_RC"
if [ "$rc" != "0" ]; then ctl_ok "K001 field 10 flipped to 'neither'"; else
  ctl_bad "K001 field 10 flipped to 'neither'"; fi

# 3b. An empty field 10, the exact shape the old file had on all 105 rows.
cp -r "$WORK/base" "$WORK/c3b"
poke K001 10 "" "$WORK/c3b/drill/INVENTORY.md"
run_gen "$WORK/c3b" --check
rc="$GEN_RC"
if [ "$rc" != "0" ]; then ctl_ok "K001 field 10 emptied"; else
  ctl_bad "K001 field 10 emptied"; fi

# 3c. Field 8 naming an item that does not declare the construct.
cp -r "$WORK/base" "$WORK/c3c"
poke K001 8 "01-nim" "$WORK/c3c/drill/INVENTORY.md"
run_gen "$WORK/c3c" --check
rc="$GEN_RC"
if [ "$rc" != "0" ]; then ctl_ok "K001 field 8 rewritten to a reading slug"; else
  ctl_bad "K001 field 8 rewritten to a reading slug"; fi

# The two controls below rearrange a multi-slug cell, so they need a row with
# at least three slugs. Reported as a skip rather than passing silently if the
# corpus ever shrinks past that.
WIDE_ROW=""
while IFS= read -r id; do
  [ -n "$id" ] || continue
  WIDE_ROW="$id"
  break
done < <(awk -F'\t' '$1 == "ROW" && gsub(/,/, ",", $8) >= 2 { print $2 }' \
           "$WORK/base/drill/INVENTORY.md")

# 3d. One slug dropped from an otherwise correct field 8. This is the control
# that catches a gate comparing set membership instead of the whole cell.
if [ -n "$WIDE_ROW" ]; then
  cp -r "$WORK/base" "$WORK/c3d"
  f8="$(field 8 "$WIDE_ROW" "$WORK/c3d/drill/INVENTORY.md")"
  poke "$WIDE_ROW" 8 "${f8#*,}" "$WORK/c3d/drill/INVENTORY.md"
  run_gen "$WORK/c3d" --check
  rc="$GEN_RC"
  if [ "$rc" != "0" ]; then ctl_ok "one slug dropped from $WIDE_ROW field 8"; else
    ctl_bad "one slug dropped from $WIDE_ROW field 8"; fi
else
  skip "control: no row carries three or more drill slugs, so the drop control cannot run"
fi

# 3e. Two slugs swapped inside field 8. Order is part of the generated form,
# so a reordered cell is drift even though the set is unchanged.
if [ -n "$WIDE_ROW" ]; then
  cp -r "$WORK/base" "$WORK/c3e"
  f8="$(field 8 "$WIDE_ROW" "$WORK/c3e/drill/INVENTORY.md")"
  first="${f8%%,*}"
  rest="${f8#*,}"
  second="${rest%%,*}"
  tail_rest="${rest#*,}"
  poke "$WIDE_ROW" 8 "${second},${first},${tail_rest}" "$WORK/c3e/drill/INVENTORY.md"
  run_gen "$WORK/c3e" --check
  rc="$GEN_RC"
  if [ "$rc" != "0" ]; then ctl_ok "two slugs swapped inside $WIDE_ROW field 8"; else
    ctl_bad "two slugs swapped inside $WIDE_ROW field 8"; fi
else
  skip "control: no row carries three or more drill slugs, so the swap control cannot run"
fi

# 3f. A hand-authored field is left alone. Fields 1 to 7 are not the
# generator's to rewrite, so a change there has to come back unchanged rather
# than being silently normalized away. This one stays clean on purpose, which
# is why it is not phrased as a control.
cp -r "$WORK/base" "$WORK/c3f"
poke K001 6 "medium" "$WORK/c3f/drill/INVENTORY.md"
run_gen "$WORK/c3f" --check
rc="$GEN_RC"
if [ "$rc" = "0" ]; then
  ok "a hand-edited weight in field 6 survives the generator untouched"
else
  bad "the generator rewrote field 6, which it does not own"
  indent "$GEN_OUT"
fi

# ---------------------------------------------------------------------------
# Part 4: controls on the corpora.
# ---------------------------------------------------------------------------
echo
echo "part 4: controls that change what a corpus declares"

# `drop_bullet <file> <text>` removes one construct bullet.
drop_bullet() {
  awk -v want="- $2" '$0 != want { print }' "$1" > "$1.cut"
  mv "$1.cut" "$1"
}

# 4a. A construct bullet deleted from a META.md.
cp -r "$WORK/base" "$WORK/c4a"
drop_bullet "$WORK/c4a/drill/core/01-box-office/META.md" "Operator definition"
run_gen "$WORK/c4a" --check
rc="$GEN_RC"
if [ "$rc" != "0" ]; then ctl_ok "'Operator definition' deleted from core/01-box-office/META.md"; else
  ctl_bad "'Operator definition' deleted from core/01-box-office/META.md"; fi

# 4b. A construct bullet deleted from a USES.md.
cp -r "$WORK/base" "$WORK/c4b"
drop_bullet "$WORK/c4b/reading/core/01-nim/USES.md" "RECURSIVE"
run_gen "$WORK/c4b" --check
rc="$GEN_RC"
if [ "$rc" != "0" ]; then ctl_ok "'RECURSIVE' deleted from reading/core/01-nim/USES.md"; else
  ctl_bad "'RECURSIVE' deleted from reading/core/01-nim/USES.md"; fi

# 4c. A whole item removed. The slug has to leave every cell it was in.
cp -r "$WORK/base" "$WORK/c4c"
rm -rf "$WORK/c4c/reading/core/01-nim"
run_gen "$WORK/c4c" --check
rc="$GEN_RC"
if [ "$rc" != "0" ]; then ctl_ok "reading/core/01-nim removed entirely"; else
  ctl_bad "reading/core/01-nim removed entirely"; fi

# 4d. A misspelled construct name. The generator refuses rather than quietly
# lowering the coverage count, which is the direction that looks like honest
# work. This is the check harness/reading-gate.sh:220-223 says it cannot run.
cp -r "$WORK/base" "$WORK/c4d"
awk '{ sub(/^- RECURSIVE$/, "- Recursive"); print }' \
  "$WORK/c4d/reading/core/01-nim/USES.md" > "$WORK/c4d/u.tmp"
mv "$WORK/c4d/u.tmp" "$WORK/c4d/reading/core/01-nim/USES.md"
run_gen "$WORK/c4d" --check
rc="$GEN_RC"
if [ "$rc" != "0" ] && grep -qF -- 'match no field 4 value' <<<"$GEN_OUT"; then
  ctl_ok "'RECURSIVE' misspelled as 'Recursive' is refused by name, not absorbed"
elif [ "$rc" != "0" ]; then
  ctl_bad "a misspelled name reddened for some other reason than the name"
else
  ctl_bad "'RECURSIVE' misspelled as 'Recursive'"
fi

# 4e. A new construct heading the generator does not read. A bullet moved out
# of a read heading has to count as a deletion, so this control catches a
# flattener that reads any heading at all.
cp -r "$WORK/base" "$WORK/c4e"
awk '
  /^- Operator definition$/ && !done { print "## Constructs the author is still weighing"; done = 1 }
  { print }' \
  "$WORK/c4e/drill/core/01-box-office/META.md" > "$WORK/c4e/m.tmp"
mv "$WORK/c4e/m.tmp" "$WORK/c4e/drill/core/01-box-office/META.md"
run_gen "$WORK/c4e" --check
rc="$GEN_RC"
if [ "$rc" != "0" ]; then ctl_ok "bullets pushed under an unread heading stop counting"; else
  ctl_bad "bullets pushed under an unread heading"; fi

# ---------------------------------------------------------------------------
# Part 5: the heading state does not leak between files.
#
# awk keeps a variable across input files, so a file whose LAST heading is a
# construct heading leaves the next file's front matter being read as
# construct bullets. It is live: all 25 USES.md files end with `## Constructs
# from other families, also exercised`, and the drill corpus carries 299
# front-matter bullets today. The reset is `FNR == 1` in the flattener.
#
# The control plants a front-matter bullet naming a construct the next item
# does not declare. With the reset the bullet is ignored, so --check stays
# clean. Without it the construct is attributed to that item and --check
# reddens, which is the opposite verdict and is how this control works.
# ---------------------------------------------------------------------------
echo
echo "part 5: heading state is reset at every file"

cp -r "$WORK/base" "$WORK/c5"
# 02-chameleons follows 01-nim in sorted order, and 01-nim ends with a
# construct heading. A front-matter bullet in 02-chameleons is therefore
# exactly where a leak would land.
awk '
  NR == 1 { print; print "- LOCAL INSTANCE"; next }
  { print }' \
  "$WORK/c5/reading/core/02-chameleons/USES.md" > "$WORK/c5/u.tmp"
mv "$WORK/c5/u.tmp" "$WORK/c5/reading/core/02-chameleons/USES.md"
run_gen "$WORK/c5" --check
rc="$GEN_RC"
if [ "$rc" = "0" ]; then
  ok "a front-matter bullet after a construct-heading file is not read as a construct"
else
  bad "a front-matter bullet leaked into the previous file's heading state"
  indent "$GEN_OUT"
fi

# The same bullet INSIDE a construct section does have to count, which proves
# the control above is testing the reset rather than a flattener that ignores
# the bullet text wherever it sits.
cp -r "$WORK/base" "$WORK/c5b"
awk '
  /^## Constructs$/ && !done { print; print ""; print "- LOCAL INSTANCE"; done = 1; next }
  { print }' \
  "$WORK/c5b/reading/core/02-chameleons/USES.md" > "$WORK/c5b/u.tmp"
mv "$WORK/c5b/u.tmp" "$WORK/c5b/reading/core/02-chameleons/USES.md"
run_gen "$WORK/c5b" --check
rc="$GEN_RC"
if [ "$rc" != "0" ]; then
  ctl_ok "the same bullet inside a Constructs section does count"
else
  ctl_bad "a bullet added inside a Constructs section"
fi

# ---------------------------------------------------------------------------
# Part 6: the declaration surface is closed.
#
# The generator reads three headings. Everything else in both corpora is
# ignored, and that is only sound if no other heading carries a bullet which
# joins on a field 4 value. Asserted rather than assumed, because a heading
# like `## Operators with no inventory row` is one rename away from looking
# like coverage.
# ---------------------------------------------------------------------------
echo
echo "part 6: no unread heading carries a construct name"

# A copy of the generator's flattener with the heading test inverted, so this
# scan sees exactly what the generator ignores. The single quotes are
# load-bearing: `$0` is awk's whole record and must not expand in the shell.
# shellcheck disable=SC2016
OTHER_AWK='
FNR == 1 { inblock = 0 }
/^## / {
  hdr = substr($0, 4)
  sub(/[ \t]+$/, "", hdr)
  inblock = (hdr == "Constructs" ||
             hdr == "Constructs exercised" ||
             hdr == "Constructs from other families, also exercised")
  next
}
/^- / {
  if (inblock) next
  b = substr($0, 3)
  gsub(/`/, "", b)
  sub(/^[ \t]+/, "", b)
  sub(/[ \t]+$/, "", b)
  if (b != "") print b
}
'
declare -a ALLMETA=()
while IFS= read -r f; do
  [ -n "$f" ] || continue
  ALLMETA+=("$f")
done < <(find "$WORK/base/drill" "$WORK/base/reading" -mindepth 3 -maxdepth 3 -type f \
           \( -name META.md -o -name USES.md \) | sort)

awk -F'\t' '$1 == "ROW" { print $4 }' "$INVENTORY" | sort -u > "$WORK/field4"
if [ "${#ALLMETA[@]}" -gt 0 ]; then
  awk "$OTHER_AWK" "${ALLMETA[@]}" | sort -u > "$WORK/other-bullets"
else
  : > "$WORK/other-bullets"
fi
n_other="$(sed -n '$=' "$WORK/other-bullets")"
leak="$(comm -12 "$WORK/other-bullets" "$WORK/field4")"
if [ -z "$leak" ]; then
  ok "${n_other:-0} bullet(s) under unread headings, none naming an inventory construct"
else
  bad "a bullet under an unread heading names an inventory construct, so coverage is being lost:"
  indent "$leak"
fi

# The control. A construct name planted under `## Operators with no inventory
# row` has to be found, or the scan above is reporting a clean surface it never
# looked at.
cp -r "$WORK/base" "$WORK/c6"
awk '
  /^## Operators with no inventory row$/ && !done { print; print ""; print "- CHOOSE"; done = 1; next }
  { print }' \
  "$WORK/c6/drill/sequences/01-triage-board/META.md" > "$WORK/c6/m.tmp"
mv "$WORK/c6/m.tmp" "$WORK/c6/drill/sequences/01-triage-board/META.md"
declare -a C6META=()
while IFS= read -r f; do
  [ -n "$f" ] || continue
  C6META+=("$f")
done < <(find "$WORK/c6/drill" "$WORK/c6/reading" -mindepth 3 -maxdepth 3 -type f \
           \( -name META.md -o -name USES.md \) | sort)
awk "$OTHER_AWK" "${C6META[@]}" | sort -u > "$WORK/c6-bullets"
if [ -n "$(comm -12 "$WORK/c6-bullets" "$WORK/field4")" ]; then
  ctl_ok "'CHOOSE' planted under 'Operators with no inventory row'"
else
  ctl_bad "'CHOOSE' planted under 'Operators with no inventory row'"
fi

# ---------------------------------------------------------------------------
# Part 7: the generator survives a checkout path holding a dot directory.
#
# An unanchored `! -path '*/.*'` in the file sweep matched the worktree's own
# `.claude/worktrees/agent-*` and excluded all 64 drill items. The run came
# back rc 0 with every row reading "neither", which is a plausible wrong
# answer rather than a crash, so nothing but a control catches it.
# ---------------------------------------------------------------------------
echo
echo "part 7: a dot directory in the path does not hide the corpora"

mkdir -p "$WORK/.hidden"
cp -r "$WORK/base" "$WORK/.hidden/tree"
run_gen "$WORK/.hidden/tree" --check
rc="$GEN_RC"
if [ "$rc" = "0" ]; then
  ok "--check is clean with the corpora under a dot directory"
else
  bad "a dot directory in the path changed the generator's answer"
  indent "$GEN_OUT"
fi

# STRIP THE COVERAGE FIRST. Reading the copied inventory back would pass
# whether or not the sweep found anything, since the copy already carries the
# answer. Cutting every ROW line back to seven fields forces the run to
# rebuild the coverage from the corpora, which is the thing being measured.
cp -r "$WORK/base" "$WORK/.hidden/bare"
awk -F'\t' -v OFS='\t' '
  $1 == "ROW" { print $1, $2, $3, $4, $5, $6, $7; next }
  { print }' "$WORK/.hidden/bare/drill/INVENTORY.md" > "$WORK/stripped"
mv "$WORK/stripped" "$WORK/.hidden/bare/drill/INVENTORY.md"

run_gen "$WORK/.hidden/bare" --stdout
rc="$GEN_RC"
nonneither="$(awk -F'\t' '$1 == "ROW" && $10 != "neither" { n++ } END { print n+0 }' \
  <<<"$GEN_OUT")"
if [ "$rc" = "0" ] && [ "$nonneither" -gt 0 ]; then
  ok "$nonneither row(s) rebuilt from a stripped inventory under a dot directory"
else
  bad "a stripped inventory under a dot directory rebuilt $nonneither reached row(s), rc $rc"
fi

printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
