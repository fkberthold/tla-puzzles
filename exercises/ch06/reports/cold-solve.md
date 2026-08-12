# Cold-solve review: ch.6 exercise set

Bead `tla-jb7f.18`. I worked this as a second agent, a fresh session with
no access to the authoring pass. Toolchain: `TLC2 Version
2026.07.31.184830`, matching the project's pin.

## Phase 1: solve blind

Materials: `exercises/ch06/EXERCISES.md`, `exercises/ch06/starters/`, and
the `ch02` through `ch05` `CHEATSHEET.md` files. Nothing else. I worked in
a scratch directory outside the repo tree, timed with `date +%s` before
and after each exercise.

| Ex | Title | Minutes | Budget | Pass | Fail |
|---|---|---|---|---|---|
| 1 | Parcel desk | 1.9 | 15 | OK | SAFETY_VIOLATION |
| 2 | Six claims about DOMAIN | 0.7 | 10 | OK | ASSUMPTION_FAILED |
| 3 | Knob panel | 0.5 | 15 | OK | SAFETY_VIOLATION |
| 4 | Patch desk | 0.4 | 12 | OK | SAFETY_VIOLATION |
| 5 | Fare table | 0.3 | 12 | OK | ASSUMPTION_FAILED |

All five solved. All ten stated outcomes (five pass, five fail)
matched what `EXERCISES.md` states. Total solve time was about 4
minutes against a stated budget of 64. I think my times run fast
because I brought prior TLA+ and PlusCal knowledge into this. That's
not the same as the exercises being easy for a first-time reader. No
exercise caused a wrong turn or a stall.

**Exercise 1, Parcel desk.** Wrote `ParcelDesk.tla` from the prompt. Used
a dotted assignment for Weigh, `parcel.kilos := parcel.kilos + 1;`, and a
full struct literal for Upgrade, matching the prompt's two different
verbs ("adds a kilo" against "replaces... with a struct literal"). Both
runs matched
[`bash harness/verdict.sh .../ParcelDesk.tla -c .../ParcelDesk.cfg` ->
`OK`, then after the `expres` typo -> exit 12, `SAFETY_VIOLATION`].
Friction: the prompt describes Weigh's behavior but never states the
assignment syntax. I used dotted-field assignment from general
TLA+/PlusCal knowledge, not from anything in `EXERCISES.md` or the
ch02-05 sheets. See finding N1.

**Exercise 2, Six claims about DOMAIN.** Wrote my six predictions before
running, all TRUE: a sequence's DOMAIN is `{1,2,3}`, a struct's DOMAIN is
its field names, the function literal over `1..3` equals `<<1,4,9>>`,
`Len` sees the same function as length 3, `@@` keeps the left operand's
value, and a two-argument function's domain has cardinality `3*2=6`. Both
runs matched
[`bash harness/verdict.sh .../DomainProbe.tla -c .../DomainProbe.cfg` ->
`OK`, then after moving Claim3 to domain `0..2` -> exit 10,
`ASSUMPTION_FAILED`]. No friction, but I read the whole `EXERCISES.md`
file before starting, so exercise 4's spoiler about `@@`'s left-wins rule
was already in view when I wrote the Claim5 prediction. That prediction
is also derivable from general knowledge of `@@`, so I don't think it
invalidates the predict-then-check, but it's worth saying.

**Exercise 3, Knob panel.** Filled the three TODOs:
`dial = [k \in Knobs |-> 0];`, `DialType == [Knobs -> 0..ceiling]`,
`dial[next] := ceiling;`. All three matched the reference solution's
text word for word. Both runs matched
[`bash harness/verdict.sh .../KnobPanel.tla -c .../KnobPanel.cfg` ->
`OK`, then after turning the knob to `MaxNotch` instead of `ceiling` ->
exit 12, `SAFETY_VIOLATION`]. No friction.

**Exercise 4, Patch desk.** Wrote `PatchDesk.tla`, working out the merge
order the exercise asks for: Override as `("retries" :> 5) @@ settings`,
Remerge as `settings @@ ("retries" :> 9)`. Both runs matched
[`bash harness/verdict.sh .../PatchDesk.tla -c .../PatchDesk.cfg` ->
`OK`, then after swapping the Remerge operands -> exit 12,
`SAFETY_VIOLATION`]. No friction. Working out the operand order took one
pass of reasoning about `@@`'s left-wins rule against the three
invariants.

**Exercise 5, Fare table.** Wrote `FareTable.tla` with
`Fare == [a \in Zones, b \in Zones |-> IF a >= b THEN a - b ELSE b - a]`.
The reference uses `a > b` instead of `a >= b`, an equally valid choice,
both give 0 on the diagonal. Both runs matched
[`bash harness/verdict.sh .../FareTable.tla -c .../FareTable.cfg` ->
`OK`, then after changing Fare to plain `a - b` -> exit 10,
`ASSUMPTION_FAILED`]. No friction.

## Phase 2: review open-book

I opened `exercises/ch06/references/`, `reports/authoring.md`,
`COVERAGE.md`, the ch06 `CHEATSHEET.md`, and a shallow clone of
`hwayne/learntla-v2` at `09840bfc2ee9a88cdbedb672be77a6c73942fe16`
[`git -C /tmp/.../learntla-v2 rev-parse HEAD` ->
`09840bfc2ee9a88cdbedb672be77a6c73942fe16`, matches the pin].

### BUDGET

No breach. No exercise even approached its budget in my run. No finding.

### AMBIGUITY

None found that produced a wrong turn during the blind solve. One
candidate came up and cleared on investigation.
`exercises/ch06/EXERCISES.md:16` tells the learner to fill in LOG.md's
prediction column without saying where LOG.md comes from. `ch04` and
`ch05` are explicit about this
(`exercises/ch04/EXERCISES.md:9-11`, `exercises/ch05/EXERCISES.md:10`
both tell the learner to copy `exercises/templates/LOG.md`). I checked
`scripts/deliver-exercises.sh` and it delivers `templates/LOG.md` into
every chapter's practice tree, uniformly, chapters 2 through 11
[`scripts/deliver-exercises.sh:111`]. `ch02` and `ch03` use the same
terse phrasing ch06 does
(`exercises/ch02/EXERCISES.md:18`, `exercises/ch03/EXERCISES.md:39`), so
this is an established project pattern rather than a ch06-specific gap.
No finding.

### PREREQUISITE LEAK

**N1 (NOTE).** Exercise 1's Weigh label needs a way to touch one field of
a struct. The natural spelling is dotted assignment,
`parcel.kilos := parcel.kilos + 1;`
(`exercises/ch06/references/ParcelDesk.tla:30`). This write form is not
demonstrated anywhere in the delivered material. `functions.rst:20`
shows the dot form only for reading (`struct.a = 1`), and
`functions.rst:206` shows single-field assignment only in bracket form
(`assignments[t] := ...`). ch03's cheat sheet carries the same
bracket-only shape in its `||` entry. A learner has to generalize "dot
reads like bracket" plus "bracket-indexed assignment updates one field"
into "dot-indexed assignment does too."

I weigh this as a NOTE rather than a DEFECT, on four points. A fully
taught alternative exists. Weigh could be a full struct literal, the
same way Upgrade is, using only the construction and dot-read syntax the
chapter demonstrates directly. The generalization the shortcut needs is
small, and it sits inside the chapter's own thesis, that structs are
functions and dot is sugar for bracket. A wrong guess at PlusCal syntax
fails fast, a parse error at `pcal` time, not a silent wrong answer.
Last, the authoring report already flags and defends this same call
with the same two citations (`exercises/ch06/reports/authoring.md:198-204`).
I'd weigh it against a PASS if something else were also wrong, but on
its own it doesn't clear the bar for SEND BACK.

No other prerequisite leak. I checked every construct in the four
from-scratch or fill-in exercises against the ch02 through ch06 sheets.
Nothing from chapter 7 or later shows up. No `either`, no
`with x \in Set`, no `RECURSIVE`, no hand-written `EXCEPT`. This matches
authoring.md's own scope table (`exercises/ch06/reports/authoring.md:184-194`),
which I checked against the reference files myself rather than taking on
trust.

### NEAR-COPY

I read `docs/core/functions.rst` in full, 401 lines, from the pinned
clone, and checked each exercise against its worked examples (`struct`,
`BankTransactionType`, `Prod`, `TruthTable`, `Zip1`/`Zip2`,
`assignments`/`OnlyOneTaskPerCpu`, the four function-set examples,
`IsSorted`, `Sort`, and the duplicate-checker rewrite).

No exercise copies story or surface content. The three structural
overlaps authoring.md declares are all same-construct-different-content,
which the checklist allows. Exercise 5's `Fare` is a two-argument
function literal like `Prod` and `TruthTable`. The payload (a
zone-boundary count) and the four claims around it are the exercise's
own. Exercise 5's `FareIsTyped` has the shape of the chapter's
`graph \in [Node \X Node -> BOOLEAN]`. A fare range isn't a graph, and
the chapter never model-checks its graph example. Exercise 3's state
sweeping takes the "bound on a value" flavor. The chapter's tip at
`functions.rst:374` names that flavor in prose but never shows it in a
spec. The chapter's own worked sweep is a sequence length.

No exercise reuses `Zip`, `Sort`, or the duplicate checker's logic,
matching `COVERAGE.md`'s account of leaving them out on purpose. No
finding.

### COVERAGE

I re-derived which constructs and themes each exercise touches, straight
from the reference `.tla` files, before reading `COVERAGE.md`'s own
tables. Both match, row for row and exercise for exercise.

The two partial-coverage rows hold up. Three exercises type a variable
with `[S -> T]` (KnobPanel, PatchDesk, FareTable), and none build one
from a filtered or mapped set, and none check the `#T^#S` size rule. Both
omissions are true and both are explained. Of the chapter's closing
worked examples, only exercise 3's state sweeping is drilled. `Zip` and
`Sort` are left out for the near-copy reason above. Also true, also
explained. No finding.

### EVIDENCE

I re-ran the whole evidence chain myself rather than reading it.

Mutant seed and run:
[`python3 exercises/ch06/reports/mutants.py` seeded all 22 mutants with
no SEED-ERROR line, `bash exercises/ch06/reports/run-mutants.sh` -> 21
rows `SAFETY_VIOLATION` or `ASSUMPTION_FAILED`, K5 alone `OK`]. This
matches authoring.md's claimed table, id for id, verdict for verdict,
exit code for exit code (`exercises/ch06/reports/authoring.md:94-119`).
21 killed, 1 inert, confirmed.

Reference pass runs:
[`bash exercises/ch06/reports/run-refs.sh` -> all five `OK`, rc=0],
matching the Pass runs table (`exercises/ch06/reports/authoring.md:46-54`).

The spot-run floor was 4 outcomes with at least one fail. I cleared it by
a wide margin. Phase 1 alone ran 10 stated outcomes, five pass and five
fail, against my own independently-written specs. Phase 2 re-ran all 5
references and all 22 mutants against the committed reference files, 27
more runs. Every stated outcome in `EXERCISES.md` is backed by a
`verdict.sh` run I watched myself, not a table I took on faith.

I also checked the type-stability claim. None of my 27 phase-2 runs
landed on 75, 76, or 255, which is what an aborted cross-type comparison
would produce. All 27 landed on 0, 10, or 12.

## Verdict

PASS

No DEFECT. One NOTE (N1, exercise 1's dotted assignment) worth a second
pair of eyes, not a blocker on its own. All five exercises solved blind
inside budget, all ten stated outcomes matched, all 27 verdict.sh runs in
the evidence chain matched, and the coverage and near-copy claims
checked out against the pinned `learntla-v2` clone.
