#!/usr/bin/env bash
# test-drill-check.sh: the gate for drill/study/check, the objective half of
# the study loop.
#
# WHAT check IS FOR, in one sentence, because every assertion below is an
# assertion about that sentence: it reports two independent facts about the
# run, the count dimension and the run verdict, and it judges neither. The
# judgment half (is this the right model, was this the right verdict to want)
# belongs to a session, which bead tla-ytv2 splits out on purpose and
# tla-ytv2.3 builds.
#
# THE TWO DIMENSIONS ARE INDEPENDENT, and bead tla-rzvk.1 is the bead that
# made the second one reportable. The count dimension owns the exit code
# (0 matched, 1 mismatched, 2 no claim to compare, 3 could not run). The run
# dimension owns `run=` and never moves the exit. Part 4 drives the whole
# matrix, and the row that matters most is 18-eval-fail: rc 76 with a count
# that MATCHES, so count=MATCH sits beside run=ERROR on one line and the exit
# is 0. An implementation that folds either dimension into the other fails
# that row and passes almost everything else.
#
# THE DEFECT THIS EXISTS TO STOP has two shapes and they pull opposite ways.
#
#   A FALSE PASS tells Frank a wrong model is right. The one I'd watch is the
#   invented zero: a prompt with no count claim, read as a claim of 0, matched
#   by a run that printed nothing. The no-claim rows assert that from the
#   claim end rather than by counting digits -- claimed=- and count=NONE, with
#   claimed=0 and every count verdict ruled out by name. Before tla-rzvk.1 the
#   same intent was asserted as "no number anywhere in the output", which a
#   no-claim run now carries on purpose, since the whole point of that bead is
#   that TLC runs there too.
#
#   A FALSE FAIL tells Frank a right model is wrong, and I think that's the
#   worse of the two on a drill loop, because the drill's whole point is
#   immediate feedback on a retrieval attempt. The parser shapes below are
#   each in the corpus, and each one check cannot read is a drill that reports
#   a mismatch at a correct model.
#
# A THIRD SHAPE ARRIVED WITH THE RUN VERDICT: a false CLEAN. A log check
# cannot read must never report as a clean run, because CLEAN is the one
# value a session will act on without looking. 20-silent-tlc drives a stub
# that prints neither an error nor a count and asserts run=NOCOUNT, so the
# classifier has to be total rather than optimistic.
#
# A FOURTH SHAPE IS A FALSE PASS NOBODY SEES: a module left out in silence.
# Before bead tla-rzvk.4 a `.tla` with no `.cfg` of its own name was dropped
# with no mention at all. So a two-model drill where Frank kept one config
# reported CLEAN on the model that worked, and said nothing about the one that
# broke. He hit it on 2026-10-14, the first drill he worked: pickers.tla ran,
# pickers_collision.tla did not, and only the first appeared.
#
# ONE CONFIG FOR TWO MODULES IS HIS WORKFLOW, not an oversight, so the fix is
# to run the second model rather than to report it. The two declare the same
# constants and the same invariants, which is what makes one config valid for
# both. Part 5 drives the three conditions that let a module borrow one, and
# the three ways a module falls out of them. The condition I would watch is
# the third: a helper module another module EXTENDS is unpaired too, and
# handing it a config would check a library rather than a spec.
#
# THE CONFIG IS ON EVERY MODULE LINE after this bead, borrowed or not, and
# 21-one-config asserts it on both. Printing it only when it was borrowed
# would leave the fact in a silence, which is the defect above arriving one
# level up.
#
# THE RC DOES NOT PREDICT THE COUNT, which is the measured fact this suite
# exists to keep true. Part 2 runs a module that violates its invariant: rc 12
# with a count printed anyway. drill/state-space/05-summary-record's G05Record
# does the same at rc 75, measured 2026-10-15 on TLC2 2026.07.31.184830. A
# parser that reads the count only when the rc is 0 passes every other
# assertion in this file.
#
# THE RC DOES NOT PREDICT THE VERDICT EITHER, which is the same fact wearing
# the other hat. 17-deadlock is rc 11 and 16-liveness is rc 13, and both are
# violations. 18-eval-fail is rc 76 and is NOT one, because TLC says
# "Evaluating invariant Bad failed" rather than "violated" and nothing is
# known about whether Bad holds. Bead tla-i9m settled that distinction for
# harness/verdict.sh and the assertions below hold check to it.
#
# PART 1  resolution, usage, and the ways to exit 3, with no TLC
# PART 2  the comparison itself, against real TLC runs
# PART 3  which modules get run, and which leavings get skipped
# PART 4  the run verdict, every value of it, and the violating state
# PART 5  whose config a module runs with, and when it does not get one
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
# WHY SLOW TIER. Nearly every fixture here drives a real TLC run, and the stub
# in part 4 is the one that does not. By the rule in scripts/test's header the
# boundary is the model checker, not the JVM, so this is slow whatever it costs
# today. Its cost tracks the fixture count in parts 2 to 5 and nothing about
# the real corpus, so it won't drift as drills land.
#
# The run count used to sit in that first sentence as a number. It read
# "Fourteen" against fifteen actual runs before bead tla-rzvk.4 touched a
# fixture, which is what a hand-counted figure does when nothing gates it.
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
# field_is <label> <field> <value>: assert a WHOLE field of a module line,
# anchored at both ends, which is the only way to ask about these values.
#
# THE SUBSTRING HAZARD IS LIVE IN EXACTLY THE FIELDS tla-rzvk.1 ADDED. A
# grep -F for `count=MATCH` is satisfied by `count=MISMATCH`, so an
# implementation that reports every run as a mismatch passes a suite written
# with `has`. The last round found that with its third RED stub and nothing
# else found it. `run=` repeats the shape: NOCOUNT ends in COUNT, so an
# unanchored test for one is a test for neither. Anchoring on a space or a
# line boundary at both ends asks the question that catches it.
#
# field_isnt is the same anchor negated, and the no-claim rows need it: the
# claim really is absent there, so `hasnt MATCH` would be satisfied by an
# implementation printing count=MISMATCH and the row would prove nothing.
field_is() {
  if grep -qE -- "(^|[[:space:]])$2=$3([[:space:]]|$)" <<<"$OUT"; then
    ok "$1"
  else
    nope "$1 (expected the whole field ${2}=${3}. output: ${OUT})"
  fi
}
field_isnt() {
  if grep -qE -- "(^|[[:space:]])$2=$3([[:space:]]|$)" <<<"$OUT"; then
    nope "$1 (the whole field ${2}=${3} must NOT appear. output: ${OUT})"
  else
    ok "$1"
  fi
}

# not_run_line <label> <module> <reason>: the WHOLE unrun line, anchored at
# both ends, reason included.
#
# THE SUBSTRING HAZARD REACHES THIS LINE FROM A NEW DIRECTION. `grep -F RUN`
# is satisfied by `NOT RUN`, so a suite that asks whether a module ran by
# looking for the word gets a yes from the line that says it did not. Below,
# a run line is counted by `rc=`, which only a run has, and an unrun line is
# matched whole so its reason cannot drift unnoticed.
#
# The reason is part of the contract rather than decoration. "Not run" on its
# own sends Frank looking for a config he already has, and the whole point of
# bead tla-rzvk.4 is that the output stops hiding what it did.
not_run_line() {
  if grep -qE -- "^module=$2 NOT RUN: $3\$" <<<"$OUT"; then
    ok "$1"
  else
    nope "$1 (expected the whole line 'module=$2 NOT RUN: $3'. output: ${OUT})"
  fi
}

# not_run_line_absent <label> <module>: this module was not refused, whatever
# the reason would have been. Asked by name rather than by counting unrun
# lines, so it still means something in a directory holding several modules.
not_run_line_absent() {
  if grep -qE -- "^module=$2 NOT RUN:" <<<"$OUT"; then
    nope "$1 (module=$2 was refused. output: ${OUT})"
  else
    ok "$1"
  fi
}

# state_block_follows <label> <module>: the violating state is an indented
# block under ITS OWN module line, which is what makes it readable when two
# variants run side by side. Asserted as adjacency rather than as presence,
# because a block printed once at the bottom of a two-module run satisfies a
# presence test and tells the reader nothing about which module violated.
state_block_follows() {
  local line want="" seen=0
  while IFS= read -r line; do
    case "$line" in
    "module=$2 "*) want=1 ;;
    'module='*) want="" ;;
    '  State '[0-9]*':'*) [ -n "$want" ] && seen=1 ;;
    esac
  done <<<"$OUT"
  if [ "$seen" = 1 ]; then
    ok "$1"
  else
    nope "$1 (no indented State block under module=$2. output: ${OUT})"
  fi
}

# ---------------------------------------------------------------------------
# PART 6's INSTRUMENT: the directory snapshot. Bead tla-9y5h.
#
# The assertion part 6 makes is an assertion of ABSENCE, and absence goes
# vacuous more easily than anything else in this file. The shape to watch was
# found on this suite's own sibling: a snapshot of a directory that does not
# exist returns one fixed value, and that value compares equal to a second
# snapshot of the same absent directory, so "every file is untouched" reports
# green over a tree nobody ever created.
#
# Two things answer it and both are needed. `dir_tree` makes the absence a
# DISTINGUISHABLE value rather than an empty one, so a snapshot of nothing
# cannot pass for a snapshot of something. And part 6 asserts its before-image
# against the literal three entries it must hold, which proves in one line that
# the directory is there, that it holds the violating model, and that the
# instrument reads it.
# ---------------------------------------------------------------------------

# dir_tree <dir> [<find args>...]: every path under <dir>, relative to it and
# sorted, one per line. An absent directory is reported as absent rather than
# as an empty tree, for the reason above.
dir_tree() {
  local d="$1"
  shift
  if [ ! -d "$d" ]; then
    printf 'ABSENT: %s\n' "$d"
    return 0
  fi
  (cd -- "$d" && find . "$@" | sort)
}

# tree_unchanged <label> <dir> <before> [<find args>...]: <dir> holds exactly
# what <before> says and nothing besides. The whole tree is compared rather
# than a count, because TLC's leavings carry a timestamp in their names and a
# count would be satisfied by a swap.
tree_unchanged() {
  local label="$1" dir="$2" before="$3" now
  shift 3
  now="$(dir_tree "$dir" "$@")"
  if [ "$now" = "$before" ]; then
    ok "$label"
  else
    nope "$label (the directory changed. before:
${before}
after:
${now})"
  fi
}

# tree_lacks <label> <dir> <pattern>: the named half of the same assertion. The
# comparison above catches anything at all, and this says which shape it was,
# so a failure reads as the defect rather than as a diff to decode.
tree_lacks() {
  local tree
  tree="$(dir_tree "$2")"
  if grep -qE -- "$3" <<<"$tree"; then
    nope "$1 (a path matching '$3' is under $2: ${tree})"
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

# mk_live <dir>: a temporal property that does not hold. Measured rc 13 with
# `4 distinct states found`, and the log reads `Error: Temporal property
# Reaches was violated.` -- a THIRD phrasing beside the invariant's `is
# violated` and the implied action's `Action property NeverUp is violated`.
# Three phrasings is why check reads the word rather than the sentence.
#
# Its last trace state is `State 4: Stuttering`, with no body and with TLC's
# next chatter line on the very next line instead of a blank. A block reader
# that stops at a blank line alone swallows that chatter into the state.
mk_live() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/Live.tla" <<'TLA'
---- MODULE Live ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 3 /\ x' = x + 1
Spec == Init /\ [][Next]_x
Reaches == <>(x = 3)
====
TLA
  cat >"${d}/Live.cfg" <<'CFG'
SPECIFICATION Spec
PROPERTY Reaches
CHECK_DEADLOCK FALSE
CFG
}

# mk_dead <dir>: a terminal state with deadlock checking left ON, which is the
# default and what the .cfg here deliberately does not turn off. Measured rc 11
# with `3 distinct states found` and `Error: Deadlock reached.` -- a violation
# with a trace and NO name, which is the only shape that drives invariant=- on
# a violated run.
mk_dead() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/Dead.tla" <<'TLA'
---- MODULE Dead ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 2 /\ x' = x + 1
Spec == Init /\ [][Next]_x
====
TLA
  cat >"${d}/Dead.cfg" <<'CFG'
SPECIFICATION Spec
CFG
}

# mk_evalfail <dir>: an invariant that is not a boolean at every state, so TLC
# gives up evaluating it. Measured rc 76 with `4 distinct states found`, a full
# trace, and `Error: Evaluating invariant Bad failed.`
#
# THIS IS THE ROW THAT KEEPS THE WORD "VIOLATED" HONEST. The log names an
# invariant and prints a trace, so every surface cue says violation, and it is
# not one: bead tla-i9m settled that 76 means the check NEVER HAPPENED, so
# nothing at all is known about whether Bad holds. Telling Frank his invariant
# was violated here would be a false statement about a check that never ran.
# It is also the independence row -- the count is real and matches while the
# run errored.
mk_evalfail() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/Bad.tla" <<'TLA'
---- MODULE Bad ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 5 /\ x' = x + 1
Spec == Init /\ [][Next]_x
Bad == IF x < 3 THEN TRUE ELSE x
====
TLA
  cat >"${d}/Bad.cfg" <<'CFG'
SPECIFICATION Spec
INVARIANT Bad
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

# mk_borrowed <dir> <name>: a second model with NO config of its own, which
# declares the two names the paired model's config asks for and puts a
# different rule under one of them.
#
# THIS IS FRANK'S OWN CASE, measured 2026-10-14. Run against mk_six's config:
# rc 12, `4 distinct states found`, `Error: Invariant TypeOK is violated.` and
# a last trace state of x = 3. The paired model beside it runs clean at 6, so
# the two lines differ in every field that matters and a borrowed run cannot
# pass by looking like the model next to it.
mk_borrowed() {
  local d="$1" name="${2:-Six_collision}"
  mkdir -p "$d"
  cat >"${d}/${name}.tla" <<TLA
---- MODULE ${name} ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 5 /\\ x' = x + 1
Spec == Init /\\ [][Next]_x
TypeOK == x < 3
====
TLA
}

# mk_helper <dir>: a module that is not a spec. It defines no Spec, no Init and
# no Next, so no config in the directory has anything to say about it.
#
# A module like this is what EXTENDS is for, and it is the case that stops the
# borrowing rule from being "hand the lone config to anything unpaired".
# Running TLC over it would check a library. It is never run, so its body only
# has to be a module that defines something other than what a config names.
mk_helper() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/Helper.tla" <<'TLA'
---- MODULE Helper ----
EXTENDS Naturals
Double(n) == n * 2
====
TLA
}

# mk_pair <dir>: the INIT/NEXT config form rather than SPECIFICATION. 53 of the
# 337 configs in the survey in .claude/rules/tla-practice.md use it, so a
# reader of configs that only knows SPECIFICATION reads a sixth of them as
# naming nothing. Measured: rc 0, `5 distinct states found`.
mk_pair() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/Pair.tla" <<'TLA'
---- MODULE Pair ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 4 /\ x' = x + 1
====
TLA
  cat >"${d}/Pair.cfg" <<'CFG'
INIT Init
NEXT Next
CHECK_DEADLOCK FALSE
CFG
}

# mk_twin <dir>: an unpaired module that defines BOTH names Pair.cfg gives, so
# it is a module that config can run. Measured against Pair.cfg: rc 0,
# `7 distinct states found`.
mk_twin() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/Twin.tla" <<'TLA'
---- MODULE Twin ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 6 /\ x' = x + 1
====
TLA
}

# mk_extends <dir>: a spec that EXTENDS a sibling module in the same directory,
# which is the shape that decides how much of the directory a temp copy has to
# carry. Bead tla-9y5h.
#
# MEASURED BOTH WAYS on TLC2 2026.07.31.184830, 2026-10-15. With Lib.tla beside
# it: rc 0 and `4 distinct states found`. With only Main.tla and Main.cfg
# copied, which is what a copy of the module being run would do:
#
#   Cannot find source file for module Lib imported in module Main.
#   Error: Parsing or semantic analysis failed.
#
# so a copy that carries one module turns a correct model into distinct=-,
# count=MISMATCH and run=ERROR. That is the FALSE FAIL direction on a right
# model, which this suite's header calls the worse of the two on a drill loop.
# Lib itself defines no Spec, so it lands in the unrun report, and the run has
# to happen anyway.
mk_extends() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/Lib.tla" <<'TLA'
---- MODULE Lib ----
EXTENDS Naturals
Limit == 3
====
TLA
  cat >"${d}/Main.tla" <<'TLA'
---- MODULE Main ----
EXTENDS Naturals, Lib
VARIABLE x
Init == x = 0
Next == x < Limit /\ x' = x + 1
Spec == Init /\ [][Next]_x
TypeOK == x \in 0..Limit
====
TLA
  cat >"${d}/Main.cfg" <<'CFG'
SPECIFICATION Spec
INVARIANT TypeOK
CHECK_DEADLOCK FALSE
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
# PART 4's PROMPTS: the run verdict. Bead tla-rzvk.1.
#
# 15 IS THE BEAD'S RED LINE, word for word: a prompt that publishes no count,
# against a model that violates its invariant. Before tla-rzvk.1 this returned
# one line of prose and never started TLC, so on the 21 prompts of the 64 that
# publish no count the session got no objective input at all. All eight of
# drill/control-state/ are in that 21 and every one of them asks for a verdict.
#
# Its body is drill/control-state/02-pumps/PROMPT.md:23's shape, the same as
# 03-no-claim, because the shape is what the 21 have in common.
mk_prompt fam-a 15-no-claim-violation <<'MD'
# No claim, and the model violates

Write the specification and both rules from an empty file, and run it.
Report the verdict and the number of distinct states.
MD

# 16 AND 17 ARE THE TWO VIOLATIONS THAT ARE NOT INVARIANTS, and both publish
# a count that MATCHES, which is the half of the locked contract that says a
# violation never moves the exit code. A violation is the right answer on some
# items: drill/control-state/01-slip-on-the-spike asks for model 1 to fail.
mk_prompt fam-a 16-liveness <<'MD'
# Liveness

Check it. A correct model finds 4 distinct states.
MD

mk_prompt fam-a 17-deadlock <<'MD'
# Deadlock

Check it. A correct model finds 3 distinct states.
MD

# 18 is the independence row. See mk_evalfail: rc 76, a matching count, a
# trace, an invariant named in the log, and NOT a violation.
mk_prompt fam-a 18-eval-fail <<'MD'
# Evaluation failure

Check it. A correct model finds 4 distinct states.
MD

# ---------------------------------------------------------------------------
# PART 5's PROMPTS: whose config a module runs with. Bead tla-rzvk.4.
#
# 21 IS FRANK'S DIRECTORY, 2026-10-14. One paired model, one variant with no
# config of its own, and TLC's trace leaving beside them. Both counts are
# published, so both models match and the exit is 0 while the second model
# reads VIOLATED. That is the row the locked exit-code decision rests on: a
# borrowed run is an ordinary run, and a violation still does not move the
# exit.
#
# Its two-count shape is the continuation parser's, which the comment on
# 06-two-sizes covers.
mk_prompt fam-a 21-one-config <<'MD'
# One config, two models

Write it, run it, then change one thing and run it again.
A correct model finds 6 distinct states, and 4 with the second rule.
MD

# 22 is the condition that keeps borrowing from being a guess. A helper module
# sits beside a real one, the directory has exactly one config, and the helper
# still does not get it.
mk_prompt fam-a 22-helper <<'MD'
# Helper beside a spec

Check it. A correct model finds 6 distinct states.
MD

# 23 is the same borrowing, through a config that names INIT and NEXT instead
# of SPECIFICATION. Both names have to be defined, not one.
mk_prompt fam-a 23-init-next <<'MD'
# Init and Next

Check it. A correct model finds 5 distinct states and 7 with the wider
ceiling.
MD

# ---------------------------------------------------------------------------
# PART 6's PROMPTS: what check leaves behind. Bead tla-9y5h.
#
# 24 IS THE BEAD'S RED LINE. A model that violates its invariant, checked
# twice, against a prompt that publishes the count it reaches. The count claim
# is there so the run is an ordinary passing run and the only thing part 6 is
# asking about is the directory.
mk_prompt fam-a 24-litter <<'MD'
# Litter

Check it. A correct model finds 4 distinct states.
MD

# 25 is the other half of the fix rather than a second instance of the defect.
# See mk_extends: a temp copy that carries only the module being run breaks an
# EXTENDS of a sibling, so this prompt publishes the count the two modules
# reach together.
mk_prompt fam-a 25-extends <<'MD'
# Extends a sibling

Check it. A correct model finds 4 distinct states.
MD

# 19 and 20 share a prompt shape and differ in the toolchain they get.
mk_prompt fam-a 20-silent-tlc <<'MD'
# Silent toolchain

Check it. A correct model finds 6 distinct states.
MD

# THE STUB TLC, and it is the one fixture here that is NOT a measurement. Every
# real failure path measured on 2026-10-15 prints a line starting `Error:`,
# including the JVM's own `Error: Could not find or load main class tlc2.TLC`
# when the pinned wrapper cannot find its jar. So no real toolchain reaches
# run=NOCOUNT, and NOCOUNT is nonetheless the value that has to be right: it is
# where a log check cannot read has to land, and the alternative is a log that
# says nothing reported as a clean run. That is the false-pass direction, on the
# one field a session will act on without looking.
#
# So this stub stands in for an unreadable log rather than for any tool. It
# prints plausible chatter with no error line and no count, and exits 0.
mkdir -p "${TMP}/stub"
cat >"${TMP}/stub/tlc" <<'STUB'
#!/usr/bin/env bash
echo "TLC2 Version 0.0.0 (stub)"
echo "Starting... (nothing to report)"
exit 0
STUB
chmod +x "${TMP}/stub/tlc"
STUB_TLC_PATH="${TMP}/stub:${NO_TLC_PATH}"

# run_check_with_stub_tlc <args...>: the same run with the stub ahead of a PATH
# that carries no real tlc, so the stub is the only one reachable.
run_check_with_stub_tlc() {
  OUT="$(DRILL_PROMPT_ROOT="$PROMPTS" DRILL_STUDY_ROOT="$WORK" PATH="$STUB_TLC_PATH" "$CHECK" "$@" 2>&1)"
  RC=$?
}

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
#
# THIS IS THE QUIET HALF OF BEAD tla-rzvk.4's CONTRACT, and the three unpaired
# leavings below are what make it bite. Each one is a `.tla` with no `.cfg` of
# its own name, which is the exact shape that now earns a module either a
# borrowed config or a named unrun line. All three must get neither, so the
# assertions in part 3 are that the output holds one module line and no unrun
# line at all.
mk_six   "${WORK}/04-leavings"
mk_eight "${WORK}/04-leavings" "Six_TTrace_1792021269"
cp "${WORK}/04-leavings/Six.tla" "${WORK}/04-leavings/Six.tla.old"
mk_eight "${WORK}/04-leavings/states/Six_17_01" "Deep"

# The unpaired forms of all three. Measured on this build 2026-10-14: a run
# that violates writes Foo_TTrace_<n>.tla with NO config beside it, so a real
# trace leaving IS an unpaired module and the name skip is the only thing
# between it and a borrowed config.
cp "${WORK}/04-leavings/Six.tla" "${WORK}/04-leavings/Six_TTrace_1792021270.tla"
cp "${WORK}/04-leavings/Six.tla" "${WORK}/04-leavings/states/Six_17_01/Orphan.tla"
cp "${WORK}/04-leavings/Six.tla" "${WORK}/04-leavings/Spare.tla.old"

# 10-no-cfg: a module with no config of its own name, which is the shape
# pickers_collision.tla has. On its own it leaves nothing to run.
mkdir -p "${WORK}/10-no-cfg"
cp "${WORK}/01-six/Six.tla" "${WORK}/10-no-cfg/Lone.tla"

# 11-variants: two qualifying pairs side by side, plus a third module with no
# config. Frank keeps variants this way, so check runs each and reports each.
mk_six   "${WORK}/11-variants"
mk_eight "${WORK}/11-variants"
cp "${WORK}/01-six/Six.tla" "${WORK}/11-variants/Lone.tla"

# Part 4's study directories.
mk_viol     "${WORK}/15-no-claim-violation"
mk_live     "${WORK}/16-liveness"
mk_dead     "${WORK}/17-deadlock"
mk_evalfail "${WORK}/18-eval-fail"
mk_six      "${WORK}/20-silent-tlc"

# Part 5's study directories. Bead tla-rzvk.4.
#
# 21 IS THE WHOLE BEAD IN ONE DIRECTORY: Frank's shape, with the trace leaving
# in it. The leaving is there to prove it is not counted as a config candidate
# and not run as a module, in the one directory where a miscount would change
# a verdict rather than only add a line.
#
# MEASURED IN /home/fkberthold/Study/tla-drills/01-slip-on-the-spike ON
# 2026-10-14: pickers.cfg, pickers.tla, pickers_collision.tla and
# pickers_TTrace_1792021269.tla, with a states/ directory. The trace module
# carries NO config of its own, which this build confirms it never writes, so
# the leaving is itself an unpaired module.
mk_six      "${WORK}/21-one-config"
mk_borrowed "${WORK}/21-one-config"
cp "${WORK}/21-one-config/Six.tla" "${WORK}/21-one-config/Six_TTrace_1792034839.tla"

# THE CONFIG SIDE OF THE SAME SKIP, and this one guards a shape the current
# build does not produce. TLC2 2026.07.31.184830 writes a trace module with no
# config beside it, so a *_TTrace_*.cfg only turns up from an older build or
# from a hand-copy. Counting one as a candidate would take this directory from
# one config to two and flip Six_collision from a borrowed run to a refusal,
# which is a false refusal on the exact case the bead exists for. The file is
# here so that stays asserted rather than merely intended.
cp "${WORK}/21-one-config/Six.cfg" "${WORK}/21-one-config/Six_TTrace_1792034839.cfg"

# 22: one config, one real model, and a module that answers to no config.
mk_six    "${WORK}/22-helper"
mk_helper "${WORK}/22-helper"

# 23: the INIT/NEXT form of the same borrowing.
mk_pair "${WORK}/23-init-next"
mk_twin "${WORK}/23-init-next"

# Part 6's study directories. Bead tla-9y5h.
#
# NOTHING BETWEEN HERE AND PART 6 MAY RUN AGAINST EITHER OF THEM. Part 6 takes
# its before-image at the top of the part rather than here, so a run earlier in
# the file would be snapshotted as though its leavings had always been there,
# and the comparison would hold over a directory already littered. Both slugs
# are unique to part 6 for that reason.
mk_viol    "${WORK}/24-litter"
mk_extends "${WORK}/25-extends"

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

# A DIRECTORY WITH NO CONFIG AT ALL. Nothing is paired and there is nothing to
# borrow, so this stays rc 3. What bead tla-rzvk.4 adds is the module's name:
# the old message said a directory had no runnable module and left Frank to
# work out which file it meant.
run_check 10-no-cfg
rc_is "a module with no config of its own name leaves nothing to run, rc 3" 3
has   "and the message says so" "no module"
not_run_line "and the module is named rather than left to be guessed at" \
  Lone 'no Lone\.cfg, and no other config in the directory'

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

# THE NO-CLAIM CASE. Exit 2 and the word UNCHECKED, as before, and now a
# module line too: the run happens and its verdict is reported, which is bead
# tla-rzvk.1's whole subject. The count fields are the absent marker and the
# count verdict is NONE.
#
# THE INVENTED ZERO IS STILL THE HAZARD and it is asked here from the claim
# end. `claimed=-` positively, `claimed=0` ruled out, and both count verdicts
# ruled out BY NAME rather than by the word MATCH, which MISMATCH contains.
# What is gone is the old "no number anywhere" row: a no-claim run now prints
# TLC's rc and TLC's count on purpose, so counting digits would assert against
# the fix.
run_check 03-no-claim
rc_is "a prompt with no count claim is rc 2" 2
has   "and says UNCHECKED" "UNCHECKED"
has   "and names the slug" "03-no-claim"
field_is   "the claim field is the absent marker" claimed '-'
field_isnt "and no zero is invented as a claim" claimed '0'
field_isnt "and TLC's own count is not read back as the claim" claimed '6'
field_is   "the count verdict is NONE" count 'NONE'
field_isnt "and it is not a match" count 'MATCH'
field_isnt "and it is not a mismatch either" count 'MISMATCH'
field_is   "TLC ran and its count is reported anyway" distinct '6'
field_is   "and its rc is reported anyway" rc '0'
lines_matching "one run line" 1 '^module=[^[:space:]]+ config='
lines_matching "one verdict line" 1 '^(MATCHED|MISMATCHED|UNCHECKED):'

# NO CLAIM AND NO TLC IS NOW RC 3, AND THAT MOVED IN tla-rzvk.1. It used to be
# rc 2: the claim scan ran before the toolchain check, so a no-claim prompt
# never asked whether tlc was there. Now the run IS the deliverable on these
# 21 prompts, so being unable to run it is "could not run" -- the same exit 3
# an absent tlc earns on every other prompt. Exit 2 keeps its meaning, that
# the prompt publishes no count. What changed is that it's no longer reached
# by declining to look.
run_check_without_tlc 03-no-claim
rc_is "no claim and no tlc is rc 3, because the verdict is the deliverable" 3
has   "and the message names tlc" "tlc"
hasnt "and it does not report an UNCHECKED it could not stand behind" "UNCHECKED"

# ===========================================================================
echo "== part 2: the comparison, against real TLC runs =="
# ===========================================================================

# The no-argument form, which is how Frank runs it: from in the directory.
# EVERY FIELD OF THE LOCKED LINE IS ASSERTED HERE, in order, because this is
# the one row where all eight carry their ordinary value. tla-rzvk.2 is being
# built against that line in parallel, so a field that drifts breaks a sibling
# rather than only this suite.
#
# IT WAS SEVEN FIELDS UNTIL BEAD tla-rzvk.4, which put `config=` between
# `module=` and `rc=`. That is a change to the epic's locked contract and not
# a private one, so a parser reading the line by position rather than by key
# has to be told. Reading by key survives it.
run_check_in "${WORK}/01-six"
rc_is "a model that reaches the claimed count is rc 0" 0
has   "the line names the module" "module=Six"
field_is "the line names the config it ran with" config 'Six\.cfg'
field_is "the line carries TLC's rc" rc '0'
field_is "the line carries the count TLC printed" distinct '6'
field_is "the line carries the count the prompt claimed" claimed '6'
field_is "and calls it a match" count 'MATCH'
field_isnt "and calls it nothing else" count 'MISMATCH'
field_is "the run verdict is CLEAN" run 'CLEAN'
field_is "and no invariant is named on a clean run" invariant '-'
hasnt "and no state block is printed when nothing violated" "  State "
has   "the verdict line names the slug" "01-six"
lines_matching "one run line" 1 '^module=[^[:space:]]+ config='
lines_matching "one verdict line" 1 '^(MATCHED|MISMATCHED|UNCHECKED):'

run_check 02-eight-wanted
rc_is "a model that reaches a different count is rc 1" 1
field_is "the count TLC printed is there" distinct '8'
field_is "the count the prompt claimed is there" claimed '6'
field_is "and it is called a mismatch" count 'MISMATCH'
field_isnt "and not a match" count 'MATCH'
field_is "a wrong count on a clean run is still a clean run" run 'CLEAN'

# The explicit-directory form.
run_check "${WORK}/05-table"
rc_is "a count published in a table matches, rc 0" 0
field_is "every count in the column is claimed, comma grouping and all" claimed '3,6,9,1024'
field_is "and the printed count is TLC's" distinct '6'
field_is "and it is a match" count 'MATCH'

run_check 06-two-sizes
rc_is "the second of two counts at two model sizes matches, rc 0" 0
field_is "both published counts are claimed" claimed '3,6'
field_is "and the printed count is TLC's" distinct '6'

run_check 07-unparsable
rc_is "a module TLC cannot parse is rc 1" 1
field_is   "and the count reads the absent marker rather than zero" distinct '-'
field_isnt "and no zero is invented" distinct '0'
field_is   "and it is a mismatch" count 'MISMATCH'
field_is   "and the run is an error rather than a violation" run 'ERROR'
field_isnt "a parse failure is not a violation" run 'VIOLATED'
field_is   "and no invariant is named" invariant '-'

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
field_is "TLC's rc is reported as it was" rc '12'
field_is "and the count is read out of the log" distinct '4'
field_is "and it is a match" count 'MATCH'
field_is "and the run verdict is VIOLATED beside it" run 'VIOLATED'
field_is "and the violating invariant is named" invariant 'Small'
state_block_follows "and the violating state sits under the module line" Viol
has "the violating state is the LAST state of the trace, not the first" "  x = 3"
hasnt "and the trace is not dumped whole" "  x = 0"

# ===========================================================================
echo "== part 3: which modules get run =="
# ===========================================================================

# THE QUIET HALF OF tla-rzvk.4. Three unpaired leavings sit in this directory
# and all three are `.tla` files with no `.cfg` of their own, which after that
# bead is the shape that earns a borrowed config or a named unrun line. None
# of them may get either. The count of unrun lines is the assertion that
# catches a leak, because a leaking *_TTrace_* would otherwise print a line
# whose module name no `hasnt` below happens to spell.
run_check 04-leavings
rc_is "a directory of TLC leavings still checks the one real module, rc 0" 0
has   "the real module ran" "module=Six"
lines_matching "exactly one run line" 1 '^module=[^[:space:]]+ config='
lines_matching "and no leaving is reported unrun" 0 '^module=[^[:space:]]+ NOT RUN:'
hasnt "a *_TTrace_* module is not run" "TTrace"
hasnt "a module under states/ is not run" "Deep"
hasnt "and an unpaired one under states/ is not named either" "Orphan"
hasnt "a *.old leaving is not run" ".old"
hasnt "and an unpaired *.old is not named either" "Spare"

# TWO CONFIGS AND AN UNPAIRED MODULE, which is the case borrowing refuses.
# Lone has no config of its own and the directory offers two, so picking one
# would be this script guessing which model Frank meant it for. It names both
# and runs neither.
run_check 11-variants
rc_is "two variants side by side is rc 1 when one of them misses" 1
lines_matching "both variants ran" 2 '^module=[^[:space:]]+ config='
has   "the matching variant is named" "module=Six"
has   "the missing variant is named" "module=Eight"
field_is "the matching variant ran with its own config" config 'Six\.cfg'
field_is "the missing variant ran with its own config" config 'Eight\.cfg'
field_is "the matching count is printed" distinct '6'
field_is "the missing count is printed" distinct '8'
not_run_line "the unpaired module is named, with both candidates" \
  Lone 'no Lone\.cfg, and 2 configs to choose from: Eight\.cfg, Six\.cfg'
lines_matching "and only that one is unrun" 1 '^module=[^[:space:]]+ NOT RUN:'
has   "the verdict names the variant that missed" "Eight"
lines_matching "each variant carries its own run verdict" 2 'run=CLEAN([[:space:]]|$)'

# ===========================================================================
echo "== part 4: the run verdict, and the violating state =="
# ===========================================================================

# THE BEAD'S RED LINE, and the defect it names. Before tla-rzvk.1 this printed
# one line of prose, started no TLC, and gave the session nothing objective at
# all on 21 of the 64 prompts.
run_check 15-no-claim-violation
rc_is "a no-claim prompt still exits 2, whatever the run did" 2
field_is "the claim is absent" claimed '-'
field_is "and the count dimension says so" count 'NONE'
field_is "and TLC ran: the count it printed is reported" distinct '4'
field_is "and TLC's rc is reported" rc '12'
field_is "AND THE VERDICT IS REPORTED, which is the bead" run 'VIOLATED'
field_is "with the violating invariant's name" invariant 'Small'
state_block_follows "and the violating state under the module line" Viol
has "the violating state is the one that violated" "  x = 3"
has "and the verdict line still says UNCHECKED" "UNCHECKED"

# A VIOLATION NEVER MOVES THE EXIT CODE, which is the locked decision the next
# three rows gate. 16 and 17 publish counts their models reach, so each is a
# match at rc 0 while the run verdict reads VIOLATED. A violation is the right
# answer on some items: drill/control-state/01-slip-on-the-spike asks for
# model 1 to fail, so an exit code for VIOLATED would gate on intent check
# cannot see.
run_check 16-liveness
rc_is "a violated temporal property at a matching count is still rc 0" 0
field_is "TLC's rc is 13 here" rc '13'
field_is "the count matched" count 'MATCH'
field_is "and the run verdict is VIOLATED" run 'VIOLATED'
field_is 'the name is read out of "was violated" as well as "is violated"' invariant 'Reaches'
state_block_follows "and the counter-example's last state is shown" Live
has "a Stuttering last state is reported as TLC wrote it" "  State 4: Stuttering"
hasnt "and TLC's next chatter line is not swallowed into the block" "  Finished checking"

run_check 17-deadlock
rc_is "a deadlock at a matching count is still rc 0" 0
field_is "TLC's rc is 11 here" rc '11'
field_is "the count matched" count 'MATCH'
field_is "a deadlock is a violation" run 'VIOLATED'
field_is "and it has no name to give, so the marker stands" invariant '-'
state_block_follows "the deadlocked state is still shown" Dead
has "and it is the terminal state" "  x = 2"

# THE INDEPENDENCE ROW, and the one that keeps the word VIOLATED honest.
# rc 76: the count is real and matches, the log names an invariant and prints a
# trace, and NOTHING is known about whether that invariant holds. Bead tla-i9m
# settled this for harness/verdict.sh and the reason is the learner-facing one:
# "your invariant was violated" would be a false statement about a check that
# never ran.
run_check 18-eval-fail
rc_is "an evaluation failure at a matching count is rc 0" 0
field_is   "TLC's rc is 76 here" rc '76'
field_is   "the count printed after the error is read" distinct '4'
field_is   "and it matches" count 'MATCH'
field_is   "the run verdict is ERROR" run 'ERROR'
field_isnt "an evaluation failure is NOT a violation" run 'VIOLATED'
field_isnt "nor is it clean" run 'CLEAN'
field_is   "and the invariant TLC named is not reported as violated" invariant '-'
hasnt "and no violating state is claimed, because nothing violated" "  State "

# THE FALSE-CLEAN GUARD. See the stub's comment: no real toolchain reaches this
# value, and that is the reason to gate it. A log check cannot read must land
# somewhere that is not CLEAN.
run_check_with_stub_tlc 20-silent-tlc
rc_is "a run that printed no count is a count mismatch, rc 1" 1
field_is   "the count is the absent marker" distinct '-'
field_is   "and the count dimension says mismatch" count 'MISMATCH'
field_is   "and a log with neither an error nor a count is NOCOUNT" run 'NOCOUNT'
field_isnt "never CLEAN, which is the false pass this row exists for" run 'CLEAN'
field_isnt "and not an error it cannot point at" run 'ERROR'
field_is   "and nothing is named" invariant '-'

# ===========================================================================
echo "== part 5: whose config a module runs with =="
# ===========================================================================

# FRANK'S DIRECTORY, AND THE BEAD'S RED LINE. One config, two models, and the
# second model is the one with the defect in it. Before bead tla-rzvk.4 only
# the first appeared and the verdict read clean.
#
# Both published counts match, so the exit is 0 WHILE the second model reads
# VIOLATED. That pairing is what the locked exit-code decision means: a
# borrowed run is an ordinary run, and a violation still never moves the exit.
# An implementation that folded an unpaired module into the failure count
# passes 11-variants above and fails here.
run_check 21-one-config
rc_is "a borrowed config does not move the exit code" 0
lines_matching "both models ran" 2 '^module=[^[:space:]]+ config='
lines_matching "and neither is reported unrun" 0 '^module=[^[:space:]]+ NOT RUN:'
has   "the paired model ran" "module=Six "
has   "the unpaired model ran too, which is the bead" "module=Six_collision "
lines_matching "and BOTH lines name the config, not just the borrowed one" \
  2 '(^|[[:space:]])config=Six\.cfg([[:space:]]|$)'
field_is   "the borrowed run reports TLC's rc" rc '12'
field_is   "and the count it printed" distinct '4'
field_is   "and the paired model's count beside it" distinct '6'
field_is   "both counts were published, so both match" claimed '6,4'
field_is   "the borrowed run's verdict is reported" run 'VIOLATED'
field_is   "with the invariant it broke" invariant 'TypeOK'
field_isnt "and no model reports a count mismatch" count 'MISMATCH'
state_block_follows "the violating state sits under the borrowed run's line" Six_collision
has   "and it is the state that broke the invariant" "  x = 3"
hasnt "the trace leaving beside them is never named" "TTrace"
not_run_line_absent "and its config is not counted as a second candidate" Six_collision
has   "the verdict line still reads MATCHED" "MATCHED:"

# THE CONDITION THAT KEEPS BORROWING FROM BEING A GUESS. Exactly one config
# sits here, and Helper still does not get it: it defines no Spec, so running
# it would check a library rather than a spec. The reason is on the line,
# because "not run" alone sends Frank looking for a config he does not need.
run_check 22-helper
rc_is "a module that answers to no config does not fail the run, rc 0" 0
has   "the real module ran" "module=Six "
lines_matching "and it is the only run" 1 '^module=[^[:space:]]+ config='
not_run_line "the helper is named, and the reason names the operator" \
  Helper 'does not define Spec, which Six\.cfg names'
hasnt "the helper was not handed the one config in the directory" "module=Helper config="
has   "the verdict line still reads MATCHED" "MATCHED:"

# THE SAME BORROWING THROUGH AN INIT/NEXT CONFIG. Twin defines both names
# Pair.cfg gives, so it runs. A reader that only knows SPECIFICATION finds no
# name here, which is the false-refusal direction: Twin would land in the unrun
# report with a reason that is not true of it.
run_check 23-init-next
rc_is "an INIT/NEXT config borrows the same way, rc 0" 0
lines_matching "both modules ran" 2 '^module=[^[:space:]]+ config='
lines_matching "and neither is reported unrun" 0 '^module=[^[:space:]]+ NOT RUN:'
has   "the paired module ran" "module=Pair "
has   "the unpaired one borrowed the config" "module=Twin "
lines_matching "and both lines name it" \
  2 '(^|[[:space:]])config=Pair\.cfg([[:space:]]|$)'
field_is "the paired count is TLC's" distinct '5'
field_is "and the borrowed count is TLC's" distinct '7'
field_is "both published counts are claimed" claimed '5,7'
field_isnt "and neither is a mismatch" count 'MISMATCH'

# ===========================================================================
echo "== part 6: check never writes in the directory it is checking =="
# ===========================================================================

# BEAD tla-9y5h, AND IT WAS MEASURED ON FRANK'S REAL DIRECTORY TWICE BEFORE IT
# WAS WRITTEN HERE, forty minutes apart on 2026-10-14 and again on 2026-10-15,
# in ~/Study/tla-drills/01-slip-on-the-spike. check ran TLC in the directory it
# was checking, so a violated run left a trace module, its .bin and a
# fingerprint cache beside the spec. The names carry a timestamp, so nothing
# overwrites at any human spacing and twenty checks leave twenty pairs, in the
# one tree that holds the only copy of his work and has no git behind it.
# scripts/deliver-drill.sh calls that tree "left alone (your work, never
# written here)" while it prints the delivery, which the checker was making
# false.
#
# A SIBLING IN THE SAME TREE ALREADY HAS THE PROPERTY. drill/study/style was
# run against that directory minutes later and wrote nothing at all, because it
# reads text and never starts TLC. So the standard part 6 holds check to is one
# another delivered tool already meets.
#
# THE DEFECT IS BROADER THAN A VIOLATED RUN, measured here on 2026-10-15: a
# CLEAN run leaves a states/ directory too. 25-extends is clean and its tree is
# asserted the same way, so the part gates every run rather than only the ones
# that refute.
#
# WHAT THIS CHANGES ABOUT BEAD tla-rzvk.4's *_TTrace_* SKIP, which part 3
# gates: the skip stops being self-inflicted. check was generating the exact
# unpaired-module shape the borrowing rule has to special-case, so the skip was
# guarding its own leavings. After this part it guards only what TLC left there
# BEFORE, from a hand run of tlc or an older session, which is what it was
# always for. The skip is no less load-bearing and 04-leavings and 21-one-config
# still gate it.
#
# EVERY ASSERTION BELOW IS AN ASSERTION OF ABSENCE, so read the instrument's
# comment above dir_tree first. The before-image is asserted against its
# literal contents, and the run is asserted to have really refuted something,
# because a run that did not violate would leave no trace to find and the
# comparison would be green for the wrong reason.

LITTER="${WORK}/24-litter"

LITTER_BEFORE_WANT='.
./Viol.cfg
./Viol.tla'
LITTER_BEFORE="$(dir_tree "$LITTER")"
if [ "$LITTER_BEFORE" = "$LITTER_BEFORE_WANT" ]; then
  ok "fixture control: the directory exists and holds exactly the violating model and its config"
else
  nope "FIXTURE: 24-litter is not the two-file directory part 6 compares against, so every row below is void (got: ${LITTER_BEFORE})"
fi

# The run itself first, in full, because a fix that stopped running TLC would
# satisfy every absence row in this part. The verdict channel has to come back
# unchanged through the copy.
run_check 24-litter
rc_is "a violating model still checks through the copy, rc 0" 0
field_is "TLC ran: its rc is reported" rc '12'
field_is "and the count it printed" distinct '4'
field_is "and the count still matches" count 'MATCH'
field_is "AND THE RUN REALLY DID REFUTE SOMETHING, which is what leaves a trace to find" run 'VIOLATED'
field_is "with the invariant it broke" invariant 'Small'
state_block_follows "and the violating state still comes back" Viol
has "and it is the state that broke the invariant" "  x = 3"

tree_unchanged "THE FIRST RUN ADDED NOTHING to the directory it checked" "$LITTER" "$LITTER_BEFORE"
tree_lacks "no trace module and no .bin beside the spec" "$LITTER" '_TTrace_'
tree_lacks "and no fingerprint cache" "$LITTER" '(^|/)states(/|$)'

# TWICE IS THE BEAD'S RED LINE AND NOT A REPETITION. The leavings carry a
# timestamp, so the second run is where they accumulate rather than overwrite:
# measured here on 2026-10-15 against the unfixed script, two runs a third of a
# second apart left one trace pair, because the name is stamped to the second,
# and TWO states/ subdirectories, because that name is stamped to the
# millisecond. At the forty-minute spacing Frank measured, both accumulate.
run_check 24-litter
rc_is "the second run reports the same verdict" 0
field_is "and still refutes" run 'VIOLATED'
field_is "at the same count" distinct '4'
tree_unchanged "AND THE SECOND RUN ADDED NOTHING EITHER, which is where the leavings used to accumulate" "$LITTER" "$LITTER_BEFORE"
tree_lacks "still no trace module after two runs" "$LITTER" '_TTrace_'
tree_lacks "and still no fingerprint cache" "$LITTER" '(^|/)states(/|$)'

# THE STUDY ROOT, ONE LEVEL UP, which the rows above cannot see: a scratch
# directory made BESIDE the work directory leaves that directory clean and
# still writes in the tree the bead is about.
#
# WHAT THIS ROW CATCHES IS A LEAK AND NOT A PLACEMENT, and I got that wrong on
# the first attempt, so it is worth writing down. Pointing the fix's mktemp at
# the study root did NOT redden this row, because the scratch directory is
# removed on the way out and the snapshot is taken after the run. Dropping the
# cleanup trap as well reddened it, alone, out of 211. So the claim it stands
# behind is that nothing SURVIVES beside the work directory, which covers a
# scratch directory that leaked and any other sibling write, and does not cover
# a copy that lived under the study tree for the length of one run. I think
# catching the placement would need the filesystem watched mid-run, and the
# leak is the shape that costs Frank anything.
STUDY_BEFORE="$(dir_tree "$WORK" -maxdepth 1)"
run_check 24-litter
tree_unchanged "and nothing was left beside the work directory either" \
  "$WORK" "$STUDY_BEFORE" -maxdepth 1

# THE OTHER HALF OF THE FIX. A copy that carries only the module being run
# breaks an EXTENDS of a sibling, which is the false-fail direction on a right
# model. See mk_extends for both measurements.
EXT="${WORK}/25-extends"

EXT_BEFORE_WANT='.
./Lib.tla
./Main.cfg
./Main.tla'
EXT_BEFORE="$(dir_tree "$EXT")"
if [ "$EXT_BEFORE" = "$EXT_BEFORE_WANT" ]; then
  ok "fixture control: the extending directory holds the spec, its config and the module it extends"
else
  nope "FIXTURE: 25-extends is not the three-file directory part 6 compares against, so the rows below are void (got: ${EXT_BEFORE})"
fi

run_check 25-extends
rc_is "a spec that extends a sibling still resolves it through the copy, rc 0" 0
has   "the spec ran" "module=Main "
field_is   "at the count both modules reach together" distinct '4'
field_is   "which matches" count 'MATCH'
field_is   "and the run is clean" run 'CLEAN'
field_isnt "never an error, which is what a one-module copy produces" run 'ERROR'
field_isnt "and the count is never the absent marker" distinct '-'
not_run_line "the extended module is named rather than run, as a library" \
  Lib 'does not define Spec, which Main\.cfg names'
tree_unchanged "A CLEAN RUN ADDS NOTHING EITHER, and before this bead it left a states/ directory" \
  "$EXT" "$EXT_BEFORE"
tree_lacks "no fingerprint cache after a clean run" "$EXT" '(^|/)states(/|$)'

# ===========================================================================
printf '\n'
if [ "$fail_count" -eq 0 ]; then
  printf 'OK: %d assertions passed.\n' "$pass_count"
  exit 0
fi
printf 'FAILED: %d of %d assertions failed.\n' "$fail_count" "$((pass_count + fail_count))" >&2
exit 1
