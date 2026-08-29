#!/usr/bin/env bash
# selftest.sh — Executable spec for harness/grade.sh (bead tla-kl5.5, V2-PLAN.md 5.2).
#
# THE RED LINE THIS PINS, verbatim from the bead:
#
#   GIVEN a reference PHI and a student spec PSI that is simultaneously too
#   strong on one conjunct and too weak on another, WHEN grade.sh runs, THEN
#   it reports BOTH an over-constraint witness and an under-constraint
#   witness, and the verdict object contains no reference conjunct text.
#
# That is the `both-at-once` block below. The other fixtures exist to stop the
# two halves of it being satisfied by accident: `too-weak` and `too-strong`
# prove each flag can be raised ALONE, so `both-at-once` raising both is not
# just a grader that always raises both.
#
# Four kinds of assertion:
#
#   Behavioural — run grade.sh over a fixture submission and require the exit
#     status and named fields of the verdict object.
#
#   Anti-leak — recompute, INDEPENDENTLY of grade.sh's own guard, the set of
#     identifiers that occur in the reference package and not in the
#     submission, and require none of them in the emitted object. grade.sh's
#     gate is a WHITELIST (only known-safe strings may be emitted); this is a
#     BLACKLIST over the same output. Two differently-shaped checks, so a bug
#     in one is not inherited by the other.
#
#   Fail-closed — drive the leak gate with a canary and require grade.sh to
#     emit NOTHING and exit 5. A guard that has never been seen to fire is not
#     evidence of anything.
#
#   Structural — read grade.sh itself and require the constraints no fixture
#     can observe: TLC is reached only through harness/verdict.sh, and TLC's
#     console output is never captured, let alone matched.
#
# Usage:  harness/fixtures/grade/selftest.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

GRADE="harness/grade.sh"
PROBLEM="harness/fixtures/grade/lockbox"
REFDIR="$PROBLEM/reference"
SUBDIR="$PROBLEM/submissions"

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

# ---------------------------------------------------------------------------
# Fixture driver. Leaves the verdict object in $GOT_JSON and the exit status
# in $GOT_RC so a block of assertions can interrogate one run.
# ---------------------------------------------------------------------------
GOT_JSON=""
GOT_RC=0
GOT_ERR=""

run_fixture() {
  local sub="$1"
  GOT_ERR=$(mktemp)
  GOT_JSON=$(bash "$GRADE" --reference "$REFDIR" --submission "$SUBDIR/$sub" \
                           --problem-id lockbox 2>"$GOT_ERR")
  GOT_RC=$?
}

# assert_rc <label> <want>
assert_rc() {
  if [ "$GOT_RC" = "$2" ]; then
    ok "$1 — exit $2"
  else
    nope "$1 — wanted exit $2, got $GOT_RC$([ -s "$GOT_ERR" ] && echo " (stderr: $(head -c 300 "$GOT_ERR" | tr '\n' ' '))")"
  fi
}

# assert_json <label> <jq-filter> <want>
assert_json() {
  local label="$1" filter="$2" want="$3" got
  got=$(printf '%s' "$GOT_JSON" | jq -r "$filter" 2>/dev/null)
  if [ "$got" = "$want" ]; then
    ok "$label — $filter = $want"
  else
    nope "$label — $filter: wanted '$want', got '$got'"
  fi
}

# ---------------------------------------------------------------------------
# Anti-leak: identifiers that occur in the reference package and NOT in the
# submission package, both with TLA+ comments stripped. Comment stripping is
# what keeps this from degenerating into a list of English words -- the
# reference's own header talks about grading, observations and submissions,
# and every one of those words is legitimate schema vocabulary.
# ---------------------------------------------------------------------------
ref_only_identifiers() {
  local refdir="$1" subdir="$2"
  python3 - "$refdir" "$subdir" <<'PY'
import re, sys, pathlib

def strip(text):
    # TLA+ block comments nest; a depth counter is the only correct reading.
    out, depth, i = [], 0, 0
    while i < len(text):
        if text.startswith("(*", i):
            depth += 1; i += 2; continue
        if text.startswith("*)", i) and depth:
            depth -= 1; i += 2; continue
        if depth == 0 and text.startswith("\\*", i):
            j = text.find("\n", i)
            i = len(text) if j < 0 else j
            continue
        if depth == 0:
            out.append(text[i])
        i += 1
    return "".join(out)

def idents(d):
    s = set()
    for p in sorted(pathlib.Path(d).glob("*.tla")):
        s.update(re.findall(r"[A-Za-z][A-Za-z0-9_]*", strip(p.read_text())))
        s.add(p.stem)          # the module name, which is also the file name
    return s

ref, sub = sys.argv[1], sys.argv[2]
for name in sorted(idents(ref) - idents(sub)):
    if len(name) >= 3:
        print(name)
PY
}

# assert_no_leak_at <label> <reference-dir> <submission-dir>
#
# BOTH DIRECTORIES ARE ARGUMENTS, and the reason is a bug this check caught in
# itself. They used to be the `lockbox` globals, so calling it for a submission
# under any other problem silently compared the object against a submission
# directory that does not exist. idents(sub) came back empty, every reference
# identifier counted as reference-only, and the check reported a leak that was
# not there. A blacklist over the wrong baseline fails in both directions;
# this one happened to fail loudly.
assert_no_leak_at() {
  local label="$1" refdir="$2" subdir="$3" hits=""
  local name
  while read -r name; do
    [ -z "$name" ] && continue
    # Here-string, not a pipe: `printf ... | grep -q` under `pipefail` returns
    # 141 when grep exits on its first match while the producer is still
    # writing, and this `if` would read that as "identifier absent" -- i.e. the
    # leak check would pass without having run. Bead tla-kr9.
    if grep -qE -- "(^|[^A-Za-z0-9_])${name}([^A-Za-z0-9_]|$)" <<<"$GOT_JSON"; then
      hits="$hits $name"
    fi
  done < <(ref_only_identifiers "$refdir" "$subdir")
  if [ -z "$hits" ]; then
    ok "$label"
  else
    nope "$label — reference-only identifiers found in the verdict object:$hits"
  fi
}

# assert_no_leak <label> <submission-dir-name>   -- the lockbox problem.
assert_no_leak() {
  assert_no_leak_at "$1" "$REFDIR" "$SUBDIR/$2"
}

# ---------------------------------------------------------------------------
# Structural helpers, copied in shape from harness/test-verdict.sh: read the
# script with whole-line comments removed, because this file's own header
# names the constructs the checks police.
# ---------------------------------------------------------------------------
# Captured once, matched through here-strings. The original note here said
# `grep -q` had to be avoided because `grade_code | grep -q` SIGPIPEs sed under
# `pipefail`. That diagnosis was right; the remedy was aimed one step short of
# the cause. It is the PIPE that is unsafe, not `-q`: measured 2026-08-07 on
# bash 5.2.21, `printf '%s\n' "$captured" | grep -q` returns 141 at exactly the
# same sizes as the uncaptured form, because the printf builtin forks into the
# pipeline and takes SIGPIPE just as sed did. With the pipe gone, `-q` is safe
# again and reads correctly. Bead tla-kr9.
if [ ! -f "$GRADE" ]; then
  echo "FATAL: $GRADE does not exist" >&2
  exit 1
fi
GRADE_CODE=$(sed 's/^[[:space:]]*#.*$//' "$GRADE")

assert_absent() {
  local label="$1" pattern="$2" hits
  hits=$(grep -nE -- "$pattern" <<<"$GRADE_CODE")
  if [ -z "$hits" ]; then
    ok "$label"
  else
    local flat
    flat=$(tr '\n' ' ' <<<"$hits")
    nope "$label — found: ${flat:0:200}"
  fi
}

assert_present() {
  local label="$1" pattern="$2"
  if grep -qE -- "$pattern" <<<"$GRADE_CODE"; then
    ok "$label"
  else
    nope "$label — pattern not found: $pattern (searched $(grep -c '' <<<"$GRADE_CODE") lines of $GRADE)"
  fi
}

# ===========================================================================
echo "== the RED line: too strong on one conjunct AND too weak on another =="
# ===========================================================================

run_fixture both-at-once
assert_rc   "both-at-once graded as a failure" 1

assert_json "both-at-once is reported under-constrained" \
  '.under_constrained' 'true'
assert_json "both-at-once is reported over-constrained" \
  '.over_constrained' 'true'

# The two flags are INDEPENDENT and both are allowed. 23.6% of wrong models
# are this shape, so a grader that can only report one of them misgrades a
# quarter of the failures.
assert_json "an under-constraint witness is emitted" \
  '.witnesses.under_constraint | type' 'object'
assert_json "an over-constraint witness is emitted" \
  '.witnesses.over_constraint | type' 'object'
assert_json "exactly one witness of each kind" \
  '.witnesses | length' '2'

# The over-constraint witness is a LOCATION in the submission's own source
# (V2-PLAN.md 3.7). It names the submission's requirement, never a reference
# conjunct.
assert_json "the over-constraint witness names the submission's requirement" \
  '.witnesses.over_constraint.obligation' 'Req_never_three'
assert_json "the over-constraint witness locates it in the submission" \
  '.witnesses.over_constraint.location.module' 'LockboxObl'

# The under-constraint witness carries an OPAQUE reference obligation id and a
# location in the submission's spec -- never the reference's conjunct.
assert_json "the under-constraint obligation id is opaque" \
  '.witnesses.under_constraint.obligation | test("^R-[0-9a-f]{6}$")' 'true'
assert_json "the under-constraint witness locates a submission module" \
  '.witnesses.under_constraint.location.module' 'Lockbox'

assert_no_leak "the verdict object contains no reference conjunct text" both-at-once

echo
# ===========================================================================
echo "== each flag can be raised ALONE, so raising both is not the default =="
# ===========================================================================

run_fixture too-weak
assert_rc   "too-weak graded as a failure" 1
assert_json "too-weak is under-constrained"     '.under_constrained' 'true'
assert_json "too-weak is NOT over-constrained"  '.over_constrained'  'false'
assert_json "too-weak emits no over-constraint witness" \
  '.witnesses.over_constraint' 'null'
# Per-conjunct partial credit: one reference obligation met, one unmet.
assert_json "partial credit: 1 of 2 reference obligations met" \
  '[.suites.Adequacy.met, .suites.Adequacy.total] | join("/")' '1/2'
assert_json "too-weak passes the Relational suite" \
  '.suites.Relational.status' 'PASS'
assert_no_leak "too-weak verdict object is leak-free" too-weak

run_fixture too-strong
assert_rc   "too-strong graded as a failure" 1
assert_json "too-strong is over-constrained"      '.over_constrained'  'true'
assert_json "too-strong is NOT under-constrained" '.under_constrained' 'false'
assert_json "too-strong emits no under-constraint witness" \
  '.witnesses.under_constraint' 'null'
# The whole point of the Relational suite: a spec that admits fewer behaviours
# satisfies MORE reference obligations, so obligation 1 alone passes it.
assert_json "obligation 1 alone sees nothing wrong with it" \
  '.suites.Adequacy.status' 'PASS'
assert_json "the Relational suite is what rejects it" \
  '.suites.Relational.status' 'FAIL'
assert_no_leak "too-strong verdict object is leak-free" too-strong

# Over-constraint BY OMISSION, which is the form learners actually produce.
# This submission states no requirement at all, so `PHI => psi_j` has nothing
# to refute and the landmark member is the only thing that can catch it.
run_fixture strict-and-silent
assert_rc   "strict-and-silent graded as a failure" 1
assert_json "a submission with no obligations module still grades" \
  '.verdict' 'FAIL'
assert_json "obligation 2 has nothing to refute" \
  '[.suites.Relational.met, .suites.Relational.total] | join("/")' '0/1'
assert_json "the landmark member is what catches it" \
  '.witnesses.over_constraint.kind' 'reference-observation-unreachable'
assert_json "the landmark id is opaque" \
  '.witnesses.over_constraint.obligation | test("^L-[0-9a-f]{6}$")' 'true'
assert_json "and it is over-constraint, not under-constraint" \
  '[.under_constrained, .over_constrained] | @csv' 'false,true'
assert_no_leak "strict-and-silent verdict object is leak-free" strict-and-silent

echo
# ===========================================================================
echo "== correct but structurally unlike the reference must PASS =="
# ===========================================================================

# V2-PLAN.md 3.5. Over ~96,000 Alloy submissions the instructor's oracle ranks
# #1 among correct forms for only 33% of exercises and is absent entirely in
# 18.6%. This fixture models the same system with a different variable, a
# different type and twice the states.
run_fixture correct-different
assert_rc   "correct-different graded as a pass" 0
assert_json "correct-different verdict"            '.verdict'           'PASS'
assert_json "correct-different not under"          '.under_constrained' 'false'
assert_json "correct-different not over"           '.over_constrained'  'false'
assert_json "correct-different not vacuous"        '.vacuous'           'false'
assert_json "correct-different emits no witnesses" '.witnesses | length' '0'
assert_no_leak "correct-different verdict object is leak-free" correct-different

echo
# ===========================================================================
echo "== obligation 3 is load-bearing: a vacuous spec satisfies 1 trivially =="
# ===========================================================================

run_fixture vacuous
assert_rc   "vacuous graded as a failure" 1
assert_json "the vacuity suite is what fails it" '.suites.NonVacuity.status' 'FAIL'
assert_json "vacuous is flagged"                 '.vacuous'                  'true'

# THE POINT OF THIS FIXTURE. Without obligation 3 this submission grades
# perfect on obligation 1: an empty state space satisfies every safety
# property there is. Asserting `met == total` here keeps that visible in the
# fixture matrix instead of only in a comment.
assert_json "obligation 1 alone grades it PERFECT" \
  '.suites.Adequacy.met == .suites.Adequacy.total' 'true'
assert_json "obligation 1 alone reports a pass" '.suites.Adequacy.status' 'PASS'

# An unsatisfiable Init is also the MAXIMALLY over-constrained spec -- it
# refines everything, which is why whole-spec refinement against a gold
# reference passes it (verified rc=0 against TLAiBench's own Gold!Refinement).
# Reporting that alongside the vacuity failure is not double-counting; the two
# facts are independent and both are true.
assert_json "it is reported over-constrained as well" '.over_constrained' 'true'
assert_no_leak "vacuous verdict object is leak-free" vacuous

echo
# ===========================================================================
echo "== a submission that does not parse is INVALID, never a grade =="
# ===========================================================================

run_fixture unparseable
assert_rc   "unparseable exits 3" 3
assert_json "unparseable verdict"        '.verdict' 'INVALID'
assert_json "the reason comes from the verdict channel" \
  '.reasons | index("PARSE_ERROR") != null' 'true'
assert_json "no suite result is invented for it" '.suites' 'null'

echo
# ===========================================================================
echo "== a structureless spec must NOT grade clean =="
# ===========================================================================

# Beads tla-59s and tla-x8s, which are one defect. Until they landed every
# reference obligation was a single-state predicate over one observation, and
# no single-state predicate can constrain a transition relation -- so the
# maximally permissive spec whose reachable observation set equals the
# admissible one passed obligation 1 BY CONSTRUCTION, for any reference.
#
# The `stepwise` problem is the same lockbox with the "one at a time" half
# stated as a Step_*(o, p) over a PAIR of successive observations.
#
# READ THE chaos-observations FIXTURE BEFORE CHANGING ANYTHING HERE. Its
# observation operator is maximally HONEST -- the variable is the observation
# -- so nothing in this block is about catching a lie. It is about a spec with
# no transition structure at all, and it graded PASS with zero witnesses
# against the state-only `lockbox` reference as it stood before tla-x8s.
#
# THAT MEASUREMENT NO LONGER REPRODUCES. `lockbox` was one of the packages the
# chaos probe refuses, so tla-x8s repaired it, and its observation now carries
# a `full` flag this submission does not define -- INVALID, exit 3, rather
# than a PASS. The reproducible form of the same fact is the `chaos-probe`
# package further down, where the reference that admits chaos is kept broken.
STEP_REF="harness/fixtures/grade/stepwise/reference"
STEP_SUB="harness/fixtures/grade/stepwise/submissions"

run_step() {
  GOT_ERR=$(mktemp)
  GOT_JSON=$(bash "$GRADE" --reference "$STEP_REF" --submission "$STEP_SUB/$1" \
                           --problem-id stepwise 2>"$GOT_ERR")
  GOT_RC=$?
}

run_step chaos-observations
assert_rc   "a structureless submission is graded a failure" 1
assert_json "and it is reported under-constrained" '.under_constrained' 'true'
assert_json "and a witness is emitted for it" \
  '.witnesses.under_constraint.kind' 'reference-obligation-unmet'
# The step obligation is the ONLY member it misses. Its reachable observations
# are exactly the admissible ones, so every single-state requirement holds and
# both landmarks are reached -- which is why nothing else in the object moves,
# and why nothing but a two-state obligation could have caught it.
assert_json "the one-state half of the suite still sees nothing wrong" \
  '[.suites.Adequacy.met, .suites.Adequacy.total] | join("/")' '1/2'
assert_json "and the Relational suite sees nothing wrong either" \
  '.suites.Relational.status' 'PASS'
assert_json "the step obligation is reported under an opaque id" \
  '.suites.Adequacy.unmet[0] | test("^R-[0-9a-f]{6}$")' 'true'
assert_no_leak_at "the stepwise verdict object is leak-free" \
  "$STEP_REF" "$STEP_SUB/chaos-observations"

# A step obligation is a new way for the grader to be WRONG as well as a new
# thing for it to catch. Both honest submissions must still pass, at two
# different representations -- the second counts the same parcels as a SET,
# which is V2-PLAN.md 3.5's fixture restated under the step channel.
run_step correct
assert_rc   "an honest submission still passes under a step obligation" 0
assert_json "correct emits no witnesses" '.witnesses | length' '0'

run_step correct-different
assert_rc   "and so does a correct submission at another representation" 0
assert_json "correct-different is not under-constrained" '.under_constrained' 'false'
assert_json "correct-different is not over-constrained"  '.over_constrained'  'false'

echo
# ===========================================================================
echo "== the trapdoor inside the fix: a frozen observation =="
# ===========================================================================

# [][A]_Observe unfolds to `A \/ UNCHANGED Observe`, so a submission whose
# observation never moves satisfies EVERY step obligation vacuously. That is
# the frozen-mapping hole from the TLAiBench survey 6 reappearing inside the
# fix for it, and no amount of care inside Step_onestep closes it -- the
# obligation is never the disjunct that gets taken.
run_step frozen-observe
assert_rc   "a frozen observation is graded a failure" 1
# It passes BOTH Adequacy members, step obligation included. Asserting that
# here rather than only asserting the verdict is what keeps the reason visible:
# if this ever reads 1/2, the fixture has stopped exercising the trapdoor and
# is passing for some other reason.
assert_json "it satisfies the step obligation vacuously (2 of 2)" \
  '[.suites.Adequacy.met, .suites.Adequacy.total] | join("/")' '2/2'
assert_json "the landmark suite is what catches it" \
  '.witnesses.over_constraint.kind' 'reference-observation-unreachable'
assert_json "and it is over-constraint, not under-constraint" \
  '[.under_constrained, .over_constrained] | @csv' 'false,true'

echo
# ===========================================================================
echo "== so the landmark requirement is a GATE, not a note in a header =="
# ===========================================================================

# Since the landmark suite is the only thing standing between a step
# obligation and the frozen-mapping trapdoor, a problem that states a Step_*
# and cannot run that probe is a broken problem. grade.sh refuses the PACKAGE
# for it -- exit 2, the author's defect, never a verdict about a submission.
#
# Both halves are checked, and the second fixture is why the first is not
# enough on its own: counting landmarks does not tell you whether one
# observation satisfies two of them.
# The submission and the problem id are OPTIONAL ARGUMENTS, added for bead
# tla-x8s, which refuses a package for a reason of its own and brings its own
# fixtures to do it. Both default to what the two call sites below already
# passed, so those are unchanged.
#
# The stderr goes in a global instead of being deleted. A refusal that does not
# say whose defect it is sends a problem author hunting through the submission,
# so what it names is worth asserting rather than only reporting on a failure.
PKG_ERR=""
assert_package_refused() {
  local label="$1" refdir="$2" subdir="${3:-$STEP_SUB/correct}" pid="${4:-stepwise}"
  local out rc
  PKG_ERR=$(mktemp)
  out=$(bash "$GRADE" --reference "$refdir" --submission "$subdir" \
                      --problem-id "$pid" 2>"$PKG_ERR")
  rc=$?
  if [ "$rc" != "2" ]; then
    nope "$label — wanted exit 2, got $rc (stderr: $(tr '\n' ' ' <"$PKG_ERR" | cut -c1-200))"
  elif [ -n "$out" ]; then
    nope "$label — a refused package emitted a verdict object"
  else
    ok "$label — exit 2, nothing printed"
  fi
}

assert_package_refused "a step obligation with one landmark is refused" \
  harness/fixtures/grade/stepwise/reference-one-landmark
assert_package_refused "a step obligation with OVERLAPPING landmarks is refused" \
  harness/fixtures/grade/stepwise/reference-overlapping

# And the requirement is conditional on Step_*, not universal. The `lockbox`
# reference states one landmark and no step obligation, and it still grades:
# every fixture above it in this file runs against it.
#
# WHAT MAKES IT LEGITIMATE MOVED UNDER BEAD tla-x8s, so read this assertion as
# the narrow claim it is. Stating no Step_* is what excuses the second
# landmark. It is not what excuses the package, and until tla-x8s landed
# `lockbox` had nothing else going for it: two requirements true of every
# record its own observation could take, which is the shape the chaos probe in
# the next block refuses. The reference was repaired rather than dropped. It
# gained an ObsDomain, a derived `full` flag beside the level in the
# observation, and one requirement relating the two, so chaos over the record
# type breaks it and the package now stands on its own account. The Step_*
# clause survived that repair untouched, which is why this assertion reads
# exactly as it did before.
run_fixture correct-different
assert_rc "a problem with no Step_* keeps its single landmark" 0

echo
# ===========================================================================
echo "== an obligation set that cannot tell chaos from the system is refused =="
# ===========================================================================

# Bead tla-x8s, the consequence half of tla-59s. Everything above grades a
# SUBMISSION. Nothing above asks whether the REFERENCE says enough to grade
# against, and grade.sh computes the Adequacy denominator from whatever the
# author happened to write. So a problem whose obligations are all true of a
# spec with no transition structure grades that spec a clean PASS, and reports
# a full score while doing it.
#
# The gate is a PROBE, not a rule about what a reference must contain.
# grade.sh generates the chaos submission over the obligations module's
# declared ObsDomain (`Init == obs \in ObsDomain`, `Next == obs' \in
# ObsDomain`, `Observe == obs`) and refuses the PACKAGE when that submission
# satisfies the whole obligation set. Exit 2, the author's defect, and never a
# verdict about a submission.
#
# WHY A PROBE RATHER THAN "EVERY REFERENCE MUST STATE A Step_*". The syntactic
# form is a stand-in for the property actually wanted, and it fails in both
# directions. A vacuous Step_* satisfies it while refusing nothing, and a
# business-rule problem with no concurrency in it would have to invent a
# transition obligation to get past it. `reference-state-refuses` below states
# no Step_* at all and refuses chaos on a one-state requirement, so it goes red
# if anyone builds the stand-in.
CHAOS="harness/fixtures/grade/chaos-probe"
CHAOS_SUB="$CHAOS/submissions/paired"

run_chaos() {
  GOT_ERR=$(mktemp)
  GOT_JSON=$(bash "$GRADE" --reference "$CHAOS/$1" --submission "$CHAOS_SUB" \
                           --problem-id chaos-probe 2>"$GOT_ERR")
  GOT_RC=$?
}

# Direction one. Measured against a hand-built probe before this assertion was
# written: chaos over `[level: 0..3, full: BOOLEAN]` grades PASS, Adequacy 1/1,
# Relational 1/1, zero witnesses. Every obligation the package states is true
# of a box whose contents teleport, so the package cannot grade.
assert_package_refused "an obligation set satisfied by chaos is refused" \
  "$CHAOS/reference-admits-chaos" "$CHAOS_SUB" chaos-probe

# And it says whose defect it is. The submission here is correct, so a refusal
# that names nothing sends the author to the one file that is not at fault.
if grep -qE -- 'AdmitsChaosRefObl' "$PKG_ERR"; then
  ok "the refusal names the reference obligations module"
else
  nope "the refusal does not name the reference obligations module: $(tr '\n' ' ' <"$PKG_ERR" | cut -c1-200)"
fi

# Direction two, on the SAME submission, which is what makes direction one a
# fact about the reference rather than about the spec beside it. Measured
# against the probe: FAIL, Adequacy 1/2, the step obligation unmet.
run_chaos reference-step-refuses
assert_rc   "a package whose Step_* refuses chaos stands" 0
assert_json "and it grades the submission the other package was refused beside" \
  '.verdict' 'PASS'

# Direction two again, with no Step_* anywhere in the module. Chaos over the
# record type reaches `[level |-> 0, full |-> TRUE]`, a box calling itself full
# while it is empty, and one requirement relating the two fields is false
# there. Measured against the probe: FAIL, Adequacy 0/1.
run_chaos reference-state-refuses
assert_rc   "a package with no Step_* stands when its own requirements refuse chaos" 0
assert_json "and it grades the same submission PASS" '.verdict' 'PASS'

echo
# ===========================================================================
echo "== a check that never ran is INVALID, and never a harness error =="
# ===========================================================================

# Bead tla-tkzt. 75, 76 and 77 are the evaluation-failure rows of 5.1: the
# spec did not evaluate, the invariant blew up mid-evaluation, or TLC refused
# the temporal formula. Nothing is known about whether the obligation holds.
#
# They used to fall through classify's catch-all to die_harness, so a
# submission whose observation record had the wrong shape crashed the grader
# with exit 4 -- which tells a learner nothing and tells whoever is running
# the batch that the harness is broken when it is not. Getting the graded
# interface wrong is a learner error and grades INVALID like every other one.
run_fixture wrong-shaped-observation
assert_rc   "a wrong-shaped observation exits 3, not 4" 3
assert_json "a wrong-shaped observation is INVALID" '.verdict' 'INVALID'
# The reason is the CHANNEL's own token. 75 is a family -- at least four EC
# constants route to it -- so the object says the spec did not evaluate and
# never guesses which of them it was.
assert_json "the reason is the verdict channel's evaluation-failure token" \
  '.reasons | index("SPEC_EVAL_FAILURE") != null' 'true'
assert_json "no suite result is invented for it" '.suites' 'null'
assert_no_leak "wrong-shaped-observation verdict object is leak-free" wrong-shaped-observation

echo
# ===========================================================================
echo "== a constants fragment carries CONSTANT assignments and nothing else =="
# ===========================================================================

# Bead tla-j8yd, the third site of a class refinement.sh (tla-nesz) and
# seeded-bugs.sh (tla-40y) already close. constants.cfg is the only text from
# a problem package that reaches a generated judge .cfg, so it is the one
# place the harness's ownership of that .cfg can leak.
#
# The fixture's fragment rides a BLOCK COMMENT -- `(* pad *) INVARIANT TypeOK`
# -- because TLC's .cfg parser is token-oriented and only `\*` comments out
# the rest of a line. A guard anchored at the start of a line sees nothing
# there. That is exactly how tla-nesz's hole worked.
smug_err=$(mktemp)
smug_out=$(bash "$GRADE" \
  --reference   harness/fixtures/grade/smuggled-constants/reference \
  --submission  harness/fixtures/grade/smuggled-constants/submissions/typeok \
  --problem-id  smuggled 2>"$smug_err")
smug_rc=$?

if [ "$smug_rc" = "2" ]; then
  ok "a directive in constants.cfg is refused — exit 2"
else
  nope "a directive in constants.cfg is refused — wanted exit 2, got $smug_rc (stdout: $(printf '%s' "$smug_out" | jq -rc '[.verdict,(.reasons|join(","))]|join(" ")' 2>/dev/null))"
fi

# The refusal is attributed to the PROBLEM PACKAGE, whose defect it is, and
# never to the submission. This submission is CORRECT -- it grades PASS
# against the same reference with the fragment removed. Before the guard
# existed the smuggled invariant fired at level 3, grade.sh read the rc=12 as
# "the reference obligation was UNMET", and a correct submission came back
# under-constrained.
if [ -z "$smug_out" ]; then
  ok "a refused fragment emits no verdict object"
else
  nope "a refused fragment emitted a verdict object: $(printf '%s' "$smug_out" | tr '\n' ' ' | cut -c1-160)"
fi

if grep -qE -- 'constants\.cfg' "$smug_err"; then
  ok "the refusal names the fragment"
else
  nope "the refusal does not name the fragment: $(tr '\n' ' ' <"$smug_err" | cut -c1-200)"
fi
rm -f "$smug_err"

echo
# ===========================================================================
echo "== the harness is resolved from grade.sh, never from the caller's cwd =="
# ===========================================================================

# Bead tla-u8on, and bead tla-1hf in the mirror direction. grade.sh used to
# resolve its repo root with `git rev-parse --show-toplevel` from wherever it
# was called. Run from inside a DIFFERENT git repository that happens to have
# a harness/ directory, it silently loaded THAT repo's verdict channel and
# THAT repo's Gate.tla -- the two things the whole grading architecture rests
# on, taken from somewhere nobody chose.
#
# The decoy below is what that looks like: a real git repo whose
# harness/verdict.sh reports a verdict nobody asked for. grade.sh must not
# read a single byte of it.
decoy=$(mktemp -d -t tla_grade_decoy.XXXXXX)
mkdir -p "$decoy/harness"
cat >"$decoy/harness/verdict.sh" <<'DECOY'
#!/usr/bin/env bash
# A DECOY verdict channel. If grade.sh reaches this file it has resolved its
# harness from the caller's cwd, and every verdict it reports afterwards came
# from a repository nobody chose. 66 is not in the 5.1 table on purpose.
exit 66
DECOY
printf '%s\n%s\n' '---- MODULE Gate ----' '====' >"$decoy/harness/Gate.tla"
git -C "$decoy" init -q >/dev/null 2>&1
git -C "$decoy" -c user.email=d@e -c user.name=d commit -q --allow-empty -m d >/dev/null 2>&1

decoy_err=$(mktemp)
decoy_out=$(cd "$decoy" && bash "$REPO_ROOT/$GRADE" \
  --reference  "$REPO_ROOT/$REFDIR" \
  --submission "$REPO_ROOT/$SUBDIR/correct-different" \
  --problem-id lockbox 2>"$decoy_err")
decoy_rc=$?

if [ "$decoy_rc" = "0" ]; then
  ok "grading from inside another repo is unaffected — exit 0"
else
  nope "grading from inside another repo is unaffected — wanted exit 0, got $decoy_rc (stderr: $(tr '\n' ' ' <"$decoy_err" | cut -c1-200))"
fi

decoy_verdict=$(printf '%s' "$decoy_out" | jq -r '.verdict' 2>/dev/null)
if [ "$decoy_verdict" = "PASS" ]; then
  ok "and it reports the same verdict it reports from the repo root"
else
  nope "and it reports the same verdict it reports from the repo root — wanted PASS, got '$decoy_verdict'"
fi
rm -rf "$decoy" "$decoy_err"

echo
# ===========================================================================
echo "== the leak gate is fail-closed and has been seen to fire =="
# ===========================================================================

leak_err=$(mktemp)
leak_out=$(GRADE_LEAK_CANARY=1 bash "$GRADE" --reference "$REFDIR" \
             --submission "$SUBDIR/both-at-once" --problem-id lockbox 2>"$leak_err")
leak_rc=$?

if [ "$leak_rc" = "5" ]; then
  ok "canary trips the leak gate — exit 5"
else
  nope "canary trips the leak gate — wanted exit 5, got $leak_rc"
fi

if [ -z "$leak_out" ]; then
  ok "a tripped leak gate emits NOTHING on stdout"
else
  nope "a tripped leak gate emitted $(printf '%s' "$leak_out" | wc -c) bytes on stdout"
fi
rm -f "$leak_err"

echo
# ===========================================================================
echo "== a PROPERTY line with no operand is caught, not graded =="
# ===========================================================================

# Bead tla-x8s. A step obligation goes into the generated .cfg as PROPERTY, and
# that form ran with NO postcondition guard at all, while every INVARIANT run
# carried `Gate!InvariantConfigured` to catch a .cfg that configured nothing.
# The gap was not an oversight in the guard's design. Neither operator in
# Gate.tla fitted: InvariantConfigured wants a non-empty `invariants` and
# RefinementConfigured wants a non-empty `impliedinits`, and a bare boxed
# action populates neither, so passing either would have turned every step
# obligation into a harness error.
#
# Gate!ActionPropertyConfigured is the operator that does fit, and it landed in
# Gate.tla without grade.sh ever naming it. The three runs below are the
# evidence that it catches the vector and stays quiet on a real run. The two
# structural checks after them are what say grade.sh asks for it, and no
# fixture can observe that. The verdict object of a run that checked nothing
# looks exactly like the verdict object of a run that passed.
prop_dir=$(mktemp -d -t tla_grade_prop.XXXXXX)
cp harness/Gate.tla "$prop_dir/"
cat >"$prop_dir/BareProperty.tla" <<'PROBE'
-------------------------- MODULE BareProperty --------------------------
EXTENDS Naturals
VARIABLE n
Init == n = 0
Next == n' = (n + 1) % 4
Spec == Init /\ [][Next]_n
GRADE_OBLIGATION == [][n' # n]_n
=============================================================================
PROBE
printf 'SPECIFICATION Spec\nPROPERTY\n' >"$prop_dir/bare.cfg"
printf 'SPECIFICATION Spec\nPROPERTY GRADE_OBLIGATION\n' >"$prop_dir/good.cfg"

# The vector itself. A .cfg keyword with no operand is not an error to TLC's
# parser, so this run reports OK and exits 0 having checked no property at all.
# Unguarded, a generator bug that dropped the operand would grade every
# submission a pass on every step obligation it states.
bash harness/verdict.sh --quiet --config "$prop_dir/bare.cfg" \
     "$prop_dir/BareProperty.tla"
bare_unguarded_rc=$?
if [ "$bare_unguarded_rc" = "0" ]; then
  ok "a bare PROPERTY line exits 0 having checked nothing"
else
  nope "a bare PROPERTY line exits 0 having checked nothing -- got $bare_unguarded_rc"
fi

bash harness/verdict.sh --quiet --postcondition "Gate!ActionPropertyConfigured" \
     --config "$prop_dir/bare.cfg" "$prop_dir/BareProperty.tla"
bare_guarded_rc=$?
if [ "$bare_guarded_rc" = "10" ]; then
  ok "and the action-property guard catches it -- exit 10"
else
  nope "and the action-property guard catches it -- wanted exit 10, got $bare_guarded_rc"
fi

# The other direction, so the guard is not one that simply always fires. A real
# boxed action populates `impliedactions` and passes.
bash harness/verdict.sh --quiet --postcondition "Gate!ActionPropertyConfigured" \
     --config "$prop_dir/good.cfg" "$prop_dir/BareProperty.tla"
good_guarded_rc=$?
if [ "$good_guarded_rc" = "0" ]; then
  ok "while a real boxed action passes the same guard -- exit 0"
else
  nope "while a real boxed action passes the same guard -- wanted exit 0, got $good_guarded_rc"
fi
rm -rf "$prop_dir"

assert_present "grade.sh names the action-property guard" \
  'Gate!ActionPropertyConfigured'
assert_present "and asks for it as the PROPERTY form's postcondition" \
  '(--postcondition|-p)[[:space:]]+"?Gate!ActionPropertyConfigured'

echo
# ===========================================================================
echo "== structural: constraints no fixture can observe =="
# ===========================================================================

# Every TLC outcome comes through the 5.1 verdict channel. grade.sh calling
# tlc itself would reintroduce the exit-code table in a second place.
#
# The pattern is the FILE, not the path that reaches it. It read
# `harness/verdict\.sh` until bead tla-u8on stopped grade.sh resolving its
# harness from the caller's cwd, and the literal string `harness/` left the
# code with it. Pinning the directory would have pinned the defect.
assert_present "TLC is reached through the verdict channel" \
  '/verdict\.sh'

assert_absent "grade.sh never invokes tlc directly" \
  '(^|[^[:alnum:]_./-])tlc[[:space:]]'

# grade.sh does not even ASK for TLC's console output. Not matching it is one
# claim; never capturing it is a stronger one, and it is the one that stays
# true when someone adds a debugging line later.
assert_absent "TLC's console output is never captured" \
  '(--log|-workers)'

assert_absent "no TLC stdout phrases used as literals" \
  '(No error has been found|Invariant .* is violated|Temporal properties were violated|Deadlock reached|Finished in|unexpected exception)'

# 3.7: feedback is error LOCATION. The counterexample-hint arm measured
# statistically indistinguishable from no hint, and the natural-language arm
# measured BELOW control. grade.sh reads the trace to find WHERE, and must
# never carry state values out of it.
assert_absent "no trace state values are carried into the verdict object" \
  'jq[^|]*\.state'

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
