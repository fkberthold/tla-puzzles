#!/usr/bin/env bash
# drill: serve the next drill in the queue, and keep a record of what got done.
#
# Delivered to ~/tla-practice/drill/drill by scripts/deliver-drill.sh, with no
# extension, so the command reads `./drill`.
#
# Usage:  ./drill [done|shaky|status|list|help] [<family>/<item>]
#
# Exit:   0 on a served drill, a recorded mark, a status or a list, and on an
#           empty queue, which is finishing rather than failing
#         1 on a usage error, a drill name that is not in the tree, a mark with
#           nothing served to attach it to, or a failed write
#
# ---------------------------------------------------------------------------
# WHERE THIS RUNS, WHICH IS WHY IT DEPENDS ON NOTHING
#
# ~/tla-practice is not a git repo. There is no harness beside this file, no
# bd, no sibling script, and no guarantee that TLC is on the path. So this
# script sources nothing, resolves no repo root, and reads nothing outside the
# directory it sits in. Everything it reads it works out from
# ${BASH_SOURCE[0]} and from the tree under it.
#
# THE ONE EXCEPTION, AND IT IS A WRITE RATHER THAN A READ. A serve creates the
# study directory you work the drill in, at $DRILL_STUDY_ROOT/<slug>, which
# defaults to $HOME/Study/tla-drills/<slug>. That is the only path outside
# this directory that this script touches, it is created and never read, and
# nothing in here opens a file under it.
#
# Why the exception is worth the narrowing: the work goes in a separate flat
# tree on purpose, so ~/tla-practice stays written only by scripts and a
# re-delivery can never land on top of a page Frank wrote in. Starting a drill
# was then three commands, and the directory is the one of the three this
# script already knows the name of.
#
# IT IS A CONVENIENCE AND THE SERVE IS THE JOB. A creation that fails warns on
# stderr and the serve carries on: the prompt prints, the pointer is written,
# and the exit code is 0. An unset HOME with no DRILL_STUDY_ROOT, a root that
# is a regular file, a read-only disk: none of those is a reason to withhold
# the prompt, because every one of them is fixed with one mkdir.
#
# AN EXISTING DIRECTORY IS NEVER TOUCHED. If it is already there the serve
# names it and says nothing about creating it. It holds the only copy of work
# that has no git behind it.
#
# It also has to work on a first run, with no state file and nothing marked.
# An absent PROGRESS.tsv means "nothing done yet", which is the ordinary case
# the morning a corpus lands, not an error.
#
# ---------------------------------------------------------------------------
# THE QUEUE IS DERIVED FROM THE TREE, NEVER FROM A LIST
#
# Items come from the glob */[0-9][0-9]-*/PROMPT.md under this directory. No
# count and no item name is written down anywhere in this file, because the
# corpus grows and a hardcoded corpus count is a staleness shape this project
# has hit more than once. 64 drills in 8 families landed on 2026-10-14, and
# nothing here breaks when that becomes 72.
#
# ORDER IS INTERLEAVED BY INDEX. 01 of every family, then 02 of every family,
# and alphabetical by family inside an index so the order is the same on every
# box. The number inside a family is an authoring order rather than a
# difficulty ramp, which scripts/deliver-drill.sh's header says, so
# interleaving costs nothing and keeps the variety high.
#
# ---------------------------------------------------------------------------
# THE TWO MARKS, AND WHAT SHAKY DOES
#
# done retires a drill. shaky retires it from the current pass and puts it
# back after everything untried, so a drill you half got comes round again
# instead of vanishing.
#
# Among the shaky ones the order is oldest mark first, and that is a decision
# rather than a detail. Canonical order would starve: once every drill is
# shaky the queue is all shaky, the head of it is whatever sorts first, and
# marking that head shaky again leaves it at the head. You would get the same
# drill until you marked it done. Ordering the shaky tail by when it was
# marked sends a re-marked drill to the back, so the pass keeps moving. The
# line number of a mark is a total order, so there is no tie to break and the
# result is the same on every box.
#
# ---------------------------------------------------------------------------
# THE RECORD IS APPEND-ONLY, WHICH IS WHAT MAKES IT A RECORD
#
#   PROGRESS.tsv    <iso8601>\t<mark>\t<family>/<item>
#
# A later line supersedes an earlier one by recency, so shaky then done is
# done. No line is ever rewritten, deleted or sorted in place. That costs
# nothing and buys two things: the log says when you worked, and a spacing
# schedule can read it later without anyone rewriting the format.
#
# Every entry carries a timestamp whether or not anything reads it yet.
#
# IT IS READ WITH PARAMETER EXPANSION, not with `IFS=$'\t' read`. That form is
# banned in this project, and for a good reason: bash strips a leading and a
# trailing empty field and collapses runs of the separator, so a TSV read that
# way loses data without saying so. `cut -f` is the other sanctioned way and
# costs a fork per line. The expansions below cut on the first and second tab
# exactly, with no fork at all.
#
# ---------------------------------------------------------------------------
# WHAT IT WRITES, WHICH IS THREE PATHS AND NOTHING ELSE
#
#   PROGRESS.tsv    appended to, one line per mark
#   LAST-SERVED     the drill served last, so a mark takes no argument
#   <study>/<slug>  created on a serve, and only ever created
#
# The first two sit beside this file. The third is the exception the section
# above argues, and it is a bare mkdir: no file is written into it, now or
# ever, by this script. There is no delete path anywhere in here.
# ~/tla-practice holds the only copy of the work done in it and has no git
# behind it, so a clobbered file does not come back, and the study tree is in
# the same position.
#
# LAST-SERVED is the one file that gets replaced rather than appended to, and
# that is sound because it holds no work. It is this script's own cursor, it
# is rewritten on every serve, and the record of what happened is in
# PROGRESS.tsv. A pointer can go stale if you work two terminals, which is why
# both marks also take an explicit <family>/<item>.

set -uo pipefail

if [ "${BASH_VERSINFO[0]:-0}" -lt 4 ]; then
  echo "drill: this needs bash 4 or newer, and the shell reports ${BASH_VERSION:-an unknown version}." >&2
  exit 1
fi

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

PROGRESS="$HERE/PROGRESS.tsv"
POINTER="$HERE/LAST-SERVED"

# The study root, which is the one path resolved from outside this tree. See
# the header for why the exception exists and why it cannot fail a serve.
#
# An EMPTY STUDY_ROOT means neither the variable nor HOME resolved, and a
# serve says so rather than guessing. Defaulting to /Study/tla-drills on an
# unset HOME would be a write at the filesystem root, which is the one place
# an accident is worst and the one place a privileged shell would let it
# through.
#
# The trailing slash comes off both forms, so DRILL_STUDY_ROOT=/tmp/x/ and
# DRILL_STUDY_ROOT=/tmp/x name the same directory rather than two paths that
# differ by a doubled separator in every message.
#
# `${HOME:+...}` rather than `${HOME:-}` and a test: the :+ form yields the
# whole default path when HOME is set and the empty string when it is not, so
# the fallback is one line and HOME is named in one place. The form is a
# defined-ness test, so it does not trip `set -u` on an unset HOME.
STUDY_ROOT="${DRILL_STUDY_ROOT:-}"
[ -n "$STUDY_ROOT" ] || STUDY_ROOT="${HOME:+${HOME%/}/Study/tla-drills}"
STUDY_ROOT="${STUDY_ROOT%/}"

TAB=$'\t'

usage() {
  cat <<'USAGE'
Usage: ./drill [done|shaky|status|list|help] [<family>/<item>]

  ./drill            serve the next drill: where to work, then its prompt
  ./drill done       mark the drill you were served done, then serve the next
  ./drill shaky      mark it shaky, then serve the next
  ./drill status     how many are done, shaky and untried
  ./drill list       the queue, in the order it gets served
  ./drill help       this text

A mark takes no argument, because the point is one command per drill. The
runner remembers what it served last. Name a drill to mark something else,
which is what you want when two terminals have drifted apart.

done retires a drill. shaky puts it back after everything untried, so a drill
you half got comes round again.

A serve makes the directory to work the drill in, under ~/Study/tla-drills.
Set DRILL_STUDY_ROOT to put it somewhere else. A directory already there is
left exactly as it is, and a serve that cannot make one still serves.
USAGE
}

# ---------------------------------------------------------------------------
# The corpus, in canonical order: index first, then family.
#
# The index is fixed at two digits by the glob, so a plain C-locale sort over
# "<index><tab><family>/<item>" gives index then family alphabetically. No
# numeric sort is needed and none is used.
# ---------------------------------------------------------------------------

ITEMS=()

collect_items() {
  local p rel item idx line
  local -a keyed=()
  ITEMS=()
  shopt -s nullglob
  for p in "$HERE"/*/[0-9][0-9]-*/PROMPT.md; do
    rel="${p#"$HERE"/}"
    item="${rel%/PROMPT.md}"
    idx="${item#*/}"
    idx="${idx%%-*}"
    keyed+=("${idx}${TAB}${item}")
  done
  shopt -u nullglob
  [ "${#keyed[@]}" -gt 0 ] || return 0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    ITEMS+=("${line#*"$TAB"}")
  done < <(printf '%s\n' "${keyed[@]}" | LC_ALL=C sort)
}

is_item() {
  local want="$1" item
  [ "${#ITEMS[@]}" -gt 0 ] || return 1
  for item in "${ITEMS[@]}"; do
    [ "$item" = "$want" ] && return 0
  done
  return 1
}

families() {
  local item n=0 line
  [ "${#ITEMS[@]}" -gt 0 ] || { printf '0\n'; return; }
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    n=$((n + 1))
  done < <(for item in "${ITEMS[@]}"; do printf '%s\n' "${item%%/*}"; done | LC_ALL=C sort -u)
  printf '%s\n' "$n"
}

# ---------------------------------------------------------------------------
# The record. A later line wins, which is recency, which is why nothing has to
# be rewritten when a shaky drill is later got.
# ---------------------------------------------------------------------------

declare -A MARK_OF=()
declare -A MARKLINE_OF=()

read_progress() {
  MARK_OF=()
  MARKLINE_OF=()
  [ -f "$PROGRESS" ] || return 0
  local n=0 line rest mark item
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    # A line with fewer than three fields is not an entry. Skipping it rather
    # than guessing at it is what keeps a hand-edited log from being read
    # wrong.
    case "$line" in
      *"$TAB"*"$TAB"*) ;;
      *) continue ;;
    esac
    rest="${line#*"$TAB"}"
    mark="${rest%%"$TAB"*}"
    item="${rest#*"$TAB"}"
    case "$mark" in
      done | shaky) ;;
      *) continue ;;
    esac
    MARK_OF["$item"]="$mark"
    MARKLINE_OF["$item"]="$n"
  done <"$PROGRESS"
}

count_mark() {
  local want="$1" item n=0
  if [ "${#ITEMS[@]}" -gt 0 ]; then
    for item in "${ITEMS[@]}"; do
      if [ "${MARK_OF[$item]:-}" = "$want" ]; then
        n=$((n + 1))
      fi
    done
  fi
  printf '%s\n' "$n"
}

# ---------------------------------------------------------------------------
# The queue: everything untried in canonical order, then every shaky drill in
# the order it was marked, oldest first. See the header for why the shaky tail
# is not in canonical order.
# ---------------------------------------------------------------------------

QUEUE=()

build_queue() {
  local item mark line
  local -a untried=() shaky_keyed=()
  QUEUE=()
  if [ "${#ITEMS[@]}" -gt 0 ]; then
    for item in "${ITEMS[@]}"; do
      mark="${MARK_OF[$item]:-}"
      case "$mark" in
        done) continue ;;
        shaky) shaky_keyed+=("$(printf '%012d' "${MARKLINE_OF[$item]}")${TAB}${item}") ;;
        *) untried+=("$item") ;;
      esac
    done
  fi
  if [ "${#untried[@]}" -gt 0 ]; then
    QUEUE+=("${untried[@]}")
  fi
  [ "${#shaky_keyed[@]}" -gt 0 ] || return 0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    QUEUE+=("${line#*"$TAB"}")
  done < <(printf '%s\n' "${shaky_keyed[@]}" | LC_ALL=C sort)
}

# ---------------------------------------------------------------------------
# Serving.
#
# THE STUDY DIRECTORY, which is the exception the header argues. It is placed
# flat, under the slug alone: the item with its family stripped, so
# control-state/01-slip-on-the-spike works in 01-slip-on-the-spike. That is
# unambiguous because all 64 delivered slugs are distinct across the eight
# families, and it keeps the path short enough to type.
#
# `${item##*/}` rather than basename or a cut: it is exact on a two-segment
# item name and it forks nothing. A serve already forks twice for the counts,
# and this is the hot path a learner runs every day.
#
# STUDY_MADE is reported and never inferred from a timestamp. A directory
# somebody else created a second earlier is still a directory this serve did
# not create, and saying otherwise over a tree that holds the only copy of the
# work is the wrong direction to be wrong in.
# ---------------------------------------------------------------------------

STUDY_DIR=""
STUDY_MADE=0

# ensure_study <item>: resolve the study directory for an item and create it
# if it is absent. Never fails: STUDY_DIR comes back empty when there is
# nothing to name, and the caller serves the drill either way.
ensure_study() {
  local item="$1" slug
  STUDY_DIR=""
  STUDY_MADE=0

  if [ -z "$STUDY_ROOT" ]; then
    echo "drill: no study directory this time: DRILL_STUDY_ROOT is unset and so is HOME," >&2
    echo "drill: so there is no root to put one under. Set DRILL_STUDY_ROOT to choose one." >&2
    return 0
  fi

  slug="${item##*/}"

  if [ -d "$STUDY_ROOT/$slug" ]; then
    STUDY_DIR="$STUDY_ROOT/$slug"
    return 0
  fi

  if mkdir -p -- "$STUDY_ROOT/$slug" 2>/dev/null; then
    STUDY_DIR="$STUDY_ROOT/$slug"
    STUDY_MADE=1
    return 0
  fi

  echo "drill: cannot create the study directory at $STUDY_ROOT/$slug, so work" >&2
  echo "drill: wherever you like and set DRILL_STUDY_ROOT when you want one made." >&2
  return 0
}

serve_next() {
  local total="${#ITEMS[@]}" done_n shaky_n item
  build_queue
  done_n="$(count_mark "done")"
  shaky_n="$(count_mark "shaky")"

  if [ "${#QUEUE[@]}" -eq 0 ]; then
    echo "The queue is empty. All ${total} drills are done."
    echo "To take another pass at one: ./drill shaky <family>/<item>"
    return 0
  fi

  item="${QUEUE[0]}"
  if ! printf '%s\n' "$item" >"$POINTER"; then
    echo "drill: cannot write the pointer at $POINTER" >&2
    return 1
  fi

  # Before the prompt, so a warning about the directory is read next to the
  # line that would have named it rather than scrolled off above the prompt.
  ensure_study "$item"

  echo "== ${item} =="
  if [ "${MARK_OF[$item]:-}" = "shaky" ]; then
    echo "You marked this one shaky, so here it is again."
  fi
  printf '%s queued, %s done, %s shaky, %s drills in all\n' \
    "${#QUEUE[@]}" "$done_n" "$shaky_n" "$total"
  if [ -n "$STUDY_DIR" ]; then
    if [ "$STUDY_MADE" -eq 1 ]; then
      printf 'work in: %s   (created)\n' "$STUDY_DIR"
    else
      printf 'work in: %s\n' "$STUDY_DIR"
    fi
  fi
  echo
  cat "$HERE/$item/PROMPT.md"
  echo
  echo "----"
  echo "./drill done when you got it, ./drill shaky when you half got it."
  echo "Either one serves the next drill."
}

# ---------------------------------------------------------------------------
# Marking. The drill to mark comes from the argument if there is one, and from
# the pointer otherwise. Either way it has to be a drill that is in the tree:
# a name that is not gets refused rather than written, so the record never
# holds an entry for something that does not exist.
# ---------------------------------------------------------------------------

TARGET=""

resolve_target() {
  local verb="$1" arg="${2:-}" item=""
  TARGET=""
  if [ -n "$arg" ]; then
    item="${arg%/}"
    item="${item#./}"
  elif [ -f "$POINTER" ]; then
    IFS= read -r item <"$POINTER" || item=""
    if [ -z "$item" ]; then
      echo "drill: the pointer at $POINTER is empty, so there is nothing to mark." >&2
      echo "drill: run ./drill to be served one, or name it: ./drill $verb <family>/<item>" >&2
      return 1
    fi
  else
    echo "drill: nothing has been served yet, so there is nothing to mark." >&2
    echo "drill: run ./drill first, or name it: ./drill $verb <family>/<item>" >&2
    return 1
  fi
  if ! is_item "$item"; then
    echo "drill: no drill at ${item}. Run ./drill list to see what there is." >&2
    return 1
  fi
  TARGET="$item"
}

mark_target() {
  local verb="$1" item="$2" ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if ! printf '%s\t%s\t%s\n' "$ts" "$verb" "$item" >>"$PROGRESS"; then
    echo "drill: cannot append to the record at $PROGRESS" >&2
    return 1
  fi
  echo "${verb}: ${item}"
  echo
}

# ---------------------------------------------------------------------------
# Reporting.
# ---------------------------------------------------------------------------

show_status() {
  local total="${#ITEMS[@]}" done_n shaky_n untried_n
  build_queue
  done_n="$(count_mark "done")"
  shaky_n="$(count_mark "shaky")"
  untried_n=$((total - done_n - shaky_n))
  printf '%s drills in %s families, at %s\n' "$total" "$(families)" "$HERE"
  printf '  untried  %s\n' "$untried_n"
  printf '  shaky    %s\n' "$shaky_n"
  printf '  done     %s\n' "$done_n"
  printf '  queued   %s   (the untried ones, then the shaky ones)\n' "${#QUEUE[@]}"
}

show_list() {
  local i=0 item mark total="${#ITEMS[@]}"
  build_queue
  if [ "${#QUEUE[@]}" -eq 0 ]; then
    echo "The queue is empty. All ${total} drills are done."
    return 0
  fi
  for item in "${QUEUE[@]}"; do
    i=$((i + 1))
    mark="${MARK_OF[$item]:-untried}"
    printf '%4d  %-44s %s\n' "$i" "$item" "$mark"
  done
  printf '%s queued of %s\n' "${#QUEUE[@]}" "$total"
}

# ---------------------------------------------------------------------------
# Main.
# ---------------------------------------------------------------------------

VERB=""
ARG=""

case "${1:-}" in
  "") VERB="serve" ;;
  done | shaky | status | list) VERB="$1" ;;
  help | -h | --help)
    usage
    exit 0
    ;;
  -*)
    echo "drill: unknown option: $1" >&2
    usage >&2
    exit 1
    ;;
  *)
    echo "drill: unknown command: $1" >&2
    usage >&2
    exit 1
    ;;
esac

if [ "$#" -gt 0 ]; then
  shift
fi

if [ "$#" -gt 0 ]; then
  ARG="$1"
  shift
fi

if [ "$#" -gt 0 ]; then
  echo "drill: unexpected extra argument: $1" >&2
  usage >&2
  exit 1
fi

case "$VERB" in
  serve | status | list)
    if [ -n "$ARG" ]; then
      echo "drill: ${VERB} takes no argument." >&2
      usage >&2
      exit 1
    fi
    ;;
esac

collect_items

if [ "${#ITEMS[@]}" -eq 0 ]; then
  echo "drill: no drill found under $HERE." >&2
  echo "drill: a drill is a directory at <family>/<NN-slug> carrying a PROMPT.md." >&2
  exit 1
fi

read_progress

case "$VERB" in
  serve)
    serve_next
    ;;
  status)
    show_status
    ;;
  list)
    show_list
    ;;
  done | shaky)
    resolve_target "$VERB" "$ARG" || exit 1
    mark_target "$VERB" "$TARGET" || exit 1
    read_progress
    serve_next
    ;;
esac
