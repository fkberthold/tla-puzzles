# Coverage: learntla core ch.8, Concurrency

Every theme and every construct on `CHEATSHEET.md` is mapped to an exercise
below, or the omission is stated with its reason.

## Major themes

| # | Theme (abridged from the sheet) | Exercise |
|---|---|---|
| 1 | `process` blocks are the base unit of concurrency, and TLC explores every legal interleaving of their labeled steps | Ex1 `SeatDesk`, Ex2 `KitchenLocks` |
| 2 | An action that only makes sense in some states crashes TLC unless the spec says what happens instead | Ex3 `Cloakroom` |
| 3 | `await` blocks a label until its condition holds, and every process blocked at once is a deadlock | Ex2 `KitchenLocks` |
| 4 | Local variables hold per-process bookkeeping, at the cost of being invisible to `define` blocks | Ex5 `BellTower`, Ex1 `SeatDesk` |
| 5 | Splitting one action across two labels is what creates a race | Ex1 `SeatDesk` |
| 6 | Procedures extend macros with labels and a call stack, so they need `EXTENDS Sequences` and sit after macros and before processes | Ex4 `StampDesk` |

Theme 1 is covered in the half that a verdict can carry. The sheet's second
sentence, that the number of orderings grows factorially with the number of
independent actions, is **not** drilled anywhere and is not going to be. A
count of orderings is a state count, and this course's expected outcomes are
representation-robust by rule, so no exercise may state one. Ex1 exercises the
part that matters for correctness: that TLC tries every order, and that one of
those orders is the one that breaks your invariant.

Theme 2's three named repairs are split. Ex3 takes the `if` guard. `await` as
the blocking repair is Ex2's whole subject, approached from the other side, as
the thing that causes the deadlock rather than the thing that avoids the crash.
The third repair, substituting a default value, is not drilled; it is the same
`if` with a different consequent and adds nothing over Ex3.

Theme 4 is carried by Ex5, which turns the "invisible to `define`" clause into
a verdict a learner can produce on purpose. Ex1's `sawFree` covers the ordinary
use, per-process bookkeeping nobody else can see.

## Constructs

| Construct | Exercise |
|---|---|
| `process` (single) | Ex2 `KitchenLocks`, two singly-defined processes |
| `pc[...]` (multi-process `pc`) | Ex5 `BellTower`, `AllRung` reads `pc[r]` |
| process-local variable | Ex1 `sawFree`, Ex5 `left` |
| process set | Ex1, Ex3, Ex4, Ex5 |
| `self` | Ex3 `Cloakroom`, `coat[h] := self` |
| `await` | Ex2 `KitchenLocks` |
| deadlock (checking) | Ex2 `KitchenLocks`, run with `-d` |
| `procedure` | Ex4 `StampDesk` |
| `call` | Ex4 `StampDesk` |
| `return` | Ex4 `StampDesk` |

All ten are exercised.

Two construct details from the sheet are stated in an exercise rather than
drilled by a verdict, because each has exactly one right answer and no
interesting wrong one:

- That deadlock checking is turned off from the model rather than from spec
  text. Here it is the `-d` flag on `verdict.sh`, and Ex2 says so at the point
  of use.
- That a `call` must be followed by a `goto`, a label, or another `return`.
  Ex4's task says it, and the `Leave: skip;` label in the answer is there for
  no other reason.

## Documented omissions

- **Liveness.** The sheet's own boundary note sends it to chapter 9
  (`concurrency.rst:313-317`). Nothing here uses a temporal property, a
  fairness annotation, or `<>`. Ex2 stops at "this deadlocks" and does not ask
  whether the kitchen eventually gets used.
- **Nondeterministic `with x \in set`,** and its blocking-on-empty behavior.
  The sheet's boundary note sends it to chapter 7 (`concurrency.rst:202`).
  Ex3 uses the deterministic `with (h = ...)` form, which is chapter 5's, to
  bind the result of a `CHOOSE`. It is a naming convenience there and carries
  no chapter-7 meaning.
- **Macros.** The sheet mentions them only as the thing procedures extend.
  Chapter 5 introduces and drills them; repeating that here would spend a
  budget on a construct this chapter does not teach.
- **`self` inside a macro,** and the `process P \in {val}` trick that lets a
  single process reach it. That is a tip in the chapter
  (`concurrency.rst:166-182`), not a theme on the sheet, and it needs macros to
  make sense.
- **Model values as process values.** The chapter's warning that all processes
  must have comparable types, with model values as the exception
  (`concurrency.rst:34`), is not drilled. Chapter 3 owns model values, and Ex2
  uses one as `Nobody`, the "nobody holds this" placeholder, rather than as a
  process value.
