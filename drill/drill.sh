#!/usr/bin/env bash
# drill: serve the next drill in the queue, and keep a record of what got done.
#
# Delivered to ~/tla-practice/drill/drill by scripts/deliver-drill.sh, with no
# extension, so the command reads `./drill`.
#
# Usage:  ./drill [done|shaky|status|list|help] [<family>/<item>]
#         ./drill --check
#         ./drill --style
#         ./drill --hint [<question>]
#
# Exit:   0 on a served drill, a recorded mark, a status or a list, and on an
#           empty queue, which is finishing rather than failing
#         1 on a usage error, a drill name that is not in the tree, a mark with
#           nothing served to attach it to, or a failed write
#         1 on a coaching run refused for a missing dependency, and otherwise
#           whatever the one-shot itself exited with
#
# ---------------------------------------------------------------------------
# WHERE THIS RUNS, WHICH IS WHY IT DEPENDS ON ALMOST NOTHING
#
# ~/tla-practice is not a git repo. There is no harness beside this file, no
# bd, no sibling script, and no guarantee that TLC is on the path. So this
# script sources nothing, discovers no repo root, and confines its reads:
# a serve reads nothing outside the directory it sits in, and works out
# everything it does read from ${BASH_SOURCE[0]} and from the tree under it.
#
# THAT CLAUSE USED TO READ "resolves no repo root" AND IT HAD TO MOVE. One
# read now sits under a repo, and the honest version of the claim is that this
# script never works out where a repo is. It takes one if it is handed one and
# does without otherwise. The section NARROWED A THIRD TIME is the whole of
# that argument.
#
# THE FIRST EXCEPTION, AND IT IS A WRITE RATHER THAN A READ. A serve creates
# the study directory you work the drill in, at $DRILL_STUDY_ROOT/<slug>,
# which defaults to $HOME/Study/tla-drills/<slug>. A serve touches no other
# path outside this directory, it is created and never read, and no serve
# opens a file under it.
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
# NARROWED AGAIN, AND SAID OUT LOUD BECAUSE AN INVARIANT NARROWED TWICE IN
# SILENCE STOPS MEANING ANYTHING
#
# The clause above used to cover the whole script: it read nothing outside the
# directory it sits in, full stop. The three coaching flags, --check, --hint
# and --style, read eight things outside it. So the clause is now about a
# serve, and here are the eight, each one named rather than tucked into the
# code:
#
#   $STUDY_ROOT/check     executed, and its output read back
#   $STUDY_ROOT/style     executed, and its output read back
#   $STUDY_ROOT/STYLE.md  read, and cat whole into the style prompt
#   $STUDY_ROOT/<slug>    the attempt's .tla and .cfg files, read
#   claude                executed, found on PATH rather than at a known path
#   $STUDY_ROOT/.claude/commands/hint.md
#                         read, and cat whole into the hint prompt
#   $STUDY_ROOT/.claude/commands/check.md
#                         read, and cat whole into the check prompt
#   $DRILL_REPO_ROOT/harness/refute.sh
#                         executed, and its table read back. THE ONE ENTRY
#                         THAT DOES NOT RESOLVE UNDER THE STUDY ROOT, which
#                         is what made the third narrowing a different shape
#                         from the first two
#
# WHY THEY ARE WORTH IT, which is one argument rather than seven. The one-shot
# runs as `claude -p --tools ""`, and the empty tool set is what makes the read
# prohibition in the study config structural rather than advisory: the model
# cannot reach the worked answer because it cannot reach anything. The cost of
# that is that it cannot fetch its own material either. So either this script
# fetches the prompt, the attempt and whichever script's numbers the mode
# needs, or the one-shot has nothing to read and the coaching is worthless.
# Measured 2026-10-14 against claude 2.1.300, bead tla-rzvk.
#
# THE STYLE PAIR ADDED NOTHING TO THAT ARGUMENT AND IS NOT ARGUED AGAIN. Bead
# tla-iiow.3 added two reads under the same root the other three already
# resolve from, and the paragraph above covers them as written: a register the
# model cannot open is a register that is not there. What grew is the list,
# because a list that says three while the code reads five is worse than no
# list. The one thing worth saying on top is that STYLE.md is READ rather than
# executed, and it is the only input here that is prose rather than a number.
#
# THE HINT SHEET IS THE SIXTH, AND IT WAS THE ARGUMENT'S OWN COUNTEREXAMPLE.
# Bead tla-1sh7.1. The paragraph above says a register the model cannot open
# is a register that is not there, and the same held for the hint sheet from
# the day --hint landed: the study config tells a hint run to classify the
# question and leaves the worked cases and the tiebreak in
# $STUDY_ROOT/.claude/commands/hint.md, which a one-shot cannot open either.
# So a hint classified on the summary alone, with no example in front of it.
# On 2026-10-16 that laddered a question Frank had marked in his own text as a
# mechanism question, and cost him the hour. The sheet now ships the way the
# register does, and this is a sixth read under the root the other five
# already resolve from rather than a new argument.
#
# THE CHECK PASSES ARE THE SEVENTH, AND THEY WERE THE SAME COUNTEREXAMPLE
# SITTING BESIDE IT. Bead tla-x0he, filed by the worker that closed the one
# above. The study config tells a check run to work the passes in /check in
# the order they are written and to hand back what their last section asks
# for. That file is $STUDY_ROOT/.claude/commands/check.md, one directory over
# from the sheet and just as unreachable, so a check run was following a
# document it had only ever seen summarized.
#
# WHAT IT WOULD HAVE COST, which is the one thing separating the two. The hint
# failure spends a rung and Frank can see it happen. A check that never
# reaches pass 4 reports a clean run over a right count reached by a wrong
# model, which is the failure the pass exists to catch, and it looks like a
# pass from the report alone. I have no measured instance of that, which is
# the problem with it rather than a reason to wait for one.
#
# Six of the eight paths resolve the same way the study directory already did,
# off $DRILL_STUDY_ROOT with the documented default. claude comes off PATH
# because a model binary has no fixed home. The instrument comes off a second
# root entirely. Those two are the ones that could surprise somebody reading
# this, so each is named twice.
#
# THE ONE-SHOT'S CWD IS THE SLUG DIRECTORY AND THAT IS LOAD-BEARING. The study
# config at the study root loads by itself from there, and it is the single
# source of what the one-shot may and may not say. This script restates none of
# it. It assembles material, labels it, and ships it on stdin.
#
# THAT CWD IS RESOLVED FROM THE DRILL AND NOT FROM WHERE YOU STAND, and the two
# are easy to run together. WHICH drill comes from LAST-SERVED, exactly as it
# does for done and shaky, with an explicit <family>/<item> on --check for when
# two terminals have drifted. WHERE the one-shot runs is then
# $STUDY_ROOT/<slug> for whichever drill that was. Your own cwd decides
# nothing, so --check works from the study root where you land.
#
# EVERY ONE OF THE SIX FAILS SOFT, AND THE SERVE PATH IS WHY. Serving is the
# job and coaching is the convenience. No claude on the path, no checker at
# the study root, no style script, no register beside it, no hint sheet under
# .claude/commands, no attempt in the directory: each is one message on stderr
# and exit 1, decided BEFORE anything is executed. So there is
# never a half-run that ships a block from a command that did not run.
#
# A model handed an empty checker block cannot tell it from a clean one, one
# handed measurements with no register cannot tell an absent register from an
# empty one, and one handed a question with no sheet cannot tell that the
# worked case it is missing exists. A check run with no passes is the fourth
# of those and the quietest, since what goes missing is a pass it never knew
# to make. That is the wrong direction to be wrong in four times. A serve
# still works with none of the eight present.
#
# THE EIGHTH IS NOT ON THAT LIST AND IT IS NOT AN OVERSIGHT. The instrument
# refuses nothing, because the block it fills is never empty: it carries the
# table or it carries one line saying there is no table and why. The section
# NARROWED A THIRD TIME argues it.
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
#   LAST-SERVED     the drill served last, so a mark and a coaching run both
#                   take no argument
#   <study>/<slug>  created on a serve, and only ever created
#
# The first two sit beside this file. The third is the exception the section
# above argues, and it is a bare mkdir: no file is written into it, now or
# ever, by this script. There is no delete path anywhere in here.
# ~/tla-practice holds the only copy of the work done in it and has no git
# behind it, so a clobbered file does not come back, and the study tree is in
# the same position.
#
# THE COACHING FLAGS ADD NO FOURTH PATH. --check, --hint and --style read,
# execute and print. None touches PROGRESS.tsv, LAST-SERVED or the study
# directory, and none is a mark: reading your attempt back to you is not
# finishing the drill, and deciding that is yours.
#
# LAST-SERVED is the one file that gets replaced rather than appended to, and
# that is sound because it holds no work. It is this script's own cursor, it
# is rewritten on every serve, and the record of what happened is in
# PROGRESS.tsv. A pointer can go stale if you work two terminals, which is why
# both marks, --check and --style all take an explicit <family>/<item>.
#
# --hint does not, and that is the one asymmetry here. The rest of its line is
# the question, so a drill name typed there is a question about that text. The
# override exists for a drifted pointer, and ./drill --check names the drill
# just as well while the hint is one command behind it.
#
# ---------------------------------------------------------------------------
# --style IS A THIRD MODE AND NOT A SECOND HALF OF --check
#
# Bead tla-iiow.3. --check asks whether the model does what the prompt asked.
# --style asks how the TLA+ reads against how published TLA+ reads. Two
# different questions, and folding the second into the first would make every
# check pay for it, so a style run does not execute the checker and a check
# run does not execute the style script. One line to change here if the two
# are ever wanted together.
#
# IT CATS THE REGISTER INTO THE PROMPT. $STUDY_ROOT/STYLE.md is where the
# survey counts and Lamport's page citations live, and a model under
# `--tools ""` cannot open it however plainly it is told to. So the register
# ships with the measurements, and the style prompt is the largest of the
# three by a wide margin. That is the cost of the separation and it is paid
# only by the runs that ask for it.
#
# THIS USED TO READ "the one thing it does that neither other mode has an
# equivalent of", and bead tla-1sh7.1 made that false rather than merely
# dated: --hint cats its own prose file now, for the same reason and in the
# same shape. tla-x0he did the same for --check, so every mode cats one and
# the clause is about which file rather than about which modes. The two
# sections below are the rest of the set.
#
# THE STYLE SCRIPT'S EXIT CODE IS NOT A VERDICT AND NOT THIS SCRIPT'S. Bead
# tla-iiow.2 locks 0 for measured-something and 3 for could-not-run, with no 1
# at all, because a style pass that can fail becomes a gate on the work. It
# goes on the block's label where the model can read it, exactly as the
# checker's does, and this script still exits with the one-shot's status.
#
# ---------------------------------------------------------------------------
# --hint CATS ITS SHEET THE WAY --style CATS THE REGISTER
#
# Bead tla-1sh7.1, and it is the register's argument with one file swapped.
# $STUDY_ROOT/.claude/commands/hint.md is where the ladder, the two worked
# cases and the tiebreak live. Claude Code reads a project command from there
# when somebody TYPES it, and nobody types anything here: the prompt arrives
# on stdin and the run has no tools, so the sheet is as unreachable as the
# register was. The study config does say to classify the question, in four
# sentences with no example under them, which is enough to sound certain with
# and not enough to classify with.
#
# WHAT IT COST, because this is the one place in the file where the failure is
# measured rather than argued. 2026-10-16. Frank asked for "a high level
# description of how this is done in general, not this specific application",
# and said in the same sentence that he was fuzzy on the notation rather than
# on the problem. He got a rung and the sentence "Explaining the general
# syntax would do the item's work for you." That is the tiebreak firing on a
# question the sheet's own worked case answers flat.
#
# SO THE GATE IS THE REGISTER'S GATE. A hint over a study root with no sheet
# in it refuses before the checker runs, because with no tools the model
# cannot tell an absent sheet from an empty one and would classify on the
# summary and sound exactly as sure. --check and --style read no sheet, so
# neither is gated on one and a root with no sheet still serves both.
#
# ---------------------------------------------------------------------------
# --check CATS ITS PASSES, AND EACH MODE SHIPS ITS OWN PROSE AND NOBODY
# ELSE'S
#
# Bead tla-x0he. Three modes, three prose files, three gates, and the thing
# worth holding on to is that none of them is the others'.
#
# This section used to argue the opposite under the heading HINT-ONLY IN THE
# PROMPT TOO. It said a check prompt carries no sheet for the reason a style
# prompt carries no checker block, and it was right about the sheet and wrong
# about what followed. The ladder is what rations a hint, so the ladder stays
# out of a check. That is an argument for keeping hint.md out of a check
# prompt, and I read it at the time as an argument for shipping a check
# nothing at all.
#
# WHAT EACH MODE SHIPS AND WHAT IT IS GATED ON:
#
#   --check   check.md, the passes and the hand-back list
#   --hint    hint.md, the ladder and the worked cases
#   --style   STYLE.md, the register
#
# No mode ships another's, and no mode is gated on another's. A root with no
# register styles nothing and checks and hints fine. A root with no sheet
# hints nothing and checks and styles fine. A root with no passes checks
# nothing and hints and styles fine.
#
# ---------------------------------------------------------------------------
# NARROWED A THIRD TIME, AND THIS ONE MOVES THE ROOT RATHER THAN THE LIST
#
# The two narrowings above both grew the list under one root this script
# already resolved. The eighth read is under a SECOND root, so the clause at
# the top of the file had to change and not only the enumeration under it.
#
# WHAT THE EIGHTH READ BUYS. A check run now also runs the learner's own
# obligations against the wrong machines the drill item ships, and prints one
# TLC exit code per pair. An exit code terminates where a reading does not:
# each machine is either refuted by one of his obligations or it is not, and
# nine runs of a reading produce nine findings whether or not anything is
# wrong. One item cost a full day that way, on a ten-minute budget.
#
# WHY A SECOND ROOT IS UNAVOIDABLE. Those machines are withheld from every
# delivery route on purpose, so they are in the repo and nowhere else, and the
# delivered copy of this script does not sit under the repo. There is nothing
# to walk up to. Discovering the root was the obvious route and it is not a
# route at all, which is worth writing down so nobody spends an afternoon
# finding that out again.
#
# SO IT ARRIVES IN DRILL_REPO_ROOT OR IT DOES NOT ARRIVE, and unset is the
# default. ./drill keeps working on a box holding nothing but the practice
# tree, and the richer report is opt-in on the one box that has the repo.
#
# IT IS NOT A GATE, WHICH IS THE ONE PLACE THIS DEPARTS FROM THE SEVEN ABOVE.
# Every other dependency refuses the run, and the argument for that is always
# the same: a model with no tools cannot tell an empty block from a clean one.
# It does not reach here. This block is never empty. It carries the table, or
# it carries one line saying there is no table and why, which is the sentence
# a refusal would have printed anyway. Refusing the whole check over an opt-in
# extra would trade a working check for no check.
#
# FOUR REASONS AND ONE OUTCOME. No repo named. A repo named with no instrument
# in it. No tlc on the path, which would otherwise fill every cell with the
# exit code of a command that was not found. And an item shipping no machine
# this method can bind, which is a fact about the item rather than about the
# attempt. No count of those items is written down here, because the
# instrument's own exit code says so per item and a count in a comment goes
# stale on the next item that gains a machine.
#
# THE INSTRUMENT'S OWN REFUSAL TEXT IS NEVER RELAYED, and that is the one rule
# here that is about the leak rather than about the shape. Its refusals name
# the author-side files it went looking for, and this script ships its prompt
# to a model. So a nonzero exit becomes one sentence in this script's words,
# and the instrument's own wording reaches nobody.

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

# The repo root, which is the second root and the one with NO default. See the
# section NARROWED A THIRD TIME for why there cannot be one: the machines a
# check run wants are in the repo, and the delivered copy of this script does
# not sit under the repo, so there is nothing to walk up to and nothing to
# fall back on. Empty means the table is not produced, and a check run says so
# in one line and otherwise runs exactly as it did.
#
# IT IS NOT CANONICALIZED. A relative value works, since nothing here changes
# directory before the instrument is executed, and the banner then shows the
# reader what he typed rather than a resolution of it. A value naming nothing
# runnable is reported rather than resolved, which is the next function down.
REPO_ROOT="${DRILL_REPO_ROOT:-}"
REPO_ROOT="${REPO_ROOT%/}"

TAB=$'\t'

usage() {
  cat <<'USAGE'
Usage: ./drill [done|shaky|status|list|help] [<family>/<item>]
       ./drill --check [<family>/<item>]
       ./drill --style [<family>/<item>]
       ./drill --hint [<question>]

  ./drill            serve the next drill: where to work, then its prompt
  ./drill done       mark the drill you were served done, then serve the next
  ./drill shaky      mark it shaky, then serve the next
  ./drill status     how many are done, shaky and untried
  ./drill list       the queue, in the order it gets served
  ./drill --check    run the checker over your attempt, then read it back
  ./drill --style    measure your attempt against how published TLA+ reads
  ./drill --hint     one rung of a hint about your attempt
  ./drill help       this text

A mark takes no argument, because the point is one command per drill. The
runner remembers what it served last. Name a drill to mark something else,
which is what you want when two terminals have drifted apart.

done retires a drill. shaky puts it back after everything untried, so a drill
you half got comes round again.

A serve makes the directory to work the drill in, under ~/Study/tla-drills.
Set DRILL_STUDY_ROOT to put it somewhere else. A directory already there is
left exactly as it is, and a serve that cannot make one still serves.

--check, --style and --hint coach the drill that was served last, the same way
a mark does, and --check and --style take a name when two terminals have
drifted apart. Every run prints the drill and the directory it read, so a
stale pointer shows up before you read the answer rather than after. It does
not matter where you are standing.

--check asks whether your model does what the prompt asked. --style asks how
your TLA+ reads next to published TLA+, which is a different question, so it
runs on its own and a check never pays for it. It has no pass and no fail.

--hint takes no drill name, because the rest of the line is the question:
./drill --hint why does this one keep failing. The quotes are optional.

All three need claude on the path. --check needs the checker at the study
root, --style needs the style script and the register beside it, --hint needs
the checker and its own sheet under .claude/commands, and each one refuses
rather than half-running when what it needs is missing. Serving never does.

--check will also run your obligations against the wrong machines the drill
ships, one TLC exit code per pair, when DRILL_REPO_ROOT names a checkout of
the repo. It is off when the variable is unset, which is the default and the
ordinary case: the machines are not in the practice tree and there is nothing
to find them by. A run without it says in one line that the table was not
produced, and is otherwise the run it always was. It is the slowest thing
here when it is on.
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
# Coaching: --check, --hint and --style.
#
# This assembles and ships. What the three modes MEAN is the study config's,
# and the first line of the prompt is the whole of the seam: MODE: check,
# MODE: hint or MODE: style, plus a QUESTION block when a hint was steered.
# Nothing here decides a rung or a register.
# ---------------------------------------------------------------------------

COACH_ITEM=""
COACH_DIR=""
COACH_HOW=""
COACH_FILES=()
COACH_MODULES=0
QUESTION=""
CHECK_OUT=""
CHECK_RC=0
STYLE_OUT=""
STYLE_RC=0
REFUTE_OUT=""
# THE THIRD RC IS NOT ON A BLOCK LABEL AND THE OTHER TWO ARE, which is worth
# a line because the asymmetry looks like an omission. A checker's exit code
# is a fact its output does not carry, so it goes where the model can read it.
# The instrument's exit code is carried by the table: every cell of it is an
# exit code, and the one from the instrument itself is 0 or there is no table.
# So this is read inside run_refuter and nowhere else.
REFUTE_RC=0
REFUTE_WHY=""
PROMPT_TEXT=""

# resolve_coach <flag> <arg>: which drill, and which directory holds it.
#
# The drill comes from resolve_target, so --check and --hint answer the
# question exactly where done and shaky answer it, in one function with one
# set of messages. A second phrasing for the same condition is a fork that
# drifts.
#
# THE DIRECTORY IS RESOLVED FROM THE DRILL, NEVER FROM WHERE YOU STAND. It is
# $STUDY_ROOT/<slug> whatever your cwd is, because that is the directory the
# one-shot has to run in for the study config above it to load. Resolution and
# cwd were always independent and they stay that way.
resolve_coach() {
  local flag="$1" arg="${2:-}"
  COACH_ITEM=""
  COACH_DIR=""
  COACH_HOW=""

  resolve_target "$flag" "$arg" || return 1
  COACH_ITEM="$TARGET"
  if [ -n "$arg" ]; then
    COACH_HOW="the name you gave"
  else
    COACH_HOW="LAST-SERVED, so it is the drill that was served last"
  fi

  if [ -z "$STUDY_ROOT" ]; then
    echo "drill: DRILL_STUDY_ROOT is unset and so is HOME, so there is no root to look" >&2
    echo "drill: for ${COACH_ITEM} under. Set DRILL_STUDY_ROOT and try again." >&2
    return 1
  fi
  COACH_DIR="$STUDY_ROOT/${COACH_ITEM##*/}"
  if [ ! -d "$COACH_DIR" ]; then
    echo "drill: there is no directory at $COACH_DIR, so the attempt at ${COACH_ITEM}" >&2
    echo "drill: has nowhere to be. Run ./drill to have one made." >&2
    return 1
  fi
  return 0
}

# collect_attempt <dir>: the attempt's own files, in one C-locale order so a
# module and its config read next to each other.
#
# A TLC TRACE DUMP IS NOT PART OF THE ATTEMPT. *_TTrace_*.tla is TLC's output
# rather than anything you wrote, and shipping one spends the prompt on a file
# the drill is not about. The study config also excludes a name ending `.old`,
# and there is no arm for that here because `Pickers.tla.old` matches neither
# glob to begin with.
#
# PRESENCE IS ALL A GLOB CAN JUDGE. The study config calls a module header with
# nothing under it not an attempt, which takes a reader rather than a glob. So
# that half of the gate stays where it is and this half is only about whether
# there is a module here at all.
collect_attempt() {
  local dir="$1" p base line
  local -a raw=()
  COACH_FILES=()
  COACH_MODULES=0
  shopt -s nullglob
  for p in "$dir"/*.tla "$dir"/*.cfg; do
    [ -f "$p" ] || continue
    base="${p##*/}"
    case "$base" in
      *_TTrace_*) continue ;;
    esac
    raw+=("$base")
    case "$base" in
      *.tla) COACH_MODULES=$((COACH_MODULES + 1)) ;;
    esac
  done
  shopt -u nullglob
  [ "${#raw[@]}" -gt 0 ] || return 0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    COACH_FILES+=("$line")
  done < <(printf '%s\n' "${raw[@]}" | LC_ALL=C sort)
}

# run_checker <dir>: the checker, with its two streams joined.
#
# JOINED ON PURPOSE. A checker that failed on stderr and printed nothing on
# stdout would otherwise ship an empty block, and a model with no tools cannot
# tell an empty block from a clean silent run. The exit code goes on the label
# beside it and neither is derived from the other, which is the rule the
# checker's own header argues at length.
#
# DRILL_PROMPT_ROOT is named rather than left to the checker's default, because
# this script reads the prompt out of $HERE and the two have to be reading the
# same file. A checker resolving some other tree would quote claims the model
# is not being shown.
run_checker() {
  CHECK_OUT=""
  CHECK_RC=0
  CHECK_OUT="$(DRILL_PROMPT_ROOT="$HERE" "$STUDY_ROOT/check" "$1" 2>&1)"
  CHECK_RC=$?
}

# run_styler <dir>: the style script, joined and labeled exactly as the
# checker is, and for the same two reasons. An empty block is unreadable to a
# model with no tools, and the exit code is a fact the output does not carry.
#
# DRILL_PROMPT_ROOT is named here too. The style axes are read against the
# item the attempt is for, and one item is excluded from one axis by name, so
# a style script resolving some other prompt tree would exclude the wrong
# thing or nothing at all.
run_styler() {
  STYLE_OUT=""
  STYLE_RC=0
  STYLE_OUT="$(DRILL_PROMPT_ROOT="$HERE" "$STUDY_ROOT/style" "$1" 2>&1)"
  STYLE_RC=$?
}

# run_refuter <dir> <item>: the learner's obligations against the machines the
# item ships, one TLC exit code per pair.
#
# TWO OUTCOMES AND EXACTLY ONE OF THEM IS SET WHEN THIS RETURNS. REFUTE_OUT
# holds a table and REFUTE_WHY is empty, or REFUTE_WHY holds one line and
# REFUTE_OUT is empty. The caller tests REFUTE_WHY and never has to decide
# which of the two to believe.
#
# IT RETURNS 0 ON EVERY PATH, which is the decision this whole feature turns
# on. Nothing here refuses a check run. See the header for the argument: the
# other seven reads are gated because a model with no tools cannot tell an
# empty block from a clean one, and that cannot happen to a block carrying a
# sentence about its own absence.
#
# THE TABLE SHIPS ONLY ON A ZERO EXIT. Every nonzero exit is a reason rather
# than a measurement, and the instrument's own wording for it names the
# author-side files it went looking for. So nothing it printed is relayed on
# those paths and the sentence is this script's.
run_refuter() {
  local dir="$1" item="$2" inst
  REFUTE_OUT=""
  REFUTE_RC=0
  REFUTE_WHY=""

  if [ -z "$REPO_ROOT" ]; then
    REFUTE_WHY="not produced: DRILL_REPO_ROOT names no repo, and the machines this would run live in the repo rather than in the delivered tree."
    return 0
  fi

  inst="$REPO_ROOT/harness/refute.sh"
  if [ ! -x "$inst" ]; then
    REFUTE_WHY="not produced: nothing runnable at ${inst}, so the repo that was named holds no instrument."
    return 0
  fi

  # Checked here rather than left to fail per pair. With no tlc the probe
  # exits 127 every time and the table comes back as a column of 127s, which
  # reads like a measurement and is the exit code of a command that was never
  # found. One missing dependency must not arrive dressed as data.
  if ! command -v tlc >/dev/null 2>&1; then
    REFUTE_WHY="not produced: no tlc on the path, and every cell of the table is a TLC exit code."
    return 0
  fi

  REFUTE_OUT="$("$inst" --attempt "$dir" --item "$item" 2>&1)"
  REFUTE_RC=$?

  if [ "$REFUTE_RC" -eq 0 ]; then
    return 0
  fi

  if [ "$REFUTE_RC" -eq 3 ]; then
    REFUTE_OUT=""
    # A 3 HAS TWO CAUSES AND THEY POINT OPPOSITE WAYS. The item ships no
    # machine this method can bind, which is nothing to do with him, or his
    # own config names no obligation, which is his to fix and worth saying as
    # his. Asking the instrument to list the item's machines settles it, reads
    # the item alone and runs no TLC, so the message can be the right one
    # rather than both.
    if "$inst" --list-machines --item "$item" >/dev/null 2>&1; then
      REFUTE_WHY="not produced: your config names no obligation, so there was nothing to run against this item's machines."
    else
      REFUTE_WHY="not produced: ${item} ships no machine this method can run, which is a fact about the item rather than about your attempt."
    fi
    return 0
  fi

  REFUTE_OUT=""
  REFUTE_WHY="not produced: the instrument exited ${REFUTE_RC} and printed no table."
  return 0
}

# build_prompt <mode>: everything the one-shot gets, on stdout.
#
# MODE is the first line and the only instruction in here. Everything after it
# is labeled material: the prompt as it was served, what the checker or the
# style script said, and the files of the attempt. No prohibition is restated,
# because the study config holds all of them and a second copy drifts from the
# day it is written.
#
# THE MIDDLE BLOCK IS THE ONLY THING THAT VARIES BY MODE, and every mode now
# has one. A style run gets the register, whole, and then the measurements. A
# hint run gets its sheet, and a check run gets its passes, each whole and
# each before the checker's numbers. The prose comes FIRST in all three,
# because it is what the material after it is read against, and a model handed
# the material before the frame reads the material twice.
#
# THIS USED TO READ "only --check gets one block", which bead tla-x0he made
# false. The sentence was true the day --check was the mode with nothing of
# its own to ship, and it stopped being true the day that turned out to be the
# bug rather than the design.
build_prompt() {
  local mode="$1" base
  printf 'MODE: %s\n' "$mode"
  printf 'DRILL: %s\n' "$COACH_ITEM"
  printf 'DIRECTORY: %s\n' "$COACH_DIR"
  if [ -n "$QUESTION" ]; then
    printf '\nQUESTION:\n%s\n' "$QUESTION"
  fi
  printf '\n== PROMPT.md ==\n'
  cat "$HERE/$COACH_ITEM/PROMPT.md"
  if [ "$mode" = "style" ]; then
    printf '\n== STYLE.md, the register, verbatim ==\n'
    cat "$STUDY_ROOT/STYLE.md"
    printf '\n== STYLE, exit %s, output verbatim ==\n' "$STYLE_RC"
    printf '%s\n' "$STYLE_OUT"
  else
    # The sheet goes BEFORE the checker's numbers, for the reason the register
    # goes before the measurements. It is what the question is classified
    # against, and the classification happens before the first word.
    if [ "$mode" = "hint" ]; then
      printf '\n== hint.md, the ladder and the worked cases, verbatim ==\n'
      cat "$STUDY_ROOT/.claude/commands/hint.md"
    fi
    # The passes go in the same slot and for the same reason. They are the
    # order the report is worked in, so they are what the checker's numbers
    # and the attempt below them are read against.
    if [ "$mode" = "check" ]; then
      printf '\n== check.md, the passes and what to hand back, verbatim ==\n'
      cat "$STUDY_ROOT/.claude/commands/check.md"
    fi
    printf '\n== CHECKER, exit %s, output verbatim ==\n' "$CHECK_RC"
    printf '%s\n' "$CHECK_OUT"
    # The table goes AFTER the checker's numbers rather than before them,
    # because the passes work in that order: the count comes first and the
    # obligations are read against it. It is check-only for the reason the
    # passes are, which is that it is what a check hands back and a hint
    # hands back one rung.
    #
    # THE BLOCK IS ALWAYS HERE AND IT IS NEVER EMPTY. Either the table or one
    # line saying there is no table and why. A block that came and went with
    # the box's configuration would leave the model unable to tell a silent
    # run from a run that never happened, which is the whole argument the
    # other seven reads are gated on.
    #
    # THE TEST IS ON THE RESULT RATHER THAN ON THE MODE, and that is not a
    # shortcut. Exactly one of the two is set whenever the instrument was
    # asked, and neither is set when it was not, so this reads "a refutation
    # was attempted" without a second opinion about which modes attempt one.
    # The call site in coach() decides that, once, and two places that have
    # to agree about it is one place too many.
    if [ -n "$REFUTE_WHY" ] || [ -n "$REFUTE_OUT" ]; then
      printf '\n== REFUTATION, the machines this item ships, against your obligations ==\n'
      if [ -n "$REFUTE_WHY" ]; then
        printf '%s\n' "$REFUTE_WHY"
      else
        printf '%s\n' "$REFUTE_OUT"
      fi
    fi
  fi
  for base in "${COACH_FILES[@]}"; do
    printf '\n== ATTEMPT %s ==\n' "$base"
    cat "$COACH_DIR/$base"
  done
}

# coach <mode>: the whole of --check, --hint and --style.
#
# EVERY GATE IS DECIDED BEFORE ANYTHING IS EXECUTED, and the order is the
# cheapest refusal first: a box with no claude on it never pays for a TLC run
# to find that out.
coach() {
  local mode="$1" arg="${2:-}" flag="--$1"

  resolve_coach "$flag" "$arg" || return 1

  collect_attempt "$COACH_DIR"
  if [ "$COACH_MODULES" -eq 0 ]; then
    echo "drill: no attempt at $COACH_DIR: there is no .tla file there to read." >&2
    echo "drill: write the module first. Feedback with no attempt in front of it is the" >&2
    echo "drill: lookup these drills are written to replace." >&2
    return 1
  fi

  if [ -z "$STUDY_ROOT" ]; then
    echo "drill: DRILL_STUDY_ROOT is unset and so is HOME, so there is no study root to" >&2
    echo "drill: find the checker in. Set DRILL_STUDY_ROOT and try again." >&2
    return 1
  fi

  # WHICH DEPENDENCY EACH MODE NEEDS, and no two sets are the same. A style
  # run never executes the checker, so a study root with no checker in it
  # styles an attempt perfectly well. A check run needs the checker and its
  # passes, and reads neither the register nor the hint's sheet. A hint run
  # needs the checker and the sheet, and reads neither the passes nor the
  # style pair. Gating on all of them would refuse a run over a tree that
  # holds everything that run needs.
  if [ "$mode" = "style" ]; then
    if [ ! -x "$STUDY_ROOT/style" ]; then
      echo "drill: no runnable style script at $STUDY_ROOT/style, so there is nothing" >&2
      echo "drill: measured to send and I would rather send nothing than a blank." >&2
      echo "drill: Deliver the study tree, then try again." >&2
      return 1
    fi
    # The register is the frame the measurements are read against, and the
    # one-shot runs with no tools, so it cannot open the file itself however
    # plainly it is told to. Measurements with no register would be read
    # against nothing and sound exactly as certain.
    if [ ! -r "$STUDY_ROOT/STYLE.md" ]; then
      echo "drill: no style register at $STUDY_ROOT/STYLE.md, and the one-shot runs with" >&2
      echo "drill: no tools, so it cannot open one itself. Measurements with nothing to" >&2
      echo "drill: read them against are worse than none. Deliver the study tree first." >&2
      return 1
    fi
  elif [ ! -x "$STUDY_ROOT/check" ]; then
    echo "drill: no runnable checker at $STUDY_ROOT/check, so there is nothing objective" >&2
    echo "drill: to send and I would rather send nothing than a blank. Deliver the study" >&2
    echo "drill: tree, then try again." >&2
    return 1
  fi

  # The hint's sheet, gated for the register's reason and not a new one. It
  # carries the ladder, the two worked cases and the tiebreak, the one-shot
  # cannot open it, and a hint handed the study config's four-sentence summary
  # alone classifies on no example and sounds exactly as certain. --check and
  # --style read no sheet, so a root with no sheet in it still serves both.
  if [ "$mode" = "hint" ] && [ ! -r "$STUDY_ROOT/.claude/commands/hint.md" ]; then
    echo "drill: no hint sheet at $STUDY_ROOT/.claude/commands/hint.md, and the" >&2
    echo "drill: one-shot runs with no tools, so it cannot open one itself. A hint with" >&2
    echo "drill: no worked case in front of it ladders a question that wanted an answer." >&2
    echo "drill: Deliver the study tree first." >&2
    return 1
  fi

  # The check's passes, gated for the sheet's reason and not a new one. The
  # study config sends a check run to work the passes in order and to hand
  # back what their last section asks for, and it reproduces neither. So a
  # check over a root with no check.md in it works from a summary of a
  # document it was told to follow.
  #
  # WHY REFUSE RATHER THAN SHIP THE SUMMARY. A hint that classifies wrongly
  # spends a rung. A check that never reaches pass 4 hands back a clean
  # verdict over a right count reached by a wrong model, which is the one
  # failure the mode exists to catch, and it hands it back looking green.
  # --hint and --style read no passes, so a root with none still serves both.
  if [ "$mode" = "check" ] && [ ! -r "$STUDY_ROOT/.claude/commands/check.md" ]; then
    echo "drill: no check passes at $STUDY_ROOT/.claude/commands/check.md, and the" >&2
    echo "drill: one-shot runs with no tools, so it cannot open them itself. A check" >&2
    echo "drill: working from a summary of its own passes reports a clean run it never" >&2
    echo "drill: made. Deliver the study tree first." >&2
    return 1
  fi

  if ! command -v claude >/dev/null 2>&1; then
    echo "drill: no claude on the path, so there is no one-shot to run." >&2
    echo "drill: ./drill, ./drill done and ./drill shaky all work without it." >&2
    return 1
  fi

  if [ "$mode" = "style" ]; then
    run_styler "$COACH_DIR"
  else
    run_checker "$COACH_DIR"
  fi

  # AFTER the checker and only for a check. It is the most expensive thing
  # here by a wide margin, since it is one TLC run per obligation per machine,
  # so a mode that does not ship the table does not pay for it either.
  if [ "$mode" = "check" ]; then
    run_refuter "$COACH_DIR" "$COACH_ITEM"
  fi

  printf -- '-- %s: %s --\n' "$mode" "$COACH_ITEM"
  printf 'chosen from %s\n' "$COACH_HOW"
  printf 'reading in:   %s\n' "$COACH_DIR"
  printf 'attempt:      %s\n' "${COACH_FILES[*]}"
  if [ "$mode" = "style" ]; then
    printf 'style:        exit %s\n' "$STYLE_RC"
    # The register is named because it is the one input a reader cannot
    # otherwise account for: it comes from a third file and it is most of the
    # prompt by volume.
    printf 'register:     %s\n' "$STUDY_ROOT/STYLE.md"
  else
    printf 'checker:      exit %s\n' "$CHECK_RC"
    # Named for the register's reason: it is prose from a file this mode ships
    # and the others do not, so a reader cannot otherwise account for it.
    if [ "$mode" = "hint" ]; then
      printf 'sheet:        %s\n' "$STUDY_ROOT/.claude/commands/hint.md"
    fi
    if [ "$mode" = "check" ]; then
      printf 'passes:       %s\n' "$STUDY_ROOT/.claude/commands/check.md"
      # ALWAYS A LINE, EVEN WHEN THERE IS NOTHING TO SAY. The reader is the
      # one person who can fix an unset variable or a repo path that moved,
      # and a silence here reads as a run that did everything it could.
      if [ -n "$REFUTE_WHY" ]; then
        printf 'refutation:   %s\n' "$REFUTE_WHY"
      else
        printf 'refutation:   %s\n' "$REPO_ROOT/harness/refute.sh"
      fi
    fi
  fi
  echo

  PROMPT_TEXT="$(build_prompt "$mode")"
  # The prompt goes on STDIN and never on argv. --tools is variadic, so a
  # positional prompt after `--tools ""` is read as a tool name and the run
  # dies asking for input it was handed. Measured 2026-10-14, bead tla-rzvk.
  ( cd -- "$COACH_DIR" && claude -p --tools "" ) <<<"$PROMPT_TEXT"
}

# ---------------------------------------------------------------------------
# WHICH DRILL, FOR ALL FIVE VERBS THAT NEED ONE
#
# done, shaky, --check, --hint and --style all answer the same question, so
# they ask it in the same place. The drill comes from the argument if there is
# one, and from the pointer otherwise. Either way it has to be a drill that is
# in the tree: a name that is not gets refused rather than written, so the
# record never holds an entry for something that does not exist.
#
# THE COACHING FLAGS USED TO RESOLVE OFF THE DIRECTORY YOU WERE STANDING IN,
# and that was wrong. The argument for it was borrowed from why a mark takes an
# explicit name, and it does not carry: a mark WRITES the record, so a wrong
# drill corrupts the log, while a check only READS, so a wrong drill costs ten
# seconds and the printed name shows it. Standing-in also forced a cd into the
# slug directory, when the study ROOT is where you land.
#
# WHAT VARIES BY VERB IS TWO WORDS OF THE MESSAGE, and both come off the verb
# rather than off a second parameter. `noun` is what you were about to do.
# `named` is the command form that takes an explicit drill, and an empty one
# drops the suggestion entirely, which is what --hint needs: the rest of its
# line is the question, so there is no room left for a drill name and offering
# one would be advice that does not work.
# ---------------------------------------------------------------------------

TARGET=""

resolve_target() {
  local verb="$1"
  local arg="${2:-}"
  local item="" noun="mark" named="$verb"
  case "$verb" in
    --check) noun="check" ;;
    --style) noun="style" ;;
    --hint)
      noun="hint"
      named=""
      ;;
  esac
  local tail=""
  [ -z "$named" ] || tail=", or name it: ./drill $named <family>/<item>"
  TARGET=""
  if [ -n "$arg" ]; then
    item="${arg%/}"
    item="${item#./}"
  elif [ -f "$POINTER" ]; then
    IFS= read -r item <"$POINTER" || item=""
    if [ -z "$item" ]; then
      echo "drill: the pointer at $POINTER is empty, so there is nothing to ${noun}." >&2
      echo "drill: run ./drill to be served one${tail}" >&2
      return 1
    fi
  else
    echo "drill: nothing has been served yet, so there is nothing to ${noun}." >&2
    echo "drill: run ./drill first${tail}" >&2
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
  --check) VERB="check" ;;
  --style) VERB="style" ;;
  --hint) VERB="hint" ;;
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

# --hint takes THE REST OF THE LINE as the question, joined by single spaces.
# A question typed at a shell prompt is not reliably quoted, and refusing an
# unquoted one would be refusing the ordinary case to protect against a
# quoting hazard that is not there: the question goes to the one-shot on
# stdin, where it is text rather than a command line.
if [ "$VERB" = "hint" ]; then
  QUESTION="$*"
  set --
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
  check | hint | style)
    # The one-shot's own exit status is this script's, because a coaching run
    # that reached the model has nothing of its own left to report. A gate
    # refusal returns 1 from coach and exits 1 here.
    coach "$VERB" "$ARG"
    COACH_RC=$?
    exit "$COACH_RC"
    ;;
esac
