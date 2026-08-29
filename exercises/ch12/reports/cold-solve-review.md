# Cold-solve review: ch12 exercise set, TLA+

Bead `tla-jb7f.27`. I solved all five exercises from a delivered tree without
reading `references/`, `reports/` or `COVERAGE.md` first, then audited against
them. Predictions for exercises 4 and 5 went into `LOG.md` before either spec
was run.

## Verdict

Five PASS on the exercises. One SEND BACK against the shared front matter,
because a single missing line there makes four sentences untrue.

| Exercise | Verdict |
|---|---|
| 1, `The seed drill` | PASS |
| 2, `The apiary` | PASS |
| 3, `Two glaziers, one bench` | PASS |
| 4, `Which winches are fair` | PASS |
| 5, `One label, two branches` | PASS |
| Shared "How to run" section | SEND BACK |

Every exercise is answerable as written, and every stated outcome reproduces.
The send-back is a text repair in one place, not a rebuild of anything.

## Setup

Delivered with `bash scripts/deliver-exercises.sh 12 <scratch>` into a scratch
tree inside this worktree [rc=0, 20 files: `EXERCISES.md`, `LOG.md`, 8 in
`starters/`, 10 in `cheatsheets/`]. The delivery carries no `references/`, no
`reports/`, no `COVERAGE.md` and no ch12 sheet [`find` over the delivered tree
listed `ch02` through `ch11` only].

Before reading a word of `EXERCISES.md` I stripped every `### After the run`
block into a scratch copy and checked the copy was clean [`sed
'112,132d;166,192d;226,241d;264,294d;319,351d'`, then `grep -c 'After the run'`
printed `0`]. I read the stripped copy for all five.

Toolchain is `TLC2 Version 2026.07.31.184830` [`tlc`], which is the build the
`verdict.sh` exit-code table was re-measured on [`harness/verdict.sh:40-42`].

## Predictions for exercise 4, written before the run

I wrote both into `LOG.md` before invoking TLC [`LOG.md`, ex4 line, written in
the turn before the first `Drawbridge` run].

1. As shipped with `\A`: `OK`. Each winch carries its own `WF`, and `Raise(w)`
   stays enabled until `w` moves, so both reach `Target`.
2. With `\E`: `LIVENESS_VIOLATION`. A quantifier over a temporal formula is a
   disjunction of the two `WF` conjuncts, so the spec only promises that some
   winch is fair. Raising north to `Target` and never touching south satisfies
   `WF_vars(Raise("north"))`, because it goes disabled at the end and weak
   fairness on a permanently disabled action is vacuous.

Both landed. `OK` [rc=0] then `LIVENESS_VIOLATION` [rc=13]. The After-the-run
block gives the same reason for the second one [`EXERCISES.md:280-282`].

## Predictions for exercise 5, written before the run

Also written into `LOG.md` before the first `Capper` run [`LOG.md`, ex5 line].

1. As shipped with `SF_vars(Cap)`: `OK`. Dodging the cap means alternating
   `Arrive` and `Wave` forever, and `Cap` is enabled at every `"bottle"` state
   in that behavior, so `[]<>ENABLED Cap` holds and `SF` fires.
2. With `WF_vars(Cap)`: `LIVENESS_VIOLATION`. The same behavior has `Cap`
   disabled at every `"empty"` state, so `<>[]ENABLED Cap` is false and `WF`
   promises nothing.

Both landed. `OK` [rc=0] then `LIVENESS_VIOLATION` [rc=13].

## Every stated outcome, run from the delivered tree

The authoring report names fifteen delivery runs [`reports/authoring.md:192-238`].
All fifteen reproduce, token and exit code.

| Run | Stated | Measured |
|---|---|---|
| ex1 pristine | `PARSE_ERROR` | 150 |
| ex2 pristine | `PARSE_ERROR` | 150 |
| ex3 pristine, `-d` | `PARSE_ERROR` | 150 |
| ex4 pristine | `OK` | 0 |
| ex5 pristine | `OK` | 0 |
| ex1 solved | `OK` | 0 |
| ex2 solved | `OK` | 0 |
| ex3 solved, `-d` | `OK` | 0 |
| ex4 solved | `OK` | 0 |
| ex5 solved | `OK` | 0 |
| ex1, drop `UNCHANGED rows` | `SPEC_EVAL_FAILURE` | 75 |
| ex2, drop the room check | `SAFETY_VIOLATION` | 12 |
| ex3, drop the bench guard | `SAFETY_VIOLATION` | 12 |
| ex4, `\A` becomes `\E` | `LIVENESS_VIOLATION` | 13 |
| ex5, `SF` becomes `WF` | `LIVENESS_VIOLATION` | 13 |

The solved rows used my own answers, written cold, not the references.

Ten further outcomes live in the After-the-run blocks. Those reproduce too.

| Edit | Stated | Measured |
|---|---|---|
| ex1, drop `rows` from `vars` | `OK`, silent | 0 |
| ex2, `frames[a]'` per key | `SPEC_EVAL_FAILURE` | 75 |
| ex2, drop `![b] = @ + 1` | `OK` | 0 |
| ex3, drop `Terminating`, with `-d` | `DEADLOCK` | 11 |
| ex3, drop `Terminating`, no `-d` | `OK` | 0 |
| ex3, drop `UNCHANGED panes` | `SPEC_EVAL_FAILURE` | 75 |
| ex4, drop the fairness conjunct | `LIVENESS_VIOLATION` | 13 |
| ex4, `WF_turns` for `WF_vars` | no change | 0 |
| ex5, `SF_vars(Press)` | `LIVENESS_VIOLATION` | 13 |
| ex5, `WF_capped(Arrive)` | `LIVENESS_VIOLATION` | 13 |

Both quoted TLC messages are exact. The completeness error came back as
`Successor state is not completely specified by action Refill of the next-state
relation. The following variable is not defined: rows.` [`--log`, line 28], and
the function error as `In evaluation, the identifier frames is either undefined
or not an operator.` [`--log`, line 32].

Twenty-five stated outcomes, no discrepancy.

## Finding: the learner can't read the output the text tells them to read

This is the send-back, and it's one repair.

`verdict.sh` sends all of TLC's output to a file and prints nothing but the
token [`harness/verdict.sh:346`, `timeout "$TIMEOUT" "${CMD[@]}" >"$LOG" 2>&1`].
With no `--log` and no `--scratch`, that file lands in a scratch directory the
exit trap deletes [`harness/verdict.sh:292-307`]. The trace goes the same way,
because it defaults into the same directory [`harness/verdict.sh:309-310`].

`EXERCISES.md` never mentions `--log`, `--trace` or `--scratch` [`grep -n --
'--log|--trace|--scratch|console'` matched one line, and it was the console
line]. Four sentences then ask for something the delivered material can't give.

- Line 54 says to ignore the console noise above the token.
- Line 114 says the fail-run message is worth reading once.
- Line 178 calls the second message the one the chapter singles out.
- Line 277 says to read the trace and check which winch stalled.

There is no console noise above the token, because there's no console output at
all. A learner who tries to follow line 114 or line 277 gets a bare token and no
way forward. I think line 277 is the one that costs most, since exercise 4's
whole insight is which winch stalled and why its fairness conjunct survived.

The fix I'd take is one line in "How to run", saying that `verdict.sh` keeps
TLC's output only when you ask for it, and giving the flag. Then line 54 wants
rewording, because ignoring noise and never seeing any are different
instructions. Lines 114, 178 and 277 become true unchanged.

The alternative is to leave the flags out and soften the four sentences to
quotations, which is what they mostly already are. That's less work, and it's
what I'd take if the intent is that a learner never looks past the token. But
exercise 4 asks for the trace by name, so I'd rather hand over the flag.

## Finding: exercise 3 sits closer to the chapter than the report says

The authoring report records the echo and calls it out honestly
[`reports/authoring.md:63-71`]. I agree it's an echo. I think the report
understates how much of it a learner can transcribe.

The chapter's `GetLock` is `/\ pc[self] = "GetLock" /\ lock = NULL /\ lock' =
self /\ pc' = [pc EXCEPT ![self] = "GetCounter"] /\ UNCHANGED << counter, tmp >>`
[`tla.rst:330-334`]. Exercise 3's `Mount` is that with `lock` renamed to
`bench`, `NULL` renamed to `Free` and the `pc` pair folded into `Trans`
[`references/GlazingBench.tla`, `Mount`]. The report says exercise 3 has "no
lock variable" [`reports/authoring.md:71`]. It has one, under another name.

`Cut` isn't transcribable, because the chapter never shows a release. The two
invariants are new. So roughly one of the two holes is a rename and the other
needs the learner's own reasoning, which I think is a fair trade for a
complete-the-skeleton exercise that says up front there's nothing in it you
haven't seen [`EXERCISES.md:228`]. Not a send-back. Worth correcting in the
report so the next reviewer doesn't have to re-derive it.

## Finding: exercise 4 leaves a wrong prediction unanswered

The brief asked whether a learner can answer exercise 4 without already knowing
that TLC accepts `\E` over a temporal formula. I think they can, and the reason
isn't the sheets.

The chapter poses the `\A` against `\E` question itself and gives the reading:
"If we instead wrote `\E`, we'd be saying that at least one thread is fair, but
the rest may be unfair" [`tla.rst:372`]. The exercise set's own first line
assumes the chapter has been read [`EXERCISES.md:3`]. So the `\E` form arrives
already framed as a spec with a meaning, not as a syntax error. The
predict-then-check format forces the run either way, so nobody stalls.

What's missing is closure for a learner who predicts `PARSE_ERROR` anyway. That
prediction is reasonable, since `PARSE_ERROR` is one of the six tokens the
preamble lists [`EXERCISES.md:64-65`] and nothing in the delivered material says
TLC will evaluate a quantifier over a temporal formula. The After-the-run block
explains `\A` against `\E` and never says TLC accepts the form
[`EXERCISES.md:264-294`]. One sentence closes it. Recommend, don't block.

## The two inert mutants are taught straight

Both are presented as things the run does not catch, and I checked both.

Dropping `rows` from `vars` returns `OK` [rc=0]. The text says so, says the
warning exists, and says `verdict.sh` suppresses it with `-nowarning`
[`EXERCISES.md:126-131`]. It calls the failure silent rather than caught.

Dropping `![b] = @ + 1` so a frame leaves and arrives nowhere returns `OK`
[rc=0]. The text says so, and says a range invariant can't see a lost element
because losing one doesn't make a number too big [`EXERCISES.md:186-191`]. It
then says the spec can't carry the conservation invariant that would catch it,
because `AddFrame` creates frames on purpose.

Neither is dressed up as a caught mutant. This check passes.

## Checks that came back clean

**No PlusCal, no `pcal`.** The string appears three times, all prose about its
absence, none in a command [`grep -n 'pcal' EXERCISES.md`, lines 5, 43, 228].

**No prerequisite leak.** Every construct I needed traces to a delivered sheet
or to chapter 12 itself. `\A`, `\E`, `pc` and invariants are ch04
[`cheatsheets/ch04.md:11-28`]. Operator definition, `EXTENDS`, integers,
strings, sets, `0..n` and `=>` are ch02 [`cheatsheets/ch02.md:11-91`]. Function
literals are ch06 [`cheatsheets/ch06.md:23`]. `<>` and `[]` are ch09
[`cheatsheets/ch09.md:11-27`]. `EXCEPT`, `@`, `UNCHANGED`, `vars`, `ProcSet`,
`Trans`, `Terminating`, `WF`, `SF`, `ENABLED` and `<<A>>_v` appear on no
delivered sheet, which is right, because they're chapter 12's own
[`grep -l -F 'EXCEPT' cheatsheets/*.md` matched nothing].

**No answer-key path in the printed text.** [`grep -n
'references/|reports/|COVERAGE|CHEATSHEET|exercises/ch12' EXERCISES.md` matched
nothing.]

**Delivery seam holds.** Every path a printed command names resolves from the
delivered chapter directory, including the `~/repos/tla-puzzles` harness path
[15 runs above, all from the delivered tree].

**No cross-type comparison.** `Free == "free"` keeps `bench` a string against
glazier strings, so `bench = g` never crosses types
[`references/GlazingBench.tla`, `Free` and `BenchHolderIsCutting`].

## Budgets

No breach observed, with a caveat about who measured it.

| Exercise | Budget | My wall clock |
|---|---|---|
| 1 | 15 min | 70 s |
| 2 | 12 min | 24 s |
| 3 | 15 min | 30 s |
| 4 | 10 min | 34 s |
| 5 | 15 min | 29 s |

Those are `date +%s` deltas from opening the prompt to the second verdict. They
say the exercises are small, and they don't say a human fits the budget, because
I'm not one. My read on the human side is that exercise 4 at 10 minutes is the
tightest of the five, since it wants two pieces of reasoning about vacuous
fairness before either run [INFERRED]. I wouldn't move it without a human timing
it.

## What I converged on

Worth recording, because it bears on ambiguity more than any assertion I could
make. My three written-from-prompt answers came out close to token-identical to
the references, which I read only afterwards. `SeedDrill` matches
[`references/SeedDrill.tla`]. `Apiary` matches, including `a # b` and the
two-key `EXCEPT` [`references/Apiary.tla`]. `GlazingBench` matches except that I
put `bench = Free` above the `Trans` call and the reference puts it below
[`references/GlazingBench.tla`]. Same conjunct list, different order, same
verdict.

Converging on the reference without seeing it is the strongest evidence I have
that the prompts pin what they mean.

## Related

`harness/test-printed-commands.sh` still stops at chapter 11
[`harness/test-printed-commands.sh:107`, `CHAPTERS=(02 03 04 05 06 07 08 09 10
11)`], so this review stands in for the gate on ch12. Bead `tla-i3zu` already
carries that [`bd list -n 1`].
