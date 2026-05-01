# R08: Review — Quantifiers in Properties ⭐

## Lesson: `\A` Inside a Temporal Property

T24 used quantifiers inside an INVARIANT — a state-level claim. Tier 5 mixes the two: quantifiers can appear inside a TEMPORAL property too. The shape

```
\A p \in Procs : <>(done[p] = TRUE)
```

reads "for every process `p`, EVENTUALLY `done[p]` is true." The `<>` is per-process: each `p` must eventually be done, but they don't have to finish at the same time. This is different from `<>(\A p \in Procs : done[p] = TRUE)` (everyone done in the SAME state) — though when the system terminates and `done` only goes from FALSE to TRUE, the two end up equivalent.

There is no new TLA+ syntax here. The novelty is the recurrence: quantifiers worked at the state level (T24) and they work the same way at the temporal level. You just nest the quantifier outside (or inside) the temporal operator.

**Worked example — a class of students submitting assignments.**

A teacher has a roster. Each student starts with `submitted` false, then at some point submits. The temporal claim is "every student eventually submits."

```
(*--algorithm Class {
  variables submitted = [s \in {"Ann", "Bob", "Cy"} |-> FALSE];

  define {
    AllEventuallySubmit == \A s \in {"Ann", "Bob", "Cy"} : <>(submitted[s] = TRUE)
  }

  fair process (student \in {"Ann", "Bob", "Cy"}) {
    turnIn:
      submitted[self] := TRUE;
  }
}*)
```

`AllEventuallySubmit` is one property — a conjunction over the roster. With `fair process`, every student eventually runs its `turnIn` step, so each `submitted[s]` flips to TRUE, so the property holds.

Drop the `fair` and the property fails: TLC can find a behavior where some student never runs.

The quantifier sits OUTSIDE the temporal operator. Read it left to right: "for every student `s` ... eventually `submitted[s]` is true." If you flipped the order to `<>(\A s : submitted[s] = TRUE)` you'd be asking for one MOMENT in which everyone is submitted simultaneously. For this puzzle that ends up true too (no one un-submits), but the difference matters whenever a flag can flip back.

## Setup

A small kitchen has three chefs: Alice, Bob, and Carol. Each chef has one dish to plate. Track plating with a function `plated[chef]`. Once a chef plates, they're done.

The head waiter wants a guarantee: "every chef eventually plates their dish." That's one property — the universal quantifier sits outside the eventually.

## Task

Write a PlusCal spec with:

- A single function-valued variable `plated` mapping each chef in `{"Alice", "Bob", "Carol"}` to `FALSE` initially
- A `define` block with:
  - `Chefs == {"Alice", "Bob", "Carol"}`
  - `TypeOK == plated \in [Chefs -> BOOLEAN]`
  - `EveryoneEventuallyPlates == \A c \in Chefs : <>(plated[c] = TRUE)`
- A `fair process` indexed over `Chefs` with one labeled step that sets `plated[self] := TRUE`

In `Chef.cfg`: `INVARIANT TypeOK` and `PROPERTY EveryoneEventuallyPlates`.

## Check

1. **TypeOK** holds in every reachable state.
2. **EveryoneEventuallyPlates** passes — every chef must eventually plate.

## Expected Result

- TLC finds **8 distinct states** — the powerset of the chef set: every subset of `{Alice, Bob, Carol}` corresponds to a "who has plated so far" state.
- No invariant or property violation. "No error has been found."
- If you change `fair process` to `process` (no fairness), TLC reports a liveness violation: in the unfair behavior, some chef may stutter forever and never plate.

## Hints

??? hint "💡 Hint 1 — Reading the property definition"
    Look at the `EveryoneEventuallyPlates` property in the expected result. You have a `\A` sitting OUTSIDE the temporal operator. Why does the quantifier go there instead of inside the `<>`?

??? hint "💡 Hint 2 — Fairness structure"
    The lesson uses `fair process` on the student. Why is `fair` needed for a `<>` property to hold? What does `fair` add to the generated TLA+ spec?

??? hint "💡 Hint 3 — The formula shape"
    Your property should look like `\A c \in Chefs : <>(plated[c] = TRUE)`. The `/\` from T24 (quantified invariants) shows up here too: you're writing a universal claim over processes.
