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
    -h|--help) sed -n '2,52p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "refute.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$ITEM" ]; then
  echo "refute.sh: --item <family>/<slug> is required." >&2
  exit 2
fi

ITEM_DIR="${REPO_ROOT}/drill/${ITEM}"
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
# ---------------------------------------------------------------------------
declare -a MACHINES=()
declare -a SEEN=()

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
  # A MACHINE MUST DECLARE ITS OWN STATE. Several items ship a second module
  # per neighbor that walks the prompt's table instead of running the spec on
  # its own, and those declare no VARIABLES, reaching the state through a
  # module they extend. The probe shape here cannot bind that, so such a
  # module came back rc 150 on every obligation and the table showed a column
  # of 150s that read like eight measurements. It is one fact about this
  # method. Skipped and counted instead, so the count says what was left out.
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
  MACHINES+=("$nm")
done <<<"$rows"

if [ "${#MACHINES[@]}" -eq 0 ]; then
  echo "refute.sh: ${ITEM} lists no runnable machine in its ANSWER.md rc table." >&2
  echo "  Nothing was run. This is a fact about the item, not about the attempt." >&2
  exit 3
fi

if [ "$LIST_ONLY" = "1" ]; then
  echo "${ITEM}: ${#MACHINES[@]} runnable machine(s), ${SKIPPED} that declare no state of their own"
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

# Constant parameters both instances need, declared once in the probe.
const_names="$(grep -hE '^[[:space:]]*CONSTANTS?[[:space:]]' "$ATLA" "${VERIFY_DIR}"/*.tla 2>/dev/null \
  | sed -e 's/^[[:space:]]*CONSTANTS\?[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | tr ',' '\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -E '^[A-Za-z][A-Za-z0-9_]*$' | sort -u | paste -sd, -)"

WORK="$(mktemp -d)"
# Reached through the EXIT trap below, which shellcheck does not follow.
# shellcheck disable=SC2317
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

cp "$ATLA" "$WORK/" || exit 2

echo "item: ${ITEM}"
echo "attempt: ${ATTEMPT_MOD} from ${ATTEMPT}"
echo "machines run: ${#MACHINES[@]}  (${SKIPPED} declare no state of their own and this method cannot bind them)"
echo
printf '%-38s %-9s' "OBLIGATION" "KIND"
i=1
for _ in "${MACHINES[@]}"; do
  printf ' %6s' "m${i}"
  i=$((i + 1))
done
printf '\n'

reported=0
for idx in "${!OB_NAMES[@]}"; do
  ob="${OB_NAMES[$idx]}"
  kind="${OB_KINDS[$idx]}"
  printf '%-38s %-9s' "$ob" "$kind"

  mi=0
  for mach in "${MACHINES[@]}"; do
    mi=$((mi + 1))
    cp "${VERIFY_DIR}/${mach}.tla" "$WORK/" || true

    # NEVER PIPE INTO head HERE. Under pipefail an early-exiting consumer
    # SIGPIPEs the producer and the pipeline returns 141, so a present line
    # reports as absent and the probe silently loses the machine's own state
    # bound. Materialize first, then take the first line from a here-string.
    mcfg="$(strip_comments "${VERIFY_DIR}/${mach}.cfg")"
    vconstraint="$(grep -E '^[[:space:]]*CONSTRAINTS?[[:space:]]' <<<"$mcfg" || true)"
    vconstraint="${vconstraint%%$'\n'*}"
    vconstraint="${vconstraint##*[[:space:]]}"
    deadlock="$(grep -E '^[[:space:]]*CHECK_DEADLOCK[[:space:]]' <<<"$mcfg" || true)"
    deadlock="${deadlock%%$'\n'*}"

    {
      printf '%s\n' "---- MODULE Probe ----"
      printf '%s\n' "EXTENDS Naturals, Sequences, FiniteSets, TLC"
      [ -n "$const_names" ] && printf '%s\n' "CONSTANTS ${const_names}"
      printf '%s\n' "VARIABLES $(vars_of "$WORK/${mach}.tla" 2>/dev/null || true)"
      printf '%s\n' "V == INSTANCE ${mach}"
      printf '%s\n' "L == INSTANCE ${ATTEMPT_MOD}"
      printf '%s\n' "Spec == V!Spec"
      [ -n "$vconstraint" ] && printf '%s\n' "Bound == V!${vconstraint}"
      printf '%s\n' "Ob == L!${ob}"
      printf '%s\n' "===="
    } >"$WORK/Probe.tla"

    {
      printf '%s\n' "SPECIFICATION Spec"
      strip_comments "${VERIFY_DIR}/${mach}.cfg" | grep -E '^[[:space:]]*CONSTANTS?[[:space:]]' || true
      strip_comments "$ACFG" | grep -E '^[[:space:]]*CONSTANTS?[[:space:]]' || true
      printf '%s Ob\n' "$kind"
      [ -n "$vconstraint" ] && printf '%s\n' "CONSTRAINT Bound"
      [ -n "$deadlock" ] && printf '%s\n' "$deadlock"
    } >"$WORK/Probe.cfg"

    ( cd "$WORK" && tlc -config Probe.cfg Probe.tla >/dev/null 2>&1 )
    rc=$?
    rm -f "$WORK"/Probe_TTrace_*.tla "$WORK"/Probe_TTrace_*.bin
    rm -rf "$WORK"/states
    printf ' %6s' "$rc"
  done
  printf '\n'
  reported=$((reported + 1))
done

echo
echo "legend: 0 silent on that machine, 12 or 13 refutes it, 150 or 255 could not substitute"

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
