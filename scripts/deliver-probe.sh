#!/usr/bin/env bash
# deliver-probe.sh: deliver the transfer-probe items into a practice tree.
#
# Bead tla-9bnj. The probe is two items graded on refinement, sitting outside
# the drill distribution on purpose, and probe 1 runs at drill item 10 because
# a pre-practice baseline is the one reading that cannot be recovered later.
#
# Usage:  scripts/deliver-probe.sh [--check | --verify] [--refresh-briefs] [dest-root]
#
#   dest-root        where the probe tree lands (default: $HOME/tla-practice/probe)
#   --check          print what a delivery would do and write nothing
#   --verify         compare what is there against the source and write nothing
#   --refresh-briefs replace a brief the repo has moved on from
#
# Exit: 0 in sync or delivered, 1 on an error, 3 when a delivery is owed.
#
# ---------------------------------------------------------------------------
# WHAT GOES AND WHAT STAYS
#
#   probe.sh              -> <dest>/probe, executable
#   README.md             -> <dest>/README.md
#   scripts/fetch-oracles.sh -> <dest>/scripts/fetch-oracles.sh, executable
#   <item>/BRIEF.md       -> <dest>/<item>/BRIEF.md
#   <item>/GRADE.conf     -> <dest>/<item>/GRADE.conf
#   <item>/constants.cfg  -> <dest>/<item>/constants.cfg
#
# WITHHELD, the same way a drill item withholds its own:
#
#   <item>/META.md        the decision the item forces, and the right reading
#   <item>/verify/        the reference solution and the wrong ones
#
# NOT DELIVERED BY THIS SCRIPT AT ALL:
#
#   <item>/<oracle>.tla   the requirement module. It is fetched rather than
#                         committed (bead tla-16je), so there is nothing here
#                         to copy. The delivered fetch script puts it in place
#                         and this script's --verify calls it.
#   <dest>/RECORD.tsv     the learner's record. Never written, never read,
#                         never compared. There is no delete path in here.
#
# ---------------------------------------------------------------------------
# TWO FILE CLASSES, AND WHY THE SECOND ONE NEEDS A RECORDED DIGEST
#
# The runner, the readme, the fetch script and each item's two config files are
# the repo's. A delivery overwrites them, and any difference is DRIFT.
#
# A brief is a page Frank reads and may annotate, so a plain run never
# overwrites one. That is the ruling he made on 2026-10-18 for drill prompts
# and it applies here for the same reason. But "never overwrite" on its own
# turns a brief the repo has corrected into a silent gap, which is the failure
# the delivery check exists to catch. So each delivered brief gets its digest
# recorded under <dest>/.delivered, and a difference splits two ways:
#
#   STALE     differs from the source AND matches the recorded digest. He has
#             not touched it, the repo moved, and --refresh-briefs lands it.
#   CONFLICT  differs from both. That is his own work. It is counted, reported,
#             and left alone, and it never fails the run.
#
# A CONFLICT IS NOT A FAILURE. Wiring a gate to an exit code that merged the
# two put a permanent red on 10 of 12 exercise chapters on 2026-10-18, every
# one of them red because Frank had done the exercises.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# Honors DELIVER_PROBE_SRC_ROOT so a test can point the derivation at a
# fixture tree, the same knob shape scripts/deliver-exercises.sh uses.
SRC_ROOT="${DELIVER_PROBE_SRC_ROOT:-$REPO_ROOT/probe}"

MODE="deliver"
REFRESH=0
DEST_ROOT=""

usage() {
  sed -n '/^# Usage:/,/^# Exit:/p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check)          MODE="check"; shift ;;
    --verify)         MODE="verify"; shift ;;
    --refresh-briefs) REFRESH=1; shift ;;
    -h|--help)        usage; exit 0 ;;
    -*) echo "$0: unknown option: $1" >&2; usage >&2; exit 1 ;;
    *)  [ -z "$DEST_ROOT" ] || { echo "$0: one dest-root, not two" >&2; exit 1; }
        DEST_ROOT="$1"; shift ;;
  esac
done

[ -n "$DEST_ROOT" ] || DEST_ROOT="$HOME/tla-practice/probe"
DEST_ROOT="${DEST_ROOT%/}"

if [ "$REFRESH" -eq 1 ] && [ "$MODE" != "deliver" ]; then
  echo "$0: --refresh-briefs replaces a brief, and neither --check nor --verify writes one." >&2
  exit 1
fi

[ -d "$SRC_ROOT" ] || { echo "$0: no source tree at $SRC_ROOT" >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "$0: sha256sum is not on the path" >&2; exit 1; }

# AN ABSENT DESTINATION IS A SKIP UNDER --verify, which is the convention the
# other five channels follow and the first version of this script got wrong.
# A verify writes nothing, so an absent root means nothing is owed: no probe
# has been delivered here and no probe is in flight. Every box but Frank's is
# in that case, so reporting drift on it would be red where it does not apply,
# which is how a gate gets switched off.
#
# It is also what harness/test-deliver-verify.sh asserts, because that suite
# reads scripts/verify-delivery.sh's AGGREGATE exit code and any channel
# reporting a finding reddens every row in it. Three rows went red before this
# block existed.
if [ "$MODE" = "verify" ] && [ ! -d "$DEST_ROOT" ]; then
  echo "no delivered tree at $DEST_ROOT, so there is nothing to compare. Skipping."
  exit 0
fi

RECORD_DIR="$DEST_ROOT/.delivered"

mapfile -t ITEMS < <(
  for d in "$SRC_ROOT"/*/; do
    [ -f "$d/BRIEF.md" ] || continue
    d="${d%/}"
    printf '%s\n' "${d##*/}"
  done
)

if [ "${#ITEMS[@]}" -eq 0 ]; then
  echo "$0: no items under $SRC_ROOT. A glob that stopped matching looks exactly like this." >&2
  exit 1
fi

RC=0
CONFLICTS=0

owed() { [ "$RC" -lt 3 ] && RC=3; return 0; }
fail() { RC=1; return 0; }

digest_of() {   # digest_of <file>
  local out
  out=$(sha256sum "$1") || return 1
  printf '%s\n' "${out%% *}"
}

same() {   # same <a> <b>
  cmp -s "$1" "$2"
}

# ---------------------------------------------------------------------------
# The repo-owned class. Overwritten on a delivery, DRIFT on a difference.
# ---------------------------------------------------------------------------
place_owned() {   # place_owned <src> <dest> <exec?>
  local src="$1" dest="$2" wantexec="$3"
  if [ ! -f "$src" ]; then
    echo "ERROR: no source file at $src"
    fail
    return
  fi
  case "$MODE" in
    verify)
      if [ ! -e "$dest" ]; then
        echo "DRIFT, absent: $dest"
        owed
      elif ! same "$src" "$dest"; then
        echo "DRIFT, differs: $dest"
        owed
      elif [ "$wantexec" = "yes" ] && [ ! -x "$dest" ]; then
        echo "DRIFT, not executable: $dest"
        owed
      else
        echo "ok $dest"
      fi
      ;;
    check)
      if [ -e "$dest" ]; then
        echo "would deliver, OVERWRITING: $dest"
      else
        echo "would deliver: $dest"
      fi
      ;;
    deliver)
      mkdir -p "$(dirname "$dest")" || { fail; return; }
      cp "$src" "$dest" || { echo "ERROR: cannot write $dest"; fail; return; }
      [ "$wantexec" = "yes" ] && chmod +x "$dest"
      echo "delivered $dest"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# The learner's class. Never overwritten by a plain run.
# ---------------------------------------------------------------------------
place_page() {   # place_page <src> <dest> <record>
  local src="$1" dest="$2" record="$3" recorded=""
  [ -f "$record" ] && recorded=$(cat "$record")

  if [ ! -e "$dest" ]; then
    case "$MODE" in
      verify) echo "STALE, absent: $dest"; owed; return ;;
      check)  echo "would deliver: $dest"; return ;;
      deliver)
        mkdir -p "$(dirname "$dest")" "$(dirname "$record")" || { fail; return; }
        cp "$src" "$dest" || { echo "ERROR: cannot write $dest"; fail; return; }
        digest_of "$src" > "$record" || { fail; return; }
        echo "delivered $dest"
        return ;;
    esac
  fi

  if same "$src" "$dest"; then
    case "$MODE" in
      verify)
        echo "ok $dest"
        # A delivered copy that matches the source and carries no record is
        # from before the record existed. Writing it is a delivery, not a
        # verify, so this reports rather than repairs.
        [ -n "$recorded" ] || echo "   (no recorded digest beside it, so a later edit of it would read as a conflict)"
        ;;
      check)    echo "already current: $dest" ;;
      deliver)  digest_of "$src" > "$record" 2>/dev/null; echo "already current: $dest" ;;
    esac
    return
  fi

  local have
  have=$(digest_of "$dest") || { echo "ERROR: cannot read $dest"; fail; return; }

  if [ -n "$recorded" ] && [ "$have" = "$recorded" ]; then
    # He has not touched it and the repo has moved on.
    case "$MODE" in
      verify)  echo "STALE, the repo has moved on: $dest"; owed ;;
      check)   echo "would replace a STALE copy (needs --refresh-briefs): $dest" ;;
      deliver)
        if [ "$REFRESH" -eq 1 ]; then
          cp "$src" "$dest" || { echo "ERROR: cannot write $dest"; fail; return; }
          digest_of "$src" > "$record" || { fail; return; }
          echo "refreshed $dest"
        else
          echo "STALE, left alone. Pass --refresh-briefs to replace it: $dest"
          owed
        fi ;;
    esac
    return
  fi

  # Differs from the source and from whatever was delivered. His own work.
  CONFLICTS=$((CONFLICTS + 1))
  echo "CONFLICT, your own work, left alone: $dest"
}

# ---------------------------------------------------------------------------

echo "source      $SRC_ROOT"
echo "destination $DEST_ROOT"
echo "items       ${#ITEMS[@]}"
echo

place_owned "$SRC_ROOT/probe.sh" "$DEST_ROOT/probe" yes
place_owned "$SRC_ROOT/README.md" "$DEST_ROOT/README.md" no
place_owned "$SRC_ROOT/scripts/fetch-oracles.sh" "$DEST_ROOT/scripts/fetch-oracles.sh" yes

for item in "${ITEMS[@]}"; do
  echo
  echo "-- $item"
  place_owned "$SRC_ROOT/$item/GRADE.conf" "$DEST_ROOT/$item/GRADE.conf" no
  if [ -f "$SRC_ROOT/$item/constants.cfg" ]; then
    place_owned "$SRC_ROOT/$item/constants.cfg" "$DEST_ROOT/$item/constants.cfg" no
  fi
  place_page "$SRC_ROOT/$item/BRIEF.md" "$DEST_ROOT/$item/BRIEF.md" "$RECORD_DIR/$item/BRIEF.md.sha256"
done

# ---------------------------------------------------------------------------
# The requirement modules. Not this script's files, and still this channel's
# obligation, so the fetch script's own verify mode runs here rather than the
# gap being left for somebody to notice.
# ---------------------------------------------------------------------------

echo
echo "-- requirement modules"
FETCHER="$DEST_ROOT/scripts/fetch-oracles.sh"
if [ ! -x "$FETCHER" ]; then
  echo "NOT CHECKED: no fetch script at $FETCHER yet, so the requirement modules were not compared."
  [ "$MODE" = "verify" ] && owed
else
  out=$("$FETCHER" --verify "$DEST_ROOT" 2>&1); frc=$?
  printf '%s\n' "$out" | sed 's/^/   /'
  case "$frc" in
    0) ;;
    3) echo "   a fetch is owed. Run $FETCHER"
       owed ;;
    *) echo "   ERROR: the fetch script exited $frc"
       fail ;;
  esac
fi

# ---------------------------------------------------------------------------

echo
if [ "$CONFLICTS" -gt 0 ]; then
  echo "$CONFLICTS brief(s) are your own work and were left alone. That is not a failure."
fi
echo "NOT CHECKED: RECORD.tsv, which holds your predictions, decisions and verdicts."
echo "             Nothing in this script reads it, writes it or deletes it."

exit "$RC"
