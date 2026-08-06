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
cd "$REPO_ROOT"

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

# assert_reports <label> <fixed-string> [vacuity.sh args...]
assert_reports() {
  local label="$1" want="$2"
  shift 2
  local got_out
  got_out=$(bash "$VACUITY" "$@" 2>/dev/null)
  # -c rather than -q, for the same reason as the structural assertions: -q
  # exits at the first match, and under `pipefail` the upstream write can die
  # of SIGPIPE and turn a found pattern into rc=141.
  if printf '%s' "$got_out" | grep -cF -- "$want" >/dev/null; then
    ok "$label"
  else
    nope "$label — remediation did not mention: $want"
  fi
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
if [ ! -f "$VACUITY" ]; then
  echo "FATAL: $VACUITY does not exist" >&2
  exit 1
fi
VACUITY_CODE=$(sed 's/^[[:space:]]*#.*$//' "$VACUITY")

assert_present() {
  local label="$1" pattern="$2"
  if printf '%s\n' "$VACUITY_CODE" | grep -cE -- "$pattern" >/dev/null; then
    ok "$label"
  else
    nope "$label — pattern not found: $pattern"
  fi
}

assert_absent() {
  local label="$1" pattern="$2"
  local hits
  hits=$(printf '%s\n' "$VACUITY_CODE" | grep -nE -- "$pattern")
  if [ -z "$hits" ]; then
    ok "$label"
  else
    nope "$label — found: $(echo "$hits" | tr '\n' ' ')"
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
  "$FIXTURES/EmptyInit.tla"

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
  --config "$FIXTURES/DanglingInvariant.cfg" "$FIXTURES/Healthy.tla"

# The two vectors must not collapse into one verdict: they have different
# causes and different remediation, so a learner needs to be told which.
assert_reports "vector 1 remediation names the empty state space" \
  "no reachable states" \
  "$FIXTURES/EmptyInit.tla"

assert_reports "vector 2 remediation names the missing operand, not Init" \
  "but the operator name after it is missing" \
  --config "$FIXTURES/DanglingInvariant.cfg" "$FIXTURES/Healthy.tla"

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
  got=$(bash verdict.sh -q --postcondition "Gate!NonVacuous" \
        --config fixtures/vacuity/DanglingInvariant.cfg \
        fixtures/vacuity/Healthy.tla 2>/dev/null)
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
  --expect none --config "$FIXTURES/DanglingInvariant.cfg" "$FIXTURES/Healthy.tla"

echo
echo "== vector 3: dead actions, and the false positive that predicate avoids =="

assert_vacuity "an unreachable guard is caught" \
  "VACUOUS_DEAD_ACTION" 5 \
  "$FIXTURES/DeadGuard.tla"

# Error location is the only feedback form that measured as working (3.7), so
# the report must name the guard rather than say "unreachable".
assert_reports "dead-action remediation quotes the guard that is never true" \
  "counter > 100" \
  "$FIXTURES/DeadGuard.tla"

assert_reports "dead-action remediation names the action" \
  "action Overflow" \
  "$FIXTURES/DeadGuard.tla"

# THE FALSE-POSITIVE CONTROL. PlusCal emits Terminating into every
# terminating algorithm and it reports 0 distinct : 1 total. A probe keyed on
# distinct == 0 flags this healthy submission, and with it essentially every
# PlusCal submission in the problem set.
assert_vacuity "a terminating PlusCal spec is NOT flagged" \
  "NON_VACUOUS" 0 \
  "$FIXTURES/TerminatingPcal.tla"

# Pinned so the reason survives: if a future TLC stopped reporting 0:1 here,
# the assertion above would keep passing for a different reason and the
# distinct-vs-total lesson would quietly stop being tested.
pcal_cov=$(
  cd harness || exit 1
  bash verdict.sh -q --log /dev/stdout fixtures/vacuity/TerminatingPcal.tla 2>/dev/null \
    | grep -E '^<Terminating .*>: [0-9]+:[0-9]+$'
)
if printf '%s' "$pcal_cov" | grep -qE '>: 0:[1-9]'; then
  ok "PlusCal Terminating still reports 0 distinct with non-zero total — ${pcal_cov##*: }"
else
  nope "PlusCal Terminating coverage — wanted 0:<non-zero>, got '${pcal_cov}'"
fi

echo
echo "== the positive control and the per-problem threshold =="

assert_vacuity "a healthy spec with a real invariant passes" \
  "NON_VACUOUS" 0 \
  "$FIXTURES/Healthy.tla"

# The threshold is per-problem. Gate.tla is centrally owned and hard-codes
# >= 4, so any other value is served by a module vacuity.sh generates.
assert_vacuity "--min-states above what the spec reaches is caught" \
  "VACUOUS_EMPTY_SPACE" 3 \
  --min-states 99 "$FIXTURES/Healthy.tla"

assert_vacuity "--min-states at what the spec reaches passes" \
  "NON_VACUOUS" 0 \
  --min-states 5 "$FIXTURES/Healthy.tla"

# A spec that will not run is not a vacuity verdict.
assert_vacuity "a missing module is inconclusive, not vacuous" \
  "PROBE_INCONCLUSIVE" 6 \
  "$FIXTURES/NoSuchModule.tla"

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
assert_present "TLC is reached through verdict.sh" \
  'VERDICT="\$HERE/verdict.sh"'

assert_absent "tlc is never invoked directly" \
  '(^|[^[:alnum:]_./-])tlc[[:space:]]'

# Gate.tla is centrally owned. vacuity.sh reads it via TLA-Library and must
# never write to it -- the per-problem threshold goes into a generated module.
assert_absent "Gate.tla is never written to" \
  '>[[:space:]]*"?\$?\{?[A-Za-z_]*\}?/?Gate\.tla'

# Verdicts come from exit codes; TLC's prose is not a verdict channel.
assert_absent "no TLC stdout phrases used as verdicts" \
  '(No error has been found|Invariant .* is violated|Temporal properties were violated|Deadlock reached)'

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
