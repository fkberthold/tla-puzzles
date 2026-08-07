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
cd "$REPO_ROOT"

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
  local subdir="$1"
  python3 - "$REFDIR" "$subdir" <<'PY'
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

# assert_no_leak <label> <submission-dir-name>
assert_no_leak() {
  local label="$1" sub="$2" hits=""
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
  done < <(ref_only_identifiers "$SUBDIR/$sub")
  if [ -z "$hits" ]; then
    ok "$label"
  else
    nope "$label — reference-only identifiers found in the verdict object:$hits"
  fi
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
echo "== structural: constraints no fixture can observe =="
# ===========================================================================

# Every TLC outcome comes through the 5.1 verdict channel. grade.sh calling
# tlc itself would reintroduce the exit-code table in a second place.
assert_present "TLC is reached through harness/verdict.sh" \
  'harness/verdict\.sh'

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
