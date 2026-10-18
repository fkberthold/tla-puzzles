#!/usr/bin/env bash
# deliver-practice-root.sh: deliver the practice tree's ROOT-LEVEL files, the
# ones that tell a learner what the directory names mean.
#
# Usage:  scripts/deliver-practice-root.sh [--check | --verify | --adopt] [dest-root]
#
#   dest-root  where to deliver into (default: $HOME/tla-practice)
#
# Env:    DELIVER_PRACTICE_ROOT_SRC_ROOT   override the source root
#                                          (default: practice/ under the repo
#                                          this script lives in)
#
# Exit:   0 on success, and on a --verify that found nothing stale
#         1 on a usage error, an empty or missing source tree, or a failed copy
#         3 on a --verify that found a stale file
#
# ---------------------------------------------------------------------------
# WHY THIS CHANNEL DID NOT EXIST UNTIL NOW
#
# Five delivery scripts shipped before this one and every one of them delivers
# into a SUBDIRECTORY of the practice tree: drill, recall, exercises,
# completion, problems. Nothing delivered to the root, so the one file that
# sits there and explains the whole layout had no source in this repo at all.
# It was hand-maintained in a tree that is not under version control, no gate
# read it, and no diff could be taken of it.
#
# That is not a theory about what might go wrong. One read on 2026-10-18 found
# three stale claims in it at once: a two-level attempt path written as one
# level, a problems directory called empty while seven problems sat in it, and
# an em dash this project does not use in prose. All three were fixed by hand
# the same day and nothing stopped a fourth. Bead tla-xbbb, successor to
# tla-bxcd.
#
# Frank ruled on 2026-10-18: give it a source and deliver it like every other
# artifact. It then gets the spelling gate, a delivery verify and a diff
# anybody can read.
#
# ---------------------------------------------------------------------------
# WHY NEVER-OVERWRITE WITH A DIGEST RECORD, RATHER THAN ALWAYS-REFRESH
#
# The cost of giving this file a source is that a file Frank may want to
# annotate becomes one a delivery could overwrite. scripts/deliver-recall.sh
# can overwrite everything it delivers because no file in its manifest is one
# the learner writes into. This one is not in that class: it is his own tree's
# front door and he has edited it by hand for weeks.
#
# So this channel takes the three-state policy scripts/deliver-exercises.sh
# introduced and scripts/deliver-problems.sh refined, and the record is what
# makes the third state legible:
#
#   absent                   deliver
#   present, equals source   nothing to do
#   present, equals record   provably unedited since this script wrote it, so
#                            a moved source lands
#   present, differs from    his work. Never touched, whatever the source
#     record, or no record   says, and reported rather than failed on
#
# THE RECORD IS .delivered.sha256 AT THE DESTINATION ROOT, one
# "<digest>  <relative path>" line per file, read with tail -1 so a
# re-delivery appends rather than editing its own old line. ONLY A DELIVERY
# WRITES AN ENTRY. That clause is the whole safety argument: an entry means
# this script put those exact bytes there, so a file matching its entry is
# provably unedited. Infer an entry from anything else and the inference is
# what overwrites his work.
#
# --adopt is the bootstrap for the file that is already there. It records an
# entry for a delivered file that is byte-identical to its source, which is
# provably unedited, and records nothing for the rest.
#
# ---------------------------------------------------------------------------
# --check AND --verify ARE DIFFERENT QUESTIONS, AND THEY READ ALIKE
#
# --check reports what a delivery WOULD do. On a tree that is already
# byte-identical it still has something to say about every file, and it says
# nothing about staleness. --verify compares content against the source and
# the record, and reports only what drifted.
#
# This script uses the spelling four of the five siblings use: --check is the
# dry run, --verify is the drift report. scripts/deliver-exercises.sh is the
# odd one out, where --check IS the drift report because that is where the
# drift report was first written and it had no dry run to collide with. That
# collision is a trap for anybody writing a wrapper, which is why
# scripts/verify-delivery.sh exists and why a new channel should not add a
# sixth spelling.
#
# STALE EXITS 3 AND CONFLICTED DOES NOT. The two are not the same kind of
# finding. Stale means a delivery is owed and somebody can act on it tonight.
# Conflicted means the file differs from its record, so it is his own work,
# and the only correct action is to leave it alone forever. Failing on that
# would put a permanent red on the one file this channel exists to protect,
# and a gate that is red every night for a reason nobody can act on is worse
# than no gate.
#
# AN ABSENT DESTINATION ROOT IS A SKIP, NEVER A FAILURE. No box but Frank's
# has a delivered tree and a CI runner never will.
#
# ---------------------------------------------------------------------------
# NOTHING IS WITHHELD AND NOTHING IS REMOVED
#
# Every sibling holds something back, because every sibling delivers one half
# of a problem whose other half is the answer. There is no answer here. The
# whole of practice/ is reader-facing documentation, so the manifest is the
# whole of practice/ and a file added there tomorrow is delivered without
# anybody editing this script.
#
# This script has no delete path at all. ~/tla-practice is not a git repo and
# it holds the only copy of the work done in it.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE >&2
Usage: $0 [--check | --verify | --adopt] [dest-root]

  dest-root  where to deliver into (default: \$HOME/tla-practice)

  --check    resolve everything and print what a delivery would do. Writes
             nothing and always exits 0. --dry-run is an accepted alias.
  --verify   compare the delivered copy against the source and the delivery
             record, name every path that is stale or conflicted, and exit 3
             if any is stale. Conflicts are your work: they are reported and
             never failed on. An absent destination root is a skip.
  --adopt    record a digest for every delivered file that is byte-identical
             to its source, so a later repair can reach a file delivered
             before this script kept records. Copies nothing.

Env:
  DELIVER_PRACTICE_ROOT_SRC_ROOT   override the source root
                                   (default: $REPO_ROOT/practice)
USAGE
}

SRC_ROOT="${DELIVER_PRACTICE_ROOT_SRC_ROOT:-$REPO_ROOT/practice}"

CHECK_ONLY=0
VERIFY_ONLY=0
ADOPT_ONLY=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --check|--dry-run) CHECK_ONLY=1; shift ;;
    --verify) VERIFY_ONLY=1; shift ;;
    --adopt) ADOPT_ONLY=1; shift ;;
    --) shift; break ;;
    -*) echo "$0: unknown option: $1" >&2; usage; exit 1 ;;
    *) break ;;
  esac
done

if [ $((CHECK_ONLY + VERIFY_ONLY + ADOPT_ONLY)) -gt 1 ]; then
  echo "$0: --check, --verify and --adopt answer different questions, so pick one." >&2
  usage
  exit 1
fi

if [ "$#" -gt 1 ]; then
  echo "$0: too many arguments, this channel takes one destination root." >&2
  usage
  exit 1
fi

DEST_ROOT="${1:-$HOME/tla-practice}"
RECORD_NAME=".delivered.sha256"
RECORD="$DEST_ROOT/$RECORD_NAME"

if [ ! -d "$SRC_ROOT" ]; then
  echo "$0: source root not found: $SRC_ROOT" >&2
  exit 1
fi

# The manifest is the whole source tree, walked rather than listed. A list
# would be a second place to remember, and a guessed manifest is what took 39
# delivered files with it in the 2026-10-02 problems incident.
MANIFEST=()
while IFS= read -r -d '' src_file; do
  MANIFEST+=("${src_file#"$SRC_ROOT/"}")
done < <(find "$SRC_ROOT" -type f -print0 | LC_ALL=C sort -z)

# A delivery script that delivers nothing reports success and does nothing,
# which is the shape a gate gets switched off by. Fail loudly instead.
if [ "${#MANIFEST[@]}" -eq 0 ]; then
  echo "$0: source root holds no files, so there is nothing to deliver: $SRC_ROOT" >&2
  exit 1
fi

digest_of() {
  [ -f "$1" ] || return 1
  sha256sum -- "$1" | cut -d' ' -f1
}

# recorded_digest <relative path>
#
# Keyed on the path relative to the destination root, so a record stays valid
# if the whole tree moves. Prints nothing and returns 1 when there is no
# entry, which is the ambiguous state and the one that must never be guessed
# at. tail -1 because record_digest appends and a later entry wins.
recorded_digest() {
  local rel="$1" line
  [ -f "$RECORD" ] || return 1
  line=$(grep -F -- "  $rel" "$RECORD" 2>/dev/null | tail -1)
  [ -n "$line" ] || return 1
  printf '%s' "${line%%  *}"
}

record_digest() {
  local rel="$1" digest="$2"
  mkdir -p -- "$DEST_ROOT" || return 1
  printf '%s  %s\n' "$digest" "$rel" >>"$RECORD"
}

# classify <relative path>
#
# Sets CLASS and CLASS_SRC_D. Equal content is decided BEFORE the record is
# consulted: a file already carrying the source's bytes needs no decision
# about who wrote it, and reporting it would be noise on every run.
CLASS=""
CLASS_SRC_D=""
classify() {
  local rel="$1" src="$SRC_ROOT/$1" dest="$DEST_ROOT/$1" dest_d rec_d
  CLASS_SRC_D=$(digest_of "$src") || CLASS_SRC_D=""
  if [ ! -e "$dest" ]; then
    CLASS="absent"
    return
  fi
  dest_d=$(digest_of "$dest") || dest_d=""
  if [ -n "$CLASS_SRC_D" ] && [ "$CLASS_SRC_D" = "$dest_d" ]; then
    CLASS="insync"
    return
  fi
  rec_d=$(recorded_digest "$rel") || rec_d=""
  if [ -n "$rec_d" ] && [ "$rec_d" = "$dest_d" ]; then
    CLASS="stale"
    return
  fi
  if [ -n "$rec_d" ]; then
    CLASS="conflict_recorded"
  else
    CLASS="conflict_unrecorded"
  fi
}

# ---------------------------------------------------------------------------
# --verify
# ---------------------------------------------------------------------------
if [ "$VERIFY_ONLY" -eq 1 ]; then
  if [ ! -d "$DEST_ROOT" ]; then
    echo "no delivered tree at $DEST_ROOT, so there is nothing to compare. Skipping."
    exit 0
  fi

  v_sync=0
  v_stale=0
  v_conflict=0
  for rel in "${MANIFEST[@]}"; do
    classify "$rel"
    case "$CLASS" in
      insync) v_sync=$((v_sync + 1)) ;;
      absent)
        # A whole tree that is absent is a skip, handled above. A file missing
        # from a tree that IS there means a delivery is owed, and the wrapper
        # reads the STALE prefix, so it carries it.
        v_stale=$((v_stale + 1))
        echo "STALE, never delivered, so a delivery is owed: $DEST_ROOT/$rel"
        ;;
      stale)
        v_stale=$((v_stale + 1))
        echo "STALE, you have not edited it so a delivery would update it: $DEST_ROOT/$rel"
        ;;
      conflict_recorded)
        v_conflict=$((v_conflict + 1))
        echo "CONFLICT, your edit and a moved source: $DEST_ROOT/$rel"
        ;;
      *)
        v_conflict=$((v_conflict + 1))
        echo "CONFLICT, differs from source and has no record, so it may be your work: $DEST_ROOT/$rel"
        ;;
    esac
  done

  echo "$v_sync in sync, $v_stale stale, $v_conflict conflicted"
  if [ "$v_stale" -gt 0 ]; then
    echo "run $0 to bring the delivered tree up to the repo." >&2
    exit 3
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# --adopt
# ---------------------------------------------------------------------------
if [ "$ADOPT_ONLY" -eq 1 ]; then
  adopted=0
  unrecorded=0
  for rel in "${MANIFEST[@]}"; do
    dest="$DEST_ROOT/$rel"
    if [ ! -e "$dest" ]; then
      echo "not delivered, so nothing to adopt: $dest"
      continue
    fi
    if recorded_digest "$rel" >/dev/null; then
      echo "already recorded: $dest"
      continue
    fi
    src_d=$(digest_of "$SRC_ROOT/$rel") || src_d=""
    dest_d=$(digest_of "$dest") || dest_d=""
    if [ -n "$src_d" ] && [ "$src_d" = "$dest_d" ]; then
      record_digest "$rel" "$dest_d" || exit 1
      adopted=$((adopted + 1))
      echo "adopted, byte-identical to its source: $dest"
    else
      # Counted, not just skipped. A bootstrap that reports it recorded
      # everything, when the files it passed over are exactly the learner's
      # own work, is the one number somebody would act on.
      unrecorded=$((unrecorded + 1))
      echo "not adopted, it differs from its source so it may be your work: $dest"
    fi
  done
  echo "$adopted file(s) adopted, $unrecorded left unrecorded"
  exit 0
fi

# ---------------------------------------------------------------------------
# --check, and the delivery itself. One loop, because a dry run that walked a
# different path from the delivery would be answering about a delivery nobody
# is going to run.
# ---------------------------------------------------------------------------
to_land=0
current=0
to_update=0
left_alone=0
rc=0

for rel in "${MANIFEST[@]}"; do
  src="$SRC_ROOT/$rel"
  dest="$DEST_ROOT/$rel"
  classify "$rel"
  case "$CLASS" in
    absent)
      to_land=$((to_land + 1))
      if [ "$CHECK_ONLY" -eq 1 ]; then
        echo "would deliver: $dest"
        continue
      fi
      mkdir -p -- "$(dirname -- "$dest")" || { rc=1; continue; }
      cp -- "$src" "$dest" || { rc=1; continue; }
      record_digest "$rel" "$CLASS_SRC_D" || rc=1
      echo "delivered: $dest"
      ;;
    insync)
      current=$((current + 1))
      if [ "$CHECK_ONLY" -eq 1 ]; then
        echo "already current, a delivery would leave it: $dest"
        continue
      fi
      echo "already current: $dest"
      ;;
    stale)
      to_update=$((to_update + 1))
      if [ "$CHECK_ONLY" -eq 1 ]; then
        echo "would update, you have not edited it: $dest"
        continue
      fi
      cp -- "$src" "$dest" || { rc=1; continue; }
      record_digest "$rel" "$CLASS_SRC_D" || rc=1
      echo "updated, you had not edited it: $dest"
      ;;
    *)
      left_alone=$((left_alone + 1))
      if [ "$CHECK_ONLY" -eq 1 ]; then
        if [ "$CLASS" = "conflict_recorded" ]; then
          echo "would leave alone, your edit and a moved source: $dest"
        else
          echo "would leave alone, it differs from source with no record so it may be your work: $dest"
        fi
        continue
      fi
      echo "left alone, it may be your work: $dest"
      if [ "$CLASS" = "conflict_recorded" ]; then
        echo "  and the source has moved since you edited it, so merge $src by hand" >&2
      else
        echo "  and it differs from $src with no record of delivery, so merge by hand if it is not yours" >&2
      fi
      ;;
  esac
done

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo "$to_land to land, $current already current, $to_update to update, $left_alone left alone"
  exit 0
fi

echo "$to_land landed, $current already current, $to_update updated, $left_alone left alone"
exit "$rc"
