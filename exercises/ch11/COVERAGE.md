# Coverage audit: ch11 exercise set

Audited against the six major themes and three constructs in
`exercises/ch11/CHEATSHEET.md`. This file is an audit run after the set was
written. It's not the thing that generated the set.

## Major themes

| # | Theme (abbreviated from the sheet) | Exercises | Verdict |
|---|---|---|---|
| 1 | Action properties restrict how the system is allowed to *change*. Invariants restrict what a single state may look like on its own | 1, 3, 5 | covered |
| 2 | `x'` is the value at the end of a step. A formula mixing `x` and `x'` describes a transition, not a state | 1, 2, 3, 4, 5 | covered |
| 3 | A bare next-state formula is always false as a property, because a stutter step can always be inserted. `[P]_x` adds `\/ UNCHANGED x` | 1, 2 | covered |
| 4 | Helper actions factor primed logic into named operators, reusable inside more than one action property | 5 | covered |
| 5 | TLC checks only a top-level `[A]_v`. A quantifier round the whole `[]` fails, and `[]` commutes with `\A`, so the quantifier moves inside | 4 | covered |
| 6 | Action properties are optional, unlike liveness properties. Flexible but secondary, for transition rules invariants and liveness do not reach | 3, 5 | covered in part |

Theme 1 is the chapter's reason for existing, so exercise 3 is built for it and
nothing else. It is the predict-then-check, because the reveal only lands if you
have committed to a wrong answer first.

Theme 3 gets the other predict-then-check, exercise 2, for the same reason.

## The one partial row

**Theme 6, action properties as the optional third kind of check.** The sheet's
theme line has two halves and this set exercises one of them.

The half that is covered is "flexible but secondary, good for expressing
transition rules that invariants and liveness properties do not reach".
Exercise 3 runs an invariant and an action property over one spec and breaks it
in a way only the action property can see. Exercise 5 does the same from the
other end, with one invariant and two action properties on one spec and a `.cfg`
that shows all three side by side. Between them a learner sees what an action
property is for and what it is not needed for.

The half that is not covered is "unlike liveness properties, where every spec
needs at least one". Exercising that would mean putting a `fair process` and a
`<>` property into a chapter 11 exercise so the learner has all three kinds in
front of them at once. Those are chapter 9's constructs. Spending a third of a
15 minute budget on chapter 9 material to make a comparative point that the
sheet states in one sentence looked like the wrong trade, so the comparison is
made in prose in exercise 5's task instead, against the invariant the spec
already has. I think this is the weakest omission in the set, and a sixth
exercise carrying a liveness property alongside an action property would close
it honestly.

## Constructs

All three constructs on the sheet appear in every exercise.

| Construct | Exercises |
|---|---|
| action property, checked with `PROPERTY` and never `INVARIANT` | 1, 2, 3, 4, 5 |
| `'`, the next-state value | 1, 2, 3, 4, 5 |
| `[P]_x`, the box action formula | 1, 2, 3, 4, 5 |

There are only three, and a chapter this narrow cannot spread them out. What
varies across the five is the shape of the action inside the brackets: a
comparison between a variable and its own next value (1), an exact step size
(1, 2), arithmetic on the difference (3), an implication guarded on the current
state (5), and a quantified body naming the whole set of legal next values (4).

Exercise 4's action is the only one in the set that is not an order or a step
size. `colony[p]' \in {colony[p], 2 * colony[p]}` is a multiplicative coupling
between a value and its own next value, and it is deliberately not a
monotonicity claim. A colony that climbs by one breaks it, which is what
exercise 4's fail run shows.

## A measured correction to theme 5

The sheet's theme 5, following the chapter, says the failure happens when a
quantifier is wrapped round the whole `[]`. Measured on this build, that is not
the trigger. What SANY refuses is a subscript that is not a variable name, and
`[][colony["left"]' \in {colony["left"], 2 * colony["left"]}]_colony["left"]` is
refused with no quantifier anywhere in it. An outer `\A` over a whole-variable
subscript compiles and is genuinely checked.

The chapter's fix is still the right fix, and exercise 4 teaches it, because
commuting the `\A` inside is exactly what puts the subscript back on the whole
variable. The full probe table is in `reports/authoring.md`, finding 2. The
sheet is worth amending, and that is a job for whoever owns the sheet rather
than for this set.

## Scope

Every construct used across the five exercises comes from chapters 2 to 11,
checked against the `ch02` through `ch11` sheets. The full check is the table in
`reports/authoring.md`.

Nothing from chapter 12 appears. The ch11 sheet's boundary notes place the
multi-variable `UNCHANGED <<x, y, z>>` form there, so every subscript in this
set is a single variable name, and `EXERCISES.md` says so at the top.
