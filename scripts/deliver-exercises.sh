#!/usr/bin/env bash
# deliver-exercises.sh: deliver one chapter's exercise set into a practice
# tree, without ever handing over the answers.
#
# Usage:  scripts/deliver-exercises.sh <chapter> [dest-root]
#
#   chapter    integer 2-13, the chapter to deliver exercises for
#   dest-root  where to deliver into (default: $HOME/tla-practice/exercises)
#
# Env:    DELIVER_SRC_ROOT   override the source root (default: exercises/
#                             under the repo root)
#
# Exit:   0 on success (including a partial delivery that only skipped an
#           already-present file, or logged a missing earlier cheat sheet)
#         1 on a usage error or a broken source tree
#
# ---------------------------------------------------------------------------
# WHAT LANDS AND WHAT NEVER DOES
#
# For chapter N this delivers EXERCISES.md, starters/ (recursively), a
# LOG.md scaffold from the shared template, and cheatsheets/chMM.md for every
# chapter MM below N that has one. It never delivers chapter N's own cheat
# sheet, any cheat sheet at or above N, references/, reports/, or
# COVERAGE.md. Those are exactly the material that would hand over the
# answer to the chapter being practiced, or the graded history of a previous
# attempt.
#
# A cheat sheet missing for an earlier chapter is reported on stderr and
# skipped; it is not fatal, because a chapter can legitimately have nothing
# to condense yet. A missing source chapter, or a source chapter with no
# EXERCISES.md, is fatal: there is nothing to deliver.
#
# ---------------------------------------------------------------------------
# NEVER OVERWRITE
#
# The destination is where the work happens, so a second run over a
# half-solved set must not clobber it. Every file this script places is
# checked for existence first; an existing file is left untouched and
# reported on stdout as "skipped (exists): <path>", never touched again.
#
# ---------------------------------------------------------------------------
# AND THE THIRD STATE (bead tla-oa0m)
#
# Never-overwrite froze every delivered chapter at its delivery date. Frank's
# ch02 to ch11 landed on 2026-08-12 and every repair since has reached the
# repo and not him. tla-e8ps alone fixes wording in eight of those ten, and he
# was working two of them.
#
# The tension is real rather than a bug: protecting his half-solved set and
# propagating a fix want opposite things from the same file. A --force flag
# does not resolve it, because the file most worth fixing is the file most
# likely to hold his answers.
#
# So delivery records what it wrote. With that record there are three states
# instead of two, and only one of them is ambiguous:
#
#   absent                      deliver, as before
#   present, matches record     he has not edited it, so a moved source is
#                               safe to land and this script lands it
#   present, differs from       his work. Never touched, whatever the source
#     record                    says. A moved source is reported as a
#                               conflict for him to merge by hand
#   present, no record          provenance unknown. Treated as his work,
#                               which is the safe reading
#
# THE RECORD IS .delivered.sha256 IN THE CHAPTER DIRECTORY, one "<digest>
# <relative path>" line per file, and ONLY A DELIVERY WRITES AN ENTRY. That
# last clause is the whole safety argument: an entry means this script put
# those exact bytes there, so a file matching its entry is provably unedited.
# Infer an entry from anything else and the inference is what overwrites his
# work.
#
# WHAT THIS CANNOT DO RETROACTIVELY. Frank's existing chapters have no
# record, so they stay in the ambiguous state and nothing gets auto-updated.
# --adopt is the safe bootstrap: it records an entry for every delivered file
# that is BYTE-IDENTICAL to its source, which is provably unedited, and
# records nothing for the rest. Run it once per chapter and later repairs
# reach him.
#
# --check writes nothing and exits 3 if anything is stale, so the reporting
# half can be gated. The bead asks for that half on its own merits: right now
# nothing tells him a delivered chapter has gone stale, which is the same
# shape as a command reporting success without distinguishing "nothing to do"
# from "something to do that I cannot see".

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE >&2
Usage: $0 [--check | --adopt] <chapter> [dest-root]

  chapter    integer 2-13, the chapter to deliver exercises for
  dest-root  where to deliver into (default: \$HOME/tla-practice/exercises)

  --check    report what is absent, stale or conflicted and write nothing.
             Exits 3 if anything is stale, 0 otherwise.
  --adopt    record a digest for every delivered file that is byte-identical
             to its source, so later repairs can reach a chapter delivered
             before this script kept records. Copies nothing.

Env:
  DELIVER_SRC_ROOT   override the source root (default: $REPO_ROOT/exercises)
USAGE
}

SRC_ROOT="${DELIVER_SRC_ROOT:-$REPO_ROOT/exercises}"

CHECK_ONLY=0
ADOPT_ONLY=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check) CHECK_ONLY=1; shift ;;
    --adopt) ADOPT_ONLY=1; shift ;;
    --) shift; break ;;
    -*) echo "$0: unknown option: $1" >&2; usage; exit 1 ;;
    *) break ;;
  esac
done

if [ "$CHECK_ONLY" -eq 1 ] && [ "$ADOPT_ONLY" -eq 1 ]; then
  echo "$0: --check writes nothing and --adopt writes the record, so pick one." >&2
  usage
  exit 1
fi

CHAPTER="${1:-}"
if [ -z "$CHAPTER" ] || ! [[ "$CHAPTER" =~ ^[0-9]+$ ]]; then
  usage
  exit 1
fi

# Strip any leading zero with the explicit base-10 prefix, so "02" and "2"
# compare equal instead of one of them being read as an (invalid) octal
# literal.
CHAPTER_NUM=$((10#$CHAPTER))

if [ "$CHAPTER_NUM" -lt 2 ] || [ "$CHAPTER_NUM" -gt 13 ]; then
  usage
  exit 1
fi

DEST_ROOT="${2:-$HOME/tla-practice/exercises}"

CHAPTER_PADDED=$(printf 'ch%02d' "$CHAPTER_NUM")
SRC_CHAPTER_DIR="$SRC_ROOT/$CHAPTER_PADDED"
DEST_CHAPTER_DIR="$DEST_ROOT/$CHAPTER_PADDED"

if [ ! -d "$SRC_CHAPTER_DIR" ]; then
  echo "$0: source chapter directory not found: $SRC_CHAPTER_DIR" >&2
  exit 1
fi

if [ ! -f "$SRC_CHAPTER_DIR/EXERCISES.md" ]; then
  echo "$0: source chapter has no EXERCISES.md: $SRC_CHAPTER_DIR/EXERCISES.md" >&2
  exit 1
fi

if [ "$CHECK_ONLY" -eq 0 ]; then
  mkdir -p "$DEST_CHAPTER_DIR"
fi

RECORD="$DEST_CHAPTER_DIR/.delivered.sha256"

STALE_COUNT=0
CONFLICT_COUNT=0
ADOPTED_COUNT=0

digest_of() {
  [ -f "$1" ] || return 1
  sha256sum -- "$1" | cut -d' ' -f1
}

# recorded_digest <dest>
#
# Keyed on the path relative to the chapter directory, so a record stays valid
# if the whole tree moves. Prints nothing and returns 1 when there is no entry,
# which is the ambiguous state and the one that must never be guessed at.
recorded_digest() {
  local rel="${1#"$DEST_CHAPTER_DIR/"}"
  [ -f "$RECORD" ] || return 1
  local line
  line=$(grep -F -- "  $rel" "$RECORD" 2>/dev/null | tail -1)
  [ -n "$line" ] || return 1
  printf '%s' "${line%%  *}"
}

# record_digest <dest> <digest>
#
# Append-and-dedupe rather than rewrite in place. A later entry wins, which
# recorded_digest reads with tail -1, so a re-delivery does not have to find
# and edit its own old line.
record_digest() {
  local rel="${1#"$DEST_CHAPTER_DIR/"}" digest="$2"
  printf '%s  %s\n' "$digest" "$rel" >>"$RECORD"
}

# deliver_file <src> <dest>
#
# The one place the never-overwrite rule lives. Every file this script places
# goes through here, one file at a time, so a hand-edited file inside a
# recursively-delivered directory (e.g. one starter out of several) is left
# alone without holding back its untouched siblings.
#
# THE MESSAGES FOR EVERY CASE THAT EXISTED BEFORE tla-oa0m ARE UNCHANGED, on
# purpose. "skipped (exists): <path>" still means what it meant, and
# harness/test-deliver-exercises.sh pins that string. The record adds one new
# outcome, a file the learner has not touched being brought up to a moved
# source, and one new line on the conflict, which prints AFTER the skip line
# rather than instead of it.
deliver_file() {
  local src="$1" dest="$2" src_d dest_d rec_d

  if [ ! -e "$dest" ]; then
    if [ "$CHECK_ONLY" -eq 1 ]; then
      echo "would deliver: $dest"
      return
    fi
    if [ "$ADOPT_ONLY" -eq 1 ]; then
      echo "not delivered, so nothing to adopt: $dest"
      return
    fi
    mkdir -p "$(dirname -- "$dest")"
    cp "$src" "$dest" || return 1
    src_d=$(digest_of "$src") && record_digest "$dest" "$src_d"
    return
  fi

  src_d=$(digest_of "$src")  || src_d=""
  dest_d=$(digest_of "$dest") || dest_d=""
  rec_d=$(recorded_digest "$dest") || rec_d=""

  if [ "$ADOPT_ONLY" -eq 1 ]; then
    if [ -n "$rec_d" ]; then
      echo "already recorded: $dest"
    elif [ -n "$src_d" ] && [ "$src_d" = "$dest_d" ]; then
      record_digest "$dest" "$dest_d"
      ADOPTED_COUNT=$((ADOPTED_COUNT + 1))
      echo "adopted, byte-identical to its source: $dest"
    else
      # Count it. Until 2026-10-18 this branch returned without touching
      # CONFLICT_COUNT, so the summary line below said "0 left unrecorded"
      # on a chapter that left five files unrecorded. A bootstrap reporting
      # that it recorded everything, when the files it skipped are exactly
      # the learner's own work, is the one number somebody would act on.
      CONFLICT_COUNT=$((CONFLICT_COUNT + 1))
      echo "not adopted, it differs from its source so it may be your work: $dest"
    fi
    return
  fi

  # Nothing to propagate. This is the common case and it keeps the old message
  # whatever the provenance turns out to be, because there is no difference to
  # report and the learner does not need to hear about the record.
  if [ -n "$src_d" ] && [ "$src_d" = "$dest_d" ]; then
    echo "skipped (exists): $dest"
    return
  fi

  # Provably unedited: the bytes on disk are the bytes this script wrote. The
  # source has moved, so land it. This is the one case the bead exists for.
  if [ -n "$rec_d" ] && [ "$rec_d" = "$dest_d" ]; then
    STALE_COUNT=$((STALE_COUNT + 1))
    if [ "$CHECK_ONLY" -eq 1 ]; then
      echo "STALE, you have not edited it so a run would update it: $dest"
      return
    fi
    cp "$src" "$dest" || return 1
    record_digest "$dest" "$src_d"
    echo "updated, you had not edited it: $dest"
    return
  fi

  # Either the record says he edited it, or there is no record and the safe
  # reading is that he did. Never touched either way. The skip line comes
  # first so the string the suite pins is still on its own line.
  CONFLICT_COUNT=$((CONFLICT_COUNT + 1))
  if [ "$CHECK_ONLY" -eq 1 ]; then
    if [ -n "$rec_d" ]; then
      echo "CONFLICT, your edit and a moved source: $dest"
    else
      echo "CONFLICT, differs from source and has no record, so it may be your work: $dest"
    fi
    return
  fi
  echo "skipped (exists): $dest"
  if [ -n "$rec_d" ]; then
    echo "  and the source has moved since you edited it, so merge $src by hand" >&2
  else
    echo "  and it differs from $src with no record of delivery, so merge by hand if it is not yours" >&2
  fi
}

deliver_file "$SRC_CHAPTER_DIR/EXERCISES.md" "$DEST_CHAPTER_DIR/EXERCISES.md"
deliver_file "$SRC_ROOT/templates/LOG.md" "$DEST_CHAPTER_DIR/LOG.md"

if [ -d "$SRC_CHAPTER_DIR/starters" ]; then
  while IFS= read -r -d '' src_file; do
    rel="${src_file#"$SRC_CHAPTER_DIR/starters/"}"
    deliver_file "$src_file" "$DEST_CHAPTER_DIR/starters/$rel"
  done < <(find "$SRC_CHAPTER_DIR/starters" -type f -print0)
fi

m=2
while [ "$m" -lt "$CHAPTER_NUM" ]; do
  m_padded=$(printf 'ch%02d' "$m")
  src_sheet="$SRC_ROOT/$m_padded/CHEATSHEET.md"
  if [ -f "$src_sheet" ]; then
    deliver_file "$src_sheet" "$DEST_CHAPTER_DIR/cheatsheets/$m_padded.md"
  else
    echo "missing sheet: $m_padded" >&2
  fi
  m=$((m + 1))
done

if [ "$ADOPT_ONLY" -eq 1 ]; then
  echo "$ADOPTED_COUNT file(s) adopted, $CONFLICT_COUNT left unrecorded"
  exit 0
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo "$STALE_COUNT stale, $CONFLICT_COUNT conflicted"
  # STALE IS THE FAILURE AND CONFLICTED IS NOT, which is what the usage line
  # above has always said and what this code did not do until 2026-10-18.
  #
  # The two findings are not the same kind of thing. Stale means a delivery is
  # owed and somebody can act on it tonight. Conflicted means the file differs
  # from its record, so it is the learner's own work, and the only correct
  # action is to leave it alone forever. Returning 3 for both put a permanent
  # red on every chapter he had actually worked: measured the same day at
  # 10 of 12 chapters red, every one of them red because he had done the
  # exercises. A wrap-up gate wired to that goes red every night for a reason
  # that is never actionable, and a gate nobody reads is worse than no gate.
  #
  # So conflicts are reported in the line above and never in the exit code.
  if [ "$STALE_COUNT" -gt 0 ]; then
    exit 3
  fi
  exit 0
fi

exit 0
