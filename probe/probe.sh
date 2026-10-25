#!/usr/bin/env bash
# probe.sh: the transfer-probe runner. Delivered into a practice tree as
# `probe`, beside the item directories.
#
# WHAT THIS IS FOR, because it is not a drill and the difference is the point.
#
# Bead tla-9bnj. Frank is 10 items into a 64-item blank-page drill and reports
# that he is learning. Two readings fit that report equally well: he is
# building specification skill, or he is getting fluent at one item format.
# The two readings only come apart on items OUTSIDE the practiced
# distribution, measured more than once, on a channel that does not care how
# anybody feels about it.
#
# So a probe item differs from a drill item on dimensions that are named
# rather than asserted (Barnett & Ceci 2002, which says the dimensions do not
# combine into one scalar, so each one has to be named on its own):
#
#   modality          600+ words of prose, NO published state count, and no
#                     construct list
#   functional        framed as work somebody would check in, not as an
#                     exercise
#   memory demands    two machines, the requirement's and his own, related by
#                     a mapping he writes
#
# And each item is UNDERSPECIFIED on purpose: at least one bound the prose
# does not give, and one pair of requirements whose interaction he has to
# settle himself. Shin, Jonassen & McGee 2003 (J. Research in Science Teaching
# 40(1):6-33) measured well-structured and ill-structured problem solving
# loading on different predictors, with the ill-structured side additionally
# recruiting regulation of cognition. 64 fully specified items will not train
# that, so the probe has to measure it separately.
#
# ---------------------------------------------------------------------------
# THE RECORD IS A SIDE EFFECT OF THE TWO COMMANDS, WHICH IS WHY IT WILL EXIST
#
# Three capture surfaces in this project were specified, shipped, and stayed
# empty, because each one asked somebody to go and write something down. The
# drill runner is the one that worked, and it worked because it records when
# you ask for the next item.
#
# So `probe start` will not print a brief without a prediction, and
# `probe grade` will not run TLC without a recorded decision. Both of those
# are things the item needs anyway. Neither is a separate chore.
#
# THE PREDICTION IS NOT DECORATION. Kornell & Bjork 2009 found actual
# performance rising sharply while predictions of it stayed flat. So
# prediction accuracy is a second signal, independent of the verdict, and it
# costs one line.
#
#   RECORD.tsv    <iso8601>\t<kind>\t<item>\t<text>
#
# Append-only. Kinds are predict, decide and verdict. A later line supersedes
# an earlier one by recency, and no line is ever rewritten or deleted. Read it
# with parameter expansion or with `cut -f`, never with `IFS=$'\t' read`, which
# strips leading and trailing empty fields and collapses runs of tabs without
# saying so.
#
# ---------------------------------------------------------------------------
# WHERE THE GRADER LIVES, AND WHY THAT IS A REFUSAL RATHER THAN A WARNING
#
# harness/refinement.sh is in the repo and nowhere else. The delivered tree is
# not under the repo and has nothing to walk up to, so the root arrives in
# PROBE_REPO_ROOT or in DRILL_REPO_ROOT, and there is no third route.
# Discovering it was the obvious idea and it is not an idea at all.
#
# The drill runner treats its equivalent as opt-in, because the thing it
# unlocks is an extra table and a check without it is still a check. This one
# refuses. The verdict IS the measurement here, so a grade run that cannot
# reach the grader has nothing left to report, and printing a softer version
# of nothing would be worse than stopping.
#
# ---------------------------------------------------------------------------
# WHAT IT WRITES, WHICH IS ONE PATH
#
#   RECORD.tsv    appended to, one line per prediction, decision and verdict
#
# There is no delete path in here and no second file. The practice tree has no
# git behind it, so a clobbered file does not come back.

set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RECORD="$HERE/RECORD.tsv"

# Resolved from BASH_SOURCE above rather than from a literal path, which is the
# bug scripts/gen-curriculum-map.sh shipped: a hardcoded repo root made the
# script write into the main checkout when it ran from a worktree.
REPO_ROOT="${PROBE_REPO_ROOT:-${DRILL_REPO_ROOT:-}}"
REPO_ROOT="${REPO_ROOT%/}"

die() { printf 'probe: %s\n' "$1" >&2; exit 1; }

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

items() {
  local d
  for d in "$HERE"/*/; do
    [ -f "$d/BRIEF.md" ] || continue
    d="${d%/}"
    printf '%s\n' "${d##*/}"
  done
}

item_dir() {   # item_dir <item>
  local d="$HERE/$1"
  [ -f "$d/BRIEF.md" ] || die "no item called '$1'. Run ./probe list."
  printf '%s\n' "$d"
}

# Reads <item>/GRADE.conf into the five variables the grader call needs. The
# file holds KEY=value lines and nothing else, and it is parsed rather than
# sourced: a delivered file that gets sourced is a delivered file that can run
# anything, and this one has no reason to.
MODULE=""; REFINES=""; ABSTRACT_INIT=""; CONSTANTS=""; TIMEOUT="120"; ORACLE=""
read_conf() {   # read_conf <item-dir>
  local conf="$1/GRADE.conf" line
  [ -f "$conf" ] || die "no GRADE.conf beside the brief in $1"
  MODULE=""; REFINES=""; ABSTRACT_INIT=""; CONSTANTS=""; TIMEOUT="120"; ORACLE=""
  while IFS= read -r line; do
    case "$line" in
      \#*|'')          continue ;;
      MODULE=*)        MODULE="${line#MODULE=}" ;;
      REFINES=*)       REFINES="${line#REFINES=}" ;;
      ABSTRACT_INIT=*) ABSTRACT_INIT="${line#ABSTRACT_INIT=}" ;;
      CONSTANTS=*)     CONSTANTS="${line#CONSTANTS=}" ;;
      TIMEOUT=*)       TIMEOUT="${line#TIMEOUT=}" ;;
      ORACLE=*)        ORACLE="${line#ORACLE=}" ;;
      *) die "GRADE.conf line not understood: $line" ;;
    esac
  done < "$conf"
  [ -n "$MODULE" ] || die "GRADE.conf names no MODULE"
  [ -n "$ORACLE" ] || die "GRADE.conf names no ORACLE"
}

TAB=$(printf '\t')

# grep reads the file directly. There is no pipe here on purpose: under
# pipefail `producer | grep -q` returns 141 when grep exits at its first match
# and the producer takes SIGPIPE, and an `if` reads that 141 as "no match".
# Bead tla-kr9.
recorded() {   # recorded <kind> <item>
  [ -f "$RECORD" ] || return 1
  grep -qF -- "$TAB$1$TAB$2$TAB" "$RECORD"
}

append() {   # append <kind> <item> <text>
  printf '%s\t%s\t%s\t%s\n' "$(now)" "$1" "$2" "$3" >> "$RECORD" \
    || die "cannot append to the record at $RECORD"
}

last_of() {   # last_of <kind> <item>
  [ -f "$RECORD" ] || return 0
  local line rest kind item out=""
  while IFS= read -r line; do
    rest="${line#*"$TAB"}"
    kind="${rest%%"$TAB"*}"
    rest="${rest#*"$TAB"}"
    item="${rest%%"$TAB"*}"
    [ "$kind" = "$1" ] || continue
    [ "$item" = "$2" ] || continue
    out="${rest#*"$TAB"}"
  done < "$RECORD"
  printf '%s\n' "$out"
}

usage() {
  cat <<'USAGE'
Usage: ./probe list
       ./probe start  <item> <your prediction, one line, with a number in it>
       ./probe decide <item> <the decision the brief forced, one line>
       ./probe grade  <item>
       ./probe status

  start   records the prediction, then prints the brief. It needs both.
  decide  records how you settled the pair of requirements that collide.
  grade   runs the refinement grader and records the verdict token.

The grader lives in the repo. Point PROBE_REPO_ROOT or DRILL_REPO_ROOT at a
checkout of tla-puzzles before you grade.
USAGE
}

cmd_list() {
  local it title
  mapfile -t ITEMS < <(items)
  for it in "${ITEMS[@]}"; do
    title=$(head -1 "$HERE/$it/BRIEF.md")
    printf '  %-12s %s\n' "$it" "${title#\# }"
  done
}

cmd_start() {
  local it="$1"; shift
  local dir; dir=$(item_dir "$it")
  read_conf "$dir"

  [ -f "$dir/$ORACLE" ] || die "the requirement module $ORACLE is not in $dir yet.
       Fetch it first:  probe/scripts/fetch-oracles.sh
       Half the item is reading that module, so there is no point starting without it."

  local pred="$*"
  case "$pred" in
    *[0-9]*) ;;
    "") die "start needs your prediction on the same line. One line, and put a number in it.
       Something like:  ./probe start $it 60 percent it refines first try, 50 minutes" ;;
    *) die "that prediction carries no number, so nothing in it can turn out wrong later.
       Give a percentage, a count of attempts, or a number of minutes." ;;
  esac

  append predict "$it" "$pred"
  printf 'recorded your prediction for %s\n\n' "$it"
  cat "$dir/BRIEF.md"
}

cmd_decide() {
  local it="$1"; shift
  local dir; dir=$(item_dir "$it")
  local text="$*"
  [ -n "$text" ] || die "decide needs the decision on the same line.
       Name the two requirements and say which reading you took."
  append decide "$it" "$text"
  printf 'recorded your decision for %s\n' "$it"
}

cmd_grade() {
  local it="$1"
  local dir; dir=$(item_dir "$it")
  read_conf "$dir"

  [ -n "$REPO_ROOT" ] || die "no repo root. The grader is harness/refinement.sh and it lives in
       the repo, which this tree is not under. Set PROBE_REPO_ROOT or
       DRILL_REPO_ROOT to a checkout of tla-puzzles and run this again."
  local inst="$REPO_ROOT/harness/refinement.sh"
  [ -x "$inst" ] || die "no grader at $inst. Check the root you pointed at."

  [ -f "$dir/$MODULE" ] || die "no $MODULE in $dir. That is the file the brief asks for."
  [ -f "$dir/$ORACLE" ] || die "the requirement module $ORACLE is not in $dir.
       Fetch it:  probe/scripts/fetch-oracles.sh"

  if ! recorded decide "$it"; then
    die "no decision recorded for $it yet, so this run would measure the verdict and
       throw away the reasoning that produced it. Record it first:
         ./probe decide $it <which pair, and which reading you took>"
  fi

  local args=(--refines "${REFINES:-Refines}" -t "$TIMEOUT")
  [ -n "$ABSTRACT_INIT" ] && args+=(--abstract-init "$ABSTRACT_INIT")
  [ -n "$CONSTANTS" ] && args+=(--constants "$dir/$CONSTANTS")

  local token rc
  token=$("$inst" "${args[@]}" "$dir/$MODULE"); rc=$?
  append verdict "$it" "$token rc=$rc"
  printf '%s\n' "$token"
  return "$rc"
}

cmd_status() {
  local it p d v
  printf '%-12s %-7s %-7s %s\n' ITEM PREDICT DECIDE VERDICT
  mapfile -t ITEMS < <(items)
  for it in "${ITEMS[@]}"; do
    p=no; d=no
    recorded predict "$it" && p=yes
    recorded decide  "$it" && d=yes
    v=$(last_of verdict "$it")
    [ -n "$v" ] || v='(not graded)'
    printf '%-12s %-7s %-7s %s\n' "$it" "$p" "$d" "$v"
  done
}

case "${1:-}" in
  list)            cmd_list ;;
  start)           shift; [ $# -ge 1 ] || { usage >&2; exit 2; }; cmd_start "$@" ;;
  decide)          shift; [ $# -ge 1 ] || { usage >&2; exit 2; }; cmd_decide "$@" ;;
  grade)           shift; [ $# -eq 1 ] || { usage >&2; exit 2; }; cmd_grade "$1" ;;
  status)          cmd_status ;;
  -h|--help|help)  usage ;;
  '')              usage >&2; exit 2 ;;
  *)               printf 'probe: no command called %s\n' "$1" >&2; usage >&2; exit 2 ;;
esac
