#!/usr/bin/env bash
# test-drill-style.sh: the gate for drill/study/style, the second objective
# half of the study loop.
#
# WHAT style IS FOR, in one sentence, because every assertion below is an
# assertion about that sentence: it measures seven textual axes of a module
# Frank wrote, prints beside each one what a published corpus counted, and
# judges neither. Whether a difference matters is the model's call, made
# against drill/study/STYLE.md. That is the same split bead tla-ytv2 drew for
# check, where check reports a count and refuses to rule on intent.
#
# STYLE HAS NO PASS AND NO FAIL, AND PART 1 PINS THAT HARDER THAN ANYTHING
# ELSE HERE. Exit 0 when it measured anything, exit 3 when it could not run.
# There is no exit 1 and no exit 2. A style pass that can fail becomes a gate
# on Frank's own work, and the maximally unidiomatic fixture in part 3 is
# there to exit 0 anyway. An implementation that scores the axes and fails the
# worst one passes almost every other assertion in this file.
#
# THE DEFECT THIS EXISTS TO STOP has three shapes.
#
#   A JUDGMENT DRESSED AS A FACT. "wrong", "should", "error", "bad",
#   "unidiomatic", "violation" -- part 3 bans the vocabulary outright across
#   the whole output of the worst fixture in the suite. The script's job ends
#   at the number.
#
#   A PLAUSIBLE WRONG MEASUREMENT. This is the one that cost the most to
#   defend against, because TLA+ wraps and a line-based scan of it gives
#   answers that look right. A CONSTANTS declaration continues onto following
#   lines in 30 sites of this repo's own reference corpus (measured
#   2026-10-15: `grep -rn -A1 'CONSTANTS* .*,$' --include='*.tla' drill/`),
#   and a scan that reads only the keyword's own line loses 27 of the 139
#   distinct constant names. TLC also lets a config's keyword and its name sit
#   on separate lines. Part 4 drives both continuations, and a line-based
#   implementation fails there and nowhere else.
#
#   A FILE LEFT BEHIND. style reads text and must never write any. check runs
#   TLC in the work directory and leaves a timestamped trace pair on every
#   violated run, which is bead tla-rzvk.5, and a text pass has no reason to
#   go near that. Part 5 snapshots the work directory before and after and
#   asserts it is unchanged, and runs the whole suite's worst case with tlc
#   taken off the path.
#
# PART 1  usage, resolution, every way to exit 3, and the ban on 1 and 2
# PART 2  the worked instance: all seven axes on the attempt Frank wrote
# PART 3  the opposite corner, and the ban on judgment vocabulary
# PART 4  the parsing hazards: wrapped declarations and wrapped config keywords
# PART 5  which modules get measured, which leavings get skipped, and that
#         nothing is written and TLC never runs
# PART 6  the one per-item suppression, and that it is one item and one axis
#
# Usage:  harness/test-drill-style.sh
# Exit:   0 if all assertions hold, 1 otherwise, 2 on a usage error or a
#         fixture this suite cannot trust.
#
# ---------------------------------------------------------------------------
# IT NEVER TOUCHES ~/tla-practice OR ~/Study. Both hold the only copy of work
# Frank did by hand and neither has an offsite copy, so every path below is
# under one mktemp -d and both roots are passed in by environment variable.
#
# THE WORKED FIXTURE IS A COPY, NOT A READ. pickers.tla in part 2 is Frank's
# real 2026-10-14 attempt at 01-slip-on-the-spike, transcribed here. A suite
# that read his tree would assert against a directory that changes under it,
# and would put this suite one typo away from writing into the only copy.
#
# WHY FAST TIER. Nothing here starts a JVM. By the rule in scripts/test's
# header the boundary is the model checker, and style never invokes one -- the
# tlc-off-the-path row in part 5 is the assertion that says so.
# ---------------------------------------------------------------------------

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

STYLE="${REPO_ROOT}/drill/study/style"

case "${1:-}" in
  "") ;;
  -h|--help)
    # Print the header block, stopping at the first line of code, the same way
    # scripts/test --help does rather than at a line number that drifts.
    awk 'NR > 1 && /^set -uo pipefail$/ { exit } NR > 1' "${BASH_SOURCE[0]}"
    exit 0
    ;;
  *)
    echo "test-drill-style.sh: unknown option '$1' (try --help)" >&2
    exit 2
    ;;
esac
if [ "$#" -gt 1 ]; then
  echo "test-drill-style.sh: takes at most one option, got $# ($*)" >&2
  exit 2
fi

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

if [ ! -x "$STYLE" ]; then
  echo "test-drill-style.sh: ${STYLE} is missing or not executable, so this suite refuses to report success." >&2
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

# run_style <args...>: the ordinary invocation, with both roots pointed at the
# fixture tree. Output is captured combined, because the exit-3 messages go to
# stderr and this suite asserts on them.
run_style() {
  OUT="$(DRILL_PROMPT_ROOT="$PROMPTS" DRILL_STUDY_ROOT="$WORK" "$STYLE" "$@" 2>&1)"
  RC=$?
}

# run_style_in <dir>: the no-argument form, from inside <dir>, which is how
# the slug gets resolved when Frank is sitting in the directory.
run_style_in() {
  OUT="$(cd "$1" && DRILL_PROMPT_ROOT="$PROMPTS" DRILL_STUDY_ROOT="$WORK" "$STYLE" 2>&1)"
  RC=$?
}

# NO_TLC_PATH: the real PATH with EVERY directory holding a tlc taken out of
# it, and nothing else changed. Lifted from test-drill-check.sh, where the two
# earlier shapes of this helper were both wrong: a hardcoded /usr/bin:/bin
# dies at rc 127 on NixOS, and dropping only the directory `command -v tlc`
# resolves to leaves the second tlc on this box standing.
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

run_style_without_tlc() {
  OUT="$(DRILL_PROMPT_ROOT="$PROMPTS" DRILL_STUDY_ROOT="$WORK" PATH="$NO_TLC_PATH" "$STYLE" "$@" 2>&1)"
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

# axis_field <label> <axis> <field> <value>: assert a WHOLE field of ONE axis
# line, anchored at both ends. Every field assertion in this file goes through
# it, and the two reasons are separate.
#
# ANCHORING IS NOT OPTIONAL, AND THE REASON IS MEASURABLE. A substring test
# for `covers:2/2` is satisfied by `covers:12/22`; `invariants:1` is a prefix
# of `invariants:10`; `primed:2` is a prefix of `primed:20`; `full-tuple:1` is
# a prefix of `full-tuple:10`; and `name:Spec` is a prefix of `name:SpecFair`,
# which is a qualified variant the corpus treats as a different answer. So an
# unanchored test for one value is a test for a family of values. Anchoring on
# a space or a line boundary at both ends asks the question that catches it.
#
# ASKING PER-AXIS IS THE SECOND HALF. Seven axes print a `measured=` field
# each, so a whole-output test for one of them says nothing about which axis
# carried it. A module line and seven axis lines give an implementation seven
# places to put a right answer to the wrong question, and only a per-axis
# lookup notices.
axis_field() {
  local line
  while IFS= read -r line; do
    case "$line" in
    *"axis=$2 "*)
      if grep -qE -- "(^|[[:space:]])$3=$4([[:space:]]|$)" <<<"$line"; then
        ok "$1"
      else
        nope "$1 (axis=$2 carries '${line}', wanted the whole field ${3}=${4})"
      fi
      return
      ;;
    esac
  done <<<"$OUT"
  nope "$1 (no axis=$2 line at all. output: ${OUT})"
}

# axis_line_count <label> <n>: how many axes the run actually MEASURED.
#
# IT COUNTS `measured=`, NOT `axis=`, and part 6 is why. A suppressed axis
# still prints an `axis=` line saying it was suppressed, so counting the
# keyword alone reports seven where six were measured -- which is the one
# number part 6 exists to pin.
axis_line_count() {
  local n
  n="$(grep -cE -- '(^|[[:space:]])axis=[a-z-]+[[:space:]]measured=' <<<"$OUT")"
  if [ "$n" = "$2" ]; then ok "$1"; else nope "$1 ($n measured axes, want $2. output: ${OUT})"; fi
}

# ===========================================================================
# FIXTURE BUILDERS
#
# Every expected value below was read off the fixture by hand and then watched
# to fail against two deliberately wrong stubs before the implementation
# existed. A fixture whose expected value was derived from the implementation
# is a fixture that can only agree with it.
# ===========================================================================

mk_prompt() {
  mkdir -p "${PROMPTS}/$1/$2"
  cat >"${PROMPTS}/$1/$2/PROMPT.md" <<'MD'
# A prompt

Write the module. A correct model finds 7 distinct states.
MD
}

# mk_pickers <dir>: Frank's real attempt at 01-slip-on-the-spike, transcribed
# from ~/Study/tla-drills/01-slip-on-the-spike/ on 2026-10-15. Every one of
# the seven axes has a real value on this one file, which is why the bead
# names it as the fixture.
#
#   constants  picker_count, max_slips  -- both snake_case
#   variables  pickers, slips           -- both plain lowercase words
#   vars       <<pickers, slips>>       -- covers both declared variables
#   Spec       Init /\ [][Next]_vars    -- named Spec, subscript the full tuple
#   Next       \E p \in ... : \/ ... \/ ...  -- two anonymous inline arms
#   types      none declared
#   config     names 2 invariants
mk_pickers() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/pickers.tla" <<'TLA'
---- MODULE pickers ----
EXTENDS Integers
CONSTANTS picker_count, max_slips

ASSUME picker_count >= 1
ASSUME max_slips >= 1

-----------------------------
\* Two pickers working an aisle
VARIABLES pickers, slips

vars == <<pickers, slips>>

-----------------------------
\* Invariants
SlipsNatural == slips >= 0
NoDoublePicks == \A p1, p2 \in 1..picker_count: (p1 # p2 /\ pickers[p1] > 0) => pickers[p1] # pickers[p2]

-----------------------------

Init ==
    /\ pickers = [p \in 1..picker_count |-> 0]
    /\ slips \in 1..max_slips

Next ==
    \E p \in 1..picker_count:
      \/ /\ pickers[p] = 0
         /\ slips > 0
         /\ pickers' = [pickers EXCEPT ![p] = slips]
         /\ slips' = slips - 1
      \/ /\ pickers[p] > 0
         /\ pickers' = [pickers EXCEPT ![p] = 0]
         /\ UNCHANGED slips

Spec == Init /\ [][Next]_vars


====
TLA
  cat >"${d}/pickers.cfg" <<'CFG'
SPECIFICATION Spec
CONSTANT picker_count = 2
CONSTANT max_slips = 1
CHECK_DEADLOCK FALSE

INVARIANT SlipsNatural
INVARIANT NoDoublePicks
CFG
}

# mk_textbook <dir>: the opposite corner on every axis. CamelCase constants,
# TypeOK declared and shaped as a membership conjunction over every declared
# variable, a vars tuple covering both, a behavior formula named Spec, the box
# subscript the full tuple, Next a bulleted disjunction of named actions, and
# a config naming one invariant and one property.
mk_textbook() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/Depot.tla" <<'TLA'
---- MODULE Depot ----
EXTENDS Naturals
CONSTANTS Crates, MaxHeld

VARIABLES held, waiting

vars == <<held, waiting>>

TypeOK ==
  /\ held \in 0..MaxHeld
  /\ waiting \in 0..Crates

Init ==
  /\ held = 0
  /\ waiting = Crates

Load ==
  /\ waiting > 0
  /\ held < MaxHeld
  /\ held' = held + 1
  /\ waiting' = waiting - 1

Ship ==
  /\ held > 0
  /\ held' = held - 1
  /\ UNCHANGED waiting

Next ==
  \/ Load
  \/ Ship

Spec == Init /\ [][Next]_vars

Drains == <>(held = 0)
====
TLA
  cat >"${d}/Depot.cfg" <<'CFG'
SPECIFICATION Spec
CONSTANT Crates = 2
CONSTANT MaxHeld = 2
INVARIANT TypeOK
PROPERTY Drains
CFG
}

# mk_awkward <dir>: the maximally unidiomatic module, and the one part 3 uses
# to pin that there is no exit 1. SCREAMING_SNAKE and snake_case constants, no
# vars tuple at all, the behavior formula named something else, a box subscript
# naming one variable of two, a Next with no disjunction, and a config naming
# nothing.
#
# A PROPER-SUBSET SUBSCRIPT IS ROUTINE, not a defect:
# .claude/rules/tla-practice.md:450 counts 12 of 16 such box sites as sound
# where the action mentions only the subscripted variable. That is exactly why
# this fixture must still exit 0.
mk_awkward() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/thing.tla" <<'TLA'
---- MODULE thing ----
EXTENDS Naturals
CONSTANTS MAX_N, step_size

VARIABLES x, y

Init ==
  /\ x = 0
  /\ y = 0

Next ==
  /\ x < MAX_N
  /\ x' = x + step_size
  /\ UNCHANGED y

Behavior == Init /\ [][Next]_x
====
TLA
  cat >"${d}/thing.cfg" <<'CFG'
INIT Init
NEXT Next
CONSTANT MAX_N = 3
CONSTANT step_size = 1
CFG
}

# mk_wrapped <dir>: the continuation hazard, both halves of it.
#
# The CONSTANTS declaration wraps onto a second line, with a trailing comma
# ending the first and a `\*` comment ending the second, which is the exact
# shape of 30 sites in this repo's reference corpus (measured 2026-10-15).
# VARIABLES wraps the same way. And the config puts INVARIANT on one line with
# its name on the next, which TLC accepts.
#
# A LINE-BASED SCAN FAILS HERE AND PASSES EVERYTHING ELSE. It reads 2
# constants where there are 5, 1 variable where there are 2, and 0 invariants
# where there is 1.
mk_wrapped() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/Wrapped.tla" <<'TLA'
---- MODULE Wrapped ----
EXTENDS Naturals
CONSTANTS Pumps, Budget,
          Offline, GoingUp, Online     \* labels

VARIABLES
  pc,
  tank

vars == <<pc, tank>>

TypeOK ==
  /\ pc \in [Pumps -> {Offline, GoingUp, Online}]
  /\ tank \in 0..Budget

Init ==
  /\ pc = [p \in Pumps |-> Offline]
  /\ tank = Budget

Open(p) ==
  /\ pc[p] = Offline
  /\ pc' = [pc EXCEPT ![p] = GoingUp]
  /\ UNCHANGED tank

Run(p) ==
  /\ pc[p] = GoingUp
  /\ tank > 0
  /\ pc' = [pc EXCEPT ![p] = Online]
  /\ tank' = tank - 1

Next == \E p \in Pumps : Open(p) \/ Run(p)

Spec == Init /\ [][Next]_vars
====
TLA
  # The keyword and its name on separate lines, which is the config half of
  # the same hazard.
  cat >"${d}/Wrapped.cfg" <<'CFG'
SPECIFICATION
  Spec
CONSTANT Pumps = {p1, p2}
CONSTANT Budget = 2
CONSTANT Offline = Offline
CONSTANT GoingUp = GoingUp
CONSTANT Online = Online
INVARIANT
  TypeOK
CFG
}

# mk_existential <dir>: Next as an existential over ONE named parameterized
# action, which is the second shape the corpus counts (69 of 238, at
# .claude/rules/tla-practice.md:279).
#
# IT IS A FALSE-INLINE TRAP AND A camelBack FIXTURE AT ONCE. The Next
# delegates to `Step`, so it primes nothing and names actions; and `maxBal` is
# the camelBack shape that 10 of the 137 reference variable names take, with
# none being CamelCase.
mk_existential() {
  local d="$1"
  mkdir -p "$d"
  cat >"${d}/Procs.tla" <<'TLA'
---- MODULE Procs ----
EXTENDS Naturals
CONSTANT Procs

VARIABLES done, maxBal

vars == <<done, maxBal>>

Step(self) ==
  /\ self \notin done
  /\ done' = done \cup {self}
  /\ maxBal' = maxBal + 1

Next == \E self \in Procs : Step(self)

Init ==
  /\ done = {}
  /\ maxBal = 0

Spec == Init /\ [][Next]_vars
====
TLA
  cat >"${d}/Procs.cfg" <<'CFG'
SPECIFICATION Spec
CONSTANT Procs = {a, b}
CFG
}

# mk_lonely <dir> <extra-configs...>: a module with no config of its own name.
# Style needs no config at all, so the module is STILL measured -- it does not
# inherit check's pairing requirement, and that is the one place the two
# scripts deliberately part company.
mk_lonely() {
  local d="$1" c
  shift
  mkdir -p "$d"
  cat >"${d}/Lonely.tla" <<'TLA'
---- MODULE Lonely ----
VARIABLE z
vars == <<z>>
Init == z = 0
Next == z' = z
Spec == Init /\ [][Next]_vars
====
TLA
  for c in "$@"; do
    cat >"${d}/${c}" <<'CFG'
SPECIFICATION Spec
INVARIANT TypeOK
CFG
  done
}

# mk_leavings <dir>: the three kinds of leaving, which drop out of the measure
# for the reasons tla-rzvk.4 settled for check.
#
#   *_TTrace_*.tla   TLC's generated trace spec, skipped by name
#   states/          TLC's fingerprint cache, never descended into
#   *.tla.old        pcal's backup, which no *.tla glob matches
#
# THE TRACE SKIP EARNS ITS KEEP ON THE STYLE SIDE TOO, and for a sharper
# reason than on check's. A trace spec is TLC's own generated TLA+, so
# measuring its style reports the toolchain's habits as Frank's. Its
# identifiers are machine-named and its Next is nothing he wrote.
mk_leavings() {
  local d="$1"
  mkdir -p "${d}/states/26-10-15"
  cat >"${d}/Good.tla" <<'TLA'
---- MODULE Good ----
VARIABLE q
vars == <<q>>
TypeOK == q \in 0..1
Init == q = 0
Next == q' = 1 - q
Spec == Init /\ [][Next]_vars
====
TLA
  cat >"${d}/Good.cfg" <<'CFG'
SPECIFICATION Spec
INVARIANT TypeOK
CFG
  cat >"${d}/Good_TTrace_1792039041.tla" <<'TLA'
---- MODULE Good_TTrace_1792039041 ----
EXTENDS Good, TLCExt, Toolbox, Naturals, TLC
CONSTANTS _generated_a, _generated_b
VARIABLES trace_q
_SpecTETrace == TRUE
====
TLA
  cat >"${d}/Good.tla.old" <<'TLA'
---- MODULE Good ----
VARIABLE old_name
Init == old_name = 0
====
TLA
  cat >"${d}/states/26-10-15/Stale.tla" <<'TLA'
---- MODULE Stale ----
VARIABLE cached_thing
====
TLA
}

# dir_snapshot <dir>: every path under <dir> with its size, sorted. The
# instrument for "style wrote nothing", which is the assertion bead tla-rzvk.5
# exists because check cannot make.
dir_snapshot() {
  find "$1" -printf '%P %s\n' 2>/dev/null | sort
}

# ===========================================================================
# PART 1 — usage, resolution, every way to exit 3, and the ban on 1 and 2
# ===========================================================================
echo "== part 1: usage, resolution, and the exit codes that exist =="

run_style --help
rc_is "--help exits 0" 0
has   "--help names the command" "Usage: style"
has   "--help says there is no fail" "no exit 1"

run_style -x
rc_is "an unknown option is 3, not 1" 3

run_style one two
rc_is "two arguments is 3" 3
has   "and it says so" "one argument at most"

# No prompt for the slug. The bead names this as a way to reach 3.
run_style no-such-slug
rc_is "a slug with no prompt is 3" 3
has   "and the message names where it looked" "no prompt for 'no-such-slug'"

# Two prompts for one slug is a corpus bug and gets reported as one, exactly
# as check reports it. All 64 slugs are distinct across the eight families, so
# this is never a choice to make.
mk_prompt fam-a twinned
mk_prompt fam-b twinned
mk_pickers "${WORK}/twinned"
run_style twinned
rc_is "a slug matching two prompts is 3" 3
has   "and it is named as a corpus bug" "corpus bug"

# A directory that is not there.
mk_prompt fam-a 09-absent
run_style 09-absent
rc_is "a slug whose study directory is absent is 3" 3
has   "and the message says there is nothing to read" "is not a directory"

# A directory with no module in it at all.
mk_prompt fam-a 10-empty
mkdir -p "${WORK}/10-empty"
run_style 10-empty
rc_is "a directory with no module is 3" 3
has   "and the message names the directory" "10-empty"

# THE BAN ITSELF is pinned in part 3, on the worst fixture in the suite. What
# part 1 settles is the narrower half: every refusal on the usage surface is a
# 3 rather than a 1, so there is no path on which a bad invocation and a bad
# module report the same way.

# ===========================================================================
# PART 2 — the worked instance: all seven axes on the attempt Frank wrote
#
# Measured by hand off the fixture above, which is a transcription of
# ~/Study/tla-drills/01-slip-on-the-spike/pickers.tla as it stood 2026-10-15.
# ===========================================================================
echo "== part 2: the worked instance, all seven axes =="

mk_prompt fam-a 01-slip-on-the-spike
mk_pickers "${WORK}/01-slip-on-the-spike"
run_style 01-slip-on-the-spike

rc_is "the worked instance exits 0" 0
axis_line_count "seven axes, one line each" 7
has "the module line names the module and its config" "module=pickers config=pickers.cfg"
has "the trailer says it measured" "MEASURED:"

# AXIS 1, identifier case. Two snake_case constants and two lowercase
# variables, and every class is printed including the empty ones so the field
# is comparable across modules.
#
# CamelCase AND camelBack ARE SEPARATE CLASSES, and the reason is measured.
# Across the 498 reference modules, 10 of 137 variable names are camelBack and
# NONE is CamelCase, so an implementation that collapses the two reports an
# ordinary variable name as the one shape no variable in that body has.
axis_field "identifier case is measured over all four declared names" \
  identifier-case measured \
  'CamelCase:0,camelBack:0,ALLCAPS:0,snake_case:2,SCREAMING_SNAKE:0,short-lowercase:0,lowercase:2'
axis_field "and each name carries its own class" \
  identifier-case detail \
  'picker_count=snake_case,max_slips=snake_case,pickers=lowercase,slips=lowercase'
# C1 IS SILENT ON THIS AXIS AND THE FIELD SAYS SO RATHER THAN OMITTING IT. The
# survey counts what things are named and never how a name is cased, so a
# figure here would be invented. A dash is a fact; a missing field is not.
axis_field "C1 is silent, and the field carries a dash rather than a guess" \
  identifier-case corpus-c1 '-'
axis_field "and the C3 figure covers constants and variables separately" \
  identifier-case corpus-c3 \
  'constants:140-distinct,CamelCase-or-ALLCAPS:134,camelBack:0,snake_case:0,short-lowercase:6;variables:137-distinct,CamelCase:0,camelBack:10,snake_case:0,lowercase:127'

# AXIS 2, type invariants. Neither name shape nor body shape: SlipsNatural and
# NoDoublePicks are not Type-prefixed, and no definition gives both declared
# variables a membership clause.
axis_field "no type invariant is declared, by either shape" \
  type-invariants measured 'name-shape:none,body-shape:none'
axis_field "with the C1 Type-prefix count beside it" \
  type-invariants corpus-c1 'TypeOK:117/713,Type-prefixed:164/713'
axis_field "and the C3 count over the reference modules" \
  type-invariants corpus-c3 'declares-TypeOK:172/498'

# AXIS 3, the state tuple. It exists, it is called vars, and it covers both.
axis_field "the state tuple exists and covers every declared variable" \
  state-tuple measured 'tuple:vars,covers:2/2'
axis_field "and its members are named" state-tuple detail 'members:pickers,slips'
axis_field "against the C1 tuple count" \
  state-tuple corpus-c1 'plain-tuple-definitions:375,named-vars:181/375,vars-or-Vars-suffix:342/375'
axis_field "and the C3 one" state-tuple corpus-c3 'tuple-definitions:208,named-vars:203/208'

# AXIS 4, the behavior formula. Named Spec.
axis_field "the behavior formula is named Spec" behavior-formula measured 'name:Spec'
axis_field "against the C1 naming count" \
  behavior-formula corpus-c1 'named-Spec:170/205,SPECIFICATION-names-Spec:178/253'
axis_field "and the C3 one" \
  behavior-formula corpus-c3 'named-Spec:230/236,SPECIFICATION-names-Spec:469/540'

# AXIS 5, the box subscript. One site, subscript vars, which resolves through
# its definition to both declared variables.
axis_field "the one box site is subscripted over the full tuple" \
  box-subscript measured 'sites:1,full-tuple:1,proper-subset:0,unresolved:0'
axis_field "and the subscript is named with its coverage" \
  box-subscript detail 'vars=full,2/2'
axis_field "against the C1 subscript split" \
  box-subscript corpus-c1 'full-tuple:405/421,bare-vars:906/1182'
axis_field "and the C3 one" box-subscript corpus-c3 'bare-vars:253/298'

# AXIS 6, Next's shape. THE TEST IS A PRIME, NOT A DISJUNCTION, and this is
# the row that pins it. Frank's Next primes both declared variables itself,
# inside the quantifier, and carries one UNCHANGED, so the body wrote its own
# transition however its arms are laid out.
#
# THE OBVIOUS ALTERNATIVE WAS MEASURED AND IT FAILS BADLY. Splitting the body
# on `\/` and asking whether each arm is a bare operator name breaks the
# `\E ... :` structure, so a body that DELEGATES under a quantifier reads as
# inline: 60 false inline against 15 real over the 222 reference modules that
# define a top-level Next. The 05-procs and 04-wrapped rows in part 4 are the
# two that catch it, because both delegate under a binder.
axis_field "Next primes its own variables, so it wrote the transition inline" \
  next-shape measured 'shape:primes-inline,primed:2,unchanged:1'
axis_field "against both C1 shapes" \
  next-shape corpus-c1 'disjunction-of-named-actions:105/238,existential-over-named-action:69/238'
axis_field "and the C3 split the test comes from" \
  next-shape corpus-c3 'names-actions:207/222,primes-inline:15/222'

# AXIS 7, the config's obligations. Two invariants, no property.
axis_field "the config names two invariants and no property" \
  config-obligations measured 'invariants:2,properties:0'
# THE NAMES GO IN TWO FIELDS, NOT ONE. A single comma-joined list cannot say
# where the invariants stop and the properties start, which matters the moment
# a config names several of each.
axis_field "and both invariant names are printed" \
  config-obligations names-invariant 'SlipsNatural,NoDoublePicks'
axis_field "with the property list empty rather than absent" \
  config-obligations names-property '-'
# BOTH TIERS PRINT ON THE AXIS WHERE THEY CONFLICT. The published corpus runs
# a median of 2 named obligations and the reference configs a median of 1, and
# drill/study/STYLE.md rules that C3 governs here, because holding a
# two-variable drill to the published median would fire on most correct
# answers. The script prints both rather than picking, so the register is what
# does the ruling.
axis_field "the conflicting C1 median prints" \
  config-obligations corpus-c1 'median:2,mean:2.79,invariants:713,properties:226,no-property:220/337'
axis_field "and so does the C3 median that governs" \
  config-obligations corpus-c3 'median:1,mean:1.55,exactly-one:327/540'

# EVERY AXIS CARRIES BOTH TIERS AND NAMES EACH ONE. The field name IS the
# tier, so a figure can never reach the model unlabeled.
lines_matching "every axis line carries a C1 field" 7 '(^|[[:space:]])corpus-c1=[^[:space:]]+([[:space:]]|$)'
lines_matching "and a C3 field" 7 '(^|[[:space:]])corpus-c3=[^[:space:]]+([[:space:]]|$)'

# ===========================================================================
# PART 3 — the opposite corner, and the ban on judgment vocabulary
# ===========================================================================
echo "== part 3: the opposite corner, and no judgment anywhere =="

mk_prompt fam-a 02-depot
mk_textbook "${WORK}/02-depot"
run_style 02-depot

rc_is "the textbook module exits 0" 0
has "the module line names it" "module=Depot config=Depot.cfg"
axis_field "its constants are CamelCase" \
  identifier-case measured \
  'CamelCase:2,camelBack:0,ALLCAPS:0,snake_case:0,SCREAMING_SNAKE:0,short-lowercase:0,lowercase:2'
axis_field "TypeOK is found by both name shape and body shape" \
  type-invariants measured 'name-shape:TypeOK,body-shape:TypeOK'
axis_field "its vars tuple covers both" state-tuple measured 'tuple:vars,covers:2/2'
axis_field "its behavior formula is Spec" behavior-formula measured 'name:Spec'
axis_field "its subscript is the full tuple" \
  box-subscript measured 'sites:1,full-tuple:1,proper-subset:0,unresolved:0'
axis_field "and its Next names two actions and primes nothing itself" \
  next-shape measured 'shape:names-actions,primed:0,unchanged:0'
axis_field "with one invariant and one property named" \
  config-obligations measured 'invariants:1,properties:1'
axis_field "and the invariant name is printed" \
  config-obligations names-invariant 'TypeOK'
axis_field "and the property name in its own field" \
  config-obligations names-property 'Drains'

# THE MAXIMALLY UNIDIOMATIC MODULE STILL EXITS 0. This is the assertion that
# distinguishes a measuring script from a gate, and an implementation that
# scores the axes fails here and almost nowhere else.
mk_prompt fam-a 03-awkward
mk_awkward "${WORK}/03-awkward"
run_style 03-awkward

rc_is "the worst fixture in this suite still exits 0" 0
axis_line_count "and all seven axes still report" 7
axis_field "a SCREAMING_SNAKE constant is its own class, not snake_case" \
  identifier-case measured \
  'CamelCase:0,camelBack:0,ALLCAPS:0,snake_case:1,SCREAMING_SNAKE:1,short-lowercase:2,lowercase:0'
axis_field "and x and y read as short lowercase, not as words" \
  identifier-case detail 'MAX_N=SCREAMING_SNAKE,step_size=snake_case,x=short-lowercase,y=short-lowercase'
axis_field "no vars tuple at all" state-tuple measured 'tuple:none,covers:0/2'
axis_field "the behavior formula is not named Spec, and its name is reported" \
  behavior-formula measured 'name:Behavior'
axis_field "the subscript names one variable of two" \
  box-subscript measured 'sites:1,full-tuple:0,proper-subset:1,unresolved:0'
axis_field "and the subscript is named with its partial coverage" \
  box-subscript detail 'x=proper-subset,1/2'
axis_field "Next primes one variable and holds the other" \
  next-shape measured 'shape:primes-inline,primed:1,unchanged:1'
axis_field "and the INIT/NEXT config names no obligation" \
  config-obligations measured 'invariants:0,properties:0'

# NO JUDGMENT VOCABULARY, ON THE WORST FIXTURE IN THE SUITE. The script says
# what it measured and what the corpora counted, and stops.
#
# MATCHED AT A WORD START, NOT AS A BARE SUBSTRING, and the first draft of
# this loop got that wrong: a substring test for `fix` fires on
# `Type-prefixed:164/713`, which is a corpus figure. The anchor is a word
# start rather than a whole word so that a stem like `violat` still catches
# `violated` and `violation`.
for word in wrong should bad error unidiomatic violat incorrect improve prefer avoid fix; do
  if grep -qiE -- "(^|[^a-zA-Z])${word}" <<<"$OUT"; then
    nope "no judgment vocabulary: '${word}' appears in the output of the worst fixture"
  else
    ok "no judgment vocabulary: '${word}'"
  fi
done

# ===========================================================================
# PART 4 — the parsing hazards: wrapped declarations and wrapped config
# keywords
#
# THIS IS THE PART A LINE-BASED IMPLEMENTATION FAILS. Everything else in this
# file can be passed by reading the keyword's own line.
# ===========================================================================
echo "== part 4: declarations and config keywords that wrap =="

mk_prompt fam-a 04-wrapped
mk_wrapped "${WORK}/04-wrapped"
run_style 04-wrapped

rc_is "the wrapped fixture exits 0" 0
axis_field "all five constants are found, across the continuation line" \
  identifier-case measured \
  'CamelCase:5,camelBack:0,ALLCAPS:0,snake_case:0,SCREAMING_SNAKE:0,short-lowercase:1,lowercase:1'
axis_field "and both variables, declared under a bare VARIABLES keyword" \
  identifier-case detail \
  'Pumps=CamelCase,Budget=CamelCase,Offline=CamelCase,GoingUp=CamelCase,Online=CamelCase,pc=short-lowercase,tank=lowercase'
axis_field "the vars tuple covers both variables found that way" \
  state-tuple measured 'tuple:vars,covers:2/2'
axis_field "and the type invariant covers them both too" \
  type-invariants measured 'name-shape:TypeOK,body-shape:TypeOK'
axis_field "the config's invariant is found with its name on the next line" \
  config-obligations measured 'invariants:1,properties:0'
axis_field "and it is named" config-obligations names-invariant 'TypeOK'

# A BODY THAT DELEGATES UNDER A QUANTIFIER IS THE FALSE-INLINE CASE. Its Next
# reads `\E p \in Pumps : Open(p) \/ Run(p)`, which primes nothing itself: the
# actions it names do the priming. This is one of the two rows an arm-splitting
# implementation gets wrong, and the measured 60-against-15 false-inline rate
# is what that mistake costs over the reference corpus.
axis_field "a Next that delegates under a binder names actions" \
  next-shape measured 'shape:names-actions,primed:0,unchanged:0'

# THE SINGLE NAMED ACTION UNDER AN EXISTENTIAL is the corpus's second shape
# verbatim, `\E self \in Procs : Step(self)`, and it is the other false-inline
# case: one arm, no disjunction, and still delegating.
mk_prompt fam-a 05-procs
mk_existential "${WORK}/05-procs"
run_style 05-procs
rc_is "the existential fixture exits 0" 0
axis_field "one named action under a binder also names actions" \
  next-shape measured 'shape:names-actions,primed:0,unchanged:0'
# THE camelBack CLASS IS EXERCISED HERE, on `maxBal`, which is the shape 10 of
# the 137 reference variable names take.
axis_field "a camelBack variable is its own class" \
  identifier-case measured \
  'CamelCase:1,camelBack:1,ALLCAPS:0,snake_case:0,SCREAMING_SNAKE:0,short-lowercase:0,lowercase:1'
axis_field "and the detail names it" \
  identifier-case detail 'Procs=CamelCase,done=lowercase,maxBal=camelBack'
axis_field "the state tuple covers both" \
  state-tuple measured 'tuple:vars,covers:2/2'
axis_field "and the subscript is the full tuple here" \
  box-subscript measured 'sites:1,full-tuple:1,proper-subset:0,unresolved:0'

# ===========================================================================
# PART 5 — which modules get measured, which leavings get skipped, and that
# nothing is written and TLC never runs
# ===========================================================================
echo "== part 5: what gets measured, and what the run leaves behind =="

# A MODULE WITH NO CONFIG IS STILL MEASURED. This is the one place style
# deliberately parts company with check: measuring style needs no config at
# all, so check's pairing requirement is not inherited. Six axes have a value
# without a config and only the seventh does not.
mk_prompt fam-a 06-lonely
mk_lonely "${WORK}/06-lonely"
run_style 06-lonely
rc_is "a module with no config anywhere still exits 0" 0
has "and it is measured, with the config marked absent" "module=Lonely config=-"
axis_line_count "all seven axes still print" 7
axis_field "the six textual axes have real values" state-tuple measured 'tuple:vars,covers:1/1'
axis_field "and only the config axis has none" \
  config-obligations measured 'invariants:-,properties:-'
has "the reason the config is absent is on a line of its own" \
  "config NOT CHOSEN: no Lonely.cfg, and no other config in the directory"

# ONE CONFIG IN THE DIRECTORY IS BORROWED, which is the rule tla-rzvk.4
# settled and the bead says applies here too.
mk_prompt fam-a 07-borrowed
mk_lonely "${WORK}/07-borrowed" Other.cfg
run_style 07-borrowed
rc_is "a borrowed config exits 0" 0
has "and the borrowed config is on the module line" "module=Lonely config=Other.cfg"
axis_field "its one invariant is counted" config-obligations measured 'invariants:1,properties:0'
hasnt "with no NOT CHOSEN line" "config NOT CHOSEN"

# TWO CONFIGS AND NO OWN ONE IS NOT A CHOICE TO MAKE. The module is still
# measured on the six textual axes, and the config axis says why it has none.
mk_prompt fam-a 08-ambiguous
mk_lonely "${WORK}/08-ambiguous" A.cfg B.cfg
run_style 08-ambiguous
rc_is "two configs and no own one still exits 0" 0
has "the module is still measured" "module=Lonely config=-"
has "and the reason names both candidates" \
  "config NOT CHOSEN: no Lonely.cfg, and 2 configs to choose from: A.cfg, B.cfg"
axis_field "the config axis has no value" \
  config-obligations measured 'invariants:-,properties:-'
axis_field "and the textual axes still do" behavior-formula measured 'name:Spec'

# THE THREE LEAVINGS. One module measured, and the trace spec, the backup and
# the fingerprint cache all absent from the output.
mk_prompt fam-a 09-leavings
mk_leavings "${WORK}/09-leavings"
BEFORE="$(dir_snapshot "${WORK}/09-leavings")"
run_style 09-leavings
rc_is "the leavings fixture exits 0" 0
lines_matching "exactly one module line" 1 '^module='
has   "the real module is measured" "module=Good config=Good.cfg"
hasnt "TLC's trace spec is not" "Good_TTrace_"
hasnt "nor its machine-generated constants" "_generated_a"
hasnt "pcal's backup is not" "old_name"
hasnt "and states/ is never descended into" "cached_thing"

# NOTHING WAS WRITTEN. This is the assertion bead tla-rzvk.5 exists because
# check cannot make, and the bead forbids outright: nothing style writes may
# create a file in the directory it is measuring.
AFTER="$(dir_snapshot "${WORK}/09-leavings")"
if [ "$BEFORE" = "$AFTER" ]; then
  ok "the work directory is byte-for-byte unchanged after a run"
else
  nope "the work directory changed. before: ${BEFORE} after: ${AFTER}"
fi

# AND TLC NEVER RAN. Asserted by taking it off the path entirely and getting
# the same answer, which is stronger than asserting the absence of leavings:
# a run that started TLC and tidied up after itself would pass the snapshot
# above and fail here.
run_style_without_tlc 01-slip-on-the-spike
rc_is "with tlc off the path, the worked instance still exits 0" 0
axis_line_count "and all seven axes still report" 7
axis_field "with the same measured value on the axis TLC could not help with" \
  next-shape measured 'shape:primes-inline,primed:2,unchanged:1'
hasnt "and nothing says tlc is missing" "tlc"

# TWO MODULES IN ONE DIRECTORY ARE BOTH MEASURED, which is Frank's workflow:
# write it, run it, change one thing, run it again.
mk_prompt fam-a 10-two-models
mk_pickers "${WORK}/10-two-models"
cp "${WORK}/10-two-models/pickers.tla" "${WORK}/10-two-models/pickers_collision.tla"
# Rename the module header so the file is a module of its own name.
sed -i 's/MODULE pickers /MODULE pickers_collision /' "${WORK}/10-two-models/pickers_collision.tla"
run_style 10-two-models
rc_is "two models in one directory exits 0" 0
lines_matching "both module lines print" 2 '^module='
axis_line_count "and both get all seven axes" 14
has "the second model borrows the one config" "module=pickers_collision config=pickers.cfg"

# RESOLUTION FROM INSIDE THE DIRECTORY, which is where Frank stands.
run_style_in "${WORK}/01-slip-on-the-spike"
rc_is "the no-argument form from inside the directory exits 0" 0
has "and resolves the same slug" "module=pickers config=pickers.cfg"

# ===========================================================================
# PART 6 — the one per-item suppression
#
# drill/study/CLAUDE.md's third prohibition is "NEVER name the construct
# that's missing", and the type-invariant axis is the one axis that collides
# with it. Measured over all 64 META.md files (epic tla-iiow): 9 items name a
# type invariant in a construct bullet, and exactly ONE drills the idiom
# itself. On that item a fact about the type invariant IS the answer.
#
# ONE ITEM, ONE AXIS. The suppression must not reach the other six axes and
# must not reach any other slug, and both halves are asserted.
# ===========================================================================
echo "== part 6: the one per-item suppression =="

mk_prompt fam-a 04-lift-types
mk_pickers "${WORK}/04-lift-types"
run_style 04-lift-types

rc_is "the drilled item still exits 0" 0
axis_line_count "six axes report, not seven" 6
hasnt "and the type-invariant axis is not among them" "axis=type-invariants measured="
has "it is named as suppressed, with the reason" \
  "axis=type-invariants SUPPRESSED:"
has "and the trailer counts it" "1 suppressed"
axis_field "the other six axes are untouched" \
  identifier-case measured \
  'CamelCase:0,camelBack:0,ALLCAPS:0,snake_case:2,SCREAMING_SNAKE:0,short-lowercase:0,lowercase:2'
axis_field "including the one next to it" state-tuple measured 'tuple:vars,covers:2/2'

# THE SUPPRESSION IS KEYED ON THE SLUG AND NOTHING ELSE. The same module under
# any other slug reports the axis, which is what keeps this from being a
# blanket exclusion of the axis.
run_style 01-slip-on-the-spike
axis_field "the same module under another slug reports the axis" \
  type-invariants measured 'name-shape:none,body-shape:none'
hasnt "and nothing is suppressed there" "SUPPRESSED"

# ===========================================================================
printf '\n'
if [ "$fail_count" -eq 0 ]; then
  printf 'OK: %d assertions passed.\n' "$pass_count"
  exit 0
fi
printf 'FAILED: %d of %d assertions failed.\n' "$fail_count" "$((pass_count + fail_count))" >&2
exit 1
