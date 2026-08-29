# Coverage audit: ch12 exercise set

Audited against the twelve major themes and eighteen constructs in
`exercises/ch12/CHEATSHEET.md`. This file is an audit run after the set was
written. It's not the thing that generated the set.

The sheet carries a thirteenth theme bullet, `SOURCE GAP:`, and it is not a
theme of the chapter. It records where `tla.rst` stops. Nothing below drills it,
on purpose, and the last section here says why.

## Major themes

| # | Theme (abbreviated from the sheet) | Exercises | Verdict |
|---|---|---|---|
| 1 | The chapter bootstraps pure TLA+ out of PlusCal, by reading the translator's output as a known-valid answer key | 3 | covered in part |
| 2 | It's all comparison, never assignment. `x = 5` and `x' = 5` are claims, which is why TLA+ needs no `:=` | 1, 2, 3 | covered |
| 3 | A spec is `Init /\ [][Next]_vars`, the blueprint every spec follows | 1, 2, 3, 4, 5 | covered |
| 4 | The next action must fully describe every variable, and `UNCHANGED` is how you say "nothing" | 1, 3 | covered |
| 5 | The same rule bites harder on functions. `s[1]' = FALSE` says nothing about `s[2]'`, and `EXCEPT` is the fix | 2 | covered |
| 6 | The translation is mechanical. Deterministic `with` becomes `LET`, nondeterministic `with` becomes `\E`, `either` becomes `\/` | 1, 2, 3 | covered in part |
| 7 | Concurrency is just `\E self \in Threads: thread(self)`, and sequence is a `pc` guard plus a `pc'` update | 3 | covered |
| 8 | `await` needs no machinery. It becomes a plain conjunct that fails to enable the action | 3 | covered |
| 9 | TLA+ can describe behaviors TLC can't enumerate. Valid spec and checkable spec are different things | none | omitted, see below |
| 10 | Fairness is a constraint appended to `Spec`, not a property checked against it | 4, 5 | covered |
| 11 | `\A` against `\E` on the fairness conjunct decides whether every process is fair or only one. The chapter's own comprehension test | 4 | covered |
| 12 | Pure TLA+ earns its curve on a short list PlusCal can't reach | 3, 5 | covered in part |

Theme 11 is what the bead singled out and what exercise 4 exists for. It's the
predict-then-check, because a quantifier over a temporal formula reads as
obvious in both directions until you've committed to one and been wrong.

Theme 10 gets both fairness exercises. Exercise 4 shows what a fairness conjunct
buys and exercise 5 shows what the wrong one buys, which is nothing.

## The one omission

**Theme 9, valid spec against checkable spec.** No exercise drills it, and I
think that's the right call rather than a gap I ran out of time for.

The theme's example is `Next == x' >= x`, whose behaviors include
`1 -> 9 -> 17 -> 17.1 -> 84`. The point lands by reading it. Making it land by
running it means writing a spec TLC can't enumerate, then collecting whichever
token TLC happens to fall over with, and that token names the channel rather
than the idea. A learner would come away having memorized an exit code for
"unbounded next-state relation" instead of having understood that TLA+ describes
more than TLC checks.

It's also the one theme on the sheet with no construct attached. The other
eleven each cash out in something you type.

Where it does show up is exercise 1's After-the-run note about `vars`. Leaving a
variable out of the tuple gives a spec TLC accepts, warns about, and reports
`OK` on, with `verdict.sh` suppressing the warning. That's the same gap between
"valid" and "checked" from the other side, and it's measured rather than
asserted.

## The two partial rows

**Theme 1, bootstrapping out of the translator.** Exercise 3 is a translator's
output written by hand, and the skeleton hands over `Trans`, `Terminating` and
`ProcSet` exactly as `pcal` would emit them. What no exercise does is put a
PlusCal module and its translation side by side and ask what maps to what.

That was deliberate. A drill built on reading a translation is a drill about
PlusCal, and the bead says this chapter is pure TLA+ with no translation step.
The half of the theme that survives is the half worth having: the shapes the
translator produces are the shapes you write by hand.

**Theme 12, what pure TLA+ buys.** The sheet lists six items. Two are drilled.
Helper actions are exercise 3's `Trans`, and fairness on a subaction is exercise
5's `SF_vars(Cap)` against `SF_vars(Press)`.

The other four aren't. Verifying a refactored spec behaves the same and
refinement both live outside `core`, and the sheet's own boundary note says
`topics/refinement.rst` is a stub that teaches nothing. Interruptible algorithms
and several sequential tasks per worker are both reachable, and both want a
spec big enough to make the contrast with PlusCal visible, which is more than a
15 minute budget holds. A sixth exercise carrying an interruptible loop would
close half of what's left honestly.

**Theme 6, mechanical translation.** Two of the three mappings are exercised.
`\E` is exercise 2's `Next` and `\/` is exercise 1's. The `LET` that a
deterministic `with` becomes isn't, and `LET-IN` is chapter 2's construct
anyway, so drilling it here would be drilling an earlier chapter.

## Constructs

| Construct | Exercises |
|---|---|
| `VARIABLE` / `VARIABLES` | 1, 2, 3, 4, 5 |
| `vars`, the all-variables tuple | 1, 2, 3, 4, 5 |
| `Init` / `Next` / `Spec` | 1, 2, 3, 4, 5 |
| action, as the formal name for a boolean operator containing a prime | 1, 2, 3, 4, 5 |
| `UNCHANGED` | 1, 3, 5 |
| nondeterministic action, `\E` form and `\/` form | 1, 2, 3, 4, 5 |
| `EXCEPT` | 2, 3, 4 |
| `@`, the original value | 2, 4 |
| `ProcSet` | 3 |
| label-as-action encoding | 3 |
| `Trans` helper action | 3 |
| `Terminating` | 3 |
| `ENABLED` | 5 |
| `<<A>>_v` | 5 |
| `WF_v(A)` | 4, 5 |
| `SF_v(A)` | 5 |
| fairness conjunct on `Spec` | 4, 5 |
| fairness on a subaction | 5 |

All eighteen appear. Two of them, `ENABLED` and `<<A>>_v`, appear in exercise
5's reasoning rather than in a module a learner types, and that's worth being
straight about. Neither is a thing you write in a spec. They're the parts of the
`WF_v` and `SF_v` definitions that decide what those operators promise, so the
way to exercise them is to make a learner predict a verdict that only those
definitions explain. Exercise 5's second run turns on `ENABLED`, and its
`WF_capped(Arrive)` run turns on `<<A>>_v` and nothing else.

`EXCEPT` and `@` land in three and two exercises respectively without any of
them being an `EXCEPT` drill except exercise 2. That's because a function-valued
variable is the normal case in this chapter, `pc` included, and updating one
needs `EXCEPT` whether or not the exercise is about it.

## Scope

Every construct used across the five exercises comes from chapters 2 to 12,
checked against the `ch02` through `ch12` sheets. The full check is the table in
`reports/authoring.md`.

Two notes on the edges.

`<=>` appears on no sheet, so exercise 3's mutual-exclusion claim is two
invariants joined by `=>`, which is chapter 2's, rather than one joined by
`<=>`. That's why `CutterHoldsBench` and `BenchHolderIsCutting` are separate
names.

`SPECIFICATION` appears on no sheet either. Every earlier chapter's `.cfg` uses
it, and no exercise in this set asks a learner to write a `.cfg`, so nothing is
being taught here that the sheets don't carry.

## The source gap, and why nothing drills it

`tla.rst:411` reserves a warning about machine closure and an example of
fairness inside a temporal property. Both sit in the fairness section that six
of the sheet's constructs draw on, and both are the kind of material exercises 4
and 5 would otherwise reach for. `tla.rst:459` is a bare `.. todo:: Summary`, so
unlike chapters 9 and 11 there's no summary section to build a recap drill from.

Neither exercise 4 nor exercise 5 goes near either. Machine closure never comes
up, and no fairness formula in this set appears inside a property. Both stay on
`Spec`, where the chapter puts them.
