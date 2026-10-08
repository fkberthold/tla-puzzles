#!/usr/bin/env bash
# test-indeterminate.sh — the reserved-indeterminate gate (bead tla-hl96).
#
# THE DEFECT SHAPE THIS GATE EXISTS FOR
#
#   An instrument whose check COULD NOT RUN reports SUCCESS rather than
#   indeterminate. The caller reads an exit code, sees a pass, and the thing
#   the instrument exists to catch walks through.
#
#   V2-PLAN.md §5.1 already forbids reading a verdict from stdout. This is the
#   same principle one level up: an exit code that cannot distinguish "passed"
#   from "did not run" is not a verdict channel either. And it is strictly
#   worse than the advisory grep CLAUDE.md's gate-don't-advise rule bans,
#   because the advisory grep at least does not lie.
#
#   Three sites were found on 2026-10-08, each by a different agent looking at
#   something else, and none of the three would have been found by looking for
#   it:
#
#     screen.sh   CLEAR, exit 0, with step 1 (the GitHub code-search name
#                 collision check) skipped because the call failed.
#     vacuity.sh  NON_VACUOUS, rc 0, with the satisfiability, dead-action and
#                 frozen-observation probes SKIPPED. That happens on every
#                 model that violates its configured invariant -- which is
#                 every broken-variant run, which is exactly the run a spike
#                 author cares about. Its remediation text said the probes
#                 were skipped. Its TOKEN did not, and the token is what a
#                 script reads.
#     verdict.sh  -deadlock passed unconditionally while TLC's deadlock
#                 checking is an AND across the .cfg and the command line, so
#                 a learner's CHECK_DEADLOCK TRUE got no check and no notice.
#
# THE RESERVED CODE
#
#   99  CHECK_DID_NOT_RUN   the instrument was asked for a check it could not
#                           perform. NOT a verdict about the subject.
#
#   99 is clear of every band any instrument in this tree already documents
#   (screen 0-2 + 64, comment-gate 0-3, grade 0-5, vacuity 0-8, verdict's TLC
#   rows 0/10-14/75-77/124/150/151/255, refinement 20-30, seeded-bugs 40-46).
#   It sits BELOW 124, so it cannot be read as timeout(1)'s verdict, and below
#   126, so it cannot be read as the shell's own "not executable" / "not
#   found" / 128+signal range. Part 1 asserts the non-collision rather than
#   asking a reader to take the paragraph's word for it.
#
# ---------------------------------------------------------------------------
# WHAT THIS GATE CHECKS, AND WHAT IT DELIBERATELY DOES NOT
# ---------------------------------------------------------------------------
#
# Read this section before trusting a pass from this suite. A gate that
# reported a pass over a shape it cannot detect would be this very defect, one
# level up again.
#
# IT CHECKS, in the five parts below:
#
#   1. That 99 is reserved: bound to one name, paired with one token, and
#      documented by nothing else as anything else.
#
#   2. THE CENSUS, which is the fourth-site detector. Every instrument under
#      harness/ -- every `harness/*.sh` that is not a test suite, selected
#      from the tree rather than from a list, so a new instrument is covered
#      the moment it lands -- is scanned, comments stripped, for a fixed
#      vocabulary of phrases that ADMIT A SKIP. An instrument that can admit
#      a skip and is not driven by a row of this suite FAILS the census.
#
#   3. That no run which admitted an INVOLUNTARY skip returned a success code.
#      The convention that makes "involuntary" decidable from the output is in
#      THE PARENTHETICAL RULE below.
#
#   4. The SILENT class, by enumeration. See the next block.
#
#   5. That each instrument still passes a clean run, so the gate is shown to
#      discriminate rather than to flag everything.
#
# IT DOES NOT CHECK, and each of these is a real hole rather than a caveat:
#
#   A. IT PROVES NO PATH. Part 3 reports on the invocations it made and on
#      nothing else. It never establishes that a skip admission cannot ride a
#      success code on some other input. Coverage here is the registry, not
#      the program, and a static proof of the property is not available at
#      this altitude.
#
#   B. IT CANNOT SEE A SILENT SKIP. The census works off phrases the
#      instrument prints. verdict.sh printed nothing at all about the
#      discarded CHECK_DEADLOCK keyword, so the census MISSES site 3
#      completely, and part 4 covers it by name rather than by detection.
#      A FOURTH SILENT SITE WILL NOT BE FOUND BY THIS GATE. That is the
#      largest thing wrong with it, and no amount of vocabulary fixes it:
#      the signal is absent from the surface being scanned.
#
#   C. ITS VOCABULARY IS A FIXED LIST OF ENGLISH PHRASES. An instrument that
#      admits a skip in words outside SKIP_VOCAB is invisible to the census.
#      Part 2 prints every instrument it scanned and every line it matched, so
#      the surface is visible in the output rather than implied by a pass.
#
#   D. IT DOES NOT COVER THE TEST SUITES. `harness/test-*.sh` and
#      `harness/fixtures/*/selftest.sh` are excluded. Their "N skipped" lines
#      are honest self-reporting at a different altitude -- but note that
#      harness/test-corpus-manifest.sh already exits 0 having reported 10
#      skipped checks, and scripts/test prints only PASS. Whether a suite may
#      report PASS to scripts/test over checks it did not run is a real
#      question, and this gate does not answer it.
#
#   E. IT DOES NOT COVER scripts/. Only harness/.
#
# ---------------------------------------------------------------------------
# THE PARENTHETICAL RULE — how a waived skip is told from an involuntary one
# ---------------------------------------------------------------------------
#
# A skip the CALLER ASKED FOR is not an indeterminate result. `--offline`
# means "no network at all"; `--expect none` means "do not probe the
# configured check"; `--no-dead-actions` means what it says. Returning 99 for
# those would refuse to serve a caller who stated their own scope.
#
# So the two have to be distinguishable, and the output is where a gate can
# see the difference. The convention, and new instruments follow it:
#
#     A LINE THAT ADMITS A SKIP NAMES, IN PARENTHESES, THE CALLER FLAG THAT
#     WAIVED IT. A SKIP ADMISSION WITH NO SUCH PARENTHETICAL IS INVOLUNTARY
#     AND MUST CARRY THE RESERVED CODE.
#
#   waived:        "query: '... language:tla'  -- skipped (offline)"
#                  "The configured-check probe was skipped (--expect none)"
#   involuntary:   "The satisfiability probe did not run, so nothing here
#                   says Spec admits a behaviour."
#
# This was not free. vacuity.sh used ONE sentence for both causes of a skipped
# dead-action probe -- the caller's --no-dead-actions and an earlier probe
# stopping at a violation -- so no output-based gate could tell them apart.
# Bead tla-hl96 split the sentence. A report that cannot distinguish "you told
# me not to" from "I could not" is not reporting the thing that matters.
#
# Usage:  harness/test-indeterminate.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

INDETERMINATE=99
TOKEN="CHECK_DID_NOT_RUN"

FIX="harness/fixtures/indeterminate"
SCREEN="harness/screen.sh"
VACUITY="harness/vacuity.sh"
VERDICT="harness/verdict.sh"
CGATE="harness/comment-gate.sh"

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

# ---------------------------------------------------------------------------
# THE VOCABULARY
#
# SKIP_VOCAB is matched case-insensitively against an instrument's
# comment-stripped source (part 2) and against a run's combined output
# (part 3). WAIVED_VOCAB is the parenthetical rule above, plus `(offline)`,
# which names a mode rather than a flag and is screen.sh's spelling.
#
# Kept as two single-quoted EREs so the census and the behavioural check
# cannot drift apart: there is one definition of "admits a skip" in this file.
# ---------------------------------------------------------------------------
SKIP_VOCAB='skipped|did not run|could not run|never ran|was not looked for|could not be assessed|unavailable|was not checked|was not run'
WAIVED_VOCAB='\((offline|(no )?--[a-z][a-z0-9 -]*)\)'

# Lines of $1 that admit a skip and do NOT name a waiving flag.
involuntary_admissions() {
  local hits waived line out=""
  hits=$(grep -nEi -- "$SKIP_VOCAB" <<<"$1")
  [ -n "$hits" ] || return 0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    waived=$(grep -cE -- "$WAIVED_VOCAB" <<<"$line")
    [ "$waived" = "0" ] && out="${out}${line}"$'\n'
  done <<<"$hits"
  printf '%s' "$out"
}

# ===========================================================================
# THE REGISTRY
#
# One entry per instrument the census obliges this suite to drive. The three
# counters run in parallel with it, the way test-pipefail.sh's ALLOW_HITS runs
# in parallel with ALLOW_KEYS: pre-sized, because an unset element would abort
# the suite under `set -u`.
# ===========================================================================
# verdict.sh is registered even though the census is BLIND to the defect it
# carried (hole B: it printed nothing at all about the discarded keyword). Its
# refusal now says "did not run", so the census reaches it from here on, and a
# second silent-skip path added to it later lands in part 3 rather than in
# nobody's lap.
REGISTERED=("$SCREEN" "$VACUITY" "$VERDICT" "$CGATE")
ROWS_RUN=()
ROWS_NONPASS=()
for i in "${!REGISTERED[@]}"; do
  ROWS_RUN[i]=0
  ROWS_NONPASS[i]=0
done

note_row() {
  local inst="$1" rc="$2" i
  for i in "${!REGISTERED[@]}"; do
    if [ "$inst" = "${REGISTERED[$i]}" ]; then
      ROWS_RUN[i]=$((ROWS_RUN[i] + 1))
      [ "$rc" != "0" ] && ROWS_NONPASS[i]=$((ROWS_NONPASS[i] + 1))
    fi
  done
}

# run_row <instrument> <label> <want-rc> -- <command...>
#
# Two assertions per row, and the second is the point of the suite: the rc the
# row declares, AND that no involuntary skip admission rode a success code.
RUN_OUT=""
RUN_RC=0
run_row() {
  local inst="$1" label="$2" want="$3"
  shift 4 # instrument, label, want-rc, the literal --

  RUN_OUT=$("$@" 2>&1)
  RUN_RC=$?
  note_row "$inst" "$RUN_RC"

  if [ "$RUN_RC" = "$want" ]; then
    ok "$label — rc=$want"
  else
    nope "$label — wanted rc=$want, got rc=$RUN_RC"
  fi

  local adm
  adm=$(involuntary_admissions "$RUN_OUT")
  if [ -z "$adm" ]; then
    return 0
  fi
  if [ "$RUN_RC" = "0" ]; then
    nope "$label — ADMITTED A SKIP AND RETURNED SUCCESS: $(tr '\n' ' ' <<<"$adm")"
  else
    ok "$label — admitted a skip and did not return success (rc=$RUN_RC)"
  fi
}

# assert_out <label> <substring>   over the last run_row's output
assert_out() {
  if grep -qF -- "$2" <<<"$RUN_OUT"; then
    ok "$1"
  else
    nope "$1 — output lacks '$2'"
  fi
}

assert_not_out() {
  if grep -qF -- "$2" <<<"$RUN_OUT"; then
    nope "$1 — output still carries '$2'"
  else
    ok "$1"
  fi
}

# assert_token <label> <want>   LINE 1 of the last run_row's output.
#
# Line 1 and not the whole output: vacuity.sh's remediation prose legitimately
# names the other tokens while explaining what it did not establish, and a
# whole-output match would turn its own explanation into a failure. The token
# is a position in the protocol, so the assertion is about that position.
assert_token() {
  local first=${RUN_OUT%%$'\n'*}
  if [ "$first" = "$2" ]; then
    ok "$1"
  else
    nope "$1 — line 1 is '$first', wanted '$2'"
  fi
}

# ===========================================================================
echo "== part 1: 99 is reserved, and collides with nothing =="
# ===========================================================================

# Bound to a NAME in each instrument that can return it, not sprinkled as a
# literal. A bare `exit 99` three files apart is three conventions.
for f in "$SCREEN" "$VACUITY" "$VERDICT"; do
  body=$(sed 's/^[[:space:]]*#.*$//' "$f")
  if grep -qE -- "^[A-Z_]*INDETERMINATE=$INDETERMINATE\$" <<<"$body"; then
    ok "$(basename "$f") binds $INDETERMINATE to a *INDETERMINATE name"
  else
    nope "$(basename "$f") does not bind $INDETERMINATE to a *INDETERMINATE name"
  fi
  if grep -qF -- "$TOKEN" <<<"$body"; then
    ok "$(basename "$f") carries the $TOKEN token"
  else
    nope "$(basename "$f") does not carry the $TOKEN token"
  fi
done

# THE NON-COLLISION, asserted rather than asserted-in-prose. Every instrument
# documents its codes in a header table of the shape `#   <num>  <TOKEN>`.
# Harvest every number from every one of them and require that 99 appears
# only against the reserved token.
#
# This is what catches a future instrument that reaches for 99 for its own
# verdict: the code would then mean two things, and a caller asking "did the
# check run?" would get the wrong answer from one of them.
collision=""
reserved_rows=0
for f in harness/*.sh; do
  case "$(basename "$f")" in
  test-*) continue ;;
  esac
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    # `read` skips leading IFS whitespace, which is the whole reason it is
    # here rather than a `${row%% *}`: the leading `#` becomes a space under
    # `tr`, so a prefix strip takes the empty string and every row reads as
    # "no number". The first RED run of this suite reported 0 matching rows
    # for exactly that reason, against three rows that were present.
    read -r num _rest <<<"$(tr -cs '0-9' ' ' <<<"$row")"
    [ "$num" = "$INDETERMINATE" ] || continue
    if grep -qF -- "$TOKEN" <<<"$row"; then
      reserved_rows=$((reserved_rows + 1))
    else
      collision="${collision}${f}: ${row}"$'\n'
    fi
  done < <(grep -hE -- '^#[[:space:]]+[0-9]+[[:space:]]+[A-Z_]{3,}' "$f")
done
if [ -z "$collision" ]; then
  ok "no instrument documents $INDETERMINATE against any token but $TOKEN"
else
  nope "$INDETERMINATE is documented for something else — $(tr '\n' ' ' <<<"$collision")"
fi
if [ "$reserved_rows" -ge 3 ]; then
  ok "$reserved_rows verdict-table rows document $INDETERMINATE $TOKEN"
else
  nope "only $reserved_rows verdict-table row(s) document $INDETERMINATE $TOKEN — wanted >= 3"
fi

# 99 is below timeout(1)'s 124/125 and below the shell's 126/127/128+. A
# reserved code that collided with either would be indistinguishable from an
# infrastructure failure, which is a different fact and needs a different fix.
if [ "$INDETERMINATE" -lt 124 ]; then
  ok "$INDETERMINATE is below timeout(1)'s 124 and the shell's 126/127/128+"
else
  nope "$INDETERMINATE collides with the timeout/shell/signal range"
fi

# ===========================================================================
echo
echo "== part 2: the census — every skip-admitting instrument is driven =="
# ===========================================================================
#
# THE FOURTH-SITE DETECTOR. The instrument set comes from the TREE, by the
# same reasoning harness/test-pipefail.sh selects by shebang rather than from
# a list: a check that reads a list covers what somebody remembered, and the
# whole point here is the site nobody was looking for.
#
# Scope is `harness/*.sh` minus `test-*.sh` -- the instruments, one directory
# deep. Fixture stubs under harness/fixtures/ are excluded: they are inputs to
# the suites, not instruments a caller branches on. See hole D in the header
# for the test suites.
# ===========================================================================

#
# A FUNCTION, and not an inline loop, for the reason test-pipefail.sh's
# selector is one: a detector that only ever runs over the real tree cannot be
# controlled. If it silently stops admitting a whole class of file, every
# assertion below still reports "found nothing" and passes -- which is this
# bead's own defect wearing a green tick. The control at the end of this part
# runs the same two functions over a planted tree.
CENSUS_FILES=()
census_select() {
  CENSUS_FILES=()
  local f
  for f in "$1"/*.sh; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in
    test-*) continue ;;
    esac
    CENSUS_FILES+=("$f")
  done
}

# Sets CENSUS_ADMITS to the files that admit a skip, and CENSUS_LINES to the
# matching lines, both newline-separated.
CENSUS_ADMITS=""
CENSUS_LINES=""
census_scan() {
  CENSUS_ADMITS=""
  CENSUS_LINES=""
  local f body hits
  for f in ${CENSUS_FILES[@]+"${CENSUS_FILES[@]}"}; do
    body=$(sed 's/^[[:space:]]*#.*$//' "$f")
    hits=$(grep -nEi -- "$SKIP_VOCAB" <<<"$body")
    [ -n "$hits" ] || continue
    CENSUS_ADMITS="${CENSUS_ADMITS}${f}"$'\n'
    # Indented through a parameter expansion rather than a line-prefix
    # rewrite: the first line takes the literal indent below and every
    # newline carries its own.
    CENSUS_LINES="${CENSUS_LINES}${f}:
        ${hits//$'\n'/$'\n'        }
"
  done
}

census_select harness
if [ "${#CENSUS_FILES[@]}" -ge 10 ]; then
  ok "census scanned ${#CENSUS_FILES[@]} instruments: $(basename -a "${CENSUS_FILES[@]}" | tr '\n' ' ')"
else
  nope "census found only ${#CENSUS_FILES[@]} instruments under harness/ — the glob is wrong"
fi
census_scan

unregistered=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  is_reg=0
  for r in "${REGISTERED[@]}"; do
    [ "$f" = "$r" ] && is_reg=1
  done
  if [ "$is_reg" = "1" ]; then
    ok "$(basename "$f") admits a skip and is registered"
  else
    unregistered="${unregistered}${f}"$'\n'
  fi
done <<<"$CENSUS_ADMITS"

if [ -z "$unregistered" ]; then
  ok "every skip-admitting instrument appears in the registry"
else
  nope "UNREGISTERED instrument(s) can admit a skip — drive them from this suite, or fix them:
$(tr '\n' ' ' <<<"$unregistered")
$CENSUS_LINES"
fi

# --- the controls: the census has to be shown to BITE ----------------------
#
# Both directions, over a planted tree. One direction alone is worthless: a
# detector that flags everything satisfies the positive control, and a
# detector that flags nothing satisfies the negative one. Only the pair says
# the thing discriminates.
PLANT=$(mktemp -d -t tla_census.XXXXXX)
trap 'rm -rf "$PLANT"' EXIT

# The single quotes are the point: this printf writes the SOURCE TEXT of a
# planted shell script, so `$answer` has to reach the file unexpanded. The
# directive goes last and adjacent to the line, with the reason above it --
# a continuation starting with the word shellcheck is parsed as a second
# directive, which is how bead tla-5r7 raised ten SC1072s on its first try.
# shellcheck disable=SC2016
printf '#!/usr/bin/env bash\nstatus="CLEAR"\nif [ -z "$answer" ]; then\n  printf "the probe did not run\\n"\nfi\nexit 0\n' >"$PLANT/planted-instrument.sh"
printf '#!/usr/bin/env bash\nprintf "all good\\n"\nexit 0\n' >"$PLANT/quiet-instrument.sh"
printf '#!/usr/bin/env bash\nprintf "the probe did not run\\n"\nexit 0\n' >"$PLANT/test-planted.sh"

census_select "$PLANT"
census_scan

if grep -qF -- "planted-instrument.sh" <<<"$CENSUS_ADMITS"; then
  ok "control: the census FINDS a planted instrument that admits a skip"
else
  nope "control: the census MISSED a planted instrument — it is not detecting anything"
fi
if grep -qF -- "quiet-instrument.sh" <<<"$CENSUS_ADMITS"; then
  nope "control: the census flagged an instrument that admits nothing"
else
  ok "control: the census does NOT flag an instrument that admits nothing"
fi
# And the exclusion, which is hole D in the header made checkable rather than
# merely stated. A test suite that says "skipped" is out of scope on purpose,
# so the selector has to be shown to leave it out.
if grep -qF -- "test-planted.sh" <<<"$CENSUS_ADMITS"; then
  nope "control: the census scanned a test-*.sh — the exclusion in hole D is not holding"
else
  ok "control: the census excludes test-*.sh, as hole D says it does"
fi

# The registry must not carry an entry nothing drives, and every registered
# instrument must have at least one row that is NOT a pass. A registry row
# whose every invocation returns 0 proves the instrument was run, not that its
# skip path was reached -- which is the loophole the census would otherwise
# leave wide open. Checked in part 6, once the rows have run.

# ===========================================================================
echo
echo "== part 3: a skip admission never rides a success code =="
# ===========================================================================

# --- site 1: screen.sh, the code-search step that could not run -------------
#
# The token is now fixed, so the 401 this was filed against no longer
# reproduces. The stub reproduces the SHAPE instead -- an answer that is not a
# number -- which is also what a rate-limit 403 produces. Measured: gh writes
# GitHub's error BODY to stdout and exits nonzero, and no line of that body is
# bare digits, so a 403 can never be read as a zero. See the stub's header.
run_row "$SCREEN" "screen.sh: code search unavailable is not CLEAR" \
  "$INDETERMINATE" -- \
  env SCREEN_GH="$FIX/gh-unavailable" \
  SCREEN_README="harness/fixtures/screen/examples-README.md" \
  SCREEN_CACHE_DIR="$(mktemp -d)" \
  SCREEN_SLEEP=0 \
  bash "$SCREEN" --name NovelSoundingName "ski pass validation with blackout dates"
assert_out "screen.sh names the step it could not run" "code search unavailable"
assert_not_out "screen.sh does not claim CLEAR over it" "VERDICT: CLEAR"

# ...and the name step with nothing to derive a name FROM. A candidate phrase
# that yields no name is a step that did not run, not a step that passed.
run_row "$SCREEN" "screen.sh: no derivable name is not CLEAR" \
  "$INDETERMINATE" -- \
  env SCREEN_GH="$FIX/gh-unavailable" \
  SCREEN_README="harness/fixtures/screen/examples-README.md" \
  SCREEN_CACHE_DIR="$(mktemp -d)" \
  SCREEN_SLEEP=0 \
  bash "$SCREEN" --name "" "the of a an"

# --- site 2: vacuity.sh, the three probes an earlier violation skips --------
#
# ViolatedWithDeadAction.tla carries two faults on purpose: its INVARIANT is
# violated, AND Overflow can never fire. Fault 1 stops probe 2 at rc=12, every
# later probe is guarded on `nv_rc = 0`, and fault 2 is therefore never looked
# for. Before this bead the run reported NON_VACUOUS rc 0 -- a pass over three
# probes that did not happen, on a module that would have failed one of them.
run_row "$VACUITY" "vacuity.sh: probes skipped by an earlier violation is not NON_VACUOUS" \
  "$INDETERMINATE" -- \
  bash "$VACUITY" --min-states 4 --observe NoSuchObservation \
  --config "$FIX/ViolatedWithDeadAction.cfg" "$FIX/ViolatedWithDeadAction.tla"
assert_token "vacuity.sh's verdict token is the reserved one" "$TOKEN"
assert_out "vacuity.sh names the satisfiability probe as not run" "satisfiability probe did not run"
assert_out "vacuity.sh names the dead-action probe as not run" "dead-action probe did not run"
assert_out "vacuity.sh names the frozen-observation probe as not run" "frozen-observation probe did not run"
# The partial assessment is worth the probes that DID deliver, so the summary
# that names them has to survive the skip report rather than be replaced by it.
assert_out "vacuity.sh still reports what it did establish" "non-empty state space"

# THE MASKING, shown rather than argued. The same module with its invariant
# satisfied IS caught as a dead action, so the probe that part 3's row proved
# was skipped is a probe that had something to find.
run_row "$VACUITY" "vacuity.sh: the same module, invariant satisfied, IS caught" \
  5 -- \
  bash "$VACUITY" --min-states 4 \
  --config "harness/fixtures/vacuity/DeadGuard.cfg" "harness/fixtures/vacuity/DeadGuard.tla"
assert_out "the masked fault is a dead action" "VACUOUS_DEAD_ACTION"

# --- the waived skips stay green, both instruments --------------------------
#
# The parenthetical rule from the header, from the other side. A caller who
# states their own scope is served, and the gate must not refuse them. Without
# these two rows the fix above could be satisfied by returning 99 for every
# skip of any kind, which would make --offline and --expect none unusable.
run_row "$SCREEN" "screen.sh: --offline is a caller instruction, not a failure" \
  0 -- \
  env SCREEN_GH="$FIX/gh-unavailable" \
  SCREEN_README="harness/fixtures/screen/examples-README.md" \
  SCREEN_CACHE_DIR="$(mktemp -d)" \
  bash "$SCREEN" --offline "ski pass validation with blackout dates"
assert_out "the offline skip names the mode that waived it" "skipped (offline)"

run_row "$VACUITY" "vacuity.sh: --expect none and --no-dead-actions are caller instructions" \
  0 -- \
  bash "$VACUITY" --min-states 4 --expect none --no-dead-actions \
  "harness/fixtures/vacuity/Healthy.tla"
assert_out "the configured-check waiver names its flag" "(--expect none)"
assert_out "the dead-action waiver names its flag" "(--no-dead-actions)"

# --- comment-gate.sh: the instrument that already got this right ------------
#
# THE POSITIVE CONTROL for the whole suite. comment-gate.sh's naive stripper
# deletes a PlusCal algorithm block, so the gate would be comparing two husks.
# It refuses: code 3 ABORT, "the gate could not run SOUNDLY and refuses to
# render a verdict". That is this bead's convention, arrived at independently
# and a bead earlier, and a gate that could not tell it apart from the three
# broken sites would be measuring nothing.
run_row "$CGATE" "comment-gate.sh: a stripper that destroys the spec ABORTs, not PASSes" \
  3 -- \
  env COMMENT_GATE_STRIPPER=naive \
  bash "$CGATE" \
  harness/fixtures/comment-gate/pluscal/frozen/lightswitch.tla \
  harness/fixtures/comment-gate/pluscal/commented-ok/lightswitch.tla
assert_out "comment-gate.sh says it refuses rather than passing" "ABORT"

# ===========================================================================
echo
echo "== part 4: the silent class — a skip that admits nothing =="
# ===========================================================================
#
# ENUMERATED, NOT DETECTED, and that is hole B in the header. verdict.sh
# printed not one word about the CHECK_DEADLOCK keyword it discarded, so no
# census over printed phrases can reach it. Every entry below is here because
# a human found it. The list cannot grow by itself.
#
# ENTRY 1 — TLC's deadlock checking is an AND across the .cfg keyword and the
# command line, and neither side mentions the other. Measured on TLC
# 2026.07.31.184830, all six cells, by this bead rather than taken on trust:
#
#     cfg keyword   -deadlock on the command line   rc
#     -----------   -----------------------------   ----
#     absent        absent                            11
#     absent        present                            0
#     TRUE          absent                            11
#     TRUE          present                            0   <- learner's keyword
#     FALSE         absent                             0   <- caller's flag
#     FALSE         present                            0
#
# 82 of 337 configs in the published corpus carry a CHECK_DEADLOCK line
# (.claude/rules/tla-practice.md §7), so this is ordinary practice.
#
# THE DESIGN CALL, and it went to the safer of the two options the bead named.
# verdict.sh does NOT stop passing -deadlock and let the cfg speak: TLC's
# default is checking ON, so honouring a silent cfg would turn every
# intended-terminal-state reference red, and 79 of 337 corpus configs carry
# CHECK_DEADLOCK FALSE precisely because their terminal states are intended.
# It keeps the flag and REFUSES THE RUN when the cfg and the command line
# disagree, which is the only outcome that neither lies nor changes the
# default under anybody's feet. The remedy is one flag and the message says
# which.
# ===========================================================================

verdict_row() {
  local label="$1" want="$2"
  shift 2
  RUN_OUT=$(bash "$VERDICT" "$@" 2>&1)
  RUN_RC=$?
  note_row "$VERDICT" "$RUN_RC"
  if [ "$RUN_RC" = "$want" ]; then
    ok "$label — rc=$want"
  else
    nope "$label — wanted rc=$want, got rc=$RUN_RC (output: $(tr '\n' ' ' <<<"$RUN_OUT"))"
  fi
  # The same admission check run_row applies, so verdict.sh's rows are held to
  # the registry's rule rather than to a looser local one.
  local adm
  adm=$(involuntary_admissions "$RUN_OUT")
  if [ -n "$adm" ] && [ "$RUN_RC" = "0" ]; then
    nope "$label — ADMITTED A SKIP AND RETURNED SUCCESS: $(tr '\n' ' ' <<<"$adm")"
  fi
}

# THE DEFECT. The learner wrote the keyword that checks for a deadlock, on a
# module that HAS one, and got OK rc 0.
verdict_row "verdict.sh: CHECK_DEADLOCK TRUE against the default flag is refused" \
  "$INDETERMINATE" \
  --config "$FIX/DeadlockKeywordTrue.cfg" "$FIX/DeadlockKeyword.tla"
assert_out "the refusal prints the reserved token" "$TOKEN"
assert_out "the refusal names the keyword" "CHECK_DEADLOCK"
assert_out "the refusal names the remedy" "--check-deadlock"

# THE OTHER DIRECTION, and it is the caller's flag being discarded rather than
# the learner's keyword. Same AND, same silence.
verdict_row "verdict.sh: CHECK_DEADLOCK FALSE against --check-deadlock is refused" \
  "$INDETERMINATE" \
  --check-deadlock --config "$FIX/DeadlockKeywordFalse.cfg" "$FIX/DeadlockKeyword.tla"

# AGREEMENT IS NOT CONFLICT, and these three rows are what stop the fix from
# being "refuse every cfg that mentions deadlock". Without them a refusal
# keyed on the keyword's PRESENCE would satisfy both rows above, and the 79
# corpus configs that write CHECK_DEADLOCK FALSE on purpose would all break.
verdict_row "verdict.sh: CHECK_DEADLOCK TRUE with --check-deadlock agrees and runs" \
  11 \
  --check-deadlock --config "$FIX/DeadlockKeywordTrue.cfg" "$FIX/DeadlockKeyword.tla"

verdict_row "verdict.sh: CHECK_DEADLOCK FALSE with the default flag agrees and runs" \
  0 \
  --config "$FIX/DeadlockKeywordFalse.cfg" "$FIX/DeadlockKeyword.tla"

verdict_row "verdict.sh: no keyword at all is not a conflict" \
  0 \
  --config "$FIX/DeadlockKeywordAbsent.cfg" "$FIX/DeadlockKeyword.tla"

# A KEYWORD INSIDE A COMMENT IS NOT A KEYWORD. The scan has to strip `\*` to
# end of line AND track `(* *)` depth, because a .cfg may carry either, and a
# refusal on a commented mention would be a gate that fires on prose.
verdict_row "verdict.sh: CHECK_DEADLOCK in a .cfg comment is not a keyword" \
  0 \
  --config "$FIX/DeadlockKeywordCommented.cfg" "$FIX/DeadlockKeyword.tla"

# THE REFUSAL PRECEDES TLC. A conflict detected after the run would report
# whatever that run found, which is the lie this part exists to remove. The
# module here does not exist, so TLC would answer 150 PARSE_ERROR; the
# conflict has to win.
verdict_row "verdict.sh: the refusal precedes the run" \
  "$INDETERMINATE" \
  --config "$FIX/DeadlockKeywordTrue.cfg" "$FIX/NoSuchModule.tla"

# ...and the negative control for that ordering: with no conflict, the missing
# module still reaches its own verdict. A refusal that swallowed every other
# answer would satisfy the row above on its own.
verdict_row "verdict.sh: with no conflict, a missing module is still 150" \
  150 \
  --config "$FIX/DeadlockKeywordAbsent.cfg" "$FIX/NoSuchModule.tla"

# ===========================================================================
echo
echo "== part 5: the controls — every instrument still passes a clean run =="
# ===========================================================================
#
# A gate that flagged everything would satisfy every assertion above. These
# rows are the discrimination.

run_row "$VACUITY" "vacuity.sh: a healthy module is still NON_VACUOUS rc 0" \
  0 -- \
  bash "$VACUITY" --min-states 4 "harness/fixtures/vacuity/Healthy.tla"
assert_out "the healthy run reports NON_VACUOUS" "NON_VACUOUS"

verdict_row "verdict.sh: a clean module is still OK rc 0" \
  0 \
  --config "harness/fixtures/verdict/Ok.cfg" "harness/fixtures/verdict/Ok.tla"

run_row "$SCREEN" "screen.sh: a working code search still reaches a verdict" \
  0 -- \
  env SCREEN_GH="harness/fixtures/screen/gh-stub" \
  SCREEN_STUB_COUNTS="harness/fixtures/screen/gh-stub-counts.txt" \
  SCREEN_README="harness/fixtures/screen/examples-README.md" \
  SCREEN_CACHE_DIR="$(mktemp -d)" \
  SCREEN_SLEEP=0 \
  bash "$SCREEN" --name SkiPassBlackout "ski pass validation with blackout dates"
assert_out "the clean screen run reports CLEAR" "CLEAR"

run_row "$CGATE" "comment-gate.sh: the real stripper still PASSes a commented spec" \
  0 -- \
  bash "$CGATE" \
  harness/fixtures/comment-gate/pluscal/frozen/lightswitch.tla \
  harness/fixtures/comment-gate/pluscal/commented-ok/lightswitch.tla

# ===========================================================================
echo
echo "== part 6: the registry is driven, and its skip paths were reached =="
# ===========================================================================
#
# The loophole part 2 would otherwise leave: an instrument can satisfy the
# census by being registered with rows that never reach a skip at all. So
# every registered instrument needs at least one row that did NOT return
# success. This does not prove the row reached THE skip -- that is judgment,
# row by row, and hole A in the header says so -- but it does close
# "registered and never exercised".

for i in "${!REGISTERED[@]}"; do
  inst=$(basename "${REGISTERED[$i]}")
  if [ "${ROWS_RUN[$i]}" -eq 0 ]; then
    nope "$inst is registered and no row drives it"
  elif [ "${ROWS_NONPASS[$i]}" -eq 0 ]; then
    nope "$inst is registered but every one of its ${ROWS_RUN[$i]} row(s) returned 0 — no skip path was reached"
  else
    ok "$inst: ${ROWS_RUN[$i]} row(s), ${ROWS_NONPASS[$i]} of them non-pass"
  fi
done

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
