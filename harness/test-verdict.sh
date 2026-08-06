#!/usr/bin/env bash
# test-verdict.sh — Executable spec for harness/verdict.sh (bead tla-kl5.4).
#
# Pins the RED invariant from the bead:
#
#   for each rc in {0,10,11,12,13,150,151,255,124} a purpose-built fixture
#   spec drives verdict.sh to exactly that verdict, and no verdict is ever
#   derived from stdout text.
#
# Two kinds of assertion:
#
#   Behavioural — run verdict.sh against a fixture in harness/fixtures/verdict/
#     and require BOTH the verdict token and the raw exit status. Asserting the
#     raw rc as well as the token is what keeps the V2-PLAN.md 5.1 table honest:
#     a future TLC that renumbered its exit codes would still produce the right
#     token through a silently-patched map, and only the rc assertion catches it.
#
#   Structural — read verdict.sh itself and require -workers 1, a timeout
#     wrapper, and the absence of any text matching over TLC's output.
#
# Usage:  harness/test-verdict.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

VERDICT="harness/verdict.sh"
FIXTURES="harness/fixtures/verdict"

pass_count=0
fail_count=0

ok() {
  printf "  PASS  %s\n" "$1"
  pass_count=$((pass_count + 1))
}

nope() {
  printf "  FAIL  %s\n" "$1"
  fail_count=$((fail_count + 1))
}

# assert_verdict <label> <want-verdict> <want-rc> [verdict.sh args...]
assert_verdict() {
  local label="$1" want_verdict="$2" want_rc="$3"
  shift 3

  local got_verdict got_rc
  got_verdict=$(bash "$VERDICT" "$@" 2>/dev/null)
  got_rc=$?

  if [ "$got_verdict" = "$want_verdict" ] && [ "$got_rc" = "$want_rc" ]; then
    ok "$label — $want_verdict (rc=$want_rc)"
  else
    nope "$label — wanted $want_verdict/rc=$want_rc, got '${got_verdict}'/rc=${got_rc}"
  fi
}

# verdict.sh with whole-line comments stripped. BOTH structural assertions read
# this rather than the raw file: the header documents the very constructs the
# checks police (it names -workers 8 as the thing not to do, and it explains why
# there is no grep), so matching raw text would let a comment satisfy a
# should-be-present check and a comment trip a must-be-absent one. Verified by
# mutation: with `-workers 1` changed to `-workers 8` in the code, the raw-file
# version of assert_present still passed off the header comment.
verdict_code() {
  sed 's/^[[:space:]]*#.*$//' "$VERDICT"
}

# assert_absent <label> <extended-regex>
assert_absent() {
  local label="$1" pattern="$2"
  local hits
  # `--` is load-bearing: several of these patterns begin with a literal '-'
  # and grep would otherwise read them as options, fail, and report no hits —
  # a check that passes because it never ran.
  hits=$(verdict_code | grep -nE -- "$pattern")
  if [ -z "$hits" ]; then
    ok "$label"
  else
    nope "$label — found: $(echo "$hits" | tr '\n' ' ')"
  fi
}

# assert_present <label> <extended-regex>
assert_present() {
  local label="$1" pattern="$2"
  if verdict_code | grep -qE -- "$pattern"; then
    ok "$label"
  else
    nope "$label — pattern not found: $pattern"
  fi
}

if [ ! -f "$VERDICT" ]; then
  echo "FATAL: $VERDICT does not exist" >&2
  exit 1
fi

echo "== behavioural: one fixture per row of the V2-PLAN.md 5.1 table =="

# rc=0 — trivially satisfied, run through the FULL canonical invocation
# including a -postCondition that holds (Ok has 5 distinct states >= 4).
assert_verdict "rc=0   trivially-satisfied spec" \
  "OK" 0 \
  --postcondition "Gate!NonVacuous" "$FIXTURES/Ok.tla"

# rc=10 — both arms of the assumption channel.
assert_verdict "rc=10  ASSUME FALSE" \
  "ASSUMPTION_FAILED" 10 \
  "$FIXTURES/AssumeFalse.tla"

assert_verdict "rc=10  -postCondition false (1 distinct state)" \
  "ASSUMPTION_FAILED" 10 \
  --postcondition "Gate!NonVacuous" "$FIXTURES/PostCondFalse.tla"

# rc=11 — genuine deadlock, and the control that proves the flag is real.
assert_verdict "rc=11  deadlock, checking ON" \
  "DEADLOCK" 11 \
  --check-deadlock "$FIXTURES/Deadlock.tla"

assert_verdict "rc=0   same spec, deadlock checking OFF (default)" \
  "OK" 0 \
  "$FIXTURES/Deadlock.tla"

# rc=12 / rc=13 — the two violation channels, kept distinct.
assert_verdict "rc=12  INVARIANT violated" \
  "SAFETY_VIOLATION" 12 \
  "$FIXTURES/SafetyViolation.tla"

assert_verdict "rc=13  PROPERTY violated" \
  "LIVENESS_VIOLATION" 13 \
  "$FIXTURES/LivenessViolation.tla"

# rc=150 / rc=151 — broken module vs broken config, deliberately separated.
assert_verdict "rc=150 unparseable module" \
  "PARSE_ERROR" 150 \
  "$FIXTURES/ParseError.tla"

assert_verdict "rc=151 .cfg names an operator the spec lacks" \
  "CONFIG_ERROR" 151 \
  "$FIXTURES/ConfigError.tla"

# rc=255 — the fixture is the ABSENCE of the file. Guard that first: if
# someone ever creates NoSuchModule.tla the assertions below would go green
# for the wrong reason.
if [ -e "$FIXTURES/NoSuchModule.tla" ] || [ -e "$FIXTURES/NoSuchModule.cfg" ]; then
  nope "rc=255 fixture integrity — no NoSuchModule.{tla,cfg} may exist"
else
  ok "rc=255 fixture integrity — NoSuchModule.{tla,cfg} absent as required"
fi

assert_verdict "rc=255 missing .cfg" \
  "TLC_EXCEPTION" 255 \
  "$FIXTURES/NoSuchModule.tla"

# rc=124 — its own verdict, not folded into failure.
assert_verdict "rc=124 unbounded state space under a short timeout" \
  "TIMEOUT" 124 \
  --timeout 5 "$FIXTURES/Unbounded.tla"

echo
echo "== the three measured departures from the V2-PLAN.md 5.1 table =="
echo "== (each is pinned here so it cannot silently drift back)      =="

# 5.1 files "file not found" under 255. Measured, the missing-MODULE half is
# 150, not 255: SANY reports "Cannot find source file" and the run dies in the
# parse channel. Same absent file as the 255 case above; the only difference is
# that a readable .cfg lets TLC get as far as looking for the module.
assert_verdict "5.1 departure: missing .tla is 150, not 255" \
  "PARSE_ERROR" 150 \
  --config "$FIXTURES/Ok.cfg" "$FIXTURES/NoSuchModule.tla"

# 5.1 files "config failure" under 151 without qualification. Measured, 151 is
# only the SEMANTIC half; a .cfg that fails to PARSE lands in the 255 catch-all
# alongside genuinely missing files.
assert_verdict "5.1 departure: unparseable .cfg is 255, not 151" \
  "TLC_EXCEPTION" 255 \
  --config "$FIXTURES/BadCfgSyntax.cfg" "$FIXTURES/Ok.tla"

# Not in 5.1 at all, and the most dangerous of the three: a .cfg keyword with
# no operand is not an error. TLC exits 0 having silently checked no invariant
# whatsoever — a vacuous PASS that looks exactly like a real one, which is the
# 5.3 hazard class arriving through the config file instead of through Init.
assert_verdict "5.1 gap: bare INVARIANT keyword is silently ignored, rc=0" \
  "OK" 0 \
  --config "$FIXTURES/DanglingKeyword.cfg" "$FIXTURES/Ok.tla"

echo
echo "== structural: the constraints that no fixture can observe =="

# -workers 1 is mandatory (V2-PLAN.md 5.1): counterexamples are
# nondeterministic above one worker.
assert_present "-workers 1 is pinned in the invocation" \
  '-workers[[:space:]]+1'

assert_absent "no worker count other than 1" \
  '-workers[[:space:]]+([02-9]|[0-9][0-9])'

# The timeout wrapper is what makes rc=124 reachable at all.
assert_present "TLC is wrapped in timeout(1)" \
  '(^|[^[:alnum:]_])timeout[[:space:]]'

# The whole point of the bead: verdicts come from the exit code, never from
# TLC's stdout. verdict.sh has no legitimate use for a text matcher, so the
# check bans them outright rather than trying to prove intent.
assert_absent "no text matching over TLC output (grep/sed/awk/rg)" \
  '(^|[^[:alnum:]_./-])(grep|sed|awk|rg|egrep|fgrep)[[:space:]]'

assert_absent "no bash regex match operator" \
  '=~'

# Belt and braces: none of TLC's own verdict strings appear as literals.
assert_absent "no TLC stdout phrases used as literals" \
  '(No error has been found|Invariant .* is violated|Temporal properties were violated|Deadlock reached|Finished in|unexpected exception)'

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
