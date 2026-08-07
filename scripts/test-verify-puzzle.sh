#!/usr/bin/env bash
# test-verify-puzzle.sh — Regression tests for scripts/verify-puzzle.sh.
#
# Two generations of contract live here.
#
# tla-xpv (multi-module resolution):
#   1. A multi-module puzzle (T51) verifies as PASS-CLEAN through the script.
#      Before tla-xpv: helper modules were not copied to the scratch dir,
#      so TLC failed parse with "Cannot find source file ..." but the elif
#      chain matched "Finished in" and reported PASS-OTHER (rc=0).
#   2. A puzzle whose helper is actually missing reports FAIL-TLC, not
#      PASS-OTHER.
#
# tla-syn (verdicts from exit codes, never from stdout):
#   3. One assertion per row of the TLC exit-code table, driven by the
#      fixtures in harness/fixtures/verdict/ — the same fixtures that pin
#      harness/verdict.sh, reused rather than re-invented. Each fixture is
#      dropped into a synthetic puzzle dir and run through the real script,
#      so the assertion covers the whole v1 path (pair collection, scratch
#      copy, verdict mapping) rather than verdict.sh alone.
#   4. Structural assertions that the classifier cannot silently regress
#      back to stdout scraping: verify-puzzle.sh must route through
#      harness/verdict.sh, must not invoke `tlc` itself (which is what
#      transitively pins `-workers 1`), and must not classify on TLC's
#      console text.
# This file also carried a local mirror of harness/test-pipefail.sh's banned-idiom
# patterns, because that suite scanned only harness/ and left scripts/ unguarded.
# Bead tla-4u0 widened its roots to harness/ + scripts/ + chapter/, so the mirror
# was deleted rather than maintained in parallel — two copies of the same three
# regexes drift apart, and the copy nobody remembers to update is the one that
# stops catching things. The real gate now covers this file and the script under
# test; do not reintroduce a local copy.
#
# Runtime note: assertions 3.x each launch TLC. Measured ~20 s total, so this
# suite is no longer a sub-2 s "fast tier" member the way scripts/test's tier
# table records it. See the report on bead tla-syn.
#
# Usage:  scripts/test-verify-puzzle.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 2

SCRIPT="scripts/verify-puzzle.sh"
FIXTURES="harness/fixtures/verdict"
fail_count=0
pass_count=0

TMPROOT=$(mktemp -d -t tla_verify_test.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

# ---------------------------------------------------------------------------
# Assertion helpers.
#
# NOTE the here-string. Feeding a captured value into `grep -q` through a live
# pipe is the banned idiom of bead tla-kr9: under `set -o pipefail` the consumer
# exits on the first match, the writer takes SIGPIPE, the pipeline returns 141,
# and inside an `if` that reads as "pattern absent" — a present verdict reported
# as a mismatch, intermittently. Capturing into a variable first does not fix
# it; only removing the live pipe does. A here-string is materialised in full
# before the consumer is exec'd, so no writer is left to signal.
# ---------------------------------------------------------------------------
assert_verdict() {
  local label="$1" want="$2" actual="$3"
  if grep -qE -- "^${want}([[:space:]]|$)" <<<"$actual"; then
    printf "  PASS  %s — verdict %s\n" "$label" "$want"
    pass_count=$((pass_count + 1))
  else
    printf "  FAIL  %s — expected verdict %s, got:\n%s\n" "$label" "$want" "$actual"
    fail_count=$((fail_count + 1))
  fi
}

assert_rc() {
  local label="$1" want="$2" actual="$3"
  if [ "$want" = "$actual" ]; then
    printf "  PASS  %s — exit %s\n" "$label" "$want"
    pass_count=$((pass_count + 1))
  else
    printf "  FAIL  %s — expected exit %s, got %s\n" "$label" "$want" "$actual"
    fail_count=$((fail_count + 1))
  fi
}

# Whole-line comments are stripped before any source assertion matches, exactly
# as harness/test-pipefail.sh does it: every fixed site here carries a comment
# naming the idiom or the console phrase it replaced, and matching raw text
# would let those explanations trip their own ban.
strip_comments() {
  sed 's/^[[:space:]]*#.*$//' "$1"
}

# assert_source <label> <present|absent> <ERE> <file>
assert_source() {
  local label="$1" mode="$2" pattern="$3" file="$4" body
  body=$(strip_comments "$file")
  if grep -qE -- "$pattern" <<<"$body"; then
    if [ "$mode" = "present" ]; then
      printf "  PASS  %s\n" "$label"
      pass_count=$((pass_count + 1))
    else
      printf "  FAIL  %s — pattern /%s/ is present in %s\n" "$label" "$pattern" "$file"
      fail_count=$((fail_count + 1))
    fi
  else
    if [ "$mode" = "absent" ]; then
      printf "  PASS  %s\n" "$label"
      pass_count=$((pass_count + 1))
    else
      printf "  FAIL  %s — pattern /%s/ is missing from %s\n" "$label" "$pattern" "$file"
      fail_count=$((fail_count + 1))
    fi
  fi
}

# mk_puzzle <name> [fixture-basename ...] — build a synthetic puzzle dir whose
# solution/ holds the named fixture files, copied (never moved, never edited)
# out of harness/fixtures/verdict/. Echoes the puzzle dir.
mk_puzzle() {
  local name="$1"; shift
  local dir="$TMPROOT/$name"
  mkdir -p "$dir/solution"
  local f
  for f in "$@"; do
    cp "$FIXTURES/$f" "$dir/solution/$f"
  done
  printf '%s\n' "$dir"
}

echo "== tla-xpv: multi-module resolution =="

# 1. Multi-module spec passes cleanly.
out=$(bash "$SCRIPT" puzzles/T51-multi-module-specs 2>&1)
assert_verdict "T51 (multi-module Order EXTENDS OrderStates)" "PASS-CLEAN" "$out"

# 2. Synthetic missing-helper case must classify as FAIL-TLC, not PASS-OTHER.
# Order.tla + Order.cfg with OrderStates.tla deliberately withheld, so the
# classifier alone has to catch the parse failure (rc=150).
mkdir -p "$TMPROOT/missing-helper/solution"
cp puzzles/T51-multi-module-specs/solution/Order.tla "$TMPROOT/missing-helper/solution/"
cp puzzles/T51-multi-module-specs/solution/Order.cfg "$TMPROOT/missing-helper/solution/"
out=$(bash "$SCRIPT" "$TMPROOT/missing-helper" 2>&1)
assert_verdict "missing-helper fixture (Order without OrderStates)" "FAIL-TLC" "$out"

echo
echo "== tla-syn: one assertion per row of the TLC exit-code table =="

# rc=0 — Ok.tla, a trivially-satisfied invariant over 5 states.
p=$(mk_puzzle ok Ok.tla Ok.cfg)
out=$(bash "$SCRIPT" "$p" 2>&1); rc=$?
assert_verdict "rc=0 clean model check (Ok.tla)" "PASS-CLEAN" "$out"
assert_rc      "rc=0 clean model check (Ok.tla)" 0 "$rc"

# rc=12 — SafetyViolation.tla, INVARIANT x < 3 with x = 3 reachable.
p=$(mk_puzzle safety SafetyViolation.tla SafetyViolation.cfg)
out=$(bash "$SCRIPT" "$p" 2>&1); rc=$?
assert_verdict "rc=12 invariant violation (SafetyViolation.tla)" "PASS-VIOLATION" "$out"
assert_rc      "rc=12 invariant violation (SafetyViolation.tla)" 0 "$rc"

# rc=13 — LivenessViolation.tla, PROPERTY <>(x = 1) with no fairness.
p=$(mk_puzzle liveness LivenessViolation.tla LivenessViolation.cfg)
out=$(bash "$SCRIPT" "$p" 2>&1)
assert_verdict "rc=13 temporal-property violation (LivenessViolation.tla)" "PASS-VIOLATION" "$out"

# rc=11 — Deadlock.tla. TLC's -deadlock flag means "do NOT check for deadlock"
# and the canonical invocation carries it, so rc=11 is reachable only when the
# caller opts in. v1 verify-puzzle.sh has always run with deadlock checking OFF;
# both halves of that are pinned here so neither can drift silently.
p=$(mk_puzzle deadlock Deadlock.tla Deadlock.cfg)
out=$(CHECK_DEADLOCK=1 bash "$SCRIPT" "$p" 2>&1)
assert_verdict "rc=11 deadlock, checking opted in (Deadlock.tla)" "PASS-OTHER" "$out"
out=$(bash "$SCRIPT" "$p" 2>&1)
assert_verdict "deadlock checking is OFF by default (Deadlock.tla)" "PASS-CLEAN" "$out"

# rc=10 — AssumeFalse.tla, `ASSUME FALSE`. A failing assumption is a defect in
# the spec, not a model-checking outcome, so it must not land in a PASS-* row.
p=$(mk_puzzle assume AssumeFalse.tla AssumeFalse.cfg)
out=$(bash "$SCRIPT" "$p" 2>&1); rc=$?
assert_verdict "rc=10 failing ASSUME (AssumeFalse.tla)" "FAIL-ASSUME" "$out"
assert_rc      "rc=10 failing ASSUME (AssumeFalse.tla)" 1 "$rc"

# rc=150 — ParseError.tla, a syntactically invalid module.
p=$(mk_puzzle parse ParseError.tla ParseError.cfg)
out=$(bash "$SCRIPT" "$p" 2>&1); rc=$?
assert_verdict "rc=150 parse failure (ParseError.tla)" "FAIL-TLC" "$out"
assert_rc      "rc=150 parse failure (ParseError.tla)" 1 "$rc"

# rc=151 — ConfigError.cfg names an INVARIANT the module does not define. The
# module itself is fine. Measured 2026-08-07 against the old grep chain: this
# fixture came out PASS-OTHER, i.e. a broken .cfg reported as a pass, because no
# console phrase in the chain matched and the fallback "Finished in" did.
p=$(mk_puzzle config ConfigError.tla ConfigError.cfg)
out=$(bash "$SCRIPT" "$p" 2>&1); rc=$?
assert_verdict "rc=151 semantic config failure (ConfigError.cfg)" "FAIL-TLC" "$out"
assert_rc      "rc=151 semantic config failure (ConfigError.cfg)" 1 "$rc"

# rc=255 — a .cfg that does not parse at all. BadCfgSyntax.cfg is a cfg-only
# fixture applied to a healthy module, so the module is provably not the defect.
p=$(mk_puzzle badcfg Ok.tla)
cp "$FIXTURES/BadCfgSyntax.cfg" "$p/solution/Ok.cfg"
out=$(bash "$SCRIPT" "$p" 2>&1); rc=$?
assert_verdict "rc=255 unparseable .cfg (BadCfgSyntax.cfg as Ok.cfg)" "FAIL-TLC" "$out"
assert_rc      "rc=255 unparseable .cfg (BadCfgSyntax.cfg as Ok.cfg)" 1 "$rc"

# rc=0 with nothing checked — DanglingKeyword.cfg's bare INVARIANT line. TLC
# exits 0 having checked no invariant at all. verify-puzzle.sh reports the
# verdict TLC gives it; detecting the vacuity is §5.3's job, not this script's.
p=$(mk_puzzle dangling Ok.tla)
cp "$FIXTURES/DanglingKeyword.cfg" "$p/solution/Ok.cfg"
out=$(bash "$SCRIPT" "$p" 2>&1)
assert_verdict "rc=0 vacuous pass (DanglingKeyword.cfg as Ok.cfg)" "PASS-CLEAN" "$out"

# rc=124 — Unbounded.tla under a short budget.
p=$(mk_puzzle timeout Unbounded.tla Unbounded.cfg)
out=$(TIMEOUT=5 bash "$SCRIPT" "$p" 2>&1); rc=$?
assert_verdict "rc=124 timeout (Unbounded.tla, TIMEOUT=5)" "FAIL-TIMEOUT" "$out"
assert_rc      "rc=124 timeout (Unbounded.tla, TIMEOUT=5)" 1 "$rc"

# rc=75 — FAILURE_SPEC_EVAL, confirmed against the pinned jar with
#   javap -cp ~/lib/tla2tools.jar -constants 'tlc2.output.EC$ExitStatus'
# There is no fixture for this row: harness/fixtures/verdict/ predates its
# discovery and is out of this bead's footprint. The corpus supplies one
# instead — T29's Clock_buggy leaves minutes' unconstrained in one IF branch,
# so TLC cannot complete the successor state and exits 75 with a trace.
#
# This row is the sharpest evidence for the whole bead. The old chain called it
# PASS-VIOLATION, but not because it read the exit code — it matched the
# "Trace exploration" line of the *_TTrace_*.tla spec TLC emits alongside the
# error. The canonical invocation passes -noGenerateSpecTE to stop that litter,
# which silently deleted the only thing the classification rested on.
out=$(bash "$SCRIPT" puzzles/T29-unchanged 2>&1); rc=$?
assert_verdict "rc=75 under-constrained successor (T29 Clock_buggy)" "PASS-VIOLATION" "$out"
assert_rc      "rc=75 under-constrained successor (T29 Clock_buggy)" 0 "$rc"

# A .tla with no .cfg beside it is not a verifiable pair. Pinned because the
# pair-collection skip is what stops "missing .cfg" from ever reaching TLC.
p=$(mk_puzzle nocfg Ok.tla)
out=$(bash "$SCRIPT" "$p" 2>&1); rc=$?
assert_verdict "module with no .cfg is skipped, not failed" "SKIP" "$out"
assert_rc      "module with no .cfg is skipped, not failed" 0 "$rc"

echo
echo "== tla-syn: structural — the classifier cannot regress to stdout =="

assert_source "verify-puzzle.sh routes TLC through harness/verdict.sh" \
  present 'harness/verdict\.sh' "$SCRIPT"

# verdict.sh is where -workers 1 is pinned (and gated by harness/test-verdict.sh).
# verify-puzzle.sh inherits that pin only for as long as it never runs tlc itself.
assert_source "verify-puzzle.sh never invokes tlc directly (inherits -workers 1)" \
  absent '(^|[^[:alnum:]_./"-])tlc[[:space:]]' "$SCRIPT"

assert_source "verify-puzzle.sh does not classify on TLC console text" \
  absent 'No error has been found|Trace exploration|threw an unexpected exception|Finished in' \
  "$SCRIPT"

echo
if [ "$fail_count" -ne 0 ]; then
  echo "FAILED: $fail_count of $((pass_count + fail_count)) assertion(s)" >&2
  exit 1
fi
echo "OK: all $pass_count assertions passed"
