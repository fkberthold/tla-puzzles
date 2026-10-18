#!/usr/bin/env bash
# deliver-problems.sh: deliver one problem into a practice tree, under the
# directory name its position in the ramp calls for, without ever handing over
# the author's own copy and without ever overwriting work in progress.
#
# Usage:  scripts/deliver-problems.sh [--check] <name> [dest-root]
#
#   --check    resolve everything and print what would be delivered. Writes
#              nothing.
#   name       the bare problem name, e.g. river-call. Never the numbered
#              directory name.
#   dest-root  where to deliver into (default: $HOME/tla-practice/problems)
#
# Env:    DELIVER_PROBLEMS_SRC_ROOT   override the source repo root (default:
#                                     the repo this script lives in)
#
# Exit:   0 on success, including a run that only skipped files already there
#         1 on a usage error, an unresolvable or empty source, or a destination
#           that already holds this problem under a different number
#
# ---------------------------------------------------------------------------
# WHAT LANDS AND WHAT NEVER DOES
#
# Everything under <location>/<name>/statement/ lands, recursively. That tree is
# the manifest. This script does not know the name of a single file it delivers,
# and that is the whole point of it.
#
# The one thing it WITHHOLDS is a file whose name ends -with-author-notes.md.
# That is the author's annotated copy of the statement, and it carries the
# reasoning the problem exists to make the reader do. Every withheld file is
# reported on stdout, so a withholding is visible rather than silent.
#
# Nothing outside statement/ is delivered. reference/, reports/, author-notes/
# and VECTOR.md sit beside it and are the answer key, the grading history and
# the load vector.
#
# WHY THE MANIFEST IS A TREE AND NOT A LIST
#
# The shape is not uniform across the ramp. A problem whose load vector carries
# representation 1 HANDS the learner a spec, so it ships a .tla or a .cfg. A
# representation-2 problem makes the learner write one, so it ships neither.
# Three of the seven on the ramp ship a starter artifact and four do not.
#
# On 2026-10-02 that asymmetry was guessed rather than read. The guess was
# PROBLEM.md plus ATTEMPT-LOG.md plus traces/, which deleted bonded-store's
# BondedStore.tla, river-call's RiverCall.cfg and assay-office's
# AssayOffice.tla. Two problems then got reported as half-attempted when what
# was being read was the shipped artifact, and the wrong reading of a learner's
# progress cost more than the deletion did.
#
# So the manifest is the tree, and a filename appears nowhere in this script.
# A per-problem exclusion list was the other way to express the one
# withholding, and it is the same mistake one layer along: a list is a second
# manifest, and it drifts from the tree the moment somebody adds a file. The
# convention cannot drift, because there is only one place to read it from.
#
# ---------------------------------------------------------------------------
# THE NUMBER ON THE DIRECTORY
#
# A problem is delivered as NN_name, where NN is its 1-based position in
# <dest-root>/ORDER. ORDER is the one source of truth for the ramp's sequence,
# and scripts/number-problems.sh owns that convention. Blank lines and comment
# lines consume no position, so a position is not a line number. A line
# matching ^[[:space:]]*checkpoint: is refused outright, which is D6 and bead
# tla-5zgr.2. See the parse itself for why a refusal rather than a skip.
#
# The parse below is DUPLICATED from scripts/number-problems.sh rather than
# shared with it, because sharing means editing that file. What keeps the copy
# honest is harness/test-deliver-problems.sh, which hands one ORDER to both
# scripts and requires the same directory names out of each. Extracting a
# shared parse is the better end state and wants its own bead.
#
# A name ORDER does not carry is off the ramp by convention, so it delivers
# under its bare name. A destination with no ORDER at all delivers the same way
# and says so on stderr: an unnumbered directory is a state
# scripts/number-problems.sh fixes the moment ORDER grows the entry, so a
# missing ORDER is worth reporting without being worth refusing.
#
# ---------------------------------------------------------------------------
# NEVER OVERWRITE
#
# ~/tla-practice is not a git repo and it holds the only copy of a learner's
# work, so a clobbered file does not come back. Every file this script places is
# checked for existence first. An existing file is left untouched and reported
# on stdout as "skipped (exists): <path>", and its untouched siblings still
# land, because the rule lives per file rather than per directory.
#
# There is one refusal on top of that. If the destination already holds this
# problem under a DIFFERENT number, delivering alongside it would leave two
# directories for one ORDER entry, which scripts/number-problems.sh then
# reports as ambiguous forever. That run refuses and changes nothing.
#
# ---------------------------------------------------------------------------
# AND THE THIRD STATE (beads tla-oa0m and tla-mjvx)
#
# Never-overwrite froze every delivered problem at its delivery date, so a
# repair to a statement reached the repo and never reached the learner. The
# tension is real rather than a bug: protecting a half-written ATTEMPT-LOG.md
# and propagating a fix want opposite things from the same directory. A --force
# flag does not resolve it, because the file most worth fixing is the file most
# likely to hold the work.
#
# So delivery records what it wrote. With that record there are three states
# instead of two, and only one of them is ambiguous:
#
#   absent                      deliver, as before
#   present, matches record     the learner has not edited it, so a moved
#                               source is safe to land and this script lands it
#   present, differs from       the learner's work. Never touched, whatever the
#     record                    source says, and reported as a conflict to
#                               merge by hand
#   present, no record          provenance unknown. Treated as the learner's
#                               work, which is the safe reading
#
# THE RECORD IS .delivered.sha256 IN THE DELIVERED PROBLEM DIRECTORY, one
# "<digest> <path relative to that directory>" line per file, and ONLY A
# DELIVERY WRITES AN ENTRY. That last clause is the whole safety argument: an
# entry means this script put those exact bytes there, so a file matching its
# entry is provably unedited. Infer an entry from anything else and the
# inference is what overwrites the learner's work.
#
# Keying the entries on the path INSIDE the problem directory is what lets
# scripts/number-problems.sh renumber 03_river-call to 04_river-call without
# invalidating a single one of them.
#
# SO "NEVER OVERWRITE" ABOVE IS NOW EXACTLY "NEVER OVERWRITE THE LEARNER'S
# WORK". The one file this script will replace is one it can prove it wrote
# itself, byte for byte.
#
# WHAT THIS CANNOT DO RETROACTIVELY. A problem delivered before records existed
# has none, so it stays in the ambiguous state and nothing gets auto-updated.
# --adopt is the safe bootstrap: it records an entry for every delivered file
# that is BYTE-IDENTICAL to its source, which is provably unedited, and records
# nothing for the rest.
#
# ---------------------------------------------------------------------------
# --verify IS THE DRIFT REPORT AND --check IS THE DRY RUN
#
# The two read alike and they answer different questions, which is the whole of
# bead tla-mjvx. --check reports what a delivery WOULD do, so it prints "would
# skip (exists)" for every file of a tree that is already byte-identical and
# exits 0. It cannot tell a stale tree from a current one. --verify compares
# content against the record and reports only what drifted. --verify is the
# spelling scripts/deliver-recall.sh already uses, so
# scripts/verify-delivery.sh can call one flag on every channel.
#
# `all` IS ACCEPTED WITH --verify AND --adopt, AND NOWHERE ELSE. A verify is a
# question about the whole channel, and the ramp's whole point is that a
# delivery is one problem at a time. Those are different questions, so they get
# different argument vocabularies rather than one that silently answers both.
#
# STALE EXITS 3 AND CONFLICTED DOES NOT. The two are not the same kind of
# finding. Stale means a delivery is owed and somebody can act on it tonight.
# Conflicted means the file differs from its record, so it is the learner's own
# work, and the only correct action is to leave it alone forever. Returning 3
# for both would put a permanent red on every problem the learner had actually
# worked, and a gate that is red every night for a reason nobody can act on is
# worse than no gate. Measured on the exercises channel the same week: 10 of 12
# chapters red, every one of them red because Frank had done the exercises.
#
# AN ABSENT DESTINATION ROOT IS A SKIP AT EXIT 0. No box but Frank's has a
# delivered tree and a CI runner never will.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE >&2
Usage: $0 [--check | --verify | --adopt] <name|all> [dest-root]

  --check    print what would be delivered, and write nothing
  --verify   compare every delivered file against its source and its delivery
             record, name every path that is stale or conflicted, and exit 3
             if any is stale. Conflicts are the learner's work: they are
             counted and reported and never failed on. Writes nothing. An
             absent destination root is a skip at exit 0.
  --adopt    record a digest for every delivered file that is byte-identical
             to its source, so later repairs can reach a problem delivered
             before this script kept records. Copies nothing.
  name       the bare problem name, e.g. river-call. 'all' is every problem
             the source carries, and is accepted only with --verify or
             --adopt, because a delivery is one problem at a time.
  dest-root  where to deliver into (default: \$HOME/tla-practice/problems)

Env:
  DELIVER_PROBLEMS_SRC_ROOT   override the source repo root (default: $REPO_ROOT)
USAGE
}

SRC_ROOT="${DELIVER_PROBLEMS_SRC_ROOT:-$REPO_ROOT}"

# The three places a problem can live, by pipeline. authoring/ holds the seven
# on the ramp, curated/ holds hand-curated ones, sources/problems/ holds the
# prose pipeline's output.
SRC_LOCATIONS=(authoring curated sources/problems)

# The delivery record. It lives in the DESTINATION problem directory and is
# never source material, so it can never appear in the statement/ manifest.
RECORD_NAME=".delivered.sha256"

CHECK_ONLY=0
VERIFY_ONLY=0
ADOPT_ONLY=0
NAME=""
DEST_ROOT=""
POSITIONAL=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)
      CHECK_ONLY=1
      shift
      ;;
    --verify)
      VERIFY_ONLY=1
      shift
      ;;
    --adopt)
      ADOPT_ONLY=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "$0: unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      POSITIONAL=$((POSITIONAL + 1))
      case "$POSITIONAL" in
        1) NAME="$1" ;;
        2) DEST_ROOT="$1" ;;
        *)
          echo "$0: unexpected extra argument: $1" >&2
          usage
          exit 1
          ;;
      esac
      shift
      ;;
  esac
done

# Anything left after a bare `--` is still an argument.
while [ "$#" -gt 0 ]; do
  POSITIONAL=$((POSITIONAL + 1))
  case "$POSITIONAL" in
    1) NAME="$1" ;;
    2) DEST_ROOT="$1" ;;
    *)
      echo "$0: unexpected extra argument: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

# The three non-delivering modes ask three different questions and two of them
# write. Refusing the combination is cheaper than deciding which one wins.
if [ $((CHECK_ONLY + VERIFY_ONLY + ADOPT_ONLY)) -gt 1 ]; then
  echo "$0: --check, --verify and --adopt ask different questions, so pick one." >&2
  usage
  exit 1
fi

if [ -z "$NAME" ]; then
  echo "$0: no problem name given" >&2
  usage
  exit 1
fi

# `all` is a question about the whole channel, and a delivery is one problem at
# a time. Refusing it outside the two reporting modes is what keeps the two
# questions apart, rather than letting one argument quietly answer both.
if [ "$NAME" = "all" ] && [ "$VERIFY_ONLY" -eq 0 ] && [ "$ADOPT_ONLY" -eq 0 ]; then
  echo "$0: 'all' is accepted with --verify or --adopt only. A delivery is one problem at a time." >&2
  usage
  exit 1
fi

if [ -z "$DEST_ROOT" ]; then
  DEST_ROOT="$HOME/tla-practice/problems"
fi

# ---------------------------------------------------------------------------
# Resolve the position in ORDER.
#
# DUPLICATED from scripts/number-problems.sh. See the header. The filter set and
# the width rule have to match that script exactly, and
# harness/test-deliver-problems.sh is what holds them to it.
#
# This parse runs BEFORE any problem is resolved, because --verify over `all`
# needs the positions for every name and parsing an ORDER once per problem
# would be the same convention read N times. Nothing here touches the source
# tree or the destination, so moving it up changes the order of two stderr
# notes and nothing else.
# ---------------------------------------------------------------------------

ORDER_FILE="$DEST_ROOT/ORDER"
names=()

if [ -f "$ORDER_FILE" ]; then
  lineno=0
  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    trimmed="${line#"${line%%[![:space:]]*}"}"
    [ -z "$trimmed" ] && continue
    case "$trimmed" in
      '#'*) continue ;;
      'checkpoint:'*)
        # D6, bead tla-5zgr.2. The two positional markers were retired when the
        # reading gate became a per-problem label, so an ORDER still carrying
        # one is stale.
        #
        # This refusal matters more here than in the sibling script, because
        # here the alternative failure is SILENT. A marker read as an ORDER
        # entry takes a position, every problem below it shifts by one, and the
        # run exits 0 having delivered into a directory numbered out of a line
        # nobody could parse. The sibling at least goes looking for a directory
        # named after the marker and reports that it is missing.
        #
        # Exit 1, because that is the only failure code this script has. The
        # sibling uses 2, which separates an unusable input from a disagreement
        # with the tree. The codes differ and the refusals do not.
        echo "$0: $ORDER_FILE line $lineno is a retired checkpoint marker: '$trimmed'" >&2
        echo "$0: the reading gate is a per-problem label now, so the positional markers are gone." >&2
        echo "$0: the line is not a problem name and it cannot take a position." >&2
        echo "$0: delete the line from ORDER, then run again." >&2
        exit 1
        ;;
    esac
    names+=("$trimmed")
  done <"$ORDER_FILE"
else
  # Worded without naming a problem, because this parse now runs before one is
  # resolved and because `all` would otherwise read as a problem called all.
  echo "$0: no ORDER file at $ORDER_FILE, so a problem there is not numbered." >&2
  echo "$0: a problem lands under its bare name. Run scripts/number-problems.sh once ORDER names it." >&2
fi

total=${#names[@]}
width=2
[ "$total" -gt 99 ] && width=3

# dest_name_for <name>
#
# The directory a problem belongs in: NN_name for a name ORDER carries, the
# bare name otherwise. Returns 1 for the bare case, so a caller can tell an
# off-ramp problem from a numbered one without comparing strings again.
dest_name_for() {
  local want="$1" entry pos=0
  for entry in "${names[@]}"; do
    pos=$((pos + 1))
    if [ "$entry" = "$want" ]; then
      printf "%0${width}d_%s" "$pos" "$want"
      return 0
    fi
  done
  printf '%s' "$want"
  return 1
}

# matches_name <basename> <problem-name>
#
# The match scripts/number-problems.sh uses to find the directory belonging to
# an ORDER entry: the bare name, or <digits>_<name>. The problem name is a
# parameter rather than a closed-over global, because --verify asks this about
# every problem in the corpus rather than about the one on the command line.
matches_name() {
  local base="$1" want="$2" digits rest
  [ "$base" = "$want" ] && return 0
  digits="${base%%_*}"
  [ "$digits" = "$base" ] && return 1
  [ -z "$digits" ] && return 1
  case "$digits" in
    *[!0-9]*) return 1 ;;
  esac
  rest="${base#*_}"
  [ "$rest" = "$want" ]
}

# ---------------------------------------------------------------------------
# Resolve the source. Exactly one of the three locations has to carry it.
#
# This happens BEFORE the destination is created, so every fatal path below
# leaves the filesystem exactly as it found it.
#
# resolve_statement <name> sets SRC_STATEMENT and returns 0, or prints why it
# could not and returns 1. It is a function rather than straight-line code
# because --verify resolves every problem in the corpus, and a second copy of
# these three messages would drift from this one the day somebody improved
# either.
# ---------------------------------------------------------------------------

SRC_STATEMENT=""

resolve_statement() {
  local want="$1" loc s d
  local found_statements=() found_dirs=()

  for loc in "${SRC_LOCATIONS[@]}"; do
    if [ -d "$SRC_ROOT/$loc/$want/statement" ]; then
      found_statements+=("$SRC_ROOT/$loc/$want/statement")
    fi
    if [ -d "$SRC_ROOT/$loc/$want" ]; then
      found_dirs+=("$SRC_ROOT/$loc/$want")
    fi
  done

  if [ "${#found_statements[@]}" -gt 1 ]; then
    echo "$0: ambiguous: more than one location carries a problem called '$want'" >&2
    for s in "${found_statements[@]}"; do
      echo "$0:   $s" >&2
    done
    echo "$0: a problem belongs to one pipeline. Rename one of them, or deliver by hand." >&2
    return 1
  fi

  if [ "${#found_statements[@]}" -eq 0 ]; then
    if [ "${#found_dirs[@]}" -gt 0 ]; then
      echo "$0: '$want' has no statement/ directory, so there is nothing to deliver:" >&2
      for d in "${found_dirs[@]}"; do
        echo "$0:   $d" >&2
      done
      echo "$0: statement/ is the delivered manifest. A problem without one is not ready." >&2
      return 1
    fi
    echo "$0: no such problem: '$want'. Looked in:" >&2
    for loc in "${SRC_LOCATIONS[@]}"; do
      echo "$0:   $SRC_ROOT/$loc/$want/statement" >&2
    done
    echo "$0: the argument is the bare problem name, never the numbered directory name." >&2
    return 1
  fi

  SRC_STATEMENT="${found_statements[0]}"
  return 0
}

# all_problem_names: every name the source carries a statement/ for, sorted and
# deduplicated. Read off the tree, never off ORDER: a problem can exist in the
# corpus and be off the ramp, and a verify still has something to say about it.
all_problem_names() {
  local loc d base
  for loc in "${SRC_LOCATIONS[@]}"; do
    [ -d "$SRC_ROOT/$loc" ] || continue
    for d in "$SRC_ROOT/$loc"/*/; do
      [ -d "$d/statement" ] || continue
      base="${d%/}"
      base="${base##*/}"
      printf '%s\n' "$base"
    done
  done | LC_ALL=C sort -u
}

# ---------------------------------------------------------------------------
# Build the manifest from the tree, and split it into what lands and what is
# withheld.
#
# is_withheld <basename>
#
# The author's annotated copy of the statement. A name, not a list, so a problem
# that grows one tomorrow is covered without anybody remembering to say so.
is_withheld() {
  case "$1" in
    *-with-author-notes.md) return 0 ;;
  esac
  return 1
}

deliver_rel=()
withheld_rel=()

# build_manifest <statement-dir>: fills deliver_rel and withheld_rel, or
# explains why there is nothing to deliver and returns 1.
build_manifest() {
  local statement="$1" src_file rel
  deliver_rel=()
  withheld_rel=()

  while IFS= read -r -d '' src_file; do
    rel="${src_file#"$statement/"}"
    if is_withheld "$(basename -- "$rel")"; then
      withheld_rel+=("$rel")
    else
      deliver_rel+=("$rel")
    fi
  done < <(find "$statement" -type f -print0 | LC_ALL=C sort -z)

  if [ "${#deliver_rel[@]}" -eq 0 ]; then
    echo "$0: nothing to deliver. $statement holds no deliverable file." >&2
    if [ "${#withheld_rel[@]}" -gt 0 ]; then
      echo "$0: it holds ${#withheld_rel[@]} file(s), and all of them are author notes." >&2
    else
      echo "$0: the statement/ directory is empty." >&2
    fi
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# The delivery record, and the one classifier every mode reads.
#
# recorded_digest compares the WHOLE field after the two-space separator
# rather than a substring, so an entry for traces/pair-1.md cannot answer a
# question about pair-1.md. A later entry wins, which is what lets
# record_digest append instead of rewriting in place.
#
# classify sets CLASS and CLASS_SRC_D. Every mode below reads the same
# function, so --verify cannot report a state that a delivery would then treat
# differently; that agreement is the reason it is a function rather than three
# copies of an if-chain.
# ---------------------------------------------------------------------------

digest_of() {
  [ -f "$1" ] || return 1
  sha256sum -- "$1" | cut -d' ' -f1
}

# recorded_digest <dest-dir> <within>
recorded_digest() {
  local record="$1/$RECORD_NAME" within="$2" line found=''
  [ -f "$record" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    [ "${line#*  }" = "$within" ] || continue
    found="${line%%  *}"
  done <"$record"
  [ -n "$found" ] || return 1
  printf '%s' "$found"
}

# record_digest <dest-dir> <within> <digest>
record_digest() {
  mkdir -p -- "$1" || return 1
  printf '%s  %s\n' "$3" "$2" >>"$1/$RECORD_NAME"
}

CLASS=""
CLASS_SRC_D=""

# classify <src> <dest> <dest-dir> <within>
classify() {
  local src="$1" dest="$2" dir="$3" within="$4" dest_d rec_d
  CLASS_SRC_D=$(digest_of "$src") || CLASS_SRC_D=""
  if [ ! -e "$dest" ]; then
    CLASS="absent"
    return
  fi
  dest_d=$(digest_of "$dest") || dest_d=""
  # Equal content first, and deliberately before the record is consulted. A
  # file that already carries the source's bytes needs no decision about who
  # wrote it, and reporting it would be noise on every run.
  if [ -n "$CLASS_SRC_D" ] && [ "$CLASS_SRC_D" = "$dest_d" ]; then
    CLASS="insync"
    return
  fi
  rec_d=$(recorded_digest "$dir" "$within") || rec_d=""
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

# delivered_dir_for <name>
#
# Where this problem's delivered copy actually is. The numbered name first, and
# then a scan for the same problem under a DIFFERENT number, because a
# destination can legitimately be mid-renumber and reporting "not delivered"
# about a directory sitting right there would be a true statement about the
# wrong question. Prints nothing and returns 1 when it is nowhere.
delivered_dir_for() {
  local want="$1" dn cand base
  dn=$(dest_name_for "$want") || true
  if [ -d "$DEST_ROOT/$dn" ]; then
    printf '%s' "$DEST_ROOT/$dn"
    return 0
  fi
  [ -d "$DEST_ROOT" ] || return 1
  for cand in "$DEST_ROOT"/*/; do
    [ -d "$cand" ] || continue
    base="${cand%/}"
    base="${base##*/}"
    if matches_name "$base" "$want"; then
      # The note goes to stderr because this function's stdout IS the path.
      echo "$0: '$want' is delivered as '$base' rather than '$dn', which scripts/number-problems.sh renames." >&2
      printf '%s' "$DEST_ROOT/$base"
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------------------
# --verify and --adopt. Neither delivers a file, and --verify writes nothing at
# all, including no record.
#
# A problem the destination does not hold AT ALL is one line rather than one
# per file. The ramp hands problems over one at a time, so most of the corpus
# is undelivered on any real tree at any moment, and a line per withheld file
# would bury the one finding somebody has to act on.
# ---------------------------------------------------------------------------

if [ "$VERIFY_ONLY" -eq 1 ] || [ "$ADOPT_ONLY" -eq 1 ]; then
  targets=()
  if [ "$NAME" = "all" ]; then
    while IFS= read -r n; do
      [ -n "$n" ] || continue
      targets+=("$n")
    done < <(all_problem_names)
    if [ "${#targets[@]}" -eq 0 ]; then
      echo "$0: no problem under $SRC_ROOT carries a statement/ directory." >&2
      exit 1
    fi
  else
    targets=("$NAME")
  fi

  echo "source: $SRC_ROOT"
  echo "destination: $DEST_ROOT"

  if [ "$VERIFY_ONLY" -eq 1 ] && [ ! -d "$DEST_ROOT" ]; then
    echo "no delivered tree at $DEST_ROOT, so there is nothing to compare. Skipping."
    exit 0
  fi

  v_sync=0
  v_stale=0
  v_conflict=0
  v_absent=0
  v_problems_absent=0
  v_adopted=0
  v_left=0
  v_err=0

  for n in "${targets[@]}"; do
    if ! resolve_statement "$n"; then
      v_err=1
      continue
    fi
    if ! build_manifest "$SRC_STATEMENT"; then
      v_err=1
      continue
    fi

    if ! dd=$(delivered_dir_for "$n"); then
      v_problems_absent=$((v_problems_absent + 1))
      v_absent=$((v_absent + ${#deliver_rel[@]}))
      if [ "$ADOPT_ONLY" -eq 1 ]; then
        echo "not delivered, so there is nothing to adopt: $DEST_ROOT/$(dest_name_for "$n" || true)"
      else
        echo "not delivered, so there is nothing to compare: $DEST_ROOT/$(dest_name_for "$n" || true)"
      fi
      continue
    fi

    for rel in "${deliver_rel[@]}"; do
      classify "$SRC_STATEMENT/$rel" "$dd/$rel" "$dd" "$rel"

      if [ "$ADOPT_ONLY" -eq 1 ]; then
        if [ "$CLASS" = "absent" ]; then
          echo "not delivered, so nothing to adopt: $dd/$rel"
        elif recorded_digest "$dd" "$rel" >/dev/null; then
          echo "already recorded: $dd/$rel"
        elif [ "$CLASS" = "insync" ]; then
          record_digest "$dd" "$rel" "$CLASS_SRC_D" || exit 1
          v_adopted=$((v_adopted + 1))
          echo "adopted, byte-identical to its source: $dd/$rel"
        else
          v_left=$((v_left + 1))
          echo "not adopted, it differs from its source so it may be your work: $dd/$rel"
        fi
        continue
      fi

      case "$CLASS" in
        absent)
          v_absent=$((v_absent + 1))
          echo "not delivered, so there is nothing to compare: $dd/$rel"
          ;;
        insync)
          v_sync=$((v_sync + 1))
          ;;
        stale)
          v_stale=$((v_stale + 1))
          echo "STALE, you have not edited it so a delivery would update it: $dd/$rel"
          ;;
        conflict_recorded)
          v_conflict=$((v_conflict + 1))
          echo "CONFLICT, your edit and a moved source: $dd/$rel"
          ;;
        *)
          v_conflict=$((v_conflict + 1))
          echo "CONFLICT, differs from source and has no record, so it may be your work: $dd/$rel"
          ;;
      esac
    done
  done

  if [ "$ADOPT_ONLY" -eq 1 ]; then
    # The summary counts what it LEFT, because those files are the learner's
    # and no later repair will reach them. That is the number somebody acts on.
    echo "$v_adopted file(s) adopted, $v_left left unrecorded"
    [ "$v_err" -eq 0 ] || exit 1
    exit 0
  fi

  echo "$v_sync in sync, $v_stale stale, $v_conflict conflicted, $v_absent not delivered ($v_problems_absent whole problem(s))"

  [ "$v_err" -eq 0 ] || exit 1
  # STALE IS THE FAILURE AND CONFLICTED IS NOT. See the header. A conflict is
  # the learner's own work and no run of this script will ever touch it, so it
  # can never be the thing a gate asks somebody to fix.
  if [ "$v_stale" -gt 0 ]; then
    echo "run $0 <name> $DEST_ROOT for each problem named above." >&2
    exit 3
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# From here on exactly one problem is in play, which is what a delivery is.
# ---------------------------------------------------------------------------

resolve_statement "$NAME" || exit 1
build_manifest "$SRC_STATEMENT" || exit 1

if DEST_NAME=$(dest_name_for "$NAME"); then
  :
else
  if [ -f "$ORDER_FILE" ]; then
    echo "$0: ORDER does not name '$NAME', so it is off the ramp." >&2
    echo "$0: delivering under its bare name, which scripts/number-problems.sh leaves alone." >&2
  fi
fi

DEST_DIR="$DEST_ROOT/$DEST_NAME"

# ---------------------------------------------------------------------------
# Refuse a destination that already holds this problem under another name.
#
# Two of those for one ORDER entry is the "ambiguous" error
# scripts/number-problems.sh reports, and delivering is how you create it.
# ---------------------------------------------------------------------------

if [ -d "$DEST_ROOT" ]; then
  strangers=()
  for d in "$DEST_ROOT"/*/; do
    [ -d "$d" ] || continue
    base="${d%/}"
    base="${base##*/}"
    [ "$base" = "$DEST_NAME" ] && continue
    if matches_name "$base" "$NAME"; then
      strangers+=("$base")
    fi
  done

  if [ "${#strangers[@]}" -gt 0 ]; then
    echo "$0: $DEST_ROOT already holds '$NAME' under a different name:" >&2
    for s in "${strangers[@]}"; do
      echo "$0:   $s" >&2
    done
    echo "$0: wanted to deliver into '$DEST_NAME'. Two directories for one ORDER entry" >&2
    echo "$0: is the 'ambiguous' error scripts/number-problems.sh then reports forever." >&2
    echo "$0: run scripts/number-problems.sh '$DEST_ROOT' first, then deliver." >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Report the withholding either way, so it is never silent.
# ---------------------------------------------------------------------------

for rel in "${withheld_rel[@]}"; do
  echo "withheld (author notes): $SRC_STATEMENT/$rel"
done

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo "source: $SRC_STATEMENT"
  echo "destination: $DEST_DIR"
  for rel in "${deliver_rel[@]}"; do
    if [ -e "$DEST_DIR/$rel" ]; then
      echo "would skip (exists): $DEST_DIR/$rel"
    else
      echo "would deliver: $DEST_DIR/$rel"
    fi
  done
  exit 0
fi

# ---------------------------------------------------------------------------
# Deliver.
#
# deliver_file <src> <dest> <within>
#
# The one place the never-overwrite rule lives. Every file goes through here one
# at a time, so a hand-edited file inside the tree is left alone without holding
# back its untouched siblings.
#
# THE MESSAGE FOR EVERY CASE THAT EXISTED BEFORE THE RECORD IS UNCHANGED, on
# purpose. "skipped (exists): <path>" still means what it meant and
# harness/test-deliver-problems.sh pins that string. The record adds one new
# outcome, a file the learner has not touched being brought up to a moved
# source, and one new line on a conflict, which prints AFTER the skip line
# rather than instead of it.
# ---------------------------------------------------------------------------

deliver_file() {
  local src="$1" dest="$2" within="$3"
  classify "$src" "$dest" "$DEST_DIR" "$within"
  case "$CLASS" in
    absent)
      mkdir -p -- "$(dirname -- "$dest")" || return 1
      cp -- "$src" "$dest" || return 1
      if [ -n "$CLASS_SRC_D" ]; then
        record_digest "$DEST_DIR" "$within" "$CLASS_SRC_D" || return 1
      fi
      ;;
    stale)
      # Provably unedited: the bytes on disk are the bytes this script wrote,
      # and the source has moved. This is the one case bead tla-mjvx exists
      # for, and the record is the only thing that makes it safe.
      cp -- "$src" "$dest" || return 1
      record_digest "$DEST_DIR" "$within" "$CLASS_SRC_D" || return 1
      echo "updated, you had not edited it: $dest"
      ;;
    insync)
      echo "skipped (exists): $dest"
      ;;
    conflict_recorded)
      echo "skipped (exists): $dest"
      echo "  and the source has moved since you edited it, so merge $src by hand" >&2
      ;;
    *)
      echo "skipped (exists): $dest"
      echo "  and it differs from $src with no record of delivery, so merge by hand if it is not yours" >&2
      ;;
  esac
  return 0
}

mkdir -p -- "$DEST_DIR" || exit 1

rc=0
for rel in "${deliver_rel[@]}"; do
  if ! deliver_file "$SRC_STATEMENT/$rel" "$DEST_DIR/$rel" "$rel"; then
    echo "$0: failed to deliver: $DEST_DIR/$rel" >&2
    rc=1
  fi
done

exit "$rc"
