#!/usr/bin/env bash
# test-vacuity.sh — Executable spec for harness/vacuity.sh (bead tla-kl5.6, V2-PLAN.md §5.3).
#
# Pins the RED lines from the bead, and the three vacuity vectors as THREE
# DISTINGUISHABLE OUTCOMES rather than one undifferentiated VACUOUS.
#
#   RED 1  GIVEN a spec whose Init is unsatisfiable, WHEN vacuity.sh runs,
#          THEN it returns VACUOUS -- even though a bare TLC run on that same
#          spec exits 0 with "No error has been found".
#
#   RED 2  GIVEN a spec with a HEALTHY state space and a .cfg keyword with no
#          operand, WHEN vacuity.sh runs, THEN it ALSO returns VACUOUS -- and
#          with a DIFFERENT token from RED 1, because the remediation differs.
#
# Two more vectors follow, from bead tla-hf39 / seedlib step-2 variants V47 and
# V46. Both were recorded UNCAUGHT at rc=0 in
# authoring/seedlib/reports/step2-variants.md.
#
#   RED 3  GIVEN a spec that ships a liveness obligation and a fairness
#          conjunct NO BEHAVIOUR CAN MEET, WHEN vacuity.sh runs, THEN it
#          reports the spec UNSATISFIABLE -- rather than letting every
#          temporal obligation pass over the empty set of behaviours.
#
#          The three existing probes are all blind to it BY CONSTRUCTION.
#          Invariants are checked over the state graph and fairness never
#          touches the state graph, so the state space is healthy, NonVacuous
#          passes, InvariantConfigured passes, and no action reads total == 0.
#          Only the liveness half goes blind, and it goes blind silently.
#
#   RED 4  GIVEN an action DELETED from Next rather than restricted to
#          nothing, WHEN vacuity.sh runs with that action's NAME expected,
#          THEN the dead-action probe reports it -- rather than keying only on
#          a coverage row that reads zero.
#
#          Deletion evades the current probe and restriction does not. The
#          predicate matches `total == 0` in TLC's -coverage 1 block; a
#          restricted action leaves a row reading zero, and a deleted action
#          leaves NO ROW AT ALL, so there is nothing to match.
#
# A fifth follows, from bead tla-dk7w / custody step 4, and it is about the
# harness rather than about a submission.
#
#   RED 5  GIVEN a problem that does not state its own state-count floor,
#          WHEN vacuity.sh runs, THEN it REFUSES -- rather than falling back
#          on Gate.tla's placeholder of 4.
#
#          Custody step 4 measured a 24-state deterministic script that
#          transcribes the published satisfying trace and passes all 13
#          obligations at rc=0. The witness probes cannot save it: 3.9 obliges
#          every property to ship a satisfying trace, and any trace rich
#          enough to teach also threads the finite witness set. So every
#          shape-A problem honouring 3.9 has this hole.
#
#          The floor is the instrument that sees it, and the mechanism has
#          been there since tla-kl5.6 -- per-problem by design, and opt-in
#          with a permissive default. Opt-in is the defect. A problem that
#          never mentions the floor gets 4, and 4 is a number the
#          transcription clears three times over.
#
# A sixth follows, from bead tla-29m4 / seedlib step-2 variants V43 and V45,
# and it is about a LATTICE rather than a switch.
#
#   RED 6  GIVEN an observation operator with a field that never changes
#          anywhere in the reachable state space, WHEN vacuity.sh runs with
#          that operator named, THEN it reports THAT FIELD -- independently of
#          whether any other field of the same record moves.
#
#          5.4 already closes this for refinement, and states the idiom at
#          harness/refinement.sh:22-25: name the mapped expression, assert as
#          an ORDINARY INVARIANT that it never leaves its initial value, and
#          require TLC to VIOLATE it. A PASSING PROBE IS A FAILING CHECK.
#
#          That probe is WHOLE-EXPRESSION, which is right for a refinement
#          mapping -- the mapped tuple either moves or it does not. AN
#          OBSERVATION RECORD IS A LATTICE, AND A WHOLE-RECORD PROBE SITS AT
#          THE TOP OF IT. Measured on ObserveLattice.tla, one module with one
#          .cfg per row, on v1.8.0:
#
#            one field frozen      whole-record probe rc=12  -> "moves", MISS
#            three fields frozen   whole-record probe rc=12  -> "moves", MISS
#            all four frozen       whole-record probe rc=0   -> FROZEN, caught
#
#          So a whole-record probe catches exactly one of the sixteen subsets,
#          and it is the one subset a learner is least likely to write. In
#          seedlib the other rows are caught by OBLIGATIONS that happen to
#          notice -- CloseSquaresTheBook at V38 and V41, DefaultIsNeverClean at
#          V42, TheReckoningComes at V44 -- which is coincidence rather than
#          coverage, and V43, the three non-season fields, is caught by
#          nothing at all. V45 stacks a real broken guard underneath the same
#          freeze and stays invisible too.
#
#          THE FIELD IS THE ALTITUDE, THEN, AND EVERY ROW OF THE LATTICE IS
#          ASSERTED RATHER THAN JUST THE HOLE. A gate that catches all five
#          rows for one stated reason is a gate; one that catches four of them
#          because something else happened to fire is a coincidence, and the
#          difference is only visible if the uniform rows are pinned too.
#
# Three kinds of assertion:
#
#   Behavioural  — drive vacuity.sh against a fixture and require both the
#     verdict token and the exit code.
#
#   Differential — the assertions that carry the bead's actual finding. Each
#     runs the SAME fixture through a weaker configuration and requires the
#     weaker one to MISS. A test that only shows the finished gate passing
#     cannot show why the second guard had to exist.
#
#   Structural   — read vacuity.sh itself for the constraints no fixture can
#     observe: the dead-action predicate keyed on total, the ban on matching
#     TLC's auto-generated debugger name, and the routing of every TLC run
#     through verdict.sh.
#
# Usage:  harness/test-vacuity.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

VACUITY="harness/vacuity.sh"
VERDICT="harness/verdict.sh"
FIXTURES="harness/fixtures/vacuity"

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

# assert_vacuity <label> <want-token> <want-rc> [vacuity.sh args...]
assert_vacuity() {
  local label="$1" want_token="$2" want_rc="$3"
  shift 3
  local got_out got_token got_rc
  # Captured whole, then sliced. Piping straight into `head` under `pipefail`
  # kills vacuity.sh with SIGPIPE and reports 141 instead of its verdict.
  got_out=$(bash "$VACUITY" "$@" 2>/dev/null)
  got_rc=$?
  got_token=${got_out%%$'\n'*}
  if [ "$got_token" = "$want_token" ] && [ "$got_rc" = "$want_rc" ]; then
    ok "$label — $want_token (rc=$want_rc)"
  else
    nope "$label — wanted $want_token/rc=$want_rc, got '${got_token}'/rc=${got_rc}"
  fi
}

# assert_verdict <label> <want-token> <want-rc> [verdict.sh args...]
assert_verdict() {
  local label="$1" want_token="$2" want_rc="$3"
  shift 3
  local got_token got_rc
  got_token=$(bash "$VERDICT" "$@" 2>/dev/null)
  got_rc=$?
  if [ "$got_token" = "$want_token" ] && [ "$got_rc" = "$want_rc" ]; then
    ok "$label — $want_token (rc=$want_rc)"
  else
    nope "$label — wanted $want_token/rc=$want_rc, got '${got_token}'/rc=${got_rc}"
  fi
}

# assert_refuses <label> <want-rc> <want-stderr-substring> [vacuity.sh args...]
#
# For an ARGUMENT fault rather than a submission verdict, which needs a
# different shape from assert_vacuity. vacuity.sh's rc=2 USAGE path writes to
# stderr and prints NO verdict token at all -- the code is listed in the table
# at vacuity.sh:32, but the exits that use it print only a message. So the
# three things worth checking here are the rc, the message naming the flag,
# and stdout staying EMPTY: a refusal that printed a token would be indexed by
# every caller that slices line 1 as a verdict.
#
# stderr goes to a file rather than through a pipe, and the substring match is
# a here-string. Bead tla-kr9: any pipe into an early-exiting consumer can come
# back 141 and report a present message as absent.
assert_refuses() {
  local label="$1" want_rc="$2" want_err="$3"
  shift 3
  local errfile got_out got_rc got_err
  errfile=$(mktemp -t tla_refuses.XXXXXX)
  got_out=$(bash "$VACUITY" "$@" 2>"$errfile")
  got_rc=$?
  got_err=$(cat "$errfile")
  rm -f "$errfile"
  if [ "$got_rc" != "$want_rc" ]; then
    nope "$label — wanted rc=$want_rc, got rc=$got_rc (stdout: '${got_out%%$'\n'*}')"
    return
  fi
  if ! grep -qF -- "$want_err" <<<"$got_err"; then
    nope "$label — refused at rc=$want_rc, but stderr never named: $want_err"
    return
  fi
  if [ -n "$got_out" ]; then
    nope "$label — refused at rc=$want_rc, but stdout was not empty: '${got_out%%$'\n'*}'"
    return
  fi
  ok "$label — refused (rc=$want_rc), stderr names $want_err, stdout empty"
}

# assert_reports <label> <fixed-string> [vacuity.sh args...]
assert_reports() {
  local label="$1" want="$2"
  shift 2
  local got_out
  got_out=$(bash "$VACUITY" "$@" 2>/dev/null)
  # Here-string, not a pipe. This used to be `printf ... | grep -cF`, where the
  # `-c` was doing the safety work: -c reads to EOF so nothing early-exits, and
  # so nothing SIGPIPEs. That worked, but it made the correctness of the check
  # depend on a flag whose stated job is counting -- swap the -c back to a -q
  # and the bug returns silently. Removing the pipe removes the hazard outright
  # and lets -q mean what it says. Bead tla-kr9.
  if grep -qF -- "$want" <<<"$got_out"; then
    ok "$label"
  else
    nope "$label — remediation did not mention: $want"
  fi
}

# assert_observe <label> <token> <rc> <frozen-fields> <live-fields> [args...]
#
# One invocation, four questions: the verdict token, the exit code, that every
# field named in <frozen-fields> is reported, and that no field named in
# <live-fields> is. Both lists are space-separated and either may be empty.
#
# THE FOUR ARE ASSERTED TOGETHER BECAUSE THEY ARE ONE CLAIM. "Reports every
# frozen field" and "reports only frozen fields" are the two halves of the
# contract, and a gate satisfying either alone is useless -- one that names
# nothing passes the first half read as a token check, and one that names all
# four fields on every row passes it too. The token alone cannot tell those
# apart. Splitting them would also double the TLC runs for no discriminating
# power, on the slowest suite in the gate.
#
# The report phrasing this matches is a CONTRACT DECISION, not a measurement:
# the per-field line reads `field <name> never changes`. Bead tla-29m4.
assert_observe() {
  local label="$1" want_token="$2" want_rc="$3" frozen="$4" live="$5"
  shift 5
  local got_out got_token got_rc missing extra f
  # Captured whole, then sliced -- never piped into an early-exiting consumer.
  # Bead tla-kr9.
  got_out=$(bash "$VACUITY" "$@" 2>/dev/null)
  got_rc=$?
  got_token=${got_out%%$'\n'*}
  if [ "$got_token" != "$want_token" ] || [ "$got_rc" != "$want_rc" ]; then
    nope "$label — wanted $want_token/rc=$want_rc, got '${got_token}'/rc=${got_rc}"
    return
  fi
  missing=""
  extra=""
  # Word-splitting is what the space-separated field lists are FOR, so the
  # unquoted expansion is deliberate here rather than an oversight.
  # shellcheck disable=SC2086
  for f in $frozen; do
    if ! grep -qF -- "field $f never changes" <<<"$got_out"; then
      missing="$missing $f"
    fi
  done
  # shellcheck disable=SC2086
  for f in $live; do
    if grep -qF -- "field $f never changes" <<<"$got_out"; then
      extra="$extra $f"
    fi
  done
  if [ -n "$missing" ] || [ -n "$extra" ]; then
    nope "$label — $want_token, but frozen fields not reported:${missing:- none}; live fields wrongly reported:${extra:- none}"
    return
  fi
  ok "$label — $want_token (rc=$want_rc), frozen:${frozen:- none}, live untouched:${live:- none}"
}

# vacuity.sh with whole-line comments stripped. BOTH structural assertions read
# this rather than the raw file: the header documents the very constructs the
# checks police (it spells out the distinct-vs-total predicate and names the
# debugger expression), so matching raw text would let a comment satisfy a
# must-be-present check and a comment trip a must-be-absent one.
#
# Captured into a variable rather than piped. `sed ... | grep -q` under
# `pipefail` reports the PIPELINE status, and grep -q exits at the first match
# and closes the pipe, so sed dies of SIGPIPE and a genuinely-present pattern
# comes back as rc=141 -- a structural check failing for a reason that has
# nothing to do with the code it checks. Measured here on the verdict.sh
# routing assertion, which matches at line 121 of ~330.
#
# NOTE (bead tla-kr9): capturing is necessary but NOT sufficient, which is why
# the matches below are here-strings rather than `printf "$VACUITY_CODE" | grep`.
# The printf builtin runs in a forked subshell inside a pipeline and takes
# SIGPIPE exactly as sed did -- measured at rc=141 on a 2 MB string, identical
# to the uncaptured shape. The pipe is the bug, not the producer.
if [ ! -f "$VACUITY" ]; then
  echo "FATAL: $VACUITY does not exist" >&2
  exit 1
fi
VACUITY_CODE=$(sed 's/^[[:space:]]*#.*$//' "$VACUITY")

assert_present() {
  local label="$1" pattern="$2"
  if grep -qE -- "$pattern" <<<"$VACUITY_CODE"; then
    ok "$label"
  else
    nope "$label — pattern not found: $pattern (searched $(grep -c '' <<<"$VACUITY_CODE") lines of $VACUITY)"
  fi
}

assert_absent() {
  local label="$1" pattern="$2"
  local hits
  hits=$(grep -nE -- "$pattern" <<<"$VACUITY_CODE")
  if [ -z "$hits" ]; then
    ok "$label"
  else
    nope "$label — found: $(tr '\n' ' ' <<<"$hits")"
  fi
}

echo "== RED 1: vector 1 — an unsatisfiable Init =="

# The control FIRST: this is the trap the bead exists to close. The same
# fixture through the plain verdict channel is an unremarkable success.
assert_verdict "control: bare TLC on the same spec reports success" \
  "OK" 0 \
  "$FIXTURES/EmptyInit.tla"

assert_vacuity "unsatisfiable Init is caught" \
  "VACUOUS_EMPTY_SPACE" 3 \
  --min-states 4 "$FIXTURES/EmptyInit.tla"

# Deadlock checking is the thing people reach for instead, and it does not
# work: there is no reachable state in which to deadlock.
assert_verdict "control: deadlock checking does NOT catch it either" \
  "OK" 0 \
  --check-deadlock "$FIXTURES/EmptyInit.tla"

echo
echo "== RED 2: vector 2 — a healthy state space with nothing checked =="

assert_verdict "control: bare TLC on the dangling-keyword cfg reports success" \
  "OK" 0 \
  --config "$FIXTURES/DanglingInvariant.cfg" "$FIXTURES/Healthy.tla"

assert_vacuity "dangling INVARIANT keyword is caught" \
  "VACUOUS_UNCHECKED" 4 \
  --min-states 4 --config "$FIXTURES/DanglingInvariant.cfg" "$FIXTURES/Healthy.tla"

# The two vectors must not collapse into one verdict: they have different
# causes and different remediation, so a learner needs to be told which.
assert_reports "vector 1 remediation names the empty state space" \
  "no reachable states" \
  --min-states 4 "$FIXTURES/EmptyInit.tla"

assert_reports "vector 2 remediation names the missing operand, not Init" \
  "but the operator name after it is missing" \
  --min-states 4 --config "$FIXTURES/DanglingInvariant.cfg" "$FIXTURES/Healthy.tla"

echo
echo "== differential: NonVacuous alone does NOT catch vector 2 =="
echo "== (the finding this bead exists to encode)                =="

# The postcondition gate from the original plan, run by itself against the
# vector-2 fixture. It exits 0. The state space is perfectly healthy -- 5
# distinct states -- so a >= N threshold has nothing to complain about. It is
# not the state space that is empty, it is the CHECKING.
#
# NOTE the working directory: TLC resolves Gate only when the MAIN module is
# given by a relative path (then the CWD is searched) or when TLA-Library is
# set (then it need not be). vacuity.sh uses the latter; this assertion uses
# the former, which is why it runs from harness/.
(
  cd harness || exit 1
  bash verdict.sh -q --postcondition "Gate!NonVacuous" \
    --config fixtures/vacuity/DanglingInvariant.cfg \
    fixtures/vacuity/Healthy.tla >/dev/null 2>&1
  rc=$?
  exit "$rc"
)
nv_on_v2=$?
if [ "$nv_on_v2" = "0" ]; then
  ok "Gate!NonVacuous MISSES vector 2 (rc=0) — the gap InvariantConfigured fills"
else
  nope "Gate!NonVacuous on vector 2 — wanted the MISS (rc=0), got rc=$nv_on_v2"
fi

# And the same gap from the other side: InvariantConfigured does not catch
# vector 1 either, because the empty-Init fixture's cfg names a real
# invariant. Neither guard subsumes the other, so both have to run.
(
  cd harness || exit 1
  bash verdict.sh -q --postcondition "Gate!InvariantConfigured" \
    fixtures/vacuity/EmptyInit.tla >/dev/null 2>&1
)
ic_on_v1=$?
if [ "$ic_on_v1" = "0" ]; then
  ok "Gate!InvariantConfigured MISSES vector 1 (rc=0) — the guards are disjoint"
else
  nope "Gate!InvariantConfigured on vector 1 — wanted the MISS (rc=0), got rc=$ic_on_v1"
fi

# The same miss through vacuity.sh itself, with the configured-check probe
# switched off. This is what a reasonable implementation that stopped at the
# original plan's gate would report on the vector-2 fixture.
assert_vacuity "vacuity.sh WITHOUT the configured-check probe misses vector 2" \
  "NON_VACUOUS" 0 \
  --min-states 4 --expect none --config "$FIXTURES/DanglingInvariant.cfg" "$FIXTURES/Healthy.tla"

echo
echo "== vector 3: dead actions, and the false positive that predicate avoids =="

assert_vacuity "an unreachable guard is caught" \
  "VACUOUS_DEAD_ACTION" 5 \
  --min-states 4 "$FIXTURES/DeadGuard.tla"

# Error location is the only feedback form that measured as working (3.7), so
# the report must name the guard rather than say "unreachable".
assert_reports "dead-action remediation quotes the guard that is never true" \
  "counter > 100" \
  --min-states 4 "$FIXTURES/DeadGuard.tla"

assert_reports "dead-action remediation names the action" \
  "action Overflow" \
  --min-states 4 "$FIXTURES/DeadGuard.tla"

# THE FALSE-POSITIVE CONTROL. PlusCal emits Terminating into every
# terminating algorithm and it reports 0 distinct : 1 total. A probe keyed on
# distinct == 0 flags this healthy submission, and with it essentially every
# PlusCal submission in the problem set.
assert_vacuity "a terminating PlusCal spec is NOT flagged" \
  "NON_VACUOUS" 0 \
  --min-states 4 "$FIXTURES/TerminatingPcal.tla"

# Pinned so the reason survives: if a future TLC stopped reporting 0:1 here,
# the assertion above would keep passing for a different reason and the
# distinct-vs-total lesson would quietly stop being tested.
pcal_cov=$(
  cd harness || exit 1
  bash verdict.sh -q --log /dev/stdout fixtures/vacuity/TerminatingPcal.tla 2>/dev/null \
    | grep -E '^<Terminating .*>: [0-9]+:[0-9]+$'
)
if grep -qE '>: 0:[1-9]' <<<"$pcal_cov"; then
  ok "PlusCal Terminating still reports 0 distinct with non-zero total — ${pcal_cov##*: }"
else
  nope "PlusCal Terminating coverage — wanted 0:<non-zero>, got '${pcal_cov}'"
fi

echo
echo "== RED 4: vector 3's second shape — an action DELETED from Next =="
echo "== (bead tla-hf39, seedlib V46)                                 =="

# THE EVASION, pinned from the MISS side first, because that is the finding.
# DeadGuard.tla's Overflow IS a disjunct of Next and merely carries a guard
# that is never true, so it leaves a coverage row reading 0:0 and the
# `total == 0` predicate matches it -- asserted above, and still passing.
# DeletedAction.tla's Down is not a disjunct at all. There is no row for that
# predicate to match, so vacuity.sh runs to the end and reports "Every action
# fired at least once", which is false. Restriction is caught. Deletion is not.
#
# This row must keep passing after the fix: supplying no expected names leaves
# the probe as strong as it is today, and no stronger.
assert_vacuity "a DELETED action is missed when no names are expected" \
  "NON_VACUOUS" 0 \
  --min-states 4 "$FIXTURES/DeletedAction.tla"

# Pinned so the reason survives, the way the PlusCal 0:1 row above is. If a
# future TLC started emitting a zero row for an action that is not in Next,
# every assertion below would keep passing for a DIFFERENT reason and the
# deletion-versus-restriction lesson would quietly stop being tested.
#
# `| grep -E` and not `| grep -q`: -E reads to EOF, so nothing closes the pipe
# early and verdict.sh is never SIGPIPEd. The -q matches that follow are
# here-strings for the same reason. Bead tla-kr9.
del_cov=$(
  cd harness || exit 1
  bash verdict.sh -q --log /dev/stdout fixtures/vacuity/DeletedAction.tla 2>/dev/null \
    | grep -E '^<(Up|Down) line'
)
del_up=$(grep -cE '^<Up line' <<<"$del_cov")
del_down=$(grep -cE '^<Down' <<<"$del_cov")
if [ "$del_up" != "0" ] && [ "$del_down" = "0" ]; then
  ok "the deleted action has NO coverage row at all — Up rows: $del_up, Down rows: $del_down"
else
  nope "deleted-action coverage — wanted a Up row and no Down row, got Up: $del_up, Down: $del_down"
fi

# THE CONTRACT. The probe takes the expected action NAMES, so an action that
# never reaches the coverage block is reported as an action that never fired.
assert_vacuity "a DELETED action is caught when its name is expected" \
  "VACUOUS_DEAD_ACTION" 5 \
  --min-states 4 --expect-actions Up,Down "$FIXTURES/DeletedAction.tla"

# Error location is the only feedback form that measured as working (§3.7), and
# an absent action has no location to quote -- so the name is all the report
# has, and it has to carry it.
assert_reports "absent-action remediation names the action" \
  "action Down" \
  --min-states 4 --expect-actions Up,Down "$FIXTURES/DeletedAction.tla"

# The two shapes need different remediation. "Your guard is never true" is
# wrong advice for an action that has no guard problem at all: Down reads word
# for word as it does in Healthy.tla, and the fault is that Next never mentions
# it. So the report has to say which of the two happened.
assert_reports "absent-action remediation says the row is missing, not zero" \
  "no coverage row at all" \
  --min-states 4 --expect-actions Up,Down "$FIXTURES/DeletedAction.tla"

# THE NEGATIVE CONTROL. A probe with no negative control cannot be shown to
# bite -- one that flags every spec would satisfy every assertion above.
# Healthy.tla has both Up and Down as disjuncts of Next and both fire.
assert_vacuity "expected names that all fire are NOT flagged" \
  "NON_VACUOUS" 0 \
  --min-states 4 --expect-actions Up,Down "$FIXTURES/Healthy.tla"

# AND THE NAMES MUST NOT REPLACE THE OLD PREDICATE. `total == 0` over a row
# that exists is the case the probe already caught, and passing expected names
# must add the absent case rather than swap one blind spot for another.
assert_vacuity "a RESTRICTED action is still caught when names are given" \
  "VACUOUS_DEAD_ACTION" 5 \
  --min-states 4 --expect-actions Up,Overflow "$FIXTURES/DeadGuard.tla"

echo
echo "== RED 3: vector 4 — a fairness conjunct no behaviour can meet =="
echo "== (bead tla-hf39, seedlib V47)                                =="

# The control FIRST, as with vector 1. UnsatFairness.cfg ships a real
# INVARIANT and a real liveness PROPERTY, and this is what the harness's own
# verdict channel says about a spec NO BEHAVIOUR SATISFIES: success.
assert_verdict "control: bare TLC on the unsatisfiable spec reports success" \
  "OK" 0 \
  "$FIXTURES/UnsatFairness.tla"

# THE CONTRACT.
assert_vacuity "an unsatisfiable Spec is caught" \
  "VACUOUS_UNSATISFIABLE" 7 \
  --min-states 4 "$FIXTURES/UnsatFairness.tla"

# THE NEGATIVE CONTROL, and it is the same module with one disjunct restored.
# Both fairness conjuncts are still there, so a probe that fires here is firing
# on the presence of fairness rather than on fairness the spec cannot meet.
assert_vacuity "the satisfiable twin is NOT flagged" \
  "NON_VACUOUS" 0 \
  --min-states 4 "$FIXTURES/LiveFairness.tla"

assert_reports "vector 4 remediation names the empty behaviour set" \
  "no behaviour satisfies your Spec" \
  --min-states 4 "$FIXTURES/UnsatFairness.tla"

# Not Init and not Next alone: both are fine here, and a learner sent to look
# at either will find nothing wrong. The mismatch BETWEEN them is the fault.
assert_reports "vector 4 remediation points at the fairness conjunct" \
  "fairness conjunct" \
  --min-states 4 "$FIXTURES/UnsatFairness.tla"

echo
echo "== differential: all three existing probes are blind to vector 4 =="

# NonVacuous sees a healthy state space, because fairness does not shrink the
# state graph -- it shrinks the set of BEHAVIOURS over that graph.
(
  cd harness || exit 1
  bash verdict.sh -q --postcondition "Gate!NonVacuous" \
    fixtures/vacuity/UnsatFairness.tla >/dev/null 2>&1
)
nv_on_v4=$?
if [ "$nv_on_v4" = "0" ]; then
  ok "Gate!NonVacuous MISSES vector 4 (rc=0) — fairness does not shrink the state graph"
else
  nope "Gate!NonVacuous on vector 4 — wanted the MISS (rc=0), got rc=$nv_on_v4"
fi

# InvariantConfigured sees a real INVARIANT in the cfg, because there is one.
(
  cd harness || exit 1
  bash verdict.sh -q --postcondition "Gate!InvariantConfigured" \
    fixtures/vacuity/UnsatFairness.tla >/dev/null 2>&1
)
ic_on_v4=$?
if [ "$ic_on_v4" = "0" ]; then
  ok "Gate!InvariantConfigured MISSES vector 4 (rc=0) — the obligation IS configured"
else
  nope "Gate!InvariantConfigured on vector 4 — wanted the MISS (rc=0), got rc=$ic_on_v4"
fi

# And the dead-action probe is blind too, for RED 4's reason arriving one
# vector over: Reset is not a disjunct of Next, so it has no coverage row, and
# every row that DOES exist reports a non-zero total. `total == 0` has nothing
# to match. Measured rather than asserted through vacuity.sh, so that the fix
# for RED 3 cannot make this row pass for a new reason.
v4_cov=$(
  cd harness || exit 1
  bash verdict.sh -q --log /dev/stdout fixtures/vacuity/UnsatFairness.tla 2>/dev/null \
    | grep -E '^<[A-Za-z]+ line .*>: [0-9]+:[0-9]+$'
)
v4_reset=$(grep -cE '^<Reset' <<<"$v4_cov")
v4_zero=$(grep -cE ':0$' <<<"$v4_cov")
if [ "$v4_reset" = "0" ] && [ "$v4_zero" = "0" ]; then
  ok "the dead-action predicate MISSES vector 4 — no Reset row, and no row reads total 0"
else
  nope "vector 4 coverage — wanted no Reset row and no zero total, got Reset: $v4_reset, zero: $v4_zero"
fi

echo
echo "== the satisfiability probe itself, measured on both fixtures =="

# THE MECHANISM, pinned rather than assumed. An always-false TEMPORAL formula
# separates a spec that has behaviours from one that has none:
#
#   rc=13  the formula was refuted, so a behaviour exists to refute it.
#   rc=0   nothing refuted it, because there is nothing to refute it WITH.
#
# Measured on both fixtures, because a probe that returned 0 on everything
# would satisfy the unsatisfiable row alone.
assert_verdict "always-false TEMPORAL formula vs the unsatisfiable Spec" \
  "OK" 0 \
  --config "$FIXTURES/UnsatFairnessProbe.cfg" "$FIXTURES/UnsatFairness.tla"

assert_verdict "always-false TEMPORAL formula vs the satisfiable Spec" \
  "LIVENESS_VIOLATION" 13 \
  --config "$FIXTURES/LiveFairnessProbe.cfg" "$FIXTURES/LiveFairness.tla"

# AND WHY IT HAS TO BE TEMPORAL. `[](counter # counter)` over a STATE
# PREDICATE is not a weaker probe, it is a different channel: TLC lifts it into
# an INVARIANT and refutes it against the state graph, which ignores fairness
# by construction. So it reports a violation on a spec that has no behaviours
# at all -- the exact opposite of the signal wanted, and unusable however false
# the formula is.
assert_verdict "the same formula over a STATE PREDICATE goes to the invariant channel" \
  "SAFETY_VIOLATION" 12 \
  --config "$FIXTURES/UnsatFairnessStateProbe.cfg" "$FIXTURES/UnsatFairness.tla"

echo
echo "== the positive control and the per-problem threshold =="

# The positive control and the missing-module row both used to sit here, both
# run with no floor at all. Bead tla-dk7w made the floor mandatory, so both
# grew a `--min-states 4` and became byte-identical to two rows the RED 5
# section already carries: "an EXPLICIT floor of 4 is legal and behaves as
# before" and "with a floor supplied, a missing module is still inconclusive".
# Dropped here rather than kept in both places. A duplicate pair can only fail
# together, so it buys no discriminating power, and this is the slowest suite
# in the gate at 47.7 s.

# The threshold is per-problem. Gate.tla is centrally owned and hard-codes
# >= 4, so any other value is served by a module vacuity.sh generates.
assert_vacuity "--min-states above what the spec reaches is caught" \
  "VACUOUS_EMPTY_SPACE" 3 \
  --min-states 99 "$FIXTURES/Healthy.tla"

assert_vacuity "--min-states at what the spec reaches passes" \
  "NON_VACUOUS" 0 \
  --min-states 5 "$FIXTURES/Healthy.tla"

echo
echo "== RED 5: the floor is MANDATORY, not a default =="
echo "== (bead tla-dk7w, custody step 4)               =="

# THE HOLE, pinned from the MISS side first, because that is the finding.
#
# Custody step 4 measured a 24-state deterministic script that replays the
# published satisfying trace and passes all 13 obligations at rc=0
# (authoring/custody/reports/step4-screens.md:125-142). The witness probes
# cannot save it: 3.9 obliges every property to ship a satisfying trace, and
# any trace rich enough to teach also threads the finite witness set. So the
# hole is structural in every shape-A problem, and the floor is the only
# instrument that can see it.
#
# TranscriptFloor.tla is that submission in miniature. It clears the
# placeholder floor THREE TIMES OVER -- 12 distinct states against >= 4 -- so
# nothing about the miss looks marginal, and every other probe passes it: the
# space is healthy, the INVARIANT is configured, Spec admits behaviours, and
# both actions fire. A problem that leaves the floor at the placeholder
# therefore grades a transcription as a model.
#
# This row must keep passing after the fix. The placeholder is not being made
# stricter; it is being made IMPOSSIBLE TO REACH BY OMISSION.
assert_vacuity "a 12-state transcription clears the placeholder floor of 4" \
  "NON_VACUOUS" 0 \
  --min-states 4 "$FIXTURES/TranscriptFloor.tla"

# THE CONTRACT. Omitting the floor is refused. The problem author has to state
# what their problem's state space is worth; the script will not pick a number
# on their behalf, because the number it used to pick is the one that lets the
# transcription through.
#
# rc=2 USAGE, the code vacuity.sh already exits with when its arguments are
# wrong (vacuity.sh:32). Deliberately NOT a new vacuity code: 3/4/5/6/7 are
# all statements about the SUBMISSION, and a missing flag is a statement about
# the CALLER. Putting an authoring fault in the learner-verdict namespace is
# the confusion the disjoint-codes note at vacuity.sh:38 exists to prevent.
assert_refuses "omitting --min-states is refused, not defaulted" \
  2 "--min-states" \
  "$FIXTURES/Healthy.tla"

# AND THE REFUSAL IS ABOUT OMISSION, NOT ABOUT THE VALUE 4. A problem whose
# state space really is worth four states says so and is served. Without this
# row the assertion above could be satisfied by banning the number.
assert_vacuity "an EXPLICIT floor of 4 is legal and behaves as before" \
  "NON_VACUOUS" 0 \
  --min-states 4 "$FIXTURES/Healthy.tla"

# The refusal is an argument fault, so it lands BEFORE any probe runs. Cheap
# to check and worth pinning: a floor validated after probing would let a
# whole TLC run happen on the strength of a number nobody supplied, and would
# report whatever that run found instead of the fault.
#
# NoSuchModule.tla cannot run at all, so today it reaches PROBE_INCONCLUSIVE
# and the answer comes from a probe. Under the contract the argument fault
# wins and no probe is reached.
assert_refuses "the refusal precedes any probe" \
  2 "--min-states" \
  "$FIXTURES/NoSuchModule.tla"

# The negative control for that: supply the floor and the inconclusive path
# is exactly as it was. The refusal must not swallow the other verdicts.
assert_vacuity "with a floor supplied, a missing module is still inconclusive" \
  "PROBE_INCONCLUSIVE" 6 \
  --min-states 4 "$FIXTURES/NoSuchModule.tla"

# THE FLOOR BITING, at a floor a real problem would set. 12 distinct states
# against a floor of 24 is vector 1's "too few states" arm, reached by a
# submission that no other probe can distinguish from a model.
assert_vacuity "the transcription IS caught once the problem states its floor" \
  "VACUOUS_EMPTY_SPACE" 3 \
  --min-states 24 "$FIXTURES/TranscriptFloor.tla"

# Error location is the only feedback form that measured as working (3.7), and
# a floor has no location -- so the numbers are what the report has to carry.
# A learner told only "too few states" cannot tell whether they are one state
# short or twenty.
assert_reports "the too-few-states report names the floor the problem set" \
  "requires at least 24" \
  --min-states 24 "$FIXTURES/TranscriptFloor.tla"

# THE NEGATIVE CONTROL, and it is run at the SAME floor. A floor that flagged
# everything would satisfy the row above on its own, so the discriminating
# thing has to be shown to be the submission rather than the number.
# ModelledFloor.tla is the same domain actually modelled: 40 distinct states.
#
# Note this is the OPPOSITE experiment from the two Healthy.tla rows above,
# which run one fixture at two floors. Neither direction substitutes for the
# other: theirs shows the number moves the verdict, this shows the submission
# does.
assert_vacuity "a modelled submission clears the SAME floor" \
  "NON_VACUOUS" 0 \
  --min-states 24 "$FIXTURES/ModelledFloor.tla"

# The usage text is the other surface the placeholder lives on, and it is the
# one a problem author reads before deciding whether to pass the flag. A text
# that still promises a number is an instruction to omit it.
#
# The pattern requires a DIGIT after "default" so that an honest "(REQUIRED;
# no default)" does not trip it -- the thing being banned is advertising a
# value, not the word.
help_out=$(bash "$VACUITY" --help 2>&1)
help_default=$(grep -nE -- 'min-states.*default[^0-9]{0,3}[0-9]' <<<"$help_out")
if [ -z "$help_default" ]; then
  ok "--help no longer advertises a numeric default for the floor"
else
  nope "--help still advertises a default floor — $(tr '\n' ' ' <<<"$help_default")"
fi

echo
echo "== RED 6: the Observe-freeze LATTICE, a field at a time =="
echo "== (bead tla-29m4, seedlib V43 and V45)                 =="

# THE CONTROL FIRST, as with vectors 1 and 4. Three of Observe's four fields are
# dead on this row and the harness's own verdict channel calls the submission
# fine, at the reference's own numbers.
assert_verdict "control: bare TLC on the three-frozen row reports success" \
  "OK" 0 \
  --config "$FIXTURES/ObserveLatticeThree.cfg" "$FIXTURES/ObserveLattice.tla"

# THE HOLE, pinned from the MISS side, the way RED 4's deleted action and RED
# 5's transcription are. Name no observation operator and the component is as
# blind as it is today -- and this row must KEEP PASSING after the fix, because
# a submission whose problem never states an observation operator has not
# acquired a fault, it has acquired a check nobody asked for.
assert_vacuity "the three-frozen row is missed when no observation is named" \
  "NON_VACUOUS" 0 \
  --min-states 16 --config "$FIXTURES/ObserveLatticeThree.cfg" "$FIXTURES/ObserveLattice.tla"

# ...and the report has to SAY that, rather than closing with a claim the run
# did not earn. vacuity.sh already does this for --expect none and for absent
# --expect-actions; a summary that stayed silent here would let "NON_VACUOUS"
# be read as "the observation was checked and moves".
assert_reports "the summary admits the freeze was not looked for" \
  "no observation operator was named" \
  --min-states 16 --config "$FIXTURES/ObserveLatticeThree.cfg" "$FIXTURES/ObserveLattice.tla"

# THE CONTRACT. Three fields dead, one alive, and the gate names the three.
assert_observe "the three-frozen row is caught, and names all three" \
  "VACUOUS_FROZEN_OBSERVE" 8 "shelf owed standing" "season" \
  --min-states 16 --observe Observe \
  --config "$FIXTURES/ObserveLatticeThree.cfg" "$FIXTURES/ObserveLattice.tla"

# THE NEGATIVE CONTROL, and it is the same module one .cfg over. A probe that
# flagged every submission would satisfy every row above on its own, so the
# discriminating thing has to be shown to be the freeze rather than the
# presence of --observe.
assert_observe "an observation whose every field moves is NOT flagged" \
  "NON_VACUOUS" 0 "" "season shelf owed standing" \
  --min-states 16 --observe Observe \
  --config "$FIXTURES/ObserveLattice.cfg" "$FIXTURES/ObserveLattice.tla"

# THE REST OF THE LATTICE. Seedlib catches these rows today, but by obligations
# that happen to notice rather than by a probe that was looking, so nothing in
# the pipeline states WHY they are caught or promises they stay caught. A gate
# that answers all five rows for one reason is what replaces that coincidence,
# and it is only visible as uniform if the uniform rows are asserted too.
assert_observe "one frozen field is caught, and only that one is named" \
  "VACUOUS_FROZEN_OBSERVE" 8 "shelf" "season owed standing" \
  --min-states 16 --observe Observe \
  --config "$FIXTURES/ObserveLatticeOne.cfg" "$FIXTURES/ObserveLattice.tla"

assert_observe "a frozen PAIR is caught, and both are named" \
  "VACUOUS_FROZEN_OBSERVE" 8 "shelf owed" "season standing" \
  --min-states 16 --observe Observe \
  --config "$FIXTURES/ObserveLatticePair.cfg" "$FIXTURES/ObserveLattice.tla"

# The top of the lattice, and the only row a whole-record probe can see. It has
# to keep being caught after the altitude drops, or the fix has traded one
# blind spot for another.
assert_observe "a wholly frozen observation is caught, and all four are named" \
  "VACUOUS_FROZEN_OBSERVE" 8 "season shelf owed standing" "" \
  --min-states 16 --observe Observe \
  --config "$FIXTURES/ObserveLatticeAll.cfg" "$FIXTURES/ObserveLattice.tla"

# An operator the module does not define. The probe cannot run, so nothing is
# known about the observation -- and "nothing is known" is PROBE_INCONCLUSIVE,
# never NON_VACUOUS. Reporting a pass here would be a false PASS on the gate,
# reached by misspelling a flag.
assert_vacuity "--observe naming an undefined operator is inconclusive" \
  "PROBE_INCONCLUSIVE" 6 \
  --min-states 16 --observe NoSuchObservation \
  --config "$FIXTURES/ObserveLatticeThree.cfg" "$FIXTURES/ObserveLattice.tla"

echo
echo "== differential: a WHOLE-RECORD probe sees only the top of the lattice =="

# The refinement idiom, run at the record altitude against three rows of the
# lattice. harness/refinement.sh:22-25 -- assert as an ordinary INVARIANT that
# the expression never leaves its initial value and require TLC to VIOLATE it,
# so rc=12 reads "it moves, nothing frozen here" and rc=0 reads "FROZEN".
#
# This is the whole finding. The probe is correct for a refinement mapping and
# wrong for an observation record, and it is wrong in the direction that waves
# submissions through.
assert_verdict "whole-record probe MISSES one frozen field (rc=12 reads 'moves')" \
  "SAFETY_VIOLATION" 12 \
  --config "$FIXTURES/ObserveLatticeOneWholeProbe.cfg" "$FIXTURES/ObserveLattice.tla"

assert_verdict "whole-record probe MISSES three frozen fields — the V43 hole" \
  "SAFETY_VIOLATION" 12 \
  --config "$FIXTURES/ObserveLatticeThreeWholeProbe.cfg" "$FIXTURES/ObserveLattice.tla"

# ...and catches the one row where the record itself is constant, which is why
# the probe looks like it works until somebody leaves a field live.
assert_verdict "whole-record probe CATCHES only the wholly frozen row" \
  "OK" 0 \
  --config "$FIXTURES/ObserveLatticeAllWholeProbe.cfg" "$FIXTURES/ObserveLattice.tla"

# THE SAME IDIOM ONE ALTITUDE DOWN, on the same .cfg row the record probe just
# missed. Both directions, because a per-field probe that returned 0 on every
# field would satisfy the frozen row alone and flag every healthy submission.
assert_verdict "per-field probe on a frozen field is NOT violated — FROZEN" \
  "OK" 0 \
  --config "$FIXTURES/ObserveLatticeThreeFieldProbe.cfg" "$FIXTURES/ObserveLattice.tla"

assert_verdict "per-field probe on the live field IS violated — it moves" \
  "SAFETY_VIOLATION" 12 \
  --config "$FIXTURES/ObserveLatticeThreeLiveFieldProbe.cfg" "$FIXTURES/ObserveLattice.tla"

echo
echo "== the field next door: a probe that dies reports nothing =="

# TLC does not return FALSE when the two sides of a comparison are of different
# types; it ABORTS the evaluation. Measured on v1.8.0 over ObserveMixedType,
# whose `phase` field holds 0, 1 and "closed" across the reachable space:
# an invariant that compares it against a number reaches the string state and
# comes back SAFETY_EVAL_FAILURE, rc=76 -- the check never happened.
#
# That is a hazard for a PER-FIELD probe specifically, and the direction it
# fails in is the dangerous one. `ledger` is frozen on this fixture and is the
# thing the gate exists to find; it is sitting next to the field most likely to
# take the instrument down, and a run that aborts on `phase` reports nothing
# about `ledger` at all.
assert_verdict "a naive equality probe ABORTS on a mixed-type field" \
  "SAFETY_EVAL_FAILURE" 76 \
  --config "$FIXTURES/ObserveMixedTypeCrossProbe.cfg" "$FIXTURES/ObserveMixedType.tla"

# AND THE HAZARD IS LATENT RATHER THAN ABSENT, which is the part an implementer
# who measures once will get wrong. The SAME comparison written the way
# refinement.sh writes it -- the field against its initial value -- answers
# correctly here, at rc=12. It answers correctly by luck: `phase` leaves 0 for 1
# before it ever reaches "closed", so TLC stops at that violation and never
# evaluates the cross-type case. Reorder the fixture, or hand it a spec whose
# heterogeneous field holds its initial value longest, and the same probe is the
# rc=76 above. Both rows are here so that neither reading stands alone.
assert_verdict "the same probe against the initial value answers by luck (rc=12)" \
  "SAFETY_VIOLATION" 12 \
  --config "$FIXTURES/ObserveMixedTypeFieldProbe.cfg" "$FIXTURES/ObserveMixedType.tla"

# THE CONTRACT. The frozen field is still reported, and the mixed-type field is
# still not reported as frozen, because it is not.
assert_observe "the frozen field is still found next to a mixed-type one" \
  "VACUOUS_FROZEN_OBSERVE" 8 "ledger" "phase" \
  --min-states 4 --observe Observe "$FIXTURES/ObserveMixedType.tla"

echo
echo "== structural: the constraints no fixture can observe =="

# The whole dead-action lesson in one assertion.
assert_present "dead-action predicate is keyed on total" \
  'total == 0'

assert_absent "dead-action predicate is NEVER keyed on distinct" \
  'distinct[[:space:]]*==[[:space:]]*0'

# TLC auto-names the injected smoke-test invariant __DebuggerExpr__<nanotime>.
# The name carries a timestamp, so matching it would work until it did not.
assert_absent "the auto-generated debugger expression name is never matched" \
  '__DebuggerExpr__'

# Every TLC run goes through the 5.1 verdict channel.
# The argument is a grep pattern, not a string to expand: the `\$` matches a
# literal dollar in vacuity.sh's source. Expanding it would search for whatever
# $HERE happens to hold in THIS shell, which is not the point of the assertion.
# shellcheck disable=SC2016
assert_present "TLC is reached through verdict.sh" \
  'VERDICT="\$HERE/verdict.sh"'

assert_absent "tlc is never invoked directly" \
  '(^|[^[:alnum:]_./-])tlc[[:space:]]'

# Gate.tla is centrally owned. vacuity.sh reads it via TLA-Library and must
# never write to it -- the per-problem threshold goes into a generated module.
assert_absent "Gate.tla is never written to" \
  '>[[:space:]]*"?\$?\{?[A-Za-z_]*\}?/?Gate\.tla'

# THE PLACEHOLDER ITSELF, banned at the source (bead tla-dk7w). The
# behavioural rows above can be satisfied by a check bolted on in front of a
# default that is still sitting there, and a default that is still sitting
# there is one edit away from being reachable again. A NUMBER is what is
# banned, not the variable: an unset sentinel such as MIN_STATES="" is how the
# script says it has no floor yet, and must stay available.
assert_absent "no numeric state-count floor is built into the script" \
  'MIN_STATES=[0-9]'

# Verdicts come from exit codes; TLC's prose is not a verdict channel.
assert_absent "no TLC stdout phrases used as verdicts" \
  '(No error has been found|Invariant .* is violated|Temporal properties were violated|Deadlock reached)'

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
