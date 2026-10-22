#!/usr/bin/env bash
# harness/refute.sh — run a learner's obligations against the wrong machines
# the drill item already ships, and print one exit code per pair.
#
# WHY THIS EXISTS. Frank worked sequences/01-triage-board over a full day on
# an item budgeted at ten minutes, and nine ./drill --check runs produced nine
# prose findings. One of them was repeated three times and was false: it said
# his GreatestSeverityAlwaysPicked "would never catch a doctor who broke the
# rule". Measured here, that obligation refutes the wrong doctor the item
# ships at rc 13. So does BoardEitherGrowsOrShrinksByOne, which no check run
# mentioned at all.
#
# The defect is not that the reading was careless. A prose reading has no
# fixed point: the instrument generates text, so there is always another
# sentence available, and nine runs produce nine findings whether or not
# anything is wrong. An exit code terminates. Each machine the item ships is
# either refuted by one of his obligations or it is not, and that is a fact
# about a TLC run rather than a reading.
#
# WHAT IT DOES NOT DO, and this is the whole leak argument. It never prints a
# module name, a config name, or any of ANSWER.md's prose about what a variant
# is wrong about. A name like TriageFifo states the item's trap outright. The
# machines are numbered in the order the item lists them and nothing else
# about them is said, so the output carries the rc signal and no part of the
# answer. drill/study/CLAUDE.md calls the withholding in deliver-drill.sh "a
# delivery boundary rather than an access boundary", and that boundary is
# about what the coaching MODEL may read. A script that runs the variants and
# prints exit codes keeps the model further from them than a reading does.
#
# HOW IT SUBSTITUTES. It generates a probe module that instantiates the
# learner's module and the variant's module side by side:
#
#   V == INSTANCE <variant>
#   L == INSTANCE <attempt>
#   Spec == V!Spec
#   Ob   == L!<obligation>
#
# A bare INSTANCE matches parameters by name, so this works exactly when the
# learner's variable names match the variant's, and fails loudly at rc 150
# when they do not. That failure mode is the point: a name mismatch must never
# come back as a silent rc 0, because a 0 that means "could not substitute"
# is the same class of lie as a gate that reports green having read no files.
#
# WHERE THE MACHINES COME FROM, AND ONE FAMILY ANSWERS DIFFERENTLY. For most
# items a machine is a module-and-config pair named in ANSWER.md's rc table.
# The 8 temporal items ship verify/MATRIX and verify/MODULE instead: a
# tab-separated manifest naming the base module and the SPECIFICATION each run
# uses, which drill/temporal/gen-cfgs.sh writes the per-run wrappers from.
# There a machine is a named SPECIFICATION inside one module rather than a
# module of its own, so the machines are the distinct module, SPECIFICATION and
# Rows triples the manifest lists. The probe shape above does not change.
#
# A row's own PROPERTY or INVARIANT is not read, and neither is its
# CHECK_DEADLOCK. Those belong to the run the manifest describes rather than to
# the machine underneath it, and the obligation under test here is the
# learner's. Deadlock checking goes off for the same reason: a terminal state
# is a fact about the machine, and an rc 11 would mask the whole column.
#
# AND ON THAT FAMILY AN rc 0 IS NOT EVIDENCE UNTIL VACUITY IS RULED OUT.
# 7 of the 8 base modules carry a fairness conjunct, and
# .claude/rules/tla-practice.md records, measured on this TLC build, that a
# fairness conjunct over an action [][Next]_vars forbids leaves no behavior at
# all. TLC then exits 0 on every temporal property, including one no behavior
# can satisfy. A column of zeros would read exactly like a correct obligation
# set, which is the false reassurance this whole instrument exists to remove,
# reappearing one level down.
#
# So every machine composed from a manifest is paired with harness/vacuity.sh,
# whose VECTOR 4 reads the same two codes, and a cell whose code is 0 reports
# which of three things that 0 is:
#
#   0     silent on that machine, and that machine admits behaviors
#   vac   that machine's Spec admits no behavior, so the 0 says nothing
#   vac?  the vacuity probe delivered no verdict, so neither state is claimed
#
# vac is never folded into 0 and 0 is never folded into vac. vac? is the third
# thing rather than a lean towards either, because a probe that did not run is
# not a finding about the machine.
#
# The pairing is on the manifest path only. There this script CHOOSES the
# SPECIFICATION, so the composition is its own work and the risk is its own to
# close. On the ANSWER.md path the machine is a pair the item already ran and
# recorded an rc for, so there is independent evidence about it either way.
#
# A CELL HAS FOUR STATES AND ONLY TWO OF THEM ARE FINDINGS. It refutes the
# machine, it is silent on it, it is vacuous, or the run did not get off the
# ground and nothing was established at all. The fourth is the one a reader
# guesses wrong, and it is the same failure as the vacuous 0 seen from the
# other end: there a code of 0 is not evidence, here a code that is not 0 is
# not evidence either.
#
# rc 75 is the case that found this. An obligation indexing outside a
# function's domain exits 75 and TLC prints "unable to fingerprint", so nothing
# about the obligation was established -- and 75 is non-zero, so beside a 0 and
# a 13 it reads as a refutation. A learner's obligation that indexed a sequence
# the wrong way would be credited with catching that machine. Measured on this
# build twice on 2026-10-22: by central on
# core-language-docs/snippets/functions-records/Outside.tla, which that
# family's CASES pins at 75, and here through this script's own probe path.
#
# So the legend names the codes it interprets and then buckets EVERYTHING
# ELSE, rather than enumerating some and leaving the rest bare. An open list
# with a closed bucket cannot be made incomplete by a code nobody has met yet.
# drill/study/.claude/commands/check.md:77 already reads that way on the
# coaching side, with "anything else, the run did not get off the ground, so
# nothing was measured", so this makes the script agree with the sheet.
#
# Usage:
#   harness/refute.sh --attempt <dir> --item <family>/<slug> [--module <name>]
#   harness/refute.sh --list-machines --item <family>/<slug>
#
# Exit codes:
#   0  the table printed
#   2  bad usage, or an input that does not exist
#   3  the item ships no runnable machine, so there was nothing to run
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

# The drill tree to read, overridable for the gate alone. No machine in the
# shipped corpus has a Spec that admits no behavior, so the vacuity pairing
# cannot be exercised against it, and a check nobody has watched fail is not
# evidence that it works. harness/test-refute.sh points this at a two-machine
# fixture it builds, one satisfiable and one not. Nothing else sets it, and the
# default is the only tree this instrument is about.
DRILL_ROOT="${REFUTE_DRILL_ROOT:-${REPO_ROOT}/drill}"

strip_comments() { sed -e 's/\\\*.*$//' "$1"; }

# The probe declares the MACHINE's variables and not the union with the
# attempt's. An attempt carrying a variable the machine does not have then
# fails at rc 150 naming it, which is the right answer: an obligation over a
# variable the machine never has cannot be evaluated against that machine. A
# union would instead leave that variable unconstrained and TLC would fail for
# a reason that reads like a bug in this script.
vars_of() {
  strip_comments "$1" \
    | grep -E '^[[:space:]]*VARIABLES?[[:space:]]' \
    | sed -e 's/^[[:space:]]*VARIABLES\?[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | paste -sd, -
}

# A MACHINE'S STATE MAY BE DECLARED ONE MODULE DOWN, and a scan of one file
# cannot see it. drill/temporal/07-pipeline-halt/verify/PipelineRefused.tla is
# two lines that EXTEND Pipeline, and Pipeline.tla:7 is where
# "VARIABLES stage, artifact, retries" lives. Walk the chain inside verify/
# instead, so the question asked is whether the machine's state is declared
# anywhere rather than whether it is declared in that one file.
#
# TWO CHAINS, AND THEY ARE NOT THE SAME CHAIN. EXTENDS is the relation that
# hands a module's VARIABLES, CONSTANTS and definitions up to the module above
# it, so that is the one the state question and the definition question follow.
# A module reached through INSTANCE hands nothing up, since its state is
# substituted inside the instance, but TLC still has to find the file, so the
# copy that goes beside the probe follows both.
#
# 04-revision-freeze is why that distinction is written down rather than
# assumed. Steps.tla:12 reads "D == INSTANCE Document" and declares all four
# variables itself, so the probe's VARIABLES line was right either way, and all
# 9 of its machines still came back rc 150 because Document.tla was never
# copied next to the probe. An EXTENDS-only copy is a column of 150s on an item
# whose state question it answered correctly.
#
# Only modules with a file in verify/ are followed. Naturals and Sequences have
# none, so they fall out without a special case.
#
# The mode is a branch rather than the name of a reader to call, because an
# indirectly invoked function reads as dead code to shellcheck and buys four
# suppressions over one if.
walk_modules() {
  local mode="$1" todo="$2" walked="" name f more
  while :; do
    name="${todo%% *}"
    [ -n "$name" ] || break
    if [ "$name" = "$todo" ]; then todo=""; else todo="${todo#* }"; fi
    case " ${walked} " in *" ${name} "*) continue ;; esac
    walked="${walked} ${name}"
    f="${VERIFY_DIR}/${name}.tla"
    [ -f "$f" ] || continue
    printf '%s\n' "$f"
    if [ "$mode" = "deps" ]; then
      more="$(refs_in "$f")"
    else
      more="$(extends_in "$f")"
    fi
    [ -n "$more" ] && todo="${todo:+${todo} }${more}"
  done
}

trim_words() {
  local out
  out="$(tr ',\n' '  ' <<<"$1" | tr -s ' ')"
  out="${out# }"
  printf '%s' "${out% }"
}

extends_in() {
  trim_words "$(strip_comments "$1" | grep -E '^[[:space:]]*EXTENDS[[:space:]]' \
    | sed -e 's/^[[:space:]]*EXTENDS[[:space:]]*//' || true)"
}

# The module name after INSTANCE, whether the line is a bare INSTANCE, a named
# one, or one carrying a WITH clause. A false positive costs a copy of a file
# that is not there, which the walk drops.
instances_in() {
  trim_words "$(strip_comments "$1" | grep -E 'INSTANCE[[:space:]]' \
    | sed -e 's/^.*INSTANCE[[:space:]][[:space:]]*//' -e 's/[^A-Za-z0-9_].*$//' || true)"
}

refs_in() {
  trim_words "$(printf '%s %s' "$(extends_in "$1")" "$(instances_in "$1")")"
}

closure_of() { walk_modules extends "$1"; }
deps_of()    { walk_modules deps "$1"; }

# The union over the chain, not the first file that answers. Two modules in one
# chain may each declare state, and a probe bound to half of it leaves the rest
# unconstrained, which TLC reports for a reason that reads like a bug here.
vars_in_closure() {
  local f v parts=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    v="$(vars_of "$f")"
    [ -n "$v" ] && parts="${parts:+${parts},}${v}"
  done <<<"$(closure_of "$1")"
  printf '%s' "$parts"
}

# WHICH MODULE A MACHINE ACTUALLY IS. A manifest row names a module and a
# SPECIFICATION, and the module it names is the one the generated wrapper
# extends rather than the one that defines the spec. Resolve the spec to the
# module that defines it, and that module is the machine.
#
# This is not tidiness. 07-pipeline-halt's n3-buggy row names PipelineRefused,
# which is two lines extending Pipeline so that it can carry one neighbor the
# tools refuse outright: TLC reads "[] followed by action not of form [A]_v"
# and exits 150 before anything is checked. Instantiating it would have printed
# a column of three 150s beside two columns of real codes, which is the exact
# shape the ANSWER.md path already refuses to print. PipelineRefused!Spec IS
# Pipeline!Spec, so resolving the definition makes that row the machine it was
# always about and deduplication then removes it. Same for HeartbeatRefused and
# TurnstileRefused. No TLC run is spent deciding it.
#
# A spec no module in the chain defines is a machine that cannot be built, and
# that is counted rather than run, for the reason every other floor here is.
defining_module() {
  local spec="$1" f body
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    # NEVER PIPE INTO grep -q HERE. Under pipefail the early-exiting consumer
    # SIGPIPEs the producer and the pipeline returns 141, so inside an if it is
    # falsy and a definition that IS there reads as absent. The machine would
    # then be counted as unbindable, on a 75-line file, some of the time.
    body="$(strip_comments "$f")"
    if grep -qE "^[[:space:]]*${spec}[[:space:]]*==" <<<"$body"; then
      basename -- "$f" .tla
      return 0
    fi
  done <<<"$(closure_of "$2")"
  return 1
}

consts_of_files() {
  grep -hE '^[[:space:]]*CONSTANTS?[[:space:]]' "$@" 2>/dev/null \
    | sed -e 's/^[[:space:]]*CONSTANTS\?[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | tr ',' '\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | grep -E '^[A-Za-z][A-Za-z0-9_]*$' | sort -u | paste -sd, -
}

SKIPPED=0

ATTEMPT=""
ITEM=""
ATTEMPT_MOD=""
LIST_ONLY=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --attempt) ATTEMPT="${2:-}"; shift 2 ;;
    --item) ITEM="${2:-}"; shift 2 ;;
    --module) ATTEMPT_MOD="${2:-}"; shift 2 ;;
    --list-machines) LIST_ONLY=1; shift ;;
    -h|--help) sed -n '2,115p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "refute.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$ITEM" ]; then
  echo "refute.sh: --item <family>/<slug> is required." >&2
  exit 2
fi

ITEM_DIR="${DRILL_ROOT}/${ITEM}"
VERIFY_DIR="${ITEM_DIR}/verify"
ANSWER="${ITEM_DIR}/ANSWER.md"

if [ ! -d "$VERIFY_DIR" ]; then
  echo "refute.sh: no verify/ under ${ITEM_DIR}." >&2
  echo "  This instrument reads the repo. It cannot run from a delivered tree." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Enumerating the machines.
#
# THE rc TABLE IN ANSWER.md IS IN THREE DIALECTS and nothing has ever read it,
# which is why the drift was never caught. Measured over all 64 items on
# 2026-10-21:
#
#   | `BoxOffice` | reference | rc 0 | ...        core/01 and 32 others
#   | `G01Alone.tla` | rc 0 | 3 | ...             modules/01 and 23 others
#   | TwoStep.tla | TwoStep.cfg | rc 12 | 9 |     the control-state family
#
# So the matcher takes an optional backtick pair and an optional .tla suffix,
# and finds the rc anywhere in the row rather than at a fixed column, because
# the column order differs between dialects too.
#
# A module is a MACHINE here only when both it and a .cfg of the same name
# exist, since a module with no config cannot be run on its own.
#
# A MANIFEST ANSWERS THE SAME QUESTION WITHOUT THE DIALECTS. verify/MATRIX is
# tab-separated, one row per run, as `tag <TAB> rows <TAB> cfg-body`, and the
# body names the SPECIFICATION. A body line "\* MODULE: Name" overrides the
# base module in verify/MODULE, for an item that checks a lasso table and a
# system spec side by side. Both are honored, because both decide which
# machine the row is about.
#
# THE MACHINE IS THE TRIPLE, NOT THE ROW. Several rows name one SPECIFICATION
# with a different obligation each time, and the obligation is the row's
# business rather than the machine's. 07-pipeline-halt lists 11 rows over 2
# machines on that reading, and 05-flaky-link 25 rows over 10. Running a
# machine once per row would print the same column repeatedly and read like
# independent measurements, which is the failure the ANSWER.md path already
# guards against by deduplicating names.
#
# The parallel arrays carry the machine: its module, its SPECIFICATION, the
# Rows value a trace-table item binds to CONSTANT Rows, and the per-machine
# .cfg the ANSWER.md path reads a CONSTRAINT and a CHECK_DEADLOCK out of. A
# manifest machine has no such file, and MACH_CFG is empty for it.
# ---------------------------------------------------------------------------
declare -a MACH_MOD=()
declare -a MACH_SPEC=()
declare -a MACH_ROWS=()
declare -a MACH_CFG=()
declare -a SEEN=()
declare -a RAWSEEN=()

# Memo for the state scan, which gives the same answer for every row naming one
# module and costs a walk of that module's EXTENDS chain each time. Across
# 05-flaky-link's 25 rows there are two distinct modules to walk.
declare -A VARS_MEMO=()
MACHINE_VARS=""
set_machine_vars() {
  if [ -n "${VARS_MEMO[$1]+set}" ]; then
    MACHINE_VARS="${VARS_MEMO[$1]}"
    return 0
  fi
  MACHINE_VARS="$(vars_in_closure "$1")"
  VARS_MEMO[$1]="$MACHINE_VARS"
}

MATRIX_FILE="${VERIFY_DIR}/MATRIX"
MODULE_FILE="${VERIFY_DIR}/MODULE"
MANIFEST=0
if [ -f "$MATRIX_FILE" ] && [ -f "$MODULE_FILE" ]; then
  MANIFEST=1
fi

if [ "$MANIFEST" = "1" ]; then

base_default="$(tr -d '[:space:]' <"$MODULE_FILE")"

while IFS=$'\t' read -r tag rows body; do
  case "$tag" in ''|'#'*) continue ;; esac
  mod="$base_default"
  case "$body" in
    *'\* MODULE: '*)
      mod="${body#*\\* MODULE: }"
      mod="${mod%%;*}"
      ;;
  esac
  spec="Spec"
  case "$body" in
    *'SPECIFICATION '*)
      spec="${body#*SPECIFICATION }"
      spec="${spec%%;*}"
      ;;
  esac
  mod="${mod#"${mod%%[![:space:]]*}"}"; mod="${mod%"${mod##*[![:space:]]}"}"
  spec="${spec#"${spec%%[![:space:]]*}"}"; spec="${spec%"${spec##*[![:space:]]}"}"
  rows="${rows:--}"
  [ -n "$mod" ] || continue

  # DEDUPLICATE ON THE ROW'S OWN NAMES FIRST, before anything is read off disk.
  # The checks below walk a module's EXTENDS chain twice, and 15 of
  # 05-flaky-link's 25 rows repeat a triple the loop has already settled.
  raw="${mod}|${spec}|${rows}"
  dup=0
  for s in ${RAWSEEN[@]+"${RAWSEEN[@]}"}; do
    [ "$s" = "$raw" ] && dup=1
  done
  [ "$dup" -eq 1 ] && continue
  RAWSEEN+=("$raw")

  # Same floor as the ANSWER.md path and for the same reason: a row naming a
  # module that is not there, or a chain that declares no state anywhere, is
  # counted rather than run, so the count says what was left out.
  set_machine_vars "$mod"
  if [ ! -f "${VERIFY_DIR}/${mod}.tla" ] || [ -z "$MACHINE_VARS" ]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  owner="$(defining_module "$spec" "$mod" || true)"
  if [ -z "$owner" ]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  mod="$owner"
  # AND AGAIN ON THE RESOLVED NAMES. Two rows naming different modules can
  # resolve to one machine, which is how a module the tools refuse stops being
  # a column: PipelineRefused!Spec resolves to Pipeline!Spec.
  key="${mod}|${spec}|${rows}"
  dup=0
  for s in ${SEEN[@]+"${SEEN[@]}"}; do
    [ "$s" = "$key" ] && dup=1
  done
  [ "$dup" -eq 1 ] && continue
  SEEN+=("$key")
  MACH_MOD+=("$mod")
  MACH_SPEC+=("$spec")
  MACH_ROWS+=("$rows")
  MACH_CFG+=("")
done <"$MATRIX_FILE"

else

rows="$(grep -E '^\|[^|]*[A-Za-z][A-Za-z0-9_]*(\.tla)?[^|]*\|' "$ANSWER" 2>/dev/null \
        | grep -E 'rc[[:space:]]*=?[[:space:]]*[0-9]+' || true)"

while IFS= read -r row; do
  [ -n "$row" ] || continue
  cell="${row#|}"
  cell="${cell%%|*}"
  nm="$(sed -e 's/`//g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/\.tla$//' <<<"$cell")"
  [ -n "$nm" ] || continue
  [ -f "${VERIFY_DIR}/${nm}.tla" ] || continue
  [ -f "${VERIFY_DIR}/${nm}.cfg" ] || continue
  # A MACHINE MUST DECLARE ITS OWN STATE, ON THIS PATH. Several items ship a
  # second module per neighbor that walks the prompt's table instead of running
  # the spec on its own, and those declare no VARIABLES, reaching the state
  # through a module they extend. Such a module came back rc 150 on every
  # obligation and the table showed a column of 150s that read like eight
  # measurements. It is one fact about this method. Skipped and counted
  # instead, so the count says what was left out.
  #
  # THE MANIFEST PATH READS THE CHAIN AND THIS ONE DOES NOT, which is a scope
  # line rather than a finding about the two families. Measured 2026-10-22:
  # drill/modules/01-*/verify/G01Pair.tla is two lines that EXTEND TankPair,
  # exactly the shape vars_in_closure was written for, so widening this test
  # would move the reach again and move it over machines nobody has run. That
  # is its own measurement and its own bead.
  if [ -z "$(vars_of "${VERIFY_DIR}/${nm}.tla")" ]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  dup=0
  for s in ${SEEN[@]+"${SEEN[@]}"}; do
    [ "$s" = "$nm" ] && dup=1
  done
  [ "$dup" -eq 1 ] && continue
  SEEN+=("$nm")
  MACH_MOD+=("$nm")
  MACH_SPEC+=("Spec")
  MACH_ROWS+=("-")
  MACH_CFG+=("${VERIFY_DIR}/${nm}.cfg")
done <<<"$rows"

fi

if [ "$MANIFEST" = "1" ]; then
  LEFT_OUT="that this method cannot bind"
  NOTHING_SRC="verify/MATRIX"
else
  LEFT_OUT="that declare no state of their own"
  NOTHING_SRC="ANSWER.md rc table"
fi

if [ "${#MACH_MOD[@]}" -eq 0 ]; then
  echo "refute.sh: ${ITEM} lists no runnable machine in its ${NOTHING_SRC}." >&2
  echo "  Nothing was run. This is a fact about the item, not about the attempt." >&2
  exit 3
fi

if [ "$LIST_ONLY" = "1" ]; then
  echo "${ITEM}: ${#MACH_MOD[@]} runnable machine(s), ${SKIPPED} ${LEFT_OUT}"
  exit 0
fi

# ---------------------------------------------------------------------------
# The attempt.
# ---------------------------------------------------------------------------
if [ -z "$ATTEMPT" ]; then
  echo "refute.sh: --attempt <dir> is required unless --list-machines is given." >&2
  exit 2
fi
if [ ! -d "$ATTEMPT" ]; then
  echo "refute.sh: no attempt directory at ${ATTEMPT}." >&2
  exit 2
fi

# Pick the attempt's module when the caller did not name one. A TTrace module
# is TLC's own trace artifact rather than the learner's work, so it is never
# a candidate.
if [ -z "$ATTEMPT_MOD" ]; then
  for f in "$ATTEMPT"/*.tla; do
    [ -e "$f" ] || continue
    b="$(basename "$f" .tla)"
    case "$b" in *_TTrace_*) continue ;; esac
    [ -f "${ATTEMPT}/${b}.cfg" ] || continue
    ATTEMPT_MOD="$b"
    break
  done
fi

if [ -z "$ATTEMPT_MOD" ]; then
  echo "refute.sh: found no module-and-config pair under ${ATTEMPT}." >&2
  exit 2
fi

ACFG="${ATTEMPT}/${ATTEMPT_MOD}.cfg"
ATLA="${ATTEMPT}/${ATTEMPT_MOD}.tla"
if [ ! -f "$ACFG" ] || [ ! -f "$ATLA" ]; then
  echo "refute.sh: ${ATTEMPT_MOD} needs both a .tla and a .cfg under ${ATTEMPT}." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# The obligations, and the count that keeps this honest.
#
# TRIM BOTH ENDS BEFORE READING THE NAME. Frank's own Triage.cfg carries a
# trailing space after BoardEitherGrowsOrShrinksByOne. Without the trim the
# name came back empty, the obligation was skipped, and the run printed seven
# rows for eight obligations with nothing said about the eighth. A dropped
# obligation reads as a clean run, which is the one output this instrument
# must never produce, so the count is asserted at the end as well.
# ---------------------------------------------------------------------------
declare -a OB_NAMES=()
declare -a OB_KINDS=()

while IFS= read -r line; do
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [ -n "$line" ] || continue
  case "$line" in
    INVARIANT[[:space:]]*|INVARIANTS[[:space:]]*) kind=INVARIANT ;;
    PROPERTY[[:space:]]*|PROPERTIES[[:space:]]*) kind=PROPERTY ;;
    *) continue ;;
  esac
  rest="${line#* }"
  for nm in $rest; do
    OB_NAMES+=("$nm")
    OB_KINDS+=("$kind")
  done
done <<<"$(strip_comments "$ACFG")"

declared=$(strip_comments "$ACFG" | grep -cE '^[[:space:]]*(INVARIANTS?|PROPERTY|PROPERTIES)[[:space:]]' || true)

if [ "${#OB_NAMES[@]}" -eq 0 ]; then
  echo "refute.sh: ${ATTEMPT_MOD}.cfg names no INVARIANT and no PROPERTY." >&2
  echo "  There is nothing to run against the item's machines." >&2
  exit 3
fi

# Constant parameters both instances need, declared once in the probe. On the
# ANSWER.md path this is the union over the attempt and every module in
# verify/, which is what the 40 items it reaches were measured against.
const_names="$(consts_of_files "$ATLA" "${VERIFY_DIR}"/*.tla)"

WORK="$(mktemp -d)"
# Reached through the EXIT trap below, which shellcheck does not follow.
# shellcheck disable=SC2317
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

cp "$ATLA" "$WORK/" || exit 2

# ---------------------------------------------------------------------------
# The vacuity pairing.
#
# A machine's Spec either admits a behavior or it does not. That is a fact
# about the machine and not about any obligation, so the verdict is taken once
# per machine and cached here. It is taken LAZILY, the first time a cell on
# that machine comes back 0, because a machine every obligation refutes never
# needed it and the probe costs three TLC runs.
#
# harness/vacuity.sh is the instrument and its VECTOR 4 is the finding, at a
# floor of ONE state. The shipped Gate!NonVacuous asks for four, and a lasso
# row is a two-state model, so the shipped floor would report a perfectly
# healthy single-row machine vacuous. --expect none and --no-dead-actions are
# this caller stating its own scope, which that script reads as a waiver rather
# than as a check that failed to run, so neither turns into a 99.
#
# VECTOR 1 AND VECTOR 4 ARE ONE ANSWER HERE. An empty state space and a Spec
# admitting no behavior are different faults needing different remedies, and
# this script needs neither remedy. Both say the same thing about the cell: the
# 0 is silence over nothing. Anything else vacuity.sh reports is a probe that
# did not deliver, and that is a third answer rather than a lean towards one of
# the first two.
# ---------------------------------------------------------------------------
declare -a VAC=()
for _ in ${MACH_MOD[@]+"${MACH_MOD[@]}"}; do VAC+=("unasked"); done

probe_vacuity() {
  local mod="$1" spec="$2" mrows="$3"
  local vd="$WORK/vac" f vrc
  rm -rf "$vd"
  mkdir -p "$vd" || { printf 'unknown'; return 0; }
  while IFS= read -r f; do
    [ -n "$f" ] && cp "$f" "$vd/"
  done <<<"$(deps_of "$mod")"
  {
    printf '%s\n' "---- MODULE RefuteMachine ----"
    printf '%s\n' "EXTENDS ${mod}"
    printf '%s\n' "===="
  } >"$vd/RefuteMachine.tla"
  # THE ATTEMPT'S CONSTANTS ARE DELIBERATELY NOT COPIED HERE, unlike on the
  # probe. This module is the machine alone, so a .cfg assigning a CONSTANT the
  # machine never declares is a config error and TLC reports it as one. Copying
  # the learner's whole CONSTANT block would turn every learner who declares a
  # constant of their own into a health probe that could not run, and that
  # whole column would read vac? for a reason that is nothing to do with the
  # machine. Every temporal base module in the corpus takes Rows and nothing
  # else, which the manifest supplies. A machine that ever needs a
  # learner-supplied constant reads vac? instead, which claims nothing rather
  # than claiming the wrong thing, and is the signal to revisit this.
  {
    printf 'SPECIFICATION %s\n' "$spec"
    [ "$mrows" != "-" ] && printf 'CONSTANT Rows = %s\n' "$mrows"
  } >"$vd/RefuteMachine.cfg"
  "${SCRIPT_DIR}/vacuity.sh" -q -n 1 --expect none --no-dead-actions \
    -c "$vd/RefuteMachine.cfg" "$vd/RefuteMachine.tla" >/dev/null 2>&1
  vrc=$?
  case "$vrc" in
    0)   printf 'live' ;;
    3|7) printf 'none' ;;
    *)   printf 'unknown' ;;
  esac
}

echo "item: ${ITEM}"
echo "attempt: ${ATTEMPT_MOD} from ${ATTEMPT}"
echo "machines run: ${#MACH_MOD[@]}  (${SKIPPED} ${LEFT_OUT})"
echo
printf '%-38s %-9s' "OBLIGATION" "KIND"
i=1
for _ in "${MACH_MOD[@]}"; do
  printf ' %6s' "m${i}"
  i=$((i + 1))
done
printf '\n'

reported=0
n_refuted=0
n_silent=0
n_vacuous=0
n_nothing=0
for idx in "${!OB_NAMES[@]}"; do
  ob="${OB_NAMES[$idx]}"
  kind="${OB_KINDS[$idx]}"
  printf '%-38s %-9s' "$ob" "$kind"

  for mi in "${!MACH_MOD[@]}"; do
    mach="${MACH_MOD[$mi]}"
    mspec="${MACH_SPEC[$mi]}"
    mrows="${MACH_ROWS[$mi]}"
    mcfgfile="${MACH_CFG[$mi]}"
    while IFS= read -r f; do
      [ -n "$f" ] && cp "$f" "$WORK/"
    done <<<"$(deps_of "$mach")"

    # NEVER PIPE INTO head HERE. Under pipefail an early-exiting consumer
    # SIGPIPEs the producer and the pipeline returns 141, so a present line
    # reports as absent and the probe silently loses the machine's own state
    # bound. Materialize first, then take the first line from a here-string.
    vconstraint=""
    deadlock=""
    if [ -n "$mcfgfile" ]; then
      mcfg="$(strip_comments "$mcfgfile")"
      vconstraint="$(grep -E '^[[:space:]]*CONSTRAINTS?[[:space:]]' <<<"$mcfg" || true)"
      vconstraint="${vconstraint%%$'\n'*}"
      vconstraint="${vconstraint##*[[:space:]]}"
      deadlock="$(grep -E '^[[:space:]]*CHECK_DEADLOCK[[:space:]]' <<<"$mcfg" || true)"
      deadlock="${deadlock%%$'\n'*}"
      pconsts="$const_names"
    else
      # A MANIFEST MACHINE DECLARES ONLY WHAT ITS OWN CHAIN NEEDS. The
      # ANSWER.md path's union over every module in verify/ would declare a
      # CONSTANT this machine's base module never has and no .cfg ever
      # assigns, and 05-flaky-link is that shape: LinkLassos takes Rows and
      # FlakyLink beside it does not.
      declare -a cfiles=("$ATLA")
      while IFS= read -r f; do
        [ -n "$f" ] && cfiles+=("$f")
      done <<<"$(closure_of "$mach")"
      pconsts="$(consts_of_files "${cfiles[@]}")"
      # Deadlock checking stays off. A terminal state is a fact about the
      # machine rather than about the obligation, and an rc 11 arriving first
      # would mask the whole column. 07-pipeline-halt puts that question in two
      # CHECK_DEADLOCK rows of its own manifest, which is where it belongs.
      deadlock="CHECK_DEADLOCK FALSE"
    fi

    {
      printf '%s\n' "---- MODULE Probe ----"
      printf '%s\n' "EXTENDS Naturals, Sequences, FiniteSets, TLC"
      [ -n "$pconsts" ] && printf '%s\n' "CONSTANTS ${pconsts}"
      printf '%s\n' "VARIABLES $(vars_in_closure "$mach" 2>/dev/null || true)"
      printf '%s\n' "V == INSTANCE ${mach}"
      printf '%s\n' "L == INSTANCE ${ATTEMPT_MOD}"
      printf '%s\n' "Spec == V!${mspec}"
      [ -n "$vconstraint" ] && printf '%s\n' "Bound == V!${vconstraint}"
      printf '%s\n' "Ob == L!${ob}"
      printf '%s\n' "===="
    } >"$WORK/Probe.tla"

    {
      printf '%s\n' "SPECIFICATION Spec"
      [ "$mrows" != "-" ] && printf 'CONSTANT Rows = %s\n' "$mrows"
      [ -n "$mcfgfile" ] && { strip_comments "$mcfgfile" | grep -E '^[[:space:]]*CONSTANTS?[[:space:]]' || true; }
      strip_comments "$ACFG" | grep -E '^[[:space:]]*CONSTANTS?[[:space:]]' || true
      printf '%s Ob\n' "$kind"
      [ -n "$vconstraint" ] && printf '%s\n' "CONSTRAINT Bound"
      [ -n "$deadlock" ] && printf '%s\n' "$deadlock"
    } >"$WORK/Probe.cfg"

    ( cd "$WORK" && tlc -config Probe.cfg Probe.tla >/dev/null 2>&1 )
    rc=$?
    rm -f "$WORK"/Probe_TTrace_*.tla "$WORK"/Probe_TTrace_*.bin
    rm -rf "$WORK"/states

    # THE FOUR STATES, COUNTED. A cell either refutes the machine, is silent on
    # it, is vacuous, or established nothing. The last bucket is open on the
    # code and closed on the meaning: 0, 12 and 13 are the codes this script
    # interprets and every other code is a run that did not get off the ground.
    cell="$rc"
    case "$rc" in
      12|13) n_refuted=$((n_refuted + 1)) ;;
      0)
        if [ "$MANIFEST" = "1" ]; then
          if [ "${VAC[$mi]}" = "unasked" ]; then
            VAC[mi]="$(probe_vacuity "$mach" "$mspec" "$mrows")"
          fi
        fi
        case "${VAC[$mi]:-live}" in
          none)    cell="vac";  n_vacuous=$((n_vacuous + 1)) ;;
          unknown) cell="vac?"; n_nothing=$((n_nothing + 1)) ;;
          *)       n_silent=$((n_silent + 1)) ;;
        esac
        ;;
      *) n_nothing=$((n_nothing + 1)) ;;
    esac
    printf ' %6s' "$cell"
  done
  printf '\n'
  reported=$((reported + 1))
done

echo
echo "legend: 12 or 13 refutes that machine. 0 is silent on it. ANY OTHER CODE"
echo "        means the run did not get off the ground, so nothing at all was"
echo "        established: 150 or 255 could not substitute, 75, 76 or 77 could"
echo "        not evaluate, 124 ran out of time. A code not named here falls in"
echo "        the same bucket rather than reading as a refutation."
if [ "$MANIFEST" = "1" ]; then
  echo "        vac that machine's Spec admits no behavior, so its 0 is not evidence."
  echo "        vac? the vacuity probe gave no verdict, so neither state is claimed."
fi
echo "cells: ${n_refuted} refute a machine, ${n_silent} are silent, ${n_vacuous} are vacuous, ${n_nothing} established nothing"
if [ "$MANIFEST" = "1" ]; then
  nvac=0; nunk=0; nlive=0; nunasked=0
  for v in ${VAC[@]+"${VAC[@]}"}; do
    case "$v" in
      none)    nvac=$((nvac + 1)) ;;
      unknown) nunk=$((nunk + 1)) ;;
      live)    nlive=$((nlive + 1)) ;;
      *)       nunasked=$((nunasked + 1)) ;;
    esac
  done
  echo "vacuity: ${nvac} machine(s) admit no behavior, ${nlive} do, ${nunk} could not be probed, ${nunasked} never came back 0 so were never asked"
fi

# THE FLOOR. One row per declared obligation, or the run says so rather than
# letting a dropped name read as a clean table.
if [ "$reported" -ne "${#OB_NAMES[@]}" ]; then
  echo "refute.sh: reported ${reported} of ${#OB_NAMES[@]} obligations." >&2
  exit 2
fi
if [ "$declared" -gt 0 ] && [ "${#OB_NAMES[@]}" -lt "$declared" ]; then
  echo "refute.sh: ${ACFG} has ${declared} obligation line(s) and only ${#OB_NAMES[@]} name(s) were read." >&2
  echo "  Refusing to report a table that is missing a row." >&2
  exit 2
fi
exit 0
