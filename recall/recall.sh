#!/usr/bin/env bash
# recall.sh: grade one recall rep, and explain a wrong answer with the two
# values side by side, what that answer says, and what the construct is
# (beads tla-wekw and tla-1sh7.6, epic tla-1sh7).
#
# A rep states a need in English and asks for the notation. This script takes
# the rep id and what was typed, drops the answer into a scaffold module beside
# the rep's constant environment, and asserts value equality against the
# canonical answer. Correctness is ONE EXIT CODE, TLC's own.
#
# Usage:
#   recall/recall.sh --session [OPTIONS]             work rep after rep
#   recall/recall.sh [OPTIONS] <rep-id> <answer>     grade one rep
#
# OPTIONS, and every one of them goes BEFORE the rep id. Once the rep id is in
# hand the next argument is the answer, whatever it starts with.
#   --session         serve reps one at a time: the prompt, then your answer
#                     read from stdin, then the grade, then the next rep
#   --count N         stop a session after N reps. Default: until the table
#                     runs out, or until you do
#   --seed N          seed a session's walk, so one can be run again
#   --reps FILE       rep table (default: recall/REPS.tsv beside this script)
#   --env-dir DIR     constant environments (default: recall/env)
#   --sheet FILE      construct sheet (default: drill/SHEET.md)
#   --misses FILE     miss table (default: recall/MISSES.tsv beside this file)
#   --full            print each value whole, however long it runs
#   -q, --quiet       the status line only, no prompt and no value block
#   --no-prompt       do not echo the rep's prompt line. This is what a
#                     session hands its own child, having printed it already
#   -h, --help        this text
#
# AN ANSWER BEGINNING WITH A DASH NEEDS NOTHING IN FRONT OF IT. Negative
# integers are ordinary answers at this rung -- R012 is a thermometer reading
# below zero and R075 is a negative interval -- so `recall.sh R012 -4` grades.
# The `--` escape still works wherever it appears, and it was the only route
# until 2026-10-16, which cost a learner typing the right answer a usage dump.
#
# ---------------------------------------------------------------------------
# THE SESSION, AND THE DEFECT IT CLOSES (bead tla-1sh7.11)
#
# Until 2026-10-17 the single-rep invocation above was the ONLY one, and it
# takes a rep id. So finding out what a rep asked meant opening REPS.tsv,
# where field 5 sits on the same tab-delimited line as field 6, the canonical
# answer. READING THE QUESTION HANDED OVER THE ANSWER, which is exactly the
# lookup this rung exists to replace: exposure without a retrieval attempt
# buys very little durability, and drill/study/CLAUDE.md cites the same
# finding where it forbids a checking agent to name a missing construct.
#
# `--session` prints the prompt and nothing else, reads the answer from
# stdin, grades it, prints the block below, and serves the next rep. No id is
# ever typed.
#
# IT RE-ENTERS THIS SCRIPT ONCE PER REP RATHER THAN GRADING INLINE. A session
# runs `recall.sh --no-prompt -- <rep> <answer>`, so what it grades is the
# single-rep invocation itself and there is no second grading path to drift
# from the first. The cost is one process per rep against a 320 ms TLC run,
# which is nothing. The gain is that every row of
# harness/test-recall-runner.sh parts 1 to 13 covers what a session grades.
#
# WHICH REP COMES NEXT: NEAR THE LAST ONE, NEVER THE SAME CONSTRUCT.
#
# Uniform random is the cheap answer and it throws away what the rep table was
# built for. tla-1sh7.2 wrote two to six differently-phrased reps per
# construct so the FACT is retrieved rather than the sentence, and
# interleaving is stronger when consecutive items are similar enough to be
# confusable. The confusions this rung exists for are within-family ones:
# recall/MISSES.tsv's 30 rows are mostly a function written where a function
# SET was asked for, which is K047 against K050.
#
# Two reps of ONE construct back to back is the other failure. That is lag 0,
# where the answer was typed a second ago and the second rep is recognition
# rather than recall.
#
# So the walk draws the next rep from a construct WITHIN TWO POSITIONS of the
# one just served and never from that construct itself. The construct's
# remaining reps stay in the pool and come round again after an intervening
# rep or two, which is the spacing a blocked order has none of.
#
# POSITION MEANS FILE ORDER, AND THAT IS A MEASUREMENT RATHER THAN AN
# ASSUMPTION. recall/REPS.tsv is sorted by family, then by construct, and the
# reps of one construct are contiguous. Measured 2026-10-17 over the shipped
# table: 120 reps, 37 constructs, four unbroken family runs -- core, then
# sequences, then sets, then functions-records -- so 33 of the 36 adjacent
# construct pairs are same-family. That is what lets the window be computed
# from the delivered table alone. A delivered tree carries no
# drill/INVENTORY.md and this script reads no family anywhere.
# harness/test-recall-runner.sh part 14 gates both halves: the contiguity and
# the four runs.
#
# AT THE TAIL IT REPEATS A CONSTRUCT RATHER THAN STOPPING. When every
# unserved rep belongs to the construct just served, the choice is between
# breaking the lag and ending a session early, and a rep the reader has not
# seen is worth more than the lag.
#
# NOTHING IS KEPT BETWEEN SESSIONS, AND THAT IS A DECISION.
#
# scripts/deliver-recall.sh overwrites every file it delivers, and its header
# justifies that by saying no file in this channel is learner-owned. A
# progress file would make that false, and the delivery would then overwrite
# a learner's own record in a tree that is not a git repo -- which is the
# shape of the 2026-10-02 incident that took 39 delivered files.
#
# The rung does not need one either. A drill item declares eight to twelve
# minutes and must not be lost. A rep costs about a third of a second, so a
# session that ends has cost nothing. What a session does keep, for as long as
# it runs, is which reps it has served, so no rep comes round twice.
#
# HOW A SESSION ENDS, three ways, and a loop that cannot be left is worse than
# no loop:
#
#     --count N       stop after N reps
#     EOF on stdin    Ctrl-D at a terminal, or the end of a pipe
#     the table       every rep served once, and it says so
#
# EOF leaves ONE PROMPT UNANSWERED on screen, and that is not a bug to fix.
# The prompt goes out before the read can discover there is nothing to read,
# so a reader who answers a question with Ctrl-D sees that question last.
#
# A BLANK LINE SKIPS THE REP AND SHOWS THE ANSWER. A reader who declines to
# attempt is past the point the attempt was protecting, and withholding it
# there teaches nothing. A skip runs no TLC at all.
#
# A SESSION ECHOES THE ANSWER WHEN STDIN IS NOT A TERMINAL. A terminal echoes
# what is typed and a pipe does not, so without this a piped transcript is a
# prompt character with the feedback jammed against it and no record of what
# was answered. It is the only behaviour in this script keyed on a terminal.
#
# A SESSION EXITS 0 WHENEVER IT RAN. It is not a grade, so it carries none:
# the grade of each rep left on that rep's own status line.
#
# ---------------------------------------------------------------------------
# EXIT, and this is the contract the gate depends on: the exit code is the
# RAW CODE THE GRADING RUN RETURNED, never a code inferred from anything TLC
# printed. Three codes are this script's own and none of them collides with a
# code of TLC's:
#
#     2   usage error -- a missing argument or an unknown flag
#     3   could not run -- no rep, no environment, no tlc, no scratch
#     4   the value is right and the construct the rep drills is not in what
#         was typed. See THE CONSTRUCT GATE below
#
# 2 and 3 happen before TLC starts, so there is no verdict to be faithful to.
# 4 is the one that happens after a run, and it replaces a grading run that
# came back 0: the status line carries 4 and the runner's own token, and the
# line under it names the rc and token the grading run returned, so nothing
# the run said is hidden. 4 sits in the 3-to-7 range harness/vacuity.sh:320
# reserves for statements about the submission.
#
# ---------------------------------------------------------------------------
# IT DEPENDS ON NOTHING BUT TLC
#
# The practice tree is not this repo. There is no harness beside this file, no
# verdict.sh to call, and no repo root to resolve. Everything this script needs
# to GRADE comes from the directory it sits in and from `tlc` on the path. An
# absent tlc is exit 3 with a message, never a quiet pass. The section is
# drill/study/check's, and so is the wording, because the problem is the same
# one.
#
# IT WAS NOT ALWAYS. Until bead tla-1sh7.10 this script resolved
# ${REPO_ROOT}/harness/verdict.sh and refused to start without it, so a copy
# delivered to a practice tree looked for a harness/ directory nothing puts
# there and answered rc 3 to every rep and every answer, right ones included.
# Measured 2026-10-16 against a delivered copy, and again 2026-10-17 in a temp
# tree with no repo above it: the canonical answer to R107 came back 3.
#
# WHAT THE SLICE ACTUALLY WAS, measured before it was absorbed rather than
# after. This script passed verdict.sh four of its ten options -- -t, -c,
# --scratch and --log -- plus the module, and read back two things, the token
# on stdout and the exit status. Of the thirteen codes verdict.sh maps, a
# grading run here can reach THREE. The scaffold below declares no
# SPECIFICATION, no INIT, no NEXT, no INVARIANT and no PROPERTY, so there is
# no behaviour to explore and nothing to refute:
#
#     0    OK                  the two values are equal
#     10   ASSUMPTION_FAILED   they are not, OR the ASSUME blew up evaluating
#     150  PARSE_ERROR         SANY rejected it
#
# 11 DEADLOCK, 12 SAFETY_VIOLATION, 13 LIVENESS_VIOLATION, 14
# ASSERT_VIOLATION, 76 SAFETY_EVAL_FAILURE and 77 LIVENESS_EVAL_FAILURE all
# need a .cfg keyword this scaffold's empty .cfg does not carry. 151
# CONFIG_ERROR needs a .cfg naming an operator, and the .cfg names nothing. 99
# CHECK_DID_NOT_RUN is verdict.sh's deadlock refusal, which cannot fire
# without a CHECK_DEADLOCK keyword or a --check-deadlock this script never
# passed.
#
# 75 SPEC_EVAL_FAILURE IS THE ONE THAT SURPRISES, and it is why the rows above
# were measured rather than reasoned about. Every evaluation failure inside an
# ASSUME comes back 10 and not 75: 1 \div 0, CHOOSE over the empty set,
# Head(<<>>), Cardinality of a function, and a set built past TLC's million-
# element ceiling. All five measured 2026-10-17 on TLC2 2026.07.31.184830
# through verdict.sh itself. 75 belongs to the initial-state computation,
# which this scaffold never reaches.
#
# TWO ROWS ARE STRUCTURAL RATHER THAN REACHABLE, and they are named anyway:
# 124 TIMEOUT, because the run is wrapped in timeout(1), and 255
# TLC_EXCEPTION, because a .cfg that failed to be written is a missing .cfg.
# Neither was provoked from a learner-typed answer in the probes that found
# the three above. Naming them costs two lines and misnaming them would cost
# a learner a sentence about their answer that was really about the run.
#
# EVERY OTHER CODE IS UNKNOWN_<rc> AND THAT IS THE POINT. A renumbered TLC
# surfaces loudly here instead of quietly matching a familiar name, which is
# verdict.sh's own posture for an unmapped code and the reason to keep it.
#
# THE DUPLICATION IS REAL AND IT IS GATED. verdict.sh's header says it is the
# one place the exit-code table lives, and five of its thirteen mapped codes
# now also live here. harness/test-recall-runner.sh part 8 reads both files
# and requires every code this script names to carry verdict.sh's own token
# for it, so the second copy drifting is a red suite rather than a learner
# being told the wrong word. That gate lives in the repo, where both files
# are. The delivered tree needs neither it nor verdict.sh.
#
# THE INVOCATION IS verdict.sh's, COPIED FLAG FOR FLAG. Nothing below is tuned
# for this rung. A flag dropped because a grading run cannot reach what it
# guards would be a new measurement wearing an old table's authority, and
# harness/test-recall-runner.sh part 2 corroborates every code here by running
# the real verdict.sh over an equivalent scaffold. Identical flags is what
# makes that corroboration mean something.
#
# THE GRADING SCAFFOLD, measured on TLC2 2026.07.31.184830:
#
#     ---- MODULE Recall ----
#     EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
#     <the rep's constant environment, spliced verbatim>
#     Answer == <what was typed>
#     ASSUME Answer = <the canonical answer>
#     ====
#
# with an empty .cfg beside it. The four rows of the epic's table, re-measured
# here 2026-10-16 over Wagons == {"a","b","c"} and Tracks == 1..3:
#
#     [Wagons -> Tracks]                  rc   0  OK                 correct
#     {f \in [Wagons -> Tracks] : TRUE}   rc   0  OK                 correct
#     [w \in Wagons |-> Tracks]           rc  10  ASSUMPTION_FAILED  not
#     [Tracks -> Wagons]                  rc  10  ASSUMPTION_FAILED  not
#
# ANY CORRECT FORM PASSES, because the comparison is on values rather than on
# text. That is the whole reason the grade is an ASSUME rather than a diff.
#
# Three more codes were measured and each gets its own report, because telling
# somebody their answer is wrong when it never parsed is a false statement
# about a check that did not run:
#
#     Answer == [Wagons ->             rc 150  PARSE_ERROR   unbalanced
#     Answer == Bogosity               rc 150  PARSE_ERROR   unknown name
#     Answer == 7                      rc  10  ASSUMPTION_FAILED
#
# The last one is the useful surprise: comparing a number to a set of
# functions is not an evaluation failure, it is simply false, so a type
# mismatch grades as a wrong answer and gets the value block like any other.
#
# THE CONSTRUCT GATE, field 7 of the rep table.
#
# Value equality grades the value, so it cannot see how the value was reached.
# A learner who computes the right answer without writing the construct the rep
# drills has not done the rep. Field 7 carries an ERE matched against the RAW
# ANSWER TEXT, and a rep without one grades exactly as it did before the field
# existed, which is why nothing in recall/REPS.tsv had to change.
#
# THE PATTERN NAMES THE CONSTRUCT'S OWN KEYWORD AND NOTHING ELSE. Any correct
# form passing is what lets this rung grade without a model in the loop, and a
# pattern that reaches for the shape of the whole answer gives that away. All
# three of these are the same answer to a LET rep, and `\bLET\b` takes all
# three where `^LET [A-Za-z]+\(t\) ==` takes one:
#
#     LET Twice(t) == t * 2 IN [t \in Tracks |-> Twice(t)]
#     LET Doubled(n) == n + n IN [t \in Tracks |-> Doubled(t)]
#     LET F == [t \in Tracks |-> t * 2] IN F
#
# THE MATCH RUNS BEFORE TLC AND THE REFUSAL AFTER IT. Matching first means a
# pattern grep will not read is "could not run" at exit 3 rather than a grade,
# and a gate that fell open on a malformed pattern would be worse than no gate.
# Refusing afterwards means a WRONG value still gets the dual value block,
# which is the half of this script that teaches, and the gate only ever speaks
# about an answer the grading run already accepted.
#
# THE DUAL VALUE BLOCK. On a wrong answer the script runs one more module per
# value, each one
#
#     ASSUME PrintT("recall-value")
#     ASSUME PrintT(<the value>)
#     ASSUME PrintT(Cardinality(<the value>))
#
# and shows the printed region. The sentinel is there so the start of the
# region is a string this script chose rather than a TLC banner.
#
# THE COUNT IS ATTEMPTED, NOT GUARDED, AND THAT IS NOT LAZINESS. Cardinality
# ERRORS on a value that is not a set:
#
#     Error: Evaluating assumption line 7 ... failed.
#     Attempted to compute cardinality of the value
#     [a |-> 1..3, b |-> 1..3, c |-> 1..3]
#
# and that error is part of the explanation rather than a failure -- it is
# often the clearest statement of the mistake, which is that a function was
# written where a set was asked for. So the value prints, the count is skipped,
# and the script says the count was skipped.
#
# There is no in-TLA+ guard available, and it was measured rather than assumed.
# IsFiniteSet([w \in Wagons |-> 1]) returns TRUE, rc 0, on the very value whose
# Cardinality errors, so `IF IsFiniteSet(x) THEN Cardinality(x) ELSE ...` would
# not skip anything. One value probe PER VALUE is what keeps the skip keyed on
# an exit code: a probe that exits nonzero printed no count, and nothing has to
# read TLC's prose to find that out.
#
# WHY THE PROBE'S rc IS NEVER THE GRADE. A probe exits 10 on the cardinality
# error, which is the SAME code a wrong answer scores on the grading run. The
# two runs are separate modules for exactly that reason, and only the grading
# run's code leaves this script.
#
# THE FIXED EXTENDS LIST is the contract an environment author writes against.
# Measured to reach `:>` and `@@` (both live in TLC, not in a base module),
# Len and Seq, record-field access, intervals, and negative integers. A rep
# needing a module outside the list is a one-line change to EXTENDS_LIST below
# and is not something an environment file can ask for, because TLA+ allows one
# EXTENDS statement and it has to come first.
#
# AN ENVIRONMENT FILE IS A FRAGMENT, NOT A MODULE. recall/env/<name>.tla holds
# bare definitions and nothing else: no module header, no EXTENDS, no trailing
# `====`. It is spliced verbatim into the scaffold, so it cannot be run on its
# own, and the .tla suffix is there for the editor rather than for SANY.
#
#     \* shunting -- three wagons, three tracks.
#     Wagons == {"a", "b", "c"}
#     Tracks == 1..3
#
# THREE NAMES ARE RESERVED and an environment that defines one of them makes
# every rep over it fail to parse, with SANY reporting a multiple declaration
# rather than anything about the rep: `Answer` and `Canonical` in the grading
# scaffold, `Shown` in the value probe.
#
# THE VALUE BLOCK IS CAPPED, because this rung is seconds a rep and a block
# that scrolls the terminal costs more attention than the mistake did. One
# wrong answer to the function-set rep ran to 40 lines, 27 of them the members
# of [Wagons -> Tracks] one per line, with the count that makes the point
# underneath them. `--full` prints the whole thing.
#
# The cap counts LINES rather than members, and the wording on the elision
# says so. TLC prints a small value on one line and breaks a large one at
# about 80 columns, one member per line, so on a flat set a line is a member
# and the two readings agree. They part company on a nested value, where
# `[ a |->` opens at one indent and the set under it sits at another, and a
# cap claiming to count members there would be counting something else. The
# member count survives either way: the probe prints it on a line of its own
# and that line is inside the tail the cap keeps.
#
# BOTH HALVES ARE CAPPED ON THE SAME RULE. The typed value is usually the
# small one, but it is not always: at R108 and R109 the characteristic mistake
# is to swap the domain and the range, and that produces a set of exactly the
# size of the right answer. Two members, the elision, the closing member and
# the count comes to five lines, which is still enough to recognize as yours.
#
# WHAT ELSE A WRONG ANSWER GETS, AND WHERE IT COMES FROM. The two values are
# the first layer of the explanation and they are not the whole of it. Two
# more are files this script reads and neither is a verdict:
#
#     drill/SHEET.md       the construct's own entry, found by the rep's
#                          field 3, which is the K id both files are keyed on
#     recall/MISSES.tsv    the explanation for THIS wrong answer, if the
#                          table carries a row for it
#
# EITHER FILE MISSING IS SILENCE, NEVER A REFUSAL. A delivered practice tree
# can arrive without them and every rep in it still grades, because an
# explanation is not a grade. That is the same posture an absent field 7 has.
# What the gate does instead is assert that the shipped files resolve, so a
# sheet that quietly stopped being found is a red suite rather than a learner
# wondering where the entry went.
#
# A SHEET ENTRY IS A HEADER LINE AND THE ONE LINE UNDER IT. The id, the
# chapter and the construct's name, then its syntax. Backticks are dropped on
# the way out: the file is markdown and this is a terminal.
#
# THE MISS TABLE IS KEYED ON THE TEXT THAT WAS TYPED, and the match is
# NORMALISED FOR WHITESPACE rather than exact. The rule is one sentence: a
# space is kept only where it stands between two word characters, and dropped
# everywhere else. So `{"c","a"}` reaches the row written `{"c", "a"}`, and
# `IN A` can never collapse into `INA`.
#
# EXACT TEXT WAS THE OTHER CANDIDATE AND IT LOSES ON THIS SCRIPT'S OWN
# ARGUMENT. The grade is value equality precisely so that any correct form
# passes and the rung is not a spelling test. Keying the explanation on the
# byte-for-byte shape of a wrong answer reintroduces the spelling test one
# layer down, where it costs a row that somebody wrote and nobody sees. 30
# rows is small enough to match exactly; it is not small enough to be worth
# missing one.
#
# THE ONE THING NORMALISING GIVES UP is TLA+'s bullet-list alignment, since a
# run of whitespace carries the indentation that groups a stacked /\ and \/
# list. That costs nothing against this table and the gate says why: no row's
# field 3 carries both operators, and re-grouping a list of one operator
# cannot change what it means. A row carrying both would be the shape where
# flattening could merge two different answers, and harness/test-recall-runner.sh
# refuses one.
#
# WHAT IT IS NOT KEYED ON IS THE VALUE. A second grading run against the
# row's expression would fire on any answer with the same value, which is a
# wider net than field 4 is written for: "that's a set, so it holds no order"
# is a sentence about a shape somebody typed.
#
# THE MISS ROW GOES ABOVE THE SHEET ENTRY, and the reason is the 90 reps that
# have no row rather than the 30 that do. Whole blocks were read both ways at
# R107, R099, R049 and R118. Either order reads tolerably on its own, so what
# settles it is that this one ENDS THE SAME WAY AT ALL 120 REPS: the sheet
# entry last, the variable section in the middle. A learner drilling at
# seconds a rep learns where to look once. The other order puts the sheet
# entry last at 90 reps and the miss row last at 30, so the bottom of the
# block moves under them.
#
# Reading R099 the other way is the clearest single case. Its sheet entry,
# `F == [x \in S |-> expr]`, landing directly under the canonical answer
# `[w \in Wagons |-> 1]` is a restatement of the line above it. The same
# entry after the misconception reads as the general form of what was just
# explained. Specific, then general, is also the movement the value block
# already starts.
#
# THE SHEET ENTRY ALSO PRINTS ON A CONSTRUCT-GATE REFUSAL, which is the one
# grade whose entire content is that a construct was not written. The miss
# row does not: the value was right, and the miss table is about wrong ones.
#
# NINETY OF THE 120 REPS CARRY NO MISS ROW, so no row is the common case and
# not the fallback. Nothing announces an absence -- no "(no misconception
# recorded)" line -- because a learner who gets both values and a sheet entry
# has had a complete answer and should not be told that a table they cannot
# see declined to speak.
#
# THE REP TABLE is tab-delimited with the literal first field REP, so prose in
# the file can never be read as data. Six fields, and an optional seventh:
#
#     1  REP          the literal marker
#     2  rep id       stable, never renumbered
#     3  construct    K001-K105, a drill/INVENTORY.md row
#     4  environment  resolves to <env-dir>/<name>.tla
#     5  prompt       English, naming none of the notation it asks for
#     6  canonical    the answer, as TLA+
#     7  requires     OPTIONAL. An ERE the raw answer has to match before a
#                     correct value is accepted. Absent or empty is no gate
#
# Rows are read with awk -F'\t', never with `IFS=$'\t' read`. Tab is an IFS
# whitespace character, so read collapses a run of tabs into one delimiter and
# drops a trailing empty field, which silently shifts every later field.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# What a session re-enters once per rep. Absolute, resolved the same way
# SCRIPT_DIR is, so it does not depend on the caller's working directory and
# it points at THIS copy -- a mutant or a delivered tree runs itself, never
# some other recall.sh that happens to be nearer.
SELF="${SCRIPT_DIR}/$(basename -- "${BASH_SOURCE[0]}")"

# REPO_ROOT IS THE SHEET'S DEFAULT AND NOTHING ELSE NOW. It used to carry the
# verdict channel too, which is what made a delivered tree ungradable. What is
# left of it points at drill/SHEET.md, and a sheet that is not there is silence
# rather than a refusal, so the parent of the delivered directory being a
# practice tree rather than a repo costs a wrong answer one explanation layer
# of three and costs a right answer nothing.
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

EXTENDS_LIST="Naturals, Integers, Sequences, FiniteSets, TLC"
SENTINEL='"recall-value"'
TIMEOUT=60

# The runner's own code for "the value is right and the construct is not in
# what was typed". Bound to a name rather than written as a literal at the exit
# site, which is the convention harness/verdict.sh uses for its own 99.
EXIT_CONSTRUCT_MISSING=4
CONSTRUCT_TOKEN="CONSTRUCT_NOT_WRITTEN"

# How much of a value survives the cap: the first two lines and the last two.
# Two at the head because the second is what shows which position moves first,
# which is the whole content of a function set. Two at the tail because the
# last two lines of a set's block are the closing member, which carries the
# ` }`, and the count underneath it.
VALUE_HEAD=2
VALUE_TAIL=2

# How wide the two prose sections wrap. The value block is not wrapped: TLC
# chose its own line breaks there and re-flowing them would move members
# across lines the cap counts. Prose has no such constraint, and 76 plus the
# two-space indent leaves a column clear of an 80-column terminal.
PROSE_WIDTH=76

REPS="${SCRIPT_DIR}/REPS.tsv"
ENV_DIR="${SCRIPT_DIR}/env"
SHEET="${REPO_ROOT}/drill/SHEET.md"
MISSES="${SCRIPT_DIR}/MISSES.tsv"
QUIET=0
FULL=0
NO_PROMPT=0
SESSION=0
SESSION_COUNT=0
SESSION_SEED=""
REP_ID=""
ANSWER=""
HAVE_ANSWER=0

# How far the session's walk reaches for the next construct, in positions of
# the rep table's own construct order. Two is the smallest window that holds
# more than one other construct, and the file is sorted by family, so two
# positions is within the family almost everywhere. See THE SESSION in the
# header for the measurement.
WALK_WINDOW=2

# Lines 2 to 30 of this file: what the script is, how it is called, and the
# flags. The range is a line number, so moving or growing the OPTIONS block
# means moving this too. It used to be ungated and silently truncated the
# help when the session flags were added. harness/test-recall-runner.sh part
# 14 now pins the first and last line this prints.
usage() { sed -n '2,30p' "${BASH_SOURCE[0]}"; }

die_usage() {
  printf 'recall.sh: %s\n' "$1" >&2
  usage >&2
  exit 2
}

# Exit 3 is "could not run", and it is deliberately not a verdict. Copied from
# drill/study/check, which reserves 3 for the same thing and for the same
# reason: a run that did not happen must not report a grade.
die_cannot_run() {
  printf 'recall.sh: %s\n' "$1" >&2
  exit 3
}

while [ "$#" -gt 0 ]; do
  # `--` ends the options wherever it stands, so every call that already used
  # the escape keeps working. It is checked first for that reason: the rule
  # under it would otherwise swallow a `--` typed after the rep id.
  if [ "$1" = "--" ]; then shift; break; fi

  # ONCE THE REP ID IS IN HAND THE NEXT ARGUMENT IS THE ANSWER, whatever it
  # starts with. This is the whole fix for a negative-integer rep: `-4` is the
  # right answer to R012, and a learner who types it has no way to guess an
  # escape. The cost is that a flag goes before the rep id, which is where
  # every caller already puts it.
  if [ -n "$REP_ID" ] && [ "$HAVE_ANSWER" = "0" ]; then
    ANSWER="$1"; HAVE_ANSWER=1; shift; continue
  fi

  case "$1" in
    --reps)    [ "$#" -ge 2 ] || die_usage "--reps needs a file"; REPS="$2"; shift 2 ;;
    --env-dir) [ "$#" -ge 2 ] || die_usage "--env-dir needs a directory"; ENV_DIR="$2"; shift 2 ;;
    --sheet)   [ "$#" -ge 2 ] || die_usage "--sheet needs a file"; SHEET="$2"; shift 2 ;;
    --misses)  [ "$#" -ge 2 ] || die_usage "--misses needs a file"; MISSES="$2"; shift 2 ;;
    --session)  SESSION=1; shift ;;
    --count)    [ "$#" -ge 2 ] || die_usage "--count needs a number"
                case "$2" in ''|*[!0-9]*) die_usage "--count takes a whole number, not: $2" ;; esac
                SESSION_COUNT="$2"; shift 2 ;;
    --seed)     [ "$#" -ge 2 ] || die_usage "--seed needs a number"
                case "$2" in ''|*[!0-9]*) die_usage "--seed takes a whole number, not: $2" ;; esac
                SESSION_SEED="$2"; shift 2 ;;
    --full)     FULL=1; shift ;;
    -q|--quiet) QUIET=1; shift ;;
    --no-prompt) NO_PROMPT=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    -*)         die_usage "unknown option: $1" ;;
    *)
      if [ -z "$REP_ID" ]; then
        REP_ID="$1"
      else
        die_usage "unexpected extra argument: $1"
      fi
      shift ;;
  esac
done

# The remainder after `--`, so an answer beginning with a dash is reachable.
while [ "$#" -gt 0 ]; do
  if [ -z "$REP_ID" ]; then
    REP_ID="$1"
  elif [ "$HAVE_ANSWER" = "0" ]; then
    ANSWER="$1"; HAVE_ANSWER=1
  else
    die_usage "unexpected extra argument: $1"
  fi
  shift
done

# A SESSION TAKES NEITHER OF THESE, and saying so is better than a usage dump
# whose first line is about a rep id. Checked before the two lines below,
# which are about the single-rep invocation.
if [ "$SESSION" = "1" ]; then
  [ -z "$REP_ID" ] || die_usage "--session takes no rep id: a session serves the reps itself"
  [ "$HAVE_ANSWER" = "0" ] || die_usage "--session takes no answer: each one is typed into the session"
else
  [ -n "$REP_ID" ]        || die_usage "no rep id given"
  [ "$HAVE_ANSWER" = "1" ] || die_usage "no answer given"
fi

# The ONE thing outside this directory a rep needs. An absent tlc is exit 3
# with a message, never a quiet pass: drill/study/check line 722 is the
# precedent and the reason is the same one. Without this the run would come
# back 127 from the shell and be reported as UNKNOWN_127, which is a true
# number attached to a false frame -- "the grading run came back 127" says
# something about the answer, and there was no grading run.
command -v tlc >/dev/null 2>&1 || die_cannot_run "tlc is not on the path, so nothing was graded."
[ -r "$REPS" ]    || die_cannot_run "no rep table at ${REPS}, so nothing was graded."

# ---------------------------------------------------------------------------
# THE SESSION LOOP (bead tla-1sh7.11). See THE SESSION in the header for why
# the walk is what it is, why nothing is kept, and how a session ends.
#
# IT SITS HERE, ABOVE THE REP LOOKUP, because the lookup below refuses to
# proceed without a rep id and a session has none. Everything it calls is
# therefore defined in this block: bash has not read the rest of this file
# when the branch at the bottom runs, so a helper from further down would be
# an unknown command rather than a helper.
# ---------------------------------------------------------------------------

# Two spaces of indent, wrapped. The same shape show_prose uses further down,
# and it is written twice rather than shared for the reason above.
session_prose() {
  local wrapped
  wrapped="$(fold -s -w "$PROSE_WIDTH" <<<"$1")"
  sed -e 's/[[:space:]]*$//' -e 's/^/  /' <<<"$wrapped"
}

# The walk's tables, read in three passes rather than one. A row is never
# field-split with `IFS=$'\t' read`: tab is an IFS whitespace character, so
# read folds a run of tabs into one delimiter and drops a trailing empty
# field, which shifts every field after it. Three awk passes over one file
# cost nothing against a single TLC run and cannot shift.
WALK_IDS=()
WALK_KS=()
WALK_PROMPTS=()
WALK_KIDX=()
WALK_SERVED=()
WALK_KN=0
WALK_CUR_K=-1
WALK_PICK=-1
WALK_KI=0
WALK_ID=""
WALK_PROMPT=""

walk_load() {
  local v k i
  while IFS= read -r v; do WALK_IDS+=("$v"); done < <(awk -F'\t' '$1 == "REP" { print $2 }' "$REPS")
  while IFS= read -r v; do WALK_KS+=("$v"); done < <(awk -F'\t' '$1 == "REP" { print $3 }' "$REPS")
  while IFS= read -r v; do WALK_PROMPTS+=("$v"); done < <(awk -F'\t' '$1 == "REP" { print $5 }' "$REPS")

  # The construct order IS the file order, which is what makes a window of two
  # positions a window of one family. See the header.
  local -A first_seen=()
  for i in "${!WALK_IDS[@]}"; do
    k="${WALK_KS[i]}"
    if [ -z "${first_seen[$k]+set}" ]; then
      first_seen[$k]="$WALK_KN"
      WALK_KN=$(( WALK_KN + 1 ))
    fi
    WALK_KIDX+=("${first_seen[$k]}")
    WALK_SERVED+=(0)
  done
}

# The canonical answer for a rep, read at the moment a skip needs it and never
# held in a table. There is no list of answers anywhere in a session.
walk_canon() {
  awk -F'\t' -v id="$1" '$1 == "REP" && $2 == id { print $6; exit }' "$REPS"
}

# Sets WALK_PICK to the index of the next rep, or returns 1 when every rep has
# been served.
walk_pick() {
  local w="$WALK_WINDOW" i d
  local -a cand
  while :; do
    cand=()
    for i in "${!WALK_IDS[@]}"; do
      [ "${WALK_SERVED[i]}" = "1" ] && continue
      WALK_KI="${WALK_KIDX[i]}"
      if [ "$WALK_CUR_K" -ge 0 ]; then
        # NEVER THE CONSTRUCT JUST SERVED. Two reps of one construct back to
        # back is lag 0, where the second is recognition rather than recall.
        [ "$WALK_KI" = "$WALK_CUR_K" ] && continue
        d=$(( WALK_KI - WALK_CUR_K ))
        [ "$d" -lt 0 ] && d=$(( 0 - d ))
        [ "$d" -gt "$w" ] && continue
      fi
      cand+=("$i")
    done
    if [ "${#cand[@]}" -gt 0 ]; then
      WALK_PICK="${cand[$(( RANDOM % ${#cand[@]} ))]}"
      return 0
    fi
    # Nothing in the window. On the first rep there is no window to widen, so
    # an empty table is the only way to get here.
    [ "$WALK_CUR_K" -lt 0 ] && break
    if [ "$w" -lt "$WALK_KN" ]; then w=$(( w * 2 )); continue; fi
    break
  done
  # THE TAIL. Every unserved rep belongs to the construct just served, so the
  # choice is between repeating a construct and ending the session early. A
  # rep the reader has not seen is worth more than the lag.
  for i in "${!WALK_IDS[@]}"; do
    if [ "${WALK_SERVED[i]}" != "1" ]; then WALK_PICK="$i"; return 0; fi
  done
  WALK_PICK=-1
  return 1
}

run_session() {
  local answer rc ended="count" echo_answer=1
  local served=0 right=0 wrong=0 skipped=0 ungraded=0
  local -a child

  # The only thing in this script keyed on a terminal. A terminal echoes what
  # is typed and a pipe does not, so a piped transcript would otherwise be a
  # prompt character with the feedback jammed against it.
  if [ -t 0 ]; then echo_answer=0; fi

  [ -x "$SELF" ] || die_cannot_run "${SELF} is not executable, so a session cannot grade."

  walk_load
  if [ "${#WALK_IDS[@]}" -eq 0 ]; then
    die_cannot_run "${REPS} carries no REP rows, so there is nothing to serve."
  fi

  # The walk is a draw, and a seeded draw can be run again. Unseeded, bash
  # seeds RANDOM itself and every session differs.
  if [ -n "$SESSION_SEED" ]; then RANDOM="$SESSION_SEED"; fi

  # Built once. It is never empty, so expanding it under `set -u` is safe on
  # every bash this script might meet.
  child=(--no-prompt)
  [ "$FULL" = "1" ] && child+=(--full)
  [ "$QUIET" = "1" ] && child+=(-q)

  while :; do
    if [ "$SESSION_COUNT" -gt 0 ] && [ "$served" -ge "$SESSION_COUNT" ]; then
      ended="count"
      break
    fi
    if ! walk_pick; then
      ended="exhausted"
      break
    fi
    WALK_SERVED[WALK_PICK]=1
    WALK_CUR_K="${WALK_KIDX[WALK_PICK]}"
    WALK_ID="${WALK_IDS[WALK_PICK]}"
    WALK_PROMPT="${WALK_PROMPTS[WALK_PICK]}"

    # The prompt and nothing else. This is the whole of the fix: a reader
    # finds out what a rep asks without the line its answer is on.
    printf '%s  %s\n' "$WALK_ID" "$WALK_PROMPT"
    printf '> '

    # EOF leaves the prompt above unanswered on screen, which is what a reader
    # who presses Ctrl-D at a question is looking at anyway.
    if ! IFS= read -r answer; then
      printf '\n'
      ended="eof"
      break
    fi
    [ "$echo_answer" = "1" ] && printf '%s\n' "$answer"

    if [ -z "$answer" ]; then
      skipped=$(( skipped + 1 ))
      served=$(( served + 1 ))
      printf '\nskipped. the answer was:\n'
      session_prose "$(walk_canon "$WALK_ID")"
      printf '\n'
      continue
    fi

    # STDIN COMES FROM /dev/null, so nothing downstream can read the answers
    # still queued for this loop. TLC reading one would take a rep away and
    # leave no trace of having done it.
    rc=0
    "$SELF" "${child[@]}" --reps "$REPS" --env-dir "$ENV_DIR" \
      --sheet "$SHEET" --misses "$MISSES" -- "$WALK_ID" "$answer" </dev/null || rc=$?
    case "$rc" in
      0)      right=$(( right + 1 )) ;;
      4|10)   wrong=$(( wrong + 1 )) ;;
      *)      ungraded=$(( ungraded + 1 )) ;;
    esac
    served=$(( served + 1 ))
    printf '\n'
  done

  if [ "$ended" = "exhausted" ]; then
    printf 'that was every rep in the table; it ran out.\n'
  fi

  if [ "$served" -eq 0 ]; then
    printf 'no reps answered.\n'
    return 0
  fi

  # Only the categories that happened. A line of zeroes says nothing and a
  # reader working at seconds a rep reads this one every time.
  local line
  line="$(printf '%d rep' "$served")"
  [ "$served" -eq 1 ] || line="${line}s"
  [ "$right" -gt 0 ]    && line="${line}, ${right} right"
  [ "$wrong" -gt 0 ]    && line="${line}, ${wrong} wrong"
  [ "$skipped" -gt 0 ]  && line="${line}, ${skipped} skipped"
  [ "$ungraded" -gt 0 ] && line="${line}, ${ungraded} not graded"
  printf '%s.\n' "$line"
  return 0
}

if [ "$SESSION" = "1" ]; then
  run_session
  exit 0
fi

# ---------------------------------------------------------------------------
# The rep.
# ---------------------------------------------------------------------------
ROW="$(awk -F'\t' -v id="$REP_ID" '$1 == "REP" && $2 == id { print; exit }' "$REPS")"
if [ -z "$ROW" ]; then
  die_cannot_run "${REPS} has no REP row with id ${REP_ID}, so nothing was graded."
fi

# Field 3 is the K id, and it is the join to drill/SHEET.md. A rep with no
# construct id reaches no entry and the rest of the run is unaffected, which
# is why this is not checked the way the environment and the canonical are.
CONSTRUCT="$(cut -f3 <<<"$ROW")"
ENV_NAME="$(cut -f4 <<<"$ROW")"
PROMPT="$(cut -f5 <<<"$ROW")"
CANON="$(cut -f6 <<<"$ROW")"
# A six-field row has no field 7 and cut returns the empty string for it, which
# is the same thing an empty field 7 says: no gate.
REQUIRES="$(cut -f7 <<<"$ROW")"

[ -n "$ENV_NAME" ] || die_cannot_run "rep ${REP_ID} names no environment, so nothing was graded."
[ -n "$CANON" ]    || die_cannot_run "rep ${REP_ID} carries no canonical answer, so nothing was graded."

# The construct gate's match, run here rather than after the grading run so
# that a pattern grep will not read is "could not run" instead of a grade. A
# gate that fell open on a malformed pattern would be worse than no gate: the
# row would look gated and would not be. What the match DOES happens further
# down, after TLC has said whether the value is right.
#
# A here-string, never a pipe into a quiet grep. Under pipefail an
# early-exiting consumer closes the pipe, the producer takes SIGPIPE, the
# pipeline reports 141, and inside an `if` that is merely falsy. So a PRESENT
# pattern would report as ABSENT and the gate would fire on a correct answer.
REQUIRES_MET=1
if [ -n "$REQUIRES" ]; then
  MATCH_RC=0
  grep -qE -- "$REQUIRES" <<<"$ANSWER" || MATCH_RC=$?
  case "$MATCH_RC" in
    0) REQUIRES_MET=1 ;;
    1) REQUIRES_MET=0 ;;
    *) die_cannot_run "rep ${REP_ID} carries a field-7 pattern grep will not read as an expression, so nothing was graded." ;;
  esac
fi

ENV_FILE="${ENV_DIR}/${ENV_NAME}.tla"
[ -r "$ENV_FILE" ] || die_cannot_run "rep ${REP_ID} names environment ${ENV_NAME}, and ${ENV_FILE} is not there, so nothing was graded."

# ---------------------------------------------------------------------------
# The scratch directory TLC runs in.
#
# A scratch directory this script cannot make is a hard error rather than a
# run in the working directory. The pattern is drill/study/check lines 724 to
# 764, and the reason is the same one: falling back would put TLC's states/
# tree and a scaffold module into whatever directory the caller happened to be
# standing in, which on a delivered practice tree holds the only copy of the
# work. "Could not run" is both true and safe.
# ---------------------------------------------------------------------------
SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/recall.XXXXXXXX" 2>/dev/null)"
if [ -z "$SCRATCH" ] || [ ! -d "$SCRATCH" ]; then
  die_cannot_run "could not make a scratch directory to run TLC in, so nothing was graded."
fi
# shellcheck disable=SC2317  # reached through the EXIT trap on the next line
drop_scratch() { rm -rf "$SCRATCH"; }
trap drop_scratch EXIT

# ---------------------------------------------------------------------------
# The modules. Written here rather than through a shell heredoc on a command
# line: the isolation harness reads a TLA+ conjunction as a path leaving the
# worktree and a set literal as a brace group, and refuses both.
#
# Every interpolated value goes in through printf '%s' as an argument, so a
# learner's answer is never shell text. It can still be bad TLA+, and that is
# what rc 150 is for.
# ---------------------------------------------------------------------------
write_grade_module() {
  local path="$1" name="$2"
  {
    printf '%s\n' "---- MODULE ${name} ----"
    printf 'EXTENDS %s\n' "$EXTENDS_LIST"
    cat -- "$ENV_FILE"
    printf 'Answer == %s\n' "$ANSWER"
    printf 'Canonical == %s\n' "$CANON"
    printf 'ASSUME Answer = Canonical\n'
    printf '%s\n' "===="
  } >"$path"
}

write_value_module() {
  local path="$1" name="$2" expr="$3"
  {
    printf '%s\n' "---- MODULE ${name} ----"
    printf 'EXTENDS %s\n' "$EXTENDS_LIST"
    cat -- "$ENV_FILE"
    printf 'Shown == %s\n' "$expr"
    printf 'ASSUME PrintT(%s)\n' "$SENTINEL"
    printf 'ASSUME PrintT(Shown)\n'
    printf 'ASSUME PrintT(Cardinality(Shown))\n'
    printf '%s\n' "===="
  } >"$path"
}

# The printed region of a probe log: everything after the sentinel this script
# planted, up to TLC's next structural line.
#
# READ FOR DISPLAY, NEVER FOR A VERDICT. harness/verdict.sh's own header draws
# that line -- the log is "for HUMANS and for witness extraction, never for
# verdicts" -- and the grade in this script comes from the exit code of a
# different run entirely.
# The one line dropped is TLC's `Error: Evaluating assumption line N, col M ...
# of module Yours failed.` It cites a line of a module in a scratch directory
# that is already gone by the time anybody reads this, so it sends a reader
# somewhere they cannot go. The sentence under it, "Attempted to compute
# cardinality of the value X", is the part that says what went wrong, and it
# stays.
printed_region() {
  awk -v sentinel="$SENTINEL" '
    $0 == sentinel { on = 1; next }
    on && /^Computing initial states/ { exit }
    on && /^Finished computing/ { exit }
    on && /^Finished in / { exit }
    on && /^Model checking completed/ { exit }
    on && /^Error: Evaluating assumption line/ { next }
    on { print }
  ' "$1"
}

# ---------------------------------------------------------------------------
# The two explanation layers that are not values. Both are lookups into files
# this script only ever reads, and neither one can change a grade.
#
# Defined up here rather than beside show_value because the construct-gate
# refusal prints a sheet entry and returns before show_value is ever defined.
# ---------------------------------------------------------------------------

# Two spaces of indent, wrapped to PROSE_WIDTH, with the trailing space
# `fold -s` leaves at each break taken back off. A here-string rather than a
# pipe at every step: under pipefail a consumer that closes early makes the
# producer take SIGPIPE and the whole pipeline report 141.
show_prose() {
  local wrapped
  wrapped="$(fold -s -w "$PROSE_WIDTH" <<<"$1")"
  sed -e 's/[[:space:]]*$//' -e 's/^/  /' <<<"$wrapped"
}

# The construct's entry in the sheet. An entry is the `- Kxxx  chNN  Name`
# line and the single line under it, and `index(...) == 1` anchors the id so
# K05 can never reach K050. Two lines out: a header this script assembles,
# then the syntax with its markdown backticks dropped.
sheet_entry() {
  [ -r "$SHEET" ] || return 1
  awk -v want="$1" '
    index($0, "- " want "  ") == 1 {
      n = split($0, a, "  ")
      name = a[3]
      for (i = 4; i <= n; i++) name = name "  " a[i]
      if ((getline body) > 0) {
        gsub(/^[ \t]+/, "", body)
        gsub(/[ \t]+$/, "", body)
        gsub(/`/, "", body)
        if (body != "") {
          printf "%s  %s  %s\n", substr(a[1], 3), a[2], name
          printf "%s\n", body
        }
      }
      exit
    }
  ' "$SHEET"
}

# The miss row for this rep and this answer, normalised for whitespace.
#
# THE ANSWER ARRIVES THROUGH THE ENVIRONMENT, NOT THROUGH -v. awk processes
# escape sequences in a -v assignment, so `\in` would reach the program as
# `in` and no TLA+ answer would ever match. ENVIRON hands the bytes over
# untouched.
#
# norm() keeps a space only where it separates two word characters, which is
# the only place TLA+ needs one. Everywhere else it goes, so a learner's
# spacing is not part of the key.
miss_row() {
  [ -r "$MISSES" ] || return 1
  RECALL_ANSWER="$ANSWER" awk -F'\t' -v rep="$1" '
    function norm(s,   out, i, c, n, prev, nxt) {
      gsub(/[ \t\r\n]+/, " ", s)
      sub(/^ /, "", s)
      sub(/ $/, "", s)
      n = length(s)
      out = ""
      for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (c != " ") { out = out c; continue }
        prev = substr(s, i - 1, 1)
        nxt  = substr(s, i + 1, 1)
        if (prev ~ /[A-Za-z0-9_]/ && nxt ~ /[A-Za-z0-9_]/) out = out " "
      }
      return out
    }
    BEGIN { want = norm(ENVIRON["RECALL_ANSWER"]) }
    $1 == "MISS" && $2 == rep && norm($3) == want { print $4; exit }
  ' "$MISSES"
}

# Layer 3. Silent when the table has no row for what was typed, which is the
# case at 90 of the 120 reps, and silent in a way that leaves no hole: a
# learner with both values and a sheet entry has a whole answer and is not
# told that a table they cannot see had nothing to say.
show_misconception() {
  local text
  text="$(miss_row "$1")" || return 0
  [ -n "$text" ] || return 0
  echo
  echo "what you wrote says"
  show_prose "$text"
}

# Layer 2. Keyed on the rep's construct rather than on the answer, so it is
# the same entry however the rep was got wrong.
show_sheet() {
  local entry
  entry="$(sheet_entry "$1")" || return 0
  [ -n "$entry" ] || return 0
  echo
  sed -n '1p' <<<"$entry"
  show_prose "$(sed -n '2,$p' <<<"$entry")"
}

# The rows this script names, and nothing else. See IT DEPENDS ON NOTHING BUT
# TLC in the header for which three a grading run can reach, which two are
# named for being structural, and which gate keeps all five agreeing with
# harness/verdict.sh.
#
# THE CATCH-ALL IS NOT A FALLBACK, it is the whole reason the table is safe to
# copy. An unmapped code is reported as itself rather than bucketed into the
# nearest familiar row, so a renumbered TLC reaches a learner as a loud
# UNKNOWN_<rc> instead of a plausible-looking wrong answer.
verdict_token() {
  case "$1" in
    0)   printf 'OK\n' ;;
    10)  printf 'ASSUMPTION_FAILED\n' ;;
    124) printf 'TIMEOUT\n' ;;
    150) printf 'PARSE_ERROR\n' ;;
    255) printf 'TLC_EXCEPTION\n' ;;
    *)   printf 'UNKNOWN_%s\n' "$1" ;;
  esac
}

# One TLC run. The code is TLC's own, taken from the process status and from
# nothing it printed, and the token is this script's name for that code.
#
# THE FLAGS ARE harness/verdict.sh's, IN ITS ORDER, AND NONE OF THEM IS
# DECORATION:
#
#   -workers 1          pinned, so a run is reproducible
#   -noGenerateSpecTE   no *_TTrace_*.tla spillage beside anything
#   -nowarning          the log is read by a person
#   -coverage 1         carried rather than dropped, see the header
#   -dumpTrace json     a counterexample would be data, not console text
#   -metadir            TLC's states/ tree, into scratch, never beside a spec
#   -deadlock           TLC's flag means "do NOT check", and with no spec to
#                       explore there is nothing to deadlock on. It is here
#                       because verdict.sh's default run carries it, and this
#                       invocation is that one.
#
# BOTH PATHS ARE ABSOLUTE OR BOTH ARE RELATIVE, never one of each. TLC moves
# the base a relative --config resolves against when, and only when, the
# module argument is absolute (bead tla-sn0h), so an absolute module with a
# relative config is the one cell of four that exits 255 on a file the caller
# can see. Both of these come out of the same mktemp root, so they always
# agree and the trap cannot be sprung from here.
run_verdict() {
  local module="$1" cfg="$2" log="$3" stem states rc=0
  stem="$(basename -- "$module" .tla)"
  states="${SCRATCH}/states-${stem}"
  mkdir -p "$states"
  timeout "$TIMEOUT" tlc \
    -workers 1 \
    -noGenerateSpecTE \
    -nowarning \
    -coverage 1 \
    -dumpTrace json "${states}/trace.json" \
    -metadir "${states}/states" \
    -deadlock \
    "$module" -config "$cfg" >"$log" 2>&1 || rc=$?
  VERDICT_RC="$rc"
  VERDICT_TOKEN="$(verdict_token "$rc")"
}

# ---------------------------------------------------------------------------
# The grading run. One TLC invocation, about 0.32 s measured over three runs
# on 2026-10-16 (316 / 388 / 351 ms), which is what makes this a drill rather
# than a quiz.
# ---------------------------------------------------------------------------
: >"${SCRATCH}/Recall.cfg"
write_grade_module "${SCRATCH}/Recall.tla" "Recall"
run_verdict "${SCRATCH}/Recall.tla" "${SCRATCH}/Recall.cfg" "${SCRATCH}/Recall.log"
GRADE_RC="$VERDICT_RC"
GRADE_TOKEN="$VERDICT_TOKEN"

case "$GRADE_RC" in
  0)   GRADE="correct" ;;
  10)  GRADE="incorrect" ;;
  150) GRADE="parse-error" ;;
  *)   GRADE="other" ;;
esac

# The construct gate's refusal. It only ever replaces a grading run that came
# back 0, so a wrong value keeps its value block and the gate has nothing to
# say about it. REPORT_RC is what leaves this script; GRADE_RC stays the
# grading run's own number and is printed under the refusal.
REPORT_RC="$GRADE_RC"
REPORT_TOKEN="$GRADE_TOKEN"
if [ "$GRADE" = "correct" ] && [ "$REQUIRES_MET" = "0" ]; then
  GRADE="construct-missing"
  REPORT_RC="$EXIT_CONSTRUCT_MISSING"
  REPORT_TOKEN="$CONSTRUCT_TOKEN"
fi

# The prompt echo. A session has already printed this line and read an answer
# under it, so it passes --no-prompt and the block starts at the status line.
# Nothing else is conditional on it.
if [ "$QUIET" = "0" ] && [ "$NO_PROMPT" = "0" ]; then
  printf '%s  %s\n' "$REP_ID" "$PROMPT"
fi
printf 'rep=%s rc=%s token=%s grade=%s\n' "$REP_ID" "$REPORT_RC" "$REPORT_TOKEN" "$GRADE"

if [ "$QUIET" = "1" ]; then
  exit "$REPORT_RC"
fi

echo

if [ "$GRADE" = "correct" ]; then
  echo "correct."
  exit "$REPORT_RC"
fi

if [ "$GRADE" = "construct-missing" ]; then
  echo "the value is right. the construct this rep drills is not in what you typed."
  echo
  printf '  wanted somewhere in the answer:  %s\n' "$REQUIRES"
  printf '  the grading run came back rc=%s token=%s, so only the form is at issue.\n' \
    "$GRADE_RC" "$GRADE_TOKEN"
  # The sheet entry, because this is the one grade whose whole content is that
  # a construct was not written, and field 7 is an ERE rather than notation.
  # No miss row: the value was right, and that table is about wrong ones.
  show_sheet "$CONSTRUCT"
  exit "$REPORT_RC"
fi

if [ "$GRADE" = "parse-error" ]; then
  echo "that did not parse, so nothing was graded about whether it is right."
  echo
  # SANY's own sentence, which names the line and the operator. Display only.
  grep -hE 'was not declared|Encountered|Unknown operator|Precedence conflict|Lexical error|Was expecting' \
    "${SCRATCH}/Recall.log" 2>/dev/null | sed -n 's/^[[:space:]]*/  /p' | sort -u
  exit "$REPORT_RC"
fi

if [ "$GRADE" = "other" ]; then
  printf 'the grading run came back %s, which is neither correct nor a wrong answer.\n' "$GRADE_RC"
  printf 'that is a report about the run rather than about the answer.\n'
  exit "$REPORT_RC"
fi

# ---------------------------------------------------------------------------
# The dual value block. One probe per value, so a count skipped on one side
# cannot cost the other side its value.
# ---------------------------------------------------------------------------
echo "not correct. what you typed, then the answer."

# The cap. A region short enough to read comes back untouched, byte for byte,
# and so does every region under --full.
#
# head and tail take a HERE-STRING rather than a pipe. The region is already
# in a variable, and piping a printf into either one would hand an
# early-exiting consumer a live pipe: the consumer closes it on its last line,
# the producer takes SIGPIPE, and under pipefail the whole thing comes back
# 141. A here-string is materialised before the consumer is exec'd, so there
# is no writer left to signal.
#
# The elision carries two leading spaces because the region's own continuation
# lines do, and show_value indents the lot by two more. That puts the three
# dots under the members rather than under the opening brace.
cap_region() {
  local region="$1" n elided
  n="$(wc -l <<<"$region")"
  if [ "$FULL" = "1" ] || [ "$n" -le "$((VALUE_HEAD + VALUE_TAIL + 1))" ]; then
    printf '%s\n' "$region"
    return
  fi
  elided="$((n - VALUE_HEAD - VALUE_TAIL))"
  head -n "$VALUE_HEAD" <<<"$region"
  printf '  ... %s more lines, and --full shows them all ...\n' "$elided"
  tail -n "$VALUE_TAIL" <<<"$region"
}

show_value() {
  local label="$1" name="$2" expr="$3"
  : >"${SCRATCH}/${name}.cfg"
  write_value_module "${SCRATCH}/${name}.tla" "$name" "$expr"
  run_verdict "${SCRATCH}/${name}.tla" "${SCRATCH}/${name}.cfg" "${SCRATCH}/${name}.log"
  echo
  printf '%-11s %s\n' "$label" "$expr"
  local region
  region="$(printed_region "${SCRATCH}/${name}.log")"
  if [ -z "$region" ]; then
    echo "  that value could not be evaluated at all, so there is nothing to show."
    return
  fi
  region="$(cap_region "$region")"
  sed -n 's/^/  /p' <<<"$region"
  # The count is skipped exactly when the probe exited nonzero. Keyed on the
  # code, not on the error text above it.
  if [ "$VERDICT_RC" != "0" ]; then
    echo "  (no count: TLC will not count that value, so it is not a set)"
  fi
}

show_value "you typed" "Yours" "$ANSWER"
show_value "the answer" "Canon" "$CANON"

# Values, then what this answer says, then what the construct is. One widening
# movement, and the order was settled by reading whole blocks both ways rather
# than by argument. The header's note names the reps.
show_misconception "$REP_ID"
show_sheet "$CONSTRUCT"

exit "$REPORT_RC"
