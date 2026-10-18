#!/usr/bin/env bash
# recall-gate.sh: the six checks over the recall rep corpus (beads tla-1sh7.4
# and tla-03ep.1, epics tla-1sh7 and tla-i7uz).
#
# WHY THIS EXISTS. 120 reps and 30 miss rows landed on 2026-10-16 and nothing
# checked either table. recall/recall.sh answers one question per submission,
# "is this answer right", and has no opinion about whether a rep is a good
# rep. The shape is harness/completion-gate.sh's and the reasoning is its:
# a corpus whose only reader is a person is a corpus checked by a person.
#
# WHAT A RECALL REP IS. A need stated in English and the notation that answers
# it, graded on one exit code. recall/REPS.tsv carries one tab-delimited row
# per rep, and FIELD 1 IS WHICH KIND:
#
#   REP   an id, a construct id that is a drill/INVENTORY.md row, an
#         environment name resolving to <root>/env/<name>.tla, the English
#         prompt, the canonical answer, and an optional field 7 holding an ERE
#         the raw answer must match. The grade is value equality
#   SPEC   the same first three, then a comma-separated SCAFFOLD list in field
#         4, the prompt, the canonical, the same optional field 7, a
#         comma-separated vector of expected exit codes in field 8, and an
#         optional field 9 filling a scaffold's `__CHECK__` hole. Each
#         scaffold resolves to a PAIR, <root>/env/spec/<name>.tla and
#         <root>/env/spec/<name>.cfg. The grade is whether the vector of
#         codes TLC returns is the vector field 8 names
#
# recall/MISSES.tsv carries one MISS row per recorded wrong answer, against
# either kind: a rep id, the wrong answer verbatim, and what that answer says.
#
# ===========================================================================
# WHY THE SECOND ROW KIND NEEDED NEW GUARDS RATHER THAN WIDER ONES
#
# Every guard in this file read `$1 == "REP"` until 2026-10-17, so a SPEC row
# was INVISIBLE to all five checks rather than mishandled by them. The 40 rows
# that landed with bead tla-03ep.1 would have been ungated in a file whose
# whole point is that a corpus nobody checks is a corpus nobody checks.
#
# WIDENING THE GUARD TO `$1 ~ /REP|SPEC/` WOULD HAVE BEEN WORSE THAN LEAVING
# IT, because four of the five checks ask a question whose ANSWER DIFFERS BY
# KIND and would then have been answered wrongly in silence:
#
#   check 1  a REP row's canonical scores rc 0 because the scaffold compares
#            it against itself. A SPEC row's scores 0 because the exit codes
#            matched a vector written down SEPARATELY. See below: that makes
#            the spec arm of check 1 strictly stronger
#   check 2  a REP row's wrong answer scores rc 10. A SPEC row's scores rc 5,
#            the runner's own code for a vector that did not match. A widened
#            check 2 would call all 60 spec misses "not wrong"
#   check 4  field 4 resolves to one file for a REP row and to two files per
#            comma-separated name for a SPEC row, and fields 8 and 9 do not
#            exist on a REP row at all
#   check 6  is new, and nothing in the REP corpus has a scaffold to check
#
# Only check 5 asks one question of both kinds, because a prompt is a prompt.
#
# ===========================================================================
# WHAT THE SPEC ARM OF CHECK 1 IS WORTH, WHICH IS MORE THAN THE REP ARM
#
# CHECK 1 below opens by saying what it cannot do: a REP row's canonical is
# submitted AGAINST ITSELF, so a row that scores 0 has proved its canonical
# parses and evaluates and NOTHING about whether it answers field 5.
#
# A SPEC ROW HAS NO SELF-GRADING FORM. The canonical goes into a scaffold
# whose other half is a declared expected code, and field 8 was written by
# reading what TLC returned rather than by copying field 6. So `0` in field 8
# is an independent claim -- this formula HOLDS on this machine -- and a
# canonical that answers a different question than field 5 describes will
# usually fail it. The claim is still not that the rep is a good rep; the
# claim is that the canonical does what field 8 says it does, which is one
# step past "it parses".
#
# IT IS NOT A CORRECTNESS CHECK EITHER, and the gap is narrower rather than
# closed. A battery of one scaffold expecting 0 is satisfied by anything that
# holds on that machine, which is why all eight fairness rows carry a field 7
# and why the property rows carry two to four scaffolds.
#
# USAGE
#   harness/recall-gate.sh [OPTIONS] <recall-root>
#
# OPTIONS
#   --inventory FILE  the construct inventory check 3 resolves against
#                     (default: <repo>/drill/INVENTORY.md)
#   --no-tlc          skip checks 1 and 2's TLC runs. Checks 3, 4 and 5 still
#                     run. This mode can NEVER exit 0. See EXIT CODES.
#   --static-only     run checks 3, 4 and 5, and no TLC at all. A clean run
#                     exits 0. See THE TWO TIERS below for why this is not
#                     --no-tlc.
#   -q, --quiet       suppress the per-check OK lines, findings still print
#   -h, --help        this text
#
# THERE IS NO --timeout, AND THAT IS NOT AN OMISSION. Checks 1 and 2 go
# through recall/recall.sh rather than through harness/verdict.sh directly,
# and the runner carries a fixed 60-second budget with no flag in front of it
# (recall/recall.sh, TIMEOUT). A flag here would have nothing to pass it to,
# so it would be a knob that reports success while changing nothing. If the
# runner ever grows one, this gate can forward it.
#
# ===========================================================================
# THE TWO TIERS. Two questions, and the second is not a volume knob on the
# first. The shape is harness/completion-gate.sh's and the reasoning is its.
#
#   --static-only   is the corpus STRUCTURALLY sound?       clean run -> 0
#   (unflagged)     does every row still grade as it says?  clean run -> 0
#   --no-tlc        I asked you to measure and you did not.    always 99
#
# `--no-tlc` means the gate was asked whether every row still grades and did
# not find out, so it carries that forward as CHECK_DID_NOT_RUN and can never
# report success. `--static-only` means it was asked for the static checks
# ONLY, and a clean run answers that question completely, so it exits 0 and
# STATES the count it did not measure, because a mode that exits 0 without
# saying what it left out is the defect this distinction exists to avoid.
#
# Passing both is a usage error. Two different questions, two different exit
# codes, and the gate will not guess which one was meant.
#
# OUTPUT. Two machine-readable line shapes, then a human block.
#   FINDING   <code> <subject> <detail>     a defect. Exits 1.
#   UNCHECKED <check> <subject> <detail>    a check that could not run. 99.
#
# THERE IS NO WAIVER LINE HERE, unlike harness/drill-gate.sh and
# harness/completion-gate.sh, and the reason is that there is nowhere to put
# one. Both of those gates read a per-item META.md, which is a file with room
# in it for an argument. A rep is a row in a shared TSV with six fields and no
# room for a seventh that is prose. So check 5's token set has to be one no
# legitimate prompt trips, rather than one with an escape hatch, and the
# measurement under CHECK 5 is what that claim rests on. A row that genuinely
# needs an exemption is a reason to reopen the token set, not to add a column.
#
# EXIT CODES, the same three this project uses everywhere.
#     0  every check THIS RUN ASKED FOR ran and passed
#     1  at least one FINDING. Findings outrank unchecked
#    99  no findings, but at least one check COULD NOT RUN. The project-wide
#        CHECK_DID_NOT_RUN code (harness/verdict.sh, bead tla-hl96)
#     2  usage error
#
# THE CHECKS RUN IN DEPENDENCY ORDER, NOT IN THE ORDER THEY ARE NUMBERED.
# The numbers are the bead's and they are kept, because the bead, this header
# and the suite all have to name the same six things. The ORDER is 3, 4, 6, 5,
# then 1 and 2, for the reason harness/reading-gate.sh checks its .cfg
# obligation before its rc reproduces: a missing environment file makes every
# row of check 1 come back rc 3, and 160 identical "could not run" lines say
# nothing that check 4's one line did not already say better. Check 6 joins
# that group because a scaffold with no `__ANSWER__` hole grades every answer
# to every rep over it identically, and saying so once beats saying it per
# row.
#
# ===========================================================================
# CHECK 1. EVERY CANONICAL ANSWER SCORES rc 0 THROUGH THE RUNNER.
#
# WHAT THIS CHECK CANNOT DO, STATED FIRST SO NOBODY READS PAST IT.
#
# It submits each canonical answer AGAINST ITSELF. The grading scaffold is
# `ASSUME Answer = Canonical` with both sides filled from the same field 6, so
# a row that scores 0 has proved its canonical PARSES and EVALUATES against its
# environment, and NOTHING AT ALL about whether it computes what field 5
# describes. An expression can be flawless TLA+ and answer a different
# question, and this check passes it.
#
# THE CORRECTNESS PROPERTY IS OUT OF SCOPE HERE, DELIBERATELY, AND IT WAS
# VERIFIED ONCE BY HAND. Gating it needs a predicted-value column in
# recall/REPS.tsv written INDEPENDENTLY of field 6, which the gate would then
# compare against. That column does not exist. The bead that authored the
# table ran the pass instead: the tla-1sh7.2 worker evaluated every rep against
# a value it had written down before looking at the canonical, and recorded
# agreed=120, disagreed=0, at commit 552f09e. So the property is true of the
# corpus as it stood that day and nothing re-establishes it after an edit.
#
# A READER WHO ASSUMES THIS GATE COVERS CORRECTNESS IS WRONG, and that
# assumption is exactly what the bead's own first RED line invited. It read
# "every row scores rc 0 when its canonical answer is submitted through
# recall/recall.sh", which can only ever prove the canonical parses. The line
# is not copied here. What is written instead is this paragraph.
#
# WHAT CHECK 1 IS WORTH, which is not nothing. Six defect classes it catches
# and a reading pass would not:
#
#   - a canonical that does not parse                            rc 150
#   - a canonical naming something the environment never defines rc 150
#   - an environment that defines one of the three reserved names
#     (Answer, Canonical, Shown), which makes EVERY rep over that
#     environment fail to parse with a SANY multiple-declaration  rc 150
#   - a canonical its own field 7 refuses, so every correct answer
#     to that rep is turned away at the construct gate            rc 4
#   - a canonical whose value is not the value of itself, which is
#     what a non-deterministic or TLC-unevaluable expression does  rc 10
#   - a regression in recall.sh, verdict.sh or the scaffold that
#     stops the channel grading anything                     rc 2, 3, other
#
# HOW IT RUNS. One `recall.sh -q` per row. Quiet mode exits straight after the
# status line, so a wrong answer costs ONE TLC run rather than three: the two
# value probes live below the quiet exit (recall/recall.sh, the QUIET branch).
# At 120 rows and about 0.32 s a grading run that is the whole of this check's
# cost.
#
# ===========================================================================
# CHECK 2. EVERY MISS ROW'S WRONG ANSWER SCORES ITS ROW KIND'S WRONG-ANSWER
# CODE AGAINST ITS OWN REP: rc 10 FOR A REP ROW, rc 5 FOR A SPEC ROW.
#
# Checks 1 and 2 together are the mutation bar applied to this channel. A
# canonical that scores anything but 0 is wrong, and a miss that scores 0 is
# not a miss. It is a correct form of the answer with an explanation attached
# saying it is a mistake, which is the worst thing this table can hold.
#
# THE EXPECTED CODE IS LOOKED UP FROM THE REP, NOT FROM THE MISS ROW, which is
# why the miss table needs no field for it. A MISS row names a rep id and this
# check reads that rep's field 1.
#
# rc 5 HOLDS ONE THING AND THAT IS WHY THE SPEC ARM IS TIGHTER THAN THE REP
# ARM. It means every scaffold ran, every code it returned was in the set
# recall/recall.sh calls gradeable, and at least one disagreed with field 8.
# A spec miss that blew TLC up instead comes back 75, 151 or 255 and is
# reported as MISS-NOT-GRADED, because a sentence about an idea attached to a
# run that fell over is the same defect rc 150 already names on the value rung.
#
# rc 10 HOLDS THREE DIFFERENT THINGS AND THE NUMBER ALONE CANNOT TELL THEM
# APART. This is worth knowing before anybody reads a green run as "all 30
# rows are ordinary wrong answers":
#
#   1  an ordinary wrong answer. ASSUME Answer = Canonical came back FALSE
#      because the two values differ. A type mismatch is in this band too:
#      `7` against a set of functions is simply false, not an error.
#   2  a CASE with no true arm. TLC reports "Attempted to evaluate a CASE
#      with no conditions true", which is an EVALUATION FAILURE inside the
#      ASSUME and surfaces as rc 10 ASSUMPTION_FAILED, not as a code of its
#      own.
#   3  a non-function applied as a function. An EXCEPT whose `@` is indexed
#      gives "A non-function (an integer) was applied as a function", again
#      rc 10.
#
# Both measurements are the tla-1sh7.3 worker's, taken on two live rows on
# 2026-10-16. So the band holds misconceptions that produce a WRONG VALUE and
# misconceptions that produce NO VALUE AT ALL. For this rung that is the right
# place to draw the line, because both are a wrong answer from the learner's
# side and both get the same two-value block. It is stated here rather than
# left to be rediscovered, because the gate keys on the number.
#
# WHAT THE OTHER CODES MEAN WHEN A MISS ROW SCORES ONE:
#   0    the row's field 3 is a CORRECT form. The explanation under it is a
#        statement that a right answer is wrong.                MISS-NOT-WRONG
#   150  it never parsed, so nothing was graded and field 4 is a sentence
#        about text rather than about an idea.                  MISS-NOT-GRADED
#   3    the rep id in field 2 is not a row of the rep table.   MISS-NO-REP
#   4    the construct gate refused it, which means the value was RIGHT and
#        field 7 turned it away. Reported as MISS-NOT-WRONG, because the miss
#        table is about wrong values and this one is not wrong.
#
# ===========================================================================
# CHECK 3. EVERY CONSTRUCT ID RESOLVES TO A drill/INVENTORY.md ROW.
#
# Field 3 is the join between this corpus and the construct inventory, and it
# is also the key drill/SHEET.md is read on, so an id that resolves to no row
# costs the learner the sheet entry at the bottom of every wrong answer to
# that rep. The inventory is the authority on which ids exist: 105 ROW lines,
# K001 to K105.
#
# THE SHEET IS NOT CHECKED HERE and that is not a hole. harness/test-recall-
# runner.sh part 13 already asserts that every construct in the rep table has
# a drill/SHEET.md entry, over the real shipped files. Two gates asserting one
# property is how they drift apart.
#
# ===========================================================================
# CHECK 4. EVERY ROW CAN BE SUBMITTED AT ALL.
#
# The bead names the first of these three. The other two are the same
# question asked of field 7, and they are here because they are static,
# because they cost nothing, and because --static-only would otherwise answer
# "is the corpus structurally sound" while leaving a row that no answer can
# ever pass.
#
#   ENV-MISSING       the environment in field 4 resolves to no file under
#                     <root>/env/, so every submission to the rep is rc 3
#   ROW-BAD-SHAPE     fewer than six tab-separated fields, or an empty field
#                     where the runner requires one
#   ROW-DUPLICATE-ID  two REP rows share an id. The runner's lookup takes the
#                     first and exits, so the second row is unreachable: it
#                     can never be graded, and nothing else would ever say so
#   REQUIRES-UNREADABLE          field 7 is not an ERE grep will read, so
#                                every submission to that rep dies at rc 3
#   REQUIRES-REFUSES-CANONICAL   field 7 does not match the row's own
#                                canonical, so the rep's own answer is turned
#                                away at rc 4 and no correct answer can score 0
#
# THE LAST TWO WERE VACUOUS WHEN THEY WERE WRITTEN AND THAT WAS THE POINT.
# Measured 2026-10-16: all 120 REP rows carried exactly six fields, so no row
# had a field 7 at all. They were here for the row that lands tomorrow, which
# is the same posture harness/test-pipefail.sh takes when it selects files by
# shebang from the tree rather than from a list. The row landed: all 40 SPEC
# rows carry a field 7, so both checks now have a subject.
#
# FOUR MORE, AND ALL FOUR ARE SPEC-ONLY, because a REP row has no field 8:
#
#   SCAFFOLD-MISSING    a name in field 4 resolves to no .tla or to no .cfg
#                       under <root>/env/spec/, so every submission is rc 3
#   EXPECT-BAD          field 8 is empty, holds something that is not an exit
#                       code, or has a different number of entries from field
#                       4. A short vector compared against a long one position
#                       by position is a grade read off a run that never
#                       happened
#   CHECK-MISSING       a scaffold the row names has a `__CHECK__` hole and
#                       field 9 is empty, so the hole fills with nothing and
#                       the scaffold does not parse
#   CHECK-UNUSED        field 9 is set and NO scaffold the row names has a
#                       `__CHECK__` hole, so the text is carried, delivered
#                       and never read. The direction matters: this one is
#                       dead weight rather than a broken rep, and it is a
#                       finding because a fingerprint silently going nowhere
#                       is how a rep stops discriminating
#
# ===========================================================================
# CHECK 5. NO PROMPT CONTAINS THE NOTATION IT IS ASKING FOR.
#
# This is the check that keeps a rep from being a transcription exercise, and
# it is harness/drill-gate.sh's layer B narrowed to one row at a time, the way
# harness/completion-gate.sh's check 3 narrows it. The rep table's own header
# states the rule it enforces: "FIELD 5 IS THE FIELD THAT DECIDES WHETHER A
# REP IS A REP. It states a need and names none of the notation that answers
# it." "The set of all the ways the wagons could be parked" asks for recall.
# "Write a function set" hands the construct over.
#
# PER ROW, NOT PER CORPUS. The token set is intersected with THIS ROW'S
# CANONICAL first, so a prompt is only ever flagged for notation its own
# answer uses. A prompt that happens to contain a token no answer of its own
# needs is not telegraphing anything.
#
# THE TOKEN SET IS WIDER THAN drill-gate.sh's DISTINCTIVE, AND THE WIDENING IS
# THE WHOLE DIFFERENCE BETWEEN THE TWO CORPORA. drill-gate.sh excludes the
# shared vocabulary (`/\ \/ \in \A \E =>`, LET IN IF THEN ELSE, DOMAIN, the
# sequence operators) because a drill prompt is ALLOWED TO SHOW A SPEC and
# ask for the missing piece, so flagging those would fail every item of that
# shape. A recall prompt shows nothing. It is one sentence of English, and any
# TLA+ at all in it is the give-away. So the exclusion list is not inherited:
# its reason does not hold here.
#
# MEASURED BEFORE IT WAS WRITTEN DOWN, over all 120 live rows on 2026-10-16:
# the set below fires on ZERO prompts. That is what the claim "no legitimate
# prompt trips this" rests on, and it is the measurement to re-take rather
# than the sentence to re-read if a row ever fires.
#
# FOUR THINGS IN THE SET ARE NOT WHAT THEY LOOK LIKE, and a reader who skips
# this paragraph will misread the list:
#
#   `[]` and `<>` are inherited from DISTINCTIVE as the temporal operators.
#   In THIS corpus they reach `<<>>`, the empty sequence (R040, R051), and the
#   CASE arm separator (R047, R048). Harmless either way, since no prompt
#   carries them, but they are not doing the job they were added for.
#
#   `\subseteq` contains `\subset`, `|->` contains `->`, and `<=>` contains
#   `=`. The redundancy is deliberate: a per-row intersection means the
#   narrower token simply fires on the same row, and dropping one to look tidy
#   would uncover the rows that use only the other form.
#
# THREE THINGS ARE EXCLUDED ON PURPOSE:
#
#   `'`  the prime. drill-gate.sh excludes it because it is an apostrophe in
#        English prose, and that reason holds here with a number on it: 14 of
#        the 120 prompts carry an apostrophe ("the yard's capacity") and ZERO
#        canonicals carry a prime, which is what a value rung with no actions
#        in it looks like.
#   `-`  the minus sign, which is a hyphen in prose.
#   `..` IS INCLUDED, and the hazard is named here rather than discovered: an
#        ellipsis in a prompt contains it. Zero prompts carry one today. If a
#        row ever fires on `..`, read the prompt before reaching for the set.
#
# WHAT THIS CHECK DOES NOT REACH, and these are holes rather than caveats:
#   - ENGLISH PARAPHRASE. "the set of all functions from wagons to tracks"
#     names no notation and hands over the construct completely. Only a reader
#     catches that. drill-gate.sh calls this the largest deliberate hole in
#     its own check 1 and it is the same hole here.
#   - A CONSTRUCT WITH NO SYMBOL. "Operator definition" has no token to scan
#     for, so K001's three reps are outside this check's reach exactly as they
#     are outside drill-gate.sh's layer A.
#   - THE MISS EXPLANATIONS. Field 4 of a miss row is printed UNDER both
#     values, so the right answer is already on screen before it speaks and
#     there is nothing left to telegraph.
#   - THE SCAFFOLD'S OWN FIRST LINE. A spec rep prints it on a wrong answer,
#     and it describes the MACHINE rather than the answer: "a goods lift
#     standing beside a lamp" tells a reader what they are reasoning about and
#     not what to write. It is also printed after the grade, like a miss row.
#
# THIS CHECK IS THE ONE THAT ASKS BOTH ROW KINDS THE SAME QUESTION, so it
# carries no per-kind arm. The per-row intersection does the work: the token
# set includes `[]`, `<>`, `~>`, `]_`, `WF_`, `SF_`, `ENABLED`, `UNCHANGED`,
# `'` is deliberately absent, and a spec prompt is only flagged for a token
# its own canonical uses. Measured over the 40 SPEC rows on 2026-10-17: zero
# fire, which is the same measurement the 120 REP rows got and the same thing
# to re-take rather than re-read if one ever does.
#
# TWO TOKENS IN THE SET ARE DOING THE JOB THEY WERE ADDED FOR AT LAST. The
# note above CHECK 5's token list says `[]` and `<>` were inherited from
# harness/drill-gate.sh as the temporal operators and in the value corpus
# reach only `<<>>` and a CASE arm separator. In the spec corpus they reach
# the temporal operators, which is what they were for.
#
# ===========================================================================
# CHECK 6. EVERY SCAFFOLD IS WELL FORMED, AND EVERY SCAFFOLD IS USED.
#
# A scaffold is the half of a spec rep that is not in the table, so nothing in
# checks 1 to 5 reads one. Four defects, and the first two make a rep grade
# every answer identically rather than grading it wrongly:
#
#   SCAFFOLD-NO-HOLE    no line whose trimmed text is `__ANSWER__`, so the
#                       answer is dropped on the floor and every submission
#                       to every rep over that scaffold scores the same
#   SCAFFOLD-TWO-HOLES  more than one `__ANSWER__` line, or more than one
#                       `__CHECK__` line. The runner fills every one it
#                       finds, which is legal TLA+ about as often as not and
#                       is never what an author meant
#   SCAFFOLD-BAD-SHAPE  not a whole module: no `---- MODULE Scaffold ----`
#                       header, or no closing `====`, or a first line that is
#                       not a `\*` comment. The header has to read `Scaffold`
#                       because the runner copies the file to Scaffold.tla and
#                       rewrites nothing, and the first line has to be a
#                       comment because the runner prints it to a learner
#   SCAFFOLD-ORPHAN     a .tla under env/spec/ that no SPEC row names. It is
#                       delivered to every practice tree and read by nothing
#
# THE ORPHAN CHECK RUNS OVER THE TREE RATHER THAN OVER A LIST, so a scaffold
# added tomorrow is covered the moment it lands, and a rep deleted without its
# scaffold shows up here rather than in a delivery that quietly grew.
#
# ===========================================================================
# ONE CHECK THAT IS DELIBERATELY NOT HERE, AND THE MEASUREMENT THAT KILLED IT
#
# "No miss explanation names a module or a variable from the drill verify
# tree" is the obvious sixth check, and recall/MISSES.tsv's own header says
# the rows were rewritten to satisfy it. The obvious way to build it is a
# whole-word match against the module basenames under drill/*/*/verify/ plus
# every declared VARIABLE name in them.
#
# THE tla-1sh7.3 WORKER BUILT THAT LIST AND RAN IT. Eight hits, every one an
# ordinary English word that happens to be declared somewhere in the tree:
#
#   a, b     drill/core/08-altimeter-approx/verify/Altimeters.tla
#   at       drill/functions-records/02-charging-bays/verify/BaysVanSide.tla
#   holds    drill/functions-records/05-tool-crib/verify/ToolCribByWorker.tla
#   level    drill/functions-records/03-ballast-tanks/verify/Ballast.tla
#   occupied drill/modules/03-the-bank-that-vouched/verify/PostOffice.tla
#   taken    drill/sequences/07-pneumatic-tube/verify/TubeDerived.tla
#   where    drill/sets/02-two-pools/verify/PoolsWhere.tla
#
# No wording survives a matcher that includes "a", "at" and "where". The names
# that actually matter came back with zero hits already: pos, out, unit, cover,
# board, line. So the check as stated would be 100% false positives and would
# flag nothing real.
#
# WHAT A WORKING VERSION WOULD MATCH is module basenames and multi-character
# identifiers that are not English words, which needs a word list this repo
# does not have, and is its own bead rather than a paragraph of this one. It
# is recorded here so the next author does not rebuild the matcher that was
# already measured and rejected.
#
# ===========================================================================
# WHAT THIS GATE DELIBERATELY DOES NOT DO
#
# NO CORRECTNESS CHECK. See CHECK 1 above, which is the longest section of
# this header for that reason.
#
# NO COVERAGE REPORT. 57 of the inventory's 105 constructs have a rep and 48
# do not, and nothing here has an opinion about which. K008 is deliberately
# absent and recall/REPS.tsv's own footer says why. harness/test-coverage-map.sh
# is the instrument for coverage questions.
#
# NO OPINION ABOUT WHETHER A BATTERY DISCRIMINATES. A SPEC row naming one
# scaffold and expecting 0 passes check 4 and check 1 and is satisfied by
# anything that holds on that machine. Nothing static can tell a battery that
# separates the canonical from its near neighbors from one that does not;
# what can is a wrong answer in recall/MISSES.tsv, which check 2 runs. So the
# density of the miss table IS the discrimination check, and it is reported
# rather than required.
#
# NO EXPLANATION QUALITY CHECK. Field 4 is taken at its word, exactly as
# META.md is by harness/drill-gate.sh's check 3.
#
# NO PROSE BUDGET. harness/test-recall-runner.sh already refuses a miss
# explanation or a sheet body that wraps past three lines, over the real
# files. Two gates asserting one property is how they drift apart.
#
# ===========================================================================
# CLOSED 2026-10-17: THIS INSTRUMENT IS IN harness/test-indeterminate.sh's
# REGISTRY NOW, and the section below is kept as the record of what was wrong
# and what fixed it rather than deleted.
#
# The patch at the bottom was applied: `QGATE="harness/recall-gate.sh"` sits
# beside its seven siblings in that suite's REGISTERED array at line 224, and
# the two rows run at lines 704 and 714. Re-measured 2026-10-17:
# `harness/test-indeterminate.sh` reads 95 assertions passed, rc 0, and its
# census row reports `recall-gate.sh: 2 row(s), 1 of them non-pass`.
#
# WHAT IS LEFT TO SAY. One of those two rows names a count in its label --
# "was asked to grade 120 reps and did not" -- and the rep table carries 160
# rows now. The label is prose rather than an assertion, so the suite is
# green either way, and the count is a sentence somebody will read as current.
# harness/test-indeterminate.sh is not in bead tla-03ep.1's footprint, so it
# is reported rather than edited. The section below is the original record.
#
# ---------------------------------------------------------------------------
# WAS: THIS INSTRUMENT IS NOT IN harness/test-indeterminate.sh's
# REGISTRY, AND THAT SUITE IS RED UNTIL IT IS.
#
# Its part 2 census selects every `harness/*.sh` that is not a test suite FROM
# THE TREE, so this file was covered the moment it landed. An instrument that
# can admit a skip has to be driven by a row of that suite, or its rc-0 skip
# admission is a success code carrying an admission nobody checks.
#
# MEASURED 2026-10-16, AND THE DIRECTION MATTERS. With this file moved aside,
# `harness/test-indeterminate.sh` reads 85 assertions passed, rc 0. With it in
# the tree, 84 passed and 1 failed, on one assertion:
#
#   FAIL  UNREGISTERED instrument(s) can admit a skip
#   harness/recall-gate.sh
#
# So the suite was GREEN on main and this file turned it red. That is not the
# state harness/completion-gate.sh's own header records for itself, where the
# suite was already red when that bead landed, and the difference is why this
# section carries the patch rather than only the problem.
#
# WHY IT IS NOT APPLIED HERE. Bead tla-1sh7.4 declares four files and
# `harness/test-indeterminate.sh` is not among them. The four admissions the
# census reaches are all honest and none should be reworded to quiet it, which
# is the rule harness/completion-gate.sh's own OUTSTANDING block states. One
# admission WAS reworded, and for the opposite reason: the MISS-NO-REP finding
# read "the runner could not run this row at all at rc 3", which matched
# SKIP_VOCAB while being a FINDING rather than a skip. It now reads "refused",
# which is both true and not an admission.
#
# THE PATCH, AND EVERY ASSERTION IN IT WAS RUN AGAINST THIS FILE BEFORE IT WAS
# WRITTEN DOWN. Add the instrument beside its six siblings:
#
#   QGATE="harness/recall-gate.sh"
#   REGISTERED=(... "$KGATE" "$QGATE")
#
# and two rows next to the completion gate's, which are the shape this
# instrument copies. Measured: `--no-tlc -q recall` returns 99 and carries
# both strings, `--static-only -q recall` returns 0 and carries both of its
# own, and neither claims OK.
#
#   run_row "$QGATE" "recall-gate.sh: --no-tlc was asked to grade 120 canonicals and did not" \
#     "$INDETERMINATE" -- \
#     bash "$QGATE" --no-tlc -q recall
#   assert_out "the recall gate names the check it did not run" "UNCHECKED every-canonical-scores-0"
#   assert_out "the recall gate reports the reserved token" "VERDICT $TOKEN"
#   assert_not_out "the recall gate does not claim OK over it" "VERDICT OK"
#
#   run_row "$QGATE" "recall-gate.sh: --static-only is a caller instruction, not a failure" \
#     0 -- \
#     bash "$QGATE" --static-only -q recall
#   assert_out "the static-only admission and its waiving flag are on one line" \
#     "were skipped (--static-only)"
#   assert_out "the static-only run still states what it did not measure" \
#     "whose grading was not measured"
#
# Both rows are cheap: neither starts a JVM, so the registration costs that
# suite about a second.
# ===========================================================================

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------------------
# TELEGRAPH_TOKENS. Check 5's token set. Read CHECK 5 above before changing
# it. Every line below is measured rather than reasoned.
#
# Rows 1 to 5 are harness/drill-gate.sh:305-311's DISTINCTIVE set VERBATIM, so
# the project has one floor rather than two.
# ---------------------------------------------------------------------------
TELEGRAPH_TOKENS=(
  '~>' '<>' '[]' ']_' 'WF_' 'SF_' 'ENABLED'
  'UNCHANGED' 'CHOOSE' 'SUBSET' 'UNION' 'EXCEPT' 'INSTANCE' 'RECURSIVE'
  '|->' ':>' '@@' 'LAMBDA'
  'Cardinality' 'Permutations' 'SelectSeq' 'TLCGet' 'Assert'
  '\X' '\o' '\cup' '\cap' '\subseteq' '\notin'

  # The widening. Every one of these is shared vocabulary a DRILL prompt may
  # legitimately show and a RECALL prompt may not, because a recall prompt
  # shows no spec. See CHECK 5.
  # $'/\\' rather than '/\': both are the two bytes /\ , proven against a
  # running shell, but the single-quoted form raises SC1003 because \' reads
  # as an attempted quote escape. The spelling and the reason are
  # harness/drill-gate.sh:334-337's, so the project carries one idiom here
  # rather than two.
  $'/\\' '\/' '\in' '\A' '\E' '=>' '<=>' '~'
  '\union' '\intersect' '\subset' '\div' '\leq' '\geq'
  'LET' 'IN' 'IF' 'THEN' 'ELSE' 'CASE' 'OTHER' 'DOMAIN' 'TRUE' 'FALSE'
  'Len' 'Append' 'Head' 'Tail' 'SubSeq' 'Seq' 'Nat' 'Int' 'BOOLEAN'
  '->' '..' '#' '/=' '=' '{' '}' '<<' '>>' '%' '^'
)

INVENTORY="${REPO_ROOT}/drill/INVENTORY.md"
NO_TLC=0
STATIC_ONLY=0
QUIET=0
ROOT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --inventory)
      if [ "$#" -lt 2 ]; then
        echo "recall-gate.sh: --inventory wants a file" >&2
        exit 2
      fi
      INVENTORY="$2"
      shift
      ;;
    --no-tlc)      NO_TLC=1 ;;
    --static-only) STATIC_ONLY=1 ;;
    -q|--quiet)    QUIET=1 ;;
    -h|--help)
      awk 'NR > 1 && /^set -uo pipefail$/ { exit } NR > 1' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "recall-gate.sh: unknown option '$1' (try --help)" >&2
      exit 2
      ;;
    *)
      if [ -n "$ROOT" ]; then
        echo "recall-gate.sh: more than one recall root given ('$ROOT', '$1')" >&2
        exit 2
      fi
      ROOT="$1"
      ;;
  esac
  shift
done

if [ -z "$ROOT" ]; then
  echo "recall-gate.sh: no recall root given (try --help)" >&2
  exit 2
fi
if [ ! -d "$ROOT" ]; then
  echo "recall-gate.sh: '$ROOT' is not a directory" >&2
  exit 2
fi

# Two different questions with two different exit codes. See THE TWO TIERS.
if [ "$NO_TLC" = "1" ] && [ "$STATIC_ONLY" = "1" ]; then
  echo "recall-gate.sh: --no-tlc and --static-only are different questions with different exit codes. Pass one" >&2
  exit 2
fi

RUN_TLC=1
if [ "$NO_TLC" = "1" ] || [ "$STATIC_ONLY" = "1" ]; then
  RUN_TLC=0
fi

RUNNER="${ROOT}/recall.sh"
REPS="${ROOT}/REPS.tsv"
MISSES="${ROOT}/MISSES.tsv"
ENV_DIR="${ROOT}/env"
SPEC_DIR="${ENV_DIR}/spec"

# The wrong-answer code of each row kind, which is what check 2 looks up per
# MISS row rather than taking from the row. Read recall/recall.sh's EXIT
# section before changing either: 10 is TLC's ASSUMPTION_FAILED and 5 is the
# runner's own code for a vector that did not match.
WRONG_RC_REP=10
WRONG_RC_SPEC=5

if [ ! -x "$RUNNER" ] && [ "$RUN_TLC" = "1" ]; then
  echo "recall-gate.sh: ${RUNNER} is missing or not executable." >&2
  echo "  Checks 1 and 2 could not run. Pass --no-tlc to say so deliberately." >&2
  exit 2
fi

finding_n=0
unchecked_n=0
rep_n=0
spec_n=0
miss_n=0
scaffold_n=0

say()       { [ "$QUIET" = "1" ] || printf '%s\n' "$1"; }
finding()   { printf 'FINDING   %-28s %-10s %s\n' "$1" "$2" "$3"; finding_n=$((finding_n + 1)); }
unchecked() { printf 'UNCHECKED %-28s %-10s %s\n' "$1" "$2" "$3"; unchecked_n=$((unchecked_n + 1)); }

# ---------------------------------------------------------------------------
# token_shown <token> <text>: does the text use this operator?
#
# A token made only of word characters matches on a WORD BOUNDARY. Anything
# with a symbol in it matches as a substring. Lifted unchanged from
# harness/completion-gate.sh, which lifted the boundary from
# harness/drill-gate.sh's rc reader, where a module called Commit picked up the
# prose word "Committed".
#
# THE BOUNDARY IDIOM `(^|[^class])TOKEN` IS THE ONE .claude/rules/dispatched-
# agents.md records as LYING under the Bash tool's ugrep wrapper, which
# returned 0 where GNU returned 6. It is correct here because this file carries
# a bash shebang and gets GNU grep, which is the same ground every other gate
# in harness/ stands on. Do not re-run one of these lines interactively and
# believe the answer.
# ---------------------------------------------------------------------------
token_shown() {
  case "$1" in
    *[!A-Za-z0-9_]*) [[ "$2" == *"$1"* ]] ;;
    *) grep -qE "(^|[^A-Za-z0-9_])$1([^A-Za-z0-9_]|$)" <<<"$2" ;;
  esac
}

# ---------------------------------------------------------------------------
# grade <rep-id> <answer>: the runner's raw exit code, into GRADE_RC.
#
# `-q` so the runner exits on the status line. That is not only quieter, it is
# THREE TIMES CHEAPER on a wrong answer: the two value probes sit below the
# quiet exit in recall/recall.sh, so every row of checks 1 and 2 costs exactly
# one TLC run whatever it scores.
#
# The three table paths are passed explicitly so the gate drives the root it
# was handed rather than the runner's own shipped defaults. --misses changes
# nothing under -q, since nothing reads it before the exit. It is passed
# anyway because a gate that drives one file from the root and another from
# the repo is a gate whose green run means two different things.
#
# --sheet is NOT passed. drill/SHEET.md is outside the recall root by design,
# the runner reads it only on the non-quiet path, and check 3 resolves
# construct ids against the inventory instead.
# ---------------------------------------------------------------------------
GRADE_RC=0
grade() {
  GRADE_RC=0
  "$RUNNER" -q --reps "$REPS" --env-dir "$ENV_DIR" --misses "$MISSES" \
    "$1" "$2" >/dev/null 2>&1 || GRADE_RC=$?
}

echo "recall-gate.sh: ${ROOT}"

# ---------------------------------------------------------------------------
# The shape. Everything below reads these, so a missing one is reported once
# rather than 120 times.
# ---------------------------------------------------------------------------
if [ ! -f "$REPS" ]; then
  finding "SHAPE-NO-REPS" "$ROOT" "no REPS.tsv. It is the corpus, and every check below reads it"
  echo
  echo "recall-gate.sh: 0 rep(s), 0 miss row(s), ${finding_n} finding(s), 0 unchecked"
  echo "VERDICT FINDINGS"
  exit 1
fi
if [ ! -d "$ENV_DIR" ]; then
  finding "SHAPE-NO-ENV-DIR" "$ROOT" "no env/. Every rep names an environment that resolves under it"
fi

# ---------------------------------------------------------------------------
# Read the rep rows once.
#
# awk -F'\t' and cut, never `IFS=$'\t' read`. Tab is an IFS whitespace
# character, so read folds a run of tabs into one delimiter and drops a
# trailing empty field, which shifts every field after it without saying so.
# recall/REPS.tsv's own header says the same thing.
# ---------------------------------------------------------------------------
#
# ONE SET OF ARRAYS WITH A KINDS ARRAY, rather than two sets. Every check that
# asks one question of both kinds then reads one loop, and every check that
# asks a different question per kind branches on KINDS[i] where a reader can
# see it. Two parallel sets would have put the branch in the file layout,
# where a check added to one and not the other is invisible.
# The constructs a REP row must gate with a field-7 pattern, because value
# equality cannot see them. Read the long comment at REQUIRES-ABSENT in check 4
# before adding or removing one.
#
# KEYED ON THE INVENTORY'S CONSTRUCT NAME, NOT ON ITS ID, and that is not a
# style choice. A construct id means whatever the inventory passed to
# --inventory says it means. drill/INVENTORY.md reads `K001 core Operator
# definition`, and harness/test-recall-gate.sh's own fixture inventory reads
# `K001 sets Set literal`. An id list would have imposed the live corpus's
# meaning on every fixture that reuses an id, and the first thing it did was
# call the suite's own clean control a finding.
#
# A name list has its own rot surface: rename a construct in the inventory and
# the requirement quietly stops applying. So the check emits an UNCHECKED for
# any name here that resolves to no inventory row, which makes a rename loud
# rather than silent. One tab-delimited name per line, since the names contain
# spaces.
REQUIRES_PATTERN_NAMES='Operator definition
Booleans and logical operators
Implication
RECURSIVE
Higher-order operator parameter
LAMBDA
Custom binary operator
Bracket function definition
Recursive function definition'

IDS=()
KINDS=()
CONSTRUCTS=()
ENVS=()
PROMPTS=()
CANONS=()
REQUIRES=()
EXPECTS=()
CHECKS=()

while IFS= read -r row; do
  kind="$(cut -f1 <<<"$row")"
  case "$kind" in
    REP)  rep_n=$((rep_n + 1)) ;;
    SPEC) spec_n=$((spec_n + 1)) ;;
  esac
  KINDS+=("$kind")
  IDS+=("$(cut -f2 <<<"$row")")
  CONSTRUCTS+=("$(cut -f3 <<<"$row")")
  ENVS+=("$(cut -f4 <<<"$row")")
  PROMPTS+=("$(cut -f5 <<<"$row")")
  CANONS+=("$(cut -f6 <<<"$row")")
  # A six-field row has no field 7 and cut returns the empty string, which is
  # the same thing an empty field 7 says: no gate. The same holds of 8 and 9,
  # which only a SPEC row carries.
  REQUIRES+=("$(cut -f7 <<<"$row")")
  EXPECTS+=("$(cut -f8 <<<"$row")")
  CHECKS+=("$(cut -f9 <<<"$row")")
done < <(awk -F'\t' '$1 == "REP" || $1 == "SPEC"' "$REPS")

row_n=$((rep_n + spec_n))

if [ "$row_n" -eq 0 ]; then
  unchecked "reps" "$ROOT" "REPS.tsv holds no REP or SPEC row. A row is tab-delimited with one of those two literals in field 1"
fi

# ===========================================================================
# CHECK 3. every construct id resolves to an inventory row.
# ===========================================================================
if [ ! -f "$INVENTORY" ]; then
  unchecked "check-3" "$ROOT" \
    "no inventory at ${INVENTORY}, so no construct id was resolved. Pass --inventory"
else
  INV_IDS="$(awk -F'\t' '$1 == "ROW" { print $2 }' "$INVENTORY")"

  # id and name, tab-separated, for check 4's REQUIRES-ABSENT. Read here
  # because this is where the inventory is already open and already known to
  # exist, and check 4 must not re-decide that.
  INV_NAMES="$(awk -F'\t' '$1 == "ROW" { print $2 "\t" $4 }' "$INVENTORY")"
  TAB_CH="$(printf '\t')"

  # THE RENAME TRIPWIRE for REQUIRES_PATTERN_NAMES. A name list stops applying
  # the moment somebody renames a construct in the inventory, and it stops
  # applying SILENTLY, which is the one failure a gate must not have. So every
  # name in the list has to resolve to an inventory row. A name that does not
  # is UNCHECKED rather than a finding: the corpus is not wrong, this gate's
  # own list is out of date, and those are different reports.
  #
  # A TOTAL MISS IS A DIFFERENT INVENTORY, NOT A RENAME, and the difference
  # matters because this gate is driven over fixture trees as well as over the
  # shipped one. harness/test-recall-gate.sh builds its own inventory with four
  # rows, none of them named here, and an unconditional tripwire called that
  # fixture nine kinds of out of date on every run. So: if NONE of the names
  # resolve, this is some other inventory and the list has nothing to say about
  # it. If SOME resolve and others do not, that is drift in the inventory this
  # list was written against, and it is loud.
  req_hit=0
  req_miss=""
  while IFS= read -r want_name; do
    [ -n "$want_name" ] || continue
    if awk -F'\t' -v N="$want_name" '$1 == "ROW" && $4 == N { found = 1 } END { exit !found }' "$INVENTORY"; then
      req_hit=$((req_hit + 1))
    else
      req_miss="${req_miss}${want_name}
"
    fi
  done <<<"$REQUIRES_PATTERN_NAMES"

  if [ "$req_hit" -gt 0 ] && [ -n "$req_miss" ]; then
    while IFS= read -r gone_name; do
      [ -n "$gone_name" ] || continue
      unchecked "check-4-requires" "$gone_name" \
        "REQUIRES_PATTERN_NAMES names this construct, ${req_hit} of its siblings resolve in ${INVENTORY} and this one does not, so no row is being held to it. Either the construct was renamed or this gate's list is stale"
    done <<<"$req_miss"
  fi

  c3_ok=1
  for i in "${!IDS[@]}"; do
    k="${CONSTRUCTS[$i]}"
    if [ -z "$k" ]; then
      finding "CONSTRUCT-EMPTY" "${IDS[$i]}" \
        "field 3 is empty, so the rep joins to no inventory row and reaches no sheet entry"
      c3_ok=0
      continue
    fi
    if ! grep -qxF -- "$k" <<<"$INV_IDS"; then
      finding "CONSTRUCT-NOT-IN-INVENTORY" "${IDS[$i]}" \
        "field 3 is '${k}', and ${INVENTORY} carries no ROW with that id"
      c3_ok=0
    fi
  done
  [ "$c3_ok" = "1" ] && [ "$row_n" -gt 0 ] && \
    say "  OK    check 3  ${row_n} construct id(s) resolve to a row of ${INVENTORY}"
fi

# ===========================================================================
# CHECK 4. every row can be submitted at all.
# ===========================================================================
c4_ok=1

# Duplicate ids. The runner's lookup takes the first match and exits, so a
# second row with the same id is unreachable: it can never be graded and
# nothing else in this corpus would ever notice it is there.
#
# ACROSS BOTH KINDS, not within each. The lookup matches either marker, so a
# SPEC row carrying a REP row's id shadows it exactly as a second REP row
# would, and that is the collision most likely to happen by accident.
while IFS= read -r dup; do
  [ -n "$dup" ] || continue
  finding "ROW-DUPLICATE-ID" "$dup" \
    "two or more rows carry this id. The runner takes the first and exits, so the rest can never be graded"
  c4_ok=0
done < <(awk -F'\t' '$1 == "REP" || $1 == "SPEC" { seen[$2]++ } END { for (k in seen) if (seen[k] > 1) print k }' "$REPS" | LC_ALL=C sort)

# Field count, before anything reads a field that may not be there. The two
# kinds have different minima, so the two scans are separate and each names
# the shape it wants.
while IFS= read -r bad; do
  [ -n "$bad" ] || continue
  finding "ROW-BAD-SHAPE" "$bad" \
    "fewer than six tab-separated fields. A REP row is marker, id, construct, environment, prompt, canonical"
  c4_ok=0
done < <(awk -F'\t' '$1 == "REP" && NF < 6 { print ($2 == "" ? "(no id)" : $2) }' "$REPS")

while IFS= read -r bad; do
  [ -n "$bad" ] || continue
  finding "ROW-BAD-SHAPE" "$bad" \
    "fewer than eight tab-separated fields. A SPEC row is marker, id, construct, scaffolds, prompt, canonical, requires, expect, and an optional check"
  c4_ok=0
done < <(awk -F'\t' '$1 == "SPEC" && NF < 8 { print ($2 == "" ? "(no id)" : $2) }' "$REPS")

for i in "${!IDS[@]}"; do
  id="${IDS[$i]}"

  if [ -z "$id" ]; then
    finding "ROW-BAD-SHAPE" "(no id)" "a row carries no id in field 2, so nothing can name it"
    c4_ok=0
    continue
  fi

  if [ -z "${CANONS[$i]}" ]; then
    finding "ROW-BAD-SHAPE" "$id" "field 6 is empty, so the rep carries no canonical answer and nothing can be graded"
    c4_ok=0
  fi

  if [ -z "${ENVS[$i]}" ]; then
    finding "ENV-MISSING" "$id" "field 4 is empty, so the rep names nothing to drop the answer into"
    c4_ok=0
  elif [ "${KINDS[$i]}" = "SPEC" ]; then
    # FIELD 4 IS A LIST AND FIELD 8 IS A VECTOR, so both are split and the two
    # lengths are compared before either is used. A short vector read position
    # by position against a long list is a grade taken off a run that never
    # happened, which is the one failure this check exists to make loud.
    spec_names=()
    spec_want=()
    IFS=',' read -r -a spec_names <<<"${ENVS[$i]}"
    IFS=',' read -r -a spec_want <<<"${EXPECTS[$i]}"
    if [ -z "${EXPECTS[$i]}" ]; then
      finding "EXPECT-BAD" "$id" "field 8 is empty, so the rep declares no expected exit code and there is no key to grade against"
      c4_ok=0
    elif [ "${#spec_names[@]}" -ne "${#spec_want[@]}" ]; then
      finding "EXPECT-BAD" "$id" \
        "field 4 names ${#spec_names[@]} scaffold(s) and field 8 holds ${#spec_want[@]} code(s), so there is no telling which code belongs to which scaffold"
      c4_ok=0
    fi
    spec_wants_check=0
    for spec_j in "${!spec_names[@]}"; do
      spec_name="${spec_names[$spec_j]}"
      if [ -z "$spec_name" ]; then
        finding "SCAFFOLD-MISSING" "$id" "field 4 carries an empty scaffold name"
        c4_ok=0
        continue
      fi
      if [ ! -r "${SPEC_DIR}/${spec_name}.tla" ]; then
        finding "SCAFFOLD-MISSING" "$id" \
          "field 4 names '${spec_name}' and ${SPEC_DIR}/${spec_name}.tla is not readable, so every submission is rc 3"
        c4_ok=0
        continue
      fi
      if [ ! -r "${SPEC_DIR}/${spec_name}.cfg" ]; then
        finding "SCAFFOLD-MISSING" "$id" \
          "field 4 names '${spec_name}' and ${SPEC_DIR}/${spec_name}.cfg is not readable, so the module has no obligations and every submission is rc 3"
        c4_ok=0
        continue
      fi
      if grep -qE '^[[:space:]]*__CHECK__[[:space:]]*$' "${SPEC_DIR}/${spec_name}.tla"; then
        spec_wants_check=1
      fi
      case "${spec_want[$spec_j]:-}" in
        ''|*[!0-9]*)
          finding "EXPECT-BAD" "$id" \
            "field 8 expects '${spec_want[$spec_j]:-}' from scaffold '${spec_name}', which is not an exit code"
          c4_ok=0
          ;;
      esac
    done
    # The two directions of the __CHECK__ hole. A hole with nothing to fill it
    # does not parse; a fill with no hole is carried and delivered and read by
    # nothing.
    if [ "$spec_wants_check" = "1" ] && [ -z "${CHECKS[$i]}" ]; then
      finding "CHECK-MISSING" "$id" \
        "a scaffold this rep names has a __CHECK__ hole and field 9 is empty, so the hole fills with nothing and the module does not parse"
      c4_ok=0
    fi
    if [ "$spec_wants_check" = "0" ] && [ -n "${CHECKS[$i]}" ]; then
      finding "CHECK-UNUSED" "$id" \
        "field 9 is set and no scaffold this rep names has a __CHECK__ hole, so the text is delivered and never read"
      c4_ok=0
    fi
  elif [ ! -r "${ENV_DIR}/${ENVS[$i]}.tla" ]; then
    finding "ENV-MISSING" "$id" \
      "field 4 names '${ENVS[$i]}' and ${ENV_DIR}/${ENVS[$i]}.tla is not readable, so every submission is rc 3"
    c4_ok=0
  fi

  # ---------------------------------------------------------------------
  # IS A PATTERN REQUIRED HERE, AND IS IT MISSING (bead tla-2s12)
  #
  # Everything below this point validates a pattern that IS there. Measured
  # by the tla-1sh7.7 author on a mirror: strip R023, R045 and R110 back to
  # six fields and this gate still reports 0 findings and VERDICT OK. So the
  # `continue` below made the field-7 adoption invisible in both directions.
  # Nothing noticed it being undone, and nothing would notice a NEW rep in
  # one of these families landing ungated, which is the likelier of the two.
  #
  # WHY A DECLARED LIST AND NOT A DERIVED SET. The list is this gate's own and
  # is deliberately not read off the table, because deriving "which rows need a
  # pattern" from "which rows have one" is exactly what makes an omission
  # invisible. A new rep in one of these families has to be named in
  # REQUIRES_PATTERN_NAMES or it is not covered, and that is the point.
  #
  # IT IS KEYED ON THE INVENTORY NAME rather than the construct id, because an
  # id means whatever the inventory in use says it means. See the declaration.
  #
  # WHY NOT INVERT THE `continue` INSTEAD, so an empty field 7 is a finding
  # everywhere: 96 of the 120 rows legitimately carry no pattern, because
  # value equality is sufficient for them. A gate that fires on all 96 is a
  # gate somebody switches off.
  #
  # WHAT PUTS A CONSTRUCT ON THIS LIST is that value equality cannot see its
  # construct, so a learner reaching the right value another way scores 0.
  #   K001, K071 to K076   the definition forms. They grade rc 0 wrapped in a
  #                        LET, so the value never shows a definition was
  #                        written. tla-1sh7.2 measured it.
  #   K009                 implication. P => Q and P /\ Q differ exactly
  #                        where P is false, so a rep with a true antecedent
  #                        cannot require the operator.
  #   K007                 and, or, not. Measured leaking on ALL FIVE of its
  #                        rows, not just the two-true-operands shape the
  #                        tla-1sh7.7 bead predicted: <=> agrees with /\
  #                        wherever the operands differ, and one operand
  #                        carrying the value needs no operator at all.
  #
  # WHY THE REP GUARD, since no SPEC row is in any of the nine today and the
  # branch is a no-op either way: a SPEC row does not grade by value equality
  # at all. It grades by whether a scaffold returned the rc field 8 names, so
  # "a learner reached the right value another way" is not a thing that can
  # happen to it and the whole rationale above does not apply. The guard says
  # that rather than leaving a later reader to work out whether the absence is
  # deliberate.
  # ---------------------------------------------------------------------
  req="${REQUIRES[$i]}"

  if [ "${KINDS[$i]}" = "REP" ] && [ -z "$req" ] && [ -n "${INV_NAMES:-}" ]; then
    this_name=""
    while IFS="$TAB_CH" read -r inv_id inv_name; do
      if [ "$inv_id" = "${CONSTRUCTS[$i]}" ]; then
        this_name="$inv_name"
        break
      fi
    done <<<"$INV_NAMES"
    if [ -n "$this_name" ] && grep -qxF -- "$this_name" <<<"$REQUIRES_PATTERN_NAMES"; then
      finding "REQUIRES-ABSENT" "$id" \
        "construct '${CONSTRUCTS[$i]}' is '${this_name}', which value equality cannot see, and field 7 is empty, so an answer that reaches the right value without the construct scores 0"
      c4_ok=0
    fi
  fi

  [ -n "$req" ] || continue

  # Is it an ERE grep will read? The runner treats a grep rc above 1 as "could
  # not run" and dies at exit 3, so an unreadable pattern takes the rep out of
  # service entirely. A here-string, never a pipe: under pipefail an
  # early-exiting consumer makes the producer take SIGPIPE and the pipeline
  # report 141, which inside an `if` is merely falsy.
  probe_rc=0
  grep -qE -- "$req" <<<"recall-gate-ere-probe" || probe_rc=$?
  if [ "$probe_rc" -gt 1 ]; then
    finding "REQUIRES-UNREADABLE" "$id" \
      "field 7 is '${req}', which grep -E will not read as an expression, so every submission to this rep dies at rc 3"
    c4_ok=0
    continue
  fi

  # Does the row's own canonical satisfy it? If not, the construct gate turns
  # the rep's own answer away at rc 4 and NO correct answer can ever score 0.
  if ! grep -qE -- "$req" <<<"${CANONS[$i]}"; then
    finding "REQUIRES-REFUSES-CANONICAL" "$id" \
      "field 7 is '${req}' and the row's own canonical does not match it, so the construct gate refuses the rep's own answer at rc 4"
    c4_ok=0
  fi
done

[ "$c4_ok" = "1" ] && [ "$row_n" -gt 0 ] && \
  say "  OK    check 4  ${row_n} row(s) are submittable: an id of their own, an environment or a scaffold pair on disk, a field 7 that takes their canonical, and a field 8 that lines up with field 4"

# ===========================================================================
# CHECK 6. every scaffold is well formed, and every scaffold is used.
#
# IT RUNS OVER THE TREE rather than over the names field 4 happens to carry,
# so a scaffold added tomorrow is covered the moment it lands and an orphan is
# reported rather than quietly delivered. See CHECK 6 in the header.
# ===========================================================================
if [ ! -d "$SPEC_DIR" ]; then
  if [ "$spec_n" -gt 0 ]; then
    finding "SHAPE-NO-SPEC-DIR" "$ROOT" \
      "${spec_n} SPEC row(s) and no env/spec/ directory, so every one of them is rc 3"
  fi
else
  c6_ok=1
  # Which scaffolds any row names, as one newline-delimited list, so the orphan
  # sweep below is a lookup rather than a nested loop.
  SPEC_USED=""
  for i in "${!IDS[@]}"; do
    [ "${KINDS[$i]}" = "SPEC" ] || continue
    SPEC_USED="${SPEC_USED}$(tr ',' '\n' <<<"${ENVS[$i]}")
"
  done

  while IFS= read -r tla; do
    [ -n "$tla" ] || continue
    scaffold_n=$((scaffold_n + 1))
    base="${tla##*/}"
    name="${base%.tla}"

    # A line at a time, counted rather than grepped for presence, because the
    # defect that matters is TWO holes as much as none.
    n_answer="$(grep -cE '^[[:space:]]*__ANSWER__[[:space:]]*$' "$tla")"
    n_check="$(grep -cE '^[[:space:]]*__CHECK__[[:space:]]*$' "$tla")"
    if [ "$n_answer" -eq 0 ]; then
      finding "SCAFFOLD-NO-HOLE" "$name" \
        "no line whose only content is __ANSWER__, so the answer is dropped and every submission to every rep over it grades the same"
      c6_ok=0
    elif [ "$n_answer" -gt 1 ]; then
      finding "SCAFFOLD-TWO-HOLES" "$name" \
        "${n_answer} __ANSWER__ lines. The runner fills every one it finds, which is not what an author meant by a hole"
      c6_ok=0
    fi
    if [ "$n_check" -gt 1 ]; then
      finding "SCAFFOLD-TWO-HOLES" "$name" \
        "${n_check} __CHECK__ lines, and field 9 fills every one of them"
      c6_ok=0
    fi

    # A whole module, and the header has to name Scaffold: the runner copies
    # the file to Scaffold.tla and rewrites nothing, so a header naming
    # anything else is rc 255 on every submission.
    if ! grep -qE '^----[- ]*MODULE Scaffold[- ]*----' "$tla"; then
      finding "SCAFFOLD-BAD-SHAPE" "$name" \
        "no '---- MODULE Scaffold ----' header. The runner copies the file to Scaffold.tla and rewrites nothing"
      c6_ok=0
    fi
    if ! grep -qE '^====' "$tla"; then
      finding "SCAFFOLD-BAD-SHAPE" "$name" \
        "no closing ==== line, so the module never ends and nothing over it parses"
      c6_ok=0
    fi
    # The first line is printed to a learner under a wrong answer, so it has
    # to be a comment and it has to say something.
    first="$(sed -n '1p' "$tla")"
    case "$first" in
      '\*'*)
        if [ "${#first}" -lt 20 ]; then
          finding "SCAFFOLD-BAD-SHAPE" "$name" \
            "the first line is a comment of ${#first} characters. It is what a wrong answer is told about the machine, so it has to describe one"
          c6_ok=0
        fi
        ;;
      *)
        finding "SCAFFOLD-BAD-SHAPE" "$name" \
          "the first line is not a \\* comment. It is what a wrong answer is told about the machine"
        c6_ok=0
        ;;
    esac

    if [ ! -r "${SPEC_DIR}/${name}.cfg" ]; then
      finding "SCAFFOLD-NO-CFG" "$name" \
        "no ${name}.cfg beside it, so TLC is handed a module with no obligations and says nothing about any answer"
      c6_ok=0
    fi

    if ! grep -qxF -- "$name" <<<"$SPEC_USED"; then
      finding "SCAFFOLD-ORPHAN" "$name" \
        "no SPEC row names it, so it is delivered to every practice tree and read by nothing"
      c6_ok=0
    fi
  done < <(find "$SPEC_DIR" -name '*.tla' -type f | LC_ALL=C sort)

  if [ "$scaffold_n" -eq 0 ] && [ "$spec_n" -gt 0 ]; then
    finding "SHAPE-NO-SCAFFOLDS" "$ROOT" \
      "${spec_n} SPEC row(s) and no .tla under ${SPEC_DIR}, so every one of them is rc 3"
  elif [ "$c6_ok" = "1" ] && [ "$scaffold_n" -gt 0 ]; then
    say "  OK    check 6  ${scaffold_n} scaffold(s) are whole modules with one answer hole, a .cfg beside them, and a row that names them"
  fi
fi

# ===========================================================================
# CHECK 5. no prompt contains the notation it is asking for.
# ===========================================================================
c5_ok=1
for i in "${!IDS[@]}"; do
  prompt="${PROMPTS[$i]}"
  canon="${CANONS[$i]}"
  if [ -z "$prompt" ]; then
    finding "PROMPT-EMPTY" "${IDS[$i]}" \
      "field 5 is empty, so the rep states no need and there is nothing to recall"
    c5_ok=0
    continue
  fi
  for tok in "${TELEGRAPH_TOKENS[@]}"; do
    token_shown "$tok" "$canon" || continue
    if token_shown "$tok" "$prompt"; then
      finding "TELEGRAPH-IN-PROMPT" "${IDS[$i]}" \
        "the canonical uses '${tok}' and the prompt shows it, so the rep is a transcription rather than a recall"
      c5_ok=0
    fi
  done
done

[ "$c5_ok" = "1" ] && [ "$row_n" -gt 0 ] && \
  say "  OK    check 5  no prompt of ${row_n} shows a token its own canonical uses"

# ===========================================================================
# CHECKS 1 and 2. The TLC half.
# ===========================================================================
if [ "$STATIC_ONLY" = "1" ]; then
  :
elif [ "$NO_TLC" = "1" ]; then
  unchecked "every-canonical-scores-0" "$ROOT" \
    "${row_n} canonical answer(s) to grade: --no-tlc was asked for, so the check was not run"
  unchecked "every-miss-scores-its-kinds-code" "$ROOT" \
    "the miss table was not read either: --no-tlc was asked for, so the check was not run"
else
  # --- check 1 ----------------------------------------------------------
  # ONE LOOP OVER BOTH KINDS, because the question is the same and only the
  # DETAIL differs: a 0 from a REP row says the canonical parses, a 0 from a
  # SPEC row says it did what field 8 independently claimed. See WHAT THE SPEC
  # ARM OF CHECK 1 IS WORTH in the header.
  c1_ok=1
  for i in "${!IDS[@]}"; do
    [ -n "${IDS[$i]}" ] || continue
    [ -n "${CANONS[$i]}" ] || continue
    grade "${IDS[$i]}" "${CANONS[$i]}"
    [ "$GRADE_RC" = "0" ] && continue
    case "$GRADE_RC" in
      4)   detail="the construct gate refused the rep's own canonical, so no correct answer can score 0" ;;
      5)   detail="the canonical does not produce the exit codes field 8 names for it, so either the answer or the key is wrong" ;;
      10)  detail="the canonical is not equal to itself, which is what a TLC-unevaluable expression does" ;;
      150) detail="the canonical did not parse, so nothing was graded. A typo, or a name the environment or the scaffold never defines" ;;
      3)   detail="the run could not happen at all: no environment file, no scaffold pair, or no scratch directory" ;;
      *)   detail="the grading run came back ${GRADE_RC}, which is a report about the run rather than about the answer" ;;
    esac
    finding "CANONICAL-NOT-CORRECT" "${IDS[$i]}" "rc ${GRADE_RC}: ${detail}"
    c1_ok=0
  done
  [ "$c1_ok" = "1" ] && [ "$row_n" -gt 0 ] && \
    say "  OK    check 1  ${row_n} canonical answer(s) scored rc 0: ${rep_n} against themselves, which is parse and evaluation only, and ${spec_n} against the vector field 8 declares separately (see CHECK 1 in this file's header)"

  # --- check 2 ----------------------------------------------------------
  if [ ! -f "$MISSES" ]; then
    # Not a finding: the runner's own contract is that a missing miss table is
    # silence rather than a refusal, and a tree delivered without one still
    # grades every rep in it. It IS an unchecked, because a corpus that lost
    # its miss table has lost 30 explanations and nothing else would say so.
    unchecked "check-2" "$ROOT" \
      "no MISSES.tsv under the root, so no wrong answer was graded"
  else
    c2_ok=1
    while IFS= read -r row; do
      miss_n=$((miss_n + 1))
      m_rep="$(cut -f2 <<<"$row")"
      m_wrong="$(cut -f3 <<<"$row")"
      m_why="$(cut -f4 <<<"$row")"

      if [ -z "$m_rep" ] || [ -z "$m_wrong" ]; then
        finding "MISS-BAD-SHAPE" "${m_rep:-(no id)}" \
          "a MISS row is marker, rep id, wrong answer, explanation, and one of the first three is empty"
        c2_ok=0
        continue
      fi
      if [ -z "$m_why" ]; then
        finding "MISS-NO-EXPLANATION" "$m_rep" \
          "field 4 is empty, so the row costs a grading run and says nothing under the two values"
        c2_ok=0
      fi

      # THE WRONG-ANSWER CODE IS THE REP'S, NOT THE MISS ROW'S. A MISS row
      # names a rep id and nothing else about the rep, so the kind is looked
      # up here. An id that is in no row at all falls through to rc 3 below,
      # which already reports as MISS-NO-REP.
      m_kind="$(awk -F'\t' -v id="$m_rep" '($1 == "REP" || $1 == "SPEC") && $2 == id { print $1; exit }' "$REPS")"
      if [ "$m_kind" = "SPEC" ]; then
        m_want="$WRONG_RC_SPEC"
      else
        m_want="$WRONG_RC_REP"
      fi

      grade "$m_rep" "$m_wrong"
      [ "$GRADE_RC" = "$m_want" ] && continue
      case "$GRADE_RC" in
        0)
          finding "MISS-NOT-WRONG" "$m_rep" \
            "'${m_wrong}' scores rc 0, so it is a CORRECT form of the answer and field 4 calls a right answer a mistake"
          ;;
        4)
          finding "MISS-NOT-WRONG" "$m_rep" \
            "'${m_wrong}' scores rc 4, so the answer was accepted and only the construct gate turned it away. The miss table is about answers that are wrong"
          ;;
        5|10)
          # THE RIGHT KIND OF WRONGNESS FOR THE OTHER ROW KIND, and this arm
          # is UNREACHABLE on the runner as it stands. recall/recall.sh never
          # exits 10 on a SPEC row -- 10 is in its gradeable set, so it is
          # compared against field 8 and leaves as 0 or 5 -- and never exits 5
          # on a REP row. The arm is here for the same reason
          # REQUIRES-UNREADABLE was here before any row carried a field 7: it
          # is the finding a runner that blurred the two codes would produce,
          # and a gate that bucketed that into MISS-NOT-GRADED would report a
          # wiring defect as a corpus defect. Reachability is a property of
          # the runner and this file does not get to assume it.
          finding "MISS-WRONG-KIND" "$m_rep" \
            "'${m_wrong}' scores rc ${GRADE_RC} and this rep is a ${m_kind:-unknown} row, whose wrong answers score rc ${m_want}"
          ;;
        150)
          finding "MISS-NOT-GRADED" "$m_rep" \
            "'${m_wrong}' scores rc 150, so it never parsed and field 4 is a sentence about text rather than about an idea"
          ;;
        3)
          finding "MISS-NO-REP" "$m_rep" \
            "the runner refused this row at rc 3. Field 2 names no row of the rep table, or its environment or a scaffold is gone"
          ;;
        *)
          finding "MISS-NOT-GRADED" "$m_rep" \
            "'${m_wrong}' scores rc ${GRADE_RC}, which is a report about the run rather than about the answer"
          ;;
      esac
      c2_ok=0
    done < <(awk -F'\t' '$1 == "MISS"' "$MISSES")

    if [ "$miss_n" -eq 0 ]; then
      unchecked "check-2" "$MISSES" \
        "the file is there and holds no MISS row. A row is tab-delimited with the literal first field MISS"
    elif [ "$c2_ok" = "1" ]; then
      say "  OK    check 2  ${miss_n} wrong answer(s) scored their own row kind's wrong-answer code against their own rep: rc ${WRONG_RC_REP} for a REP row, rc ${WRONG_RC_SPEC} for a SPEC row"
    fi
  fi
fi

# ===========================================================================
# THE MODE BLOCK. What a tier that exits 0 did NOT measure.
#
# A MODE THAT EXITS 0 WITHOUT SAYING WHAT IT LEFT OUT IS THE DEFECT. The
# counts do not exist until the rows have been read, so the block sits here
# rather than in the banner, and it prints through `echo` so `-q` cannot
# suppress it: an honesty statement is not a per-check OK line.
#
# THE ADMISSION IS SPELLED IN harness/test-indeterminate.sh's VOCABULARY, ON
# PURPOSE, AND THE WAIVING FLAG IS NAMED IN PARENTHESES ON THE SAME LINE.
# That suite's parenthetical rule is what makes a voluntary skip tellable from
# an involuntary one: an admission naming the caller flag behind it is
# legitimate at rc 0, and one that names no flag must carry 99. Phrasing this
# to dodge the skip vocabulary would hide the admission from the only gate
# that looks for it. The word is `skipped` and the flag is in brackets after
# it, which is the form harness/completion-gate.sh landed on after a first
# version dodged the vocabulary by grammar.
# ===========================================================================
if [ "$STATIC_ONLY" = "1" ]; then
  echo
  echo "recall-gate.sh: --static-only. ${row_n} rep(s) whose grading was not measured, no TLC ran."
  echo "Checks 1 and 2 were skipped (--static-only), which is the scope the caller asked for."
  echo "NOT COVERED HERE: whether every canonical still scores rc 0, and whether every miss still scores the wrong-answer code of its own row kind."
  echo "The slow row of harness/test-recall-gate.sh runs those."
  echo "This run answers whether the corpus is STRUCTURALLY sound and nothing more."
fi

# ===========================================================================
# THE SUMMARY LINE NAMES BOTH ROW KINDS AND THE SCAFFOLDS SEPARATELY. One
# total would have let 40 spec rows land under a number that did not move,
# which is the shape of the defect this bead's gate work exists to close.
echo
echo "recall-gate.sh: ${rep_n} rep(s), ${spec_n} spec rep(s), ${scaffold_n} scaffold(s), ${miss_n} miss row(s), ${finding_n} finding(s), ${unchecked_n} unchecked"

if [ "$finding_n" -gt 0 ]; then
  echo "VERDICT FINDINGS"
  exit 1
fi
if [ "$unchecked_n" -gt 0 ]; then
  echo "VERDICT CHECK_DID_NOT_RUN"
  exit 99
fi
echo "VERDICT OK"
exit 0
