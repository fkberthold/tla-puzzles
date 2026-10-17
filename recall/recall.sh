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
# A TYPO DOES NOT SPEND THE REP (bead tla-1sh7.12). A parse error is not a
# wrong answer: nothing was graded, so the retrieval attempt the rung exists
# for never happened. The session hands the SAME rep back, up to
# SESSION_PARSE_TRIES, and only then shows the answer and says so. See that
# constant for why the cap is three, and the loop itself for why only 150 is
# retried.
#
# EACH PROMPT CARRIES THE NAMES IN SCOPE (bead tla-1sh7.13). A prompt names
# none of the notation it asks for and none of the identifiers either, so a
# rep that needs `Balance` and `!["ann"]` exactly was unanswerable from what a
# session printed. The block under each prompt is what the answer is dropped
# into: a REP row's environment definitions, or a SPEC row's machines with the
# line being filled marked. See THE SCOPE BLOCK for what is in it and why it
# is the definitions rather than a list of names.
#
# AND ONE LINE AT THE HEAD SAYS WHAT AN ANSWER IS. Every REP row goes into a
# scaffold as `Answer == <what was typed>`, so an action can never be right on
# one, and nothing anywhere said so. It is a property of the channel rather
# than of a rep, so it is said once rather than under 160 prompts.
#
# A SESSION ECHOES THE ANSWER WHEN STDIN IS NOT A TERMINAL. A terminal echoes
# what is typed and a pipe does not, so without this a piped transcript is a
# prompt character with the feedback jammed against it and no record of what
# was answered. It is the only behavior in this script keyed on a terminal.
#
# A SESSION EXITS 0 WHENEVER IT RAN. It is not a grade, so it carries none:
# the grade of each rep left on that rep's own status line.
#
# ---------------------------------------------------------------------------
# EXIT, and this is the contract the gate depends on: the exit code is the
# RAW CODE THE GRADING RUN RETURNED, never a code inferred from anything TLC
# printed. Four codes are this script's own and none of them collides with a
# code of TLC's:
#
#     2   usage error -- a missing argument or an unknown flag
#     3   could not run -- no rep, no environment, no scaffold, no tlc, no
#         scratch
#     4   the answer was accepted and the construct the rep drills is not in
#         what was typed. See THE CONSTRUCT GATE below
#     5   a SPEC rep whose scaffolds all ran and whose exit codes did not
#         match the vector field 8 names. See A SPEC REP below
#
# 2 and 3 happen before TLC starts, so there is no verdict to be faithful to.
# 4 is the one that happens after a run, and it replaces a grading run that
# came back 0: the status line carries 4 and the runner's own token, and the
# line under it names the rc and token the grading run returned, so nothing
# the run said is hidden. 4 and 5 sit in the 3-to-7 range
# harness/vacuity.sh:320 reserves for statements about the submission.
#
# 5 IS A CODE OF THIS SCRIPT'S RATHER THAN A CODE OF TLC'S, AND THAT IS A
# CHOICE WORTH SEEING. A spec rep runs between one and four TLCs, so there is
# no single raw code to be faithful to, and reporting the first disagreeing
# run's own code would put `rc=0` on a status line reading `grade=incorrect`
# whenever the answer PASSED a spec it was supposed to fail. The number that
# is true of a vector is a number about the vector. Every code each run
# returned is printed under the status line, so nothing any run said is
# hidden -- the same arrangement 4 already uses.
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
# no behavior to explore and nothing to refute:
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
# THE REP TABLE is tab-delimited and carries the row kind in field 1, so prose
# in the file can never be read as data. There are TWO kinds and the marker is
# how they are told apart.
#
# A REP ROW. Six fields, and an optional seventh:
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
# A SPEC ROW. Eight fields, and an optional ninth:
#
#     1  SPEC         the literal marker
#     2  rep id       stable, never renumbered
#     3  construct    K001-K105, a drill/INVENTORY.md row
#     4  scaffolds    comma-separated, each resolving to a PAIR of files,
#                     <env-dir>/spec/<name>.tla and <env-dir>/spec/<name>.cfg
#     5  prompt       English, naming none of the notation it asks for
#     6  canonical    the answer, as TLA+
#     7  requires     OPTIONAL, and the SAME FIELD IT IS ON A REP ROW. See
#                     THE CONSTRUCT GATE. On a spec row it is usually not
#                     optional in practice; the reason is below
#     8  expect       comma-separated exit codes, one per scaffold, in the
#                     scaffolds' own order. This is the KEY
#     9  check        OPTIONAL. the text that fills a scaffold's __CHECK__
#                     hole, if it has one
#
# Rows are read with awk -F'\t', never with `IFS=$'\t' read`. Tab is an IFS
# whitespace character, so read collapses a run of tabs into one delimiter and
# drops a trailing empty field, which silently shifts every later field.
#
# ---------------------------------------------------------------------------
# A SPEC REP, AND WHY VALUE EQUALITY CANNOT REACH ONE (bead tla-03ep.1)
#
# 68 of the inventory's 105 constructs say nothing about a value. `WF_v(A)` is
# not an expression with a value; it is a promise about a behavior, and
# `ASSUME Answer = Canonical` over it is not false, it is meaningless. The 20
# constructs of the `temporal` family are the whole of that problem: nothing
# in them has a value to compare.
#
# So a spec rep grades the answer by PUTTING IT IN A MACHINE AND RUNNING THE
# MACHINE. The answer fills a hole in a scaffold, TLC checks the scaffold, and
# the KEY IS THE EXIT CODE -- the same contract the value rung has, read off a
# model check instead of off an assumption.
#
# A SCAFFOLD IS A WHOLE MODULE WITH HOLES IN IT, not a fragment. Both halves
# of it ship:
#
#     <env-dir>/spec/<name>.tla    the module, named `Scaffold`, with a line
#                                  whose only content is `__ANSWER__` and at
#                                  most one whose only content is `__CHECK__`
#     <env-dir>/spec/<name>.cfg    the obligations TLC is given over it
#
# THE HOLE IS A WHOLE LINE AND THE FILL IS NEVER PASSED THROUGH A REGEX. The
# runner reads the template a line at a time and emits the answer in place of
# the line whose trimmed text is `__ANSWER__`. A learner's answer therefore
# never meets sed, awk or the shell as a program, which is the same posture
# the value scaffold's `printf '%s'` takes. The scaffold author decides what
# the hole is: a fairness conjunct, a temporal property, an action, a Spec
# body, a `vars` tuple, or the VARIABLE declaration itself.
#
# THE MODULE IS ALWAYS CALLED `Scaffold`, so the runner copies it to
# `Scaffold.tla` beside `Scaffold.cfg` in a directory of its own and rewrites
# nothing. A battery of three scaffolds is three directories.
#
# THE KEY IS THE VECTOR, NOT A CODE, AND THAT IS THE WHOLE DESIGN. A single
# run cannot grade a temporal property, because a property WEAKER than the one
# asked for also holds: `[]TRUE` passes any machine. Two runs catch too-weak
# and too-strong. Even two miss a near neighbor -- measured 2026-10-17, the
# answer `<>(level = 1)` has the same two-sided profile as `<>(level = 2)` and
# needed a fourth spec to separate. So field 8 is a vector and field 4 is a
# list, and the grade is whether the two agree position by position.
#
#     correct      every run returned the code field 8 names for it
#     incorrect    every run was gradeable and at least one disagreed
#
# WHICH CODES ARE GRADEABLE, measured on TLC2 2026.07.31.184830 over the 29
# shipped scaffolds and every wrong answer in recall/MISSES.tsv:
#
#     0   OK                  the obligation held
#     10  ASSUMPTION_FAILED   a POSTCONDITION came back FALSE. This is how a
#                             state-graph fingerprint reports a mismatch
#     12  SAFETY_VIOLATION    an INVARIANT was broken, OR a PROPERTY that is
#                             a bare state predicate under [] was. Measured:
#                             `[](level =< 2)` against a lift that reaches a
#                             third floor is 12 and not 13, because TLC reads
#                             a box-of-state-predicate as an invariant
#     13  LIVENESS_VIOLATION  a temporal PROPERTY did not hold
#
# 11 DEADLOCK IS NOT IN THAT LIST and the reason is the invocation rather than
# the table: every run here carries TLC's `-deadlock`, which means do NOT
# check, so a terminal state is never an error.
#
# EVERYTHING ELSE IS A REPORT ABOUT THE RUN RATHER THAN ABOUT THE ANSWER, and
# four were reached from real wrong answers rather than imagined:
#
#     150  PARSE_ERROR        SANY rejected the filled scaffold. A temporal
#                             formula in an ACTION hole lands here as a LEVEL
#                             error rather than a syntax one
#     151  CONFIG_ERROR       an ACTION in a PROPERTY hole, which is the
#                             mirror of the level error above. Also
#                             `CONSTANTS level, lamp` where VARIABLES was
#                             wanted: the .cfg then assigns nothing
#     255  TLC_EXCEPTION      `WF_vars(Init)` -- fairness over the initial
#                             predicate rather than over an action. Also a
#                             VARIABLES line declaring a name nothing
#                             constrains
#     75   SPEC_EVAL_FAILURE  an action that leaves a variable unspecified,
#                             `level' = 0 \/ level' = 2` with nothing said
#                             about the lamp
#
# A run outside the gradeable set OUTRANKS a disagreement, so a rep whose
# first scaffold blew up is never reported as a wrong answer. Telling somebody
# their answer is wrong when nothing was checked is the same false statement
# rc 150 already exists to avoid on the value rung.
#
# WHY FIELD 7 IS NOT REALLY OPTIONAL HERE. Value equality cannot see how a
# value was reached and an exit code cannot see how a verdict was reached, so
# the construct gate is load-bearing on a spec row in a way it is not on a
# value row. Measured: `<>(level = 2)` conjoined into the fairness hole of
# `fair-lift` PASSES at rc 0. It is not a fairness condition at all -- it is
# the goal asserted as a hypothesis -- and the run cannot tell. `\bWF_` in
# field 7 is what closes it, and the refusal says the value was right and the
# construct was not written, which is exactly true.
#
# WHAT THE VECTOR STILL CANNOT SEE, stated here rather than left to be
# discovered. Two measured holes:
#
#   - A WRONG SUBSCRIPT IN A Spec BODY. `Init /\ [][Next]_level` and
#     `Init /\ [][Next]_vars` give the identical state graph, 6 distinct
#     states at diameter 4 generating 11, because TLC builds successors from
#     Next and the subscript only decides which steps count as stuttering.
#     No fingerprint reaches it. The `vars` tuple has reps of its own, where
#     the key is a battery over two machines that stop moving in different
#     places.
#   - A PROPERTY ABOUT THE ONLY PERPETUAL MOVER. On a two-machine battery
#     that separates "something really moves, for ever" from its ENABLED
#     form, `[]<>(lamp = 1)` shares the canonical's vector, because the lamp
#     is the thing that moves. It is not recorded as a miss for that rep,
#     because it is not caught.
#
# A ROW THAT WAS NEVER SUBMITTED WRONG IS NOT EVIDENCE. Every wrong answer
# recall/MISSES.tsv records against a spec rep was run against the battery
# that rep actually ships, and the vector it produced was read before the row
# was written.
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

# The literal a REP row's answer is written after. Bound to a name because its
# LENGTH is the column offset the parse-error caret subtracts, so the prefix and
# the offset cannot drift apart: write_grade_module writes this string and
# answer_caret reads its length. A SPEC row has no prefix, because the answer
# fills a whole line there and the column comes back unshifted.
ANSWER_PREFIX="Answer == "

# How many goes a session gives ONE rep before it shows the answer and moves on.
#
# A parse error is not a wrong answer, so until bead tla-1sh7.12 the rep was
# spent on a typo and the retrieval attempt the rung exists for never happened.
# The session hands the rep back instead. It is capped because an answer that
# will never parse must not loop, and a loop that cannot be left is worse than
# a rep lost.
#
# THREE RATHER THAN TWO, AND THE TWO WERE RUN AGAINST EACH OTHER. The case that
# separates them is a typo, then a second typo in the retype, then the right
# answer. Measured 2026-10-17 over R119: at two that scores `1 rep, 1 not
# graded` and the reader is handed the answer over a slip that has nothing to
# do with the notation. At three it scores `1 rep, 1 right`.
#
# THE WORST CASE IS CHEAP, which is what makes the third go affordable. One
# whole session of nothing but unparseable answers: 222 ms at a cap of 1,
# 429 ms at two, 638 ms at three, 762 ms at four. Four buys nothing the third
# go did not, and reads as a session that will not let go.
SESSION_PARSE_TRIES=3

# The runner's own code for "the value is right and the construct is not in
# what was typed". Bound to a name rather than written as a literal at the exit
# site, which is the convention harness/verdict.sh uses for its own 99.
EXIT_CONSTRUCT_MISSING=4
CONSTRUCT_TOKEN="CONSTRUCT_NOT_WRITTEN"

# The runner's own code for "every scaffold of a SPEC rep ran and the vector
# of codes is not the vector field 8 names". Bound to a name for the same
# reason 4 is, and it carries a token of its own because verdict_token() maps
# TLC's codes and 5 is not one of them.
EXIT_SPEC_NOT_MATCHED=5
SPEC_TOKEN="SPEC_NOT_MATCHED"

# Where a SPEC row's scaffolds resolve, under the environment directory. A
# scaffold is a WHOLE MODULE and an environment file is a FRAGMENT, so the two
# kinds live apart rather than sharing a directory and a suffix.
SPEC_SUBDIR="spec"

# The module every scaffold declares, and the basename the runner copies it to.
# Fixed rather than derived from the scaffold name, because a scaffold name
# carries hyphens and a TLA+ module name cannot.
SPEC_MODULE="Scaffold"

# The two holes. A line whose trimmed content is one of these is replaced; any
# other line is emitted byte for byte.
HOLE_ANSWER="__ANSWER__"
HOLE_CHECK="__CHECK__"

# The codes a SPEC run may return that are a statement about the spec the
# answer built. Anything else is a report about the run. All four were reached
# from a real wrong answer on TLC2 2026.07.31.184830; see A SPEC REP in the
# header for which answer reaches which.
#
# 11 DEADLOCK IS DELIBERATELY NOT IN THIS LIST, and its absence is a fact
# about the runner rather than about the codes. Every run here carries TLC's
# `-deadlock`, which means do NOT check, so a terminal state is never an error
# and 11 cannot be reached from any scaffold. A rep whose whole question is
# about a terminal state needs the runner to stop passing that flag, and that
# is a change to the invocation rather than a row in a table.
SPEC_GRADEABLE="0 10 12 13"

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

# ---------------------------------------------------------------------------
# THE SCOPE BLOCK: the names a rep needs and does not say (bead tla-1sh7.13)
#
# A prompt states a need in English and names none of the notation that answers
# it, which is what makes it a rep. It also names none of the IDENTIFIERS, and
# those are not notation. R119 asks for "the balance after two has been paid
# into ann's account", and the answer has to read `Balance` and `!["ann"]`
# exactly. Nothing in the prompt says `Balance` is capitalized that way, and
# nothing anywhere said `ann` was a quoted string. Measured 2026-10-17: all 160
# rows name a field 4, and a session printed the prompt and nothing else.
#
# SHOWING THE NAMES IS NOT SHOWING THE ANSWER. The names are the vocabulary.
# Knowing `Balance` exists does not say to reach for EXCEPT, any more than the
# shunting prompt naming wagons and tracks says to reach for a function set.
# What has to stay hidden is field 6, and nothing below reads field 6.
#
# IT IS THE DEFINITIONS AND NOT A ROSTER OF NAMES, and that was measured rather
# than preferred. A roster lists top-level definitions, so a string literal
# INSIDE one is hidden by it. 39 of the 120 REP canonicals carry a quoted
# literal and R119 is one of them. The fuller form also teaches the thing a
# roster could never show, since `Accounts == {"ann", "bo"}` sits beside
# `Balance == [ann |-> 3, bo |-> 0]`: the same name quoted in one and bare in
# the other, which is why `Balance["ann"]` works.
#
# THE SAME ARGUMENT REACHES THE SPEC ROWS BY A DIFFERENT ROUTE. None of the 40
# SPEC canonicals carries a quoted literal, so the literal argument does not
# apply there. The structural one does: `act-decl` and `act-decl3` have the
# VARIABLES line itself as the hole, so `level`, `lamp` and `latch` are never
# DECLARED anywhere in those two scaffolds. They appear only inside bodies, in
# `vars == <<level, lamp, latch>>`, which is the `ann` problem one rung up. A
# roster over either one comes back without the names the answer needs.
#
# WHAT A SPEC ROW'S EQUIVALENT OF AN ENVIRONMENT IS. Field 4 names scaffolds,
# and a scaffold is a whole module rather than a fragment, so the block is the
# module's own lines with the first comment, the header, the EXTENDS line, the
# `====` and the `__CHECK__` line taken out, and the answer hole marked. That
# is the same rule the REP block follows: everything the answer is dropped in
# beside, comments stripped.
#
# THE SCAFFOLD'S FIRST LINE IS NOT ENOUGH ON ITS OWN. It is a `\*` comment
# saying in English what machine this is, and it leads the block for exactly
# that reason, because it is the bridge from the prompt's "the lift's own rise"
# to an identifier. It is not the block: fair-lift's comment reads "a goods
# lift standing beside a lamp", and the canonical `WF_vars(Raise)` needs two
# names the comment does not carry.
#
# EVERY SCAFFOLD OF A BATTERY, NOT THE FIRST. Measured over the 20 rows naming
# more than one: 10 of them do NOT agree on the names in scope, because one
# member carries a `Drop` or a `latch` the others do not, and prop-slip leads
# three of those rows. Showing one machine would state a name another machine
# does not have, and the answer is checked against all of them. The cost is
# lines, and a battery rep is not a seconds-a-rep rep anyway: measured 347 ms
# for one scaffold against 1346 ms for the four of S011.
#
# ONE CONSEQUENCE, WEIGHED AND ACCEPTED. The block prints a scaffold's
# obligation, which on fair-lift is `Tops == <>(level = 2)`. That is the goal
# the fairness condition exists to buy, and conjoining it into the fairness
# hole PASSES at rc 0, which is the measured trap recorded in REPS.tsv's own
# header. Field 7 closes it on all 40 rows and the refusal says the construct
# was not written, so the trap is caught and explained rather than left to
# score. Leaving the obligation out would also drop `Checked ==` from the 18
# property rows, which is the line that says the hole is a named formula.
#
# THE FINGERPRINT IS NOT IN THE BLOCK and that is a fact about where it lives
# rather than a filter here. `TLCGet("distinct") = 3 /\ ...` is field 9 of the
# rep row, and a scaffold carries only the `__CHECK__` marker it fills. The
# line is dropped because a marker says nothing, not to hide a number.
#
# UNDER EVERY REP, NOT ONCE PER ENVIRONMENT, AND BOTH WERE READ. Printing on
# change saves about three blocks in six and costs the reader the names at the
# moment they are owed. Measured over the shipped table at ten seeds: field 4
# changes at 96 of 190 steps over both row kinds and at 71 of 190 over the REP
# rows alone, so a run between changes is two or three reps. One rep's feedback
# runs eight to ten lines, so the block from two reps back has already left a
# 24-line terminal. The on-change transcript of a six-rep session at seed 1 has
# three prompts naming the train and wagon b with `Train` and `Parking` forty
# lines up and nothing on screen saying they are still in scope, which is the
# state this bead is about.
#
# IT COSTS ALMOST NOTHING WHERE IT WOULD HAVE SAVED MOST, which is the other
# half of the same measurement. Inside the spec family field 4 changes at 18 of
# 19 steps, because a scaffold list belongs to a rep rather than to a surface
# several reps share. So on-change would have printed the block anyway on the
# rows where it is longest.
# ---------------------------------------------------------------------------

# What the answer hole reads as on screen. `__ANSWER__` is the runner's own
# marker and says nothing to a reader.
SCOPE_HOLE="<your answer>"

# A REP row's block: the environment fragment, comments and blank lines out,
# indented two. ONE sed rather than a chain of them, because a pipe into a
# consumer that can close early reports 141 under pipefail.
scope_env() {
  [ -r "$1" ] || return 0
  sed -e '/^[[:space:]]*\\\*/d' -e '/^[[:space:]]*$/d' -e 's/^/  /' "$1"
}

# A SPEC row's block: one scaffold, the English line first and then the module's
# own definitions with the answer hole marked.
#
# THE FIRST-LINE READ IS spec_about's AND IT IS WRITTEN TWICE ON PURPOSE.
# spec_about is defined below the session branch, so bash has not read it when
# a session runs. session_prose duplicates show_prose for the same reason, and
# the alternative is moving half the script above a branch that would then be
# harder to find.
scope_scaffold() {
  local tla="${ENV_DIR}/${SPEC_SUBDIR}/${1}.tla"
  [ -r "$tla" ] || return 0
  session_prose "$(sed -n '1{s/^\\\*[[:space:]]*//;p;}' "$tla")"
  echo
  sed -e '1d' \
      -e '/^----.*MODULE/d' \
      -e '/^====/d' \
      -e '/^EXTENDS /d' \
      -e "/^[[:space:]]*${HOLE_CHECK}[[:space:]]*\$/d" \
      -e '/^[[:space:]]*\\\*/d' \
      -e '/^[[:space:]]*$/d' \
      -e "s|^[[:space:]]*${HOLE_ANSWER}[[:space:]]*\$|${SCOPE_HOLE}|" \
      -e 's/^/  /' \
      "$tla"
}

# The block for one rep, under its prompt. A field 4 that resolves to nothing
# is silence rather than a refusal, which is the posture an absent sheet and an
# absent miss table already have: a block is an explanation and not a grade.
session_scope() {
  local kind="$1" field4="$2" n first=1
  local -a names
  if [ "$kind" = "SPEC" ]; then
    IFS=',' read -r -a names <<<"$field4"
    if [ "${#names[@]}" -eq 1 ]; then
      printf 'the machine:\n'
    else
      printf 'the %s machines, and the answer goes into each of them:\n' "${#names[@]}"
    fi
    for n in "${names[@]}"; do
      [ "$first" = "1" ] || echo
      first=0
      scope_scaffold "$n"
    done
  else
    printf 'in scope:\n'
    scope_env "${ENV_DIR}/${field4}.tla"
  fi
}

# The walk's tables, read in five passes rather than one. A row is never
# field-split with `IFS=$'\t' read`: tab is an IFS whitespace character, so
# read folds a run of tabs into one delimiter and drops a trailing empty
# field, which shifts every field after it. Five awk passes over one file
# cost nothing against a single TLC run and cannot shift.
#
# FIELDS 1 AND 4 ARE HERE FOR THE SCOPE BLOCK (bead tla-1sh7.13), which has to
# know the row kind to know what field 4 resolves to. Field 6 is NOT read
# anywhere in the walk and never has been: walk_canon goes back to the file at
# the moment a skip needs one answer, so no list of answers is ever in memory
# while a rep is on screen.
WALK_IDS=()
WALK_KINDS=()
WALK_KS=()
WALK_ENVS=()
WALK_PROMPTS=()
WALK_KIDX=()
WALK_SERVED=()
WALK_KN=0
WALK_CUR_K=-1
WALK_PICK=-1
WALK_KI=0
WALK_ID=""
WALK_KIND=""
WALK_ENV=""
WALK_PROMPT=""

# BOTH ROW KINDS ARE IN ONE POOL, so a session interleaves a spec rep with a
# value rep. That is not a convenience: the window below draws the next rep
# from a construct within two positions of the last, and the families sit in
# file order, so a spec family appended to the table is reached across one
# boundary rather than sealed off behind a flag.
walk_load() {
  local v k i
  while IFS= read -r v; do WALK_IDS+=("$v"); done < <(awk -F'\t' '$1 == "REP" || $1 == "SPEC" { print $2 }' "$REPS")
  while IFS= read -r v; do WALK_KINDS+=("$v"); done < <(awk -F'\t' '$1 == "REP" || $1 == "SPEC" { print $1 }' "$REPS")
  while IFS= read -r v; do WALK_KS+=("$v"); done < <(awk -F'\t' '$1 == "REP" || $1 == "SPEC" { print $3 }' "$REPS")
  while IFS= read -r v; do WALK_ENVS+=("$v"); done < <(awk -F'\t' '$1 == "REP" || $1 == "SPEC" { print $4 }' "$REPS")
  while IFS= read -r v; do WALK_PROMPTS+=("$v"); done < <(awk -F'\t' '$1 == "REP" || $1 == "SPEC" { print $5 }' "$REPS")

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
  awk -F'\t' -v id="$1" '($1 == "REP" || $1 == "SPEC") && $2 == id { print $6; exit }' "$REPS"
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
  local answer rc ended="count" echo_answer=1 tries outcome
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

  # ONCE, AT THE HEAD, AND NOT UNDER EVERY PROMPT (bead tla-1sh7.13). What an
  # answer may be is a property of the channel rather than of a rep: every REP
  # row goes into a scaffold as `Answer == <what was typed>`, so an action can
  # never be right on one, and nothing anywhere said so. Frank read "the
  # balance after two has been paid in" as asking for the change and wrote a
  # primed assignment, which is the documented false friend for anybody
  # arriving from a language where `x = e` updates something.
  #
  # THE UNQUALIFIED CLAIM IS FALSE ON THE SPEC ROWS and the second sentence is
  # there for that. 14 of the 40 fill an ACTION hole, where `level' = level + 1
  # /\ lamp' = lamp` is the canonical. So the line says where an action is
  # wanted rather than ruling one out, and the scope block is what says it: the
  # hole sits under `Act ==` on those rows and under `Fair ==` or `Checked ==`
  # on the rest.
  #
  # The prompts stay short. They are deliberately short, and a constraint that
  # holds at every rep said at every rep is noise 160 times over.
  if [ "$QUIET" = "0" ]; then
    session_prose "under every prompt is the block your answer is dropped into. on a value rep that is the definitions in scope, and on a spec rep it is the machine, with the line you are filling marked. the names and their spelling come from there."
    echo
    session_prose "an answer is an expression. a primed variable with an equals sign is an action, and the one kind of rep that wants an action shows you the line it goes on."
    echo
  fi

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
    WALK_KIND="${WALK_KINDS[WALK_PICK]}"
    WALK_ENV="${WALK_ENVS[WALK_PICK]}"
    WALK_PROMPT="${WALK_PROMPTS[WALK_PICK]}"

    # ---------------------------------------------------------------------
    # ONE REP, AND IT IS NOT SPENT BY A TYPO (bead tla-1sh7.12).
    #
    # A parse error is not a wrong answer. Nothing was graded, so the
    # retrieval attempt the rung exists for never happened, and until this
    # bead the session moved on to the next rep anyway. It hands the rep
    # back instead, up to SESSION_PARSE_TRIES, and only then shows the
    # answer and says that is what happened.
    #
    # KEYED ON 150 AND ON NOTHING ELSE. 255, 151 and 75 are reports about
    # the run rather than about a typo, so retyping cannot fix one and a
    # retry over them would be a loop the reader cannot leave.
    #
    # THE SESSION IS THE ONLY PLACE THIS LIVES. A single-rep invocation
    # returning 150 is correct as it stands, and the gate drives that path.
    #
    # `outcome` carries why the inner loop ended, because an EOF has to end
    # the session and the two other exits have to end only the rep.
    # ---------------------------------------------------------------------
    tries=0
    rc=0
    outcome=""
    while [ -z "$outcome" ]; do
      tries=$(( tries + 1 ))

      # The prompt, then the names in scope. The prompt leads because the id
      # is the rep's own header and everything under it belongs to that rep.
      printf '%s  %s\n' "$WALK_ID" "$WALK_PROMPT"
      [ "$QUIET" = "0" ] && session_scope "$WALK_KIND" "$WALK_ENV"
      printf '> '

      # EOF leaves the prompt above unanswered on screen, which is what a
      # reader who presses Ctrl-D at a question is looking at anyway.
      if ! IFS= read -r answer; then
        printf '\n'
        outcome="eof"
        continue
      fi
      [ "$echo_answer" = "1" ] && printf '%s\n' "$answer"

      # A blank line is a skip and a skip is never retried: a reader who
      # declines to attempt is past the point the attempt was protecting.
      if [ -z "$answer" ]; then
        outcome="skip"
        continue
      fi

      # STDIN COMES FROM /dev/null, so nothing downstream can read the
      # answers still queued for this loop. TLC reading one would take a rep
      # away and leave no trace of having done it.
      rc=0
      "$SELF" "${child[@]}" --reps "$REPS" --env-dir "$ENV_DIR" \
        --sheet "$SHEET" --misses "$MISSES" -- "$WALK_ID" "$answer" </dev/null || rc=$?

      if [ "$rc" != "150" ]; then
        outcome="graded"
        continue
      fi
      if [ "$tries" -ge "$SESSION_PARSE_TRIES" ]; then
        outcome="spent"
        continue
      fi
      printf '\nnothing was graded, so the same rep comes back.\n\n'
    done

    case "$outcome" in
      eof)
        ended="eof"
        break
        ;;
      skip)
        skipped=$(( skipped + 1 ))
        served=$(( served + 1 ))
        printf '\nskipped. the answer was:\n'
        session_prose "$(walk_canon "$WALK_ID")"
        printf '\n'
        continue
        ;;
      spent)
        ungraded=$(( ungraded + 1 ))
        served=$(( served + 1 ))
        printf '\n%s tries and none of them parsed. the answer was:\n' "$tries"
        session_prose "$(walk_canon "$WALK_ID")"
        printf '\n'
        continue
        ;;
    esac

    # 5 joins 4 and 10 as a wrong answer: a spec rep whose vector did not
    # match is wrong in the same sense a value that is not equal is.
    case "$rc" in
      0)      right=$(( right + 1 )) ;;
      4|5|10) wrong=$(( wrong + 1 )) ;;
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
ROW="$(awk -F'\t' -v id="$REP_ID" '($1 == "REP" || $1 == "SPEC") && $2 == id { print; exit }' "$REPS")"
if [ -z "$ROW" ]; then
  die_cannot_run "${REPS} has no REP or SPEC row with id ${REP_ID}, so nothing was graded."
fi

# FIELD 1 IS THE ROW KIND and it chooses the grading path. Read out of the row
# rather than guessed from the shape, so a row short of a field reports as a
# row short of a field rather than as the other kind.
KIND="$(cut -f1 <<<"$ROW")"

# Field 3 is the K id, and it is the join to drill/SHEET.md. A rep with no
# construct id reaches no entry and the rest of the run is unaffected, which
# is why this is not checked the way the environment and the canonical are.
CONSTRUCT="$(cut -f3 <<<"$ROW")"
# Field 4 is the environment on a REP row and the comma-separated scaffold
# list on a SPEC row. One position, because the two are the same thing: what
# the answer is dropped into.
ENV_NAME="$(cut -f4 <<<"$ROW")"
PROMPT="$(cut -f5 <<<"$ROW")"
CANON="$(cut -f6 <<<"$ROW")"
# A six-field row has no field 7 and cut returns the empty string for it, which
# is the same thing an empty field 7 says: no gate. The same holds of fields 8
# and 9, which only a SPEC row carries.
REQUIRES="$(cut -f7 <<<"$ROW")"
EXPECT="$(cut -f8 <<<"$ROW")"
CHECK="$(cut -f9 <<<"$ROW")"

[ -n "$ENV_NAME" ] || die_cannot_run "rep ${REP_ID} names no environment, so nothing was graded."
[ -n "$CANON" ]    || die_cannot_run "rep ${REP_ID} carries no canonical answer, so nothing was graded."
if [ "$KIND" = "SPEC" ]; then
  [ -n "$EXPECT" ] || die_cannot_run "rep ${REP_ID} is a SPEC row with no expected exit codes in field 8, so there is no key to grade against and nothing was graded."
fi

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

# ---------------------------------------------------------------------------
# What field 4 resolves to, which is the one thing the two row kinds differ on
# before TLC starts.
#
# A SPEC row's list is split on commas and every part has to resolve to BOTH
# files before anything runs. A battery that is half there is not a battery:
# its vector would be short, and a short vector compared against a full one
# position by position is a grade read off a run that did not happen. Field 8
# is counted here too, for the same reason.
# ---------------------------------------------------------------------------
SPEC_NAMES=()
SPEC_WANT=()
if [ "$KIND" = "SPEC" ]; then
  IFS=',' read -r -a SPEC_NAMES <<<"$ENV_NAME"
  IFS=',' read -r -a SPEC_WANT <<<"$EXPECT"
  if [ "${#SPEC_NAMES[@]}" -ne "${#SPEC_WANT[@]}" ]; then
    die_cannot_run "rep ${REP_ID} names ${#SPEC_NAMES[@]} scaffold(s) and ${#SPEC_WANT[@]} expected code(s), so there is no telling which code belongs to which scaffold and nothing was graded."
  fi
  for spec_i in "${!SPEC_NAMES[@]}"; do
    spec_name="${SPEC_NAMES[spec_i]}"
    [ -n "$spec_name" ] || die_cannot_run "rep ${REP_ID} carries an empty scaffold name in field 4, so nothing was graded."
    [ -r "${ENV_DIR}/${SPEC_SUBDIR}/${spec_name}.tla" ] || \
      die_cannot_run "rep ${REP_ID} names scaffold ${spec_name}, and ${ENV_DIR}/${SPEC_SUBDIR}/${spec_name}.tla is not there, so nothing was graded."
    [ -r "${ENV_DIR}/${SPEC_SUBDIR}/${spec_name}.cfg" ] || \
      die_cannot_run "rep ${REP_ID} names scaffold ${spec_name}, and ${ENV_DIR}/${SPEC_SUBDIR}/${spec_name}.cfg is not there, so nothing was graded."
    case "${SPEC_WANT[spec_i]}" in
      ''|*[!0-9]*) die_cannot_run "rep ${REP_ID} expects '${SPEC_WANT[spec_i]}' from scaffold ${spec_name}, which is not an exit code, so nothing was graded." ;;
    esac
  done
else
  ENV_FILE="${ENV_DIR}/${ENV_NAME}.tla"
  [ -r "$ENV_FILE" ] || die_cannot_run "rep ${REP_ID} names environment ${ENV_NAME}, and ${ENV_FILE} is not there, so nothing was graded."
fi

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
    printf '%s%s\n' "$ANSWER_PREFIX" "$ANSWER"
    printf 'Canonical == %s\n' "$CANON"
    printf 'ASSUME Answer = Canonical\n'
    printf '%s\n' "===="
  } >"$path"
  # WHERE THE ANSWER LANDED, which is what the parse-error caret translates
  # against. Read back off the file rather than counted while writing it,
  # because the environment is spliced with `cat` and its line count is the
  # one number a counter here would have to guess at. `Answer` is a reserved
  # name in an environment file, so the first line starting with the prefix is
  # this one.
  #
  # AN EMPTY ANSWER_LINE IS THE SAFE ANSWER rather than a failure. An
  # environment whose last line has no newline glues the prefix onto it, the
  # match fails, and the caret is withheld. That module was broken anyway, and
  # a caret under the wrong character is worse than none.
  ANSWER_LINE="$(awk -v p="$ANSWER_PREFIX" 'index($0, p) == 1 { print FNR; exit }' "$path")"
  ANSWER_OFFSET="${#ANSWER_PREFIX}"
}

# A SPEC rep's module: the scaffold, line for line, with the two holes filled.
#
# A LINE AT A TIME, AND NEVER THROUGH A REGEX ENGINE. A learner's answer meets
# no sed program and no shell parse on the way in: this reads the template with
# `read`, compares each line's trimmed text against a fixed string, and emits
# either the fill or the line byte for byte. `sed "s/__ANSWER__/$ANSWER/"` would
# hand a TLA+ answer to a substitution where `\`, `&` and `/` all mean
# something, and a learner's wrong answer would come back as a parse error
# about a character they did not type.
#
# `|| [ -n "$line" ]` catches a template whose last line has no newline, which
# `read` would otherwise drop -- and the dropped line is `====`.
write_spec_module() {
  local tmpl="$1" path="$2"
  local line trimmed n=0
  # The hole's own line number, for the parse-error caret. The fill is one
  # line and the answer is one line, so every line number after the hole is
  # the template's own and SANY's number can be compared against this one
  # directly. The offset is zero: a SPEC row's answer starts in column 1.
  ANSWER_LINE=""
  ANSWER_OFFSET=0
  : >"$path"
  while IFS= read -r line || [ -n "$line" ]; do
    n=$(( n + 1 ))
    trimmed="${line#"${line%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    case "$trimmed" in
      "$HOLE_ANSWER") ANSWER_LINE="$n"; printf '%s\n' "$ANSWER" ;;
      "$HOLE_CHECK")  printf '%s\n' "$CHECK" ;;
      *)              printf '%s\n' "$line" ;;
    esac >>"$path"
  done <"$tmpl"
}

# The scaffold's own first line, which is a `\*` comment saying in English what
# machine the answer is being put into. It is what a wrong answer's report
# names, so a learner reads about a lift and a lamp rather than about a file
# called fair-lift. Read rather than stored in the rep table, because it
# belongs to the scaffold and two reps share one.
spec_about() {
  sed -n '1{s/^\\\*[[:space:]]*//;p;}' "${ENV_DIR}/${SPEC_SUBDIR}/${1}.tla"
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
# SANY's own sentences about what it rejected, for the parse-error report.
# Display only, the way printed_region is: the grade came from the exit code
# of the run and never from this.
#
# TWO SHAPES, AND A PHRASE LIST ONLY REACHES ONE OF THEM.
#
# A SYNTAX error is a single line with no header above it: `Encountered "..."
# at line N, column M and token "..."`. A phrase list is the only way to find
# that one, and the list below is the one this script has always carried.
#
# A SEMANTIC error sits under a `Semantic errors:` header and runs to
# `Starting`, and a phrase list is the wrong instrument for it. THREE
# different sentences turned up from real wrong answers inside two days --
# "Level error in applying operator", "Could not find declaration or
# definition of symbol" and "Couldn't resolve infix operator symbol" -- and
# every one of them came back as an EMPTY block under "that did not parse".
# Chasing them one at a time is a list that is wrong until the next one
# arrives. The region is bounded, so the region is what gets printed.
#
# THE SPEC PATH IS WHY THIS CHANGED. The value scaffold declares no
# SPECIFICATION and one ASSUME, so SANY's semantic pass had almost nothing to
# reject there. A filled scaffold is a whole machine, so it reaches all three.
#
# THE `line N, col M of module Scaffold` LINES ARE DROPPED, for the same
# reason printed_region drops TLC's own location line: the module sits in a
# scratch directory that is gone before anybody reads this, so the citation
# sends a reader somewhere they cannot go. What is left is the sentence, and
# the sentence names the symbol.
#
# THE INLINE `at line N, column M` IS DROPPED TOO (bead tla-1sh7.12), and it
# is the same drop one sentence down rather than a new rule. answer_caret below
# prints the position in the reader's own line, so what is left here is the
# sentence and the sentence names the token.
#
# SO IS `Was expecting "==== or more Module body"`. It is about module
# structure rather than about the expression, it was the first thing Frank read
# under a parse error on 2026-10-17, and it told him nothing. printed_region
# drops TLC's `Error: Evaluating assumption line N` on the same reasoning.
# ---------------------------------------------------------------------------
sany_sentences() {
  {
    awk '
      /^Semantic errors:/            { on = 1; next }
      on && /^Starting/              { exit }
      on && /^\*\*\* Errors:/        { next }
      on && /^line [0-9]+, col /     { next }
      on && /^[[:space:]]*$/         { next }
      on { print }
    ' "$1"
    grep -hE 'was not declared|Encountered|Unknown operator|Precedence conflict|Lexical error' \
      "$1" 2>/dev/null
  } | sed -E -e 's/ at line [0-9]+, column [0-9]+//' -e 's/^[[:space:]]*/  /' | sort -u
}

# ---------------------------------------------------------------------------
# THE LINE THAT WAS TYPED, WITH A CARET UNDER THE ERROR (bead tla-1sh7.12)
#
# Frank typed `acct' = acct EXCEPT !["ann"] = @ + 2` and was told "Encountered
# EXCEPT at line 17, column 24". Line 17 is a line of a module in a scratch
# directory this script deletes before the message is read, so the citation
# sends a reader somewhere they cannot go. His own diagnosis is the fix: the
# session should either let him fix the error or point out what it is.
#
# THE TRANSLATION IS ARITHMETIC, AND BOTH HALVES OF IT COME FROM THE WRITER
# RATHER THAN FROM A CONSTANT HERE. write_grade_module and write_spec_module
# each record ANSWER_LINE and ANSWER_OFFSET, so a scaffold that changes shape
# moves the numbers with it. Measured on TLC2 2026.07.31.184830, 2026-10-17:
#
#   REP   the answer follows `Answer == `, so the offset is 10. Frank's own
#         typo reports column 24, and 24 - 10 is 14, which is the E of EXCEPT
#   SPEC  the answer fills a whole line, so the offset is 0. `level' = level
#         ++ 1` into act-step's hole reports line 8 col 16, the hole is line 8,
#         and column 16 is the first + of the ++
#
# THE LINE NUMBER IS THE GUARD AND IT IS WHY THERE IS NO CONSTANT TO TRUST. An
# unbalanced bracket is reported on the line AFTER the answer: `[Balance
# EXCEPT` comes back "line 18, column 1" with the answer on 17. Subtracting 10
# from that would put a confident caret under the wrong character, so a
# location that is not on the answer's own line yields no caret at all.
#
# THREE LOCATION SHAPES, ALL MEASURED, AND THE STACK TRACE IS NOT ONE OF THEM:
#
#   Encountered "X" at line N, column M and token "Y"   a syntax error
#   Lexical error at line N, column M.                  an unterminated string
#   line N, col M to line N, col M of module Z          a semantic error
#
# `Residual stack trace follows` carries `Some [] Form starting at line 17,
# column 11`, which is where a CONSTRUCT opened rather than where the error is.
# The patterns below are anchored so that `starting at line` cannot match one.
#
# A TAB IN THE ANSWER WITHHOLDS THE CARET. The caret is placed by counting
# characters, and a terminal places a tab by counting columns, so the two part
# company on the first tab and the caret lands somewhere nobody chose.
#
# DISPLAY ONLY, the way printed_region and sany_sentences are. The grade came
# from the exit code of the run.
# ---------------------------------------------------------------------------

# The column SANY named on this line of the module, or nothing.
sany_column() {
  awk -v want="$2" '
    function take(s,   t, a) {
      # The three rules below are not exclusive of each other, and a line that
      # matched two of them would otherwise print two columns.
      if (found) return
      if (match(s, /line [0-9]+, col(umn)? [0-9]+/) == 0) return
      t = substr(s, RSTART, RLENGTH)
      gsub(/[^0-9]+/, " ", t)
      split(t, a, " ")
      if (a[1] + 0 == want + 0) { print a[2] + 0; found = 1 }
    }
    /^Lexical error at line [0-9]+, column [0-9]+/                { take($0) }
    /Encountered .* at line [0-9]+, column [0-9]+ and token/      { take($0) }
    /^line [0-9]+, col [0-9]+ to line/                            { take($0) }
    found { exit }
  ' "$1"
}

answer_caret() {
  local log="$1" aline="$2" offset="$3" col="" n
  echo
  printf '  %s\n' "$ANSWER"
  if [ -n "$aline" ] && [ "$ANSWER" = "${ANSWER//$'\t'/}" ]; then
    col="$(sany_column "$log" "$aline")"
  fi
  if [ -n "$col" ]; then
    col=$(( col - offset ))
    n=${#ANSWER}
    if [ "$col" -ge 1 ] && [ "$col" -le "$n" ]; then
      printf '  %*s^\n' "$(( col - 1 ))" ""
      return
    fi
  fi
  printf '  nothing in the message points inside that line, so there is no caret.\n'
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
    12)  printf 'SAFETY_VIOLATION\n' ;;
    13)  printf 'LIVENESS_VIOLATION\n' ;;
    75)  printf 'SPEC_EVAL_FAILURE\n' ;;
    124) printf 'TIMEOUT\n' ;;
    150) printf 'PARSE_ERROR\n' ;;
    151) printf 'CONFIG_ERROR\n' ;;
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
  # BESIDE THE MODULE, not under the scratch root, because every scaffold of a
  # battery is called Scaffold.tla and a states tree keyed on the stem alone
  # would be one tree shared by three runs. For the value rung's three modules
  # -- Recall, Yours and Canon -- the module IS at the scratch root, so this
  # resolves to exactly the paths it always did.
  states="$(dirname -- "$module")/states-${stem}"
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
# The grading run. On a REP row, one TLC invocation, about 0.32 s measured over
# three runs on 2026-10-16 (316 / 388 / 351 ms), which is what makes this a
# drill rather than a quiz. On a SPEC row, one per scaffold.
#
# PARSE_LOG is the log the parse-error report reads SANY's own sentence out of.
# On a spec rep it is the log of the run that failed to parse rather than a
# fixed name, because a battery has one log per scaffold and the sentence is in
# exactly one of them.
# ---------------------------------------------------------------------------
SPEC_RCS=()
SPEC_TOKENS=()
SPEC_ANSWER_LINES=()
SPEC_FIRST_BAD=-1
SPEC_FIRST_DIFF=-1
PARSE_LOG="${SCRATCH}/Recall.log"

# Where the answer landed in the module SANY read, and by how much its column
# is shifted. Written by whichever module writer ran, read by answer_caret, and
# empty until one of them has run -- which is the right value for a run that
# never happened.
ANSWER_LINE=""
ANSWER_OFFSET=0

if [ "$KIND" = "SPEC" ]; then
  # ONE DIRECTORY PER SCAFFOLD, because every scaffold declares `MODULE
  # Scaffold` and TLC takes the module from the filename. Copying three
  # scaffolds to one directory would be three writes to one file.
  for spec_i in "${!SPEC_NAMES[@]}"; do
    spec_dir="${SCRATCH}/s${spec_i}"
    mkdir -p "$spec_dir" || die_cannot_run "could not make a scratch directory for scaffold ${SPEC_NAMES[spec_i]}, so nothing was graded."
    write_spec_module "${ENV_DIR}/${SPEC_SUBDIR}/${SPEC_NAMES[spec_i]}.tla" "${spec_dir}/${SPEC_MODULE}.tla"
    cp -- "${ENV_DIR}/${SPEC_SUBDIR}/${SPEC_NAMES[spec_i]}.cfg" "${spec_dir}/${SPEC_MODULE}.cfg"
    # The hole's line number, per scaffold, because a battery's members put
    # their holes on different lines and the parse error comes from exactly
    # one of them.
    SPEC_ANSWER_LINES+=("$ANSWER_LINE")
    run_verdict "${spec_dir}/${SPEC_MODULE}.tla" "${spec_dir}/${SPEC_MODULE}.cfg" "${spec_dir}/run.log"
    SPEC_RCS+=("$VERDICT_RC")
    SPEC_TOKENS+=("$VERDICT_TOKEN")
  done

  # THE VECTOR, READ IN ONE PASS, AND A RUN THAT DID NOT HAPPEN OUTRANKS A
  # DISAGREEMENT. A scaffold whose code is outside the gradeable set is a
  # report about the run, and reporting a wrong answer over it would be the
  # same false statement rc 150 exists to avoid on the value rung.
  for spec_i in "${!SPEC_RCS[@]}"; do
    spec_rc="${SPEC_RCS[spec_i]}"
    if ! grep -qE -- "(^| )${spec_rc}( |$)" <<<"$SPEC_GRADEABLE"; then
      [ "$SPEC_FIRST_BAD" -lt 0 ] && SPEC_FIRST_BAD="$spec_i"
      continue
    fi
    if [ "$spec_rc" != "${SPEC_WANT[spec_i]}" ] && [ "$SPEC_FIRST_DIFF" -lt 0 ]; then
      SPEC_FIRST_DIFF="$spec_i"
    fi
  done

  if [ "$SPEC_FIRST_BAD" -ge 0 ]; then
    GRADE_RC="${SPEC_RCS[SPEC_FIRST_BAD]}"
    GRADE_TOKEN="${SPEC_TOKENS[SPEC_FIRST_BAD]}"
    PARSE_LOG="${SCRATCH}/s${SPEC_FIRST_BAD}/run.log"
    # The hole of the scaffold that failed, not of the last one written.
    ANSWER_LINE="${SPEC_ANSWER_LINES[SPEC_FIRST_BAD]}"
    ANSWER_OFFSET=0
    case "$GRADE_RC" in
      150) GRADE="parse-error" ;;
      *)   GRADE="other" ;;
    esac
  elif [ "$SPEC_FIRST_DIFF" -ge 0 ]; then
    GRADE="incorrect"
    GRADE_RC="$EXIT_SPEC_NOT_MATCHED"
    GRADE_TOKEN="$SPEC_TOKEN"
  else
    GRADE="correct"
    GRADE_RC=0
    GRADE_TOKEN="$(verdict_token 0)"
  fi
else
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
fi

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
  # THE FIRST CLAUSE NAMES WHAT WAS ACCEPTED, AND THE TWO ROW KINDS ACCEPT
  # DIFFERENT THINGS. On a value rep the value was right; on a spec rep every
  # scaffold returned the code the rep wanted. Saying "the value is right"
  # over a fairness condition would be a sentence about a value that does not
  # exist.
  if [ "$KIND" = "SPEC" ]; then
    echo "every spec said what it was supposed to. the construct this rep drills is not in what you typed."
  else
    echo "the value is right. the construct this rep drills is not in what you typed."
  fi
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
  # The line that was typed first, then what SANY said about it. The caret is
  # the position and the sentences are the rest, so the sentences no longer
  # carry a position of their own. See answer_caret.
  answer_caret "$PARSE_LOG" "$ANSWER_LINE" "$ANSWER_OFFSET"
  echo
  sany_sentences "$PARSE_LOG"
  exit "$REPORT_RC"
fi

if [ "$GRADE" = "other" ]; then
  printf 'the grading run came back %s, which is neither correct nor a wrong answer.\n' "$GRADE_RC"
  printf 'that is a report about the run rather than about the answer.\n'
  # WHICH RUN, on a spec rep. A battery's other scaffolds may have been fine,
  # and a learner told only the number is left guessing which of three machines
  # it came from.
  if [ "$KIND" = "SPEC" ] && [ "$SPEC_FIRST_BAD" -ge 0 ]; then
    echo
    echo "it came from this one:"
    show_prose "$(spec_about "${SPEC_NAMES[SPEC_FIRST_BAD]}")"
  fi
  exit "$REPORT_RC"
fi

# ---------------------------------------------------------------------------
# A SPEC rep's wrong answer. One line per scaffold rather than two values,
# because there is no value: what the answer produced is a verdict per machine
# and the grade is whether the verdicts line up with the key.
#
# EVERY SCAFFOLD IS SHOWN, not only the ones that disagreed. A battery exists
# because one run cannot tell a weaker property from the one asked for, so the
# run that AGREED is half the lesson: it says the answer did hold where it was
# meant to, and the next line says where it did not.
#
# THE SCAFFOLD'S OWN ENGLISH LINE LEADS, so a learner reads about a lift that
# stops at the second floor rather than about a file called prop-settle.
# ---------------------------------------------------------------------------
if [ "$KIND" = "SPEC" ]; then
  if [ "${#SPEC_RCS[@]}" -eq 1 ]; then
    echo "not correct. this is what the spec it is checked against made of it."
  else
    printf 'not correct. this is what each of the %s specs made of it.\n' "${#SPEC_RCS[@]}"
  fi
  for spec_i in "${!SPEC_RCS[@]}"; do
    echo
    show_prose "$(spec_about "${SPEC_NAMES[spec_i]}")"
    if [ "${SPEC_RCS[spec_i]}" = "${SPEC_WANT[spec_i]}" ]; then
      printf '    as wanted: rc %s %s\n' "${SPEC_RCS[spec_i]}" "${SPEC_TOKENS[spec_i]}"
    else
      printf '    wanted rc %s %s, and it came back rc %s %s\n' \
        "${SPEC_WANT[spec_i]}" "$(verdict_token "${SPEC_WANT[spec_i]}")" \
        "${SPEC_RCS[spec_i]}" "${SPEC_TOKENS[spec_i]}"
    fi
  done
  echo
  printf 'the answer is:\n'
  show_prose "$CANON"
  show_misconception "$REP_ID"
  show_sheet "$CONSTRUCT"
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
