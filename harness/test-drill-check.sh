#!/usr/bin/env bash
# test-drill-check.sh: the gate for drill/study/check, the objective half of
# the study loop.
#
# WHAT check IS FOR, in one sentence, because every assertion below is an
# assertion about that sentence: it answers whether the model Frank wrote
# reaches a distinct-state count the prompt publishes, and it answers nothing
# else. The judgment half (is this the right model, did it reach the number
# for the right reason) belongs to a session, which bead tla-ytv2 splits out
# on purpose and tla-ytv2.3 builds.
#
# THE DEFECT THIS EXISTS TO STOP has two shapes and they pull opposite ways.
#
#   A FALSE PASS tells Frank a wrong model is right. The one I'd watch is the
#   invented zero: a prompt with no count claim, read as a claim of 0, matched
#   by a run that printed nothing. So the no-claim case is asserted from both
#   ends, exit 2 and no number anywhere in the output.
#
#   A FALSE FAIL tells Frank a right model is wrong, and I think that's the
#   worse of the two on a drill loop, because the drill's whole point is
#   immediate feedback on a retrieval attempt. The parser shapes below are
#   each in the corpus, and each one check cannot read is a drill that reports
#   a mismatch at a correct model.
#
# THE RC DOES NOT PREDICT THE COUNT, which is the measured fact this suite
# exists to keep true. Part 2 runs a module that violates its invariant: rc 12
# with a count printed anyway. drill/state-space/05-summary-record's G05Record
# does the same at rc 75, measured 2026-10-15 on TLC2 2026.07.31.184830. A
# parser that reads the count only when the rc is 0 passes every other
# assertion in this file.
#
# PART 1  resolution, usage, and the ways to exit 3, with no TLC
# PART 2  the comparison itself, against real TLC runs
# PART 3  which modules get run, and which leavings get skipped
#
# Usage:  harness/test-drill-check.sh
# Exit:   0 if all assertions hold, 1 otherwise, 2 on a usage error or a
#         fixture this suite cannot trust.
#
# ---------------------------------------------------------------------------
# IT NEVER TOUCHES ~/tla-practice OR ~/Study. Both hold the only copy of work
# Frank did by hand and neither has an offsite copy, so every path below is
# under one mktemp -d and both roots are passed in by environment variable. A
# suite that read the real corpus would also be asserting against a tree that
# changes under it, which is the other half of why the fixtures are built
# here.
#
# WHY SLOW TIER. Ten real TLC runs. By the rule in scripts/test's header the
# boundary is the model checker, not the JVM, so this is slow whatever it
# costs today. Its cost tracks the fixture count in parts 2 and 3 and nothing
# about the real corpus, so it won't drift as drills land.
# ---------------------------------------------------------------------------

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

CHECK="${REPO_ROOT}/drill/study/check"

case "${1:-}" in
  "") ;;
  -h|--help)
    # Print the header block, stopping at the first line of code, the same way
    # scripts/test --help does rather than at a line number that drifts.
    awk 'NR > 1 && /^set -uo pipefail$/ { exit } NR > 1' "${BASH_SOURCE[0]}"
    exit 0
    ;;
  *)
    echo "test-drill-check.sh: unknown option '$1' (try --help)" >&2
    exit 2
    ;;
esac
if [ "$#" -gt 1 ]; then
  echo "test-drill-check.sh: takes at most one option, got $# ($*)" >&2
  exit 2
fi

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

if [ ! -x "$CHECK" ]; then
  echo "test-drill-check.sh: ${CHECK} is missing or not executable, so this suite refuses to report success." >&2
  exit 2
fi

if ! command -v tlc >/dev/null 2>&1; then
  echo "test-drill-check.sh: tlc is not on the path, and parts 2 and 3 are the whole point." >&2
  exit 2
fi

TMP="$(mktemp -d)"
# shellcheck disable=SC2317  # reached through the EXIT trap on the next line
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

PROMPTS="${TMP}/prompts"
WORK="${TMP}/work"
mkdir -p "$PROMPTS/fam-a" "$PROMPTS/fam-b" "$WORK"

OUT=""
RC=0

# run_check <args...>: the ordinary invocation, with both roots pointed at the
# fixture tree. Output is captured combined, because the exit-3 messages go to
# stderr and this suite asserts on them.
run_check() {
  OUT="$(DRILL_PROMPT_ROOT="$PROMPTS" DRILL_STUDY_ROOT="$WORK" "$CHECK" "$@" 2>&1)"
  RC=$?
}

# run_check_in <dir>: the no-argument form, from inside <dir>, which is how
# the slug gets resolved when Frank is sitting in the directory.
run_check_in() {
  OUT="$(cd "$1" && DRILL_PROMPT_ROOT="$PROMPTS" DRILL_STUDY_ROOT="$WORK" "$CHECK" 2>&1)"
  RC=$?
}

# NO_TLC_PATH: the real PATH with EVERY directory holding a tlc taken out of
# it, and nothing else changed.
#
# Two earlier shapes were wrong and both are worth recording, because each one
# failed in a direction that reads as somebody else's bug.
#
# A hardcoded /usr/bin:/bin died at rc 127 with `env: 'bash': No such file or
# directory`. This is NixOS and bash lives in /run/current-system/sw/bin, so a
# broken fixture reported as a broken implementation.
#
# Dropping only the directory `command -v tlc` resolves to left a tlc
# standing: this box has two, the pinned wrapper in ~/bin and a nix-profile
# TLC2 2.19 of 08 August 2024 in /etc/profiles/per-user/<user>/bin. That one
# is four releases behind the project's pin and would have run the fixture
# anyway. The control below is what caught it.
strip_tlc_from_path() {
  local part out=""
  while IFS= read -r part; do
    [ -n "$part" ] || continue
    [ -x "${part}/tlc" ] && continue
    out="${out:+${out}:}${part}"
  done < <(tr ':' '\n' <<<"$PATH")
  printf '%s\n' "$out"
}
NO_TLC_PATH="$(strip_tlc_from_path)"

# run_check_without_tlc <args...>: the same run with tlc off the path.
run_check_without_tlc() {
  OUT="$(DRILL_PROMPT_ROOT="$PROMPTS" DRILL_STUDY_ROOT="$WORK" PATH="$NO_TLC_PATH" "$CHECK" "$@" 2>&1)"
  RC=$?
}

# Assertions read OUT through a HERE-STRING, never a pipe. A pipe into
# `grep -q` returns 141 under pipefail, which inside an `if` reads as "pattern
# absent", so a present finding would report as missing and a control would
# pass on a broken instrument. harness/test-pipefail.sh bans the idiom
# outright (bead tla-kr9).
has() {
  if grep -qF -- "$2" <<<"$OUT"; then ok "$1"; else nope "$1 (expected in output: $2)"; fi
}
hasnt() {
  if grep -qF -- "$2" <<<"$OUT"; then nope "$1 (must NOT be in output: $2)"; else ok "$1"; fi
}
rc_is() {
  if [ "$RC" = "$2" ]; then ok "$1"; else nope "$1 (rc=${RC}, want $2. output: ${OUT})"; fi
}
lines_matching() {
  local n
  n="$(grep -cE -- "$3" <<<"$OUT")"
  if [ "$n" = "$2" ]; then ok "$1"; else nope "$1 ($n lines match '$3', want $2. output: ${OUT})"; fi
}
# no_number_but_the_slug <label> <slug>: the slug carries digits of its own
# (every real one begins with two), so "prints no number" has to be asked with
# the slug removed first. A plain digit scan would fail on 03-no-claim's own
# name and say nothing about an invented count.
no_number_but_the_slug() {
  local stripped="${OUT//$2/}"
  if grep -qE '[0-9]' <<<"$stripped"; then
    nope "$1 (a number survives with the slug removed: ${stripped})"
  else
    ok "$1"
  fi
}

# ===========================================================================
# FIXTURE BUILDERS
#
# Every module below was MEASURED on TLC2 2026.07.31.184830 before it was
# written down, and the measurement sits in the comment beside it. A fixture
# whose expected count was reasoned out rather than run is a fixture that can
# make this suite agree with a wrong parser.
# ===========================================================================

# mk_six <dir> [<basename>]: six distinct states, rc 0. Measured.
mk_six() {
  local d="$1" name="${2:-Six}"
  mkdir -p "$d"
  cat >"${d}/${name}.tla" <<TLA
---- MODULE ${name} ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 5 /\\ x' = x + 1
Spec == Init /\\ [][Next]_x
TypeOK == x \\in 0..5
====
TLA
  cat >"${d}/${name}.cfg" <<'CFG'
SPECIFICATION Spec
INVARIANT TypeOK
CHECK_DEADLOCK FALSE
CFG
}

# mk_eight <dir> [<basename>]: eight distinct states, rc 0. Measured.
mk_eight() {
  local d="$1" name="${2:-Eight}"
  mkdir -p "$d"
  cat >"${d}/${name}.tla" <<TLA
---- MODULE ${name} ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 7 /\\ x' = x + 1
Spec == Init /\\ [][Next]_x
TypeOK == x \\in 0..7
====
TLA
  cat >"${d}/${name}.cfg" <<'CFG'
SPECIFICATION Spec
INVARIANT TypeOK
CHECK_DEADLOCK FALSE
CFG
}

# mk_viol <dir>: an invariant violation at four distinct states. Measured
# rc 12 WITH `4 distinct states found` in the log, which is the whole point of
# the fixture: the rc says failure and the count is there anyway.
mk_viol() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/Viol.tla" <<'TLA'
---- MODULE Viol ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 5 /\ x' = x + 1
Spec == Init /\ [][Next]_x
Small == x < 3
====
TLA
  cat >"${d}/Viol.cfg" <<'CFG'
SPECIFICATION Spec
INVARIANT Small
CHECK_DEADLOCK FALSE
CFG
}

# mk_broken <dir>: a module TLC cannot parse. Measured rc 150 with NO count
# printed anywhere in the log.
mk_broken() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/Broken.tla" <<'TLA'
---- MODULE Broken ----
EXTENDS Naturals
VARIABLE x
Init == x =
Next == x' = x + 1
====
TLA
  cat >"${d}/Broken.cfg" <<'CFG'
INIT Init
NEXT Next
CFG
}

# mk_prompt <family> <slug>, body on stdin.
mk_prompt() {
  mkdir -p "${PROMPTS}/${1}/${2}"
  cat >"${PROMPTS}/${1}/${2}/PROMPT.md"
}

# ---------------------------------------------------------------------------
# The prompts. Each body is the shape it names, taken from the real corpus
# rather than invented, so a parser that passes here reads the real thing.
# ---------------------------------------------------------------------------

# THE PLAIN PROSE CLAIM. 25 of the 43 claim-bearing prompts are this shape,
# e.g. drill/sequences/07-pneumatic-tube/PROMPT.md:12.
mk_prompt fam-a 01-six <<'MD'
# Six

Write the specification from an empty file, and run it.
Check it with a ceiling of 5. A correct model finds 6 distinct states
and reports no error.
MD

# The same shape, against a model that reaches a different number.
mk_prompt fam-a 02-eight-wanted <<'MD'
# Eight wanted

Write the specification from an empty file, and run it.
A correct model finds 6 distinct states.
MD

# NO CLAIM. Taken from drill/control-state/02-pumps/PROMPT.md:23, which asks
# for the count rather than publishing one. Four control-state prompts end
# this way, and reading the request as a claim is how a zero gets invented.
mk_prompt fam-a 03-no-claim <<'MD'
# No claim

Write the specification and both rules from an empty file, and run it.
Report the verdict and the number of distinct states.
MD

# A claim, against a directory full of TLC leavings.
mk_prompt fam-a 04-leavings <<'MD'
# Leavings

Check it. A correct model finds 6 distinct states.
MD

# THE TABLE SHAPE. 18 prompts publish their counts in a `| distinct states |`
# column, all eight of modules/ and all eight of state-space/ among them. The
# blank cells are in the real corpus too (a refused run has no count), and one
# row carries the comma grouping that state-space/01 writes as `3,531`.
#
# EVERY OTHER COLUMN HERE HOLDS NUMBERS TOO, and they hold different ones from
# the counts on purpose. drill/state-space/08's first column is a doctor count
# and every table in both families carries a depth, so a parser that reads the
# row rather than the column passes nothing below.
mk_prompt fam-a 05-table <<'MD'
# Table

## What happened

| workers | verdict | distinct states | depth |
|---|---|---|---|
| 1 | clean | 3 | 2 |
| 2 | clean | 6 | 5 |
| 3 | clean | 9 | 8 |
| 4 | refused | | |
| 5 | killed | 1,024 | 70 |

Reproduce the 6, then break it.
MD

# TWO COUNTS AT TWO MODEL SIZES, the continuation shape. Taken from
# drill/functions-records/08-troughs/PROMPT.md:15, and
# drill/state-space/08-the-database-you-did-not-need/PROMPT.md:22 runs it out
# to four sizes. Reading only the first count reports a mismatch at a correct
# model run at the other size.
mk_prompt fam-a 06-two-sizes <<'MD'
# Two sizes

The model stops when it is done, which is intended, so check it with
deadlock checking off. A correct model finds 3 distinct states with two
tanks and 6 with three, and reports no error at either.
MD

# A claim, against a module TLC cannot parse.
mk_prompt fam-a 07-unparsable <<'MD'
# Unparsable

Check it. A correct model finds 6 distinct states.
MD

# A claim, against a model that violates its invariant at the claimed count.
mk_prompt fam-a 08-violation <<'MD'
# Violation

Check it. A correct model finds 4 distinct states.
MD

# THE DUPLICATE SLUG, which is a corpus bug and not a choice to make. All 64
# real slugs are distinct across the eight families (measured 2026-10-15), so
# two hits means the tree is wrong.
mk_prompt fam-a 09-duplicate <<'MD'
# Duplicate, in fam-a

Check it. A correct model finds 6 distinct states.
MD
mk_prompt fam-b 09-duplicate <<'MD'
# Duplicate, in fam-b

Check it. A correct model finds 9 distinct states.
MD

mk_prompt fam-a 10-no-cfg <<'MD'
# No config

Check it. A correct model finds 6 distinct states.
MD

mk_prompt fam-a 11-variants <<'MD'
# Variants

Check it. A correct model finds 6 distinct states.
MD

mk_prompt fam-a 12-empty <<'MD'
# Empty

Check it. A correct model finds 6 distinct states.
MD

mk_prompt fam-a 13-no-dir <<'MD'
# No study directory

Check it. A correct model finds 6 distinct states.
MD

# THE TWO DEFAULTS, asserted against a fixture HOME rather than taken on
# trust. Both roots are documented defaults ($HOME/tla-practice/drill and
# $HOME/Study/tla-drills), and nothing else in this suite drives them,
# because every other row passes both roots in. A default that drifted would
# otherwise only ever be found by Frank, on the one tree that has no copy.
#
# This redirection has to happen INSIDE a script. Setting HOME on a command
# line is refused by the worktree-isolation harness, which reads it as
# injecting git configuration (measured by a sibling worker, 2026-10-14).
#
# THE FIXTURE HOME NEEDS A lib/tla2tools.jar, and that cost a false red
# before it was there. The pinned tlc wrapper scripts/setup writes resolves
# its jar from $HOME too, so a redirected HOME takes TLC out with
# `Could not find or load main class tlc2.TLC` at rc 1 and no count in the
# log. check reported that honestly as distinct=none, which is right, and the
# row read as a parser bug. The symlink puts the real jar back.
mkdir -p "${TMP}/home/tla-practice/drill/fam-a/14-default" "${TMP}/home/lib"
ln -s "${HOME}/lib/tla2tools.jar" "${TMP}/home/lib/tla2tools.jar"
cat >"${TMP}/home/tla-practice/drill/fam-a/14-default/PROMPT.md" <<'MD'
# Default roots

Check it. A correct model finds 6 distinct states.
MD
mk_six "${TMP}/home/Study/tla-drills/14-default"

# ---------------------------------------------------------------------------
# The study directories. 13-no-dir deliberately has none.
# ---------------------------------------------------------------------------

mk_six    "${WORK}/01-six"
mk_eight  "${WORK}/02-eight-wanted"
mk_six    "${WORK}/03-no-claim"
mk_six    "${WORK}/05-table"
mk_six    "${WORK}/06-two-sizes"
mk_broken "${WORK}/07-unparsable"
mk_viol   "${WORK}/08-violation"
mk_six    "${WORK}/09-duplicate"
mkdir -p  "${WORK}/12-empty"

# 04-leavings: one real pair, plus every kind of leaving Frank's own study
# directory holds. Measured in /home/fkberthold/Study/tla-drills/
# 01-slip-on-the-spike on 2026-10-15: pickers.tla + pickers.cfg,
# pickers_collision.tla with no config, pickers_TTrace_1792021269.tla, and a
# states/ directory. The *.old entry is pcal's, named by that tree's own
# .gitignore.
mk_six   "${WORK}/04-leavings"
mk_eight "${WORK}/04-leavings" "Six_TTrace_1792021269"
cp "${WORK}/04-leavings/Six.tla" "${WORK}/04-leavings/Six.tla.old"
mk_eight "${WORK}/04-leavings/states/Six_17_01" "Deep"

# 10-no-cfg: a module with no config of its own name, which is the shape
# pickers_collision.tla has. On its own it leaves nothing to run.
mkdir -p "${WORK}/10-no-cfg"
cp "${WORK}/01-six/Six.tla" "${WORK}/10-no-cfg/Lone.tla"

# 11-variants: two qualifying pairs side by side, plus a third module with no
# config. Frank keeps variants this way, so check runs each and reports each.
mk_six   "${WORK}/11-variants"
mk_eight "${WORK}/11-variants"
cp "${WORK}/01-six/Six.tla" "${WORK}/11-variants/Lone.tla"

# ===========================================================================
echo "== part 1: resolution, usage, and the ways to exit 3 =="
# ===========================================================================

run_check 01-six 02-eight-wanted
rc_is "two arguments is a usage error" 3
has   "the usage error names the interface" "check [<slug-or-dir>]"

run_check 99-absent
rc_is "a slug with no prompt is rc 3" 3
has   "the no-prompt message names the slug" "99-absent"

OUT="$(DRILL_PROMPT_ROOT="${TMP}/not-a-root" DRILL_STUDY_ROOT="$WORK" "$CHECK" 01-six 2>&1)"
RC=$?
rc_is "a prompt root that does not exist is rc 3" 3
has   "and the message names the root it looked under" "${TMP}/not-a-root"

run_check 09-duplicate
rc_is "a slug matching two prompts is rc 3" 3
has   "the duplicate message calls it a corpus bug" "corpus bug"
has   "and names the first hit"  "fam-a/09-duplicate/PROMPT.md"
has   "and names the second hit" "fam-b/09-duplicate/PROMPT.md"
hasnt "and nothing was run" "distinct="

run_check 13-no-dir
rc_is "a slug with no study directory is rc 3" 3
has   "and the message names the directory it wanted" "${WORK}/13-no-dir"

run_check 10-no-cfg
rc_is "a module with no config of its own name leaves nothing to run, rc 3" 3
has   "and the message says so" "no module"

run_check 12-empty
rc_is "an empty study directory is rc 3" 3

# The control for the next rows: the fixture PATH must really have no tlc on
# it, or they prove nothing. It must still carry bash, or they fail for the
# wrong reason.
if PATH="$NO_TLC_PATH" command -v tlc >/dev/null 2>&1; then
  nope "FIXTURE: the stripped PATH still carries a tlc, so the absent-tlc rows are void"
else
  ok "fixture control: the stripped PATH carries no tlc"
fi
if PATH="$NO_TLC_PATH" command -v bash >/dev/null 2>&1; then
  ok "fixture control: the stripped PATH still carries bash"
else
  nope "FIXTURE: the stripped PATH lost bash, so the absent-tlc rows fail at the shebang"
fi

run_check_without_tlc 01-six
rc_is "an absent tlc is rc 3, never a silent pass" 3
has   "and the message names tlc" "tlc"
hasnt "and nothing is reported as matched" "MATCH"

# THE NO-CLAIM CASE, from both ends. Exit 2, the word UNCHECKED, and no number
# of any kind: not a claimed 0, not a distinct 0, not a count field at all.
run_check 03-no-claim
rc_is "a prompt with no count claim is rc 2" 2
has   "and says UNCHECKED" "UNCHECKED"
has   "and names the slug" "03-no-claim"
hasnt "and invents no claim field" "claimed="
hasnt "and invents no count field" "distinct="
hasnt "and reports no match" "MATCH"
no_number_but_the_slug "and invents no number at all" "03-no-claim"
lines_matching "one verdict line and nothing else" 1 '.'

# UNCHECKED is decided by the prompt alone, so it needs no tlc. This pins the
# order: the claim scan happens before the toolchain check.
run_check_without_tlc 03-no-claim
rc_is "no claim and no tlc is still rc 2" 2
has   "and still says UNCHECKED" "UNCHECKED"

# ===========================================================================
echo "== part 2: the comparison, against real TLC runs =="
# ===========================================================================

# The no-argument form, which is how Frank runs it: from in the directory.
run_check_in "${WORK}/01-six"
rc_is "a model that reaches the claimed count is rc 0" 0
has   "the line names the module" "module=Six"
has   "the line carries TLC's rc" "rc=0"
has   "the line carries the count TLC printed" "distinct=6"
has   "the line carries the count the prompt claimed" "claimed=6"
has   "and calls it a match" "MATCH"
hasnt "and calls it nothing else" "MISMATCH"
has   "the verdict line names the slug" "01-six"
lines_matching "one module line" 1 '^module='
lines_matching "one verdict line" 1 '^(MATCHED|MISMATCHED|UNCHECKED):'

run_check 02-eight-wanted
rc_is "a model that reaches a different count is rc 1" 1
has   "the count TLC printed is there" "distinct=8"
has   "the count the prompt claimed is there" "claimed=6"
has   "and it is called a mismatch" "MISMATCH"

# The explicit-directory form.
run_check "${WORK}/05-table"
rc_is "a count published in a table matches, rc 0" 0
has   "every count in the column is claimed, comma grouping and all" "claimed=3,6,9,1024"
has   "and the printed count is TLC's" "distinct=6"
has   "and it is a match" "MATCH"

run_check 06-two-sizes
rc_is "the second of two counts at two model sizes matches, rc 0" 0
has   "both published counts are claimed" "claimed=3,6"
has   "and the printed count is TLC's" "distinct=6"

run_check 07-unparsable
rc_is "a module TLC cannot parse is rc 1" 1
has   "and the count reads none rather than zero" "distinct=none"
hasnt "and no zero is invented" "distinct=0"
has   "and it is a mismatch" "MISMATCH"

# THE DEFAULT ROOTS, with neither environment variable set. The control first:
# a fixture home with no jar in it fails for the wrong reason, so the symlink
# has to be there.
if [ -r "${TMP}/home/lib/tla2tools.jar" ]; then
  ok "fixture control: the fixture HOME carries a readable tla2tools.jar"
else
  nope "FIXTURE: the fixture HOME has no readable jar, so the default-root rows are void"
fi
OUT="$(env -u DRILL_PROMPT_ROOT -u DRILL_STUDY_ROOT HOME="${TMP}/home" "$CHECK" 14-default 2>&1)"
RC=$?
rc_is "the documented default roots resolve with neither variable set" 0
has   "and the module under the default study root ran" "module=Six"
has   "and the count came from the prompt under the default prompt root" "claimed=6"

# THE ROW THE RC TABLE EXISTS FOR. rc 12, with a count in the log.
run_check 08-violation
rc_is "a count printed at a failing rc still matches, rc 0" 0
has   "TLC's rc is reported as it was" "rc=12"
has   "and the count is read out of the log" "distinct=4"
has   "and it is a match" "MATCH"

# ===========================================================================
echo "== part 3: which modules get run =="
# ===========================================================================

run_check 04-leavings
rc_is "a directory of TLC leavings still checks the one real module, rc 0" 0
has   "the real module ran" "module=Six"
lines_matching "exactly one module line" 1 '^module='
hasnt "a *_TTrace_* module is not run" "TTrace"
hasnt "a module under states/ is not run" "Deep"
hasnt "a *.old leaving is not run" ".old"

run_check 11-variants
rc_is "two variants side by side is rc 1 when one of them misses" 1
lines_matching "both variants are reported" 2 '^module='
has   "the matching variant is named" "module=Six"
has   "the missing variant is named" "module=Eight"
has   "the matching count is printed" "distinct=6"
has   "the missing count is printed" "distinct=8"
hasnt "a module with no config of its own name is skipped" "Lone"
has   "the verdict names the variant that missed" "Eight"

# ===========================================================================
printf '\n'
if [ "$fail_count" -eq 0 ]; then
  printf 'OK: %d assertions passed.\n' "$pass_count"
  exit 0
fi
printf 'FAILED: %d of %d assertions failed.\n' "$fail_count" "$((pass_count + fail_count))" >&2
exit 1
