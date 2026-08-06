#!/usr/bin/env bash
#
# comment-gate.sh — the v2 harness comment-pass gate.
#
# Enforces V2-PLAN.md §3.8: "Comments are added in a SEPARATE post-freeze pass,
# enforced by strip-and-diff." Comments written alongside a spec bend the spec
# toward the commentary, so the commented artifact must be provably the frozen
# spec PLUS comments and NOTHING ELSE.
#
# Usage:
#   comment-gate.sh <frozen.tla> <commented.tla>
#   comment-gate.sh --strip <spec.tla>      # print the comment-stripped form
#   comment-gate.sh --self-test             # run the fixture matrix
#
# Exit codes:
#   0  PASS   — the commented spec is the frozen spec plus comments.
#   1  FAIL   — the comment pass changed the spec.
#   2  USAGE  — bad invocation.
#   3  ABORT  — the gate could not run SOUNDLY and refuses to render a verdict.
#
# Code 3 is the load-bearing one. See "the trap" below.
#
# ---------------------------------------------------------------------------
# THE TRAP (V2-PLAN.md §5.6)
# ---------------------------------------------------------------------------
# In PlusCal specs the algorithm lives inside `(* --algorithm ... *)`. By the
# TLA+ grammar that IS a comment. So a *grammatically correct* comment stripper
# DELETES THE ENTIRE SPEC — and the gate then diffs two husks, finds them equal,
# and reports PASS. A gate that compares nothing is worse than no gate: it
# launders an unchecked spec as a checked one.
#
# Two independent defences, both required:
#
#   1. The stripper preserves the block containing `--algorithm` /
#      `--fair algorithm` (stripping comments *nested inside* it), and preserves
#      the `\* BEGIN TRANSLATION` / `\* END TRANSLATION` markers.
#
#   2. A vacuity guard (`assert_not_vacuous`) refuses to emit any verdict when
#      the stripped form lost the module header or lost an algorithm block the
#      source demonstrably had. A stripper regression can therefore only ever
#      produce ABORT, never a silent PASS.
#
# `COMMENT_GATE_STRIPPER=naive` selects the grammatically-correct-but-fatal
# stripper on purpose, so the trap stays permanently reproducible:
#
#   COMMENT_GATE_STRIPPER=naive ./harness/comment-gate.sh --self-test   # RED
#   ./harness/comment-gate.sh --self-test                               # GREEN
#
# ---------------------------------------------------------------------------
# THE TWO CHECKS
# ---------------------------------------------------------------------------
# CHECK 1 — strip-and-diff (every spec).
#   Strip comments from both files, normalize whitespace, require identical.
#   Covers the WHOLE file: the algorithm, the generated translation, EXTENDS,
#   CONSTANTS, and any operator defined outside the algorithm block.
#
# CHECK 2 — pcal re-translation (PlusCal specs only; §5.6's preferred gate).
#   Copy both specs to scratch dirs, re-run `pcal` on each, and require the
#   generated TRANSLATION bodies BYTE-IDENTICAL. Comments inside the algorithm
#   are not carried into the generated TLA+, so any difference at all means the
#   pass touched the algorithm itself. Check 2 has ZERO dependence on the
#   trap-laden stripper, which is exactly why it is worth running alongside it.
#
# Neither check subsumes the other:
#   - an edit to the checked-in translation block, or to EXTENDS, is invisible
#     to check 2 (which regenerates the translation from an unchanged algorithm)
#     and is caught only by check 1;
#   - check 2 is the independent cross-check that survives a stripper bug.
# Both must pass.
#
# ---------------------------------------------------------------------------
# CONTRACT NOTE
# ---------------------------------------------------------------------------
# The comment pass must not re-run a *different* pcal version than the freeze
# did. pcal 1.11 does not reproduce this repo's checked-in translations
# byte-for-byte (it reorders `VARIABLES pc, light, count` to
# `light, count, pc`), so a re-translation during the comment pass rewrites the
# translation block and check 1 correctly reports FAIL. That is the intended
# reading of §3.8: the file changed. Check 2 sidesteps the drift by running the
# *same* pcal over both sides itself.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE_DIR="$SCRIPT_DIR/fixtures/comment-gate"

EXIT_PASS=0
EXIT_FAIL=1
EXIT_USAGE=2
EXIT_ABORT=3

# One scratch dir per invocation, torn down by an EXIT trap. A RETURN trap
# cannot be used here: it fires in the CALLER's scope, where the callee's
# `local workdir` no longer exists, and under `set -u` that aborts the script
# on the way out of an otherwise-passing run.
GATE_TMP=""
cleanup() { [ -n "$GATE_TMP" ] && rm -rf "$GATE_TMP"; return 0; }
trap cleanup EXIT

# --------------------------------------------------------------------------
# The stripper.
#
# A character-level state machine over the whole file. TLA+ block comments
# nest and string literals may contain comment openers, so a line-oriented
# sed pipeline cannot do this correctly.
#
# States: depth (block-comment nesting), algo (inside the algorithm block, at
# nesting depth algodepth), instr (inside a string literal), linecomment.
#
# `emitting` is true at depth 0 (module body) and at exactly algodepth when
# inside the algorithm block — so the algorithm's CODE survives while comments
# NESTED inside it are still stripped.
# --------------------------------------------------------------------------
read -r -d '' STRIP_AWK <<'AWK' || true
{ buf = buf $0 "\n" }
END {
  n = length(buf)
  i = 1
  depth = 0          # block-comment nesting depth
  algo = 0           # 1 while inside the PlusCal algorithm block
  algodepth = 0      # the depth at which the algorithm block sits
  instr = 0          # inside a string literal
  linecomment = 0    # inside a \* line comment
  out = ""

  while (i <= n) {
    c  = substr(buf, i, 1)
    c2 = substr(buf, i, 2)

    if (linecomment) {
      if (c == "\n") { linecomment = 0; out = out c }
      i++
      continue
    }

    emitting = (depth == 0) || (algo == 1 && depth == algodepth)

    if (instr) {
      if (c == "\\") { out = out c substr(buf, i + 1, 1); i += 2; continue }
      out = out c
      if (c == "\"") instr = 0
      i++
      continue
    }

    if (c2 == "(*") {
      depth++
      # THE TRAP: a depth-0 block comment that opens the PlusCal algorithm is
      # code, not commentary. `naive` skips this test and eats the spec.
      if (naive != 1 && depth == 1 && algo == 0) {
        look = substr(buf, i + 2, 80)
        if (look ~ /^[ \t\r\n]*--(fair[ \t\r\n]+)?algorithm[ \t\r\n]/) {
          algo = 1
          algodepth = 1
        }
      }
      i += 2
      continue
    }

    if (c2 == "*)" && depth > 0) {
      if (algo == 1 && depth == algodepth) algo = 0
      depth--
      i += 2
      continue
    }

    if (emitting && c2 == "\\*") {
      # \* BEGIN/END TRANSLATION are line comments by grammar but are
      # load-bearing structure. Preserve them, normalized: pcal stamps a
      # checksum onto the BEGIN marker, and that checksum is derived, not
      # authored, so it must not drive the diff.
      j = index(substr(buf, i), "\n")
      if (j == 0) rest = substr(buf, i)
      else        rest = substr(buf, i, j - 1)
      if (rest ~ /^\\\*[ \t]*BEGIN TRANSLATION/)    out = out "\\* BEGIN TRANSLATION"
      else if (rest ~ /^\\\*[ \t]*END TRANSLATION/) out = out "\\* END TRANSLATION"
      linecomment = 1
      i += 2
      continue
    }

    if (emitting) {
      if (c == "\"") instr = 1
      out = out c
    }
    i++
  }
  printf "%s", out
}
AWK

# Whitespace normalization. Leading indentation is preserved verbatim (TLA+
# conjunction lists are column-sensitive); runs of interior whitespace collapse
# to one space so that a comment removed from mid-line leaves no scar; blank
# lines are dropped so that a full-line comment leaves no scar either.
read -r -d '' NORMALIZE_AWK <<'AWK' || true
{
  line = $0
  match(line, /^[ \t]*/)
  lead = substr(line, 1, RLENGTH)
  body = substr(line, RLENGTH + 1)
  gsub(/[ \t]+/, " ", body)
  sub(/[ \t]+$/, "", body)
  if (body == "") next
  print lead body
}
AWK

# Lines strictly between the TRANSLATION markers. The markers themselves are
# excluded: pcal's checksum stamp lives on the BEGIN line and is derived.
read -r -d '' TRANSLATION_AWK <<'AWK' || true
/^[ \t]*\\\*[ \t]*BEGIN TRANSLATION/ { inblock = 1; next }
/^[ \t]*\\\*[ \t]*END TRANSLATION/   { inblock = 0; next }
inblock { print }
AWK

log()  { printf '%s\n' "$*" >&2; }
fatal() { printf 'ABORT: %s\n' "$*" >&2; exit "$EXIT_ABORT"; }

strip_comments() {
  local file="$1" naive=0
  [ "${COMMENT_GATE_STRIPPER:-}" = "naive" ] && naive=1
  awk -v naive="$naive" "$STRIP_AWK" "$file" | awk "$NORMALIZE_AWK"
}

has_algorithm_block() {
  grep -qE -- '--(fair[[:space:]]+)?algorithm[[:space:]]' "$1"
}

# The vacuity guard. This is what makes a stripper regression loud.
assert_not_vacuous() {
  local src="$1" stripped="$2" label="$3"

  if [ ! -s "$stripped" ]; then
    fatal "stripping $label ($src) produced an EMPTY file. The gate refuses to compare husks."
  fi

  if ! grep -q -- '---- MODULE' "$stripped"; then
    fatal "stripping $label ($src) destroyed the module header. The gate refuses to compare husks."
  fi

  if has_algorithm_block "$src" && ! has_algorithm_block "$stripped"; then
    fatal "stripping $label ($src) DELETED THE PLUSCAL ALGORITHM BLOCK.
       In PlusCal the algorithm lives inside (* --algorithm ... *), which the TLA+
       grammar calls a comment. A stripper that honours that grammar deletes the
       spec, and the gate then compares two husks and reports a vacuous PASS.
       See V2-PLAN.md §5.6. Refusing to render a verdict."
  fi

  if has_algorithm_block "$src" && ! grep -q -- 'BEGIN TRANSLATION' "$stripped" \
     && grep -q -- 'BEGIN TRANSLATION' "$src"; then
    fatal "stripping $label ($src) destroyed the \\* BEGIN TRANSLATION marker."
  fi
}

# CHECK 1 — strip both, normalize, diff.
check_strip_and_diff() {
  local frozen="$1" commented="$2" workdir="$3"
  local fs="$workdir/frozen.stripped" cs="$workdir/commented.stripped"

  strip_comments "$frozen"    > "$fs"
  strip_comments "$commented" > "$cs"

  assert_not_vacuous "$frozen"    "$fs" "the frozen spec"
  assert_not_vacuous "$commented" "$cs" "the commented spec"

  if diff -u "$fs" "$cs" > "$workdir/strip.diff" 2>&1; then
    log "  [check 1] strip-and-diff: PASS ($(wc -l < "$fs") stripped lines compared)"
    return 0
  fi

  log "  [check 1] strip-and-diff: FAIL — the comment pass changed the spec."
  log "            (--- frozen, +++ commented, comments already removed from both)"
  sed 's/^/            /' "$workdir/strip.diff" >&2
  return 1
}

# CHECK 2 — re-run pcal over both, require byte-identical TRANSLATION bodies.
check_pcal_translation() {
  local frozen="$1" commented="$2" workdir="$3"
  local base_f base_c

  command -v pcal >/dev/null 2>&1 \
    || fatal "spec is PlusCal but pcal is not on PATH. Refusing to run a weakened gate."

  base_f="$(basename "$frozen")"
  base_c="$(basename "$commented")"

  mkdir -p "$workdir/pcal-frozen" "$workdir/pcal-commented"
  cp "$frozen"    "$workdir/pcal-frozen/$base_f"
  cp "$commented" "$workdir/pcal-commented/$base_c"

  ( cd "$workdir/pcal-frozen"    && pcal "$base_f" ) > "$workdir/pcal-frozen.log" 2>&1 \
    || fatal "pcal failed on the frozen spec. See $workdir/pcal-frozen.log"
  ( cd "$workdir/pcal-commented" && pcal "$base_c" ) > "$workdir/pcal-commented.log" 2>&1 \
    || { log "  [check 2] pcal FAILED on the commented spec — the comment pass broke the algorithm:"
         sed 's/^/            /' "$workdir/pcal-commented.log" >&2
         return 1; }

  awk "$TRANSLATION_AWK" "$workdir/pcal-frozen/$base_f"    > "$workdir/frozen.translation"
  awk "$TRANSLATION_AWK" "$workdir/pcal-commented/$base_c" > "$workdir/commented.translation"

  # Anti-vacuity again: two empty translations are not a passing comparison.
  [ -s "$workdir/frozen.translation" ] \
    || fatal "pcal produced no TRANSLATION block for the frozen spec. Refusing to compare husks."
  [ -s "$workdir/commented.translation" ] \
    || fatal "pcal produced no TRANSLATION block for the commented spec. Refusing to compare husks."

  if cmp -s "$workdir/frozen.translation" "$workdir/commented.translation"; then
    log "  [check 2] pcal re-translation: PASS (TRANSLATION byte-identical, $(wc -c < "$workdir/frozen.translation") bytes)"
    return 0
  fi

  log "  [check 2] pcal re-translation: FAIL — regenerated TRANSLATION differs, so the"
  log "            comment pass touched the ALGORITHM, not just the commentary."
  diff -u "$workdir/frozen.translation" "$workdir/commented.translation" \
    | sed 's/^/            /' >&2 || true
  return 1
}

run_gate() {
  local frozen="$1" commented="$2"
  local workdir rc=0 pluscal=0

  [ -f "$frozen" ]    || fatal "frozen spec not found: $frozen"
  [ -f "$commented" ] || fatal "commented spec not found: $commented"

  GATE_TMP="$(mktemp -d "${TMPDIR:-/tmp}/comment-gate.XXXXXX")"
  workdir="$GATE_TMP"

  if has_algorithm_block "$frozen"; then pluscal=1; fi

  if [ "$pluscal" = 1 ]; then
    log "comment-gate: PlusCal spec detected — running strip-and-diff + pcal re-translation."
  else
    log "comment-gate: pure TLA+ spec (no algorithm block) — running strip-and-diff."
  fi
  log "  frozen:    $frozen"
  log "  commented: $commented"

  check_strip_and_diff "$frozen" "$commented" "$workdir" || rc=1

  if [ "$pluscal" = 1 ]; then
    check_pcal_translation "$frozen" "$commented" "$workdir" || rc=1
  fi

  if [ "$rc" = 0 ]; then
    log "comment-gate: PASS — the commented spec is the frozen spec plus comments."
    return "$EXIT_PASS"
  fi
  log "comment-gate: FAIL — §3.8 violated: the comment pass changed the spec."
  return "$EXIT_FAIL"
}

# --------------------------------------------------------------------------
# Self-test
# --------------------------------------------------------------------------
ST_PASS=0
ST_FAIL=0

st_ok()  { ST_PASS=$((ST_PASS + 1)); printf '  ok    %s\n' "$1"; }
st_bad() { ST_FAIL=$((ST_FAIL + 1)); printf '  FAIL  %s\n' "$1"; }

st_expect() {
  local want="$1" name="$2" frozen="$3" commented="$4" rc=0 out
  out="$("$0" "$FIXTURE_DIR/$frozen" "$FIXTURE_DIR/$commented" 2>&1)" || rc=$?
  if [ "$rc" = "$want" ]; then
    st_ok "$name (exit $rc)"
  else
    st_bad "$name — expected exit $want, got $rc"
    printf '%s\n' "$out" | sed 's/^/          | /'
  fi
}

st_assert_contains() {
  local file="$1" needle="$2" name="$3"
  if grep -qF -- "$needle" "$file"; then st_ok "$name"; else st_bad "$name"; fi
}

st_assert_absent() {
  local file="$1" needle="$2" name="$3"
  if grep -qF -- "$needle" "$file"; then st_bad "$name"; else st_ok "$name"; fi
}

self_test() {
  local work stripped naive_stripped rc lines
  GATE_TMP="$(mktemp -d "${TMPDIR:-/tmp}/comment-gate-selftest.XXXXXX")"
  work="$GATE_TMP"

  [ -d "$FIXTURE_DIR" ] || fatal "fixture directory missing: $FIXTURE_DIR"

  if [ "${COMMENT_GATE_STRIPPER:-}" = "naive" ]; then
    printf 'comment-gate self-test  [STRIPPER=naive — this run is EXPECTED TO FAIL]\n\n'
  else
    printf 'comment-gate self-test\n\n'
  fi

  # ---- RED: the algorithm block must survive the stripper -----------------
  # bd tla-kl5.9 RED: GIVEN a PlusCal spec whose algorithm lives inside
  # (* --algorithm ... *), WHEN comment-gate.sh strips comments, THEN the
  # algorithm block survives and the gate compares real specs — a naive
  # stripper that deletes it must FAIL this test.
  printf 'RED — the stripper preserves the PlusCal algorithm block\n'
  stripped="$work/frozen.stripped"
  strip_comments "$FIXTURE_DIR/pluscal/frozen/lightswitch.tla" > "$stripped"

  st_assert_contains "$stripped" '--algorithm lightswitch'   'algorithm header survives stripping'
  st_assert_contains "$stripped" 'while(count<3)'            'algorithm control flow survives stripping'
  st_assert_contains "$stripped" 'light := "on";'            'algorithm body survives stripping'
  # These two strings occur ONLY inside the algorithm block. `AlwaysOff` and
  # `TypeOk` deliberately are not used here: pcal copies the define block into
  # the generated translation, so they survive even the naive stripper and
  # would not discriminate.
  st_assert_contains "$stripped" '  light="off",'          'algorithm variable init survives stripping'
  st_assert_contains "$stripped" 'process (lightswitch = "Lightswitch")' \
                                                           'algorithm process declaration survives stripping'
  st_assert_contains "$stripped" '\* BEGIN TRANSLATION'      'BEGIN TRANSLATION marker survives stripping'
  st_assert_contains "$stripped" '\* END TRANSLATION'        'END TRANSLATION marker survives stripping'
  st_assert_contains "$stripped" '---- MODULE lightswitch'   'module header survives stripping'

  lines="$(wc -l < "$stripped")"
  if [ "$lines" -ge 30 ]; then
    st_ok "stripped spec is a real spec, not a husk ($lines lines)"
  else
    st_bad "stripped spec collapsed to $lines lines — the gate would compare husks"
  fi

  # Comments must still be gone, including ones nested inside the algorithm.
  st_assert_absent "$stripped" 'chksum(pcal)' 'derived pcal checksum normalized off the marker'

  # ---- The trap, asserted so it can never quietly return ------------------
  printf '\nRED — the naive (grammatically correct) stripper deletes the spec\n'
  naive_stripped="$work/frozen.naive"
  COMMENT_GATE_STRIPPER=naive strip_comments \
    "$FIXTURE_DIR/pluscal/frozen/lightswitch.tla" > "$naive_stripped" 2>/dev/null || true
  st_assert_absent "$naive_stripped" '--algorithm'    'naive stripper DELETES the algorithm header'
  st_assert_absent "$naive_stripped" 'while(count<3)' 'naive stripper DELETES the algorithm body'

  rc=0
  COMMENT_GATE_STRIPPER=naive "$0" \
    "$FIXTURE_DIR/pluscal/frozen/lightswitch.tla" \
    "$FIXTURE_DIR/pluscal/commented-edited-algorithm/lightswitch.tla" \
    >/dev/null 2>&1 || rc=$?
  if [ "$rc" = "$EXIT_ABORT" ]; then
    st_ok "naive stripper ABORTS the gate (exit 3) instead of passing vacuously"
  else
    st_bad "naive stripper produced exit $rc — expected 3 (ABORT); a vacuous verdict is shippable"
  fi

  # ---- Fixture matrix ------------------------------------------------------
  printf '\nFixture matrix — PlusCal (algorithm inside a block comment)\n'
  st_expect "$EXIT_PASS" 'legitimately commented           -> PASS' \
    'pluscal/frozen/lightswitch.tla' 'pluscal/commented-ok/lightswitch.tla'
  st_expect "$EXIT_FAIL" 'commented + algorithm edited     -> FAIL' \
    'pluscal/frozen/lightswitch.tla' 'pluscal/commented-edited-algorithm/lightswitch.tla'
  st_expect "$EXIT_FAIL" 'commented + line deleted         -> FAIL' \
    'pluscal/frozen/lightswitch.tla' 'pluscal/commented-deleted-conjunct/lightswitch.tla'
  st_expect "$EXIT_FAIL" 'commented + translation patched  -> FAIL (check 1 only)' \
    'pluscal/frozen/lightswitch.tla' 'pluscal/commented-edited-translation/lightswitch.tla'
  st_expect "$EXIT_FAIL" 'commented + EXTENDS changed      -> FAIL (check 1 only)' \
    'pluscal/frozen/lightswitch.tla' 'pluscal/commented-edited-outside/lightswitch.tla'

  printf '\nFixture matrix — PlusCal, fair algorithm header\n'
  stripped="$work/fair.stripped"
  strip_comments "$FIXTURE_DIR/pluscal-fair/frozen/fairswitch.tla" > "$stripped"
  st_assert_contains "$stripped" '--fair algorithm lightswitch' \
    'the --fair algorithm header survives stripping'
  st_expect "$EXIT_PASS" 'legitimately commented           -> PASS' \
    'pluscal-fair/frozen/fairswitch.tla' 'pluscal-fair/commented-ok/fairswitch.tla'
  # Fairness silently dropped during the comment pass: WF_vars(Next) disappears
  # from the regenerated translation. This is the case check 2 exists for.
  st_expect "$EXIT_FAIL" 'commented + fairness dropped     -> FAIL' \
    'pluscal-fair/frozen/fairswitch.tla' 'pluscal-fair/commented-defaired/fairswitch.tla'

  printf '\nFixture matrix — pure TLA+ (no algorithm block)\n'
  st_expect "$EXIT_PASS" 'legitimately commented           -> PASS' \
    'tla/frozen/Clock.tla' 'tla/commented-ok/Clock.tla'
  st_expect "$EXIT_FAIL" 'commented + action edited        -> FAIL' \
    'tla/frozen/Clock.tla' 'tla/commented-edited/Clock.tla'

  printf '\nFixture matrix — degenerate inputs\n'
  st_expect "$EXIT_PASS" 'a spec against itself            -> PASS' \
    'pluscal/frozen/lightswitch.tla' 'pluscal/frozen/lightswitch.tla'
  st_expect "$EXIT_PASS" 'a pure-TLA+ spec against itself  -> PASS' \
    'tla/frozen/Clock.tla' 'tla/frozen/Clock.tla'

  printf '\n%s passed, %s failed\n' "$ST_PASS" "$ST_FAIL"
  [ "$ST_FAIL" = 0 ] || return "$EXIT_FAIL"
  return "$EXIT_PASS"
}

usage() {
  cat >&2 <<'USAGE'
comment-gate.sh — the v2 harness comment-pass gate (V2-PLAN.md §3.8, §5.6).

Proves that a commented spec is the frozen spec PLUS comments and nothing else.

Usage:
  comment-gate.sh <frozen.tla> <commented.tla>   run the gate
  comment-gate.sh --strip <spec.tla>             print the comment-stripped form
  comment-gate.sh --self-test                    run the fixture matrix

Exit codes:
  0  PASS   the commented spec is the frozen spec plus comments
  1  FAIL   the comment pass changed the spec
  2  USAGE  bad invocation
  3  ABORT  the gate could not run soundly and refuses to render a verdict

Environment:
  COMMENT_GATE_STRIPPER=naive   select the grammatically-correct-but-fatal
                                stripper, which deletes a PlusCal algorithm
                                block. Kept so the trap stays reproducible;
                                the gate ABORTs rather than passing vacuously.
USAGE
  exit "$EXIT_USAGE"
}

main() {
  case "${1:-}" in
    --self-test) self_test ;;
    --strip)
      [ $# -eq 2 ] || usage
      [ -f "$2" ] || fatal "not found: $2"
      strip_comments "$2"
      ;;
    -h|--help|'') usage ;;
    -*) usage ;;
    *)
      [ $# -eq 2 ] || usage
      run_gate "$1" "$2"
      ;;
  esac
}

main "$@"
